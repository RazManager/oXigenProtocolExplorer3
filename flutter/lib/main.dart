import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'serial_port_demo.dart';
import 'settings.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppModel(),
      child: MaterialApp.router(
        title: 'oXigen Protocol Explorer 3',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: '/serial-port-demo',
              builder: (context, state) => const SerialPortDemo(),
            ),
          ],
        ),
      ),
    );
  }
}
