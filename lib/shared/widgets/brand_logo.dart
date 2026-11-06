import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_assets.dart';

enum LogoVariant {
  fullHorizontal,
  markOnly,
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = LogoVariant.fullHorizontal,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.useSvg = true,
  });

  final LogoVariant variant;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool useSvg;

  String get _svgAsset {
    switch (variant) {
      case LogoVariant.fullHorizontal:
        return AppAssets.logoSvg;
      case LogoVariant.markOnly:
        return AppAssets.markSvg;
    }
  }

  String get _pngAsset {
    switch (variant) {
      case LogoVariant.fullHorizontal:
        return AppAssets.logoPng;
      case LogoVariant.markOnly:
        return AppAssets.markPng;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!useSvg) {
      return Image.asset(
        _pngAsset,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return SvgPicture.asset(
      _svgAsset,
      width: width,
      height: height,
      fit: fit,
      placeholderBuilder: (BuildContext context) {
        return Image.asset(
          _pngAsset,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}

