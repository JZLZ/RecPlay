import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum DeviceType {
  mobile,
  tablet,
  television,
}

class DeviceDetector {
  final DeviceInfoPlugin _deviceInfoPlugin;
  DeviceType? _cachedDeviceType;

  DeviceDetector({DeviceInfoPlugin? deviceInfoPlugin})
      : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  Future<DeviceType> getDeviceType() async {
    if (_cachedDeviceType != null) {
      return _cachedDeviceType!;
    }

    if (kIsWeb) {
      _cachedDeviceType = DeviceType.mobile;
      return _cachedDeviceType!;
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        final systemFeatures = androidInfo.systemFeatures;

        // Verifica a presença do recurso nativo do Android TV (Leanback)
        final isLeanback = systemFeatures.contains('android.software.leanback');
        final isTelevision = systemFeatures.contains('android.hardware.type.television');

        if (isLeanback || isTelevision) {
          _cachedDeviceType = DeviceType.television;
          return _cachedDeviceType!;
        }

        // Caso seja tablet ou smartphone baseado em dimensões lógicas
        _cachedDeviceType = DeviceType.mobile;
        return _cachedDeviceType!;
      }
    } catch (_) {
      // Fallback seguro caso ocorra erro na consulta de hardware
    }

    _cachedDeviceType = DeviceType.mobile;
    return _cachedDeviceType!;
  }

  bool get isTv => _cachedDeviceType == DeviceType.television;

  // Permite forçar o modo (útil para testes em emuladores ou no painel adm)
  void overrideDeviceType(DeviceType type) {
    _cachedDeviceType = type;
  }
}
