import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../core/network/dynamic_api_client.dart';
import '../../domain/entities/api_config.dart';
import '../bloc/admin_cubit.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _contentController = TextEditingController();
  final _liveController = TextEditingController();
  final _tokenController = TextEditingController();
  final _headersController = TextEditingController();
  final _jsonImportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().checkAuth();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _nameController.dispose();
    _baseUrlController.dispose();
    _categoriesController.dispose();
    _contentController.dispose();
    _liveController.dispose();
    _tokenController.dispose();
    _headersController.dispose();
    _jsonImportController.dispose();
    super.dispose();
  }

  void _populateFields(ApiConfig? config) {
    if (config == null) return;
    _nameController.text = config.name;
    _baseUrlController.text = config.baseUrl;
    _categoriesController.text = config.categoriesEndpoint ?? '';
    _contentController.text = config.contentEndpoint ?? '';
    _liveController.text = config.liveEndpoint ?? '';
    _tokenController.text = config.authToken ?? '';
    if (config.customHeaders != null) {
      _headersController.text = jsonEncode(config.customHeaders);
    }
  }

  ApiConfig _buildCurrentConfig() {
    Map<String, String>? headers;
    if (_headersController.text.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(_headersController.text.trim()) as Map;
        headers = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      } catch (_) {}
    }

    return ApiConfig(
      name: _nameController.text.trim().isEmpty ? 'Media Source' : _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      categoriesEndpoint: _categoriesController.text.trim().isEmpty ? null : _categoriesController.text.trim(),
      contentEndpoint: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
      liveEndpoint: _liveController.text.trim().isEmpty ? null : _liveController.text.trim(),
      authToken: _tokenController.text.trim().isEmpty ? null : _tokenController.text.trim(),
      customHeaders: headers,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Painel Administrativo - Configuração de Mídia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Importar JSON',
            onPressed: () => _showJsonImportDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminLoaded) {
            if (state.config != null && _baseUrlController.text.isEmpty) {
              _populateFields(state.config);
            }
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppTheme.danger,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is AdminAuthRequired) {
            return _buildAuthView(context, state.isIncorrect);
          }

          if (state is AdminLoaded) {
            return _buildFormView(context, state);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildAuthView(BuildContext context, bool isIncorrect) {
    return Center(
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: AppTheme.secondary),
            const SizedBox(height: 16),
            const Text(
              'Acesso Restrito',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Insira o PIN do administrador para gerenciar os endpoints.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '••••',
                errorText: isIncorrect ? 'PIN incorreto. Padrão: 0000' : null,
              ),
              onSubmitted: (pin) => context.read<AdminCubit>().authenticate(pin),
            ),
            const SizedBox(height: 24),
            TvFocusable(
              onPressed: () => context.read<AdminCubit>().authenticate(_pinController.text),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, AdminLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Configuração de Endpoints',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TvFocusable(
                            onPressed: () => _showJsonImportDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.secondary),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.file_upload_outlined, size: 18, color: AppTheme.secondary),
                                  SizedBox(width: 8),
                                  Text('Colar JSON', style: TextStyle(color: AppTheme.secondary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Provedor / Servidor',
                          prefixIcon: Icon(Icons.dns_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _baseUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Base URL (ex: https://meu-servidor-midia.com)',
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _categoriesController,
                        decoration: const InputDecoration(
                          labelText: 'Endpoint de Categorias (ex: /api/v1/categories)',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Endpoint de Conteúdo / Catálogo (ex: /api/v1/content)',
                          prefixIcon: Icon(Icons.movie_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _liveController,
                        decoration: const InputDecoration(
                          labelText: 'Endpoint de Canais ao Vivo (ex: /api/v1/live)',
                          prefixIcon: Icon(Icons.live_tv_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Bearer Token de Autenticação (Opcional)',
                          prefixIcon: Icon(Icons.key_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _headersController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Cabeçalhos Customizados em JSON (Opcional)',
                          hintText: '{"X-API-Key": "segredo", "User-Agent": "CustomApp"}',
                          prefixIcon: Icon(Icons.code),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Exibição dos resultados de validação em tempo real
              if (state.validationResults != null) ...[
                const Text(
                  'Diagnóstico de Conectividade em Tempo Real',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...state.validationResults!.entries.map((entry) {
                  final key = entry.key;
                  final res = entry.value;
                  return _buildEndpointStatusCard(key, res);
                }),
                const SizedBox(height: 16),
              ],

              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: TvFocusable(
                      onPressed: state.isValidating
                          ? null
                          : () {
                              final config = _buildCurrentConfig();
                              context.read<AdminCubit>().validateConnectivity(config);
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: state.isValidating
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Testando Conexão...', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.network_check),
                                  SizedBox(width: 8),
                                  Text(
                                    'Validar Conectividade em Tempo Real',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TvFocusable(
                      onPressed: state.isSaving
                          ? null
                          : () {
                              final config = _buildCurrentConfig();
                              context.read<AdminCubit>().saveConfiguration(config);
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: state.isSaving
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_outlined),
                                  SizedBox(width: 8),
                                  Text(
                                    'Salvar Configuração no Dispositivo',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndpointStatusCard(String label, EndpointValidationResult res) {
    final isOnline = res.isReachable;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOnline ? AppTheme.success.withOpacity(0.4) : AppTheme.danger.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.check_circle : Icons.error,
            color: isOnline ? AppTheme.success : AppTheme.danger,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  res.endpoint,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isOnline ? AppTheme.success.withOpacity(0.2) : AppTheme.danger.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOnline ? 'HTTP ${res.statusCode ?? 200}' : (res.statusCode != null ? 'HTTP ${res.statusCode}' : 'FALHA'),
                  style: TextStyle(
                    color: isOnline ? AppTheme.success : AppTheme.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${res.latencyMs} ms',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showJsonImportDialog(BuildContext context) {
    _jsonImportController.clear();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Importar Configuração JSON'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cole o conteúdo JSON com as definições de base_url, endpoints e headers:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _jsonImportController,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '{\n  "base_url": "https://api.exemplo.com",\n  "categories_endpoint": "/categories"\n}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = _jsonImportController.text.trim();
              if (raw.isNotEmpty) {
                context.read<AdminCubit>().importFromJson(raw);
                try {
                  final map = jsonDecode(raw) as Map<String, dynamic>;
                  final model = ApiConfig(
                    name: map['name'] ?? 'Media Source',
                    baseUrl: map['base_url'] ?? map['baseUrl'] ?? '',
                    categoriesEndpoint: map['categories_endpoint'] ?? map['categoriesEndpoint'],
                    contentEndpoint: map['content_endpoint'] ?? map['contentEndpoint'],
                    liveEndpoint: map['live_endpoint'] ?? map['liveEndpoint'],
                    authToken: map['auth_token'] ?? map['authToken'],
                    customHeaders: map['custom_headers'] != null ? Map<String, String>.from(map['custom_headers']) : null,
                    lastUpdated: DateTime.now(),
                  );
                  _populateFields(model);
                } catch (_) {}
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }
}
