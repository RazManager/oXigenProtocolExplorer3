import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oxigen_protocol_explorer_3/page_base.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'race_state_button.dart';

class PracticeSession extends StatelessWidget {
  const PracticeSession({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const AppNavigationRail(),
      Expanded(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Practice session'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<AppModel>(builder: (context, model, child) {
              var carControllerPairs = model.carControllerPairs.entries.where((x) => x.key != 0).toList();
              carControllerPairs.sort((a, b) => a.key.compareTo(b.key));
              if (carControllerPairs.isEmpty) {
                return const Center(child: Text('There are no connected controllers'));
              } else {
                return Column(
                  children: [
                    RaceStateButton(value: model.txRaceState, setValue: model.oxigenTxRaceStateSet),
                    Table(
                      children: [
                        TableRow(
                            children: carControllerPairs.map((kv) => Center(child: Text(kv.key.toString()))).toList()),
                        TableRow(children: carControllerPairs.map((kv) => const Center(child: Text('Laps'))).toList()),
                        TableRow(
                            children: carControllerPairs
                                .map((kv) => Center(
                                      child: Text(kv.value.rx.calculatedLaps == null
                                          ? ''
                                          : kv.value.rx.calculatedLaps.toString()),
                                    ))
                                .toList()),
                        TableRow(
                            children:
                                carControllerPairs.map((kv) => const Center(child: Text('Fastest lap'))).toList()),
                        TableRow(
                            children: carControllerPairs
                                .map((kv) => Center(
                                      child: Text(kv.value.rx.fastestLapTime == null
                                          ? ''
                                          : kv.value.rx.fastestLapTime!.toStringAsFixed(2)),
                                    ))
                                .toList()),
                        TableRow(
                            children: carControllerPairs
                                .map(
                                  (kv) => Center(
                                    child: Table(
                                        columnWidths: const <int, TableColumnWidth>{
                                          0: IntrinsicColumnWidth(),
                                          1: IntrinsicColumnWidth(),
                                          2: IntrinsicColumnWidth(),
                                        },
                                        children: [
                                          const TableRow(children: [
                                            Align(alignment: Alignment.centerRight, child: Text('Lap')),
                                            SizedBox(width: 16),
                                            Align(alignment: Alignment.centerRight, child: Text('Lap time'))
                                          ])
                                        ]
                                            .followedBy(kv.value.rx.practiceSessionLaps.map((x) => TableRow(children: [
                                                  Align(
                                                      alignment: Alignment.centerRight, child: Text(x.lap.toString())),
                                                  const SizedBox(width: 16),
                                                  Align(
                                                      alignment: Alignment.centerRight,
                                                      child: Text(x.lapTime.toStringAsFixed(2)))
                                                ])))
                                            .toList()),
                                  ),
                                )
                                .toList())
                      ],
                    ),
                  ],
                );
              }
            }),
          ),
        ),
      )
    ]);
  }
}
