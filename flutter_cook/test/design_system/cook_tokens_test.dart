import 'package:flutter/material.dart';
import 'package:flutter_cook/design_system/cook_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines V6 color responsibilities', () {
    expect(CookTokens.primary, const Color(0xFF13C89A));
    expect(CookTokens.primaryDeep, const Color(0xFF087C63));
    expect(CookTokens.danger, const Color(0xFFF05249));
    expect(CookTokens.warm, const Color(0xFFFF8A3D));
    expect(CookTokens.info, const Color(0xFF6B5BF5));
    expect(CookTokens.page, const Color(0xFFF7F6EE));
  });

  test('locks core control dimensions from V6 specs', () {
    expect(CookTokens.pagePadding, 20);
    expect(CookTokens.heroButtonHeight, 52);
    expect(CookTokens.contextButtonHeight, 44);
    expect(CookTokens.chipHeight, 36);
    expect(CookTokens.headerToolButtonSize, 44);
    expect(CookTokens.headerToolIconSize, 24);
    // 浮动 TabBar 几何对齐 iOS 26 系统实测值：高 67~68pt、左右各 20pt、距底约 20pt。
    expect(CookTokens.tabBarHeight, 68);
    expect(CookTokens.tabBarMaxWidth, 362);
    expect(CookTokens.tabBarBottomInset, 20);
    expect(CookTokens.tabBarBottomInsetRatio, 0.6);
    expect(CookTokens.tabBarItemWidth, 96);
    expect(CookTokens.tabBarGlassBlur, 30);
    expect(CookTokens.tabBarScrollEdgeHeight, 28);
    // 对齐原生玻璃的透明度：填充不能过实，否则会明显偏离系统材质观感。
    expect(CookTokens.tabBarGlassFillOpacity, lessThan(0.8));
    // 玻璃填充过薄会牺牲中文标签在照片背景上的可读性，这里锁定下限。
    expect(
      CookTokens.tabBarGlassFillOpacity,
      greaterThan(CookTokens.tabBarGlassFillOpacityDark),
    );
    expect(CookTokens.tabBarGlassFillOpacity, greaterThan(0.7));
    expect(CookTokens.radiusXs, 4);
    expect(CookTokens.radiusSm, 6);
    expect(CookTokens.radiusMd, 8);
    expect(CookTokens.heroCardRadius, 16);
    expect(CookTokens.cardRadius, 12);
    expect(CookTokens.listCardRadius, 10);
    expect(CookTokens.inputRadius, 10);
    expect(CookTokens.controlRadius, 10);
    expect(CookTokens.dialogRadius, 16);
    expect(CookTokens.navigationRadius, CookTokens.tabBarHeight / 2);
    expect(CookTokens.pillRadius, 999);
  });

  test('defines ingredient semantic colors', () {
    expect(CookTokens.vegetable, isA<Color>());
    expect(CookTokens.protein, isA<Color>());
    expect(CookTokens.staple, isA<Color>());
    expect(CookTokens.seasoning, isA<Color>());
    expect(
      {
        CookTokens.vegetable,
        CookTokens.protein,
        CookTokens.staple,
        CookTokens.seasoning,
      },
      hasLength(4),
    );
  });
}
