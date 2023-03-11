import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'oxigen_constants.dart';

class RxControllerCarPair {
  late OxigenRxCarReset carReset;
  late OxigenRxControllerCarLink controllerCarLink;
  late OxigenRxControllerBatteryLevel controllerBatteryLevel;
  late OxigenRxTrackCall trackCall;
  late OxigenRxArrowUpButton arrowUpButton;
  late OxigenRxArrowDownButton arrowDownButton;
  late OxigenRxCarOnTrack carOnTrack;
  late OxigenRxCarPitLane carPitLane;
  late int triggerMeanValue;
}

class AppModel extends ChangeNotifier {
  SerialPort? serialPort;
  SerialPortReader? _serialPortReader;
  List<String> availablePortNames = [];
  OxigenTxPitlaneLapCounting? oxigenTxPitlaneLapCounting;
  OxigenTxPitlaneLapTrigger? oxigenTxPitlaneLapTrigger;
  OxigenTxRaceStatus? oxigenTxRaceStatus = OxigenTxRaceStatus.running;
  int oxigenMaximumSpeed = 255;

  double? oxigenDongleFirmwareVersion;
  Map<int, RxControllerCarPair> rxControllerCarPairs = {};

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
    return serialPort != null && !serialPort!.isOpen;
  }

  void serialPortOpen() {
    print(serialPort!.name);
    print('open');
    if (!serialPort!.openReadWrite()) {
      print(SerialPort.lastError);
      return;
    }
    _serialPortReadStreamAsync();
    serialPortDongleCommandDongleFirmwareVersion();
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

  void serialPortDongleCommandDongleFirmwareVersion() {
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

  void serialPortWriteRaceStatus() {
    int byte0;
    switch (oxigenTxRaceStatus) {
      case null:
        return;
      case OxigenTxRaceStatus.running:
        byte0 = 0x3;
        break;
      case OxigenTxRaceStatus.paused:
        byte0 = 0x4;
        break;
      case OxigenTxRaceStatus.stopped:
        byte0 = 0x1;
        break;
      case OxigenTxRaceStatus.flaggedLcEnabled:
        byte0 = 0x5;
        break;
      case OxigenTxRaceStatus.flaggedLcDisabled:
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

    var bytes = Uint8List.fromList([byte0, oxigenMaximumSpeed, 0, 0, 0, 0, 0, 0, 0, 0]);
    var i = serialPort!.write(bytes);
    print(i);
    print(serialPort!.bytesAvailable);
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
            var rxControllerCarPair = RxControllerCarPair();

            if (buffer[0 + offset] & (pow(2, 0) as int) == 0) {
              rxControllerCarPair.carReset = OxigenRxCarReset.carPowerSupplyHasntChanged;
            } else {
              rxControllerCarPair.carReset = OxigenRxCarReset.carHasJustBeenPoweredUpOrReset;
            }

            if (buffer[0 + offset] & (pow(2, 1) as int) == 0) {
              rxControllerCarPair.controllerCarLink =
                  OxigenRxControllerCarLink.controllerLinkWithItsPairedCarHasntChanged;
            } else {
              rxControllerCarPair.controllerCarLink =
                  OxigenRxControllerCarLink.controllerHasJustGotTheLinkWithItsPairedCar;
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

            rxControllerCarPairs[buffer[1 + offset]] = rxControllerCarPair;

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
