import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:keeta/src/networking/generics/request_error.dart';
import 'package:keeta/src/networking/responses/certificate_content_response.dart';
import 'package:keeta/src/networking/responses/vote_response.dart';

/// Endpoint configuration for HTTP requests
class Endpoint {
  const Endpoint({
    required this.url,
    required this.method,
    this.query = const <String, String>{},
    this.header = const <String, String>{},
    this.body,
  });

  final Uri url;
  final String method;
  final Map<String, String> query;
  final Map<String, String> header;
  final Map<String, dynamic>? body;
}

/// HTTP Client base class for making API requests
abstract class HTTPClient {
  /// Sends a request and decodes the response with custom error type handling
  Future<R> sendRequest<R, E>({
    required final Endpoint to,
    final E Function(Map<String, dynamic>)? errorDecoder,
  }) async {
    try {
      return await sendRequestDecoded<R>(to: to);
    } on InvalidResponseError<void> catch (e) {
      if (e.response != null && errorDecoder != null) {
        try {
          final Map<String, dynamic> errorData =
              jsonDecode(e.response!) as Map<String, dynamic>;
          final E error = errorDecoder(errorData);
          throw KeetaError<E>(statusCode: e.statusCode, error: error);
        } catch (decodeError) {
          throw UnknownError<E>(
            statusCode: e.statusCode,
            response: e.response,
            error: decodeError,
          );
        }
      }
      rethrow;
    }
  }

  /// Sends a request and decodes the response
  Future<T> sendRequestDecoded<T>({required final Endpoint to}) async {
    final List<int> data = await sendRequestRaw(to: to);

    try {
      final Map<String, dynamic> jsonData =
          jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return _decodeResponse<T>(jsonData);
    } catch (error) {
      if (error is RequestError) {
        rethrow;
      }

      throw DecodingError<void>(error: error, data: data);
    }
  }

  /// Sends a raw HTTP request and returns the response data
  Future<List<int>> sendRequestRaw({required final Endpoint to}) async {
    final Uri uri = to.url;

    // Add query parameters if present
    final Uri finalUri;
    if (to.query.isNotEmpty) {
      finalUri = uri.replace(
        queryParameters: <String, dynamic>{...uri.queryParameters, ...to.query},
      );
    } else {
      finalUri = uri;
    }

    final http.Request request = http.Request(to.method, finalUri);

    // Add headers
    request.headers.addAll(to.header);

    // Add body if present
    if (to.body != null) {
      request.body = jsonEncode(to.body);
      request.headers['Content-Type'] = 'application/json';
    }

    try {
      final http.StreamedResponse streamedResponse = await request.send();
      final http.Response response = await http.Response.fromStream(
        streamedResponse,
      );

      // Check status code
      switch (response.statusCode) {
        case >= 200 && < 300:
          return response.bodyBytes;
        case 401:
          throw const UnauthorizedError<void>();
        default:
          throw InvalidResponseError<void>(
            statusCode: response.statusCode,
            response: response.body,
          );
      }
    } on SocketException {
      throw const NoResponseError<void>();
    } catch (e) {
      if (e is RequestError) {
        rethrow;
      }
      throw const NoResponseError<void>();
    }
  }

  /// Helper method to decode response based on type
  /// Override this method in subclasses to provide custom decoding logic
  /// Generic response decoder — tries to find the correct `fromJson` factory
  T _decodeResponse<T>(final Map<String, dynamic> json) {
    final Function(Map<String, dynamic> p1)? fromJson =
        _findFromJsonFactory<T>();
    if (fromJson != null) {
      return fromJson(json);
    }

    throw UnimplementedError(
      'Decoding for type $T not implemented. '
      '''
Ensure $T has a fromJson(Map<String, dynamic>) factory or override _decodeResponse.''',
    );
  }

  /// Registers known decoders for different response types
  Function(Map<String, dynamic>)? _findFromJsonFactory<T>() {
    switch (T) {
      // Add mappings for all your models here 👇
      case VoteResponse _:
        return VoteResponse.fromJson;
      case const (CertificateContentResponse):
        return CertificateContentResponse.fromJson;
      default:
        return null;
    }
  }
}
