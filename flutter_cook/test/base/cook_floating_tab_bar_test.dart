import 'package:flutter/material.dart';
import 'package:flutter_cook/base/widgets/cook_floating_tab_bar.dart';
import 'package:flutter_cook/design_system/cook_assets.dart';
import 'package:flutter_cook/design_system/cook_theme.dart';
import 'package:flutter_cook/design_system/cook_tokens.dart';
import 'package:flutter_cook/utils/language/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const List<CookTabItemData> _items = <CookTabItemData>[
  CookTabItemData(
    labelKey: 'tab_home_title',
    iconPath: CookAssets.tabHome,
    activeIconPath: CookAssets.tabHomeActive,
    iconSize: 24,
  ),
  CookTabItemData(
    labelKey: 'tab_cook_title',
    iconPath: CookAssets.tabCook,
    activeIconPath: CookAssets.tabCookActive,
    iconSize: 24,
  ),
  CookTabItemData(
    labelKey: 'tab_book_title',
    iconPath: CookAssets.tabRecipe,
    activeIconPath: CookAssets.tabRecipeActive,
    iconSize: 24,
  ),
  CookTabItemData(
    labelKey: 'tab_mine_title',
    iconPath: CookAssets.tabMine,
    activeIconPath: CookAssets.tabMineActive,
    iconSize: 24,
  ),
];

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('保持 iOS 26 几何尺寸且图标与文字始终同时展示', (tester) async {
    await _pumpBar(tester);

    expect(
      tester
          .getSize(find.byKey(const ValueKey('cook_floating_tab_bar')))
          .height,
      CookTokens.tabBarHeight,
    );
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('烹饪'), findsOneWidget);
    expect(find.text('菜谱'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('点击 Tab 回传索引', (tester) async {
    final List<int> taps = <int>[];
    await _pumpBar(tester, onTap: taps.add);

    await tester.tap(find.byKey(const ValueKey('cook_tab_2')));
    await tester.pumpAndSettle();

    expect(taps, <int>[2]);
  });

  testWidgets('按住横向拖动可跨项选中，松手才提交', (tester) async {
    final List<int> taps = <int>[];
    await _pumpBar(tester, onTap: taps.add);

    final Offset from =
        tester.getCenter(find.byKey(const ValueKey('cook_tab_0')));
    final Offset to =
        tester.getCenter(find.byKey(const ValueKey('cook_tab_2')));

    final TestGesture gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveTo(to);
    await tester.pump(const Duration(milliseconds: 20));

    // iOS 的滑动选中在手指滑过时只做高亮，选中项在抬手时才切换。
    expect(taps, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(taps, <int>[2]);
  });

  testWidgets('拖动过程中选中胶囊跟手滑动，松手后回落到选中项', (tester) async {
    final List<int> taps = <int>[];
    await _pumpBar(tester, onTap: taps.add);

    final Finder pill = find.byKey(const ValueKey('cook_tab_selection_pill'));
    final double pillStartLeft = tester.getTopLeft(pill).dx;
    final Offset item0 =
        tester.getCenter(find.byKey(const ValueKey('cook_tab_0')));
    final Offset item1 =
        tester.getCenter(find.byKey(const ValueKey('cook_tab_1')));

    final TestGesture gesture = await tester.startGesture(item0);
    await tester.pump(const Duration(milliseconds: 16));

    // 手指停在第一、二项之间：胶囊中心应贴着手指，而不是整格跳到第一或第二项。
    final Offset between = Offset(
      item0.dx + (item1.dx - item0.dx) * 0.35,
      item0.dy,
    );
    await gesture.moveTo(between);
    await tester.pump(const Duration(milliseconds: 16));

    final double pillCenterWhileDragging = tester.getCenter(pill).dx;
    expect(pillCenterWhileDragging, greaterThan(pillStartLeft + 8));
    expect((pillCenterWhileDragging - between.dx).abs(), lessThan(2));

    // 该位置仍落在第一项内，松手不应切换，胶囊回到第一项。
    await gesture.up();
    await tester.pumpAndSettle();

    expect(taps, isEmpty);
    expect(tester.getTopLeft(pill).dx, closeTo(pillStartLeft, 0.1));
  });

  testWidgets('拖到目标项松手后胶囊停在目标项位置', (tester) async {
    final List<int> taps = <int>[];
    await _pumpBar(tester, onTap: taps.add, stateful: true);

    final Offset item0 =
        tester.getCenter(find.byKey(const ValueKey('cook_tab_0')));
    final Offset item3 =
        tester.getCenter(find.byKey(const ValueKey('cook_tab_3')));

    final TestGesture gesture = await tester.startGesture(item0);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveTo(item3);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(taps, <int>[3]);
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('cook_tab_selection_pill')))
          .dx,
      closeTo(
          tester.getTopLeft(find.byKey(const ValueKey('cook_tab_3'))).dx + 3,
          0.1),
    );
  });

  testWidgets('拖动回到当前项时不触发切换', (tester) async {
    final List<int> taps = <int>[];
    await _pumpBar(tester, onTap: taps.add);

    final Offset from =
        tester.getCenter(find.byKey(const ValueKey('cook_tab_0')));

    final TestGesture gesture = await tester.startGesture(from);
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(taps, isEmpty);
  });

  testWidgets('窄屏 320dp 下保留左右安全边距且不溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpBar(tester);
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('cook_floating_tab_bar'))).width,
      320 - CookTokens.pagePadding * 2,
    );
  });

  testWidgets('关闭动画时渲染与交互不抛异常', (tester) async {
    final List<int> taps = <int>[];
    await _pumpBar(tester, onTap: taps.add, disableAnimations: true);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cook_tab_1')));
    await tester.pumpAndSettle();

    expect(taps, <int>[1]);
  });
}

Future<void> _pumpBar(
  WidgetTester tester, {
  bool disableAnimations = false,
  bool stateful = false,
  ValueChanged<int>? onTap,
}) async {
  final Widget bar = stateful
      ? _StatefulBarHost(onTap: onTap ?? (_) {})
      : CookFloatingTabBar(
          items: _items,
          currentIndex: 0,
          onTap: onTap ?? (_) {},
        );

  await tester.pumpWidget(
    GetMaterialApp(
      theme: CookTheme.light(),
      darkTheme: CookTheme.dark(),
      translations: Messages(),
      locale: const Locale('zh', 'CN'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: bar,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// 模拟真实 Tabs 的选中状态流转：点击后更新 currentIndex，用于校验胶囊落点。
class _StatefulBarHost extends StatefulWidget {
  const _StatefulBarHost({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  State<_StatefulBarHost> createState() => _StatefulBarHostState();
}

class _StatefulBarHostState extends State<_StatefulBarHost> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return CookFloatingTabBar(
      items: _items,
      currentIndex: _index,
      onTap: (int index) {
        widget.onTap(index);
        setState(() => _index = index);
      },
    );
  }
}
