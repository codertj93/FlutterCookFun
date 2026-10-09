import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cook/design_system/cook_tokens.dart';
import 'package:get/get.dart';

/// 单个 Tab 的展示数据。
@immutable
class CookTabItemData {
  /// 创建 Tab 展示数据。
  ///
  /// 参数：
  /// - [labelKey]: 语言包中的标题 key。
  /// - [iconPath]: 未选中态图标资源路径。
  /// - [activeIconPath]: 选中态图标资源路径。
  /// - [iconSize]: 图标边长。
  const CookTabItemData({
    required this.labelKey,
    required this.iconPath,
    required this.activeIconPath,
    required this.iconSize,
  });

  /// 语言包中的标题 key。
  final String labelKey;

  /// 未选中态图标资源路径。
  final String iconPath;

  /// 选中态图标资源路径。
  final String activeIconPath;

  /// 图标边长。
  final double iconSize;
}

/// CookFun V6 浮动 TabBar，按 iOS 26 浮动 TabBar 的几何与交互规范实现。
///
/// 对齐要点：
/// - 图标与文字**始终同时展示**，不随滚动隐去文字（iOS 原生常态）；
/// - 支持按住后横向拖动跨项选中，滑过时给出高亮与轻触觉反馈；
/// - 触摸时玻璃整体回弹，替代 Material 波纹这类非 iOS 反馈；
/// - 玻璃表面保持高透明度，可读性交由背景模糊与滚动边缘淡出承担。
class CookFloatingTabBar extends StatefulWidget {
  /// 选中胶囊位移时长。
  static const Duration _selectionDuration = Duration(milliseconds: 280);

  /// 按压反馈时长。
  static const Duration _pressDuration = Duration(milliseconds: 140);

  /// 镜面高光描边宽度。
  static const double _rimWidth = 0.8;

  /// 玻璃表面与内容之间的内边距。
  static const double _contentPadding = 5;

  /// 选中胶囊的水平内缩距离。
  static const double _selectionHorizontalInset = 3;

  /// 选中胶囊的垂直内缩距离。
  ///
  /// 依据 iOS 26 原生 TabBar 实测比例：胶囊高度约占栏位的 0.78，几乎贴住玻璃边缘。
  static const double _selectionVerticalInset = 3;

  /// 创建浮动 TabBar。
  ///
  /// 参数：
  /// - [items]: Tab 展示数据，顺序即索引顺序。
  /// - [currentIndex]: 当前选中的 Tab 索引。
  /// - [onTap]: Tab 选中回调，回传目标索引（点击与拖动选中都会触发）。
  const CookFloatingTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  }) : assert(items.length > 0, '浮动 TabBar 至少需要一个 Tab');

  /// Tab 展示数据。
  final List<CookTabItemData> items;

  /// 当前选中的 Tab 索引。
  final int currentIndex;

  /// Tab 选中回调。
  final ValueChanged<int> onTap;

  @override
  State<CookFloatingTabBar> createState() => _CookFloatingTabBarState();
}

class _CookFloatingTabBarState extends State<CookFloatingTabBar> {
  /// 拖动过程中手指所在的高亮项；为 null 表示当前没有拖动。
  int? _previewIndex;

  /// 拖动过程中选中胶囊的左边缘（内容区坐标）；为 null 表示未拖动。
  ///
  /// 用 ValueNotifier 承载：拖动时每帧都会更新胶囊位置，
  /// 只重建胶囊本身即可，避免整行 Tab 跟着重建。
  final ValueNotifier<double?> _draggingPillLeft = ValueNotifier<double?>(null);

  @override
  void dispose() {
    _draggingPillLeft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Duration selectionDuration =
        reduceMotion ? Duration.zero : CookFloatingTabBar._selectionDuration;

    return Center(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // iOS 26 浮动栏宽度由项数决定并居中：先按项数推导，再受屏幕左右安全边距约束。
          final double intrinsicWidth =
              widget.items.length * CookTokens.tabBarItemWidth +
                  CookTokens.tabBarInlinePadding;
          final double width = math.min(
            math.max(0, constraints.maxWidth - CookTokens.pagePadding * 2),
            math.min(intrinsicWidth, CookTokens.tabBarMaxWidth),
          );

          return SizedBox(
            width: width,
            height: CookTokens.tabBarHeight,
            child: _GlassBarSurface(
              borderRadius: CookTokens.navigationRadius,
              child: Padding(
                padding: const EdgeInsets.all(
                  CookFloatingTabBar._contentPadding,
                ),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints inner) {
                    final double itemWidth =
                        inner.maxWidth / widget.items.length;

                    return Stack(
                      children: <Widget>[
                        ValueListenableBuilder<double?>(
                          valueListenable: _draggingPillLeft,
                          builder: (
                            BuildContext context,
                            double? draggingLeft,
                            Widget? child,
                          ) {
                            return AnimatedPositioned(
                              // 拖动期间胶囊直接跟手（不补间），松手后再补间回落到选中项。
                              duration: draggingLeft == null
                                  ? selectionDuration
                                  : Duration.zero,
                              curve: Curves.easeOutCubic,
                              left: draggingLeft ??
                                  itemWidth * widget.currentIndex +
                                      CookFloatingTabBar
                                          ._selectionHorizontalInset,
                              top: CookFloatingTabBar._selectionVerticalInset,
                              bottom:
                                  CookFloatingTabBar._selectionVerticalInset,
                              width: itemWidth -
                                  CookFloatingTabBar._selectionHorizontalInset *
                                      2,
                              child: child!,
                            );
                          },
                          child: DecoratedBox(
                            key: const ValueKey<String>(
                              'cook_tab_selection_pill',
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                CookTokens.pillRadius,
                              ),
                            ),
                          ),
                        ),
                        _buildDragSelectableItems(itemWidth, inner.maxWidth),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建可按住拖动选中的 Tab 行。
  ///
  /// 参数：
  /// - [itemWidth]: 单个 Tab 的宽度，用于把手指横坐标换算成索引。
  /// - [trackWidth]: Tab 行总宽度，用于把胶囊限制在行内。
  ///
  /// 返回：承载横向拖动识别的 Tab 行。
  Widget _buildDragSelectableItems(double itemWidth, double trackWidth) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (DragStartDetails details) {
        _trackDrag(details.localPosition.dx, itemWidth, trackWidth);
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        _trackDrag(details.localPosition.dx, itemWidth, trackWidth);
      },
      onHorizontalDragEnd: (_) => _commitPreview(),
      onHorizontalDragCancel: _clearPreview,
      child: Row(
        children: <Widget>[
          for (int index = 0; index < widget.items.length; index++)
            Expanded(
              child: _CookTabButton(
                key: ValueKey<String>('cook_tab_$index'),
                item: widget.items[index],
                selected: index == widget.currentIndex,
                dragHighlighted: _previewIndex == index,
                pressDuration: reduceMotion
                    ? Duration.zero
                    : CookFloatingTabBar._pressDuration,
                onTap: () => widget.onTap(index),
              ),
            ),
        ],
      ),
    );
  }

  void _trackDrag(double localDx, double itemWidth, double trackWidth) {
    if (itemWidth <= 0) {
      return;
    }

    // 胶囊跟随手指：以手指作为胶囊中心，并限制在 Tab 行内，避免滑出玻璃表面。
    final double halfPillWidth =
        (itemWidth - CookFloatingTabBar._selectionHorizontalInset * 2) / 2;
    _draggingPillLeft.value = (localDx - halfPillWidth).clamp(
      CookFloatingTabBar._selectionHorizontalInset,
      trackWidth -
          itemWidth +
          CookFloatingTabBar._selectionHorizontalInset,
    );

    final int index =
        (localDx / itemWidth).floor().clamp(0, widget.items.length - 1);
    if (_previewIndex == index) {
      return;
    }
    // 与 iOS 一致：手指滑过每一项时给出一次轻触觉反馈，让滑动有"刻度感"。
    HapticFeedback.selectionClick();
    setState(() => _previewIndex = index);
  }

  void _commitPreview() {
    final int? previewIndex = _previewIndex;
    _clearPreview();
    if (previewIndex == null || previewIndex == widget.currentIndex) {
      return;
    }
    widget.onTap(previewIndex);
  }

  void _clearPreview() {
    if (_previewIndex == null && _draggingPillLeft.value == null) {
      return;
    }
    _draggingPillLeft.value = null;
    setState(() => _previewIndex = null);
  }
}

/// 浮动 TabBar 的玻璃容器。
///
/// 由下到上依次是：半透明填充与投影、背景模糊、镜面高光描边、内容。
/// 描边与高光作为独立覆盖层绘制，不参与尺寸计算，避免内缩改变选中胶囊的几何。
class _GlassBarSurface extends StatelessWidget {
  const _GlassBarSurface({
    required this.borderRadius,
    required this.child,
  });

  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    final Color fill =
        (isDark ? theme.colorScheme.surface : Colors.white).withValues(
      alpha: isDark
          ? CookTokens.tabBarGlassFillOpacityDark
          : CookTokens.tabBarGlassFillOpacity,
    );

    return Stack(
      // 投影绘制在容器边界之外，必须关闭裁剪才能保留。
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            key: const ValueKey<String>('cook_floating_tab_bar'),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              // iOS 26 浮动栏的投影非常克制，过重会明显偏离原生观感。
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: CookTokens.tabBarGlassBlur,
                  sigmaY: CookTokens.tabBarGlassBlur,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        // 镜面高光描边：让玻璃边缘在深色内容上仍可辨识，模拟 Liquid Glass 的边缘折射。
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.58),
                  width: CookFloatingTabBar._rimWidth,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// 单个 Tab 按钮，负责按压反馈、拖动高亮、触觉反馈与图标文字展示。
class _CookTabButton extends StatefulWidget {
  const _CookTabButton({
    super.key,
    required this.item,
    required this.selected,
    required this.dragHighlighted,
    required this.pressDuration,
    required this.onTap,
  });

  final CookTabItemData item;
  final bool selected;

  /// 拖动滑过该项：图标与文字临时切换为选中配色，与跟手的选中胶囊保持一致。
  final bool dragHighlighted;
  final Duration pressDuration;
  final VoidCallback onTap;

  @override
  State<_CookTabButton> createState() => _CookTabButtonState();
}

class _CookTabButtonState extends State<_CookTabButton> {
  /// 按压缩放比例，参考 iOS 玻璃控件的整体回弹反馈。
  static const double _pressedScale = 0.92;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color selectedColor = theme.colorScheme.primary;
    final Color unselectedColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.66 : 0.58,
    );
    final bool highlighted = widget.selected || widget.dragHighlighted;
    final Color iconColor = highlighted ? selectedColor : unselectedColor;

    return Semantics(
      selected: widget.selected,
      button: true,
      label: widget.item.labelKey.tr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          // 与 iOS 系统 TabBar 一致：切换 Tab 时给出一次轻触觉反馈。
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        // 撑满整格，保证热区不小于 iOS 建议的最小触摸目标（44pt）。
        child: SizedBox.expand(
          child: AnimatedScale(
            scale: _pressed ? _pressedScale : 1,
            duration: widget.pressDuration,
            curve: Curves.easeOut,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Image.asset(
                      highlighted
                          ? widget.item.activeIconPath
                          : widget.item.iconPath,
                      width: widget.item.iconSize,
                      height: widget.item.iconSize,
                      color: iconColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.item.labelKey.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 10.5,
                          fontWeight:
                              highlighted ? FontWeight.w600 : FontWeight.w400,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }
}
