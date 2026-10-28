abstract class AppException implements Exception {
  final String message;
  const AppException({required this.message});
}
 
class ServerException extends AppException {
  const ServerException({required super.message});
}
 
class CacheException extends AppException {
  const CacheException({required super.message});
}
 
// Renombrada para no colisionar con FormatException de Dart core
class InvalidFormatException extends AppException {
  const InvalidFormatException({required super.message});
}
 
class ConnectionException extends AppException {
  const ConnectionException({required super.message});
}
 