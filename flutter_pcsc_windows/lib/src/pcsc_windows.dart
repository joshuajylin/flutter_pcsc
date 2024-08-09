import 'package:flutter_pcsc_platform_interface/flutter_pcsc_platform_interface.dart';
import 'package:flutter_pcsc_windows/src/pcsc_bindings.dart';

/// The main class to use to deal with PCSC.
class PcscWindows extends PcscPlatform {
  static void registerWith() {
    PcscPlatform.instance = PcscWindows();
  }

  static final PCSCBinding _binding = PCSCBinding();

  /*
   * Not really asynchronous (the C call is synchronous), but it will be easier to use if a Future is returned
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

  @override
  Future<String> getReaderDeviceInstanceId(int context, String readerName) {
    return _binding.getReaderDeviceInstanceId(context, readerName);
  }

  /// Connects to the card using the specified reader.
  @override
  Future<Map> cardConnect(
      int context, String reader, int shareMode, int protocol) {
    return _binding.cardConnect(context, reader, shareMode, protocol);
  }

  /// Retrieves the current status of a smart card in a reader.
  @override
  Future<Map<String, dynamic>> scardStatus(int hCard) {
    return _binding.scardStatus(hCard);
  }

  /// Reconnects to the card.
  /// This is useful when the card has been disconnected and needs to be reconnected.
  @override
  Future<Map<String, dynamic>> cardReconnect(int hCard) {
    return _binding.scardReconnect(hCard);
  }

  /// Transmits an APDU to the card.
  @override
  Future<List<int>> transmit(
      int hCard, int activeProtocol, List<int> commandBytes,
      {bool newIsolate = false}) {
    return _binding.transmit(hCard, activeProtocol, commandBytes,
        newIsolate: newIsolate);
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

  /// Begins a transaction.
  /// This is useful when multiple commands need to be sent to the card.
  @override
  Future<void> scardBeginTransaction(int hCard) {
    return _binding.scardBeginTransaction(hCard);
  }

  /// Ends a transaction.
  @override
  Future<void> scardEndTransaction(int hCard, int disposition) {
    return _binding.scardEndTransaction(hCard, disposition);
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
}
