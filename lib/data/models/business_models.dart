import 'package:equatable/equatable.dart';

class Business extends Equatable {
  final String id;
  final String name;
  final String? type;
  final String? description;
  final String? phone;
  final String? email;
  final String? address;
  final String? tinNumber;
  final String? logoUrl;
  final List<Branch> branches;

  const Business({
    required this.id,
    required this.name,
    this.type,
    this.description,
    this.phone,
    this.email,
    this.address,
    this.tinNumber,
    this.logoUrl,
    this.branches = const [],
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: json['type']?.toString(),
      description: json['description'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      tinNumber: json['tinNumber'],
      logoUrl: json['logoUrl'],
      branches:
          (json['branches'] as List?)
              ?.map((e) => Branch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    description,
    phone,
    email,
    address,
    tinNumber,
  ];
}

class Branch extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;

  const Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      isActive: json['active'] ?? json['isActive'] ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, address, phone, isActive];
}
