import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/token_manager.dart';
import '../../../data/models/auth_models.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final TokenManager _tokenManager;

  AuthBloc(this._authRepository, this._tokenManager)
    : super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSelectBusiness>(_onSelectBusiness);
    on<AuthSelectBranch>(_onSelectBranch);
    on<AuthLoadBusinesses>(_onLoadBusinesses);
    on<AuthLoadBranches>(_onLoadBranches);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<
    ({
      Set<String> features,
      DateTime? trialEndsAt,
      String? subscriptionStatus,
    })
  >
  _loadTenantData() async {
    // Both calls are best-effort — failures (including offline) return empty/null.
    final results = await Future.wait([
      _authRepository.getTenantFeatures().catchError((_) => <TenantFeature>[]),
      _authRepository.getSubscription().catchError((_) => null),
    ]);

    final featureList = results[0] as List<TenantFeature>;
    final subscription = results[1] as SubscriptionInfo?;

    final enabled = featureList
        .where((f) => f.enabled && f.featureName.isNotEmpty)
        .map((f) => f.featureName)
        .toSet();

    return (
      features: enabled,
      trialEndsAt: subscription?.trialEndDate,
      subscriptionStatus: subscription?.status,
    );
  }

  // ── Startup check ────────────────────────────────────────────────────────
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final token = await _tokenManager.getAccessToken();
    if (token == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }

    User? user;
    final userJson = await _tokenManager.getUserJson();
    if (userJson != null) {
      try {
        user = User.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }
    if (user == null) {
      // /api/auth/me doesn't exist yet — treat as unauthenticated
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }

    final savedBizId = await _tokenManager.getBusinessId();
    final savedBranch = await _tokenManager.getBranchId();

    // If we have a saved default business+branch, try to re-establish context
    if (savedBizId != null && savedBranch != null &&
        savedBizId.isNotEmpty && savedBranch.isNotEmpty) {
      try {
        final ctx = await _authRepository.switchContext(
          SwitchContextRequest(businessId: savedBizId, branchId: savedBranch),
        );
        final tenantData = await _loadTenantData();
        String? businessType;
        try {
          final businesses = await _authRepository.getBusinesses();
          for (final business in businesses) {
            if (business.id == ctx.businessId) {
              businessType = business.type;
              break;
            }
          }
        } catch (_) {}
        // Cache businessType for offline use
        if (businessType != null) {
          await _tokenManager.saveBusinessType(businessType);
        }
        final perms = ctx.permissions.toSet();
        await _tokenManager.savePermissions(perms);
        emit(
          AuthState(
            status: AuthStatus.authenticated,
            user: user,
            businessId: ctx.businessId,
            branchId: ctx.branchId,
            selectedBusinessType: businessType,
            enabledFeatures: tenantData.features,
            trialEndsAt: tenantData.trialEndsAt,
            subscriptionStatus: tenantData.subscriptionStatus,
            permissions: perms,
          ),
        );
        return;
      } catch (e) {
        if (e is NetworkException) {
          // Offline — resume with cached context so user can still use the app
          final cachedType = await _tokenManager.getBusinessType();
          final cachedPerms = await _tokenManager.getPermissions();
          emit(
            AuthState(
              status: AuthStatus.authenticated,
              user: user,
              businessId: savedBizId,
              branchId: savedBranch,
              selectedBusinessType: cachedType,
              enabledFeatures: const {},
              permissions: cachedPerms,
            ),
          );
          return;
        }
        // Real server error (branch deleted, business suspended, etc.) — ask user
        await _tokenManager.saveBusinessId('');
        await _tokenManager.saveBranchId('');
      }
    }

    // No saved context — need business/branch selection
    emit(AuthState(status: AuthStatus.businessRequired, user: user));
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final response = await _authRepository.login(
        LoginRequest(email: event.email, password: event.password),
      );

      // Load businesses immediately after login
      final businesses = await _authRepository.getBusinesses();
      final bizList = businesses
          .map((b) => UserBusiness(id: b.id, name: b.name))
          .toList();

      // Auto-select if only one business
      if (bizList.length == 1) {
        emit(
          AuthState(
            status: AuthStatus.branchRequired,
            user: response.user,
            businessId: bizList.first.id,
            selectedBusinessType: businesses.first.type,
            availableBusinesses: bizList,
          ),
        );
        return;
      }

      emit(
        AuthState(
          status: AuthStatus.businessRequired,
          user: response.user,
          availableBusinesses: bizList,
        ),
      );
    } catch (e) {
      if (_isSessionExpired(e)) return _emitSessionExpired(emit);
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  // ── Load businesses ───────────────────────────────────────────────────────
  Future<void> _onLoadBusinesses(
    AuthLoadBusinesses event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final businesses = await _authRepository.getBusinesses();
      final bizList = businesses
          .map((b) => UserBusiness(id: b.id, name: b.name))
          .toList();

      // Auto-select if only one
      if (bizList.length == 1) {
        emit(
          state.copyWith(
            status: AuthStatus.branchRequired,
            businessId: bizList.first.id,
            selectedBusinessType: businesses.first.type,
            availableBusinesses: bizList,
          ),
        );
        return;
      }

      emit(state.copyWith(availableBusinesses: bizList));
    } catch (e) {
      if (_isSessionExpired(e)) return _emitSessionExpired(emit);
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  // ── Select business ───────────────────────────────────────────────────────
  // Does NOT call switchContext — backend requires both business+branch.
  // Just stores the selection and moves to branch selection.
  Future<void> _onSelectBusiness(
    AuthSelectBusiness event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.branchRequired,
        businessId: event.businessId,
        selectedBusinessType: event.businessType,
      ),
    );
  }

  // ── Load branches ─────────────────────────────────────────────────────────
  Future<void> _onLoadBranches(
    AuthLoadBranches event,
    Emitter<AuthState> emit,
  ) async {
    // Branches are loaded by BranchBloc; no-op here
  }

  // ── Select branch → complete context switch ───────────────────────────────
  Future<void> _onSelectBranch(
    AuthSelectBranch event,
    Emitter<AuthState> emit,
  ) async {
    final businessId = state.businessId;
    if (businessId == null) {
      emit(
        state.copyWith(
          status: AuthStatus.businessRequired,
          errorMessage: 'Please select a business first',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final ctx = await _authRepository.switchContext(
        SwitchContextRequest(businessId: businessId, branchId: event.branchId),
      );
      final tenantData = await _loadTenantData();

      // Save as default for next startup (including offline resume)
      await _tokenManager.saveBusinessId(ctx.businessId);
      await _tokenManager.saveBranchId(ctx.branchId ?? event.branchId);
      if (state.selectedBusinessType != null) {
        await _tokenManager.saveBusinessType(state.selectedBusinessType!);
      }
      final perms = ctx.permissions.toSet();
      await _tokenManager.savePermissions(perms);

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          businessId: ctx.businessId,
          branchId: ctx.branchId ?? event.branchId,
          selectedBusinessType: state.selectedBusinessType,
          enabledFeatures: tenantData.features,
          trialEndsAt: tenantData.trialEndsAt,
          subscriptionStatus: tenantData.subscriptionStatus,
          permissions: perms,
        ),
      );
    } catch (e) {
      if (_isSessionExpired(e)) return _emitSessionExpired(emit);
      emit(
        state.copyWith(
          status: AuthStatus.branchRequired,
          errorMessage: humanizeError(e),
        ),
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  // ── Session-expired detection ─────────────────────────────────────────────
  // ApiClient already attempted a token refresh before propagating the error.
  // A 401 that reaches the bloc means the refresh token is also expired —
  // the session is fully dead and the user must log in again.
  bool _isSessionExpired(Object e) =>
      e is ServerException && e.statusCode == 401;

  void _emitSessionExpired(Emitter<AuthState> emit) {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
