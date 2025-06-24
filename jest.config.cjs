module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.[jt]s'],
  verbose: true,
  clearMocks: true,
  coveragePathIgnorePatterns: [
    '/packages/api-gateway/src/generated/',
    '/packages/api-gateway/src/main.js'
  ],
  coverageThreshold: {
    global: { lines: 80 }
  },
};
