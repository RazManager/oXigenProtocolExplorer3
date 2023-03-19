import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'page_base.dart';

class LapDataPage extends PageBase {
  const LapDataPage({super.key}) : super(title: 'Lap data', body: const LapData());

  @override
  State<PageBase> createState() => _LapDataPageState();
}

class _LapDataPageState<SettingsPage> extends PageBaseState<PageBase> {}

class LapData extends StatelessWidget {
  const LapData({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, model, child) {
      var carControllerPairs = model.carControllerPairs.entries.where((x) => x.key != 0).toList();
      carControllerPairs.sort((a, b) => a.key.compareTo(b.key));
      if (carControllerPairs.isEmpty) {
        return const Center(child: Text('There are no connected controllers'));
      } else {
        return FittedBox(
          child: DataTable(
              columnSpacing: 10,
              columns: const [
                DataColumn(label: Text('Id'), numeric: true),
                DataColumn(label: Text('Lap time (cs)'), numeric: true),
                DataColumn(label: Text('Lap time delay'), numeric: true),
                DataColumn(label: Text('Laps'), numeric: true),
                DataColumn(label: Text('Timer'), numeric: true),
              ],
              rows: carControllerPairs
                  .map((x) => DataRow(cells: [
                        DataCell(Text(x.key.toString())),
                        DataCell(Text(x.value.rx.lastLapTime.toString())),
                        DataCell(Text(x.value.rx.lastLapTimeDelay.toString())),
                        DataCell(Text(x.value.rx.totalLaps.toString())),
                        DataCell(Text(x.value.rx.raceTimer.toString())),
                      ]))
                  .toList()),
        );
      }
    });
  }
}
