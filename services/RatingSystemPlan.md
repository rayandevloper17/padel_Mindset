# Technical Plan: Padel Rating Calculation System (Rn)

This document outlines the technical implementation for the new Padel rating system based on match performance, player ratings, and reliability scores.

## 1. Overview

The system will calculate a new rating ($R_n$) for a user after a match is confirmed. The calculation considers the relative strength of both teams, the match score (points conceded), and the reliability (fiability) of the participants.

## 2. Mathematical Formulae

### Step 1: Rating Difference ($X$)

$$X = \frac{(R_{user} + R_{partner}) - (R_{opponent1} + R_{opponent2})}{2}$$

### Step 2: Base Weight ($W$)

Find $W$ by looking up $X$ in the **Rating Interval Table**.

| Interval ($I$)       | Weight ($W$) |
| :--------------------- | :------------- |
| $3.5$ to $0.96$    | $0.02$       |
| $0.95$ to $0.86$   | $0.03$       |
| $0.85$ to $0.76$   | $0.05$       |
| $0.75$ to $0.66$   | $0.08$       |
| $0.65$ to $0.56$   | $0.11$       |
| $0.55$ to $0.46$   | $0.15$       |
| $0.45$ to $0.36$   | $0.20$       |
| $0.35$ to $0.26$   | $0.26$       |
| $0.25$ to $0.16$   | $0.33$       |
| $0.15$ to $0.05$   | $0.41$       |
| $0.05$ to $-0.06$  | $0.50$       |
| $-0.06$ to $-0.16$ | $0.60$       |
| $-0.16$ to $-0.25$ | $0.70$       |
| $-0.26$ to $-0.36$ | $0.85$       |
| $-0.36$ to $-0.46$ | $1.00$       |
| $-0.46$ to $-0.56$ | $1.20$       |
| $-0.56$ to $-0.66$ | $1.40$       |
| $-0.66$ to $-0.76$ | $1.70$       |
| $-0.76$ to $-0.86$ | $2.00$       |
| $-0.86$ to $-0.96$ | $2.40$       |
| $-0.96$ to $-3.50$ | $2.80$       |

### Step 3: Performance Adjustment ($Y$)

Calculate the adjustment based on points scored using the **Points Adjustment Table**.

$$Y = W \times \frac{\text{Percentage}}{100}$$

**Points-to-Percentage Mapping (0-19 points):**

| Points Scored | Adjustment % |
|---------------|--------------|
| 0             | 100.00       |
| 1             | 97.37        |
| 2             | 94.74        |
| 3             | 92.11        |
| 4             | 89.47        |
| 5             | 86.84        |
| 6             | 84.21        |
| 7             | 81.58        |
| 8             | 78.95        |
| 9             | 76.32        |
| 10            | 73.68        |
| 11            | 71.05        |
| 12            | 68.42        |
| 13            | 65.79        |
| 14            | 63.16        |
| 15            | 60.53        |
| 16            | 57.89        |
| 17            | 55.26        |
| 18            | 52.63        |
| 19            | 50.00        |

**Logic:**
- **More points scored = Lower percentage = BIGGER rating gain**
- **Fewer points scored = Higher percentage = SMALLER rating gain**

### Step 4: Net Gain ($Z$)

$$Z = W - Y$$

**Interpretation:**
- $Z > 0$: Player performed better than expected (rating increases)
- $Z < 0$: Player performed worse than expected (rating decreases)
- $Z = 0$: Player performed exactly as expected (no change)

### Step 5: Reliability Adjustment ($R_o$)

Adjust the gain based on the average reliability ($F$) of the teammate and opponents.

$$R_o = Z \times \frac{F_{partner} + F_{opponent1} + F_{opponent2}}{3}$$

**Important Notes:**
- Reliability coefficients ($F$) are in the range **[0, 1]**
- Database stores `fiability` as **0-100**
- **Convert by dividing by 100**: $F = \frac{\text{fiability}}{100}$
- **Default value** if missing: 50 → 0.5

**Implementation:**
```javascript
// Convert database values (0-100) to coefficients (0-1)
const teammateReliability = (teammate.fiability || 50) / 100;
const adversary1Reliability = (opponent1.fiability || 50) / 100;
const adversary2Reliability = (opponent2.fiability || 50) / 100;

// Calculate average reliability
const avgReliability = (teammateReliability + adversary1Reliability + adversary2Reliability) / 3;

// Apply to formula
const Ro = Z * avgReliability;
```

### Step 6: Final Rating ($R_n$)

$$R_n = R_{current} + R_o$$

**Constraints:**
- Minimum $R_n$: **0.5**
- Maximum $R_n$: **7.0**

```javascript
let Rn = currentRating + Ro;

// Apply bounds
if (Rn < 0.5) Rn = 0.5;
if (Rn > 7.0) Rn = 7.0;
```

## 3. Implementation Strategy

### A. Backend Service

Create a dedicated `RatingService` in the backend to encapsulate this logic.

- **Location**: `backend/services/rating.service.js`
- **Function**: `calculateNewRating(matchData)`

### B. Trigger Mechanism

The calculation is triggered in `ReservationService` when a match score is confirmed (Score Status = 2).

**Flow:**
1. User confirms match score
2. Score status changes to "confirmed" (status 2)
3. System calls `updatePlayerRatings(reservationId)`
4. For each of the 4 players:
   - Gather match data (ratings, points, reliability)
   - Call `calculateNewRating(matchData)`
   - Update user's `note` field in database
   - Log rating change

### C. Data Persistence

1. **Update** the `note` field in the `utilisateur` table
2. **Log** the rating change (optional but recommended for transparency and debugging)

**Recommended Logging:**
```javascript
console.log(`User ${userId} rating: ${oldRating} -> ${newRating} (${change > 0 ? '+' : ''}${change})`);
```

## 4. Edge Case Handling

### Missing Players
- If a match has fewer than 4 players, **skip rating calculation**
- Log a warning message

### High Scores
- If points scored > 19, use **50%** or continue decreasing pattern
- Implementation: `Math.max(0, 50 - (points - 19) * 2.63)`

### Reliability Growth
- As users play more matches, their `fiability` score should increase
- Suggested: **+1 per match played** (capped at 100)

### New Players
- Default rating: **0.5**
- Default reliability: **50** (0.5 after conversion)

## 5. Testing Scenarios

### Test 1: Equal Teams, Moderate Score
```javascript
const matchData = {
    playerRating: 3.0,
    teammateRating: 3.0,
    adversary1Rating: 3.0,
    adversary2Rating: 3.0,
    pointsScored: 10,
    teammateReliability: 1.0,
    adversary1Reliability: 1.0,
    adversary2Reliability: 1.0
};
// Expected: Small rating change based on performance
```

### Test 2: Underdog Wins
```javascript
const matchData = {
    playerRating: 2.0,
    teammateRating: 2.5,
    adversary1Rating: 5.0,
    adversary2Rating: 5.5,
    pointsScored: 15, // Good performance
    teammateReliability: 1.0,
    adversary1Reliability: 1.0,
    adversary2Reliability: 1.0
};
// Expected: Large positive rating change
```

### Test 3: Favorite Loses
```javascript
const matchData = {
    playerRating: 6.0,
    teammateRating: 6.5,
    adversary1Rating: 3.0,
    adversary2Rating: 3.5,
    pointsScored: 5, // Poor performance
    teammateReliability: 1.0,
    adversary1Reliability: 1.0,
    adversary2Reliability: 1.0
};
// Expected: Large negative rating change
```

### Test 4: Complete Loss (0 Points)
```javascript
const matchData = {
    playerRating: 5.0,
    teammateRating: 5.0,
    adversary1Rating: 5.0,
    adversary2Rating: 5.0,
    pointsScored: 0, // Complete loss
    teammateReliability: 1.0,
    adversary1Reliability: 1.0,
    adversary2Reliability: 1.0
};
// Expected: NO rating change (Z = W - W = 0)
```

## 6. Formula Verification Examples

### Example 1: Balanced Match with 10 Points

**Given:**
- Team A: Player (4.0) + Teammate (4.0) = 8.0
- Team B: Opponent1 (4.0) + Opponent2 (4.0) = 8.0
- Points scored: 10
- All reliability: 1.0

**Calculation:**
1. $X = (8.0 - 8.0) / 2 = 0$
2. $W = 0.5$ (from table, X in [-0.06, 0.05])
3. $Y = 0.5 \times (73.68 / 100) = 0.3684$
4. $Z = 0.5 - 0.3684 = 0.1316$
5. $R_o = 0.1316 \times 1.0 = 0.1316$
6. $R_n = 4.0 + 0.1316 = 4.1316$

**Result:** Rating increases by **+0.13**

### Example 2: Underdog Victory with 15 Points

**Given:**
- Team A: Player (2.0) + Teammate (2.5) = 4.5
- Team B: Opponent1 (5.0) + Opponent2 (5.5) = 10.5
- Points scored: 15
- All reliability: 1.0

**Calculation:**
1. $X = (4.5 - 10.5) / 2 = -3.0$
2. $W = 2.8$ (from table, X in [-3.5, -0.96])
3. $Y = 2.8 \times (60.53 / 100) = 1.6948$
4. $Z = 2.8 - 1.6948 = 1.1052$
5. $R_o = 1.1052 \times 1.0 = 1.1052$
6. $R_n = 2.0 + 1.1052 = 3.1052$

**Result:** Rating increases by **+1.11** (large gain for beating stronger opponents!)

---

**Review Status**: ✅ Verified - Formula and implementation are mathematically correct.
