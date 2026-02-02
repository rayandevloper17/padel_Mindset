/**
 * Rating Calculation System for Padel Matches - ACTUALLY CORRECT VERSION
 * 
 * This service calculates the new rating (Rn) for players after a match is validated.
 * 
 * UNDERSTANDING THE LOGIC:
 * - More points scored = Lower percentage = BIGGER rating gain
 * - Fewer points scored = Higher percentage = SMALLER rating gain
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

// TABLE 2: Points scored to adjustment percentage
// ✅ CORRECT - Based on Image 2
// Lower percentage = Better performance = More rating gain
const POINTS_ADJUSTMENT = {
    0: 100,     // ✅ 0 points = 100% (no rating change from base)
    1: 97.37,   // ✅ Percentage decreases as points increase
    2: 94.74,
    3: 92.11,
    4: 89.47,
    5: 86.84,
    6: 84.21,
    7: 81.58,
    8: 78.95,
    9: 76.32,
    10: 73.68,  // ✅ CORRECT - 10 maps to 73.68
    11: 71.05,
    12: 68.42,
    13: 65.79,
    14: 63.16,
    15: 60.53,
    16: 57.89,
    17: 55.26,
    18: 52.63,
    19: 50.00   // ✅ 19 points = 50% (maximum rating gain shown)
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
    
    // For scores > 19, continue decreasing or use 50%
    if (pointsScored > 19) {
        // Continue pattern: decrease by ~2.63 per point
        const decrease = 2.63;
        return Math.max(0, 50 - (pointsScored - 19) * decrease);
    }
    
    return 100; // default for 0 points
};

/**
 * Calculate new rating after a validated match
 * 
 * @param {Object} matchData - Match information
 * @param {number} matchData.playerRating - Current rating of the player (Ra) [0.5-7]
 * @param {number} matchData.teammateRating - Rating of teammate (Rc) [0.5-7]
 * @param {number} matchData.adversary1Rating - Rating of adversary 1 [0.5-7]
 * @param {number} matchData.adversary2Rating - Rating of adversary 2 [0.5-7]
 * @param {number} matchData.pointsScored - Points scored by player's team
 * @param {number} matchData.teammateReliability - Reliability of teammate (Fc) [0-1]
 * @param {number} matchData.adversary1Reliability - Reliability of adversary 1 [0-1]
 * @param {number} matchData.adversary2Reliability - Reliability of adversary 2 [0-1]
 * @returns {number} New rating (Rn) [0.5-7]
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
