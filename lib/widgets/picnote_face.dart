import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PicnoteFace extends StatelessWidget {
  final double size;

  const PicnoteFace({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/cute-face.svg',
      width: size,
    );
  }
}
