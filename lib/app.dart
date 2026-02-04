import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'HomePage.dart';
import 'foundation/constants/colors.dart';
import 'foundation/helpers/helper_functions.dart';
import 'foundation/theme/app_theme.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: TAppTheme.lightTheme,
        darkTheme: TAppTheme.darkTheme,

        builder: (context, child) {
          final bool dark=THelperFunctions.isDarkMode(context);
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  dark
                      ? TColors.darkGradientBackgroundStart
                      : TColors.lightGradientBackgroundStart,
                  dark
                      ? TColors.darkGradientBackgroundEnd
                      : TColors.lightGradientBackgroundEnd
                ],
                center: Alignment.center,
                radius: 1.0,
              ),
            ),
            child: child,
          );
        },
        home: HomePage()
    );
  }
}
