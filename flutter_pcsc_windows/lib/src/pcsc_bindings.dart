import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:flutter_pcsc_platform_interface/flutter_pcsc_platform_interface.dart';
import 'package:flutter_pcsc_windows/src/generated_bindings.dart';

class PCSCBinding {
  static final _dylib = ffi.DynamicLibrary.open("winscard.dll");
  static final NativeLibraryWinscard _nlwinscard =
      NativeLibraryWinscard(_dylib);

  static final ffi.Pointer<Never> _nullptr = ffi.Pointer.fromAddress(0);

  final LPSCARD_IO_REQUEST _scardT0Pci = calloc<SCARD_IO_REQUEST>();
  final LPSCARD_IO_REQUEST _scardT1Pci = calloc<SCARD_IO_REQUEST>();

  PCSCBinding() {
    _scardT0Pci.ref.cbPciLength = _nlwinscard.g_rgSCardT0Pci.cbPciLength;
    _scardT0Pci.ref.dwProtocol = _nlwinscard.g_rgSCardT0Pci.dwProtocol;

    _scardT1Pci.ref.cbPciLength = _nlwinscard.g_rgSCardT1Pci.cbPciLength;
    _scardT1Pci.ref.dwProtocol = _nlwinscard.g_rgSCardT1Pci.dwProtocol;
  }

  close() {
    calloc.free(_scardT0Pci);
    calloc.free(_scardT1Pci);
  }

  Future<int> establishContext(int scope) {
    ffi.Pointer<SCARDCONTEXT> phContext = calloc<SCARDCONTEXT>();
    try {
      var res = _nlwinscard.SCardEstablishContext(
          scope, _nullptr, _nullptr, phContext);
      _checkAndThrow(res, 'Error while establing context');

      return Future.value(phContext.value);
    } finally {
      calloc.free(phContext);
    }
  }

  void _checkAndThrow(int res, String prefix) {
    if (res != PcscConstants.SCARD_S_SUCCESS) {
      throw Exception(prefix + '. Reason: ${PcscConstants.errorToString(res)}');
    }
  }

  Future<Map<String, dynamic>> scardStatus(int hCard) async {
    var pcbAtrLen = calloc<DWORD>();
    var dwReaderLen = calloc<DWORD>();
    var dwState = calloc<DWORD>();
    var dwProtocol = calloc<DWORD>();

    try {
      // Initial call to get the lengths
      var res = _nlwinscard.SCardStatusA(hCard, _nullptr, dwReaderLen, dwState,
          dwProtocol, _nullptr, pcbAtrLen);
      _checkAndThrow(res, 'Error while getting status #1');

      // Allocate buffers for the reader name and the ATR
      var mszReaderNames = calloc<ffi.Int8>(dwReaderLen.value);
      var pbAtr = calloc<ffi.Uint8>(pcbAtrLen.value);

      try {
        // Actual call to get the data
        res = _nlwinscard.SCardStatusA(hCard, mszReaderNames, dwReaderLen,
            dwState, dwProtocol, pbAtr, pcbAtrLen);
        _checkAndThrow(res, 'Error while getting status #2');

        // Convert the data to Dart types
        String readerName =
            _decodemstr(_asInt8List(mszReaderNames, dwReaderLen.value)).first;
        Uint8List atr = _asUint8List(pbAtr, pcbAtrLen.value);

        // Return the result
        return {
          'reader_name': readerName,
          'state': dwState.value,
          'protocol': dwProtocol.value,
          'atr': atr,
        };
      } finally {
        calloc.free(mszReaderNames);
        calloc.free(pbAtr);
      }
    } finally {
      calloc.free(pcbAtrLen);
      calloc.free(dwReaderLen);
      calloc.free(dwState);
      calloc.free(dwProtocol);
    }
  }

  Future<Map<String, dynamic>> scardReconnect(int hCard) async {
    var dwActiveProtocol = calloc<DWORD>();
    try {
      var res = _nlwinscard.SCardReconnect(
          hCard,
          PcscConstants.SCARD_SHARE_SHARED,
          PcscConstants.SCARD_PROTOCOL_T0 | PcscConstants.SCARD_PROTOCOL_T1,
          PcscConstants.SCARD_LEAVE_CARD,
          dwActiveProtocol);
      _checkAndThrow(res, 'Error while reconnecting to card');

      return Future.value({'active_protocol': dwActiveProtocol.value});
    } finally {
      calloc.free(dwActiveProtocol);
    }
  }

  Future<List<String>> listReaders(int context) {
    final pcchReaders = calloc<DWORD>();
    try {
      var res = _nlwinscard.SCardListReadersA(
          context, _nullptr, _nullptr, pcchReaders);

      // In that particular case, don't throw an error.
      if (res == PcscConstants.SCARD_E_NO_READERS_AVAILABLE) {
        return Future.value([]);
      }
      _checkAndThrow(res, 'Error while listing readers #1');

      final mszReaders = calloc<ffi.Int8>(pcchReaders.value);
      try {
        res = _nlwinscard.SCardListReadersA(
            context, _nullptr, mszReaders, pcchReaders);
        _checkAndThrow(res, 'Error while listing readers #2');

        return Future.value(
            _decodemstr(_asInt8List(mszReaders, pcchReaders.value)));
      } finally {
        calloc.free(mszReaders);
      }
    } finally {
      calloc.free(pcchReaders);
    }
  }

  Future<String> getReaderDeviceInstanceId(int context, String reader) {
    ffi.Pointer<ffi.Int8> nativeReaderName =
        reader.toNativeUtf8(allocator: calloc).cast();
    final pcchDeviceInstanceId = calloc<DWORD>();
    try {
      var res = _nlwinscard.SCardGetReaderDeviceInstanceIdA(
          context, nativeReaderName, _nullptr, pcchDeviceInstanceId);
      _checkAndThrow(res, 'Error while getting device instance id #1');

      final mszDeviceInstanceId = calloc<ffi.Int8>(pcchDeviceInstanceId.value);
      try {
        res = _nlwinscard.SCardGetReaderDeviceInstanceIdA(context,
            nativeReaderName, mszDeviceInstanceId, pcchDeviceInstanceId);
        _checkAndThrow(res, 'Error while getting device instance id #2');

        return Future.value(_decodemstr(
                _asInt8List(mszDeviceInstanceId, pcchDeviceInstanceId.value))
            .first);
      } finally {
        calloc.free(mszDeviceInstanceId);
      }
    } finally {
      calloc.free(pcchDeviceInstanceId);
      calloc.free(nativeReaderName);
    }
  }

  Future<Map> cardConnect(
      int context, String reader, int shareMode, int protocol) async {
    ffi.Pointer<ffi.Int8> nativeReaderName =
        reader.toNativeUtf8(allocator: calloc).cast();
    final phCard = calloc<SCARDHANDLE>();
    final pdwActiveProtocol = calloc<DWORD>();

    try {
      var res = _nlwinscard.SCardConnectA(context, nativeReaderName, shareMode,
          protocol, phCard, pdwActiveProtocol);
      _checkAndThrow(res, 'Error while connecting to card');

      Map result = {};
      result['h_card'] = phCard.value;
      result['active_protocol'] = pdwActiveProtocol.value;
      result['reader'] = reader;

      return result;
    } finally {
      calloc.free(nativeReaderName);
      calloc.free(phCard);
      calloc.free(pdwActiveProtocol);
    }
  }

  Future<Uint8List> transmit(
      int hCard, int activeProtocol, List<int> sendCommand,
      {bool newIsolate = false}) {
    if (newIsolate) {
      return _transmitInNewIsolate(hCard, activeProtocol, sendCommand);
    } else {
      return _transmitInSameIsolate(hCard, activeProtocol, sendCommand);
    }
  }

  Future<Map> cardGetStatusChange(int context, String readerName,
      {int currentState = PcscConstants.SCARD_STATE_UNAWARE,
      int timeout = PcscConstants.SCARD_INFINITE}) async {
    ffi.Pointer<SCARD_READERSTATEA> rgReaderStates =
        calloc<SCARD_READERSTATEA>();

    rgReaderStates.ref.szReader = readerName.toNativeUtf8().cast();
    rgReaderStates.ref.dwCurrentState = currentState;

    try {
      var res = _nlwinscard.SCardGetStatusChangeA(
          context, timeout, rgReaderStates, 1);
      if (res == PcscConstants.SCARD_E_TIMEOUT) {
        throw TimeoutException(
            'Error while waiting for status change (card insertion/removal)',
            Duration(milliseconds: timeout));
      }
      _checkAndThrow(res,
          'Error while waiting for status change (card insertion/removal)');

      return _buildMapData(rgReaderStates.ref);
    } finally {
      calloc.free(rgReaderStates.ref.szReader);
      calloc.free(rgReaderStates);
    }
  }

  Future<void> cardCancel(int context) async {
    var res = _nlwinscard.SCardCancel(context);
    _checkAndThrow(res, 'Error while cancelling card');
  }

  Future<void> cardDisconnect(int hCard, int disposition) async {
    var res = _nlwinscard.SCardDisconnect(hCard, disposition);
    _checkAndThrow(res, 'Error while disconnecting card');
  }

  Future<void> releaseContext(int context) async {
    var res = _nlwinscard.SCardReleaseContext(context);
    _checkAndThrow(res, 'Error while releasing context');
  }

  Future<void> scardBeginTransaction(int hCard) {
    var res = _nlwinscard.SCardBeginTransaction(hCard);
    _checkAndThrow(res, 'Error while beginning transaction');

    return Future.value(PcscConstants.SCARD_S_SUCCESS);
  }

  Future<void> scardEndTransaction(int hCard, int disposition) {
    var res = _nlwinscard.SCardEndTransaction(hCard, disposition);
    _checkAndThrow(res, 'Error while ending transaction');

    return Future.value(PcscConstants.SCARD_S_SUCCESS);
  }

  Future<Map> waitForCardPresent(
      int context, String readerName, int timeout) async {
    Map map = await cardGetStatusChange(context, readerName, timeout: timeout);
    int currentState = map['pcsc_tag']['event_state'];

    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    while (currentState & PcscConstants.SCARD_STATE_EMPTY != 0 &&
        stopwatch.elapsedMilliseconds < timeout &&
        map['pcsc_tag']['atr'].isEmpty) {
      map = await compute(_computeFunctionCardGetStatusChange, {
        'context': context,
        'reader_name': readerName,
        'current_state': currentState,
        'timeout': timeout
      });
      currentState = map['pcsc_tag']['event_state'];
    }
    if (map['pcsc_tag']['atr'].isEmpty) {
      throw TimeoutException('Card is still not present in the reader');
    }
    return map;
  }

  Future<void> waitForCardRemoved(
      int context, String readerName, int timeout) async {
    Map map = await cardGetStatusChange(context, readerName, timeout: timeout);
    int currentState = map['pcsc_tag']['event_state'];

    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    while (currentState & PcscConstants.SCARD_STATE_PRESENT != 0 &&
        stopwatch.elapsedMilliseconds < timeout) {
      map = await compute(_computeFunctionCardGetStatusChange, {
        'context': context,
        'reader_name': readerName,
        'current_state': currentState,
        'timeout': timeout
      });
      currentState = map['pcsc_tag']['event_state'];
    }
    if (currentState & PcscConstants.SCARD_STATE_PRESENT != 0) {
      throw TimeoutException('Card is still present in the reader');
    }
    print('PCSC: reader not present. current state: $currentState');
  }

  Future<Map> waitForCardStatusChanged(
      int context, String readerName, int timeout) async {
    Map map = await cardGetStatusChange(context, readerName, timeout: timeout);
    int currentState = map['pcsc_tag']['event_state'];

    return await compute(_computeFunctionCardGetStatusChange, {
      'context': context,
      'reader_name': readerName,
      'current_state': currentState,
      'timeout': timeout
    });
  }

  Future<void> cancelWaiting(int context) async {
    return cardCancel(context);
  }

  Future<bool> isValidContext(int context) async {
    final result = _nlwinscard.SCardIsValidContext(context);
    return result == PcscConstants.SCARD_S_SUCCESS;
  }

  /*
   * This computeFunction allows to run a blocking C function in an Isolate
   */
  static Future<Uint8List> _computeFunctionTransmit(Map map) async {
    PCSCBinding binding = PCSCBinding();
    return binding.transmit(
        map['h_card'], map['active_protocol'], map['command'],
        newIsolate: false);
  }

  /*
   * This computeFunction allows to run a blocking C function in an Isolate
   */
  static Future<Map> _computeFunctionCardGetStatusChange(Map map) async {
    PCSCBinding binding = PCSCBinding();
    return binding.cardGetStatusChange(map['context'], map['reader_name'],
        currentState: map['current_state'], timeout: map['timeout']);
  }

  Future<Uint8List> _transmitInNewIsolate(
      int hCard, int activeProtocol, List<int> sendCommand) {
    return Isolate.run(() => _computeFunctionTransmit({
          'h_card': hCard,
          'active_protocol': activeProtocol,
          'command': sendCommand
        }));
  }

  Future<Uint8List> _transmitInSameIsolate(
      int hCard, int activeProtocol, List<int> sendCommand) {
    var nativeSendCommand = _allocateNative(sendCommand);

    var pcbRecvLength = calloc<DWORD>();
    pcbRecvLength.value = PcscConstants.MAX_BUFFER_SIZE_EXTENDED;
    var pbRecvBuffer = calloc<ffi.Uint8>(pcbRecvLength.value);

    try {
      ffi.Pointer<SCARD_IO_REQUEST> pioSendPci = _getPCI(activeProtocol);

      var res = _nlwinscard.SCardTransmit(hCard, pioSendPci, nativeSendCommand,
          sendCommand.length, _nullptr, pbRecvBuffer, pcbRecvLength);
      _checkAndThrow(res, 'Error while transmitting to card');

      Uint8List response = _asUint8List(pbRecvBuffer, pcbRecvLength.value);

      return Future.value(response);
    } finally {
      calloc.free(nativeSendCommand);
      calloc.free(pcbRecvLength);
      calloc.free(pbRecvBuffer);
    }
  }

  Map _buildMapData(SCARD_READERSTATEA readerState) {
    Map pcscData = {};
    Uint8List atr = Uint8List(readerState.cbAtr);
    for (int i = 0; i < readerState.cbAtr; i++) {
      atr[i] = readerState.rgbAtr[i];
    }
    pcscData['atr'] = atr;
    pcscData['event_state'] = readerState.dwEventState;
    pcscData['current_state'] = readerState.dwCurrentState;
    Map data = {};
    data['pcsc_tag'] = pcscData;

    return data;
  }

  List<String> _decodemstr(Int8List list) {
    List<String> result = List.empty(growable: true);
    int prevPos = 0;
    while (prevPos < list.length) {
      int pos = list.indexOf(0, prevPos);
      if (pos == -1) {
        pos = list.length;
      }
      if (prevPos != pos) {
        String s = String.fromCharCodes(list.sublist(prevPos, pos));
        result.add(s);
      }
      prevPos = pos + 1;
    }
    return result;
  }

  ffi.Pointer<ffi.Uint8> _allocateNative(List<int> buffer) {
    var result = calloc<ffi.Uint8>(buffer.length);
    var bufferView = result.asTypedList(buffer.length);
    bufferView.setAll(0, buffer);

    return result;
  }

  ffi.Pointer<SCARD_IO_REQUEST> _getPCI(int activeProtocol) {
    ffi.Pointer<SCARD_IO_REQUEST> pioSendPci;

    if (activeProtocol == PcscConstants.SCARD_PROTOCOL_T0) {
      pioSendPci = _scardT0Pci;
    } else {
      pioSendPci = _scardT1Pci;
    }

    return pioSendPci;
  }

  Int8List _asInt8List(ffi.Pointer<ffi.Int8> p, int length) {
    Int8List result = Int8List(length);
    for (int i = 0; i < length; i++) {
      result[i] = p[i];
    }
    return result;
  }

  Uint8List _asUint8List(ffi.Pointer<ffi.Uint8> p, int length) {
    Uint8List result = Uint8List(length);
    for (int i = 0; i < length; i++) {
      result[i] = p[i];
    }
    return result;
  }
}
