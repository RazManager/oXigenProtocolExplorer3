import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'app_model.dart';
import 'car_controller_commands.dart';
import 'car_data.dart';
import 'controller_data.dart';
import 'global_commands.dart';
import 'serial_port_demo.dart';
import 'settings.dart';

final router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const SettingsPage()),
    ),
    GoRoute(
      path: '/global-commands',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const GlobalCommandsPage()),
    ),
    GoRoute(
      path: '/car-controller-commands',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const CarControllerCommands()),
    ),
    GoRoute(
      path: '/controller-data',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const ControllerDataPage()),
    ),
    GoRoute(
      path: '/car-data',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const CarDataPage()),
    ),
    GoRoute(
      path: '/demo',
      pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: const DemoPage()),
    ),
  ],
);

class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({super.key});

  @override
  Widget build(BuildContext context) {
    var model = context.read<AppModel>();
    return NavigationRail(
      selectedIndex: model.menuIndex,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (index) {
        model.menuIndex = index;
        switch (index) {
          case 0:
            context.go('/');
            break;

          case 1:
            context.go('/global-commands');
            break;

          case 2:
            context.go('/car-controller-commands');
            break;

          case 3:
            context.go('/controller-data');
            break;

          case 4:
            context.go('/car-data');
            break;

          case 5:
            context.go('/demo');
            break;

          default:
        }
      },
      //labelType: labelType,
      leading: const Text('3 oXigen Protocol Explorer'),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          selectedIcon: Icon(Icons.settings),
          label: Text('Global commands'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          selectedIcon: Icon(Icons.settings),
          label: Text('Controller/car commands'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.speed_outlined),
          selectedIcon: Icon(Icons.speed),
          label: Text('Controller data'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          selectedIcon: Icon(Icons.settings),
          label: Text('Car data'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          selectedIcon: Icon(Icons.settings),
          label: Text('Lap times'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          selectedIcon: Icon(Icons.settings),
          label: Text('Practice session'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          selectedIcon: Icon(Icons.settings),
          label: Text('About'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.developer_mode),
          selectedIcon: Icon(Icons.book),
          label: Text('Demo'),
        ),
      ],
    );
  }
}

abstract class PageBase extends StatefulWidget {
  const PageBase({super.key, required this.title, required this.body, this.bottomNavigationBar});

  final String title;
  final Widget body;
  final Widget? bottomNavigationBar;
}

abstract class PageBaseState<TPageBase extends PageBase> extends State<TPageBase> {
  final scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<AppModel>().streamController.stream.listen((serialPortError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(serialPortError.message), duration: const Duration(seconds: 10)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, boxConstraints) {
      if (boxConstraints.maxWidth > 600) {
        return Row(
          children: [
            const AppNavigationRail(),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(widget.title),
                ),
                body: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(padding: const EdgeInsets.all(16.0), child: widget.body),
                  ),
                ),
                bottomNavigationBar: widget.bottomNavigationBar,
              ),
            ),
          ],
        );
      } else {
        return const Text('small...');
      }
    });
  }
}
