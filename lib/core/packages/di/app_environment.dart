enum AppEnvironment {
  prod,
  dev,
  test,
  mock;

  bool get isProd => this == prod;

  bool get isDev => this == dev;

  bool get isTest => this == test;

  bool get isMock => this == mock;
}
