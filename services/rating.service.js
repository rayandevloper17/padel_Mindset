/**
 * Rating Calculation System for Padel Matches - CORRECTED VERSION
 * 
 * This service calculates the new rating (Rn) for players after a match is validated.
 * 
 * ERRORS FIXED:
 * ❌ ERROR 1: Points 0 was 100.00 → ✅ FIXED: Should be 97.37
 * ❌ ERROR 2: Points 1 was 97.37 → ✅ FIXED: Should be 94.74 
 * ❌ ERROR 3: All subsequent points were shifted → ✅ FIXED: Corrected all values
 */

// TABLE 1: Rating difference (X) to Expected Win Value (W)
const RATING_DIFF_TABLE = [
    { min: 0.96, max: 3.5, W: 0.02 },
    { min: 0.86, max: 0.95, W: 0.03 },
    { min: 0.76, max: 0.85, W: 0.05 },
    { min: 0.66, max: 0.75, W: 0.08 },
    { min: 0.56, max: 0.65, W: 0.11 },
    { min: 0.46, max: 0.55, W: 0.15 },
    { min: 0.36, max: 0.45, W: 0.2 },
    { min: 0.26, max: 0.35, W: 0.26 },
    { min: 0.16, max: 0.25, W: 0.33 },
    { min: 0.05, max: 0.15, W: 0.41 },
    { min: -0.06, max: 0.05, W: 0.5 },
    { min: -0.16, max: -0.06, W: 0.6 },
    { min: -0.25, max: -0.16, W: 0.7 },
    { min: -0.36, max: -0.26, W: 0.85 },
    { min: -0.46, max: -0.36, W: 1 },
    { min: -0.56, max: -0.46, W: 1.2 },
    { min: -0.66, max: -0.56, W: 1.4 },
    { min: -0.76, max: -0.66, W: 1.7 },
    { min: -0.86, max: -0.76, W: 2 },
    { min: -0.96, max: -0.86, W: 2.4 },
    { min: -3.5, max: -0.96, W: 2.8 }
];

// TABLE 2: Points to adjustment percentage
// ✅ CORRECTED - Based on Image 2 exact values
const POINTS_ADJUSTMENT = {
    0: 97.37,   // ❌ WAS: 100.00 (WRONG!)
    1: 94.74,   // ❌ WAS: 97.37 (shifted)
    2: 92.11,   // ❌ WAS: 94.74 (shifted)
    3: 89.47,   // ❌ WAS: 92.11 (shifted)
    4: 86.84,   // ❌ WAS: 89.47 (shifted)
    5: 84.21,   // ❌ WAS: 86.84 (shifted)
    6: 81.58,   // ❌ WAS: 84.21 (shifted)
    7: 78.95,   // ❌ WAS: 81.58 (shifted)
    8: 76.32,   // ❌ WAS: 78.95 (shifted)
    9: 73.68,   // ❌ WAS: 76.32 (shifted)
    10: 71.05,  // ❌ WAS: 73.68 (shifted)
    11: 68.42,  // ❌ WAS: 71.05 (shifted)
    12: 65.79,  // ❌ WAS: 68.42 (shifted)
    13: 63.16,  // ❌ WAS: 65.79 (shifted)
    14: 60.53,  // ❌ WAS: 63.16 (shifted)
    15: 57.89,  // ❌ WAS: 60.53 (shifted)
    16: 55.26,  // ❌ WAS: 57.89 (shifted)
    17: 52.63,  // ❌ WAS: 55.26 (shifted)
    18: 50.00,  // ❌ WAS: 52.63 (shifted)
    19: 50      // ❌ WAS: 50.00 (but was missing from table)
};

/**
 * Look up W value based on rating difference X
 */
const lookupW = (X) => {
    for (let row of RATING_DIFF_TABLE) {
        if (X >= row.min && X <= row.max) {
            return row.W;
        }
    }
    // Fallbacks for extreme values
    if (X > 3.5) return 0.02;
    if (X < -3.5) return 2.8;
    return 0.5; // default for 0 difference
};

/**
 * Look up adjustment percentage based on points scored
 */
const getAdjustmentPercentage = (pointsScored) => {
    if (pointsScored in POINTS_ADJUSTMENT) {
        return POINTS_ADJUSTMENT[pointsScored];
    }
    
    // For scores > 19, use 50% (last value in table)
    if (pointsScored > 19) {
        return 50;
    }
    
    return 97.37; // ✅ CORRECTED: default for 0 points
};

/**
 * Calculate new rating after a validated match
 * 
 * @param {Object} matchData - Match information
 */
const calculateNewRating = (matchData) => {
    const {
        playerRating,
        teammateRating,
        adversary1Rating,
        adversary2Rating,
        pointsScored,
        teammateReliability,
        adversary1Reliability,
        adversary2Reliability
    } = matchData;

    console.log(`[RatingService] 📈 Calculating rating for player with current rating: ${playerRating}`);

    // STEP 1: Calculate X - Average rating difference
    const X = ((playerRating + teammateRating) - (adversary1Rating + adversary2Rating)) / 2;
    console.log(`[RatingService] Step 1 - X (rating difference): ${X.toFixed(4)}`);

    // STEP 2: Find W from Table 1
    const W = lookupW(X);
    console.log(`[RatingService] Step 2 - W (expected win value): ${W}`);

    // STEP 3: Calculate Y - Adjusted points value
    const adjustmentPercentage = getAdjustmentPercentage(pointsScored);
    const Y = W * (adjustmentPercentage / 100);
    console.log(`[RatingService] Step 3 - Points: ${pointsScored}, Adjustment %: ${adjustmentPercentage}, Y: ${Y.toFixed(4)}`);

    // STEP 4: Calculate Z - Performance difference
    const Z = W - Y;
    console.log(`[RatingService] Step 4 - Z (performance difference): ${Z.toFixed(4)}`);

    // STEP 5: Calculate Ro - Rating change with reliability factor
    const avgReliability = (teammateReliability + adversary1Reliability + adversary2Reliability) / 3;
    const Ro = Z * avgReliability;
    console.log(`[RatingService] Step 5 - Avg Reliability: ${avgReliability.toFixed(4)}, Ro (Rating change): ${Ro.toFixed(4)}`);

    // STEP 6: Calculate Rn - New rating with constraints
    let Rn = playerRating + Ro;

    // Apply constraints
    if (Rn < 0.5) Rn = 0.5;
    if (Rn > 7.0) Rn = 7.0;

    console.log(`[RatingService] Step 6 - Final New Rating (Rn): ${Rn.toFixed(4)}`);
    console.log(`[RatingService] ✅ Rating change: ${(Rn - playerRating > 0 ? '+' : '')}${(Rn - playerRating).toFixed(4)}`);
    
    return Rn;
};

export default {
    calculateNewRating
};
