class AppException implements Exception {
  final String? _message;
  final String? _prefix;
  final String? url;

  AppException([this._message, this._prefix, this.url]);

  String? get message => _message;

  @override
  String toString() {
    return "$_prefix$_message";
  }
}

class BadRequestException extends AppException {
  BadRequestException([String? message, String? url]) : super(message, 'Bad Request: ', url);
}

class FetchDataException extends AppException {
  FetchDataException([String? message, String? url]) : super(message, 'Unable to process: ', url);
}

class ApiNotRespondingException extends AppException {
  ApiNotRespondingException([String? message, String? url]) : super(message, 'API not responding: ', url);
}

class UnauthorisedException extends AppException {
  UnauthorisedException([String? message, String? url]) : super(message, 'Unauthorized: ', url);
}
