import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oxigen_protocol_explorer_3/page_base.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'race_state_button.dart';

class PracticeSession extends StatefulWidget {
  const PracticeSession({super.key});

  @override
  State<PracticeSession> createState() => _PracticeSessionState();
}

class _PracticeSessionState extends State<PracticeSession> {
  StreamSubscription<String>? exceptionStreamSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    exceptionStreamSubscription = context.read<AppModel>().exceptionStreamController.stream.listen((message) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 10)));
    });
  }

  @override
  void dispose() async {
    super.dispose();
    if (exceptionStreamSubscription != null) {
      await exceptionStreamSubscription!.cancel();
    }
  }

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
                return LayoutBuilder(builder: (context, constraints) {
                  var fontSize = min(constraints.maxHeight / 20, constraints.maxWidth / carControllerPairs.length / 10);
                  return Column(
                    children: [
                      RaceStateButton(value: model.txRaceState, setValue: model.oxigenTxRaceStateSet),
                      const SizedBox(height: 16),
                      Table(
                        children: [
                          TableRow(
                              children: carControllerPairs
                                  .map((kv) => Center(
                                          child: Text(
                                        kv.key.toString(),
                                        style: TextStyle(fontSize: fontSize * 2, fontWeight: FontWeight.bold),
                                      )))
                                  .toList()),
                          TableRow(
                              children: carControllerPairs
                                  .map((kv) => Center(
                                      child: Text('Laps',
                                          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold))))
                                  .toList()),
                          TableRow(
                              children: carControllerPairs
                                  .map((kv) => Center(
                                        child: Text(
                                            kv.value.rx.calculatedLaps == null
                                                ? ''
                                                : kv.value.rx.calculatedLaps.toString(),
                                            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                                      ))
                                  .toList()),
                          TableRow(
                              children: carControllerPairs
                                  .map((kv) => Center(
                                      child: Text('Fastest lap',
                                          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold))))
                                  .toList()),
                          TableRow(
                              children: carControllerPairs
                                  .map((kv) => Center(
                                        child: Text(
                                            kv.value.rx.fastestLapTime == null
                                                ? ''
                                                : kv.value.rx.fastestLapTime!.toStringAsFixed(2),
                                            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
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
                                            TableRow(children: [
                                              Align(
                                                  alignment: Alignment.centerRight,
                                                  child: Text('Lap',
                                                      style:
                                                          TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold))),
                                              SizedBox(width: fontSize),
                                              Align(
                                                  alignment: Alignment.centerRight,
                                                  child: Text('Lap time',
                                                      style:
                                                          TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)))
                                            ])
                                          ]
                                              .followedBy(
                                                  kv.value.rx.practiceSessionLaps.map((x) => TableRow(children: [
                                                        Align(
                                                            alignment: Alignment.centerRight,
                                                            child: Text(x.lap.toString(),
                                                                style: TextStyle(
                                                                    fontSize: fontSize, fontWeight: FontWeight.bold))),
                                                        const SizedBox(width: 16),
                                                        Align(
                                                            alignment: Alignment.centerRight,
                                                            child: Text(x.lapTime.toStringAsFixed(2),
                                                                style: TextStyle(
                                                                    fontSize: fontSize, fontWeight: FontWeight.bold)))
                                                      ])))
                                              .toList()),
                                    ),
                                  )
                                  .toList())
                        ],
                      ),
                    ],
                  );
                });
              }
            }),
          ),
        ),
      )
    ]);
  }
}
