/// JSON type alias
typedef JSON = Map<String, dynamic>;

/// Endpoint protocol for HTTP requests
abstract class Endpoint {
  const Endpoint();

  Uri get url;
  RequestMethod get method;
  Map<String, String>? get header;
  Map<String, String> get query;
  JSON? get body;
}

/// HTTP request methods
enum RequestMethod {
  delete,
  get,
  patch,
  post,
  put;

  String get value => name.toUpperCase();
}
