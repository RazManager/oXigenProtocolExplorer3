import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:oxigen_protocol_explorer_3/page_base.dart';

class SettingsPage extends PageBase {
  const SettingsPage({super.key}) : super(body: const Settings());

  @override
  State<PageBase> createState() => _SettingsPageState();
}

class _SettingsPageState<SettingsPage> extends PageBaseState<PageBase> {
  // @override
  // Widget build(BuildContext context) {
  //   return const Placeholder();
  // }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late List<String> availablePortNames;
  SerialPort? selectedSerialPort;
  //late SerialPortConfig serialPortConfig;
  //final ScrollController scrollController = ScrollController();

  @override
  didChangeDependencies() {
    super.didChangeDependencies();

    //serialPortConfig = SerialPortConfig();
    //serialPortConfig.baudRate = 9600;

    initPorts();
  }

  void initPorts() {
    clearSelectedSerialPort();
    availablePortNames = SerialPort.availablePorts;
    if (availablePortNames.isNotEmpty) {
      selectedSerialPort = SerialPort(availablePortNames.first);
    }
  }

  void setSelectedSerialPort(String name) {
    if (selectedSerialPort != null) {
      if (selectedSerialPort!.isOpen) {
        selectedSerialPort!.close();
      }
      selectedSerialPort!.dispose();
    }
    selectedSerialPort = SerialPort(name);
    //selectedSerialPort!.config = serialPortConfig;
  }

  void clearSelectedSerialPort() {
    if (selectedSerialPort != null) {
      if (selectedSerialPort!.isOpen) {
        selectedSerialPort!.close();
      }
      selectedSerialPort!.dispose();
    }
    selectedSerialPort = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<dynamic>(
            value: selectedSerialPort?.name,
            items: availablePortNames.map<DropdownMenuItem<String>>((x) {
              var port = SerialPort(x);
              var result = DropdownMenuItem<String>(
                value: x,
                child: Text(port.description!),
              );
              port.dispose();
              return result;
            }).toList(),
            onChanged: (value) {
              setState(() {
                setSelectedSerialPort(value);
              });
            }),
        FilledButton.tonal(
            onPressed: () {
              setState(() {
                initPorts();
              });
            },
            child: const Text('Refresh')),
        FilledButton.tonal(
            onPressed: (serialPortCanOpen())
                ? () {
                    setState(() {
                      serialPortOpen();
                    });
                  }
                : null,
            child: const Text('Open')),
        FilledButton.tonal(
            onPressed: (serialPortCanClose())
                ? () {
                    setState(() {
                      serialPortClose();
                    });
                  }
                : null,
            child: const Text('Close')),
        FilledButton.tonal(
            onPressed: (serialPortIsOpen())
                ? () {
                    setState(() {
                      serialPortDongleCommandRelease();
                    });
                  }
                : null,
            child: const Text('Get dongle release')),
        FilledButton.tonal(
            onPressed: (serialPortIsOpen())
                ? () {
                    setState(() {
                      serialPortRead();
                    });
                  }
                : null,
            child: const Text('Read')),
      ],
    );
  }

  bool serialPortCanOpen() {
    return selectedSerialPort != null && !selectedSerialPort!.isOpen;
  }

  void serialPortOpen() {
    print(selectedSerialPort!.name);
    print('open');
    //print(selectedSerialPort!.config.baudRate);
    if (!selectedSerialPort!.openReadWrite()) {
      print(SerialPort.lastError);
    }
    print(selectedSerialPort!.isOpen);
  }

  bool serialPortCanClose() {
    return selectedSerialPort != null && selectedSerialPort!.isOpen;
  }

  void serialPortClose() {
    print(selectedSerialPort!.name);
    print('close');
    if (!selectedSerialPort!.close()) {
      print(SerialPort.lastError);
    }
    print(selectedSerialPort!.isOpen);
  }

  bool serialPortIsOpen() {
    return selectedSerialPort != null && selectedSerialPort!.isOpen;
  }

  void serialPortDongleCommandRelease() {
    var bytes = Uint8List.fromList([6, 6, 6, 6, 0, 0, 0]);
    var i = selectedSerialPort!.write(bytes);
    print(i);
    print(selectedSerialPort!.bytesAvailable);
  }

  void serialPortRead() {
    print(selectedSerialPort!.bytesAvailable);
    var bytes = selectedSerialPort!.read(selectedSerialPort!.bytesAvailable);
    print(bytes);
  }
}
