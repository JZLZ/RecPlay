import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/di/injection_container.dart' as di;
import 'core/device/device_detector.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Service Locator
  await di.initDependencies();

  // Força detecção de Android TV (Leanback)
  di.sl<DeviceDetector>().overrideDeviceType(DeviceType.television);

  // Modo Imersivo e Orientação Paisagem para Android TV
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const AstraApp(forcedDeviceType: DeviceType.television));
}
