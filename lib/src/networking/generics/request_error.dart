/// Request error with optional typed error response
sealed class RequestError<T> implements Exception {
  const RequestError._();
}

/// Invalid URL error
class InvalidURLError<T> extends RequestError<T> {
  const InvalidURLError() : super._();

  @override
  String toString() => 'RequestError.invalidURL';
}

/// No response error
class NoResponseError<T> extends RequestError<T> {
  const NoResponseError() : super._();

  @override
  String toString() => 'RequestError.noResponse';
}

/// Decoding error
class DecodingError<T> extends RequestError<T> {
  const DecodingError({required this.error, required this.data}) : super._();

  final Object error;
  final List<int> data;

  @override
  String toString() => 'RequestError.decodingError(error: $error)';
}

/// Unauthorized error (401)
class UnauthorizedError<T> extends RequestError<T> {
  const UnauthorizedError() : super._();

  @override
  String toString() => 'RequestError.unauthorized';
}

/// Invalid response error
class InvalidResponseError<T> extends RequestError<T> {
  const InvalidResponseError({required this.statusCode, this.response})
    : super._();

  final int statusCode;
  final String? response;

  @override
  String toString() =>
      'RequestError.invalidResponse(statusCode: $statusCode, response: $response)';
}

/// Unknown error
class UnknownError<T> extends RequestError<T> {
  const UnknownError({
    required this.statusCode,
    required this.error,
    this.response,
  }) : super._();

  final int statusCode;
  final String? response;
  final Object error;

  @override
  String toString() =>
      'RequestError.unknownError(statusCode: $statusCode, error: $error)';
}

/// Error with typed error response
class KeetaError<T> extends RequestError<T> {
  const KeetaError({required this.statusCode, required this.error}) : super._();

  final int statusCode;
  final T error;

  @override
  String toString() =>
      'RequestError.error(statusCode: $statusCode, error: $error)';
}
