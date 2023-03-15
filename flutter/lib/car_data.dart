import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'oxigen_constants.dart';
import 'page_base.dart';

class CarDataPage extends PageBase {
  const CarDataPage({super.key}) : super(title: 'Car data', body: const CarData());

  @override
  State<PageBase> createState() => _CarDataPageState();
}

class _CarDataPageState<SettingsPage> extends PageBaseState<PageBase> {}

class CarData extends StatelessWidget {
  const CarData({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, model, child) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
            columnSpacing: 10,
            columns: const [
              DataColumn(label: Text('Id'), numeric: true),
              DataColumn(label: Text('On track')),
              DataColumn(label: Text('Pitlane')),
              DataColumn(label: Text('Car reset')),
              DataColumn(label: Text('Link reset')),
              DataColumn(label: Text('Firmware'), numeric: true),
            ],
            rows: model.rxControllerCarPairs
                .where((x) => x != null)
                .map((x) => DataRow(cells: [
                      DataCell(Text(x!.id.toString())),
                      DataCell(x.carOnTrack == OxigenRxCarOnTrack.carIsOnTheTrack
                          ? const Icon(Icons.no_crash)
                          : const Icon(Icons.car_crash, color: Colors.red)),
                      DataCell(x.carPitLane == OxigenRxCarPitLane.carIsInThePitLane
                          ? const Icon(Icons.car_repair)
                          : const Text('')),
                      DataCell(Badge(
                          label: x.carResetCount == 0 ? null : Text(x.carResetCount.toString()),
                          child: const Icon(Icons.restart_alt))),
                      DataCell(Badge(
                          label: x.controllerCarLinkCount == 0 ? null : Text(x.controllerCarLinkCount.toString()),
                          child: const Icon(Icons.link))),
                      DataCell(Text(x.carFirmwareVersion.toString())),
                    ]))
                .toList()),
      );
    });
  }
}
