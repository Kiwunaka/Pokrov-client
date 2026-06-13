import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('android manifest declares special-use foreground service permission',
      () async {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    expect(await manifest.exists(), isTrue);

    final content = await manifest.readAsString();
    expect(
      content,
      contains('android.permission.FOREGROUND_SERVICE_SPECIAL_USE'),
    );
    expect(
      content,
      contains('android:foregroundServiceType="specialUse"'),
    );
  });

  test('android runtime service source hardens foreground start failures',
      () async {
    final serviceSource = File(
      'android/app/src/main/kotlin/space/pokrov/pokrov_android_shell/PokrovRuntimeVpnService.kt',
    );
    expect(await serviceSource.exists(), isTrue);

    final content = await serviceSource.readAsString();
    expect(content, contains('FOREGROUND_SERVICE_TYPE_SPECIAL_USE'));
    expect(content, contains('Android runtime foreground start failed:'));
  });

  test('android community QR scanner declares camera permission and app wiring',
      () async {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    final mainSource = File('lib/main.dart');
    final scannerSource = File('lib/community_qr_scanner.dart');

    expect(await manifest.exists(), isTrue);
    expect(await mainSource.exists(), isTrue);
    expect(await scannerSource.exists(), isTrue);

    expect(
        await manifest.readAsString(), contains('android.permission.CAMERA'));
    expect(await mainSource.readAsString(), contains('scanCommunityQr'));
    expect(await scannerSource.readAsString(), contains('MobileScanner'));
  });

  test('android open-source host defaults to neutral brand placeholders',
      () async {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    final buildGradle = File('android/app/build.gradle');
    final serviceSource = File(
      'android/app/src/main/kotlin/space/pokrov/pokrov_android_shell/PokrovRuntimeVpnService.kt',
    );
    final runtimeStateSource = File(
      'android/app/src/main/kotlin/space/pokrov/pokrov_android_shell/AndroidRuntimeState.kt',
    );
    final runtimeBootstrapSource = File(
      '../../packages/app_shell/lib/app_first_runtime_bootstrap.dart',
    );

    final manifestContent = await manifest.readAsString();
    final buildContent = await buildGradle.readAsString();
    final serviceContent = await serviceSource.readAsString();
    final runtimeStateContent = await runtimeStateSource.readAsString();
    final runtimeBootstrapContent = await runtimeBootstrapSource.readAsString();

    expect(manifestContent, contains(r'android:label="${openClientAppLabel}"'));
    expect(manifestContent, isNot(contains('android:label="POKROV"')));
    expect(
      manifestContent,
      contains(r'android:value="${openClientRuntimeVpnSubtype}"'),
    );
    expect(buildContent, contains('"org.pokrovclient.community"'));
    expect(buildContent, contains('"Open Client"'));
    expect(buildContent, contains('manifestPlaceholders +='));
    expect(buildContent, isNot(contains('applicationId = "space.pokrov')));
    expect(
        runtimeBootstrapContent, contains('OPEN_CLIENT_ANDROID_PACKAGE_NAME'));
    expect(runtimeBootstrapContent, contains('org.pokrovclient.community'));
    expect(serviceContent, contains('NativeBranding.message'));
    expect(runtimeStateContent, contains('NativeBranding.message'));
  });
}
