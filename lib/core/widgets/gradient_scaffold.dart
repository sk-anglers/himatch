import 'package:flutter/material.dart';
import 'package:himatch/core/theme/app_colors_extension.dart';

/// A [Scaffold] wrapped in a gradient background container.
///
/// Automatically picks gradient colors from the current theme's
/// [AppColorsExtension]. The Scaffold itself has a transparent background
/// so the gradient shows through.
class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool extendBody;

  const GradientScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.gradientStart,
            colors.gradientMiddle,
            colors.gradientEnd,
          ],
        ),
      ),
      child: Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        extendBody: extendBody,
      ),
    );
  }
}
