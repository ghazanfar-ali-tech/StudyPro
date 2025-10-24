import 'package:flutter/widgets.dart';

class SizeConfig {
 
  double scaleHeight(double size, BuildContext context) {
    double baseHeight = 812;
    double screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * (size / baseHeight);
  }

  double scaleWidth(double size, BuildContext context) {
    double baseWidth = 375;
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * (size / baseWidth);
  }
}
