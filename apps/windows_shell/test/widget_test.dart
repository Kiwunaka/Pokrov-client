import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokrov_app_shell/app_shell.dart';
import 'package:pokrov_core_domain/core_domain.dart';

void main() {
  testWidgets('windows shell boots the shared protection surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      PokrovSeedApp(
        appContext: buildSeedAppContext(hostPlatform: HostPlatform.windows),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Защита'), findsWidgets);
    expect(find.text('Open Client'), findsWidgets);
    expect(find.byKey(const ValueKey('desktop-shell')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('desktop-sidebar-expanded')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pokrov-brand-mark')), findsWidgets);
    expect(find.text('Ваш основной регион'), findsNothing);
    expect(find.text('Новости и уведомления'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);

    expect(find.text('Prime runtime'), findsNothing);
    expect(find.text('Stage local smoke profile'), findsNothing);
    expect(find.text('Connect now'), findsNothing);
    final connectAction = find.byKey(const ValueKey('primary-connect-action'));
    expect(connectAction, findsOneWidget);
    expect(find.text('Пока недоступно'), findsOneWidget);
  });
  test('windows community QR scanner has camera and zxing adapter states',
      () async {
    final mainSource = File('lib/main.dart');
    final scannerSource = File('lib/community_qr_scanner.dart');

    expect(await mainSource.exists(), isTrue);
    expect(await scannerSource.exists(), isTrue);

    final mainContent = await mainSource.readAsString();
    final scannerContent = await scannerSource.readAsString();

    expect(mainContent, contains('scanCommunityQr'));
    expect(scannerContent, contains('CameraController'));
    expect(scannerContent, contains('QRCodeReader'));
    expect(scannerContent, contains('No camera was found.'));
    expect(scannerContent, contains('No QR code was found in this frame.'));
  });

  test('windows native runner defaults to neutral open-source metadata',
      () async {
    final topLevelCmake = File('windows/CMakeLists.txt');
    final runnerCmake = File('windows/runner/CMakeLists.txt');
    final mainSource = File('windows/runner/main.cpp');
    final resourceSource = File('windows/runner/Runner.rc');

    final topLevelContent = await topLevelCmake.readAsString();
    final runnerContent = await runnerCmake.readAsString();
    final mainContent = await mainSource.readAsString();
    final resourceContent = await resourceSource.readAsString();

    expect(topLevelContent, contains('OPEN_CLIENT_WINDOWS_APP_NAME'));
    expect(topLevelContent, contains('project(open_client_windows'));
    expect(topLevelContent, contains('"Open Client"'));
    expect(topLevelContent, contains('"open_client_windows"'));
    expect(topLevelContent, contains('OPEN_CLIENT_RUNTIME_DIR'));
    expect(topLevelContent, isNot(contains('POKROV_RUNTIME_DIR')));
    expect(topLevelContent, isNot(contains('project(pokrov_windows_beta')));
    expect(runnerContent, contains('OC_WIN_PRODUCT_NAME'));
    expect(mainContent, contains('OC_WIN_APP_NAME'));
    expect(mainContent, isNot(contains('window.Create(L"POKROV"')));
    expect(resourceContent, contains('OC_WIN_COMPANY_NAME'));
    expect(resourceContent, contains('OC_WIN_PRODUCT_NAME'));
    expect(resourceContent, isNot(contains('"space.pokrov"')));
    expect(resourceContent, isNot(contains('"POKROV"')));
    expect(resourceContent, isNot(contains('"pokrov_windows_beta"')));
  });
}
