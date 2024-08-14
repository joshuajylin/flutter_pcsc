import 'package:flutter_pcsc_macos/src/pcsc_bindings.dart';
import 'package:flutter_pcsc_platform_interface/flutter_pcsc_platform_interface.dart';

/// The main class to use to deal with PCSC.
class PcscMacOS extends PcscPlatform {
  static void registerWith() {
    PcscPlatform.instance = PcscMacOS();
  }

  static final PCSCBinding _binding = PCSCBinding();

  /*
   * Not really asynchronous (the C call is synchronous), but it will be easier to use if a Future is returned
   * The only true asynchronous methods are:
   * - waitForCardPresent
   * - waitForCardRemoved
   * which uses an Isolate to really be async
   */

  /// Establishes a PCSC context.
  @override
  Future<int> establishContext(int scope) {
    return _binding.establishContext(scope);
  }

  /// Lists available readers for this context.
  @override
  Future<List<String>> listReaders(int context) {
    return _binding.listReaders(context);
  }

  /// Connects to the card using the specified reader.
  @override
  Future<Map> cardConnect(
      int context, String reader, int shareMode, int protocol) {
    return _binding.cardConnect(context, reader, shareMode, protocol);
  }

  /// Transmits an APDU to the card.
  @override
  Future<List<int>> transmit(
      int hCard, int activeProtocol, List<int> commandBytes,
      {bool newIsolate = false}) {
    return _binding.transmit(hCard, activeProtocol, commandBytes,
        newIsolate: newIsolate);
  }

  /// Get status change for the card
  @override
  Future<Map> cardGetStatusChange(int context, String readerName,
      {int currentState = PcscConstants.SCARD_STATE_UNAWARE, int timeout = PcscConstants.SCARD_INFINITE}) {
    return _binding.cardGetStatusChange(context, readerName, currentState: currentState, timeout: timeout);
  }

  /// Cancel blocking cardGetStatusChange for the context
  @override
  Future<void> cardCancel(int context) {
    return _binding.cardCancel(context);
  }

  /// Disconnects from the card.
  @override
  Future<void> cardDisconnect(int hCard, int disposition) {
    return _binding.cardDisconnect(hCard, disposition);
  }

  /// Releases the PCSC context.
  @override
  Future<void> releaseContext(int context) {
    return _binding.releaseContext(context);
  }

  /// Waits for a card to be present on the specified reader.
  ///
  /// If a card is already present, it does not wait.
  @override
  Future<Map> waitForCardPresent(int context, String readerName,
      {int timeout = PcscConstants.SCARD_INFINITE}) {
    return _binding.waitForCardPresent(context, readerName, timeout);
  }

  /// Waits for a card to be removed on the specified reader.
  ///
  /// If a card is already removed, it does not wait.
  @override
  Future<void> waitForCardRemoved(int context, String readerName,
      {int timeout = PcscConstants.SCARD_INFINITE}) {
    return _binding.waitForCardRemoved(context, readerName, timeout);
  }

  /// Waits for a card's status to be changed on the specified reader.
  @override
  Future<Map> waitForCardStatusChanged(int context, String readerName,
      {int timeout = PcscConstants.SCARD_INFINITE}) {
    return _binding.waitForCardStatusChanged(context, readerName, timeout);
  }

  /// Cancel blocking cardGetStatusChange for the context
  @override
  Future<void> cancelWaiting(int context) async {
    return cardCancel(context);
  }

  /// Check validity for the context
  @override
  Future<bool> isValidContext(int context) async {
    return _binding.isValidContext(context);
  }
}
