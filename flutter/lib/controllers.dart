import 'package:flutter/material.dart';
import 'package:oxigen_protocol_explorer_3/oxigen_constants.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'page_base.dart';

class ControllersPage extends PageBase {
  const ControllersPage({super.key}) : super(body: const Controllers());

  @override
  State<PageBase> createState() => _ControllersPageState();
}

class _ControllersPageState<SettingsPage> extends PageBaseState<PageBase> {}

class Controllers extends StatelessWidget {
  const Controllers({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, model, child) {
      return DataTable(
          columns: const [
            DataColumn(label: Text('Id'), numeric: true),
            DataColumn(label: Text('Throttle')),
            DataColumn(label: Text('Track call')),
            DataColumn(label: Text('Up button')),
            DataColumn(label: Text('Down button')),
            DataColumn(label: Text('Battery')),
            DataColumn(label: Text('Firmware'), numeric: true),
          ],
          rows: model.rxControllerCarPairs
              .where((x) => x != null)
              .map((x) => DataRow(cells: [
                    DataCell(Text(x!.id.toString())),
                    DataCell(Text(x.triggerMeanValue.toString())),
                    DataCell(x.trackCall == OxigenRxTrackCall.yes
                        ? const Icon(Icons.flag, color: Colors.red)
                        : const Text('')),
                    DataCell(x.arrowUpButton == OxigenRxArrowUpButton.buttonPressed
                        ? const Icon(Icons.arrow_upward)
                        : const Text('')),
                    DataCell(x.arrowDownButton == OxigenRxArrowDownButton.buttonPressed
                        ? const Icon(Icons.arrow_downward)
                        : const Text('')),
                    DataCell(x.controllerBatteryLevel == OxigenRxControllerBatteryLevel.ok
                        ? const Icon(Icons.battery_full)
                        : const Icon(Icons.battery_alert)),
                    DataCell(Text(x.controllerFirmwareVersion.toString())),
                  ]))
              .toList());
    });
  }
}
