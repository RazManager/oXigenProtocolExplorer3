import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'oxigen_constants.dart';
import 'serial_port_worker.dart';

class CarControllerPair {
  TxCarControllerPair tx = TxCarControllerPair();
  RxCarControllerPair rx = RxCarControllerPair();
  ScrollController scrollController = ScrollController();
}

class AppModel extends ChangeNotifier {
  AppModel() {
    Isolate.spawn(SerialPortWorker().startAsync, _receivePort.sendPort);
    _serialPortWorkerDataStreamSubscription = _receivePort.listen((message) => _onSerialPortWorkerData(message));
  }

  int menuIndex = 0;

  final _receivePort = ReceivePort();
  SendPort? _sendPort;
  StreamSubscription<dynamic>? _serialPortWorkerDataStreamSubscription;

  SerialPortResponse? _serialPortResponse;
  List<String> availablePortNames = [];

  OxigenTxPitlaneLapCounting? txPitlaneLapCounting;
  OxigenTxPitlaneLapTrigger? txPitlaneLapTrigger;
  OxigenTxRaceState? txRaceState;
  int? maximumSpeed;
  int txDelay = 500;
  int txTimeout = 1000;
  int rxControllerTimeout = 30;
  int rxBufferLength = 0;
  final exceptionStreamController = StreamController<String>.broadcast();

  double? dongleFirmwareVersion;
  final Map<int, CarControllerPair> _carControllerPairs = List.generate(21, (index) => CarControllerPair()).asMap();
  Queue<int> refreshRatesQueue = Queue<int>();
  Stopwatch stopwatch = Stopwatch();

  void serialPortRefresh() {
    _sendPort!.send(SerialPortRefreshRequest());
  }

  void serialPortSet(String name) {
    _sendPort!.send(SerialPortSetRequest(name: name));
  }

  String? serialPortGet() {
    return _serialPortResponse?.name;
  }

  bool serialPortCanOpen() {
    return _serialPortResponse != null &&
        !_serialPortResponse!.isOpen &&
        txPitlaneLapCounting != null &&
        (txPitlaneLapCounting == OxigenTxPitlaneLapCounting.disabled || txPitlaneLapTrigger != null) &&
        txRaceState != null &&
        maximumSpeed != null;
  }

  bool serialPortIsOpen() {
    return _serialPortResponse != null && _serialPortResponse!.isOpen;
  }

  void serialPortOpen() {
    _sendPort!.send(SerialPortOpenRequest());
  }

  bool serialPortCanClose() {
    return _serialPortResponse != null && _serialPortResponse!.isOpen;
  }

  void serialPortClose() {
    _sendPort!.send(SerialPortCloseRequest());
  }

  void oxigenTxPitlaneLapCountingSet(OxigenTxPitlaneLapCounting value) {
    txPitlaneLapCounting = value;
    _sendPort!.send(txPitlaneLapCounting!);
    notifyListeners();
  }

  void oxigenPitlaneLapTriggerModeSet(OxigenTxPitlaneLapTrigger value) {
    txPitlaneLapTrigger = value;
    _sendPort!.send(txPitlaneLapTrigger!);
    notifyListeners();
  }

  void oxigenTxRaceStateSet(OxigenTxRaceState value) {
    if (txRaceState == OxigenTxRaceState.stopped && value == OxigenTxRaceState.running) {
      stopwatch.reset();
    }
    switch (value) {
      case OxigenTxRaceState.running:
      case OxigenTxRaceState.flaggedLcEnabled:
      case OxigenTxRaceState.flaggedLcDisabled:
        stopwatch.start();
        break;
      case OxigenTxRaceState.paused:
      case OxigenTxRaceState.stopped:
        stopwatch.stop();
        break;
    }

    txRaceState = value;
    _sendPort!.send(txRaceState!);
    notifyListeners();
  }

  void oxigenMaximumSpeedSet(int id, int value) {
    maximumSpeed = value;
    _sendPort!.send(MaximumSpeedRequest(maximumSpeed: value));
    notifyListeners();
  }

  void txDelaySet(int value) {
    txDelay = value;
    _sendPort!.send(TxDelayRequest(txDelay: value));
    notifyListeners();
  }

  void txTimeoutSet(int value) {
    txTimeout = value;
    _sendPort!.send(TxTimeoutRequest(txTimeout: value));
    notifyListeners();
  }

  void controllerTimeoutSet(int value) {
    rxControllerTimeout = value;
    notifyListeners();
  }

  void oxigenTxMaximumSpeedSet(int id, int value) {
    _carControllerPairs[id]!.tx.maximumSpeed = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.maximumSpeed, value: value));
    notifyListeners();
  }

  void oxigenTxMinimumSpeedSet(int id, int value) {
    _carControllerPairs[id]!.tx.minimumSpeed = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.minimumSpeed, value: value));
    notifyListeners();
  }

  void oxigenTxPitlaneSpeedSet(int id, int value) {
    _carControllerPairs[id]!.tx.pitlaneSpeed = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.pitlaneSpeed, value: value));
    notifyListeners();
  }

  void oxigenTxMaximumBrakeSet(int id, int value) {
    _carControllerPairs[id]!.tx.maximumBrake = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.maximumBrake, value: value));
    notifyListeners();
  }

  void oxigenTxForceLcUpSet(int id, bool value) {
    _carControllerPairs[id]!.tx.forceLcUp = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.forceLcUp, value: value));
    notifyListeners();
  }

  void oxigenTxForceLcDownSet(int id, bool value) {
    _carControllerPairs[id]!.tx.forceLcDown = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.forceLcDown, value: value));
    notifyListeners();
  }

  void oxigenTxTransmissionPowerSet(int id, OxigenTxTransmissionPower value) {
    _carControllerPairs[id]!.tx.transmissionPower = value;
    _sendPort!.send(TxCommand(id: id, command: OxigenTxCommand.transmissionPower, value: value));
    notifyListeners();
  }

  void _onSerialPortWorkerData(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
    } else if (message is SerialPortResponse) {
      _serialPortResponse = message;
      notifyListeners();
    } else if (message is List<String>) {
      availablePortNames = message;
      notifyListeners();
    } else if (message is RxResponse) {
      rxBufferLength = message.rxBufferLength;

      for (var kv in message.updatedRxCarControllerPairs.entries) {
        _carControllerPairs[kv.key]!.rx = kv.value;
        if (kv.value.refreshRate != null) {
          refreshRatesQueue.addLast(kv.value.refreshRate!);
          while (refreshRatesQueue.length >= 100) {
            refreshRatesQueue.removeFirst();
          }
        }
      }

      notifyListeners();
    } else if (message is DongleFirmwareVersionResponse) {
      dongleFirmwareVersion = message.dongleFirmwareVersion;
      notifyListeners();
    } else if (message is SerialPortError) {
      exceptionStreamController.add(message.message);
      notifyListeners();
    }
  }

  TxCarControllerPair globalCarControllerPairTx() {
    return _carControllerPairs[0]!.tx;
  }

  Iterable<MapEntry<int, CarControllerPair>> carControllerPairs() {
    final now = DateTime.now();
    return _carControllerPairs.entries.where((x) =>
        x.key != 0 &&
        x.value.rx.refreshRate != null &&
        x.value.rx.updatedAt != null &&
        x.value.rx.updatedAt!.isAfter(now.add(Duration(milliseconds: -rxControllerTimeout * 1000))));
  }

  @override
  void dispose() {
    if (_serialPortWorkerDataStreamSubscription != null) {
      _serialPortWorkerDataStreamSubscription!.cancel();
    }
    if (_sendPort != null) {
      _sendPort!.send(null);
    }
    super.dispose();
  }
}
