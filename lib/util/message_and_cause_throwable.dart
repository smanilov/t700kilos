/// A generic exception or error that optionally has a message and a cause
/// (another throwable).
abstract class MessageAndCauseThrowable {
  final String? message;

  /// Another throwable that was the cause of this one.
  final dynamic cause;

  MessageAndCauseThrowable({this.message, this.cause});

  @override
  String toString() {
    if (message != null && cause == null) return message!;
    if (message == null && cause != null) return cause.toString();
    if (message == null && cause == null) return '<no details>';
    return '{message: $message, cause: $cause}';
  }
}
