enum AppMode { mock, real }

AppMode getAppMode() {
  const mode = String.fromEnvironment('APP_MODE', defaultValue: 'mock');
  return mode == 'real' ? AppMode.real : AppMode.mock;
}
