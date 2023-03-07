import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late List<String> availablePortNames;
  SerialPort? selectedSerialPort;
  late SerialPortConfig serialPortConfig;

  @override
  didChangeDependencies() {
    super.didChangeDependencies();

    serialPortConfig = SerialPortConfig();
    serialPortConfig.baudRate = 9600;

    initPorts();
  }

  void initPorts() {
    setState(() {
      availablePortNames = SerialPort.availablePorts;
      if (availablePortNames.isEmpty) {
        clearSelectedSerialPort();
      } else {
        selectedSerialPort = SerialPort(availablePortNames.first);
      }
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(children: [
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
            onPressed: (selectedSerialPort != null && !selectedSerialPort!.isOpen)
                ? () {
                    setState(() {
                      print(selectedSerialPort!.name);
                      print('open');
                      //print(selectedSerialPort!.config.baudRate);
                      if (!selectedSerialPort!.openReadWrite()) {
                        print(SerialPort.lastError);
                      }
                      print(selectedSerialPort!.isOpen);
                    });
                  }
                : null,
            child: const Text('Open')),
        FilledButton.tonal(
            onPressed: (selectedSerialPort != null && selectedSerialPort!.isOpen)
                ? () {
                    setState(() {
                      print(selectedSerialPort!.name);
                      print('close');
                      if (!selectedSerialPort!.close()) {
                        print(SerialPort.lastError);
                      }
                      print(selectedSerialPort!.isOpen);
                    });
                  }
                : null,
            child: const Text('Close'))
      ]),
    );
  }
}
