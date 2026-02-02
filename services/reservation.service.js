import { addNotification } from '../utils/notificationBus.js';
import { generateReservationCoder } from '../utils/codeGenerator.js';
import ratingService from './rating.service.js';
import { Op } from 'sequelize';

/**
 * ════════════════════════════════════════════════════════════════════════════════
 * RESERVATION SERVICE - FIXED: Proper Multi-Capacity Slot Management
 * ════════════════════════════════════════════════════════════════════════════════
 * 
 * CRITICAL FIX:
 * - Now properly checks CAPACITY vs RESERVATION COUNT
 * - A slot is only "full" when: active_reservations >= capacity
 * - Supports multiple concurrent users booking the same time slot
 * 
 * ════════════════════════════════════════════════════════════════════════════════
 */

export default function ReservationService(models) {

  // ════════════════════════════════════════════════════════════════════════════
  // UTILITY: Audit log for credit transactions
  // ════════════════════════════════════════════════════════════════════════════
  const logCreditTransaction = async (userId, amount, type, t) => {
    try {
      await models.credit_transaction.create({
        id_utilisateur: userId,
        nombre: amount,
        type,
        date_creation: new Date(),
      }, t ? { transaction: t } : undefined);
    } catch (err) {
      console.warn('[RefundService] Failed to write credit_transaction:', err?.message);
    }
  };

  // ════════════════════════════════════════════════════════════════════════════
  // UTILITY: Idempotent refund with duplicate prevention
  // ════════════════════════════════════════════════════════════════════════════
  const refundUserIdempotent = async (userId, amount, reservationId, participantId, t) => {
    if (!Number.isFinite(amount) || amount <= 0) {
      console.log(`[RefundService] Skip refund user ${userId} - invalid amount=${amount}`);
      return false;
    }

    const auditKey = `refund:R${reservationId}:U${userId}:P${participantId}`;

    // Check for duplicate refund
    const existing = await models.credit_transaction.findOne({
      where: { id_utilisateur: userId, type: auditKey },
      transaction: t,
      lock: t?.LOCK?.UPDATE,
    });

    if (existing) {
      console.log('[RefundService] Duplicate refund prevented for', auditKey);
      return false;
    }

    const user = await models.utilisateur.findByPk(userId, {
      transaction: t,
      lock: t?.LOCK?.UPDATE
    });

    if (!user) {
      console.log(`[RefundService] User ${userId} not found`);
      return false;
    }

    const currentBalance = Number(user.credit_balance ?? 0);
    const newBalance = currentBalance + amount;
    await user.update({ credit_balance: newBalance }, { transaction: t });
    await logCreditTransaction(userId, amount, auditKey, t);

    console.log(`[RefundService] Refunded user ${userId} amount=${amount} (${currentBalance} -> ${newBalance})`);
    return true;
  };

  // ════════════════════════════════════════════════════════════════════════════
  // UTILITY: Cancel ONLY other VALID matches when a new valid match is created
  // PENDING matches are NOT cancelled - they compete for remaining slots
  // ════════════════════════════════════════════════════════════════════════════
  const handleValidMatchCreated = async (plageHoraireId, date, newValidReservationId, creatorUserId, t, models) => {
    console.log('[ValidMatch] Valid match created -> Cancelling other VALID reservations ONLY', {
      plageHoraireId,
      date,
      newValidReservationId,
      creatorUserId
    });

    try {
      // Get the new reservation to determine its type
      const newReservation = await models.reservation.findByPk(newValidReservationId, {
        transaction: t,
        lock: t.LOCK.UPDATE
      });

      if (!newReservation) {
        console.log('[ValidMatch] New reservation not found');
        return;
      }

      const newReservationType = Number(newReservation.typer);

      // 🔥 CRITICAL FIX: Get the plage_horaire to find ALL sibling slots
      const plage = await models.plage_horaire.findByPk(plageHoraireId, {
        transaction: t,
        lock: t.LOCK.UPDATE
      });

      if (!plage) {
        console.log('[ValidMatch] Plage horaire not found');
        return;
      }

      // Get timestamp for comparison
      const getFullTimestamp = (timeVal) => {
        if (!timeVal) return null;
        if (typeof timeVal === 'string') return timeVal;
        const d = new Date(timeVal);
        return d.toISOString();
      };

      const startTimestamp = getFullTimestamp(plage.start_time);
      const endTimestamp = getFullTimestamp(plage.end_time);

      // Find ALL sibling slots (same terrain, same FULL timestamp)
      const allSiblingSlots = await models.sequelize.query(`
        SELECT id FROM plage_horaire
        WHERE terrain_id = :terrainId
          AND start_time = :startTime
          AND end_time = :endTime
      `, {
        replacements: {
          terrainId: plage.terrain_id,
          startTime: startTimestamp,
          endTime: endTimestamp
        },
        transaction: t,
        type: models.sequelize.QueryTypes.SELECT
      });

      const siblingSlotIds = allSiblingSlots.map(s => s.id);
      console.log(`[ValidMatch] Found ${siblingSlotIds.length} sibling slot IDs: [${siblingSlotIds.join(', ')}]`);

      // 🔥 NEW LOGIC: Only cancel other VALID (etat=1) reservations
      // PENDING (etat=0) reservations stay active and compete for remaining slots
      let whereClause = {
        id_plage_horaire: { [Op.in]: siblingSlotIds },
        date: date,
        isCancel: 0,
        etat: 1, // ← CRITICAL: Only cancel VALID matches!
        id: { [Op.ne]: newValidReservationId }
      };

      if (newReservationType === 1) {
        // PRIVATE match → Cancel ALL valid types
        console.log('[ValidMatch] PRIVATE match created → Cancelling other VALID reservation types');
      } else if (newReservationType === 2) {
        // OPEN match → Cancel only other VALID OPEN matches
        console.log('[ValidMatch] OPEN match became valid → Cancelling other VALID OPEN matches');
        whereClause.typer = 2;
      }

      // Find VALID reservations to cancel (NOT pending ones!)
      const reservationsToCancel = await models.reservation.findAll({
        where: whereClause,
        transaction: t,
        lock: t.LOCK.UPDATE
      });

      console.log(`[ValidMatch] Found ${reservationsToCancel.length} VALID reservation(s) to cancel (pending matches remain active)`);

      for (const reservation of reservationsToCancel) {
        console.log(`[ValidMatch] Cancelling VALID reservation ${reservation.id} (typer=${reservation.typer}, etat=${reservation.etat}, slot=${reservation.id_plage_horaire})`);

        // 1. Cancel the reservation
        await reservation.update({
          isCancel: 1,
          etat: -1,
          date_modif: new Date()
        }, { transaction: t });

        // 2. Find all participants
        const participants = await models.participant.findAll({
          where: { id_reservation: reservation.id },
          transaction: t,
          lock: t.LOCK.UPDATE
        });

        // 3. Build list of users to refund
        const usersToRefund = new Set();
        usersToRefund.add(reservation.id_utilisateur);
        participants.forEach(p => usersToRefund.add(p.id_utilisateur));

        // 4. Refund each user who paid
        for (const userId of usersToRefund) {
          // Check if user paid
          const userDebit = await models.credit_transaction.findOne({
            where: {
              id_utilisateur: userId,
              [Op.or]: [
                { type: `debit:reservation:R${reservation.id}:U${userId}:creator` },
                { type: { [Op.like]: `debit:join:R${reservation.id}:U${userId}%` } }
              ],
              nombre: { [Op.lt]: 0 }
            },
            transaction: t
          });

          if (userDebit) {
            await refundUserIdempotent(
              userId,
              reservation.prix_total,
              reservation.id,
              userId === reservation.id_utilisateur ? null : userId,
              t
            );
            console.log(`[ValidMatch] ✅ Refunded ${reservation.prix_total} to user ${userId}`);
          } else {
            console.log(`[ValidMatch] ℹ️  User ${userId} didn't pay - no refund needed`);
          }
        }

        // 5. Remove all participants
        if (participants.length > 0) {
          await models.participant.destroy({
            where: { id_reservation: reservation.id },
            transaction: t
          });
        }

        // 6. Send notifications to all affected users
        for (const userId of usersToRefund) {
          try {
            await addNotification(userId, {
              type: 'reservation_cancelled',
              title: 'Réservation annulée',
              message: `Votre réservation du ${date} a été annulée car un autre match a été confirmé.`,
              data: {
                cancelledReservationId: reservation.id,
                newReservationId: newValidReservationId
              }
            });
          } catch (err) {
            console.warn('[ValidMatch] Failed to send notification:', err);
          }
        }
      }

      console.log(`[ValidMatch] ✅ Successfully cancelled ${reservationsToCancel.length} VALID reservation(s). Pending reservations remain active.`);
    } catch (error) {
      console.error('[ValidMatch] Error during cancellation:', error);
      throw error;
    }
  };

  // ════════════════════════════════════════════════════════════════════════════
  // UTILITY: Cancel excess PENDING reservations when all slots are VALID
  // ════════════════════════════════════════════════════════════════════════════
  const cancelExcessPendingReservations = async (plageHoraireId, date, t, models) => {
    console.log('[ExcessCancel] Checking for excess pending reservations', {
      plageHoraireId,
      date
    });

    try {
      // Get the plage to find sibling slots
      const plage = await models.plage_horaire.findByPk(plageHoraireId, {
        transaction: t,
        lock: t.LOCK.UPDATE
      });

      if (!plage) {
        console.log('[ExcessCancel] Plage horaire not found');
        return;
      }

      // Get timestamp for comparison
      const getFullTimestamp = (timeVal) => {
        if (!timeVal) return null;
        if (typeof timeVal === 'string') return timeVal;
        const d = new Date(timeVal);
        return d.toISOString();
      };

      const startTimestamp = getFullTimestamp(plage.start_time);
      const endTimestamp = getFullTimestamp(plage.end_time);

      // Find ALL sibling slots (same terrain, same FULL timestamp)
      const allSiblingSlots = await models.sequelize.query(`
        SELECT id FROM plage_horaire
        WHERE terrain_id = :terrainId
          AND start_time = :startTime
          AND end_time = :endTime
      `, {
        replacements: {
          terrainId: plage.terrain_id,
          startTime: startTimestamp,
          endTime: endTimestamp
        },
        transaction: t,
        type: models.sequelize.QueryTypes.SELECT
      });

      const siblingSlotIds = allSiblingSlots.map(s => s.id);
      const totalCapacity = siblingSlotIds.length;

      console.log(`[ExcessCancel] Total capacity: ${totalCapacity} slots`);

      // Count VALID reservations
      const validReservations = await models.reservation.count({
        where: {
          id_plage_horaire: { [Op.in]: siblingSlotIds },
          date: date,
          isCancel: 0,
          etat: 1 // Valid matches
        },
        transaction: t
      });

      console.log(`[ExcessCancel] Valid reservations: ${validReservations}/${totalCapacity}`);

      // If all slots are full with valid matches, cancel ALL pending ones
      if (validReservations >= totalCapacity) {
        console.log('[ExcessCancel] All slots are full → Cancelling ALL pending reservations');

        // Find ALL pending reservations for this time
        const pendingReservations = await models.reservation.findAll({
          where: {
            id_plage_horaire: { [Op.in]: siblingSlotIds },
            date: date,
            isCancel: 0,
            etat: 0 // Pending only
          },
          transaction: t,
          lock: t.LOCK.UPDATE
        });

        console.log(`[ExcessCancel] Found ${pendingReservations.length} pending reservation(s) to cancel`);

        for (const reservation of pendingReservations) {
          console.log(`[ExcessCancel] Cancelling pending reservation ${reservation.id}`);

          // 1. Cancel the reservation
          await reservation.update({
            isCancel: 1,
            etat: -1,
            date_modif: new Date()
          }, { transaction: t });

          // 2. Find all participants
          const participants = await models.participant.findAll({
            where: { id_reservation: reservation.id },
            transaction: t,
            lock: t.LOCK.UPDATE
          });

          // 3. Build list of users to refund
          const usersToRefund = new Set();
          usersToRefund.add(reservation.id_utilisateur);
          participants.forEach(p => usersToRefund.add(p.id_utilisateur));

          // 4. Refund each user who paid
          for (const userId of usersToRefund) {
            const userDebit = await models.credit_transaction.findOne({
              where: {
                id_utilisateur: userId,
                [Op.or]: [
                  { type: `debit:reservation:R${reservation.id}:U${userId}:creator` },
                  { type: { [Op.like]: `debit:join:R${reservation.id}:U${userId}%` } }
                ],
                nombre: { [Op.lt]: 0 }
              },
              transaction: t
            });

            if (userDebit) {
              await refundUserIdempotent(
                userId,
                reservation.prix_total,
                reservation.id,
                userId === reservation.id_utilisateur ? null : userId,
                t
              );
              console.log(`[ExcessCancel] ✅ Refunded ${reservation.prix_total} to user ${userId}`);
            }
          }

          // 5. Remove all participants
          if (participants.length > 0) {
            await models.participant.destroy({
              where: { id_reservation: reservation.id },
              transaction: t
            });
          }

          // 6. Send notifications
          for (const userId of usersToRefund) {
            try {
              await addNotification(userId, {
                type: 'reservation_cancelled',
                title: 'Réservation annulée',
                message: `Votre réservation du ${date} a été annulée car tous les créneaux sont maintenant complets.`,
                data: {
                  cancelledReservationId: reservation.id,
                  reason: 'all_slots_full'
                }
              });
            } catch (err) {
              console.warn('[ExcessCancel] Failed to send notification:', err);
            }
          }
        }

        console.log(`[ExcessCancel] ✅ Successfully cancelled ${pendingReservations.length} pending reservation(s)`);
      } else {
        console.log(`[ExcessCancel] Slots not full yet (${validReservations}/${totalCapacity}) - pending reservations remain active`);
      }
    } catch (error) {
      console.error('[ExcessCancel] Error during excess cancellation:', error);
      throw error;
    }
  };

  // ════════════════════════════════════════════════════════════════════════════
  // 🔥 FIXED: Check if a slot has available capacity with PROPER LOCKING
  // ════════════════════════════════════════════════════════════════════════════
  const hasAvailableCapacity = async (plageHoraireId, date, t) => {
    // Get the plage_horaire to check its capacity
    const plage = await models.plage_horaire.findByPk(plageHoraireId, {
      transaction: t,
      lock: t.LOCK.UPDATE
    });

    if (!plage) {
      return false;
    }

    // Get capacity (default to 1 if not set)
    const capacity = Number(plage.capacity ?? 1);

    // 🔥 CRITICAL FIX: Lock ONLY VALID reservations for this slot+date
    // PENDING reservations (etat=0) don't count towards capacity!
    const existingReservations = await models.reservation.findAll({
      where: {
        id_plage_horaire: plageHoraireId,
        date: date,
        isCancel: 0,
        etat: 1
      },
      transaction: t,
      lock: t.LOCK.UPDATE
    });

    const activeReservations = existingReservations.length;
    const available = activeReservations < capacity;

    console.log(`[Capacity Check] Slot ${plageHoraireId} on ${date}: ${activeReservations}/${capacity} valid reservations - Available: ${available}`);

    return available;
  };

  // ════════════════════════════════════════════════════════════════════════════
  // MAIN: Create Reservation with Smart Capacity & Race Condition Protection
  // ════════════════════════════════════════════════════════════════════════════
  // ════════════════════════════════════════════════════════════════════════════
  // RATING: Update player ratings after match confirmation
  // ════════════════════════════════════════════════════════════════════════════
  const updatePlayerRatings = async (reservationId) => {
    try {
      console.log(`[RatingService] 🏁 Starting rating updates for reservation ${reservationId}`);

      const reservation = await models.reservation.findByPk(reservationId, {
        include: [{
          model: models.participant,
          as: 'participants',
          include: [{
            model: models.utilisateur,
            as: 'utilisateur'
          }]
        }]
      });

      if (!reservation) {
        console.error(`[RatingService] Reservation ${reservationId} not found`);
        return;
      }

      const participants = reservation.participants || [];
      if (participants.length < 4) {
        console.warn(`[RatingService] Match ${reservationId} has fewer than ${participants.length}/4 participants. Rating calculation skipped.`);
        return;
      }

      // 1. Map participants to teams (0,1 vs 2,3)
      const pMap = {};
      participants.forEach(p => {
        if (p.team !== null && p.team !== undefined) {
          pMap[p.team] = p;
        }
      });

      const a1 = pMap[0];
      const a2 = pMap[1];
      const b1 = pMap[2];
      const b2 = pMap[3];

      if (!a1 || !a2 || !b1 || !b2) {
        console.warn(`[RatingService] Missing participants in team slots (found: ${Object.keys(pMap).join(',')}). Rating update aborted.`);
        return;
      }

      // 2. Calculate games won by each team
      const teamAGames = (reservation.Set1A || 0) + (reservation.Set2A || 0) + (reservation.Set3A || 0);
      const teamBGames = (reservation.Set1B || 0) + (reservation.Set2B || 0) + (reservation.Set3B || 0);

      const players = [a1, a2, b1, b2];

      // 3. Update each player
      for (let i = 0; i < 4; i++) {
        const player = players[i];
        const user = player.utilisateur;
        if (!user) continue;

        const isTeamA = i < 2;
        const teammate = isTeamA ? (i === 0 ? a2 : a1) : (i === 2 ? b2 : b1);
        const opponents = isTeamA ? [b1, b2] : [a1, a2];

        const matchData = {
          playerRating: Number(user.note) || 0.5,
          teammateRating: Number(teammate.utilisateur?.note) || 0.5,
          adversary1Rating: Number(opponents[0].utilisateur?.note) || 0.5,
          adversary2Rating: Number(opponents[1].utilisateur?.note) || 0.5,
          pointsScored: isTeamA ? teamAGames : teamBGames,
          teammateReliability: (Number(teammate.utilisateur?.fiability) || 50) / 100,
          adversary1Reliability: (Number(opponents[0].utilisateur?.fiability) || 50) / 100,
          adversary2Reliability: (Number(opponents[1].utilisateur?.fiability) || 50) / 100
        };

        const newRating = ratingService.calculateNewRating(matchData);

        // Update user rating in DB
        await user.update({ note: newRating });
        console.log(`[RatingService] ✅ User ${user.id} (${user.nom}) rating updated: ${matchData.playerRating.toFixed(2)} -> ${newRating.toFixed(2)}`);
      }

    } catch (error) {
      console.error('[RatingService] ❌ Failed to update player ratings:', error);
    }
  };

  const create = async (data) => {
    const t = await models.sequelize.transaction({
      isolationLevel: models.Sequelize.Transaction.ISOLATION_LEVELS.READ_COMMITTED
    });

    try {
      console.log('[ReservationService] Starting reservation creation', {
        userId: data.id_utilisateur,
        slotId: data.id_plage_horaire,
        date: data.date,
        typer: data.typer
      });

      // ══════════════════════════════════════════════════════════════════════
      // STEP 1: Validate terrain exists
      // ══════════════════════════════════════════════════════════════════════
      const terrain = await models.terrain.findByPk(data.id_terrain, { transaction: t });
      if (!terrain) {
        throw new Error("Terrain not found");
      }

      // ══════════════════════════════════════════════════════════════════════
      // STEP 2: Lock user row for balance operations
      // ══════════════════════════════════════════════════════════════════════
      const utilisateur = await models.utilisateur.findByPk(data.id_utilisateur, {
        transaction: t,
        lock: t.LOCK.UPDATE
      });
      if (!utilisateur) {
        throw new Error("Utilisateur not found");
      }

      // ══════════════════════════════════════════════════════════════════════
      // STEP 3: CRITICAL - Lock the requested plage_horaire row
      // ══════════════════════════════════════════════════════════════════════
      let plage = await models.plage_horaire.findByPk(data.id_plage_horaire, {
        transaction: t,
        lock: t.LOCK.UPDATE
      });

      if (!plage) {
        throw new Error("Plage horaire not found");
      }

      console.log('[ReservationService] Acquired lock on plage_horaire', {
        id: plage.id,
        disponible: plage.disponible,
        capacity: plage.capacity ?? 1
      });

      // ══════════════════════════════════════════════════════════════════════
      // STEP 4: 🔥 FIXED - SMART SLOT REASSIGNMENT (Proper Capacity Handling)
      // ══════════════════════════════════════════════════════════════════════

      // Check if the requested slot has available capacity
      const hasCapacity = await hasAvailableCapacity(plage.id, data.date, t);

      if (!hasCapacity) {
        console.log(`[ReservationService] ⚠️ Slot ${plage.id} is at capacity. Searching for siblings...`);

        // Extract FULL timestamp for comparison (including date!)
        const getFullTimestamp = (timeVal) => {
          if (!timeVal) return null;
          // Return as-is if already a string
          if (typeof timeVal === 'string') return timeVal;
          // If it's a Date object, convert to ISO string
          const d = new Date(timeVal);
          return d.toISOString();
        };

        const startTimestamp = getFullTimestamp(plage.start_time);
        const endTimestamp = getFullTimestamp(plage.end_time);

        console.log(`[ReservationService] 🔍 Looking for: terrain_id=${plage.terrain_id}, start_time=${startTimestamp}, end_time=${endTimestamp}`);

        // 🔥 FIX: Match FULL timestamp (date + time), not just time!
        const siblings = await models.sequelize.query(`
          SELECT * FROM plage_horaire
          WHERE terrain_id = :terrainId
            AND id != :currentId
            AND start_time = :startTime
            AND end_time = :endTime
          FOR UPDATE
        `, {
          replacements: {
            terrainId: plage.terrain_id,
            currentId: plage.id,
            startTime: startTimestamp,
            endTime: endTimestamp
          },
          transaction: t,
          type: models.sequelize.QueryTypes.SELECT
        });

        console.log(`[ReservationService] 🔍 Found ${siblings.length} sibling slot(s): [${siblings.map(s => s.id).join(', ')}]`);

        let freeSiblingFound = false;

        // Check each sibling for available capacity
        for (const sibling of siblings) {
          const siblingHasCapacity = await hasAvailableCapacity(sibling.id, data.date, t);

          console.log(`[ReservationService] 🔍 Checking sibling ${sibling.id}: hasCapacity=${siblingHasCapacity}`);

          if (siblingHasCapacity) {
            // Found a slot with available capacity! Switch to it.
            console.log(`[ReservationService] ✅ Switching to sibling slot with capacity: ${sibling.id}`);

            // Re-fetch as model instance with lock
            plage = await models.plage_horaire.findByPk(sibling.id, {
              transaction: t,
              lock: t.LOCK.UPDATE
            });

            data.id_plage_horaire = sibling.id; // Update payload ID
            freeSiblingFound = true;
            break; // Stop searching
          }
        }

        if (!freeSiblingFound) {
          console.log(`[ReservationService] ❌ All ${siblings.length + 1} slot(s) for this time are at full capacity.`);
          const error = new Error('Tous les créneaux pour cette heure sont complets. Veuillez choisir une autre heure.');
          error.statusCode = 409;
          throw error;
        }
      } else {
        console.log(`[ReservationService] ✅ Slot ${plage.id} has available capacity.`);
      }

      // ══════════════════════════════════════════════════════════════════════
      // STEP 5: Validate and normalize price
      // ══════════════════════════════════════════════════════════════════════
      const plagePrice = Number(plage?.price);
      const normalizedPrice = Number.isFinite(plagePrice) && plagePrice > 0
        ? plagePrice
        : 1;

      const typerVal = Number(data?.typer ?? 0);

      // ══════════════════════════════════════════════════════════════════════
      // STEP 6: Validate rating range for open matches
      // ══════════════════════════════════════════════════════════════════════
      if (typerVal === 2) {
        const minFloat = Number(data?.min);
        const maxFloat = Number(data?.max);

        if (!Number.isFinite(minFloat) || !Number.isFinite(maxFloat)) {
          throw new Error('Rating range (min/max) is required for Match Ouvert');
        }

        if (minFloat > maxFloat) {
          throw new Error('Invalid rating range: min must be <= max');
        }
      }

      // ════════════════════════════════════════════════════════════════════════════════
      // STEP 7: Handle payment and balance deduction (WITH MEMBERSHIP LOGIC)
      // ════════════════════════════════════════════════════════════════════════════════

      // 🔥 FIX: More robust payment type detection
      const creatorPayType = (() => {
        if (data.typepaiementForCreator !== undefined && data.typepaiementForCreator !== null) {
          return Number(data.typepaiementForCreator);
        }
        if (data.typepaiement !== undefined && data.typepaiement !== null) {
          return Number(data.typepaiement);
        }
        return 1; // Default to credit
      })();

      const etatVal = Number(data?.etat ?? -1);
      const isOnsitePayment = (creatorPayType === 2) || (etatVal === 0);
      const shouldSkipDeduction = (typerVal === 1) && isOnsitePayment;

      // 👑 MEMBERSHIP LOGIC 👑
      // Fetch user's active membership
      // Pass match date to check for daily limits
      // We need to import membershipService logic or replicate it here. 
      // For cleaner architecture, we should rely on the membership service instance if available,
      // but here we are using models directly. 
      // We'll use the checkMembershipExpiry helper from our new membership service logic.
      // Since we don't have the membershipService instance injected here clearly, 
      // we'll instantiate it or assume we can use the logic.
      // Ideally, we should use: const { checkMembershipExpiry } = MembershipService(models);

      // Let's assume we can access the logic. To be safe and self-contained within this file 
      // without big refactors, I will verify the membership manually here OR better:
      // use the logic we just added to membership service if I can require it.
      // Actually, standard pattern in this codebase seems to be direct model access.
      // However, checkMembershipExpiry is quite complex now.

      // Let's implement the daily check locally here to avoid import circles or injection issues,
      // closely mirroring the membership service logic.

      const membership = await models.membership.findOne({
        where: {
          id_user: data.id_utilisateur,
          dateend: { [Op.gte]: new Date() } // Active only
        },
        transaction: t
      });

      let membershipType = Number(membership?.typemmbership ?? 0);
      let membershipDiscount = 0;
      let isFree = false;
      let limitReached = false;

      // Check daily limit for Infinity (Type 4)
      if (membershipType === 4 && data.date) {
        try {
          // Count participations for this user on this date
          // We need to include cancellations check logic properly
          const count = await models.participant.count({
            where: {
              id_utilisateur: data.id_utilisateur
            },
            include: [{
              model: models.reservation,
              as: 'reservation',
              where: {
                date: data.date,
                isCancel: 0
              }
            }],
            transaction: t
          });

          if (count > 0) {
            console.log(`[ReservationService] 👑 User ${data.id_utilisateur} (Infinity) already has ${count} match(es) on ${data.date}. Daily limit reached.`);
            limitReached = true;
            // Downgrade to Normal for this transaction
            membershipType = 0;
          }
        } catch (e) {
          console.error('[ReservationService] Error checking daily limit:', e);
        }
      }

      if (membershipType === 4) { // Infinity
        isFree = true;
        console.log(`[ReservationService] 👑 User ${data.id_utilisateur} has INFINITY membership - Match is FREE`);
      } else if (membershipType === 1 || membershipType === 2 || membershipType === 3) { // Access (1), Gold (2) or Platinum (3)
        membershipDiscount = 300;
        console.log(`[ReservationService] 👑 User ${data.id_utilisateur} has Access/Gold/Platinum - Discount: ${membershipDiscount} DA`);
      }

      if (limitReached) {
        console.log(`[ReservationService] ℹ️ Membership daily limit applied. User treated as Normal.`);
      }

      console.log(`[ReservationService] 💳 Payment detection:`, {
        typepaiementForCreator: data.typepaiementForCreator,
        creatorPayType,
        isOnsitePayment,
        membershipType,
        isFree,
        membershipDiscount,
        limitReached
      });

      // Store the charge amount for later use
      let creatorCharge = 0;
      let totalChargeToDeduct = 0; // Total to deduct from balance
      let isPayForAll = false;

      // Check for Pay For All flag
      if (data.payForAll === true || data.payForAll === 'true' || data.payForAll === 1 ||
        data.ispayed === true || data.ispayed === 'true' || data.ispayed === 1) {
        isPayForAll = true;
        console.log(`[ReservationService] 💸 "Pay for All" selected by user ${data.id_utilisateur}`);
      }

      if (!shouldSkipDeduction && !isFree) {
        // Apply discount if applicable
        let finalPrice = normalizedPrice - membershipDiscount;
        if (finalPrice < 0) finalPrice = 0;

        creatorCharge = finalPrice;
      } else if (isFree && !shouldSkipDeduction) {
        // Infinity members don't pay, but effectively "charge" is 0
        creatorCharge = 0;
      }

      // Calculate Total Charge (Creator + 3 others if PayForAll)
      if (isPayForAll && !shouldSkipDeduction) {
        // Pay for 3 additional slots at standard price (normalizedPrice)
        // Others don't get creator's discount
        const extraSlotsCost = 3 * normalizedPrice;

        totalChargeToDeduct = creatorCharge + extraSlotsCost;
        console.log(`[ReservationService] 🧾 Pay For All Calculation: Creator(${creatorCharge}) + 3xStandard(${extraSlotsCost}) = ${totalChargeToDeduct}`);
      } else {
        totalChargeToDeduct = creatorCharge;
      }

      // Check balance
      if (!shouldSkipDeduction && totalChargeToDeduct > 0) {
        const currentBalance = Number(utilisateur.credit_balance ?? 0);

        if (!Number.isFinite(currentBalance) || currentBalance < totalChargeToDeduct) {
          throw new Error(`Solde insuffisant pour "Payer pour tous" (Requis: ${totalChargeToDeduct}, Actuel: ${currentBalance})`);
        }

        await utilisateur.update(
          { credit_balance: currentBalance - totalChargeToDeduct },
          { transaction: t }
        );
      } else {
        // Just for logging or if skipping deduction
        totalChargeToDeduct = 0;
      }

      // ══════════════════════════════════════════════════════════════════════
      // STEP 8: FINAL VALIDATION - Prevent double-booking same slot
      // ══════════════════════════════════════════════════════════════════════

      // 🔥 CRITICAL: Re-check capacity one more time RIGHT before creating
      // This prevents race condition where another user books between STEP 4 and now
      const finalCapacityCheck = await hasAvailableCapacity(plage.id, data.date, t);

      if (!finalCapacityCheck) {
        console.log(`[ReservationService] ⚠️ RACE CONDITION: Slot ${plage.id} was just filled by another user`);
        const error = new Error('Ce créneau vient d\'être réservé par un autre joueur. Veuillez rafraîchir.');
        error.statusCode = 409;
        throw error;
      }

      // ══════════════════════════════════════════════════════════════════════
      // STEP 9: Create the reservation
      // ══════════════════════════════════════════════════════════════════════
      
      // Generate a truly unique coder in the backend
      let uniqueCoder;
      let isUnique = false;
      let attempts = 0;
      
      while (!isUnique && attempts < 10) {
        uniqueCoder = generateReservationCoder();
        const existing = await models.reservation.findOne({ 
          where: { coder: uniqueCoder },
          transaction: t
        });
        if (!existing) isUnique = true;
        attempts++;
      }

      // If PayForAll, store the TOTAL amount paid in prix_total so refunds work easily
      // Also set ispayed = 1
      const payload = {
        ...data,
        coder: uniqueCoder, // Override any frontend-provided coder
        prix_total: isPayForAll ? totalChargeToDeduct : normalizedPrice, // Store actual unit cost or total? Cancel logic uses this.
        // Wait, if I store totalChargeToDeduct (e.g. 4000), and I join. 
        // Join logic sees "prix_total". 
        // If PayForAll is OFF, prix_total is 1000. Joiner pays 1000.
        // If PayForAll is ON, prix_total is 4000. Joiner SHOULD pay 0.
        // IsPayed = 1 logic will handle the 0 charge.
        // Refund logic uses prix_total. So storing 4000 here is CORRECT for refunding the creator.
        ispayed: isPayForAll ? 1 : 0
      };

      // NOTE: If PayForAll is false, prix_total is normalizedPrice (1000).
      // Refund refunds 1000 to creator. Correct.
      // If PayForAll is true, prix_total is 4000 (approx). 
      // Refund refunds 4000 to creator. Correct.

      let reservation;
      try {
        reservation = await models.reservation.create(payload, { transaction: t });
        console.log('[ReservationService] ✅ Created reservation', { id: reservation.id, slotId: plage.id, isPayForAll });

        // Record the credit_transaction AFTER reservation is created
        // ONLY log if actual charge > 0
        if (!shouldSkipDeduction && totalChargeToDeduct > 0) {
          await models.credit_transaction.create({
            id_utilisateur: data.id_utilisateur,
            nombre: -totalChargeToDeduct,
            type: `debit:reservation:R${reservation.id}:U${data.id_utilisateur}:creator`, // Same type key, but amount is larger
            date_creation: new Date()
          }, { transaction: t });

          // Notification: Credit Deduction
          await addNotification({
            recipient_id: data.id_utilisateur,
            reservation_id: reservation.id,
            type: 'credit_deduction',
            message: `Votre réservation a été confirmée. ${totalChargeToDeduct} crédits ont été débités.`
          });
        }

        // Notification: Reservation Confirmation
        await addNotification({
          recipient_id: data.id_utilisateur,
          reservation_id: reservation.id,
          type: 'reservation_confirmed',
          message: `Votre réservation pour le ${data.date} a été confirmée avec succès.`
        });

      } catch (insertError) {
        // Handle unique constraint violation
        if (insertError.name === 'SequelizeUniqueConstraintError' ||
          insertError.parent?.code === '23505') {
          console.log('[ReservationService] ❌ Unique constraint violation detected!');
          console.log('[ReservationService] This indicates a database constraint issue.');
          console.log('[ReservationService] Please run FIX_DATABASE_CONSTRAINT.sql to fix this.');

          const error = new Error('Cette réservation existe déjà. Veuillez choisir un autre créneau ou actualiser la page.');
          error.statusCode = 409;
          throw error;
        }

        if (insertError.name === 'SequelizeDatabaseError' || insertError.message?.includes('deadlock')) {
          const error = new Error('Ce créneau vient d\'être réservé par un autre joueur. Veuillez rafraîchir.');
          error.statusCode = 409;
          throw error;
        }

        throw insertError;
      }

      // ══════════════════════════════════════════════════════════════════════
      // STEP 10: Check if all slots are full and cancel excess pending
      // ══════════════════════════════════════════════════════════════════════

      // Check if we created a VALID match (private with credit)
      const isPrivateWithCredit = (typerVal === 1) && (creatorPayType === 1);

      if (isPrivateWithCredit) {
        // Private match is valid immediately (etat=1)
        // Each valid match takes ONE slot only
        // NO need to cancel other valid matches - they can coexist!

        console.log('[ReservationService] Created VALID private match → Checking if all slots full');

        // Only check if all slots are now full
        // If yes, cancel remaining PENDING reservations
        await cancelExcessPendingReservations(
          data.id_plage_horaire,
          data.date,
          t,
          models
        );
      }

      // ══════════════════════════════════════════════════════════════════════
      // STEP 11: Update slot availability
      // ══════════════════════════════════════════════════════════════════════

      // 🔍 DIAGNOSTIC LOGGING
      console.log(`[ReservationService] 🔍 Availability check:`, {
        typerVal,
        creatorPayType,
        etatVal,
        isOnsitePayment,
        shouldMarkUnavailable: typerVal === 1 && !isOnsitePayment
      });

      // For PRIVATE matches with CREDIT payment: Mark slot as unavailable immediately
      if (typerVal === 1 && !isOnsitePayment) {
        // Private match + Credit payment → Slot is now taken
        await plage.update({ disponible: false }, { transaction: t });
        console.log(`[ReservationService] 🔒 Slot ${plage.id} marked as unavailable (private + credit)`);
      } else if (typerVal !== 2 && !isOnsitePayment) {
        // For other cases: Check if this slot is now at full capacity
        const nowAtCapacity = !(await hasAvailableCapacity(plage.id, data.date, t));

        if (nowAtCapacity) {
          await plage.update({ disponible: false }, { transaction: t });
          console.log(`[ReservationService] 🔒 Slot ${plage.id} marked as unavailable (at capacity)`);
        }
      } else {
        console.log(`[ReservationService] ℹ️ Slot ${plage.id} kept available (typer=${typerVal}, onsite=${isOnsitePayment})`);
      }

      // ══════════════════════════════════════════════════════════════════════
      // STEP 12: Create participant record for creator
      // ══════════════════════════════════════════════════════════════════════
      await models.participant.create({
        id_reservation: reservation.id,
        id_utilisateur: data.id_utilisateur,
        est_createur: true,
        statepaiement: shouldSkipDeduction ? 0 : 1,
        typepaiement: shouldSkipDeduction ? 2 : 1,
        team: 0,
      }, { transaction: t });

      // ══════════════════════════════════════════════════════════════════════
      // STEP 13: COMMIT - Release all locks
      // ══════════════════════════════════════════════════════════════════════
      await t.commit();
      console.log('[ReservationService] Transaction committed successfully');

      // Return reservation with all includes
      const finalReservation = await models.reservation.findByPk(reservation.id, {
        include: [
          { model: models.terrain, as: 'terrain' },
          { model: models.utilisateur, as: 'utilisateur' },
          { model: models.plage_horaire, as: 'plage_horaire' },
          { model: models.participant, as: 'participants' },
        ]
      });

      return finalReservation;

    } catch (err) {
      await t.rollback();
      console.error('[ReservationService] Transaction rolled back:', err.message);

      if (err.name === 'SequelizeDatabaseError' || err.message?.includes('deadlock')) {
        const error = new Error('Ce créneau vient d\'être réservé par un autre joueur. Veuillez rafraîchir.');
        error.statusCode = 409;
        throw error;
      }

      if (err.statusCode) {
        throw err;
      }
      throw err;
    }
  };

  const findAll = async () => {
    return await models.reservation.findAll({
      include: [
        { model: models.terrain, as: 'terrain' },
        { model: models.utilisateur, as: 'utilisateur' },
        { model: models.plage_horaire, as: 'plage_horaire' }
      ]
    });
  };

  const findById = async (id) => {
    return await models.reservation.findByPk(id, {
      include: [
        { model: models.terrain, as: 'terrain' },
        { model: models.utilisateur, as: 'utilisateur' },
        { model: models.plage_horaire, as: 'plage_horaire' }
      ]
    });
  };

  const findByUserId = async (userId) => {
    try {
      const createdReservations = await models.reservation.findAll({
        where: { id_utilisateur: userId },
        include: [
          { model: models.terrain, as: 'terrain' },
          { model: models.utilisateur, as: 'utilisateur' },
          { model: models.plage_horaire, as: 'plage_horaire' },
          { model: models.participant, as: 'participants' }
        ],
        order: [['date_creation', 'DESC']]
      });

      const participantRecords = await models.participant.findAll({
        where: { id_utilisateur: userId },
        attributes: ['id_reservation']
      });

      const participantReservationIds = [...new Set(participantRecords.map(p => p.id_reservation))];
      const createdIds = new Set(createdReservations.map(r => r.id));
      const additionalIds = participantReservationIds.filter(id => !createdIds.has(id));

      let additionalReservations = [];
      if (additionalIds.length > 0) {
        additionalReservations = await models.reservation.findAll({
          where: { id: additionalIds },
          include: [
            { model: models.terrain, as: 'terrain' },
            { model: models.utilisateur, as: 'utilisateur' },
            { model: models.plage_horaire, as: 'plage_horaire' },
            { model: models.participant, as: 'participants' }
          ],
          order: [['date_creation', 'DESC']]
        });
      }

      const allReservations = [...createdReservations, ...additionalReservations];
      allReservations.sort((a, b) => new Date(b.date_creation || 0) - new Date(a.date_creation || 0));
      return allReservations;
    } catch (err) {
      console.error('[findByUserId] Error:', err?.message);
      throw err;
    }
  };

  const findOne = async (filter) => {
    return await models.reservation.findOne({
      where: filter,
      include: [
        { model: models.terrain, as: 'terrain' },
        { model: models.utilisateur, as: 'utilisateur' },
        { model: models.plage_horaire, as: 'plage_horaire' }
      ]
    });
  };

  const findByDate = async (dateStr) => {
    return await models.reservation.findAll({
      where: { date: dateStr },
      include: [
        { model: models.terrain, as: 'terrain' },
        { model: models.utilisateur, as: 'utilisateur' },
        { model: models.plage_horaire, as: 'plage_horaire' },
        { model: models.participant, as: 'participants' },
      ],
      order: [['date', 'ASC']]
    });
  };

  const findAvailableByDate = async (dateStr) => {
    const rows = await models.reservation.findAll({
      where: { date: dateStr },
      include: [
        { model: models.terrain, as: 'terrain' },
        { model: models.utilisateur, as: 'utilisateur' },
        { model: models.plage_horaire, as: 'plage_horaire' },
        { model: models.participant, as: 'participants' },
      ],
      order: [['date', 'ASC']]
    });

    return rows.filter((r) => {
      const typerVal = Number.parseInt((r.typer ?? 0).toString());
      const count = Array.isArray(r.participants) ? r.participants.length : 0;
      const isCancelled = Number(r.isCancel ?? 0) === 1;
      return typerVal === 2 && !isCancelled && count < 4;
    });
  };

  // ════════════════════════════════════════════════════════════════════════════
  // UPDATE OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  const update = async (id, data) => {
    const reservation = await models.reservation.findByPk(id);
    if (!reservation) throw new Error("Reservation not found");

    const isStatusUpdateToValid = data.etat === 'valid' && reservation.etat !== 'valid';
    const isOpenMatch = reservation.typer === 2;

    if (isStatusUpdateToValid && isOpenMatch) {
      const plage = await models.plage_horaire.findByPk(reservation.id_plage_horaire);
      if (plage) {
        await plage.update({ disponible: false });
      }
    }

    await reservation.update(data);
    return await findById(id);
  };

  const remove = async (id) => {
    const reservation = await models.reservation.findByPk(id);
    if (!reservation) throw new Error("Reservation not found");
    return await reservation.destroy();
  };

  // ════════════════════════════════════════════════════════════════════════════
  // CANCEL OPERATION (with proper locking)
  // ════════════════════════════════════════════════════════════════════════════

  const cancel = async (id, cancellingUserId) => {
    const t = await models.sequelize.transaction();

    try {
      console.log(`💰 [CancelService] Starting cancellation for reservation ${id}`);

      const reservation = await models.reservation.findByPk(id, {
        transaction: t,
        lock: t.LOCK.UPDATE
      });

      if (!reservation) {
        throw new Error('Reservation not found');
      }

      if (Number(reservation.isCancel ?? 0) === 1) {
        await t.commit();
        return reservation;
      }

      // 24-Hour Policy Check
      const now = new Date();
      const matchStartTime = reservation.date;
      if (matchStartTime && now < matchStartTime) {
        const hoursUntilMatch = Math.floor((matchStartTime - now) / (1000 * 60 * 60));
        if (hoursUntilMatch <= 24) {
          const error = new Error('Annulation non autorisée : moins de 24 heures avant le match.');
          error.statusCode = 409;
          throw error;
        }
      }

      const plage = reservation.id_plage_horaire
        ? await models.plage_horaire.findByPk(reservation.id_plage_horaire, {
          transaction: t,
          lock: t.LOCK.UPDATE
        })
        : null;

      const participants = await models.participant.findAll({
        where: { id_reservation: id },
        transaction: t,
        lock: t.LOCK.UPDATE,
      });

      const creatorParticipant = participants.find(p => Boolean(p.est_createur));
      const isCancellerCreator = !!creatorParticipant &&
        Number(creatorParticipant.id_utilisateur) === Number(cancellingUserId);

      const slotPrice = (() => {
        const p = Number(plage?.price ?? reservation.prix_total ?? 0);
        return Number.isFinite(p) && p > 0 ? p : 0;
      })();

      // Refund helper
      const refundUser = async (userId, amount) => {
        if (!Number.isFinite(amount) || amount <= 0) return;
        const user = await models.utilisateur.findByPk(userId, { transaction: t, lock: t.LOCK.UPDATE });
        if (user) {
          await user.update({ credit_balance: (user.credit_balance ?? 0) + amount }, { transaction: t });
          await logCreditTransaction(userId, amount, `refund:cancel:R${id}`, t);
        }
      };

      if (isCancellerCreator) {
        // Creator cancels - Refund EVERYONE and FREE THE SLOT
        for (const p of participants) {
          if (Number(p.statepaiement) === 1) {
            // 🔥 CRITICAL FIX: Check if user ACTUALLY paid before refunding
            // Verify debit transaction exists
            const userDebit = await models.credit_transaction.findOne({
              where: {
                id_utilisateur: p.id_utilisateur,
                [Op.or]: [
                  { type: `debit:reservation:R${reservation.id}:U${p.id_utilisateur}:creator` },
                  { type: { [Op.like]: `debit:join:R${reservation.id}:U${p.id_utilisateur}%` } }
                ],
                nombre: { [Op.lt]: 0 }
              },
              transaction: t
            });

            if (userDebit) {
              await refundUser(p.id_utilisateur, Math.abs(Number(userDebit.nombre)));
            } else {
              console.log(`[CancelService] ℹ️ User ${p.id_utilisateur} did not pay (Infinity/Onsite) - No refund.`);
            }
          }
        }

        await reservation.update({ isCancel: 1, etat: 3, date_modif: new Date() }, { transaction: t });

        // Notify others
        for (const p of participants) {
          if (Number(p.id_utilisateur) !== Number(cancellingUserId)) {
            await addNotification({
              recipient_id: p.id_utilisateur,
              reservation_id: reservation.id,
              type: 'reservation_cancelled',
              message: 'Le créateur du match a annulé la réservation.'
            });
          }
        }

        await models.participant.destroy({ where: { id_reservation: id }, transaction: t });

        // 🔥 FIXED: Re-enable slot if it now has capacity
        if (plage) {
          const stillHasCapacity = await hasAvailableCapacity(plage.id, reservation.date, t);
          if (stillHasCapacity) {
            await plage.update({ disponible: true }, { transaction: t });
            console.log(`[CancelService] ✅ Slot ${plage.id} re-enabled (has capacity after cancellation)`);
          }
        }

      } else {
        // Participant leaves - Refund ONLY them
        const cancellerParticipant = participants.find(p => Number(p.id_utilisateur) === Number(cancellingUserId));
        if (!cancellerParticipant) throw new Error('User is not a participant');

        if (Number(cancellerParticipant.statepaiement) === 1) {
          // 🔥 CRITICAL FIX: Check if user ACTUALLY paid before refunding
          const userDebit = await models.credit_transaction.findOne({
            where: {
              id_utilisateur: cancellingUserId,
              [Op.or]: [
                { type: `debit:reservation:R${reservation.id}:U${cancellingUserId}:creator` },
                { type: { [Op.like]: `debit:join:R${reservation.id}:U${cancellingUserId}%` } }
              ],
              nombre: { [Op.lt]: 0 }
            },
            transaction: t
          });

          if (userDebit) {
            await refundUser(cancellingUserId, Math.abs(Number(userDebit.nombre)));
          } else {
            console.log(`[CancelService] ℹ️ User ${cancellingUserId} did not pay (Infinity/Onsite) - No refund.`);
          }
        }

        await models.participant.destroy({ where: { id_reservation: id, id_utilisateur: cancellingUserId }, transaction: t });

        // ✅ Check remaining participants count after deletion
        const remainingParticipants = await models.participant.count({
          where: { id_reservation: id },
          transaction: t
        });

        console.log(`[CancelService] Participant left. Remaining: ${remainingParticipants}/4`);

        // ✅ If match was valid (etat=1) but now has < 4 players, revert to pending
        const wasValid = Number(reservation.etat) === 1;
        if (wasValid && remainingParticipants < 4) {
          console.log(`[CancelService] ⚠️ Match dropped below 4 players - reverting to pending (etat=0)`);

          await reservation.update({
            etat: 0,  // Revert to pending
            date_modif: new Date()
          }, { transaction: t });

          // Re-enable the slot
          if (plage) {
            await plage.update({ disponible: true }, { transaction: t });
            console.log(`[CancelService] ✅ Slot ${plage.id} re-enabled (disponible=true)`);
          }

          // ✅ Notify remaining players that match is now pending
          for (const p of participants) {
            if (Number(p.id_utilisateur) !== Number(cancellingUserId)) {
              await addNotification({
                recipient_id: p.id_utilisateur,
                reservation_id: reservation.id,
                submitter_id: cancellingUserId,
                type: 'match_status_changed',
                message: `Un joueur a quitté le match. Le match est maintenant en attente (${remainingParticipants}/4 joueurs).`
              });
            }
          }
        } else {
          // Just update modification date
          await reservation.update({ date_modif: new Date() }, { transaction: t });

          // ✅ Notify remaining players that someone left
          for (const p of participants) {
            if (Number(p.id_utilisateur) !== Number(cancellingUserId)) {
              await addNotification({
                recipient_id: p.id_utilisateur,
                reservation_id: reservation.id,
                submitter_id: cancellingUserId,
                type: 'participant_left',
                message: `Un participant a quitté le match (${remainingParticipants}/4 joueurs).`
              });
            }
          }
        }


      }

      await t.commit();
      return await models.reservation.findByPk(id, { include: [{ model: models.terrain, as: 'terrain' }] });

    } catch (err) {
      await t.rollback();
      throw err;
    }
  };

  // ════════════════════════════════════════════════════════════════════════════
  // BATCH REFUND PROCESSOR
  // ════════════════════════════════════════════════════════════════════════════

  const processStatusRefunds = async () => {
    const t = await models.sequelize.transaction();

    try {
      const reservations = await models.reservation.findAll({
        where: { isCancel: 0 },
        transaction: t,
        lock: t.LOCK.UPDATE,
      });

      for (const reservation of reservations) {
        try {
          const [plageHoraire, participants] = await Promise.all([
            models.plage_horaire.findByPk(reservation.id_plage_horaire, { transaction: t }),
            models.participant.findAll({ where: { id_reservation: reservation.id }, transaction: t })
          ]);
          reservation.dataValues.plage_horaire = plageHoraire;
          reservation.dataValues.participants = participants;
        } catch (e) { }
      }

      const bySlot = new Map();
      for (const r of reservations) {
        const slotId = Number(r.id_plage_horaire);
        if (!bySlot.has(slotId)) bySlot.set(slotId, []);
        bySlot.get(slotId).push(r);
      }

      const slotPriceOf = (r) => {
        const p = Number(r?.plage_horaire?.price ?? r?.prix_total ?? 0);
        return Number.isFinite(p) && p > 0 ? p : 0;
      };

      for (const r of reservations) {
        if (Number(r?.etat ?? -1) === 0 && r.participants?.length > 0) {
          const slotPrice = slotPriceOf(r);
          for (const p of r.participants) {
            if (Number(p.statepaiement) === 1) {
              await refundUserIdempotent(p.id_utilisateur, slotPrice, r.id, p.id, t);
            }
          }
          await models.participant.destroy({ where: { id_reservation: r.id }, transaction: t });
          await models.reservation_utilisateur.destroy({ where: { id_reservation: r.id }, transaction: t });
        }
      }

      await t.commit();
      return { processedSlots: bySlot.size };

    } catch (err) {
      await t.rollback();
      throw err;
    }
  };

  // ════════════════════════════════════════════════════════════════════════════
  // SCORE LOGIC: Validate a single Set
  // ════════════════════════════════════════════════════════════════════════════
  const validateSet = (setIndex, a, b, isSuperTieBreak) => {
    const scoreA = Number(a);
    const scoreB = Number(b);

    if (!Number.isFinite(scoreA) || !Number.isFinite(scoreB) || scoreA < 0 || scoreB < 0) {
      throw new Error(`Invalid score values for Set ${setIndex + 1}`);
    }

    const diff = Math.abs(scoreA - scoreB);
    const max = Math.max(scoreA, scoreB);
    const min = Math.min(scoreA, scoreB);

    // Set 3: Super Tie-Break Mode
    if (setIndex === 2 && isSuperTieBreak) {
      // Must reach at least 10, diff >= 2
      // Valid: 10-8, 11-9, 12-10
      // Invalid: 10-9, 9-9
      if (max < 10) return false;
      if (diff < 2) return false;
      return true;
    }

    // Normal Set (Set 1, 2, or 3-Normal)
    // Valid outcomes:
    // 6-0 to 6-4 (max=6, diff>=2)
    // 7-5 (max=7, min=5)
    // 7-6 (max=7, min=6) - Tie-break
    // Any other 7-x is invalid (e.g. 7-4 means it should have ended at 6-4)
    // 8+ games is invalid

    if (max > 7) return false; // No set goes beyond 7 games

    if (max === 6) {
      // Must win by 2 (6-0 ... 6-4)
      return diff >= 2;
    }

    if (max === 7) {
      // Must be 7-5 or 7-6
      return min === 5 || min === 6;
    }

    return false; // Less than 6 games played (e.g. 5-5 is invalid final score)
  };

  // ════════════════════════════════════════════════════════════════════════════
  // SCORE LOGIC: Determine Winner (First to 2 sets)
  // ════════════════════════════════════════════════════════════════════════════
  const determineWinner = (sets) => {
    let winsA = 0;
    let winsB = 0;

    for (const s of sets) {
      if (s.a > s.b) winsA++;
      else if (s.b > s.a) winsB++; // Draw impossible in valid set

      if (winsA === 2) return 1; // Team A = 1
      if (winsB === 2) return 2; // Team B = 2
    }
    return null; // Match not finished or draw (shouldn't happen in padel)
  };

  // ════════════════════════════════════════════════════════════════════════════
  // SCORE LOGIC: Update Score (Main Business Logic)
  // ════════════════════════════════════════════════════════════════════════════
  const updateScore = async (reservationId, scoreData, submitterId) => {
    const t = await models.sequelize.transaction();
    try {
      const reservation = await models.reservation.findByPk(reservationId, {
        transaction: t,
        lock: t.LOCK.UPDATE
      });

      if (!reservation) throw new Error('Reservation not found');

      // 1. Check if locked
      if (reservation.score_status === 1 || reservation.score_status === 2) {
        throw new Error('Score is already confirmed and cannot be modified.');
      }

      const { set1, set2, set3, set3_mode } = scoreData;
      const isSuperTieBreak = set3_mode === 'SUPER_TIE_BREAK';

      // 2. Validate Sets
      const sets = [];

      // Set 1
      if (!validateSet(0, set1.a, set1.b, false)) {
        throw new Error('Invalid score for Set 1 (Must be 6-x, 7-5, or 7-6)');
      }
      sets.push({ a: set1.a, b: set1.b });

      // Set 2
      if (!validateSet(1, set2.a, set2.b, false)) {
        throw new Error('Invalid score for Set 2');
      }
      sets.push({ a: set2.a, b: set2.b });

      // Determine interim state to see if Set 3 is needed
      let tempWinner = determineWinner(sets);

      // Set 3 (Only if 1-1 split)
      if (!tempWinner) {
        if (!set3) throw new Error('Set 3 score is required for a 1-1 match');

        if (!validateSet(2, set3.a, set3.b, isSuperTieBreak)) {
          throw new Error(isSuperTieBreak
            ? 'Invalid Super Tie-Break score (Must be >=10 pts, diff >=2)'
            : 'Invalid score for Set 3'
          );
        }
        sets.push({ a: set3.a, b: set3.b });
        tempWinner = determineWinner(sets);
      }

      if (!tempWinner) {
        throw new Error('Match must have a winner (Best of 3)');
      }

      // 3. Compare with Existing (if PENDING)
      let newStatus = 0; // 0 = PENDING
      let confirmedAt = null;

      if (reservation.score_status === 0 && reservation.last_score_submitter !== submitterId) {
        // Someone else submitted before. Compare scores.
        const sameScore =
          reservation.Set1A === set1.a && reservation.Set1B === set1.b &&
          reservation.Set2A === set2.a && reservation.Set2B === set2.b &&
          (sets.length < 3 || (reservation.Set3A === set3.a && reservation.Set3B === set3.b)) &&
          reservation.teamwin === tempWinner;

        if (sameScore) {
          newStatus = 1; // 1 = CONFIRMED
          confirmedAt = new Date();
        } else {
          newStatus = 3; // 3 = CONFLICT
        }
      }

      // 4. Update DB
      await reservation.update({
        Set1A: set1.a,
        Set1B: set1.b,
        Set2A: set2.a,
        Set2B: set2.b,
        Set3A: sets[2] ? sets[2].a : null,
        Set3B: sets[2] ? sets[2].b : null,
        supertiebreak: isSuperTieBreak ? 1 : 0,
        score_status: newStatus,
        teamwin: tempWinner,
        last_score_submitter: submitterId,
        last_score_update: confirmedAt || new Date()
      }, { transaction: t });



      await t.commit();

      // Trigger rating calculation if match is confirmed
      if (newStatus === 1) {
        // Run in background to not block response
        updatePlayerRatings(reservationId).catch(err => console.error('[RatingService] Background update error:', err));
      }

      // ─────────────────────────────────────────────────────────────────────────────
      // NOTIFICATIONS
      // ─────────────────────────────────────────────────────────────────────────────
      try {
        // Fetch participants (excluding submitter) to notify them
        const participants = await models.participant.findAll({
          where: { id_reservation: reservationId },
          include: [{
            model: models.utilisateur,
            as: 'utilisateur',
            attributes: ['id', 'fcm_token', 'nom', 'prenom']
          }]
        });

        // 1. Get tokens of OTHER players
        const recipients = participants
          .map(p => p.utilisateur)
          .filter(u => u && u.id != submitterId && u.fcm_token);

        const tokens = recipients.map(u => u.fcm_token);
        const submitterName = participants.find(p => p.utilisateur.id == submitterId)?.utilisateur.nom || 'A player';

        if (tokens.length > 0) {
          const notificationService = (await import('./notification.service.js')).default;
          let title = '';
          let body = '';
          let type = '';

          if (newStatus === 0) { // PENDING
            title = '🎾 Score Proposed';
            body = `${submitterName} has proposed a score. Please confirm or contest it.`;
            type = 'SCORE_PROPOSAL';
          } else if (newStatus === 1) { // CONFIRMED
            title = '✅ Match Score Confirmed';
            const winnerText = reservation.teamwin === 1 ? 'Team A' : 'Team B';
            body = `The match score has been confirmed! Winner: ${winnerText}`;
            type = 'SCORE_CONFIRMED';
          } else if (newStatus === 3) { // CONFLICT
            title = '⚠️ Score Conflict';
            body = `There is a conflict in the reported scores. Please review.`;
            type = 'SCORE_CONFLICT';
          }

          if (title) {
            await notificationService.sendMulticast(tokens, title, body, {
              type: type,
              reservationId: reservationId.toString(),
              submitterId: submitterId.toString()
            });
            console.log(`🔔 Notification sent to ${tokens.length} users: ${title}`);
          }
        }
      } catch (notifError) {
        console.error('❌ Failed to send score notification:', notifError);
        // Do not throw; update was successful
      }

      return reservation;

    } catch (error) {
      await t.rollback();
      throw error;
    }
  };

  // ════════════════════════════════════════════════════════════════════════════
  // JOB: Finalize Pending Scores (> 24h)
  // ════════════════════════════════════════════════════════════════════════════
  const finalizePendingScores = async () => {
    const t = await models.sequelize.transaction();
    try {
      const yesterday = new Date(new Date() - 24 * 60 * 60 * 1000);

      const pendingReservations = await models.reservation.findAll({
        where: {
          score_status: 0, // 0 = PENDING
          updatedAt: { [Op.lt]: yesterday } // Assuming updatedAt tracks submission time
        },
        transaction: t,
        lock: t.LOCK.UPDATE
      });

      for (const r of pendingReservations) {
        await r.update({
          score_status: 2, // 2 = CONFIRMED_AUTO
          last_score_update: new Date()
        }, { transaction: t });
        
        // Trigger rating calculation for each confirmed reservation
        updatePlayerRatings(r.id).catch(err => console.error('[RatingService] Background update error (auto):', err));
      }

      await t.commit();
      return { count: pendingReservations.length };
    } catch (error) {
      await t.rollback();
      throw error;
    }
  };
  return {
    create,
    findAll,
    findById,
    update,
    findByUserId,
    findOne,
    remove,
    findByDate,
    findAvailableByDate,
    cancel,
    processStatusRefunds,
    cancelExcessPendingReservations,
    updateScore,
    finalizePendingScores,
  };
}