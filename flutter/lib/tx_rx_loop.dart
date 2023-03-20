import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oxigen_protocol_explorer_3/page_base.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';

class TxRxLoop extends StatelessWidget {
  const TxRxLoop({super.key});

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
                  return Column(children: [
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
                    const Text(
                      'Car/controller RX refresh rate (ms)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                            maxY: model.refreshRateQueue.isEmpty ? null : model.refreshRateQueue.reduce(max).toDouble(),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(drawVerticalLine: false),
                            barGroups: model.carControllerPairs.entries
                                .where((x) => x.key != 0 && x.value.rx.refreshRate != null)
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
