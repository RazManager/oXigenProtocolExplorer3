import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';

class Controllers extends StatelessWidget {
  const Controllers({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, model, child) {
      return DataTable(
        columns: const [
          DataColumn(label: Text('Id')),
          DataColumn(label: Text('Throttle')),
          DataColumn(label: Text('Battery OK')),
          DataColumn(label: Text('Track call')),
          DataColumn(label: Text('Up arrow')),
          DataColumn(label: Text('Down arrow'))
        ],
        rows: model.rxControllerCarPairs.entries
            .map((x) => DataRow(cells: [
                  DataCell(Text(x.key.toString())),
                  DataCell(Text(x.value.triggerMeanValue.toString())),
                  DataCell(Text(x.value.controllerBatteryLevel.toString())),
                  DataCell(Text(x.value.trackCall.toString())),
                  DataCell(Text(x.value.arrowUpButton.toString())),
                  DataCell(Text(x.value.arrowDownButton.toString())),
                ]))
            .toList(),
      );
    });
  }
}
