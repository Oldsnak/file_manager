import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../foundation/constants/colors.dart';
import '../../../foundation/helpers/helper_functions.dart';

class HealthScoreMeter extends StatelessWidget {
  final double score; // 0–100

  const HealthScoreMeter({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);

    // ✔ Light & dark responsive colors
    final Color bgArcColor = dark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color tickColor = dark ? Colors.white70 : Colors.black87;
    final Color labelColor = dark ? Colors.white : Colors.black;

    return SizedBox(
      height: 250,   // ✔ prevents huge empty space
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 100,
            startAngle: 180,
            endAngle: 0,

            // ✔ Removes large unused space
            canScaleToFit: true,
            showTicks: true,
            showLabels: true,
            interval: 10,
            axisLabelStyle: GaugeTextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            majorTickStyle: MajorTickStyle(
              length: 8,
              thickness: 2,
              color: tickColor,
            ),

            // ✔ Background arc
            axisLineStyle: AxisLineStyle(
              thickness: 25,
              cornerStyle: CornerStyle.bothCurve,
              color: bgArcColor,
            ),

            // ✔ Dynamic ranges (auto light/dark)
            ranges: <GaugeRange>[
              GaugeRange(
                startValue: 0,
                endValue: 40,
                color: Colors.green.shade400,
                startWidth: 25,
                endWidth: 25,
              ),
              GaugeRange(
                startValue: 40,
                endValue: 60,
                color: Colors.yellow.shade700,
                startWidth: 25,
                endWidth: 25,
              ),
              GaugeRange(
                startValue: 60,
                endValue: 80,
                color: Colors.orange.shade600,
                startWidth: 25,
                endWidth: 25,
              ),
              GaugeRange(
                startValue: 80,
                endValue: 100,
                color: Colors.red.shade600,
                startWidth: 25,
                endWidth: 25,
              ),
            ],

            // ✔ Needle pointer
            pointers: <GaugePointer>[
              NeedlePointer(
                value: score,
                enableAnimation: true,
                animationDuration: 1200,
                needleColor: TColors.primary,

                // ✔ ONLY small circular tail — NOT rectangle
                tailStyle: TailStyle(
                  length: 0.15, // short tail
                  width: 6,  // circular width
                  color: TColors.primary,
                ),

                // ✔ Center knob circle
                knobStyle: KnobStyle(
                  color: TColors.buttonPrimary,
                  borderColor: dark ? TColors.darkContainer : TColors.buttonDisabled,
                  borderWidth: 0.01
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
