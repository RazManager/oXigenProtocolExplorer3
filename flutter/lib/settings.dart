import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:provider/provider.dart';

import 'oxigen_constants.dart';
import 'app_model.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    var model = context.read<AppModel>();
    return Column(
      children: [
        DropdownButton<dynamic>(
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
            onChanged: (value) => model.serialPortSet(value, true)),
        Consumer<AppModel>(builder: (context, model, child) {
          return Column(children: [
            Row(
              children: [
                FilledButton.tonal(
                    onPressed: (model.serialPortCanOpen()) ? () => model.serialPortOpen() : null,
                    child: const Text('Open')),
                FilledButton.tonal(
                    onPressed: (model.serialPortCanClose()) ? () => model.serialPortClose() : null,
                    child: const Text('Close')),
                FilledButton.tonal(
                    onPressed:
                        (model.serialPortIsOpen()) ? () => model.serialPortDongleCommandDongleFirmwareVersion() : null,
                    child: const Text('Get dongle release')),
                FilledButton.tonal(
                    onPressed: (model.serialPortIsOpen()) ? () => model.serialPortWriteRaceStatus() : null,
                    child: const Text('Write')),
                // ]),
              ],
            ),
            const Text('Pitlane lap counting'),
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
            const Text('Pitlane lap trigger placement'),
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
            )
          ]);
        }),
      ],
    );
  }
}
