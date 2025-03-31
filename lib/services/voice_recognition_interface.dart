abstract class VoiceRecognitionInterface {
  Future<bool> initialize({
    Function(String)? onResult,
    Function()? onFinished,
    Function(String)? onError,
  });

  Future<bool> startListening();
  Future<void> stopListening();
  Future<void> dispose();
}
