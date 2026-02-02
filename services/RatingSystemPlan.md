# Technical Plan: Padel Rating Calculation System (Rn)

This document outlines the technical implementation for the new Padel rating system based on match performance, player ratings, and reliability scores.

## 1. Overview
The system will calculate a new rating ($R_n$) for a user after a match is confirmed. The calculation considers the relative strength of both teams, the match score (points conceded), and the reliability (fiability) of the participants.

## 2. Mathematical Formulae

### Step 1: Rating Difference ($X$)
$X = \frac{(R_{user} + R_{partner}) - (R_{opponent1} + R_{opponent2})}{2}$

### Step 2: Base Weight ($W$)
Find $W$ by looking up $X$ in the **Rating Interval Table**.

| Interval ($I$) | Weight ($W$) |
| :--- | :--- |
| $3.5$ to $0.96$ | $0.02$ |
| $0.95$ to $0.86$ | $0.03$ |
| $0.85$ to $0.76$ | $0.05$ |
| $0.75$ to $0.66$ | $0.08$ |
| $0.65$ to $0.56$ | $0.11$ |
| $0.55$ to $0.46$ | $0.15$ |
| $0.45$ to $0.36$ | $0.20$ |
| $0.35$ to $0.26$ | $0.26$ |
| $0.25$ to $0.16$ | $0.33$ |
| $0.15$ to $0.05$ | $0.41$ |
| $0.05$ to $-0.06$ | $0.50$ |
| $-0.06$ to $-0.16$ | $0.60$ |
| $-0.16$ to $-0.25$ | $0.70$ |
| $-0.26$ to $-0.36$ | $0.85$ |
| $-0.36$ to $-0.46$ | $1.00$ |
| $-0.46$ to $-0.56$ | $1.20$ |
| $-0.56$ to $-0.66$ | $1.40$ |
| $-0.66$ to $-0.76$ | $1.70$ |
| $-0.76$ to $-0.86$ | $2.00$ |
| $-0.86$ to $-0.96$ | $2.40$ |
| $-0.96$ to $-3.50$ | $2.80$ |

### Step 3: Performance Penalty ($Y$)
Calculate the percentage of points/games conceded based on the **Penalty Table**.
$Y = W \times \text{Percentage}$

*Example Mapping (0-19 points):*
- $0 \rightarrow 100\%$
- $10 \rightarrow 73.68\%$
- $19 \rightarrow 50.00\%$

### Step 4: Net Gain ($Z$)
$Z = W - Y$

### Step 5: Reliability Adjustment ($R_o$)
Adjust the gain based on the average reliability ($F$) of the teammate and opponents.
$R_o = Z \times \frac{F_{partner} + F_{opponent1} + F_{opponent2}}{3 \times 100}$
*(Note: Reliability is treated as a percentage coefficient)*

### Step 6: Final Rating ($R_n$)
$R_n = R_{current} + R_o$

**Constraints:**
- Minimum $R_n$: $0.5$
- Maximum $R_n$: $7.0$

## 3. Implementation Strategy

### A. Backend Service
Create a dedicated `RatingService` in the backend to encapsulate this logic.
- **Location**: `backend/backend/services/rating.service.js`
- **Function**: `calculateNewRating(players, scores)`

### B. Trigger Mechanism
The calculation will be triggered in `ReservationService` when a match score is moved to `confirmed` status (Score Status 2).

### C. Data Persistence
1. Update the `note` field in the `utilisateur` table.
2. Log the rating change in a new `rating_history` table (recommended for transparency).

## 4. Edge Case Handling
- **Missing Players**: If a match is played with fewer than 4 players, the formula will adjust to use the average of available players.
- **High Scores**: If points conceded $> 19$, the percentage will floor at $50\%$ or follow a linear decay.
- **Reliability Growth**: As users play more matches, their `fiability` score should increase (e.g., +1 per match played).

---
**Review Request**: Please confirm if the interval mappings and the reliability coefficient (divided by 100) match your expectations.
