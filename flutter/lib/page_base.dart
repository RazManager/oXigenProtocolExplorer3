import 'package:flutter/material.dart';

abstract class PageBase extends StatefulWidget {
  const PageBase({super.key, required this.body});

  final Widget body;

  // @override
  // State<PageBase> createState() => _PageBaseState();
}

abstract class PageBaseState<TPageBase extends PageBase> extends State<TPageBase> {
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, boxConstraints) {
      if (boxConstraints.maxWidth > 100) {
        return Row(children: [
          const Text('menu...'),
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
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(color: Colors.red, width: double.infinity, child: widget.body)),
                ),
              ),
            ),
          ),
        ]);
      } else {
        return const Text('small...');
      }
    });
  }
}
