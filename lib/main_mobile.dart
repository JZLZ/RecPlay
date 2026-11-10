import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/di/injection_container.dart' as di;
import 'core/device/device_detector.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Service Locator
  await di.initDependencies();

  // Força detecção de Smartphone
  di.sl<DeviceDetector>().overrideDeviceType(DeviceType.mobile);

  // Orientação flexível para Smartphone (Retrato e Paisagem)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const AstraApp(forcedDeviceType: DeviceType.mobile));
}
