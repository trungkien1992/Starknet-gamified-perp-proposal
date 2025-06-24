module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.[jt]s'],
  verbose: true,
  clearMocks: true,
  coveragePathIgnorePatterns: [
    '/packages/api-gateway/src/'
  ],
  coverageThreshold: {
    global: { lines: 80 }
  },
};
