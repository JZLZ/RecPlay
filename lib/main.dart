import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/device/device_detector.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/domain/repositories/api_config_repository.dart';
import 'features/admin/presentation/bloc/admin_cubit.dart';
import 'features/catalog/data/repositories/catalog_repository.dart';
import 'features/catalog/presentation/pages/catalog_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Service Locator (Clean Architecture)
  await di.initDependencies();

  // Otimização de tela para Android TV e Mobile (Modo Imersivo)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const AstraApp());
}

class AstraApp extends StatelessWidget {
  const AstraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AdminCubit>(
          create: (_) => di.sl<AdminCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'Astra',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: CatalogPage(
          deviceDetector: di.sl<DeviceDetector>(),
          catalogRepository: di.sl<CatalogRepository>(),
          configRepository: di.sl<ApiConfigRepository>(),
        ),
      ),
    );
  }
}
