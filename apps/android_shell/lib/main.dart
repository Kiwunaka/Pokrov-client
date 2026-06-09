import 'package:flutter/widgets.dart';
import 'package:pokrov_app_shell/app_shell.dart';
import 'package:pokrov_core_domain/core_domain.dart';

import 'community_qr_scanner.dart';

void main() {
  final variantProfile = selectedClientVariantProfile();
  runApp(
    PokrovSeedApp(
      appContext: buildSeedAppContext(
        hostPlatform: HostPlatform.android,
        variantProfile: variantProfile,
      ),
      communityQrScanner: scanCommunityQr,
    ),
  );
}
