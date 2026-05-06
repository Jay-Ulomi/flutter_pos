class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse(
      success: json['success'] ?? true,
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final bool hasNext;

  PaginatedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.hasNext,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final contentList =
        (json['content'] as List?)
            ?.map((e) => fromItem(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PaginatedResponse(
      content: contentList,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['number'] ?? 0,
      hasNext: !(json['last'] ?? true),
    );
  }
}
