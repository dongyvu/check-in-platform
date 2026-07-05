import 'package:flutter/material.dart';
import 'package:sign/shared/ui/responsive_layout.dart';

class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帮助与反馈')),
      body: const MaxWidthContainer(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('如果软件对你有帮助，麻烦帮我在Github点个star谢谢喵~'),
        ),
      ),
    );
  }
}
