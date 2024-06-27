class ApiResult {
  bool success;
  Body? body;

  ApiResult({required this.success, this.body});
}

class Body {
  String status;
  String message;
  dynamic value;

  Body({required this.status, required this.message, this.value});

  static Body? fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    return Body(
      status: data['status'],
      message: data['message'],
      value: data['body'],
    );
  }
}
