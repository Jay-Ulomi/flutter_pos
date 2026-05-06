class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? true,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      statusCode: json['statusCode'] as int?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool hasNext;

  PaginatedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.hasNext,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final contentList =
        (json['content'] as List?)
            ?.map((e) => fromJsonT(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PaginatedResponse(
      content: contentList,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['number'] ?? json['currentPage'] ?? 0,
      pageSize: json['size'] ?? json['pageSize'] ?? 20,
      hasNext: json['hasNext'] ?? !(json['last'] ?? true),
    );
  }
}
