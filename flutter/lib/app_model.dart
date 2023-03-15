import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'oxigen_constants.dart';

class TxControllerCarPairState {
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

class RxControllerCarPair {
  RxControllerCarPair({required this.id});
  final int id;
  late OxigenRxCarReset carReset;
  int carResetCount = 0;
  late OxigenRxControllerCarLink controllerCarLink;
  int controllerCarLinkCount = 0;
  late OxigenRxControllerBatteryLevel controllerBatteryLevel;
  late OxigenRxTrackCall trackCall;
  late OxigenRxArrowUpButton arrowUpButton;
  late OxigenRxArrowDownButton arrowDownButton;
  late OxigenRxCarOnTrack carOnTrack;
  late OxigenRxCarPitLane carPitLane;
  late int triggerMeanValue;
  late int lastLapTime;
  late int lastLapTimeDelay;
  late int totalLaps;
  late int raceTimer;
  double? controllerFirmwareVersion;
  double? carFirmwareVersion;
}

class AppModel extends ChangeNotifier {
  int menuIndex = 0;
  SerialPort? serialPort;
  SerialPortReader? _serialPortReader;
  List<String> availablePortNames = [];
  OxigenTxPitlaneLapCounting? oxigenTxPitlaneLapCounting;
  OxigenTxPitlaneLapTrigger? oxigenTxPitlaneLapTrigger;
  OxigenTxRaceState? oxigenTxRaceState;
  int? oxigenMaximumSpeed;
  TxControllerCarPairState oxigenGlobalTxControllerCarPairState = TxControllerCarPairState();
  Queue<TxCommand> oxigenTxCommandQueue = Queue<TxCommand>();

  double? oxigenDongleFirmwareVersion;
  List<RxControllerCarPair?> rxControllerCarPairs = List<RxControllerCarPair?>.generate(20, (index) => null);

  void availablePortsRefresh(bool shouldNotify) {
    serialPortClear(shouldNotify);
    availablePortNames = SerialPort.availablePorts;
    if (availablePortNames.isNotEmpty) {
      serialPortSet(availablePortNames.first, shouldNotify);
    }
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void serialPortClear(bool shouldNotify) {
    if (serialPort != null) {
      if (serialPort!.isOpen) {
        serialPort!.close();
      }
      serialPort!.dispose();
    }
    serialPort = null;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void serialPortSet(String name, bool shouldNotify) {
    if (serialPort != null) {
      if (serialPort!.isOpen) {
        serialPort!.close();
      }
      serialPort!.dispose();
    }
    serialPort = SerialPort(name);
    if (shouldNotify) {
      notifyListeners();
    }
  }

  bool serialPortCanOpen() {
    return serialPort != null &&
        !serialPort!.isOpen &&
        oxigenTxPitlaneLapCounting != null &&
        (oxigenTxPitlaneLapCounting == OxigenTxPitlaneLapCounting.disabled || oxigenTxPitlaneLapTrigger != null);
  }

  void serialPortOpen() {
    print(serialPort!.name);
    print('open');
    if (!serialPort!.openReadWrite()) {
      print(SerialPort.lastError);
      return;
    }
    _serialPortReadStreamAsync();
    _serialPortDongleCommandDongleFirmwareVersion();
    _serialPortWriteLoop();
    notifyListeners();
  }

  bool serialPortCanClose() {
    return serialPort != null && serialPort!.isOpen;
  }

  void serialPortClose() {
    print(serialPort!.name);
    print('close');
    if (_serialPortReader != null) {
      _serialPortReader!.close();
      _serialPortReader = null;
    }

    if (!serialPort!.close()) {
      print(SerialPort.lastError);
    }
    print(serialPort!.isOpen);
    notifyListeners();
  }

  bool serialPortIsOpen() {
    return serialPort != null && serialPort!.isOpen;
  }

  void _serialPortDongleCommandDongleFirmwareVersion() {
    var bytes = Uint8List.fromList([6, 6, 6, 6, 0, 0, 0]);
    var i = serialPort!.write(bytes);
    print(i);
    print(serialPort!.bytesAvailable);
  }

  void oxigenTxPitlaneLapCountingSet(OxigenTxPitlaneLapCounting value) {
    oxigenTxPitlaneLapCounting = value;
    notifyListeners();
  }

  void oxigenPitlaneLapTriggerModeSet(OxigenTxPitlaneLapTrigger value) {
    oxigenTxPitlaneLapTrigger = value;
    notifyListeners();
  }

  void oxigenTxRaceStateSet(OxigenTxRaceState value) {
    oxigenTxRaceState = value;
    notifyListeners();
  }

  void oxigenMaximumSpeedSet(int value) {
    oxigenMaximumSpeed = value;
    notifyListeners();
  }

  void oxigenGlobalTxMaximumSpeedSet(int value) {
    oxigenGlobalTxControllerCarPairState.maximumSpeed = value;
    oxigenTxCommandQueue.addLast(TxCommand(id: 0, command: OxigenTxCommand.maximumSpeed));
    notifyListeners();
  }

  void oxigenGlobalTxMinimumSpeedSet(int value) {
    oxigenGlobalTxControllerCarPairState.minimumSpeed = value;
    oxigenTxCommandQueue.addLast(TxCommand(id: 0, command: OxigenTxCommand.minimumSpeed));
    notifyListeners();
  }

  void oxigenGlobalTxPitlaneSpeedSet(int value) {
    oxigenGlobalTxControllerCarPairState.pitlaneSpeed = value;
    oxigenTxCommandQueue.addLast(TxCommand(id: 0, command: OxigenTxCommand.pitlaneSpeed));
    notifyListeners();
  }

  void oxigenGlobalTxMaximumBrakeSet(int value) {
    oxigenGlobalTxControllerCarPairState.maximumBrake = value;
    oxigenTxCommandQueue.addLast(TxCommand(id: 0, command: OxigenTxCommand.maximumBrake));
    notifyListeners();
  }

  void oxigenGlobalTxForceLcUpSet(bool value) {
    oxigenGlobalTxControllerCarPairState.forceLcUp = value;
    oxigenTxCommandQueue.addLast(TxCommand(id: 0, command: OxigenTxCommand.forceLcUp));
    notifyListeners();
  }

  void oxigenGlobalTxForceLcDownSet(bool value) {
    oxigenGlobalTxControllerCarPairState.forceLcDown = value;
    oxigenTxCommandQueue.addLast(TxCommand(id: 0, command: OxigenTxCommand.forceLcDown));
    notifyListeners();
  }

  void oxigenGlobalTxTransmissionPowerSet(OxigenTxTransmissionPower value) {
    oxigenGlobalTxControllerCarPairState.transmissionPower = value;
    oxigenTxCommandQueue.addLast(TxCommand(id: 0, command: OxigenTxCommand.transmissionPower));
    notifyListeners();
  }

  void _serialPortWriteLoop() {
    print('_serialPortWriteLoop start');
    int byte0;
    switch (oxigenTxRaceState) {
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

    switch (oxigenTxPitlaneLapCounting) {
      case null:
        return;
      case OxigenTxPitlaneLapCounting.enabled:
        break;
      case OxigenTxPitlaneLapCounting.disabled:
        byte0 = byte0 | (pow(2, 5) as int);
        break;
    }

    if (oxigenTxPitlaneLapCounting != null && oxigenTxPitlaneLapCounting == OxigenTxPitlaneLapCounting.enabled) {
      switch (oxigenTxPitlaneLapTrigger) {
        case null:
          return;
        case OxigenTxPitlaneLapTrigger.pitlaneEntry:
          break;
        case OxigenTxPitlaneLapTrigger.pitlaneExit:
          byte0 = byte0 | (pow(2, 6) as int);
          break;
      }
    }

    if (oxigenMaximumSpeed == null) {
      return;
    }

    if (serialPortIsOpen()) {
      var id = 0;
      var byte3 = 0;
      var byte4 = 0;

      if (oxigenTxCommandQueue.isNotEmpty) {
        var txCommand = oxigenTxCommandQueue.first;
        oxigenTxCommandQueue.removeFirst();
        id = txCommand.id;
        switch (txCommand.command) {
          case OxigenTxCommand.maximumSpeed:
            byte3 = 2;
            byte4 = oxigenGlobalTxControllerCarPairState.maximumSpeed ?? 0;
            break;
          case OxigenTxCommand.minimumSpeed:
          case OxigenTxCommand.forceLcUp:
          case OxigenTxCommand.forceLcDown:
            byte3 = 3;
            byte4 = (oxigenGlobalTxControllerCarPairState.minimumSpeed ?? 0) &
                (oxigenGlobalTxControllerCarPairState.forceLcDown == null
                    ? 0
                    : oxigenGlobalTxControllerCarPairState.forceLcDown!
                        ? 64
                        : 0) &
                (oxigenGlobalTxControllerCarPairState.forceLcUp == null
                    ? 0
                    : oxigenGlobalTxControllerCarPairState.forceLcUp!
                        ? 128
                        : 0);
            break;
          case OxigenTxCommand.pitlaneSpeed:
            byte3 = 1;
            byte4 = oxigenGlobalTxControllerCarPairState.pitlaneSpeed ?? 0;
            break;
          case OxigenTxCommand.maximumBrake:
            byte3 = 5;
            byte4 = oxigenGlobalTxControllerCarPairState.maximumBrake ?? 0;
            break;
          case OxigenTxCommand.transmissionPower:
            byte3 = 4;
            byte4 = oxigenGlobalTxControllerCarPairState.transmissionPower?.index ?? 0;
            break;
        }
      }

      var bytes = Uint8List.fromList([byte0, oxigenMaximumSpeed!, id, byte3, byte4, 0, 0, 0, 0, 0, 0]);

      serialPort!.write(bytes);
      //print(i);
      //print(serialPort!.bytesAvailable);

      Timer(const Duration(milliseconds: 1000), () => _serialPortWriteLoop());
    }
  }

  Future<void> _serialPortReadStreamAsync() async {
    _serialPortReader = SerialPortReader(serialPort!);
    try {
      await for (var buffer in _serialPortReader!.stream.takeWhile((element) => element.isNotEmpty)) {
        print('Got ${buffer.length} characters from stream');

        if (buffer.length == 5) {
          oxigenDongleFirmwareVersion = buffer[0] + buffer[1] / 100;
        } else if (buffer.length % 13 == 0) {
          var offset = 0;
          do {
            var id = buffer[1 + offset];

            RxControllerCarPair rxControllerCarPair;
            OxigenRxCarReset? oldCarReset;
            OxigenRxControllerCarLink? oldControllerCarLink;
            if (rxControllerCarPairs[id] == null) {
              rxControllerCarPair = RxControllerCarPair(id: id);
            } else {
              rxControllerCarPair = rxControllerCarPairs[id]!;
              oldCarReset = rxControllerCarPair.carReset;
              oldControllerCarLink = rxControllerCarPair.controllerCarLink;
            }

            if (buffer[0 + offset] & (pow(2, 0) as int) == 0) {
              rxControllerCarPair.carReset = OxigenRxCarReset.carPowerSupplyHasntChanged;
            } else {
              rxControllerCarPair.carReset = OxigenRxCarReset.carHasJustBeenPoweredUpOrReset;
            }
            if (rxControllerCarPair.carReset == OxigenRxCarReset.carHasJustBeenPoweredUpOrReset &&
                oldCarReset != null &&
                oldCarReset != rxControllerCarPair.carReset) {
              rxControllerCarPair.carResetCount++;
            }

            if (buffer[0 + offset] & (pow(2, 1) as int) == 0) {
              rxControllerCarPair.controllerCarLink =
                  OxigenRxControllerCarLink.controllerLinkWithItsPairedCarHasntChanged;
            } else {
              rxControllerCarPair.controllerCarLink =
                  OxigenRxControllerCarLink.controllerHasJustGotTheLinkWithItsPairedCar;
            }
            if (rxControllerCarPair.controllerCarLink ==
                    OxigenRxControllerCarLink.controllerHasJustGotTheLinkWithItsPairedCar &&
                oldControllerCarLink != null &&
                oldControllerCarLink != rxControllerCarPair.controllerCarLink) {
              rxControllerCarPair.controllerCarLinkCount++;
            }

            if (buffer[0 + offset] & (pow(2, 2) as int) == 0) {
              rxControllerCarPair.controllerBatteryLevel = OxigenRxControllerBatteryLevel.ok;
            } else {
              rxControllerCarPair.controllerBatteryLevel = OxigenRxControllerBatteryLevel.low;
            }

            if (buffer[0 + offset] & (pow(2, 3) as int) == 0) {
              rxControllerCarPair.trackCall = OxigenRxTrackCall.no;
            } else {
              rxControllerCarPair.trackCall = OxigenRxTrackCall.yes;
            }

            if (buffer[0 + offset] & (pow(2, 5) as int) == 0) {
              rxControllerCarPair.arrowUpButton = OxigenRxArrowUpButton.buttonNotPressed;
            } else {
              rxControllerCarPair.arrowUpButton = OxigenRxArrowUpButton.buttonPressed;
            }

            if (buffer[0 + offset] & (pow(2, 6) as int) == 0) {
              rxControllerCarPair.arrowDownButton = OxigenRxArrowDownButton.buttonNotPressed;
            } else {
              rxControllerCarPair.arrowDownButton = OxigenRxArrowDownButton.buttonPressed;
            }

            if (buffer[7 + offset] & (pow(2, 7) as int) == 0) {
              rxControllerCarPair.carOnTrack = OxigenRxCarOnTrack.carIsNotOnTheTrack;
            } else {
              rxControllerCarPair.carOnTrack = OxigenRxCarOnTrack.carIsOnTheTrack;
            }

            if (buffer[8 + offset] & (pow(2, 6) as int) == 0) {
              rxControllerCarPair.carPitLane = OxigenRxCarPitLane.carIsNotInThePitLane;
            } else {
              rxControllerCarPair.carPitLane = OxigenRxCarPitLane.carIsInThePitLane;
            }

            rxControllerCarPair.triggerMeanValue = buffer[7 + offset] & 0x7F;
            rxControllerCarPair.lastLapTime = buffer[2 + offset] * 256 + buffer[3 + offset];
            rxControllerCarPair.lastLapTimeDelay = buffer[4 + offset];
            rxControllerCarPair.totalLaps = buffer[6 + offset] * 256 + buffer[5 + offset];

            OxigenRxDeviceSoftwareReleaseOwner deviceSoftwareReleaseOwner;
            if (buffer[8 + offset] & (pow(2, 7) as int) == 0) {
              deviceSoftwareReleaseOwner = OxigenRxDeviceSoftwareReleaseOwner.controllerSoftwareRelease;
            } else {
              deviceSoftwareReleaseOwner = OxigenRxDeviceSoftwareReleaseOwner.carSoftwareRelease;
            }

            var softwareRelease = (buffer[8 + offset] & 48) / 16 + (buffer[8 + offset] & 15) / 100;

            print(buffer[8 + offset] & (pow(2, 7) as int));
            print(buffer[8 + offset] & 15);

            switch (deviceSoftwareReleaseOwner) {
              case OxigenRxDeviceSoftwareReleaseOwner.controllerSoftwareRelease:
                rxControllerCarPair.controllerFirmwareVersion = softwareRelease;
                break;
              case OxigenRxDeviceSoftwareReleaseOwner.carSoftwareRelease:
                rxControllerCarPair.carFirmwareVersion = softwareRelease;
                break;
            }

            rxControllerCarPair.raceTimer = buffer[9 + offset] * 16777216 +
                buffer[10 + offset] * 65536 +
                buffer[11 + offset] * 256 +
                buffer[12 + offset];

            rxControllerCarPairs[id] = rxControllerCarPair;

            offset = offset + 13;
          } while (offset < buffer.length - 1);
        } else {
          // error
        }
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }
}
