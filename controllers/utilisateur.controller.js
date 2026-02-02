// controllers/utilisateur.controller.js
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
export default (models) => {
  const { utilisateur } = models;

  // Ensure refresh_tokens is an array; handle legacy TEXT column storing JSON string
  function ensureArray(value) {
    if (Array.isArray(value)) return value;
    if (typeof value === 'string') {
      try {
        const parsed = JSON.parse(value);
        return Array.isArray(parsed) ? parsed : [];
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  return {
    // Retrieve all users
    getAll: async (req, res, next) => {
      try {
        const users = await utilisateur.findAll();
        // Explicitly cast displayQ to Number (int) because BIGINT returns as string
        const serialized = users.map(u => {
          const d = u.toJSON();
          if (d.displayQ !== undefined && d.displayQ !== null) {
            d.displayQ = Number(d.displayQ);
          }
          return d;
        });
        res.json(serialized);
      } catch (err) {
        next(err);
      }
    },

    // Get user by ID
    getById: async (req, res, next) => {
      try {
        const user = await utilisateur.findByPk(req.params.id);
        if (!user) return res.status(404).json({ message: 'Utilisateur non trouvé' });
        
        // Explicitly cast displayQ to Number (int)
        const userData = user.toJSON();
        if (userData.displayQ !== undefined && userData.displayQ !== null) {
          userData.displayQ = Number(userData.displayQ);
        }
        
        res.json(userData);
      } catch (err) {
        next(err);
      }
    },

    // Create new user (hash password)
    create: async (req, res, next) => {
      try {
        const { mot_de_passe, email, displayQ } = req.body;
        
        // Hash password with standard rounds (salt embedded in hash)
        const hashedPassword = await bcrypt.hash(mot_de_passe, 10);
        
        // Create user with hashed password
        const user = await utilisateur.create({
          ...req.body,
          mot_de_passe: hashedPassword,
          displayQ: displayQ !== undefined ? displayQ : 0 // Ensure displayQ is captured
        });

        // Return user data without sensitive information
        res.status(201).json({
          id: user.id,
          email: user.email,
          nom: user.nom,
          prenom: user.prenom,
          mainprefere: user.mainprefere,
          displayQ: user.displayQ,
          fiability: user.fiability
        });
      } catch (err) {
        next(err);
      }
    },

    // creta function creditCalculateSubmit


    // User login
    login: async (req, res, next) => {
      try {
        const { email, mot_de_passe } = req.body;

        // Find user by email
        const user = await utilisateur.findOne({ where: { email } });
        if (!user) {
          return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
        }

        // Compare passwords
        const isValidPassword = await bcrypt.compare(mot_de_passe, user.mot_de_passe);
        if (!isValidPassword) {
          return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
        }

        // Generate JWT tokens
        const accessToken = jwt.sign(
          { id: user.id, email: user.email },
          process.env.JWT_SECRET,
          { expiresIn: '15m' } // Short-lived access token
        );

        const refreshToken = jwt.sign(
          { id: user.id, email: user.email, type: 'refresh' },
          process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET + '_refresh',
          { expiresIn: '30d' } // Long-lived refresh token (30 days)
        );

        // Store refresh token in array (multi-device support)
        const existing = ensureArray(user.refresh_tokens);
        const updated = [...existing, refreshToken];
        await user.update({ refresh_tokens: JSON.stringify(updated) });

        res.json({
          accessToken,
          refreshToken,
          expiresIn: 900, // 15 minutes in seconds
          tokenType: 'Bearer',
          user: {
            id: user.id,
            email: user.email,
            nom: user.nom,
            prenom: user.prenom
          }
        });
      } catch (err) {
        next(err);
      }
    },

    // Refresh token endpoint (rotate refresh tokens)
    refreshToken: async (req, res, next) => {
      try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
          return res.status(401).json({ 
            message: 'Refresh token requis',
            error: 'REFRESH_TOKEN_MISSING' 
          });
        }

        // Verify refresh token
        const decoded = jwt.verify(
          refreshToken,
          process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET + '_refresh'
        );

        // Check if it's a refresh token
        if (decoded.type !== 'refresh') {
          return res.status(401).json({ 
            message: 'Token invalide',
            error: 'INVALID_TOKEN_TYPE' 
          });
        }
        // Find user and verify refresh token exists in stored array
        const user = await utilisateur.findByPk(decoded.id);
        const list = ensureArray(user?.refresh_tokens);
        if (!user || !list.includes(refreshToken)) {
          return res.status(401).json({ 
            message: 'Refresh token invalide ou expiré',
            error: 'INVALID_REFRESH_TOKEN' 
          });
        }

        // Generate new access token
        const newAccessToken = jwt.sign(
          { id: user.id, email: user.email },
          process.env.JWT_SECRET,
          { expiresIn: '15m' }
        );

        // Rotate refresh token
        const newRefreshToken = jwt.sign(
          { id: user.id, email: user.email, type: 'refresh' },
          process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET + '_refresh',
          { expiresIn: '30d' }
        );

        // Replace the old token with the new one
        const rotated = list.map(t => (t === refreshToken ? newRefreshToken : t));
        await user.update({ refresh_tokens: JSON.stringify(rotated) });

        res.json({
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          expiresIn: 900, // 15 minutes in seconds
          tokenType: 'Bearer',
          message: 'Token rafraîchi avec succès',
          user: {
            id: user.id,
            email: user.email,
            nom: user.nom,
            prenom: user.prenom
          }
        });

      } catch (err) {
        if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
          return res.status(401).json({ 
            message: 'Refresh token invalide ou expiré',
            error: 'INVALID_REFRESH_TOKEN' 
          });
        }
        next(err);
      }
    },

    // Logout endpoint (invalidate specific refresh token)
    logout: async (req, res, next) => {
      try {
        const { refreshToken } = req.body;
        
        if (refreshToken) {
          // Attempt to decode to locate the user
          let user = null;
          try {
            const decoded = jwt.verify(
              refreshToken,
              process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET + '_refresh'
            );
            user = await utilisateur.findByPk(decoded.id);
          } catch (_) {
            // If decode fails, fallback: no-op or additional search strategies could be used
          }

          if (user) {
            const list = ensureArray(user.refresh_tokens);
            const filtered = list.filter(t => t !== refreshToken);
            await user.update({ refresh_tokens: JSON.stringify(filtered) });
          }
        }

        res.json({ 
          message: 'Déconnexion réussie',
          success: true 
        });
      } catch (err) {
        next(err);
      }
    },

// Enhanced update function - handles user info AND credit operations
update: async (req, res, next) => {
  try {
    const user = await utilisateur.findByPk(req.params.id);
    if (!user) return res.status(404).json({ message: 'Utilisateur non trouvé' });
    
    // Handle password hashing if password is being updated
    if (req.body.mot_de_passe) {
      req.body.mot_de_passe = await bcrypt.hash(req.body.mot_de_passe, 10);
    }
    
    // Handle credit operations if requested
    if (req.body.creditOperation) {
      const { creditOperation, creditAmount, creditType, sport } = req.body;
      
      if (creditOperation === 'deduct') {
        // Determine which credit field to update
        let currentCredit;
        let creditField;
        
        console.log('DEDUCT CREDIT: userId=', req.params.id, 'creditType=', creditType, 'creditAmount=', creditAmount, 'sport=', sport);
        
        if (creditType === 'gold') {
          if (sport === 'padel') {
            currentCredit = user.credit_gold_padel || 0;
            creditField = 'credit_gold_padel';
          } else if (sport === 'soccer') {
            currentCredit = user.credit_gold_soccer || 0;
            creditField = 'credit_gold_soccer';
          } else {
            return res.status(400).json({ message: 'Sport invalide. Utilisez "padel" ou "soccer"' });
          }
        } else if (creditType === 'silver') {
          if (sport === 'padel') {
            currentCredit = user.credit_silver_padel || 0;
            creditField = 'credit_silver_padel';
          } else if (sport === 'soccer') {
            currentCredit = user.credit_silver_soccer || 0;
            creditField = 'credit_silver_soccer';
          } else {
            return res.status(400).json({ message: 'Sport invalide. Utilisez "padel" ou "soccer"' });
          }
        } else if (creditType === 'balance' || !creditType) {
          // Unified balance-based deduction (no sport required)
          currentCredit = user.credit_balance || 0;
          creditField = 'credit_balance';
        } else {
          console.error('Erreur de type de crédit:', req.body);
          // return res.status(400).json({ message: 'Type de crédit invalide. Utilisez "gold", "silver" ou "balance"' });
        }
        
        console.log('DEDUCT CREDIT: currentCredit=', currentCredit, 'creditField=', creditField);
        
        // Verify user has enough credit
        if (currentCredit < creditAmount) {
          console.log('DEDUCT CREDIT: Insufficient credit - current:', currentCredit, 'requested:', creditAmount);
          return res.status(400).json({ 
            message: `Solde de crédit ${creditType} insuffisant pour ${sport}`,
            currentBalance: currentCredit,
            requested: creditAmount,
            deficit: creditAmount - currentCredit
          });
        }
        
        // Calculate new credit balance and add to update object
        const newCreditBalance = currentCredit - creditAmount;
        req.body[creditField] = newCreditBalance;
        
        console.log('DEDUCT CREDIT: Success - newCreditBalance=', newCreditBalance);
        
        // Remove credit operation fields from body so they don't get saved to DB
        delete req.body.creditOperation;
        delete req.body.creditAmount;
        delete req.body.creditType;
        delete req.body.sport;
        
      } else if (creditOperation === 'add') {
        // Handle adding credits
        let currentCredit;
        let creditField;
        
        if (creditType === 'gold') {
          if (sport === 'padel') {
            currentCredit = user.credit_gold_padel || 0;
            creditField = 'credit_gold_padel';
          } else if (sport === 'soccer') {
            currentCredit = user.credit_gold_soccer || 0;
            creditField = 'credit_gold_soccer';
          } else {
            return res.status(400).json({ message: 'Sport invalide. Utilisez "padel" ou "soccer"' });
          }
        } else if (creditType === 'silver') {
          if (sport === 'padel') {
            currentCredit = user.credit_silver_padel || 0;
            creditField = 'credit_silver_padel';
          } else if (sport === 'soccer') {
            currentCredit = user.credit_silver_soccer || 0;
            creditField = 'credit_silver_soccer';
          } else {
            return res.status(400).json({ message: 'Sport invalide. Utilisez "padel" ou "soccer"' });
          }
        } else if (creditType === 'balance' || !creditType) {
          // Unified balance-based addition (no sport required)
          currentCredit = user.credit_balance || 0;
          creditField = 'credit_balance';
        } else {
          return res.status(400).json({ message: 'Type de crédit invalide. Utilisez "gold", "silver" ou "balance"' });
        }
        
        // Add credits
        const newCreditBalance = currentCredit + creditAmount;
        req.body[creditField] = newCreditBalance;
        
        // Remove credit operation fields from body
        delete req.body.creditOperation;
        delete req.body.creditAmount;
        delete req.body.creditType;
        delete req.body.sport;
      }
    }
    
    // Always update the modification timestamp
    req.body.date_misajour = new Date();
    
    // Update user with all changes
    await user.update(req.body);
    
    // Return updated user (excluding sensitive information)
    const { mot_de_passe, ...userResponse } = user.toJSON();
    res.json({
      success: true,
      user: userResponse,
      message: 'Utilisateur mis à jour avec succès'
    });
    
  } catch (err) {
    console.error('Error in update:', err);
    next(err);
  }
 },



    // Delete user
    delete: async (req, res, next) => {
      try {
        const user = await utilisateur.findByPk(req.params.id);
        if (!user) return res.status(404).json({ message: 'Utilisateur non trouvé' });
        await user.destroy();
        res.status(204).send();
      } catch (err) {
        next(err);
      }
    },
  };
};
