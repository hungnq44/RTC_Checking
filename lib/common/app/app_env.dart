// Các môi trường chạy App

enum AppEnv {
  debug,
  production,
  staging;

  static AppEnv fromString(String value) {
    switch (value) {
      case 'debug':
        return AppEnv.debug;
      case 'production':
        return AppEnv.production;
      case 'staging':
        return AppEnv.staging;
      default:
        return AppEnv.debug;
    }
  }
}
