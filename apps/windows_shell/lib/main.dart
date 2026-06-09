import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:pokrov_app_shell/app_shell.dart';
import 'package:pokrov_core_domain/core_domain.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'community_qr_scanner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final variantProfile = selectedClientVariantProfile();
  await windowManager.ensureInitialized();
  await _PokrovWindowsTray.install(variantProfile);
  runApp(
    PokrovSeedApp(
      appContext: buildSeedAppContext(
        hostPlatform: HostPlatform.windows,
        variantProfile: variantProfile,
      ),
      communityQrScanner: scanCommunityQr,
    ),
  );
}

final class _PokrovWindowsTray with TrayListener {
  _PokrovWindowsTray._();

  static final _PokrovWindowsTray _instance = _PokrovWindowsTray._();

  static Future<void> install(ClientVariantProfile variantProfile) async {
    if (!Platform.isWindows) {
      return;
    }
    trayManager.addListener(_instance);
    await trayManager.setIcon('windows/runner/resources/app_icon.ico');
    await trayManager.setToolTip(variantProfile.displayName);
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(
            key: 'show_window',
            label: 'Open ${variantProfile.displayName}',
          ),
          MenuItem(
            key: 'support',
            label: 'Поддержка',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit_app',
            label: 'Выход',
          ),
        ],
      ),
    );
  }

  Future<void> _showWindow() async {
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_showWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
      case 'support':
        unawaited(_showWindow());
        break;
      case 'exit_app':
        unawaited(trayManager.destroy());
        unawaited(windowManager.destroy());
        break;
    }
  }
}
