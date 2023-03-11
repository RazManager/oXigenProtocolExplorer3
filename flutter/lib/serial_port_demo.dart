import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialPortDemo extends StatefulWidget {
  const SerialPortDemo({super.key});

  @override
  State<SerialPortDemo> createState() => _SerialPortDemoState();
}

class _SerialPortDemoState extends State<SerialPortDemo> {
  var availablePorts = [];

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    //initPorts();
  }

  void initPorts() {
    setState(() => availablePorts = SerialPort.availablePorts);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final address in availablePorts)
          Builder(builder: (context) {
            final port = SerialPort(address);
            return ExpansionTile(
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
