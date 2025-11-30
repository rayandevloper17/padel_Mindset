export default function ReservationService(models) {
  const create = async (data) => {
    const terrain = await models.terrain.findByPk(data.id_terrain);
    if (!terrain) throw new Error("Terrain not found");

    const utilisateur = await models.utilisateur.findByPk(data.id_utilisateur);
    if (!utilisateur) throw new Error("Utilisateur not found");

    const plage = await models.plage_horaire.findByPk(data.id_plage_horaire);
    if (!plage) throw new Error("Plage horaire not found");

    // Prevent double booking: the same user cannot reserve the same time slot on the same day
    const existingSameSlotReservation = await models.reservation.findOne({
      where: {
        id_utilisateur: data.id_utilisateur,
        id_plage_horaire: data.id_plage_horaire,
        date: data.date,
      }
    });
    if (existingSameSlotReservation) {
      throw new Error('Vous avez déjà une réservation pour cette plage horaire le même jour.');
    }

    // Check reservation limits for specific date ranges
    const reservationDate = new Date(data.date);
    const year = reservationDate.getFullYear();
    const month = reservationDate.getMonth(); // 0-based (11 = December)
    const day = reservationDate.getDate();

    // Define the restricted date ranges for December 2025
    const isInFirstRange = year === 2025 && month === 11 && day >= 1 && day <= 7;
    const isInSecondRange = year === 2025 && month === 11 && day >= 8 && day <= 15;

    if (isInFirstRange || isInSecondRange) {
      // Count existing reservations in the relevant range
      let startDate, endDate, rangeName;
      
      if (isInFirstRange) {
        startDate = new Date(2025, 11, 1); // December 1, 2025
        endDate = new Date(2025, 11, 7); // December 7, 2025
        rangeName = "1er au 7 décembre 2025";
      } else {
        startDate = new Date(2025, 11, 8); // December 8, 2025
        endDate = new Date(2025, 11, 15); // December 15, 2025
        rangeName = "8 au 15 décembre 2025";
      }

      const existingReservations = await models.reservation.count({
        where: {
          id_utilisateur: data.id_utilisateur,
          date: {
            [models.Sequelize.Op.between]: [startDate, endDate]
          }
        }
      });

      if (existingReservations >= 3) {
        throw new Error(`Vous ne pouvez pas créer plus de 3 réservations dans la période du ${rangeName}. Vous avez déjà ${existingReservations} réservations.`);
      }
    }

    // Normalize prix_total to satisfy DB constraint (check_prix_positif)
    // Prefer client-provided prix_total if valid (> 0); otherwise use plage.price; fallback to 1
    const incomingPrice = Number(data?.prix_total);
    const plagePrice = Number(plage?.price);
    const normalizedPrice = Number.isFinite(incomingPrice) && incomingPrice > 0
      ? incomingPrice
      : (Number.isFinite(plagePrice) && plagePrice > 0 ? plagePrice : 1);

    const payload = { ...data, prix_total: normalizedPrice };

    const reservation = await models.reservation.create(payload);

    await plage.update({ disponible: false });

    // Return reservation with details
    return await models.reservation.findByPk(reservation.id, {
      include: [
        { model: models.terrain, as: 'terrain' },
        { model: models.utilisateur, as: 'utilisateur' },
        { model: models.plage_horaire, as: 'plageHoraire' }
      ]
    });
  };

  const findAll = async () => {
    return await models.reservation.findAll({
      include: [
        { model: models.terrain, as: 'terrain' },
        { model: models.utilisateur, as: 'utilisateur' },
        { model: models.plage_horaire, as: 'plageHoraire' }
      ]
    });
  };

  const findById = async (id) => {
    return await models.reservation.findByPk(id, {
      include: [
        { model: models.terrain, as: 'terrain' },
        { model: models.utilisateur, as: 'utilisateur' },
        { model: models.plage_horaire, as: 'plageHoraire' }
      ]
    });
  };

  const findByUserId = async (userId) => {
    return await models.reservation.findAll({
      where: { id_utilisateur: userId },
      include: [
        { model: models.terrain, as: 'terrain' },
        { model: models.utilisateur, as: 'utilisateur' },
        { model: models.plage_horaire, as: 'plageHoraire' },
        { model: models.participant, as: 'participants' }
      ],
      order: [[ 'date_creation', 'DESC' ]]
    });
  };



const findOne = async (filter) => {
  return await models.reservation.findOne({
    where: filter,  
      include: [
        { model: models.terrain, as: 'terrain' },
        { model: models.utilisateur, as: 'utilisateur' },
        { model: models.plage_horaire, as: 'plageHoraire' }
      ]
    });
  }

  const update = async (id, data) => {
    const reservation = await models.reservation.findByPk(id);
    if (!reservation) throw new Error("Reservation not found");
    await reservation.update(data);
    return await findById(id); // return with includes
  };

  const remove = async (id) => {
    const reservation = await models.reservation.findByPk(id);
    if (!reservation) throw new Error("Reservation not found");
    return await reservation.destroy();
  };

  return {
    create,
    findAll,
    findById,
    update,
    findByUserId,
    findOne,
    remove,
  };
}
