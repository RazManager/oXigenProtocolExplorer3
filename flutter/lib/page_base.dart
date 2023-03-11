import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'app_model.dart';
import 'controllers.dart';
import 'serial_port_demo.dart';
import 'settings.dart';

final router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsPage();
      },
    ),
    GoRoute(
      path: '/controllers',
      builder: (BuildContext context, GoRouterState state) {
        return const ControllersPage();
      },
    ),
    GoRoute(
      path: '/demo',
      builder: (BuildContext context, GoRouterState state) {
        return const DemoPage();
      },
    ),
  ],
);

abstract class PageBase extends StatefulWidget {
  const PageBase({super.key, required this.body});

  final Widget body;
}

abstract class PageBaseState<TPageBase extends PageBase> extends State<TPageBase> {
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, boxConstraints) {
      if (boxConstraints.maxWidth > 600) {
        var model = context.read<AppModel>();
        return Row(
          children: [
            NavigationRail(
              selectedIndex: model.menuIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (index) {
                model.menuIndex = index;
                switch (index) {
                  case 0:
                    context.go('/');
                    break;

                  case 1:
                    context.go('/controllers');
                    break;

                  case 2:
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
                  icon: Icon(Icons.speed_outlined),
                  selectedIcon: Icon(Icons.speed),
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
                  controller: scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(padding: const EdgeInsets.all(16.0), child: widget.body),
                    //child: Container(color: Colors.red, width: double.infinity, child: widget.body)),
                  ),
                ),
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
