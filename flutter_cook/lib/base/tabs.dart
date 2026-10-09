import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_cook/base/controller/tab_navigation_controller.dart';
import 'package:flutter_cook/base/widgets/cook_floating_tab_bar.dart';
import 'package:flutter_cook/design_system/cook_assets.dart';
import 'package:flutter_cook/design_system/cook_tokens.dart';
import 'package:get/get.dart';

import '../module/home/home_data_page.dart';
import '../module/cook/cook_home_page.dart';
import '../module/book/book_home_page.dart';
import '../module/mine/mine_page.dart';

class Tabs extends StatefulWidget {
  final int index;
  final List<Widget>? pages;

  const Tabs({
    super.key,
    this.index = 0,
    this.pages,
  }) : assert(pages == null || pages.length == 4);

  @override
  State<Tabs> createState() => _TabsState();

  static int resolveInitialIndex({
    required int widgetIndex,
    required Object? routeArguments,
    required int pageCount,
  }) {
    final requestedIndex = routeArguments is int ? routeArguments : widgetIndex;
    if (requestedIndex < 0 || requestedIndex >= pageCount) {
      return widgetIndex.clamp(0, pageCount - 1);
    }
    return requestedIndex;
  }
}

class _TabsState extends State<Tabs> {
  static const double _tabIconSize = 24;
  static const List<CookTabItemData> _tabItems = [
    CookTabItemData(
      labelKey: 'tab_home_title',
      iconPath: CookAssets.tabHome,
      activeIconPath: CookAssets.tabHomeActive,
      iconSize: _tabIconSize,
    ),
    CookTabItemData(
      labelKey: 'tab_cook_title',
      iconPath: CookAssets.tabCook,
      activeIconPath: CookAssets.tabCookActive,
      iconSize: _tabIconSize,
    ),
    CookTabItemData(
      labelKey: 'tab_book_title',
      iconPath: CookAssets.tabRecipe,
      activeIconPath: CookAssets.tabRecipeActive,
      iconSize: _tabIconSize,
    ),
    CookTabItemData(
      labelKey: 'tab_mine_title',
      iconPath: CookAssets.tabMine,
      activeIconPath: CookAssets.tabMineActive,
      iconSize: _tabIconSize,
    ),
  ];

  late final TabNavigationController _navigationController;

  bool _didPrecacheTabIcons = false;

  late final List<Widget> _pages = widget.pages ??
      [
        const HomePage(),
        const CookPage(),
        const BookPage(),
        const MinePage(),
      ];

  @override
  void initState() {
    super.initState();

    _navigationController = Get.isRegistered<TabNavigationController>()
        ? Get.find<TabNavigationController>()
        : Get.put(TabNavigationController());
    final initialIndex = Tabs.resolveInitialIndex(
      widgetIndex: widget.index,
      routeArguments: Get.arguments,
      pageCount: _tabItems.length,
    );
    if (Get.arguments is int ||
        widget.index != TabNavigationController.homeIndex) {
      _navigationController.select(initialIndex);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheTabIcons) {
      return;
    }
    _didPrecacheTabIcons = true;
    for (final item in _tabItems) {
      precacheImage(AssetImage(item.iconPath), context);
      precacheImage(AssetImage(item.activeIconPath), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _buildScaffold(
        context,
        _navigationController.currentIndex.value,
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, int currentIndex) {
    // iOS 26 浮动 TabBar 不贴底：标准 App 实测约 20pt，且完整位于 Home Indicator 之上。
    // iOS 无 Home Indicator 时（如外接键盘场景）安全区为 0，此时使用同一常量保证间距一致。
    final double bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final double floatingBottom = math.max(
      CookTokens.tabBarBottomInset,
      bottomSafeArea * CookTokens.tabBarBottomInsetRatio,
    );
    // 滚动内容的内边距使用标称底边间距，避免栏位随设备安全区浮动时页面留白跟着抖动。
    const double scrollBottomInset =
        CookTokens.tabBarHeight + CookTokens.tabBarBottomInset + 12;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _IOS26TabContentInset(
            bottomInset: scrollBottomInset,
            child: _buildIndexedPages(currentIndex),
          ),
          // iOS 26 的滚动边缘效果：内容在导航栏下方柔和淡出，替代在导航栏内部叠加加深背景。
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: _TabBarScrollEdgeFade(
                height: floatingBottom +
                    CookTokens.tabBarHeight +
                    CookTokens.tabBarScrollEdgeHeight,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: floatingBottom,
            child: CookFloatingTabBar(
              items: _tabItems,
              currentIndex: currentIndex,
              onTap: _handleTabTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexedPages(int currentIndex) {
    return IndexedStack(
      index: currentIndex,
      children: _pages,
    );
  }

  void _handleTabTap(int index) {
    _navigationController.select(index);
  }
}

class _IOS26TabContentInset extends StatelessWidget {
  final double bottomInset;
  final Widget child;

  const _IOS26TabContentInset({
    required this.bottomInset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final currentPadding = mediaQuery.padding;
    final currentViewPadding = mediaQuery.viewPadding;
    final effectiveBottomPadding = currentPadding.bottom > bottomInset
        ? currentPadding.bottom
        : bottomInset;
    final effectiveBottomViewPadding = currentViewPadding.bottom > bottomInset
        ? currentViewPadding.bottom
        : bottomInset;

    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: currentPadding.copyWith(bottom: effectiveBottomPadding),
        viewPadding:
            currentViewPadding.copyWith(bottom: effectiveBottomViewPadding),
      ),
      child: child,
    );
  }
}

/// 浮动 TabBar 下方的滚动边缘淡出层。
///
/// iOS 26 新设计中导航栏不再依赖不透明背景保证可读性，而是由系统在滚动边缘提供
/// 柔和的模糊与淡出；Flutter 侧用页面底色的渐变近似该效果，内容滚到底部时自然淡出。
class _TabBarScrollEdgeFade extends StatelessWidget {
  final double height;

  const _TabBarScrollEdgeFade({required this.height});

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Theme.of(context).scaffoldBackgroundColor;

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              baseColor.withValues(alpha: 0),
              baseColor.withValues(alpha: 0.55),
              baseColor.withValues(alpha: 0.92),
            ],
            stops: const <double>[0, 0.55, 1],
          ),
        ),
      ),
    );
  }
}
