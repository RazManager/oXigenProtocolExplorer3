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

enum ChartType { bar, line }

class _TxRxLoopState extends State<TxRxLoop> {
  StreamSubscription<String>? exceptionStreamSubscription;

  final carControllerColors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.lime,
    Colors.cyan,
    Colors.grey,
    Colors.purple,
    Colors.brown,
    Colors.indigo,
    Colors.pink,
    Colors.teal,
    Colors.deepOrange,
    Colors.blueGrey,
    Colors.deepPurple,
    Colors.lightGreen,
    Colors.lightBlue,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.amberAccent,
  ];

  ChartType chartType = ChartType.bar;

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
              final carControllerPairs =
                  model.carControllerPairs.entries.where((x) => x.key != 0 && x.value.rx.refreshRate != null).toList();
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
                SegmentedButton<ChartType>(
                  segments: const [
                    ButtonSegment<ChartType>(
                        value: ChartType.bar, label: Text('Bar chart'), icon: Icon(Icons.bar_chart)),
                    ButtonSegment<ChartType>(
                        value: ChartType.line, label: Text('Line chart'), icon: Icon(Icons.ssid_chart)),
                  ],
                  selected: {chartType},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      setState(() {
                        chartType = selected.first;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (chartType == ChartType.bar) ...[
                  const Text(
                    'RX buffer length',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                          width: 25,
                          child: Align(alignment: Alignment.centerRight, child: Text(model.rxBufferLength.toString()))),
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
                          maxY: model.refreshRatesQueue.isEmpty ? null : model.refreshRatesQueue.reduce(max).toDouble(),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(drawVerticalLine: false),
                          barGroups: carControllerPairs
                              .map((kv) => BarChartGroupData(x: kv.key, barRods: [
                                    BarChartRodData(
                                        toY: kv.value.rx.refreshRate!.toDouble(), color: carControllerColors[kv.key])
                                  ]))
                              .toList()),
                    ),
                  ),
                ],
                if (chartType == ChartType.line) ...[
                  const SizedBox(height: 16),
                  Expanded(
                    child: LineChart(
                        LineChartData(
                          lineBarsData: carControllerPairs
                              .map(
                                (kv) => LineChartBarData(
                                    spots: kv.value.rx.txRefreshRates
                                        .map((txr) => FlSpot(txr.txOffset.toDouble(), txr.refreshRate.toDouble()))
                                        .toList(),
                                    color: carControllerColors[kv.key]),
                              )
                              .toList(),
                          minY: 0,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(drawVerticalLine: false),
                          titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 0)),
                  ),
                  const SizedBox(height: 16),
                ],
              ]);
            }),
          ),
        ),
      )
    ]);
  }
}
