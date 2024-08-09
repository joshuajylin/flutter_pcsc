import 'package:flutter_pcsc_platform_interface/flutter_pcsc_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of flutter_pcsc must implement.
///
/// Platform implementations should extend this class rather than implement it as `flutter_pcsc`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [PcscPlatform] methods.
abstract class PcscPlatform extends PlatformInterface {
  /// Constructs a UrlLauncherPlatform.
  PcscPlatform() : super(token: _token);

  static final Object _token = Object();

  static PcscPlatform _instance = DummyPcscPlatform();

  /// The default instance of [PcscPlatform] to use.
  ///
  /// Defaults to [DummyPcscPlatform].
  static PcscPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [UrlLauncherPlatform] when they register themselves.
  static set instance(PcscPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<int> establishContext(int scope) {
    throw UnimplementedError('establishContext() has not been implemented.');
  }

  Future<List<String>> listReaders(int context) {
    throw UnimplementedError('listReaders() has not been implemented.');
  }

  Future<Map> cardConnect(
      int context, String reader, int shareMode, int protocol) {
    throw UnimplementedError('cardConnect() has not been implemented.');
  }

  Future<Map<String, dynamic>> cardReconnect(int hCard) {
    throw UnimplementedError('cardReconnect() has not been implemented.');
  }

  Future<Map<String, dynamic>> scardStatus(int hCard) {
    throw UnimplementedError('scardStatus() has not been implemented.');
  }

  Future<List<int>> transmit(
      int hCard, int activeProtocol, List<int> commandBytes,
      {bool newIsolate = false}) {
    throw UnimplementedError('transmit() has not been implemented.');
  }

  Future<void> cardDisconnect(int hCard, int disposition) {
    throw UnimplementedError('cardDisconnect() has not been implemented.');
  }

  Future<void> releaseContext(int context) {
    throw UnimplementedError('releaseContext() has not been implemented.');
  }

  Future<void> scardBeginTransaction(int hCard) {
    throw UnimplementedError(
        'scardBeginTransaction() has not been implemented.');
  }

  Future<void> scardEndTransaction(int hCard, int disposition) {
    throw UnimplementedError('scardEndTransaction() has not been implemented.');
  }

  Future<Map> waitForCardPresent(int context, String readerName,
      {int timeout = PcscConstants.SCARD_INFINITE}) {
    throw UnimplementedError('waitForCardPresent() has not been implemented.');
  }

  Future<String> getReaderDeviceInstanceId(int context, String readerName) {
    throw UnimplementedError(
        'getReaderDeviceInstanceId() has not been implemented.');
  }

  Future<void> waitForCardRemoved(int context, String readerName,
      {int timeout = PcscConstants.SCARD_INFINITE}) {
    throw UnimplementedError('waitForCardPresent() has not been implemented.');
  }
}

class DummyPcscPlatform extends PcscPlatform {}
