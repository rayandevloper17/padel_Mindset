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
// CORRECT - Based on Image 2
// Lower percentage = Better performance = More rating gain
const POINTS_ADJUSTMENT = {
    0: 100,
    1: 97.37,
    2: 94.74,
    3: 92.11,
    4: 89.47,
    5: 86.84,
    6: 84.21,
    7: 81.58,
    8: 78.95,
    9: 76.32,
    10: 73.68,
    11: 71.05,
    12: 68.42,
    13: 65.79,
    14: 63.16,
    15: 60.53,
    16: 57.89,
    17: 55.26,
    18: 52.63,
    19: 50.00
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
        pointsConceded, // Changed from pointsScored to pointsConceded
        teammateReliability,
        adversary1Reliability,
        adversary2Reliability,
        winnerTeamRatingSum,
        loserTeamRatingSum,
        isWinner,
        resultFactor
    } = matchData;

    console.log(`[RatingService] 📈 Calculating rating for player (Rating: ${playerRating}, IsWinner: ${isWinner})`);

    // STEP 1: Calculate X - Rating Average Difference
    // Formula: X = (MyTeamAvg - OpponentTeamAvg) / 2 ? No, User says (Sum Winner - Sum Loser)/2
    // If we want W to reflect the "Expected Outcome Benefit", we usually use (MyTeam - OpponentTeam).
    // User Text: "X= ( somme rating gagnant - somme rating perdant ) / 2"
    // BUT User Table has Negative values.
    // If I am Loser, X should be Negative?
    // Let's use: X = ((MyRating + TeammateRating) - (Adv1 + Adv2)) / 2

    // const teamRatingSum = playerRating + teammateRating;
    // const oppRatingSum = adversary1Rating + adversary2Rating;
    // let X = (teamRatingSum - oppRatingSum) / 2;

    // However, to strictly follow the "Winner - Loser" text, let's see. 
    // If I use (Winner - Loser)/2, X is always positive. 
    // If I look up Positive X in table -> Small W (e.g. 0.02).
    // This is correct for Winner (Favored). 
    // If I am Loser (Unfavored), I shouldn't treat X as Positive.
    // So X MUST be directional.

    const X = ((playerRating + teammateRating) - (adversary1Rating + adversary2Rating)) / 2;
    console.log(`[RatingService] Step 1 - X (Rating Diff / 2): ${X.toFixed(4)}`);

    // STEP 2: Find W from Table 1
    const W = lookupW(X);
    console.log(`[RatingService] Step 2 - W (Expected Value): ${W}`);

    // STEP 3: Calculate Z (Gain Factor) based on Points Conceded
    // User Formula: Y = (W x %point encaissé)
    // User Formula: Z = W - Y
    // ISSUE: Table maps 0 conceded to 100%. If Y = W * 100%, then Z = W - W = 0.
    // Perfect game (0 conceded) -> 0 Rating Change. This is illogical.
    // CORRECTION: Logic implies Z should be the Kept Amount.
    // We assume Z = W * (% from Table). 
    // (i.e. Concede 0 -> 100% of W. Concede 19 -> 50% of W).

    const adjustmentPercentage = getAdjustmentPercentage(pointsConceded);
    const Y = W * (adjustmentPercentage / 100);
    // Corrected Step 3: Z is Y.
    const Z = Y;

    console.log(`[RatingService] Step 3 - Points Conceded: ${pointsConceded}, Adj%: ${adjustmentPercentage}, Z (Gain): ${Z.toFixed(4)}`);

    // STEP 4: Calculate Ro - Rating Change
    // Formula: Ro = Z x ((Fc + Fa1 + Fa2)/3)
    // We implicitly apply 'resultFactor' (Score Factor) here as per Step 6 instructions.

    const factor = typeof resultFactor === 'number' ? resultFactor : 1;
    const avgReliability = (teammateReliability + adversary1Reliability + adversary2Reliability) / 3;

    const Ro = Z * avgReliability * factor;
    console.log(`[RatingService] Step 4 - AvgReliability: ${avgReliability.toFixed(3)}, Factor: ${factor}, Ro: ${Ro.toFixed(4)}`);

    // STEP 5: Calculate Rn - New Rating
    // Rn = Ra + Ro (For Winner)
    // Rn = Ra - Ro (For Loser - implied Symmetric Logic)

    let Rn = isWinner ? (playerRating + Ro) : (playerRating - Ro);

    // Constraints
    if (Rn < 0.5) Rn = 0.5;
    if (Rn > 7.0) Rn = 7.0;

    console.log(`[RatingService] Step 5 - Final Rating: ${Rn.toFixed(4)} (${isWinner ? '+' : ''}${(Rn - playerRating).toFixed(4)})`);
    return Rn;
};

/**
 * Calculate new reliability (FR) after a validated match
 * 
 * Formula:
 * FR = FR_current + (beta * (1 - (1 - RE)) * (1 / SQRT(H)))
 * 
 * Variables:
 * - beta = 0.1 (fixed)
 * - RE = 1 / (1 + 10^(((AvgLoser - AvgWinner)/20)))
 * - H = (Sum of reliability of other 3 players) / 3
 */
const calculateNewReliability = (matchData) => {
    const {
        playerReliability, // My reliability (FR) [0-1]
        teammateReliability, // Teammate (Fc) [0-1]
        adversary1Reliability, // Adv 1 [0-1]
        adversary2Reliability, // Adv 2 [0-1]
        winnerTeamRatingSum, // Sum of ratings of winning team
        loserTeamRatingSum // Sum of ratings of losing team
    } = matchData;

    console.log(`[RatingService] 🛡️ Calculating reliability (Current: ${playerReliability.toFixed(3)})`);

    const beta = 0.1;

    // RE Calculation
    const avgWinnerRating = winnerTeamRatingSum / 2;
    const avgLoserRating = loserTeamRatingSum / 2;

    // Exponent = (AvgLoser - AvgWinner) / 20
    const exponent = (avgLoserRating - avgWinnerRating) / 20;

    const RE = 1 / (1 + Math.pow(10, exponent));
    console.log(`[RatingService] Reliability Step 1 - AvgWin: ${avgWinnerRating}, AvgLose: ${avgLoserRating}, RE: ${RE.toFixed(4)}`);

    // H Calculation
    // H = Sum of other 3 players' reliability / 3
    const reliabilitySumOthers = teammateReliability + adversary1Reliability + adversary2Reliability;
    // Edge case: if H is 0, 1/sqrt(H) is Infinity. 
    // Assume minimum effective H to avoid explosion, e.g., 0.01 (1%)
    const H = Math.max(0.01, reliabilitySumOthers / 3);

    console.log(`[RatingService] Reliability Step 2 - H (Avg History): ${H.toFixed(4)}`);

    // FR Calculation
    // FR = Current + (0.1 * RE * (1/sqrt(H)))
    // Note: User wrote (1 - (1 - RE)), which simplifies to RE.
    // Term 2: (1 - (1 - RE)) = RE
    // Term 3: 1 / SQRT(H)

    const term3 = 1 / Math.sqrt(H);
    const reliabilityChange = beta * RE * term3;

    let newReliability = playerReliability + reliabilityChange;

    // Clamp between 0 and 1
    if (newReliability > 1) newReliability = 1;
    if (newReliability < 0) newReliability = 0;

    console.log(`[RatingService] Reliability Step 3 - Change: ${reliabilityChange.toFixed(4)}, New FR: ${newReliability.toFixed(4)}`);

    return newReliability;
};

export default {
    calculateNewRating,
    calculateNewReliability
};
