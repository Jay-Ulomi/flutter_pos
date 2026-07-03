import 'package:equatable/equatable.dart';

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;
  final List<UserBusiness> businesses;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.businesses,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns flat fields (userId, firstName, etc.), not a nested user object
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: User(
        id: json['userId']?.toString() ?? '',
        email: json['email'] ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        role: json['role'] ?? json['roleName'] ?? '',
      ),
      businesses:
          (json['businesses'] as List?)
              ?.map((e) => UserBusiness.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class User extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'role': role,
  };

  @override
  List<Object?> get props => [id, email, firstName, lastName, phone, role];
}

class UserBusiness extends Equatable {
  final String id;
  final String name;
  final String? role;

  const UserBusiness({required this.id, required this.name, this.role});

  factory UserBusiness.fromJson(Map<String, dynamic> json) {
    return UserBusiness(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      role: json['role'],
    );
  }

  @override
  List<Object?> get props => [id, name, role];
}

class TenantFeature extends Equatable {
  final String featureName;
  final String? featureValue;
  final bool enabled;

  const TenantFeature({
    required this.featureName,
    this.featureValue,
    required this.enabled,
  });

  factory TenantFeature.fromJson(Map<String, dynamic> json) {
    return TenantFeature(
      featureName: json['featureName']?.toString() ?? '',
      featureValue: json['featureValue']?.toString(),
      enabled: json['enabled'] == true || json['isEnabled'] == true,
    );
  }

  @override
  List<Object?> get props => [featureName, featureValue, enabled];
}

/// Current subscription from GET /api/subscriptions/current
/// Backend statuses: TRIAL | ACTIVE | PAST_DUE | SUSPENDED | CANCELED | EXPIRED
class SubscriptionInfo extends Equatable {
  final String status;          // lowercase: trial, active, expired, suspended…
  final DateTime? trialEndDate; // null when not on trial
  final DateTime? endDate;

  const SubscriptionInfo({
    required this.status,
    this.trialEndDate,
    this.endDate,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      status: (json['status']?.toString() ?? '').toLowerCase(),
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.tryParse(json['trialEndDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [status, trialEndDate, endDate];
}

class SwitchContextRequest {
  final String businessId;
  final String? branchId;

  SwitchContextRequest({required this.businessId, this.branchId});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'businessId': businessId};
    if (branchId != null) map['branchId'] = branchId;
    return map;
  }
}

class ContextResponse {
  final String accessToken;
  final String refreshToken;
  final String businessId;
  final String? branchId;

  /// Effective permission names for this business. `['*']` means all (privileged
  /// role); empty list means the role has no explicit grants.
  final List<String> permissions;

  ContextResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.businessId,
    this.branchId,
    this.permissions = const [],
  });

  factory ContextResponse.fromJson(Map<String, dynamic> json) {
    return ContextResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      businessId: json['businessId']?.toString() ?? '',
      branchId: json['branchId']?.toString(), // null if branch not yet selected
      permissions: (json['permissions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
