import { Sequelize, DataTypes } from 'sequelize';

export default function (sequelize) {
  return sequelize.define('utilisateur', {
    id: {
      autoIncrement: true,
      type: DataTypes.BIGINT,
      allowNull: false,
      primaryKey: true
    },
    email: {
      type: DataTypes.TEXT,
      allowNull: false,
      unique: true
    },
    nom: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    prenom: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    numero_telephone: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    mot_de_passe: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    image_url: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    mainprefere: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    // ✅ Add displayQ field
    displayQ: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 0
    },
    note: {
      type: DataTypes.DOUBLE,
      allowNull: true,
      defaultValue: 0
    },
    credit_balance: {
      type: DataTypes.DOUBLE,
      allowNull: true,
      defaultValue: 0
    },
    credit_gold_padel: {
      type: DataTypes.DOUBLE,
      allowNull: true,
      defaultValue: 0
    },
    credit_gold_soccer: {
      type: DataTypes.DOUBLE,
      allowNull: true,
      defaultValue: 0
    },
    credit_silver_padel: {
      type: DataTypes.DOUBLE,
      allowNull: true,
      defaultValue: 0
    },
    credit_silver_soccer: {
      type: DataTypes.DOUBLE,
      allowNull: true,
      defaultValue: 0
    },
    refresh_tokens: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    date_misajour: {
      type: DataTypes.DATE,
      allowNull: true,
      defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
    },
    positionsurlecourt: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    fcm_token: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    gender: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    date_naissance: {
      type: DataTypes.DATE,
      allowNull: true
    }, 
    fiability: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 20
    }
  }, {
    sequelize,
    tableName: 'utilisateur',
    schema: 'public',
    timestamps: false,
    indexes: [
      {
        name: 'utilisateur_pkey',
        unique: true,
        fields: [{ name: 'id' }]
      },
      {
        name: 'idx_utilisateur_email',
        unique: true,
        fields: [{ name: 'email' }]
      }
    ]
  });
};