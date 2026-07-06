sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class GameFailure extends Failure {
  const GameFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Error desconocido']);
}

// Resultado funcional — evita lanzar excepciones en lógica de negocio
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}
