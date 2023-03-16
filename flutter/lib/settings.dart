import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:provider/provider.dart';

import 'command_slider.dart';
import 'oxigen_constants.dart';
import 'app_model.dart';
import 'page_base.dart';
import 'race_state_button.dart';

class SettingsPage extends PageBase {
  const SettingsPage({super.key})
      : super(title: 'Settings', body: const Settings(), bottomNavigationBar: const SettingsBottomAppBar());

  @override
  State<PageBase> createState() => _SettingsPageState();
}

class _SettingsPageState<SettingsPage> extends PageBaseState<PageBase> {}

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    var model = context.read<AppModel>();
    model.availablePortsRefresh(false);
    return Consumer<AppModel>(builder: (context, model, child) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DropdownButton<String>(
            value: model.serialPort?.name,
            items: model.availablePortNames.map<DropdownMenuItem<String>>((x) {
              var port = SerialPort(x);
              var result = DropdownMenuItem<String>(
                value: x,
                child: Text(port.description!),
              );
              port.dispose();
              return result;
            }).toList(),
            onChanged: (value) => model.serialPortSet(value!, true)),
        Table(
          columnWidths: const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(),
            1: IntrinsicColumnWidth(),
          },
          children: [
            const TableRow(children: [
              Text(
                'Pitlane lap counting *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Pitlane lap trigger placement *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ]),
            TableRow(children: [
              SegmentedButton<OxigenTxPitlaneLapCounting>(
                segments: const [
                  ButtonSegment<OxigenTxPitlaneLapCounting>(
                      value: OxigenTxPitlaneLapCounting.enabled, label: Text('Enabled')),
                  ButtonSegment<OxigenTxPitlaneLapCounting>(
                      value: OxigenTxPitlaneLapCounting.disabled, label: Text('Disabled')),
                ],
                emptySelectionAllowed: true,
                selected: model.oxigenTxPitlaneLapCounting == null ? {} : {model.oxigenTxPitlaneLapCounting!},
                onSelectionChanged: (selected) {
                  if (selected.isNotEmpty) {
                    model.oxigenTxPitlaneLapCountingSet(selected.first);
                  }
                },
              ),
              SegmentedButton<OxigenTxPitlaneLapTrigger>(
                segments: const [
                  ButtonSegment<OxigenTxPitlaneLapTrigger>(
                      value: OxigenTxPitlaneLapTrigger.pitlaneEntry, label: Text('Pitlane entry')),
                  ButtonSegment<OxigenTxPitlaneLapTrigger>(
                      value: OxigenTxPitlaneLapTrigger.pitlaneExit, label: Text('Pitlane exit')),
                ],
                emptySelectionAllowed: true,
                selected: model.oxigenTxPitlaneLapTrigger == null ? {} : {model.oxigenTxPitlaneLapTrigger!},
                onSelectionChanged: (model.oxigenTxPitlaneLapCounting == null ||
                        model.oxigenTxPitlaneLapCounting == OxigenTxPitlaneLapCounting.disabled)
                    ? null
                    : (selected) {
                        if (selected.isNotEmpty) {
                          model.oxigenPitlaneLapTriggerModeSet(selected.first);
                        }
                      },
              ),
            ])
          ],
        ),
        const Text(
          'Race state *',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        RaceStateButton(value: model.oxigenTxRaceState, setValue: model.oxigenTxRaceStateSet),
        const Text(
          'Maximum speed (TX byte 1) *',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CommandSlider(max: 255, value: model.oxigenMaximumSpeed, setValue: model.oxigenMaximumSpeedSet),
        Table(
          // columnWidths: const <int, TableColumnWidth>{
          //   0: IntrinsicColumnWidth(),
          //   1: IntrinsicColumnWidth(),
          //   2: IntrinsicColumnWidth(),
          // },
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
              Center(child: Text(model.controllerTimeout.toString())),
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
                value: model.controllerTimeout.toDouble(),
                onChanged: (newValue) {
                  model.controllerTimeoutSet(newValue.round());
                },
              ),
            ])
          ],
        ),
      ]);
    });
  }
}

class SettingsBottomAppBar extends StatelessWidget {
  const SettingsBottomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, model, child) {
      return BottomAppBar(
        child: Row(
          children: [
            FilledButton.tonal(
                onPressed: (model.serialPortCanOpen()) ? () => model.serialPortOpen() : null,
                child: const Text('Open')),
            FilledButton.tonal(
                onPressed: (model.serialPortCanClose()) ? () => model.serialPortClose() : null,
                child: const Text('Close')),
          ],
        ),
      );
    });
  }
}
