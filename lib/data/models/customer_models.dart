import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String? code;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? tinNumber;
  final String? customerType;
  final String? customerGroupId;
  final double currentBalance;
  final int loyaltyPoints;
  final bool isActive;
  final DateTime? updatedAt;

  const Customer({
    required this.id,
    this.code,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.tinNumber,
    this.customerType,
    this.customerGroupId,
    this.currentBalance = 0,
    this.loyaltyPoints = 0,
    this.isActive = true,
    this.updatedAt,
  });

  Customer copyWith({
    String? id,
    String? code,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? tinNumber,
    String? customerType,
    String? customerGroupId,
    double? currentBalance,
    int? loyaltyPoints,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      tinNumber: tinNumber ?? this.tinNumber,
      customerType: customerType ?? this.customerType,
      customerGroupId: customerGroupId ?? this.customerGroupId,
      currentBalance: currentBalance ?? this.currentBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString(),
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      tinNumber: json['tinNumber'],
      customerType: json['customerType']?.toString(),
      customerGroupId: json['customerGroupId']?.toString(),
      currentBalance: (json['currentBalance'] ?? 0).toDouble(),
      loyaltyPoints: (json['loyaltyPoints'] ?? 0) is int
          ? (json['loyaltyPoints'] ?? 0) as int
          : int.tryParse('${json['loyaltyPoints']}') ?? 0,
      isActive: json['isActive'] ?? json['active'] ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'tinNumber': tinNumber,
    'customerType': customerType,
    'customerGroupId': customerGroupId,
    'currentBalance': currentBalance,
    'loyaltyPoints': loyaltyPoints,
    'isActive': isActive,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  Map<String, dynamic> toCreateRequest() => {
    'name': name,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (address != null) 'address': address,
    if (tinNumber != null) 'tinNumber': tinNumber,
    if (customerType != null) 'customerType': customerType,
    if (customerGroupId != null) 'customerGroupId': customerGroupId,
  };

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    email,
    phone,
    currentBalance,
    loyaltyPoints,
    isActive,
  ];
}

class CustomerGroup extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double? discountPercent;
  final bool isActive;

  const CustomerGroup({
    required this.id,
    required this.name,
    this.description,
    this.discountPercent,
    this.isActive = true,
  });

  CustomerGroup copyWith({
    String? id,
    String? name,
    String? description,
    double? discountPercent,
    bool? isActive,
  }) {
    return CustomerGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      discountPercent: discountPercent ?? this.discountPercent,
      isActive: isActive ?? this.isActive,
    );
  }

  factory CustomerGroup.fromJson(Map<String, dynamic> json) {
    return CustomerGroup(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
      isActive: json['isActive'] ?? json['active'] ?? true,
    );
  }

  Map<String, dynamic> toCreateRequest() => {
    'name': name,
    if (description != null) 'description': description,
    if (discountPercent != null) 'discountPercent': discountPercent,
    'isActive': isActive,
  };

  @override
  List<Object?> get props => [id, name, description, discountPercent, isActive];
}
