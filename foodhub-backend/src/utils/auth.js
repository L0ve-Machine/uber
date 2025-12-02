// Re-export password utilities
const { hashPassword, comparePassword } = require('./password');

module.exports = {
  hashPassword,
  comparePassword,
};
