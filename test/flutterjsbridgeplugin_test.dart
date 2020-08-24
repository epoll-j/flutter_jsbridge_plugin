import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:flutterjsbridgeplugin/flutterjsbridgeplugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutterjsbridgeplugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
//    expect(await Flutterjsbridgeplugin.platformVersion, '42');
  });
}
