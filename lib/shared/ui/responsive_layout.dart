import 'package:flutter/material.dart';

/// 判断是否为宽屏（横屏/平板/PC）
bool isWideScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= 600;
}

class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class ResponsiveSplitView extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final Widget emptyDetail;
  final double masterWidth;

  const ResponsiveSplitView({
    super.key,
    required this.master,
    this.detail,
    this.emptyDetail = const Center(child: Text('请选择一项以查看详情')),
    this.masterWidth = 350,
  });

  @override
  Widget build(BuildContext context) {
    final wideScreen = isWideScreen(context);

    if (wideScreen) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final mw = (constraints.maxWidth * 0.35).clamp(280.0, 400.0);
          return Row(
            children: [
              SizedBox(width: mw, child: master),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: detail ?? emptyDetail),
            ],
          );
        },
      );
    } else {
      return master;
    }
  }
}
