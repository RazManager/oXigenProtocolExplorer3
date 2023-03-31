import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'oxigen_constants.dart';

class TxCarControllerPair {
  int? maximumSpeed;
  int? minimumSpeed;
  int? pitlaneSpeed;
  int? maximumBrake;
  bool? forceLcUp;
  bool? forceLcDown;
  OxigenTxTransmissionPower? transmissionPower;
}

class TxCommand {
  TxCommand({required this.id, required this.command});
  final int id;
  final OxigenTxCommand command;
}

class RxCarControllerPair {
  OxigenRxCarReset carReset = OxigenRxCarReset.carPowerSupplyHasntChanged;
  int carResetCount = 0;
  OxigenRxControllerCarLink controllerCarLink =
      OxigenRxControllerCarLink.controllerLinkWithItsPairedCarHasntChanged;
  int controllerCarLinkCount = 0;
  late OxigenRxControllerBatteryLevel controllerBatteryLevel;
  late OxigenRxTrackCall trackCall;
  late OxigenRxArrowUpButton arrowUpButton;
  late OxigenRxArrowDownButton arrowDownButton;
  late OxigenRxCarOnTrack carOnTrack;
  late OxigenRxCarPitLane carPitLane;
  late int triggerMeanValue;
  late int dongleRaceTimer;
  late int dongleLapRaceTimer;
  late int dongleLapTime;
  late double dongleLapTimeSeconds;
  late int dongleLapTimeDelay;
  late int dongleLaps;
  int? previousLapRaceTimer;
  double? calculatedLapTimeSeconds;
  int? calculatedLaps;
  double? controllerFirmwareVersion;
  double? carFirmwareVersion;
  DateTime? updatedAt;
  int? refreshRate = 0;
  double? fastestLapTime;
  Queue<PracticeSessionLap> practiceSessionLaps = Queue<PracticeSessionLap>();
  ScrollController scrollController = ScrollController();
}

class PracticeSessionLap {
  PracticeSessionLap({required this.lap, required this.lapTime});

  late int lap;
  late double lapTime;
}

class CarControllerPair {
  TxCarControllerPair tx = TxCarControllerPair();
  RxCarControllerPair rx = RxCarControllerPair();
}

class AppModel extends ChangeNotifier {
  AppModel() {
    availablePortsRefresh(false);
  }

  int menuIndex = 0;
  SerialPort? serialPort;
  SerialPortReader? _serialPortReader;
  StreamSubscription<Uint8List>? _serialPortStreamSubscription;
  List<String> availablePortNames = [];
  OxigenTxPitlaneLapCounting? txPitlaneLapCounting;
  OxigenTxPitlaneLapTrigger? txPitlaneLapTrigger;
  OxigenTxRaceState? txRaceState;
  int? maximumSpeed;
  int txDelay = 500;
  int txTimeout = 1000;
  Timer? txTimeoutTimer;
  int rxControllerTimeout = 30;
  int rxBufferLength = 0;
  Queue<TxCommand> txCommandQueue = Queue<TxCommand>();
  final exceptionStreamController = StreamController<String>.broadcast();

  double? oxigenDongleFirmwareVersion;
  Map<int, CarControllerPair> carControllerPairs = {0: CarControllerPair()};
  Queue<int> refreshRateQueue = Queue<int>();
  Uint8List? _unusedBuffer;

  void availablePortsRefresh(bool shouldNotify) {
    _serialPortClear(shouldNotify);
    availablePortNames = SerialPort.availablePorts;
    if (availablePortNames.isNotEmpty) {
      for (final address in availablePortNames) {
        var port = SerialPort(address);
        try {
          if (port.vendorId != null &&
              port.vendorId == 0x1FEE &&
              port.productId != null &&
              port.productId == 0x2) {
            serialPortSet(address, false);
            port.dispose();
            break;
          }
          port.dispose();
        } on SerialPortError {}
        if (serialPort == null) {
          serialPortSet(availablePortNames.first, false);
        }
      }
    }
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void _serialPortClear(bool shouldNotify) {
    if (_serialPortStreamSubscription != null) {
      _serialPortStreamSubscription!.cancel();
      _serialPortStreamSubscription = null;
    }
    if (_serialPortReader != null) {
      _serialPortReader!.close();
      _serialPortReader = null;
    }
    if (serialPort != null) {
      if (serialPort!.isOpen) {
        if (!serialPort!.close() && SerialPort.lastError != null) {
          exceptionStreamController.add(SerialPort.lastError!.message);
        }
      }
      serialPort!.dispose();
      serialPort = null;
    }
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void serialPortSet(String name, bool shouldNotify) {
    _serialPortClear(false);
    serialPort = SerialPort(name);
    if (shouldNotify) {
      notifyListeners();
    }
  }

  bool serialPortCanOpen() {
    return serialPort != null &&
        !serialPort!.isOpen &&
        txPitlaneLapCounting != null &&
        (txPitlaneLapCounting == OxigenTxPitlaneLapCounting.disabled ||
            txPitlaneLapTrigger != null) &&
        txRaceState != null &&
        maximumSpeed != null;
  }

  bool serialPortIsOpen() {
    return serialPort != null && serialPort!.isOpen;
  }

  void serialPortOpen(bool dongleFirmwareVersion) {
    if (!serialPort!.openReadWrite() && SerialPort.lastError != null) {
      exceptionStreamController.add(SerialPort.lastError!.message);
      notifyListeners();
      return;
    }
    _serialPortReadStream();
    if (dongleFirmwareVersion) {
      _serialPortDongleCommandDongleFirmwareVersion();
    } else {
      _serialPortWriteLoop();
    }

    notifyListeners();
  }

  bool serialPortCanClose() {
    return serialPort != null && serialPort!.isOpen;
  }

  void serialPortClose() {
    _serialPortClear(true);
  }

  void _serialPortReset() { 
    _serialPortClear(false);
    serialPortOpen(false);
  }

  void _serialPortDongleCommandDongleFirmwareVersion() {
    var bytes = Uint8List.fromList([6, 6, 6, 6, 0, 0, 0]);
    serialPort!.write(bytes);
  }

  void oxigenTxPitlaneLapCountingSet(OxigenTxPitlaneLapCounting value) {
    txPitlaneLapCounting = value;
    notifyListeners();
  }

  void oxigenPitlaneLapTriggerModeSet(OxigenTxPitlaneLapTrigger value) {
    txPitlaneLapTrigger = value;
    notifyListeners();
  }

  void oxigenTxRaceStateSet(OxigenTxRaceState value) {
    if (txRaceState == OxigenTxRaceState.stopped &&
        value == OxigenTxRaceState.running) {
      for (var x in carControllerPairs.entries.where((kv) => kv.key != 0)) {
        x.value.rx.previousLapRaceTimer = null;
        x.value.rx.calculatedLapTimeSeconds = null;
        x.value.rx.calculatedLaps = null;
        x.value.rx.fastestLapTime = null;
        x.value.rx.practiceSessionLaps = Queue<PracticeSessionLap>();
      }
    }
    txRaceState = value;
    notifyListeners();
  }

  void oxigenMaximumSpeedSet(int id, int value) {
    maximumSpeed = value;
    notifyListeners();
  }

  void txDelaySet(int value) {
    txDelay = value;
    notifyListeners();
  }

  void txTimeoutSet(int value) {
    txTimeout = value;
    notifyListeners();
  }

  void controllerTimeoutSet(int value) {
    rxControllerTimeout = value;
    notifyListeners();
  }

  void oxigenTxMaximumSpeedSet(int id, int value) {
    carControllerPairs[id]!.tx.maximumSpeed = value;
    txCommandQueue
        .addLast(TxCommand(id: id, command: OxigenTxCommand.maximumSpeed));
    notifyListeners();
  }

  void oxigenTxMinimumSpeedSet(int id, int value) {
    carControllerPairs[id]!.tx.minimumSpeed = value;
    txCommandQueue
        .addLast(TxCommand(id: id, command: OxigenTxCommand.minimumSpeed));
    notifyListeners();
  }

  void oxigenTxPitlaneSpeedSet(int id, int value) {
    carControllerPairs[id]!.tx.pitlaneSpeed = value;
    txCommandQueue
        .addLast(TxCommand(id: id, command: OxigenTxCommand.pitlaneSpeed));
    notifyListeners();
  }

  void oxigenTxMaximumBrakeSet(int id, int value) {
    carControllerPairs[id]!.tx.maximumBrake = value;
    txCommandQueue
        .addLast(TxCommand(id: id, command: OxigenTxCommand.maximumBrake));
    notifyListeners();
  }

  void oxigenTxForceLcUpSet(int id, bool value) {
    carControllerPairs[id]!.tx.forceLcUp = value;
    txCommandQueue
        .addLast(TxCommand(id: id, command: OxigenTxCommand.forceLcUp));
    notifyListeners();
  }

  void oxigenTxForceLcDownSet(int id, bool value) {
    carControllerPairs[id]!.tx.forceLcDown = value;
    txCommandQueue
        .addLast(TxCommand(id: id, command: OxigenTxCommand.forceLcDown));
    notifyListeners();
  }

  void oxigenTxTransmissionPowerSet(int id, OxigenTxTransmissionPower value) {
    carControllerPairs[id]!.tx.transmissionPower = value;
    txCommandQueue
        .addLast(TxCommand(id: id, command: OxigenTxCommand.transmissionPower));
    notifyListeners();
  }

  void _serialPortWriteLoop() {
    try {
      var disconnectedControllers = carControllerPairs.entries.where((x) =>
          x.key != 0 &&
          x.value.rx.updatedAt != null &&
          x.value.rx.updatedAt!.isBefore(DateTime.now()
              .add(Duration(milliseconds: -rxControllerTimeout * 1000))));
      if (disconnectedControllers.isNotEmpty) {
        carControllerPairs.remove(disconnectedControllers.first.key);
        notifyListeners();
      }

      int byte0;
      switch (txRaceState) {
        case null:
          return;
        case OxigenTxRaceState.running:
          byte0 = 0x3;
          break;
        case OxigenTxRaceState.paused:
          byte0 = 0x4;
          break;
        case OxigenTxRaceState.stopped:
          byte0 = 0x1;
          break;
        case OxigenTxRaceState.flaggedLcEnabled:
          byte0 = 0x5;
          break;
        case OxigenTxRaceState.flaggedLcDisabled:
          byte0 = 0x15;
          break;
      }

      switch (txPitlaneLapCounting) {
        case null:
          return;
        case OxigenTxPitlaneLapCounting.enabled:
          break;
        case OxigenTxPitlaneLapCounting.disabled:
          byte0 = byte0 | (pow(2, 5) as int);
          break;
      }

      if (txPitlaneLapCounting != null &&
          txPitlaneLapCounting == OxigenTxPitlaneLapCounting.enabled) {
        switch (txPitlaneLapTrigger) {
          case null:
            return;
          case OxigenTxPitlaneLapTrigger.pitlaneEntry:
            break;
          case OxigenTxPitlaneLapTrigger.pitlaneExit:
            byte0 = byte0 | (pow(2, 6) as int);
            break;
        }
      }

      if (maximumSpeed == null) {
        return;
      }

      if (serialPortIsOpen()) {
        var id = 0;
        var byte3 = 0;
        var byte4 = 0;

        if (txCommandQueue.isNotEmpty) {
          var txCommand = txCommandQueue.first;
          txCommandQueue.removeFirst();
          txCommandQueue.removeWhere(
              (x) => x.id == txCommand.id && x.command == txCommand.command);

          id = txCommand.id;
          var txCarControllerPair = carControllerPairs[id]!.tx;

          switch (txCommand.command) {
            case OxigenTxCommand.maximumSpeed:
              byte3 = 2;
              byte4 = txCarControllerPair.maximumSpeed ?? 0;
              break;
            case OxigenTxCommand.minimumSpeed:
            case OxigenTxCommand.forceLcUp:
            case OxigenTxCommand.forceLcDown:
              byte3 = 3;
              byte4 = (txCarControllerPair.minimumSpeed ?? 0) |
                  (txCarControllerPair.forceLcDown == null
                      ? 0
                      : txCarControllerPair.forceLcDown!
                          ? 64
                          : 0) |
                  (txCarControllerPair.forceLcUp == null
                      ? 0
                      : txCarControllerPair.forceLcUp!
                          ? 128
                          : 0);
              break;
            case OxigenTxCommand.pitlaneSpeed:
              byte3 = 1;
              byte4 = txCarControllerPair.pitlaneSpeed ?? 0;
              break;
            case OxigenTxCommand.maximumBrake:
              byte3 = 5;
              byte4 = txCarControllerPair.maximumBrake ?? 0;
              break;
            case OxigenTxCommand.transmissionPower:
              byte3 = 4;
              byte4 = txCarControllerPair.transmissionPower?.index ?? 0;
              break;
          }

          if (id > 0) {
            byte3 = byte3 | 0x80;
          }
        }

        var bytes = Uint8List.fromList(
            [byte0, maximumSpeed!, id, byte3, byte4, 0, 0, 0, 0, 0, 0]);
        serialPort!.write(bytes, timeout: 0);

        if (txTimeoutTimer != null) {
          txTimeoutTimer!.cancel();
        }
        txTimeoutTimer = Timer(
            Duration(milliseconds: txTimeout), () => _serialPortWriteLoop());
      }
    } on SerialPortError catch (e) {
      print('_serialPortReadStreamAsync SerialPortError error: ${e.message}');
      exceptionStreamController.add(e.message);
        _serialPortReset();
    } catch (e) {
      print('_serialPortWriteLoop error: $e');
      exceptionStreamController.add(e.toString());
    }
  }

  void _serialPortReadStream() {
    _serialPortReader = SerialPortReader(serialPort!);
    _serialPortStreamSubscription = _serialPortReader!.stream.listen((buffer) {
      try {
        rxBufferLength = buffer.length;

        if (buffer.length == 5) {
          _unusedBuffer = null;
          oxigenDongleFirmwareVersion = buffer[0] + buffer[1] / 100;
        } else if (buffer.length % 13 == 0) {
          _unusedBuffer = null;
          processBuffer(buffer);
        } else {
          //print('Got ${buffer.length} characters from stream');
          if (_unusedBuffer == null) {
            _unusedBuffer = buffer;
          } else {
            var bytesBuilder = BytesBuilder();
            bytesBuilder.add(_unusedBuffer!);
            bytesBuilder.add(buffer);
            _unusedBuffer = bytesBuilder.toBytes();
          }
          if (_unusedBuffer!.length % 13 == 0) {
            //print('Combining ${_unusedBuffer!.length} characters from stream');
            processBuffer(_unusedBuffer!);
          }
        }

        Timer(Duration(milliseconds: txDelay), () => _serialPortWriteLoop());

        notifyListeners();
      } on SerialPortError catch (e) {
        print('_serialPortReadStreamAsync SerialPortError error: ${e.message}');
        exceptionStreamController.add(e.message);
        _serialPortReset();
      } catch (e) {
        print('_serialPortReadStreamAsync error: $e');
        exceptionStreamController.add(e.toString());
      }
    });
  }

  void processBuffer(Uint8List buffer) {
    var offset = 0;
    do {
      var id = buffer[1 + offset];

      CarControllerPair carControllerPair;
      OxigenRxCarReset? oldCarReset;
      OxigenRxControllerCarLink? oldControllerCarLink;
      if (!carControllerPairs.containsKey(id)) {
        carControllerPair = CarControllerPair();
        carControllerPairs[id] = carControllerPair;
      } else {
        carControllerPair = carControllerPairs[id]!;
        oldCarReset = carControllerPair.rx.carReset;
        oldControllerCarLink = carControllerPair.rx.controllerCarLink;
      }

      if (buffer[0 + offset] & (pow(2, 0) as int) == 0) {
        carControllerPair.rx.carReset =
            OxigenRxCarReset.carPowerSupplyHasntChanged;
      } else {
        carControllerPair.rx.carReset =
            OxigenRxCarReset.carHasJustBeenPoweredUpOrReset;
      }
      if (carControllerPair.rx.carReset ==
              OxigenRxCarReset.carHasJustBeenPoweredUpOrReset &&
          oldCarReset != null &&
          oldCarReset != carControllerPair.rx.carReset) {
        carControllerPair.rx.carResetCount++;
      }

      if (buffer[0 + offset] & (pow(2, 1) as int) == 0) {
        carControllerPair.rx.controllerCarLink = OxigenRxControllerCarLink
            .controllerLinkWithItsPairedCarHasntChanged;
      } else {
        carControllerPair.rx.controllerCarLink = OxigenRxControllerCarLink
            .controllerHasJustGotTheLinkWithItsPairedCar;
      }
      if (carControllerPair.rx.controllerCarLink ==
              OxigenRxControllerCarLink
                  .controllerHasJustGotTheLinkWithItsPairedCar &&
          oldControllerCarLink != null &&
          oldControllerCarLink != carControllerPair.rx.controllerCarLink) {
        carControllerPair.rx.controllerCarLinkCount++;
      }

      if (buffer[0 + offset] & (pow(2, 2) as int) == 0) {
        carControllerPair.rx.controllerBatteryLevel =
            OxigenRxControllerBatteryLevel.ok;
      } else {
        carControllerPair.rx.controllerBatteryLevel =
            OxigenRxControllerBatteryLevel.low;
      }

      if (buffer[0 + offset] & (pow(2, 3) as int) == 0) {
        carControllerPair.rx.trackCall = OxigenRxTrackCall.no;
      } else {
        carControllerPair.rx.trackCall = OxigenRxTrackCall.yes;
      }

      if (buffer[0 + offset] & (pow(2, 5) as int) == 0) {
        carControllerPair.rx.arrowUpButton =
            OxigenRxArrowUpButton.buttonNotPressed;
      } else {
        carControllerPair.rx.arrowUpButton =
            OxigenRxArrowUpButton.buttonPressed;
      }

      if (buffer[0 + offset] & (pow(2, 6) as int) == 0) {
        carControllerPair.rx.arrowDownButton =
            OxigenRxArrowDownButton.buttonNotPressed;
      } else {
        carControllerPair.rx.arrowDownButton =
            OxigenRxArrowDownButton.buttonPressed;
      }

      if (buffer[7 + offset] & (pow(2, 7) as int) == 0) {
        carControllerPair.rx.carOnTrack = OxigenRxCarOnTrack.carIsNotOnTheTrack;
      } else {
        carControllerPair.rx.carOnTrack = OxigenRxCarOnTrack.carIsOnTheTrack;
      }

      if (buffer[8 + offset] & (pow(2, 6) as int) == 0) {
        carControllerPair.rx.carPitLane =
            OxigenRxCarPitLane.carIsNotInThePitLane;
      } else {
        carControllerPair.rx.carPitLane = OxigenRxCarPitLane.carIsInThePitLane;
      }

      carControllerPair.rx.triggerMeanValue = buffer[7 + offset] & 0x7F;
      carControllerPair.rx.dongleLapTime =
          buffer[2 + offset] * 256 + buffer[3 + offset];
      carControllerPair.rx.dongleLapTimeDelay = buffer[4 + offset];
      carControllerPair.rx.dongleLaps =
          buffer[6 + offset] * 256 + buffer[5 + offset];

      OxigenRxDeviceSoftwareReleaseOwner deviceSoftwareReleaseOwner;
      if (buffer[8 + offset] & (pow(2, 7) as int) == 0) {
        deviceSoftwareReleaseOwner =
            OxigenRxDeviceSoftwareReleaseOwner.controllerSoftwareRelease;
      } else {
        deviceSoftwareReleaseOwner =
            OxigenRxDeviceSoftwareReleaseOwner.carSoftwareRelease;
      }

      var softwareRelease = (buffer[8 + offset] & 48) / 16 +
          (buffer[0 + offset] & 16) / 100 +
          (buffer[8 + offset] & 15) / 100;

      switch (deviceSoftwareReleaseOwner) {
        case OxigenRxDeviceSoftwareReleaseOwner.controllerSoftwareRelease:
          carControllerPair.rx.controllerFirmwareVersion = softwareRelease;
          break;
        case OxigenRxDeviceSoftwareReleaseOwner.carSoftwareRelease:
          carControllerPair.rx.carFirmwareVersion = softwareRelease;
          break;
      }

      carControllerPair.rx.dongleRaceTimer = buffer[9 + offset] * 16777216 +
          buffer[10 + offset] * 65536 +
          buffer[11 + offset] * 256 +
          buffer[12 + offset];

      carControllerPair.rx.dongleLapRaceTimer =
          carControllerPair.rx.dongleRaceTimer -
              carControllerPair.rx.dongleLapTimeDelay;

      carControllerPair.rx.dongleLapTimeSeconds =
          carControllerPair.rx.dongleLapTime / 99.25;

      if (carControllerPair.rx.previousLapRaceTimer == null) {
        if (carControllerPair.rx.dongleRaceTimer == 0) {
          carControllerPair.rx.previousLapRaceTimer = 0;
        }
      } else if (carControllerPair.rx.dongleRaceTimer > 0) {
        if (carControllerPair.rx.previousLapRaceTimer !=
            carControllerPair.rx.dongleLapRaceTimer) {
          if (carControllerPair.rx.calculatedLaps == null) {
            carControllerPair.rx.calculatedLaps = 0;
          } else {
            carControllerPair.rx.calculatedLaps =
                carControllerPair.rx.calculatedLaps! + 1;
            if (carControllerPair.rx.previousLapRaceTimer != null) {
              carControllerPair.rx.calculatedLapTimeSeconds =
                  (carControllerPair.rx.dongleLapRaceTimer -
                          carControllerPair.rx.previousLapRaceTimer!) /
                      100.0;

              if (carControllerPair.rx.fastestLapTime == null ||
                  carControllerPair.rx.fastestLapTime! >
                      carControllerPair.rx.calculatedLapTimeSeconds!) {
                carControllerPair.rx.fastestLapTime =
                    carControllerPair.rx.calculatedLapTimeSeconds!;
              }

              carControllerPair.rx.practiceSessionLaps.addFirst(
                  PracticeSessionLap(
                      lap: carControllerPair.rx.calculatedLaps!,
                      lapTime: carControllerPair.rx.calculatedLapTimeSeconds!));
              if (carControllerPair.rx.practiceSessionLaps.length >= 6) {
                carControllerPair.rx.practiceSessionLaps.removeLast();
              }
            }
          }
          carControllerPair.rx.previousLapRaceTimer =
              carControllerPair.rx.dongleLapRaceTimer;
        }
      }

      var now = DateTime.now();
      if (carControllerPair.rx.updatedAt != null) {
        carControllerPair.rx.refreshRate = now.millisecondsSinceEpoch -
            carControllerPair.rx.updatedAt!.millisecondsSinceEpoch;
        refreshRateQueue.addLast(carControllerPair.rx.refreshRate!);
        if (refreshRateQueue.length >= 100) {
          refreshRateQueue.removeFirst();
        }
      }
      carControllerPair.rx.updatedAt = now;

      offset = offset + 13;
    } while (offset < buffer.length - 1);
  }
}
