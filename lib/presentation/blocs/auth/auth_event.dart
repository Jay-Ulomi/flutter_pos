import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSelectBusiness extends AuthEvent {
  final String businessId;
  final String? branchId;
  final String? businessType;

  const AuthSelectBusiness({
    required this.businessId,
    this.branchId,
    this.businessType,
  });

  @override
  List<Object?> get props => [businessId, branchId, businessType];
}

class AuthSelectBranch extends AuthEvent {
  final String branchId;

  const AuthSelectBranch({required this.branchId});

  @override
  List<Object?> get props => [branchId];
}

class AuthLoadBusinesses extends AuthEvent {
  const AuthLoadBusinesses();
}

class AuthLoadBranches extends AuthEvent {
  final String businessId;

  const AuthLoadBranches({required this.businessId});

  @override
  List<Object?> get props => [businessId];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
