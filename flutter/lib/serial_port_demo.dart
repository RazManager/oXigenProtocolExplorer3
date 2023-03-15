import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'page_base.dart';

class DemoPage extends PageBase {
  const DemoPage({super.key}) : super(title: 'Demo', body: const Demo());

  @override
  State<PageBase> createState() => _DemoPageState();
}

class _DemoPageState<SettingsPage> extends PageBaseState<PageBase> {}

class Demo extends StatefulWidget {
  const Demo({super.key});

  @override
  State<Demo> createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  var availablePorts = [];

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    initPorts();
  }

  void initPorts() {
    setState(() => availablePorts = SerialPort.availablePorts);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final address in availablePorts)
          Builder(builder: (context) {
            final port = SerialPort(address);
            return Expanded(
              child: ExpansionTile(
                title: Text(address),
                children: [
                  CardListTile(name: 'Description', value: port.description),
                  CardListTile(name: 'Transport', value: port.transport.toTransport()),
                  CardListTile(name: 'USB Bus', value: port.busNumber?.toPadded()),
                  CardListTile(name: 'USB Device', value: port.deviceNumber?.toPadded()),
                  CardListTile(name: 'Vendor ID', value: port.vendorId?.toHex()),
                  CardListTile(name: 'Product ID', value: port.productId?.toHex()),
                  CardListTile(name: 'Manufacturer', value: port.manufacturer),
                  CardListTile(name: 'Product Name', value: port.productName),
                  CardListTile(name: 'Serial Number', value: port.serialNumber),
                  CardListTile(name: 'MAC Address', value: port.macAddress),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class CardListTile extends StatelessWidget {
  const CardListTile({super.key, required this.name, required this.value});
  final String name;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(value ?? 'N/A'),
        subtitle: Text(name),
      ),
    );
  }
}

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    switch (this) {
      case SerialPortTransport.usb:
        return 'USB';
      case SerialPortTransport.bluetooth:
        return 'Bluetooth';
      case SerialPortTransport.native:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}
