import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/api_config.dart';
import '../../domain/repositories/api_config_repository.dart';
import '../../data/models/api_config_model.dart';
import '../../../../core/network/dynamic_api_client.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminAuthRequired extends AdminState {
  final bool isIncorrect;
  const AdminAuthRequired({this.isIncorrect = false});

  @override
  List<Object?> get props => [isIncorrect];
}

class AdminLoaded extends AdminState {
  final ApiConfig? config;
  final Map<String, EndpointValidationResult>? validationResults;
  final bool isValidating;
  final bool isSaving;
  final String? successMessage;
  final String? errorMessage;

  const AdminLoaded({
    this.config,
    this.validationResults,
    this.isValidating = false,
    this.isSaving = false,
    this.successMessage,
    this.errorMessage,
  });

  AdminLoaded copyWith({
    ApiConfig? config,
    Map<String, EndpointValidationResult>? validationResults,
    bool? isValidating,
    bool? isSaving,
    String? successMessage,
    String? errorMessage,
  }) {
    return AdminLoaded(
      config: config ?? this.config,
      validationResults: validationResults ?? this.validationResults,
      isValidating: isValidating ?? this.isValidating,
      isSaving: isSaving ?? this.isSaving,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        config,
        validationResults,
        isValidating,
        isSaving,
        successMessage,
        errorMessage,
      ];
}

class AdminCubit extends Cubit<AdminState> {
  final ApiConfigRepository _repository;

  AdminCubit(this._repository) : super(AdminInitial());

  Future<void> checkAuth() async {
    emit(const AdminAuthRequired());
  }

  Future<void> authenticate(String pin) async {
    final isValid = await _repository.verifyAdminPin(pin);
    if (isValid) {
      await loadConfig();
    } else {
      emit(const AdminAuthRequired(isIncorrect: true));
    }
  }

  Future<void> loadConfig() async {
    final active = await _repository.getActiveConfig();
    emit(AdminLoaded(config: active));
  }

  Future<void> importFromJson(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final model = ApiConfigModel.fromJson(decoded);
      if (state is AdminLoaded) {
        emit((state as AdminLoaded).copyWith(
          config: model,
          successMessage: 'Configuração JSON importada com sucesso!',
        ));
      } else {
        emit(AdminLoaded(config: model, successMessage: 'Configuração importada!'));
      }
    } catch (e) {
      if (state is AdminLoaded) {
        emit((state as AdminLoaded).copyWith(
          errorMessage: 'Formato JSON inválido: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> validateConnectivity(ApiConfig config) async {
    if (state is! AdminLoaded) return;
    final current = state as AdminLoaded;

    emit(current.copyWith(isValidating: true, successMessage: null, errorMessage: null));

    try {
      final results = await _repository.validateAllEndpoints(config);
      emit(current.copyWith(
        isValidating: false,
        validationResults: results,
        successMessage: 'Teste de conectividade finalizado.',
      ));
    } catch (e) {
      emit(current.copyWith(
        isValidating: false,
        errorMessage: 'Falha durante o teste: ${e.toString()}',
      ));
    }
  }

  Future<void> saveConfiguration(ApiConfig config) async {
    if (state is! AdminLoaded) return;
    final current = state as AdminLoaded;

    emit(current.copyWith(isSaving: true, successMessage: null, errorMessage: null));

    try {
      await _repository.saveConfig(config);
      emit(current.copyWith(
        config: config,
        isSaving: false,
        successMessage: 'Configuração gravada permanentemente no armazenamento seguro!',
      ));
    } catch (e) {
      emit(current.copyWith(
        isSaving: false,
        errorMessage: 'Erro ao salvar configuração: ${e.toString()}',
      ));
    }
  }
}
