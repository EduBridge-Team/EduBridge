import 'package:edubridge_app/theme.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/widgets/dashboard_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('gradient keeps its physical direction and actions in $brightness', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(brightness: brightness),
        home: Directionality(textDirection: TextDirection.rtl, child: Scaffold(
          appBar: BrandAppBar(title: const Text('الدروس'), toolbarHeight: 74,
            actions: [IconButton(tooltip: 'الإشعارات', onPressed: () { taps++; },
              icon: const Icon(Icons.notifications_outlined))]),
        ))));
      final bar = tester.widget<BrandAppBar>(find.byType(BrandAppBar));
      expect(bar.preferredSize.height, BrandAppBar.standardToolbarHeight);
      expect(bar.foregroundColor, Colors.white);
      expect(bar.scrolledUnderElevation, 0);
      expect(bar.backgroundColor, AppColors.brandBlue);
      expect(bar.flexibleSpace, isA<BrandHeaderSurface>());
      final background = tester.widget<DecoratedBox>(find.descendant(
        of: find.byType(BrandHeaderSurface), matching: find.byType(DecoratedBox)).first);
      final gradient = (background.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.begin, Alignment.centerLeft);
      expect(gradient.end, Alignment.centerRight);
      expect(gradient.colors, [const Color(0xFF1EB7C4), const Color(0xFF1969C1)]);
      await tester.tap(find.byTooltip('الإشعارات'));
      expect(taps, 1);
    });
  }

  testWidgets('shared toolbar retains navigation and rounded shape', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
        builder: (_) => const Scaffold(appBar: JisrAppBar(title: 'تفاصيل')))),
        child: const Text('افتح'))))));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    final bar = tester.widget<BrandAppBar>(find.byType(BrandAppBar));
    expect(bar.preferredSize.height, BrandAppBar.standardToolbarHeight);
    expect(bar.shape, isA<RoundedRectangleBorder>());
    expect(bar.clipBehavior, Clip.antiAlias);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('افتح'), findsOneWidget);
    expect(find.text('تفاصيل'), findsNothing);
  });
  for (final brightness in Brightness.values) {
    testWidgets('parent branding and menu retain contrast and taps in $brightness', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var taps = 0;
      await tester.pumpWidget(MaterialApp(locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(brightness: brightness,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white)),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(top: 24),
            textScaler: TextScaler.linear(1.8)),
          child: Directionality(textDirection: TextDirection.rtl, child: child!)),
        home: Scaffold(appBar: BrandAppBar(
          leadingWidth: 72,
          leading: DashboardMenu(actions: [DashboardMenuAction(id: 'notifications',
            label: 'الإشعارات', icon: Icons.notifications_outlined,
            onSelected: () { taps++; })]),
          title: const SizedBox.shrink(),
          actions: [Padding(padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              child: Image.asset('assets/brand_logo.png', width: 136, height: 38,
                semanticLabel: 'EduBridge'))))],
        ))));
      await tester.pump();
      final bar = tester.widget<BrandAppBar>(find.byType(BrandAppBar));
      expect(bar.backgroundColor, AppColors.brandBlue);
      expect(bar.foregroundColor, Colors.white);
      expect(bar.preferredSize.height, BrandAppBar.standardToolbarHeight);
      final surface = find.byType(BrandHeaderSurface);
      expect(tester.getSize(surface).height, BrandAppBar.standardToolbarHeight + 24);
      final logo = find.byWidgetPredicate((widget) => widget is Image && widget.semanticLabel == 'EduBridge');
      expect(tester.getCenter(find.byTooltip('المزيد من الخيارات')).dx,
        greaterThan(tester.getCenter(logo).dx));
      await tester.tap(find.byTooltip('المزيد من الخيارات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الإشعارات'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('profile-sized header across legacy sizes $language $width at 2x', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final requested in [76.0, 92.0, 96.0, 100.0, 116.0, 180.0]) {
          var taps = 0;
          await tester.pumpWidget(MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24),
                textScaler: const TextScaler.linear(2)), child: child!),
            home: Scaffold(appBar: BrandAppBar(
              toolbarHeight: requested,
              leading: BackButton(onPressed: () => taps++),
              title: Text(language == 'ar' ? 'الملف الشخصي' : 'Profile'),
              actions: [IconButton(tooltip: 'refresh',
                onPressed: () => taps++, icon: const Icon(Icons.refresh))],
            )),
          ));
          await tester.pumpAndSettle();
          final expected = requested > BrandAppBar.standardToolbarHeight
              ? requested : BrandAppBar.standardToolbarHeight;
          final bar = tester.widget<BrandAppBar>(find.byType(BrandAppBar));
          expect(bar.preferredSize.height, expected);
          expect(tester.getSize(find.byType(BrandHeaderSurface)).width, width);
          expect(tester.getSize(find.byType(BrandHeaderSurface)).height, expected + 24);
          await tester.tap(find.byType(BackButton));
          await tester.tap(find.byTooltip('refresh'));
          expect(taps, 2);
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('toolbar controls share the bottom profile row $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2),
              padding: const EdgeInsets.only(top: 24)), child: child!),
          home: Scaffold(appBar: BrandAppBar(
            leading: BackButton(onPressed: () {}),
            title: Text(language == 'ar' ? 'درس' : 'Page', key: const ValueKey('bottom-title')),
            actions: [IconButton(tooltip: 'refresh-bottom', onPressed: () {}, icon: const Icon(Icons.refresh))],
          )),
        ));
        await tester.pumpAndSettle();
        final bottom = tester.getBottomLeft(find.byType(BrandHeaderSurface)).dy;
        for (final target in [find.byType(BackButton), find.byKey(const ValueKey('bottom-title')),
            find.byTooltip('refresh-bottom')]) {
          expect(tester.getCenter(target).dy, closeTo(bottom - 44, 1), reason: target.description);
          expect(target.hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
      testWidgets('body dashboard header shares size and bottom inset $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(home: Directionality(
          textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(body: Column(children: [BrandDashboardHeader(child: Row(children: [
            Expanded(child: Text(language == 'ar' ? 'الرئيسية' : 'Home')),
            IconButton(key: const ValueKey('dashboard-bottom-action'), onPressed: () {}, icon: const Icon(Icons.menu)),
          ]))])),
        )));
        await tester.pumpAndSettle();
        final surface = find.byType(BrandHeaderSurface);
        expect(tester.getSize(surface), Size(width, BrandAppBar.standardToolbarHeight));
        expect(tester.getBottomLeft(surface).dy - tester.getBottomLeft(find.byKey(const ValueKey('dashboard-bottom-action'))).dy,
            BrandAppBar.controlBottomInset);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('implicit drawer and end drawer actions remain available', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      appBar: BrandAppBar(title: const Text('Home')),
      drawer: const Drawer(child: Text('Main menu')),
      endDrawer: const Drawer(child: Text('End menu')),
    )));
    await tester.tap(find.byType(DrawerButton)); await tester.pumpAndSettle();
    expect(find.text('Main menu').hitTestable(), findsOneWidget);
    Navigator.of(tester.element(find.text('Main menu'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EndDrawerButton)); await tester.pumpAndSettle();
    expect(find.text('End menu').hitTestable(), findsOneWidget);
  });

}
