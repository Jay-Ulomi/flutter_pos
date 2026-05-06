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
    );
  }

  bool hasFeature(String featureName) => enabledFeatures.contains(featureName);

  /// True when the subscription/trial has expired and the app should be blocked.
  bool get isTrialExpired {
    if (subscriptionStatus == 'expired' || subscriptionStatus == 'suspended') {
      return true;
    }
    if (trialEndsAt != null && DateTime.now().isAfter(trialEndsAt!)) {
      return true;
    }
    return false;
  }

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
  ];
}
