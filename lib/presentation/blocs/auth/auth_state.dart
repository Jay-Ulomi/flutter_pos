import 'package:equatable/equatable.dart';

import '../../../data/models/auth_models.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticated,
  businessRequired,
  branchRequired,
  loading,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? businessId;
  final String? branchId;
  final String? selectedBusinessType;
  final List<UserBusiness> availableBusinesses;
  final Set<String> enabledFeatures;
  final String? errorMessage;
  // Subscription / trial
  final DateTime? trialEndsAt;
  final String? subscriptionStatus; // 'trial', 'active', 'expired', 'suspended'
  // Effective permissions for the active business. Contains '*' for privileged roles.
  final Set<String> permissions;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.businessId,
    this.branchId,
    this.selectedBusinessType,
    this.availableBusinesses = const [],
    this.enabledFeatures = const <String>{},
    this.errorMessage,
    this.trialEndsAt,
    this.subscriptionStatus,
    this.permissions = const <String>{},
  });

  const AuthState.unknown() : this();

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? businessId,
    String? branchId,
    String? selectedBusinessType,
    List<UserBusiness>? availableBusinesses,
    Set<String>? enabledFeatures,
    String? errorMessage,
    bool clearBusinessId = false,
    bool clearBranchId = false,
    bool clearError = false,
    DateTime? trialEndsAt,
    String? subscriptionStatus,
    bool clearTrial = false,
    Set<String>? permissions,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      businessId: clearBusinessId ? null : (businessId ?? this.businessId),
      branchId: clearBranchId ? null : (branchId ?? this.branchId),
      selectedBusinessType: selectedBusinessType ?? this.selectedBusinessType,
      availableBusinesses: availableBusinesses ?? this.availableBusinesses,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      trialEndsAt: clearTrial ? null : (trialEndsAt ?? this.trialEndsAt),
      subscriptionStatus: clearTrial ? null : (subscriptionStatus ?? this.subscriptionStatus),
      permissions: permissions ?? this.permissions,
    );
  }

  bool hasFeature(String featureName) => enabledFeatures.contains(featureName);

  /// Whether the current user may perform an action requiring [permission].
  /// Privileged roles carry '*' (all). Defaults to allow when permissions are
  /// unknown (e.g. offline before the first context sync) so we never wrongly
  /// block a legitimate manager who has no cached permission set yet.
  bool can(String permission) {
    if (permissions.isEmpty) return true;
    return permissions.contains('*') || permissions.contains(permission);
  }

  /// True when the subscription/trial has expired and the app should be blocked.
  bool get isTrialExpired {
    if (subscriptionStatus == 'expired' ||
        subscriptionStatus == 'suspended' ||
        subscriptionStatus == 'canceled') {
      return true;
    }
    if (trialEndsAt != null && DateTime.now().isAfter(trialEndsAt!)) {
      return true;
    }
    return false;
  }

  /// True when in grace period — reads allowed, writes blocked.
  bool get isPastDue => subscriptionStatus == 'past_due';

  /// Days remaining in trial. Null if not on trial. 0 = expired today.
  int? get trialDaysRemaining {
    if (trialEndsAt == null) return null;
    final diff = trialEndsAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// True if on a trial (even if still valid).
  bool get isOnTrial =>
      subscriptionStatus == 'trial' ||
      (subscriptionStatus == null && trialEndsAt != null);

  @override
  List<Object?> get props => [
    status,
    user,
    businessId,
    branchId,
    selectedBusinessType,
    availableBusinesses,
    enabledFeatures,
    errorMessage,
    trialEndsAt,
    subscriptionStatus,
    permissions,
  ];
}
