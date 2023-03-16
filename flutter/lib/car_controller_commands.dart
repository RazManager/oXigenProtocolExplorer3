import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_model.dart';
import 'page_base.dart';

class CarControllerCommands extends StatefulWidget {
  const CarControllerCommands({super.key});

  @override
  State<CarControllerCommands> createState() => _CarControllerCommandsState();
}

class _CarControllerCommandsState extends State<CarControllerCommands> {
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
              child: Consumer<AppModel>(builder: (context, model, child) {
                if (model.rxControllerCarPairs.where((x) => x != null).isEmpty) {
                  return const Text('empty');
                } else {
                  return DefaultTabController(
                      //initialIndex: 1,
                      length: model.rxControllerCarPairs.where((x) => x != null).length,
                      child: Scaffold(
                        appBar: AppBar(
                          title: const Text('Car/controller commands'),
                          bottom: TabBar(
                            tabs: model.rxControllerCarPairs
                                .where((x) => x != null)
                                .map((x) => Tab(text: 'Id ${x!.id.toString()}'))
                                .toList(),
                          ),
                        ),
                        body: TabBarView(
                            children: model.rxControllerCarPairs
                                .where((x) => x != null)
                                .map((e) => const Text("It's cloudy here"))
                                .toList()),
                      ));
                }
              }),
            )
          ],
        );
      } else {
        return const Text('small...');
      }
    });
  }
}
