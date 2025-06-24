module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/test/**/*.test.[jt]s', '**/tests/**/*.test.[jt]s'],
  verbose: true,
  clearMocks: true,
  coveragePathIgnorePatterns: [
    '/packages/api-gateway/src/'
  ],
  coverageThreshold: {
    global: { lines: 80 }
  },
};
