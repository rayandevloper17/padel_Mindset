// middlewares/validation.middleware.js

// Email validation regex
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const validateCreateUser = (req, res, next) => {
  console.log('🔍 Validation - Request body:', req.body);
  const { nom, prenom, email, mot_de_passe, numero_telephone, telephone, mainprefere } = req.body;

  // Check required fields
  if (!nom || !email || !mot_de_passe) {
    return res.status(400).json({
      error: 'Champs requis manquants',
      message: 'nom, email et mot_de_passe sont requis'
    });
  }

  // Validate email format
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      error: 'Format email invalide',
      message: 'Veuillez fournir un email valide'
    });
  }

  // Validate password strength
  if (mot_de_passe.length < 8) {
    return res.status(400).json({
      error: 'Mot de passe trop faible',
      message: 'Le mot de passe doit contenir au moins 8 caractères'
    });
  }

  // Optional: Check password complexity
  const hasUpperCase = /[A-Z]/.test(mot_de_passe);
  const hasLowerCase = /[a-z]/.test(mot_de_passe);
  const hasNumbers = /\d/.test(mot_de_passe);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(mot_de_passe);

  if (!hasUpperCase || !hasLowerCase || !hasNumbers) {
    return res.status(400).json({
      error: 'Mot de passe trop faible',
      message: 'Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre'
    });
  }

  // Validate name (no numbers, special characters)
  const nameRegex = /^[a-zA-ZÀ-ÿ\s'-]+$/;
  if (!nameRegex.test(nom)) {
    return res.status(400).json({
      error: 'Format nom invalide',
      message: 'Le nom ne peut contenir que des lettres, espaces, apostrophes et tirets'
    });
  }

  // Validate prenom if provided
  if (prenom && !nameRegex.test(prenom)) {
    return res.status(400).json({
      error: 'Format prénom invalide',
      message: 'Le prénom ne peut contenir que des lettres, espaces, apostrophes et tirets'
    });
  }

  // Validate phone number if provided (check both fields)
  const phoneNumber = numero_telephone || telephone;
  if (phoneNumber) {
    const phoneRegex = /^(\+213|0)[5-7][0-9]{8}$/; // Algerian phone number format
    if (!phoneRegex.test(phoneNumber.replace(/\s/g, ''))) {
      return res.status(400).json({
        error: 'Format téléphone invalide',
        message: 'Veuillez fournir un numéro de téléphone algérien valide'
      });
    }
  }

  // Validate hand preference (required: 0 = droite, 1 = gauche)
  if (mainprefere === undefined || mainprefere === null || mainprefere === '') {
    return res.status(400).json({
      error: 'Main préférée manquante',
      message: 'Veuillez choisir votre main préférée (0: droite, 1: gauche)'
    });
  }
  if (!(mainprefere === 0 || mainprefere === 1 || mainprefere === '0' || mainprefere === '1')) {
    return res.status(400).json({
      error: 'Valeur main préférée invalide',
      message: 'mainprefere doit être 0 (droite) ou 1 (gauche)'
    });
  }
  // Normalize to integer
  req.body.mainprefere = parseInt(mainprefere, 10);

  next();
};

export const validateUpdateUser = (req, res, next) => {
  const { nom, prenom, email, mot_de_passe, telephone, mainprefere } = req.body;

  // Validate email format if provided
  if (email && !emailRegex.test(email)) {
    return res.status(400).json({
      error: 'Format email invalide',
      message: 'Veuillez fournir un email valide'
    });
  }

  // Validate password if provided
  if (mot_de_passe) {
    if (mot_de_passe.length < 8) {
      return res.status(400).json({
        error: 'Mot de passe trop faible',
        message: 'Le mot de passe doit contenir au moins 8 caractères'
      });
    }

    // Check password complexity
    const hasUpperCase = /[A-Z]/.test(mot_de_passe);
    const hasLowerCase = /[a-z]/.test(mot_de_passe);
    const hasNumbers = /\d/.test(mot_de_passe);

    if (!hasUpperCase || !hasLowerCase || !hasNumbers) {
      return res.status(400).json({
        error: 'Mot de passe trop faible',
        message: 'Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre'
      });
    }
  }

  // Validate name format if provided
  const nameRegex = /^[a-zA-ZÀ-ÿ\s'-]+$/;
  if (nom && !nameRegex.test(nom)) {
    return res.status(400).json({
      error: 'Format nom invalide',
      message: 'Le nom ne peut contenir que des lettres, espaces, apostrophes et tirets'
    });
  }

  if (prenom && !nameRegex.test(prenom)) {
    return res.status(400).json({
      error: 'Format prénom invalide',
      message: 'Le prénom ne peut contenir que des lettres, espaces, apostrophes et tirets'
    });
  }

  // Validate phone number if provided
  if (telephone) {
    const phoneRegex = /^(\+213|0)[5-7][0-9]{8}$/;
    if (!phoneRegex.test(telephone.replace(/\s/g, ''))) {
      return res.status(400).json({
        error: 'Format téléphone invalide',
        message: 'Veuillez fournir un numéro de téléphone algérien valide'
      });
    }
    // Map telephone to numero_telephone for DB update
    req.body.numero_telephone = telephone;
  }

  // Validate rating questionnaire flag if provided (must be 0 or 1)
  if (req.body.hasOwnProperty('questionnaire_note_rempli')) {
    const flag = req.body.questionnaire_note_rempli;
    if (!(flag === 0 || flag === 1 || flag === '0' || flag === '1')) {
      return res.status(400).json({
        error: 'Valeur questionnaire invalide',
        message: 'questionnaire_note_rempli doit être 0 (afficher) ou 1 (masquer)'
      });
    }
    // Normalize to integer
    req.body.questionnaire_note_rempli = parseInt(flag, 10);
  }

  // Validate displayQ if provided (must be 0 or 1)
  if (req.body.hasOwnProperty('displayQ')) {
    const flag = req.body.displayQ;
    if (!(flag === 0 || flag === 1 || flag === '0' || flag === '1')) {
      return res.status(400).json({
        error: 'Valeur displayQ invalide',
        message: 'displayQ doit être 0 (afficher) ou 1 (masquer)'
      });
    }
    req.body.displayQ = parseInt(flag, 10);
  }

  // Validate hand preference if provided (must be 0 or 1)
  if (req.body.hasOwnProperty('mainprefere')) {
    if (mainprefere === undefined || mainprefere === null || mainprefere === '') {
      return res.status(400).json({
        error: 'Main préférée manquante',
        message: 'Veuillez choisir votre main préférée (0: droite, 1: gauche)'
      });
    }
    if (!(mainprefere === 0 || mainprefere === 1 || mainprefere === '0' || mainprefere === '1')) {
      return res.status(400).json({
        error: 'Valeur main préférée invalide',
        message: 'mainprefere doit être 0 (droite) ou 1 (gauche)'
      });
    }
    req.body.mainprefere = parseInt(mainprefere, 10);
  }

  next();
};

export const validateLogin = (req, res, next) => {
  const { email, mot_de_passe } = req.body;

  if (!email || !mot_de_passe) {
    return res.status(400).json({
      error: 'Champs requis manquants',
      message: 'Email et mot de passe sont requis'
    });
  }

  if (!emailRegex.test(email)) {
    return res.status(400).json({
      error: 'Format email invalide',
      message: 'Veuillez fournir un email valide'
    });
  }

  next();
};

// Generic validation for IDs
export const validateId = (req, res, next) => {
  const id = parseInt(req.params.id);

  if (!id || id <= 0) {
    return res.status(400).json({
      error: 'ID invalide',
      message: 'Un ID numérique valide est requis'
    });
  }

  next();
};
export const validateCreditUpdate = (req, res, next) => {
  const { userId, creditAmount, creditType } = req.body;

  // Validate userId
  if (!userId || !Number.isInteger(Number(userId)) || userId <= 0) {
    return res.status(400).json({
      error: 'ID invalide user',
      message: 'Un ID numérique valide est requis'
    });
  }

  // Validate creditAmount
  if (!creditAmount || creditAmount <= 0) {
    return res.status(400).json({
      error: 'Montant invalide',
      message: 'Le montant doit être supérieur à zéro'
    });
  }

  // Validate creditType: allow unified balance or default to balance when mi ssing
  if (creditType && !['credit_balance'].includes(creditType)) {
    return res.status(400).json({
      error: 'Type de crédit invalide',
      message: 'Le type de crédit doit être "credit_balance"'
    });
  }
  // Default to unified balance if not provided
  if (!creditType) {
    req.body.creditType = 'credit_balance';
  }

  next();
};
// Sanitize input data
export const sanitizeInput = (req, res, next) => {
  // Remove extra whitespace from string fields
  if (req.body) {
    Object.keys(req.body).forEach(key => {
      if (typeof req.body[key] === 'string') {
        req.body[key] = req.body[key].trim();
      }
    });
  }

  next();
};