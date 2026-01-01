import 'package:injectable/injectable.dart';

enum AppEnvironment {
  prod,
  dev,
  test,
  mock;

  String get name => toString().split('.').last;
}

const prod = Environment('prod');
const dev = Environment('dev');
const test = Environment('test');
const mock = Environment('mock');
