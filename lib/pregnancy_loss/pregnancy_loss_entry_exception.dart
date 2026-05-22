/// User-visible failure when entering pregnancy-loss mode (callable / auth).
class PregnancyLossEntryException implements Exception {
  PregnancyLossEntryException(this.message);

  final String message;

  @override
  String toString() => message;
}
