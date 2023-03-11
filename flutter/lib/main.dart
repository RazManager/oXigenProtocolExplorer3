import 'package:flutter/material.dart';
import 'package:oxigen_protocol_explorer_3/controllers.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'serial_port_demo.dart';
import 'settings.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0;
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppModel(),
      child: MaterialApp(
        title: 'oXigen Protocol Explorer 3',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
        home: LayoutBuilder(builder: (context, boxConstraints) {
          context.read<AppModel>().availablePortsRefresh(false);
          if (boxConstraints.maxWidth > 600) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  //labelType: labelType,
                  leading: const Text('3 oXigen Protocol Explorer'),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_applications_outlined),
                      selectedIcon: Icon(Icons.settings_applications),
                      label: Text('Settings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.car_crash_outlined),
                      selectedIcon: Icon(Icons.car_crash),
                      label: Text('Controllers'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.developer_mode),
                      selectedIcon: Icon(Icons.book),
                      label: Text('Demo'),
                    ),
                  ],
                ),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Settings'),
                    ),
                    body: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: const [Settings(), Controllers(), Text('demo')],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            );
          } else {
            return const Text('small...');
          }
        }),
      ),
    );
  }
}
