import 'package:flutter/material.dart';

import '../../../../foundation/constants/colors.dart';
import 'circular_container.dart';
import '../curved_container/curved_edges_widget.dart';

class TPrimaryHeaderContainer extends StatelessWidget {
  const TPrimaryHeaderContainer({
    super.key,
    required this.child
  });

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return TCurvedEdgeWidget(
      child: Container(
        color: TColors.primary,
        child: Stack(
          children: [
            Positioned(top: -180, right: -250,child: TCircularContainer(backgroundColor: TColors.white.withOpacity(0.1))),
            Positioned(top: 60, right: -300,child: TCircularContainer(backgroundColor: TColors.white.withAlpha((0.1 * 255).round()),)),
            child,
          ],
        ),
      ),
    );
  }
}