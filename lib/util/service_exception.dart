/// A message suitable for displaying to the reader, without provider payloads.
class ServiceException implements Exception {
  final String message;
  const ServiceException(this.message);

  @override
  String toString() => message;
}
