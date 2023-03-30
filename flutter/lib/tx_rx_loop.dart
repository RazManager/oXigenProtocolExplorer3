import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oxigen_protocol_explorer_3/page_base.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';

class TxRxLoop extends StatefulWidget {
  const TxRxLoop({super.key});

  @override
  State<TxRxLoop> createState() => _TxRxLoopState();
}

class _TxRxLoopState extends State<TxRxLoop> {
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
                title: const Text('TX/RX loop'),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Consumer<AppModel>(builder: (context, model, child) {
                  var carControllerPairs = model.carControllerPairs.entries
                      .where((x) => x.key != 0 && x.value.rx.refreshRate != null)
                      .toList();
                  carControllerPairs.sort((a, b) => a.key.compareTo(b.key));
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Table(
                      children: [
                        const TableRow(children: [
                          Center(
                            child: Text(
                              'Transmit delay (ms) *',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Center(
                            child: Text(
                              'Transmit timeout (ms) *',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Center(
                            child: Text(
                              'Controller timeout (s) *',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]),
                        TableRow(children: [
                          Center(child: Text(model.txDelay.toString())),
                          Center(child: Text(model.txTimeout.toString())),
                          Center(child: Text(model.rxControllerTimeout.toString())),
                        ]),
                        TableRow(children: [
                          Slider(
                            min: 0,
                            max: 2000,
                            divisions: 2000,
                            value: model.txDelay.toDouble(),
                            onChanged: (newValue) {
                              if (newValue <= model.txTimeout) {
                                model.txDelaySet(newValue.round());
                              }
                            },
                          ),
                          Slider(
                            min: 0,
                            max: 2000,
                            divisions: 2000,
                            value: model.txTimeout.toDouble(),
                            onChanged: (newValue) {
                              if (newValue >= model.txDelay) {
                                model.txTimeoutSet(newValue.round());
                              }
                            },
                          ),
                          Slider(
                            min: 10,
                            max: 60,
                            divisions: 50,
                            value: model.rxControllerTimeout.toDouble(),
                            onChanged: (newValue) {
                              model.controllerTimeoutSet(newValue.round());
                            },
                          ),
                        ])
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'RX buffer length',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                            width: 25,
                            child:
                                Align(alignment: Alignment.centerRight, child: Text(model.rxBufferLength.toString()))),
                        const SizedBox(width: 10),
                        Expanded(child: LinearProgressIndicator(value: model.rxBufferLength / 52)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Car/controller RX refresh rate (ms)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                            maxY: model.refreshRateQueue.isEmpty ? null : model.refreshRateQueue.reduce(max).toDouble(),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(drawVerticalLine: false),
                            barGroups: carControllerPairs
                                .map((kv) => BarChartGroupData(x: kv.key, barRods: [
                                      BarChartRodData(toY: kv.value.rx.refreshRate!.toDouble(), color: Colors.blueGrey)
                                    ]))
                                .toList()),
                      ),
                    ),
                  ]);
                }),
              )))
    ]);
  }
}
