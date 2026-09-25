abstract class Failure {
  final String errorMessage;
  const Failure({required this.errorMessage});

  @override
  String toString() => '$runtimeType(errorMessage: $errorMessage)';

  @override
  int get hashCode => Object.hash(runtimeType, errorMessage);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is Failure &&
          other.errorMessage == errorMessage;
}

class ServerFailure extends Failure {
  /// Code HTTP de la réponse (optionnel), utile pour distinguer par ex. un
  /// 404 (ressource inexistante) d'une véritable erreur serveur.
  final int? statusCode;

  ServerFailure({required String errorMessage, this.statusCode})
      : super(errorMessage: errorMessage);
}

class CacheFailure extends Failure {
  CacheFailure({required String errorMessage})
      : super(errorMessage: errorMessage);
}
