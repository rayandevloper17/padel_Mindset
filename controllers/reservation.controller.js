export default function ReservationController(service) {
  const create = async (req, res) => {
    try {
      const reservation = await service.create(req.body);
      res.status(201).json(reservation);
    } catch (err) {
      // Enhanced error response for better frontend display
      const errorResponse = {
        error: err.message,
        type: 'RESERVATION_LIMIT_EXCEEDED',
        code: 4001,
        displayType: 'snackbar' // This tells frontend to show as snackbar/popup
      };
      
      // Check if it's a reservation limit error
      if (err.message.includes('Vous ne pouvez pas créer plus de 3 réservations')) {
        errorResponse.title = 'Limite de réservations atteinte';
        errorResponse.severity = 'warning';
        errorResponse.action = 'VIEW_RESERVATIONS';
      } else if (err.message.includes('Vous avez déjà une réservation pour cette plage horaire le même jour')) {
        // Double booking on same day and time slot
        errorResponse.type = 'DOUBLE_BOOKING';
        errorResponse.title = 'Réservation en double';
        errorResponse.severity = 'warning';
        errorResponse.action = 'VIEW_RESERVATIONS';
      }
      
      res.status(400).json(errorResponse);
    }
  };

  

const findByCode = async (req, res) => {
  try {
    // route is /code/:code -> param name is `code`
    const { code } = req.params;

    console.debug('[ReservationController] findByCode called with code=', code);

    if (!code) {
      return res.status(400).json({ error: "Reservation code is required", code: 4001 });
    }

    // The DB field is named `coder`, so query by that field
    const reservation = await service.findOne({ coder: code });

  console.debug('[ReservationController] findByCode result=', !!reservation, reservation ? reservation.id : null);

    if (!reservation) {
      return res.status(404).json({ error: "Reservation not found", code: 4041 });
    }

    res.json(reservation);
  } catch (err) {
    res.status(500).json({ error: "Internal server error", code: 5001, details: err.message });
  }
};


  const findAll = async (req, res) => {
    try {
      // Check if user is admin - only admins can see all reservations
      if (!req.user.si_admin) {
        return res.status(403).json({ 
          error: 'Accès non autorisé',
          message: 'Seuls les administrateurs peuvent accéder à toutes les réservations. Utilisez /history/me pour voir vos propres réservations.'
        });
      }
      
      const list = await service.findAll();
      res.json(list);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  };

  const findById = async (req, res) => {
    try {
      const { id } = req.params;

      console.debug('[ReservationController] findById called with id=', id);

      // Try primary id lookup first
      let item = await service.findById(id);
      console.debug('[ReservationController] findById findById result=', !!item, item ? item.id : null);

      // If not found, it's possible the client passed the reservation 'coder' instead
      if (!item) {
        item = await service.findOne({ coder: id });
        console.debug('[ReservationController] findById findOne by coder result=', !!item, item ? item.id : null);
      }

      if (!item) return res.status(404).json({ error: "Reservation not found" });

      // Security check: only allow users to see their own reservations, unless they're admin
      if (!req.user.si_admin && item.id_utilisateur !== req.user.id) {
        return res.status(403).json({ 
          error: 'Accès non autorisé',
          message: 'Vous ne pouvez accéder qu\'à vos propres réservations'
        });
      }

      res.json(item);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  };

  const update = async (req, res) => {
    try {
      // First check if the reservation exists and user has permission
      const existingReservation = await service.findById(req.params.id);
      if (!existingReservation) {
        return res.status(404).json({ error: "Reservation not found" });
      }

      // Security check: only allow users to update their own reservations, unless they're admin
      if (!req.user.si_admin && existingReservation.id_utilisateur !== req.user.id) {
        return res.status(403).json({ 
          error: 'Accès non autorisé',
          message: 'Vous ne pouvez modifier que vos propres réservations'
        });
      }

      const updated = await service.update(req.params.id, req.body);
      res.json(updated);
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  };

  const remove = async (req, res) => {
    try {
      // First check if the reservation exists and user has permission
      const existingReservation = await service.findById(req.params.id);
      if (!existingReservation) {
        return res.status(404).json({ error: "Reservation not found" });
      }

      // Security check: only allow users to delete their own reservations, unless they're admin
      if (!req.user.si_admin && existingReservation.id_utilisateur !== req.user.id) {
        return res.status(403).json({ 
          error: 'Accès non autorisé',
          message: 'Vous ne pouvez supprimer que vos propres réservations'
        });
      }

      await service.remove(req.params.id);
      res.json({ message: "Reservation deleted" });
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  };

  const historyForUser = async (req, res) => {
    try {
      // Get user ID from authenticated token
      const userId = req.user.id;
      
      console.debug('[ReservationController] historyForUser called for userId=', userId);
      
      const reservations = await service.findByUserId(userId);
      
      console.debug('[ReservationController] historyForUser found', reservations.length, 'reservations');
      
      res.json(reservations);
    } catch (err) {
      console.error('[ReservationController] historyForUser error:', err);
      res.status(500).json({ error: err.message });
    }
  };

  return {
    create,
    findAll,
    findByCode,
    findById,
    update,
    remove,
    historyForUser,
  };
}
