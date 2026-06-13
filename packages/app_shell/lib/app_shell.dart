library pokrov_app_shell;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pokrov_core_domain/core_domain.dart';
import 'package:pokrov_platform_contracts/platform_contracts.dart';
import 'package:pokrov_runtime_engine/runtime_engine.dart';
import 'package:pokrov_support_context/support_context.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_first_runtime_bootstrap.dart';
import 'src/assistant/pokrov_ai_assistant.dart';
import 'src/design_system/design_system.dart';
import 'src/warp/pokrov_warp_lifecycle.dart';
export 'app_first_runtime_bootstrap.dart';
part 'app_shell_ui_helpers.dart';

enum SeedTab {
  protection,
  locations,
  rules,
  profile,
}

class _SelectSeedTabIntent extends Intent {
  const _SelectSeedTabIntent(this.tab);

  final SeedTab tab;
}

class _FocusSupportComposerIntent extends Intent {
  const _FocusSupportComposerIntent();
}

class _SendSupportMessageIntent extends Intent {
  const _SendSupportMessageIntent();
}

enum _SectionTone {
  accent,
  muted,
  neutral,
  reward,
}

enum _FirstLaunchStep {
  choice,
  restore,
  ready,
}

typedef ExternalHandoffLauncher = Future<bool> Function(Uri uri);
typedef CommunityQrScanner = Future<String?> Function(BuildContext context);

abstract class PokrovFirstLaunchStore {
  Future<bool> isCompleted();
  Future<void> markCompleted();
}

class PokrovFileFirstLaunchStore implements PokrovFirstLaunchStore {
  const PokrovFileFirstLaunchStore();

  static const _fileName = 'pokrov-first-launch-state.txt';
  static const _completedMarker = 'completed';

  Future<File> _stateFile() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<bool> isCompleted() async {
    final file = await _stateFile();
    if (!await file.exists()) {
      return false;
    }
    return (await file.readAsString()).trim() == _completedMarker;
  }

  @override
  Future<void> markCompleted() async {
    final file = await _stateFile();
    await file.writeAsString(_completedMarker, flush: true);
  }
}

abstract final class _SeedPalette {
  static const canvas = PokrovPalette.canvas;
  static const canvasAlt = PokrovPalette.canvasAlt;
  static const ink = PokrovPalette.ink;
  static const accent = PokrovPalette.accent;
  static const accentBright = PokrovPalette.accentBright;
  static const success = PokrovPalette.success;
  static const warning = PokrovPalette.warning;
  static const surface = PokrovPalette.surface;
  static const surfaceMuted = PokrovPalette.surfaceMuted;
  static const line = PokrovPalette.line;
  static const muted = PokrovPalette.muted;
}

const _openClientVariant = String.fromEnvironment(
  'OPEN_CLIENT_VARIANT',
  defaultValue: 'community',
);
const _openClientBrandName = String.fromEnvironment(
  'OPEN_CLIENT_BRAND_NAME',
  defaultValue: '',
);
const _openClientApiBaseUrl = String.fromEnvironment(
  'OPEN_CLIENT_API_BASE_URL',
  defaultValue: '',
);
const _openClientCheckoutUrl = String.fromEnvironment(
  'OPEN_CLIENT_CHECKOUT_URL',
  defaultValue: '',
);
const _openClientCabinetUrl = String.fromEnvironment(
  'OPEN_CLIENT_CABINET_URL',
  defaultValue: '',
);
const _openClientSupportUrl = String.fromEnvironment(
  'OPEN_CLIENT_SUPPORT_URL',
  defaultValue: '',
);
const _openClientPrivacyUrl = String.fromEnvironment(
  'OPEN_CLIENT_PRIVACY_URL',
  defaultValue: '',
);
const _openClientBrandAsset = String.fromEnvironment(
  'OPEN_CLIENT_BRAND_ASSET',
  defaultValue: '',
);
const _openClientOfficialBuild = bool.fromEnvironment(
  'OPEN_CLIENT_OFFICIAL_BUILD',
  defaultValue: false,
);
const _selectedAppsEnforcementReady = true;
const _pokrovAppVersion = '1.0.0-beta.2';
const _seedRulesetVersion = '2026-04-13';
const _seedPackageCatalogVersion = '2026-04-13';

abstract final class _MotionTokens {
  static const short = PokrovMotionTokens.short;
  static const standard = PokrovMotionTokens.standard;
  static const homeReveal = PokrovMotionTokens.homeReveal;
  static const ease = PokrovMotionTokens.ease;
}

class _MotionScope extends PokrovMotionScope {
  const _MotionScope({
    required super.child,
    required super.disableAnimations,
    super.key,
  });

  static PokrovMotionScope of(BuildContext context) {
    return PokrovMotionScope.of(context);
  }
}

const _apiBaseUrlOverride = String.fromEnvironment(
  'POKROV_API_BASE_URL',
  defaultValue: 'https://api.pokrov.space/',
);
const _checkoutUrlOverride = String.fromEnvironment(
  'POKROV_CHECKOUT_URL',
  defaultValue: 'https://pay.pokrov.space/checkout/?plan=1_month',
);
const _cabinetUrlOverride = String.fromEnvironment(
  'POKROV_CABINET_URL',
  defaultValue: 'https://app.pokrov.space/',
);

String _normalizeSeedUrl(String value, String fallback) {
  final candidate = value.trim();
  if (candidate.isEmpty) {
    return fallback;
  }
  return candidate.endsWith('/') ? candidate : '$candidate/';
}

class SeedAppContext {
  const SeedAppContext({
    required this.hostPlatform,
    required this.variantProfile,
    required this.accessLane,
    required this.scope,
    required this.runtimeProfile,
    required this.bootstrapContract,
    required this.supportSnapshot,
    required this.rulesPresetContract,
    required this.locations,
    required this.apiBaseUrl,
    required this.checkoutUrl,
    required this.cabinetUrl,
    required this.redeemHint,
    required this.managedProfileSeed,
  });

  final HostPlatform hostPlatform;
  final ClientVariantProfile variantProfile;
  final AccessLane accessLane;
  final ProgramScope scope;
  final RuntimeProfile runtimeProfile;
  final PlatformBootstrapContract bootstrapContract;
  final SupportSnapshot supportSnapshot;
  final RulesPresetContract rulesPresetContract;
  final List<LocationCluster> locations;
  final String apiBaseUrl;
  final String checkoutUrl;
  final String cabinetUrl;
  final String redeemHint;
  final ManagedProfilePayload managedProfileSeed;

  List<SeedTab> get defaultTabs => const [
        SeedTab.protection,
        SeedTab.locations,
        SeedTab.rules,
        SeedTab.profile,
      ];
}

class ClientVariantProfile {
  const ClientVariantProfile({
    required this.variant,
    required this.id,
    required this.displayName,
    required this.brandMarkAssetName,
    required this.apiBaseUrl,
    required this.checkoutUrl,
    required this.cabinetUrl,
    required this.supportBot,
    required this.feedbackBot,
    required this.publicChannel,
    required this.supportEmail,
    required this.supportUrl,
    required this.privacyPolicyUrl,
    required this.usesApiServices,
    required this.description,
  });

  final ProductVariant variant;
  final String id;
  final String displayName;
  final String brandMarkAssetName;
  final String apiBaseUrl;
  final String checkoutUrl;
  final String cabinetUrl;
  final String supportBot;
  final String feedbackBot;
  final String publicChannel;
  final String supportEmail;
  final String supportUrl;
  final String privacyPolicyUrl;
  final bool usesApiServices;
  final String description;

  String get fallbackMarkText =>
      displayName.trim().isEmpty ? 'O' : displayName.trim().substring(0, 1);

  bool get isCommunity => id == 'community';
  bool get isOperator => id == 'operator';
  bool get isOfficialPokrov => id == 'pokrov';
}

ClientVariantProfile selectedClientVariantProfile() {
  return buildClientVariantProfileFor(
    variant: _openClientVariant,
    brandName: _openClientBrandName,
    apiBaseUrl: _openClientApiBaseUrl,
    checkoutUrl: _openClientCheckoutUrl,
    cabinetUrl: _openClientCabinetUrl,
    supportUrl: _openClientSupportUrl,
    privacyPolicyUrl: _openClientPrivacyUrl,
    brandAsset: _openClientBrandAsset,
    officialBuild: _openClientOfficialBuild,
  );
}

ClientVariantProfile buildClientVariantProfileFor({
  String variant = 'community',
  String brandName = '',
  String apiBaseUrl = '',
  String checkoutUrl = '',
  String cabinetUrl = '',
  String supportUrl = '',
  String privacyPolicyUrl = '',
  String brandAsset = '',
  bool officialBuild = false,
}) {
  final productVariant = ProductVariantPresentation.parse(variant);
  switch (productVariant) {
    case ProductVariant.pokrov:
      if (!officialBuild) {
        throw StateError(
          'OPEN_CLIENT_OFFICIAL_BUILD=true is required for the pokrov variant.',
        );
      }
      final displayName =
          brandName.trim().isEmpty ? 'POKROV' : brandName.trim();
      final asset = brandAsset.trim().isEmpty
          ? PokrovBrandAssets.mark
          : brandAsset.trim();
      final normalizedApiBaseUrl = _normalizeSeedUrl(
        apiBaseUrl.trim().isEmpty ? _apiBaseUrlOverride : apiBaseUrl,
        'https://api.pokrov.space/',
      );
      final normalizedCabinetUrl = _normalizeSeedUrl(
        cabinetUrl.trim().isEmpty ? _cabinetUrlOverride : cabinetUrl,
        'https://app.pokrov.space/',
      );
      final normalizedCheckoutUrl = checkoutUrl.trim().isEmpty
          ? _checkoutUrlOverride
          : checkoutUrl.trim();
      final normalizedSupportUrl = supportUrl.trim().isEmpty
          ? 'https://pokrov.space/'
          : supportUrl.trim();
      final normalizedPrivacyUrl = privacyPolicyUrl.trim().isEmpty
          ? 'https://pokrov.space/privacy/'
          : privacyPolicyUrl.trim();
      _validatePokrovOfficialBoundary(
        displayName: displayName,
        brandAsset: asset,
        apiBaseUrl: normalizedApiBaseUrl,
        cabinetUrl: normalizedCabinetUrl,
        checkoutUrl: normalizedCheckoutUrl,
        supportUrl: normalizedSupportUrl,
        privacyPolicyUrl: normalizedPrivacyUrl,
      );
      return ClientVariantProfile(
        variant: ProductVariant.pokrov,
        id: ProductVariant.pokrov.id,
        displayName: displayName,
        brandMarkAssetName: asset,
        apiBaseUrl: normalizedApiBaseUrl,
        checkoutUrl: normalizedCheckoutUrl,
        cabinetUrl: normalizedCabinetUrl,
        supportBot: '@pokrov_supportbot',
        feedbackBot: '@pokrov_feedbackbot',
        publicChannel: '@pokrov_vpn',
        supportEmail: 'support@pokrov.space',
        supportUrl: normalizedSupportUrl,
        privacyPolicyUrl: normalizedPrivacyUrl,
        usesApiServices: true,
        description: 'Official POKROV service client mode.',
      );
    case ProductVariant.operator:
      final displayName =
          brandName.trim().isEmpty ? 'Operator Connect' : brandName.trim();
      final normalizedApiBaseUrl = _normalizeSeedUrl(apiBaseUrl, '');
      final normalizedCabinetUrl = _normalizeSeedUrl(cabinetUrl, '');
      final normalizedCheckoutUrl = checkoutUrl.trim();
      final normalizedSupportUrl = supportUrl.trim();
      final normalizedPrivacyUrl = privacyPolicyUrl.trim();
      _validateOperatorBoundary(
        displayName: displayName,
        brandAsset: brandAsset,
        apiBaseUrl: normalizedApiBaseUrl,
        cabinetUrl: normalizedCabinetUrl,
        checkoutUrl: normalizedCheckoutUrl,
        supportUrl: normalizedSupportUrl,
        privacyPolicyUrl: normalizedPrivacyUrl,
      );
      return ClientVariantProfile(
        variant: ProductVariant.operator,
        id: ProductVariant.operator.id,
        displayName: displayName,
        brandMarkAssetName: brandAsset.trim(),
        apiBaseUrl: normalizedApiBaseUrl,
        checkoutUrl: normalizedCheckoutUrl,
        cabinetUrl: normalizedCabinetUrl,
        supportBot: '',
        feedbackBot: '',
        publicChannel: '',
        supportEmail: 'support@example.invalid',
        supportUrl: normalizedSupportUrl,
        privacyPolicyUrl: normalizedPrivacyUrl,
        usesApiServices: true,
        description: 'White-label operator mode for a custom service backend.',
      );
    case ProductVariant.community:
      final displayName =
          brandName.trim().isEmpty ? 'Open Client' : brandName.trim();
      _validateCommunityBoundary(
        displayName: displayName,
        brandAsset: brandAsset,
        apiBaseUrl: apiBaseUrl,
        cabinetUrl: cabinetUrl,
        checkoutUrl: checkoutUrl,
        supportUrl: supportUrl,
        privacyPolicyUrl: privacyPolicyUrl,
      );
      return ClientVariantProfile(
        variant: ProductVariant.community,
        id: ProductVariant.community.id,
        displayName: displayName,
        brandMarkAssetName: brandAsset.trim(),
        apiBaseUrl: '',
        checkoutUrl: '',
        cabinetUrl: '',
        supportBot: '',
        feedbackBot: '',
        publicChannel: '',
        supportEmail: '',
        supportUrl: '',
        privacyPolicyUrl: '',
        usesApiServices: false,
        description:
            'Community client mode for local keys, subscriptions, and public catalogs.',
      );
  }
}

void _validateCommunityBoundary({
  required String displayName,
  required String brandAsset,
  required String apiBaseUrl,
  required String cabinetUrl,
  required String checkoutUrl,
  required String supportUrl,
  required String privacyPolicyUrl,
}) {
  if (_looksLikePokrovBrand(displayName) || _looksLikePokrovBrand(brandAsset)) {
    throw StateError(
      'The community variant must use neutral branding, not POKROV branding.',
    );
  }
  if (_usesPokrovEndpoint(apiBaseUrl) ||
      _usesPokrovEndpoint(cabinetUrl) ||
      _usesPokrovEndpoint(checkoutUrl) ||
      _usesPokrovEndpoint(supportUrl) ||
      _usesPokrovEndpoint(privacyPolicyUrl)) {
    throw StateError(
      'The community variant must not be configured with POKROV endpoints.',
    );
  }
}

void _validateOperatorBoundary({
  required String displayName,
  required String brandAsset,
  required String apiBaseUrl,
  required String cabinetUrl,
  required String checkoutUrl,
  required String supportUrl,
  required String privacyPolicyUrl,
}) {
  if (apiBaseUrl.trim().isEmpty) {
    throw StateError(
      'OPEN_CLIENT_API_BASE_URL is required for the operator variant.',
    );
  }
  if (privacyPolicyUrl.trim().isEmpty) {
    throw StateError(
      'OPEN_CLIENT_PRIVACY_URL is required for the operator variant.',
    );
  }
  if (_looksLikePokrovBrand(displayName) || _looksLikePokrovBrand(brandAsset)) {
    throw StateError(
      'The operator variant must use operator-owned branding by default.',
    );
  }
  if (_usesPokrovEndpoint(apiBaseUrl) ||
      _usesPokrovEndpoint(cabinetUrl) ||
      _usesPokrovEndpoint(checkoutUrl) ||
      _usesPokrovEndpoint(supportUrl) ||
      _usesPokrovEndpoint(privacyPolicyUrl)) {
    throw StateError(
      'The operator variant must not use official POKROV endpoints.',
    );
  }
}

void _validatePokrovOfficialBoundary({
  required String displayName,
  required String brandAsset,
  required String apiBaseUrl,
  required String cabinetUrl,
  required String checkoutUrl,
  required String supportUrl,
  required String privacyPolicyUrl,
}) {
  if (!_looksLikePokrovBrand(displayName) ||
      !_looksLikePokrovBrand(brandAsset)) {
    throw StateError(
      'The pokrov variant must keep official POKROV branding.',
    );
  }
  if (!_usesPokrovEndpoint(apiBaseUrl) ||
      !_usesPokrovEndpoint(cabinetUrl) ||
      !_usesPokrovEndpoint(checkoutUrl) ||
      !_usesPokrovEndpoint(supportUrl) ||
      !_usesPokrovEndpoint(privacyPolicyUrl)) {
    throw StateError(
      'The pokrov variant must use official POKROV endpoints.',
    );
  }
}

bool _looksLikePokrovBrand(String value) {
  return value.toLowerCase().contains('pokrov');
}

bool _usesPokrovEndpoint(String value) {
  final candidate = value.trim();
  if (candidate.isEmpty) {
    return false;
  }
  final uri = Uri.tryParse(candidate);
  final host = uri?.host.toLowerCase() ?? candidate.toLowerCase();
  return host == 'pokrov.space' || host.endsWith('.pokrov.space');
}

enum RulesPresetState {
  enabled,
  staged,
  locked,
}

class RulesPresetStatus {
  const RulesPresetStatus({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String id;
  final String title;
  final String subtitle;
  final RulesPresetState state;

  bool get enabled => state == RulesPresetState.enabled;
}

class RulesPresetContract {
  const RulesPresetContract({
    required this.rulesetVersion,
    required this.packageCatalogVersion,
    required this.presets,
  });

  final String rulesetVersion;
  final String packageCatalogVersion;
  final List<RulesPresetStatus> presets;

  int get enabledCount => presets
      .where((preset) => preset.state == RulesPresetState.enabled)
      .length;
}

String _brandText(String value, ClientVariantProfile profile) {
  return value.replaceAll('POKROV', profile.displayName);
}

String _brandTextForName(String value, String brandName) {
  return value.replaceAll('POKROV', brandName);
}

RulesPresetContract _seedRulesPresetContractFor(
  HostPlatform hostPlatform,
  ClientVariantProfile profile,
) {
  final brandName = profile.displayName;
  return switch (hostPlatform) {
    HostPlatform.windows => RulesPresetContract(
        rulesetVersion: _seedRulesetVersion,
        packageCatalogVersion: _seedPackageCatalogVersion,
        presets: [
          RulesPresetStatus(
            id: 'ru-region',
            title: 'Российские сервисы',
            subtitle:
                'Российские сайты, локальные адреса и нужные RU-сервисы идут напрямую.',
            state: RulesPresetState.enabled,
          ),
          RulesPresetStatus(
            id: 'local-network',
            title: 'Локальная сеть',
            subtitle: 'Домашние и рабочие адреса работают напрямую.',
            state: RulesPresetState.enabled,
          ),
          RulesPresetStatus(
            id: 'full-tunnel',
            title: 'Всё устройство',
            subtitle: _brandTextForName(
              'Можно направить весь трафик Windows через POKROV.',
              brandName,
            ),
            state: RulesPresetState.enabled,
          ),
          RulesPresetStatus(
            id: 'selected-apps',
            title: 'Выбранные приложения',
            subtitle: _brandTextForName(
              'POKROV работает только для выбранных .exe и процессов.',
              brandName,
            ),
            state: RulesPresetState.enabled,
          ),
        ],
      ),
    HostPlatform.android => RulesPresetContract(
        rulesetVersion: _seedRulesetVersion,
        packageCatalogVersion: _seedPackageCatalogVersion,
        presets: [
          RulesPresetStatus(
            id: 'ru-banks',
            title: 'Российские банки',
            subtitle: 'Карты, платежи и приложения банков идут напрямую.',
            state: RulesPresetState.enabled,
          ),
          RulesPresetStatus(
            id: 'gosuslugi',
            title: 'Госуслуги',
            subtitle: _brandTextForName(
              'Государственные сервисы остаются без POKROV.',
              brandName,
            ),
            state: RulesPresetState.enabled,
          ),
          RulesPresetStatus(
            id: 'marketplaces',
            title: 'Маркетплейсы',
            subtitle: 'Покупки и доставка работают привычным маршрутом.',
            state: RulesPresetState.enabled,
          ),
          RulesPresetStatus(
            id: 'messengers',
            title: 'Мессенджеры',
            subtitle: 'Категория готовится к проверке правил.',
            state: RulesPresetState.staged,
          ),
          RulesPresetStatus(
            id: 'selected-apps',
            title: 'Выбранные приложения',
            subtitle: _brandTextForName(
              'Можно выбрать приложения, которые идут через POKROV.',
              brandName,
            ),
            state: RulesPresetState.enabled,
          ),
        ],
      ),
    HostPlatform.ios || HostPlatform.macos => RulesPresetContract(
        rulesetVersion: _seedRulesetVersion,
        packageCatalogVersion: _seedPackageCatalogVersion,
        presets: [
          RulesPresetStatus(
            id: 'ru-region',
            title: 'Российский регион',
            subtitle: 'Российские сайты и локальные адреса идут напрямую.',
            state: RulesPresetState.enabled,
          ),
          RulesPresetStatus(
            id: 'full-tunnel',
            title: 'Всё устройство',
            subtitle: _brandTextForName(
              'Весь трафик устройства идет через POKROV.',
              brandName,
            ),
            state: RulesPresetState.enabled,
          ),
          RulesPresetStatus(
            id: 'selected-apps',
            title: 'Выбранные приложения',
            subtitle: 'Платформа пока не дает управлять приложениями отсюда.',
            state: RulesPresetState.locked,
          ),
        ],
      ),
  };
}

const _seedManagedProfilePayload = ManagedProfilePayload(
  profileName: 'pokrov-seed-runtime',
  configPayload: '''
{
  "log": {
    "disabled": false,
    "level": "info"
  },
  "dns": {
    "servers": [
      {
        "tag": "local",
        "address": "local"
      }
    ]
  },
  "inbounds": [],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "final": "direct"
  }
}
''',
  materializedForRuntime: true,
);

SeedAppContext buildSeedAppContext({
  required HostPlatform hostPlatform,
  ClientVariantProfile? variantProfile,
}) {
  final profile = variantProfile ?? selectedClientVariantProfile();
  final bootstrapContract = switch (hostPlatform) {
    HostPlatform.android => const PlatformBootstrapContract(
        hostPlatform: HostPlatform.android,
        requiredPermissions: [
          PermissionRequirement.notifications,
          PermissionRequirement.vpnProfile,
          PermissionRequirement.backgroundStart,
        ],
        defaultCore: RuntimeCore.singBox,
        advancedFallbackCore: RuntimeCore.xray,
        supportsSelectedAppsMode: true,
      ),
    HostPlatform.ios => const PlatformBootstrapContract(
        hostPlatform: HostPlatform.ios,
        requiredPermissions: [
          PermissionRequirement.notifications,
          PermissionRequirement.vpnProfile,
        ],
        defaultCore: RuntimeCore.singBox,
        advancedFallbackCore: RuntimeCore.xray,
        supportsSelectedAppsMode: false,
      ),
    HostPlatform.macos => const PlatformBootstrapContract(
        hostPlatform: HostPlatform.macos,
        requiredPermissions: [
          PermissionRequirement.notifications,
          PermissionRequirement.vpnProfile,
        ],
        defaultCore: RuntimeCore.singBox,
        advancedFallbackCore: RuntimeCore.xray,
        supportsSelectedAppsMode: false,
      ),
    HostPlatform.windows => const PlatformBootstrapContract(
        hostPlatform: HostPlatform.windows,
        requiredPermissions: [
          PermissionRequirement.notifications,
          PermissionRequirement.elevatedSession,
        ],
        defaultCore: RuntimeCore.singBox,
        advancedFallbackCore: RuntimeCore.xray,
        supportsSelectedAppsMode: true,
      ),
  };

  return SeedAppContext(
    hostPlatform: hostPlatform,
    variantProfile: profile,
    accessLane:
        profile.isCommunity ? AccessLane.freeMonthly : AccessLane.trialPremium,
    scope: const ProgramScope(
      publicReleaseTargets: [
        ClientPlatform.android,
        ClientPlatform.windows,
      ],
      readinessOnlyTargets: [
        ClientPlatform.ios,
        ClientPlatform.macos,
      ],
    ),
    runtimeProfile: RuntimeProfile(
      defaultCore: RuntimeCore.singBox,
      advancedFallbackCore: RuntimeCore.xray,
      defaultRouteMode: RouteMode.allExceptRu,
      supportedRouteModes: [
        RouteMode.allExceptRu,
        RouteMode.fullTunnel,
        if (bootstrapContract.supportsSelectedAppsMode &&
            _selectedAppsEnforcementReady)
          RouteMode.selectedApps,
      ],
      trialDays: profile.isCommunity ? 0 : 5,
      telegramBonusDays: profile.isCommunity ? 0 : 10,
      freeTier: const FreeTierPolicy(
        trafficGb: 5,
        periodDays: 30,
        speedMbps: 50,
        deviceLimit: 1,
        nodePool: 'NL-free',
      ),
      allowsExternalCheckoutOnly: true,
      firstPartyPromosOnly: true,
    ),
    bootstrapContract: bootstrapContract,
    supportSnapshot: SupportSnapshot(
      supportBot: profile.supportBot,
      feedbackBot: profile.feedbackBot,
      publicChannel: profile.publicChannel,
      supportEmail: profile.supportEmail,
      safeNotes:
          'Поддержка видит только безопасный контекст: версию приложения, платформу, режим и статус подключения.',
      recommendedRouteMode: RouteMode.allExceptRu,
      channelBonusDays: 10,
    ),
    rulesPresetContract: _seedRulesPresetContractFor(hostPlatform, profile),
    locations: [
      LocationCluster(
        code: profile.isCommunity ? 'local-profile' : 'managed-service',
        label: profile.displayName,
        city: 'Автоматический выбор',
        countryCode: profile.isCommunity ? 'LC' : 'OP',
        recommendedLane: 'Авто',
        variants: const [
          LocationVariant(kind: TransportKind.vlessReality),
          LocationVariant(kind: TransportKind.vmess),
          LocationVariant(kind: TransportKind.trojan),
          LocationVariant(
            kind: TransportKind.xhttp,
            availability: VariantAvailability.gated,
            note: 'Откроется после подготовки публичного контура.',
          ),
        ],
      ),
    ],
    apiBaseUrl: profile.apiBaseUrl,
    checkoutUrl: profile.checkoutUrl,
    cabinetUrl: profile.cabinetUrl,
    redeemHint: '',
    managedProfileSeed: _seedManagedProfilePayload,
  );
}

class PokrovSeedApp extends StatelessWidget {
  const PokrovSeedApp({
    super.key,
    required this.appContext,
    this.bootstrapper,
    this.supportTicketService,
    this.handoffLauncher,
    this.firstLaunchStore,
    this.communitySubscriptionFetcher,
    this.communityQrScanner,
    this.runtimeActionTimeout = const Duration(seconds: 18),
    this.communitySubscriptionAutoRefreshInterval = const Duration(minutes: 30),
    this.communitySubscriptionStaleAfter = const Duration(minutes: 30),
  });

  final SeedAppContext appContext;
  final ManagedProfileBootstrapper? bootstrapper;
  final SupportTicketService? supportTicketService;
  final ExternalHandoffLauncher? handoffLauncher;
  final PokrovFirstLaunchStore? firstLaunchStore;
  final Future<String> Function(Uri uri)? communitySubscriptionFetcher;
  final CommunityQrScanner? communityQrScanner;
  final Duration runtimeActionTimeout;
  final Duration communitySubscriptionAutoRefreshInterval;
  final Duration communitySubscriptionStaleAfter;

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.light(
      primary: _SeedPalette.accent,
      onPrimary: Colors.white,
      secondary: _SeedPalette.accentBright,
      onSecondary: Colors.white,
      surface: _SeedPalette.surface,
      onSurface: _SeedPalette.ink,
      error: Color(0xFFB33B2E),
      onError: Colors.white,
    );

    return MaterialApp(
      title: appContext.variantProfile.displayName,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: _SeedPalette.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: _SeedPalette.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: _SeedPalette.accent.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? _SeedPalette.ink
                  : _SeedPalette.ink.withValues(alpha: 0.68),
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? _SeedPalette.accent
                  : _SeedPalette.ink.withValues(alpha: 0.68),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _SeedPalette.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _SeedPalette.ink,
            side: BorderSide(color: _SeedPalette.ink.withValues(alpha: 0.16)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: PokrovSeedShell(
        appContext: appContext,
        bootstrapper: bootstrapper,
        supportTicketService: supportTicketService,
        handoffLauncher: handoffLauncher,
        firstLaunchStore: firstLaunchStore,
        communitySubscriptionFetcher: communitySubscriptionFetcher,
        communityQrScanner: communityQrScanner,
        runtimeActionTimeout: runtimeActionTimeout,
        communitySubscriptionAutoRefreshInterval:
            communitySubscriptionAutoRefreshInterval,
        communitySubscriptionStaleAfter: communitySubscriptionStaleAfter,
      ),
    );
  }
}

class PokrovSeedShell extends StatefulWidget {
  const PokrovSeedShell({
    super.key,
    required this.appContext,
    this.bootstrapper,
    this.supportTicketService,
    this.handoffLauncher,
    this.firstLaunchStore,
    this.communitySubscriptionFetcher,
    this.communityQrScanner,
    this.runtimeActionTimeout = const Duration(seconds: 18),
    this.communitySubscriptionAutoRefreshInterval = const Duration(minutes: 30),
    this.communitySubscriptionStaleAfter = const Duration(minutes: 30),
  });

  final SeedAppContext appContext;
  final ManagedProfileBootstrapper? bootstrapper;
  final SupportTicketService? supportTicketService;
  final ExternalHandoffLauncher? handoffLauncher;
  final PokrovFirstLaunchStore? firstLaunchStore;
  final Future<String> Function(Uri uri)? communitySubscriptionFetcher;
  final CommunityQrScanner? communityQrScanner;
  final Duration runtimeActionTimeout;
  final Duration communitySubscriptionAutoRefreshInterval;
  final Duration communitySubscriptionStaleAfter;

  @override
  State<PokrovSeedShell> createState() => _PokrovSeedShellState();
}

class _StaticManagedProfileBootstrapper implements ManagedProfileBootstrapper {
  const _StaticManagedProfileBootstrapper(this.payload);

  final ManagedProfilePayload payload;

  @override
  Future<ManagedProfilePayload> resolveManagedProfile({
    required HostPlatform hostPlatform,
    required RouteMode routeMode,
    List<String> selectedApps = const <String>[],
  }) async {
    return payload;
  }
}

class _LocalManagedProfileStore {
  const _LocalManagedProfileStore();

  static const _fileName = 'open-client-local-profile.json';

  Future<File> _profileFile() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  Future<_CommunityProfileState> readState() async {
    try {
      final file = await _profileFile();
      if (!await file.exists()) {
        return const _CommunityProfileState.empty();
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return const _CommunityProfileState.empty();
      }
      final profiles = decoded['profiles'];
      if (profiles is List<Object?>) {
        final records = profiles
            .whereType<Map<String, Object?>>()
            .map(_CommunityProfileRecord.fromJson)
            .whereType<_CommunityProfileRecord>()
            .toList(growable: false);
        if (records.isEmpty) {
          return const _CommunityProfileState.empty();
        }
        final activeName = decoded['active_profile_name']?.toString() ?? '';
        return _CommunityProfileState(
          profiles: records,
          activeProfileName: records.any(
            (record) => record.payload.profileName == activeName,
          )
              ? activeName
              : records.first.payload.profileName,
        );
      }
      final configPayload = decoded['config_payload']?.toString() ?? '';
      final profileName = decoded['profile_name']?.toString() ?? '';
      if (configPayload.trim().isEmpty || profileName.trim().isEmpty) {
        return const _CommunityProfileState.empty();
      }
      final routeModeName = decoded['route_mode']?.toString() ?? '';
      final routeMode = RouteMode.values.firstWhere(
        (mode) => mode.name == routeModeName,
        orElse: () => RouteMode.fullTunnel,
      );
      final record = _CommunityProfileRecord(
        displayName: profileName,
        sourceKind: 'single_key',
        payload: ManagedProfilePayload(
          profileName: profileName,
          configPayload: configPayload,
          materializedForRuntime: true,
          routeMode: routeMode,
        ),
      );
      return _CommunityProfileState(
        profiles: [record],
        activeProfileName: record.payload.profileName,
      );
    } on FormatException {
      return const _CommunityProfileState.empty();
    }
  }

  Future<ManagedProfilePayload?> read() async {
    return (await readState()).activeProfile?.payload;
  }

  Future<void> writeState(_CommunityProfileState state) async {
    final file = await _profileFile();
    await file.writeAsString(
      jsonEncode(<String, Object?>{
        'schema': 2,
        'active_profile_name': state.activeProfileName,
        'profiles': state.profiles
            .map((record) => record.toJson())
            .toList(growable: false),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
  }

  Future<void> write(ManagedProfilePayload payload) async {
    await writeState(
      _CommunityProfileState(
        profiles: [
          _CommunityProfileRecord(
            displayName: payload.profileName,
            sourceKind: 'single_key',
            payload: payload,
          ),
        ],
        activeProfileName: payload.profileName,
      ),
    );
  }

  Future<void> delete() async {
    final file = await _profileFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class _CommunityProfileRecord {
  const _CommunityProfileRecord({
    required this.displayName,
    required this.sourceKind,
    required this.payload,
    this.sourceUrl = '',
    this.lastFetchedAt = '',
    this.lastRefreshStatus = '',
    this.refreshError = '',
    this.entryCount = 0,
  });

  final String displayName;
  final String sourceKind;
  final ManagedProfilePayload payload;
  final String sourceUrl;
  final String lastFetchedAt;
  final String lastRefreshStatus;
  final String refreshError;
  final int entryCount;

  _CommunityProfileRecord copyWith({
    String? displayName,
    String? sourceKind,
    ManagedProfilePayload? payload,
    String? sourceUrl,
    String? lastFetchedAt,
    String? lastRefreshStatus,
    String? refreshError,
    int? entryCount,
  }) {
    return _CommunityProfileRecord(
      displayName: displayName ?? this.displayName,
      sourceKind: sourceKind ?? this.sourceKind,
      payload: payload ?? this.payload,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastRefreshStatus: lastRefreshStatus ?? this.lastRefreshStatus,
      refreshError: refreshError ?? this.refreshError,
      entryCount: entryCount ?? this.entryCount,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'profile_name': payload.profileName,
      'display_name': displayName,
      'source_kind': sourceKind,
      'source_url': sourceUrl,
      'last_fetched_at': lastFetchedAt,
      'last_refresh_status': lastRefreshStatus,
      'refresh_error': refreshError,
      'entry_count': entryCount,
      'config_payload': payload.configPayload,
      'route_mode': payload.routeMode.name,
      'materialized_for_runtime': true,
    };
  }

  static _CommunityProfileRecord? fromJson(Map<String, Object?> json) {
    final profileName = json['profile_name']?.toString() ?? '';
    final configPayload = json['config_payload']?.toString() ?? '';
    if (profileName.trim().isEmpty || configPayload.trim().isEmpty) {
      return null;
    }
    final routeModeName = json['route_mode']?.toString() ?? '';
    final routeMode = RouteMode.values.firstWhere(
      (mode) => mode.name == routeModeName,
      orElse: () => RouteMode.fullTunnel,
    );
    return _CommunityProfileRecord(
      displayName: (json['display_name']?.toString() ?? '').trim().isEmpty
          ? profileName
          : json['display_name'].toString().trim(),
      sourceKind: (json['source_kind']?.toString() ?? '').trim().isEmpty
          ? 'single_key'
          : json['source_kind'].toString().trim(),
      sourceUrl: json['source_url']?.toString().trim() ?? '',
      lastFetchedAt: json['last_fetched_at']?.toString().trim() ?? '',
      lastRefreshStatus: json['last_refresh_status']?.toString().trim() ?? '',
      refreshError: json['refresh_error']?.toString().trim() ?? '',
      entryCount: _readInt(json['entry_count']),
      payload: ManagedProfilePayload(
        profileName: profileName,
        configPayload: configPayload,
        materializedForRuntime: true,
        routeMode: routeMode,
      ),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _CommunityProfileState {
  const _CommunityProfileState({
    required this.profiles,
    required this.activeProfileName,
  });

  const _CommunityProfileState.empty()
      : profiles = const <_CommunityProfileRecord>[],
        activeProfileName = '';

  final List<_CommunityProfileRecord> profiles;
  final String activeProfileName;

  _CommunityProfileRecord? get activeProfile {
    for (final profile in profiles) {
      if (profile.payload.profileName == activeProfileName) {
        return profile;
      }
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  List<String> get subscriptionSourceUrls {
    final urls = <String>{};
    for (final profile in profiles) {
      final sourceUrl = profile.sourceUrl.trim();
      if (sourceUrl.isNotEmpty) {
        urls.add(sourceUrl);
      }
    }
    return urls.toList(growable: false)..sort();
  }

  _CommunityProfileState upsertAll(
    List<_CommunityProfileRecord> incoming, {
    String? activeProfileName,
  }) {
    final byName = <String, _CommunityProfileRecord>{
      for (final profile in profiles) profile.payload.profileName: profile,
    };
    for (final profile in incoming) {
      byName[profile.payload.profileName] = profile;
    }
    final values = byName.values.toList(growable: false)
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final active = activeProfileName ??
        (incoming.isNotEmpty
            ? incoming.first.payload.profileName
            : this.activeProfileName);
    return _CommunityProfileState(
      profiles: values,
      activeProfileName:
          values.any((profile) => profile.payload.profileName == active)
              ? active
              : (values.isEmpty ? '' : values.first.payload.profileName),
    );
  }

  _CommunityProfileState setActive(String profileName) {
    if (!profiles
        .any((profile) => profile.payload.profileName == profileName)) {
      return this;
    }
    return _CommunityProfileState(
      profiles: profiles,
      activeProfileName: profileName,
    );
  }

  _CommunityProfileState remove(String profileName) {
    final values = profiles
        .where((profile) => profile.payload.profileName != profileName)
        .toList(growable: false);
    return _CommunityProfileState(
      profiles: values,
      activeProfileName: activeProfileName == profileName
          ? (values.isEmpty ? '' : values.first.payload.profileName)
          : activeProfileName,
    );
  }

  _CommunityProfileState markSubscriptionRefreshFailed(
    String sourceUrl,
    String message,
  ) {
    return _CommunityProfileState(
      profiles: profiles
          .map(
            (profile) => profile.sourceUrl == sourceUrl
                ? profile.copyWith(
                    lastRefreshStatus: 'failed',
                    refreshError: message,
                  )
                : profile,
          )
          .toList(growable: false),
      activeProfileName: activeProfileName,
    );
  }
}

class _LocalManagedProfileBootstrapper implements ManagedProfileBootstrapper {
  _LocalManagedProfileBootstrapper({
    required ManagedProfilePayload fallback,
    _LocalManagedProfileStore store = const _LocalManagedProfileStore(),
  })  : _fallback = fallback,
        _payload = fallback,
        _store = store;

  final _LocalManagedProfileStore _store;
  final ManagedProfilePayload _fallback;
  ManagedProfilePayload _payload;
  _CommunityProfileState _state = const _CommunityProfileState.empty();
  bool _loaded = false;

  Future<_CommunityProfileState> loadImportedState() async {
    final state = await _store.readState();
    _state = state;
    _payload = state.activeProfile?.payload ?? _fallback;
    _loaded = true;
    return state;
  }

  Future<ManagedProfilePayload?> loadImportedProfile() async {
    return (await loadImportedState()).activeProfile?.payload;
  }

  Future<_CommunityProfileState> saveImportedRecords(
    List<_CommunityProfileRecord> records,
  ) async {
    if (!_loaded) {
      await loadImportedState();
    }
    _state = _state.upsertAll(records);
    _payload = _state.activeProfile?.payload ?? _fallback;
    _loaded = true;
    await _store.writeState(_state);
    return _state;
  }

  Future<_CommunityProfileState> saveState(
    _CommunityProfileState state,
  ) async {
    _state = state;
    _payload = _state.activeProfile?.payload ?? _fallback;
    _loaded = true;
    if (_state.profiles.isEmpty) {
      await _store.delete();
    } else {
      await _store.writeState(_state);
    }
    return _state;
  }

  Future<_CommunityProfileState> saveImportedProfile(
    _CommunityProfileRecord record,
  ) async {
    return saveImportedRecords([record]);
  }

  Future<_CommunityProfileState> setActiveProfile(String profileName) async {
    if (!_loaded) {
      await loadImportedState();
    }
    _state = _state.setActive(profileName);
    _payload = _state.activeProfile?.payload ?? _fallback;
    await _store.writeState(_state);
    return _state;
  }

  Future<_CommunityProfileState> removeProfile(String profileName) async {
    if (!_loaded) {
      await loadImportedState();
    }
    _state = _state.remove(profileName);
    _payload = _state.activeProfile?.payload ?? _fallback;
    if (_state.profiles.isEmpty) {
      await _store.delete();
    } else {
      await _store.writeState(_state);
    }
    return _state;
  }

  Future<void> clearImportedProfile() async {
    _state = const _CommunityProfileState.empty();
    _payload = _fallback;
    _loaded = true;
    await _store.delete();
  }

  @override
  Future<ManagedProfilePayload> resolveManagedProfile({
    required HostPlatform hostPlatform,
    required RouteMode routeMode,
    List<String> selectedApps = const <String>[],
  }) async {
    if (!_loaded) {
      await loadImportedState();
    }
    return _payload.copyWith(routeMode: routeMode);
  }
}

class _CommunityProfileImportResult {
  const _CommunityProfileImportResult({
    required this.record,
    required this.displayName,
  });

  final _CommunityProfileRecord record;
  final String displayName;
}

class _CommunityProfileImportFailure implements Exception {
  const _CommunityProfileImportFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class _CommunityProfileImporter {
  const _CommunityProfileImporter._();

  static _CommunityProfileImportResult parse(
    String value, {
    required RouteMode routeMode,
    String sourceKind = 'single_key',
  }) {
    final source = value.trim();
    if (source.isEmpty) {
      throw const _CommunityProfileImportFailure(
        'Paste a single proxy key.',
      );
    }
    final uri = Uri.tryParse(source);
    if (uri == null || !uri.hasScheme) {
      throw const _CommunityProfileImportFailure(
        'This does not look like a supported proxy key.',
      );
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      throw const _CommunityProfileImportFailure(
        'Subscription URL refresh is not enabled yet. Paste a single vless://, trojan://, ss://, or vmess:// key.',
      );
    }

    final outbound = switch (scheme) {
      'vless' => _parseVless(uri),
      'trojan' => _parseTrojan(uri),
      'ss' => _parseShadowsocks(source, uri),
      'vmess' => _parseVmess(source),
      _ => throw _CommunityProfileImportFailure(
          'Unsupported key type: $scheme.',
        ),
    };
    final name = _profileNameFromSource(
      source: source,
      uri: uri,
      fallback: scheme.toUpperCase(),
    );
    final config = <String, Object?>{
      'log': <String, Object?>{
        'disabled': false,
        'level': 'info',
      },
      'dns': <String, Object?>{
        'servers': <Object?>[
          <String, Object?>{
            'tag': 'local',
            'address': 'local',
          },
          <String, Object?>{
            'tag': 'remote',
            'address': 'https://1.1.1.1/dns-query',
            'detour': 'proxy',
          },
        ],
        'final': 'remote',
      },
      'outbounds': <Object?>[
        outbound,
        <String, Object?>{
          'type': 'direct',
          'tag': 'direct',
        },
        <String, Object?>{
          'type': 'block',
          'tag': 'block',
        },
      ],
      'route': <String, Object?>{
        'final': 'proxy',
        'auto_detect_interface': true,
      },
    };
    return _CommunityProfileImportResult(
      displayName: name,
      record: _CommunityProfileRecord(
        displayName: name,
        sourceKind: sourceKind,
        payload: ManagedProfilePayload(
          profileName: _safeProfileName(name),
          configPayload: const JsonEncoder.withIndent('  ').convert(config),
          materializedForRuntime: true,
          routeMode: routeMode,
        ),
      ),
    );
  }

  static List<_CommunityProfileImportResult> parseMany(
    String value, {
    required RouteMode routeMode,
    String sourceKind = 'subscription',
  }) {
    final entries = _subscriptionEntries(value);
    if (entries.isEmpty) {
      throw const _CommunityProfileImportFailure(
        'No supported proxy keys were found.',
      );
    }
    final results = <_CommunityProfileImportResult>[];
    final errors = <String>[];
    for (final entry in entries.take(64)) {
      try {
        results.add(parse(entry, routeMode: routeMode, sourceKind: sourceKind));
      } on _CommunityProfileImportFailure catch (error) {
        errors.add(error.message);
      }
    }
    if (results.isEmpty) {
      throw _CommunityProfileImportFailure(
        errors.isEmpty ? 'No supported proxy keys were found.' : errors.first,
      );
    }
    return results;
  }

  static List<String> _subscriptionEntries(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }
    final direct = _extractProxyUris(trimmed);
    if (direct.isNotEmpty) {
      return direct;
    }
    final decoded = _decodeMaybeBase64(trimmed);
    if (decoded != trimmed) {
      return _extractProxyUris(decoded);
    }
    return const <String>[];
  }

  static List<String> _extractProxyUris(String value) {
    final normalized = value
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList(growable: false);
    return normalized.where((line) {
      final uri = Uri.tryParse(line);
      return uri != null &&
          const <String>{'vless', 'vmess', 'trojan', 'ss'}
              .contains(uri.scheme.toLowerCase());
    }).toList(growable: false);
  }

  static Map<String, Object?> _parseVless(Uri uri) {
    final uuid = Uri.decodeComponent(uri.userInfo).trim();
    _require(uuid.isNotEmpty, 'VLESS key has no UUID.');
    final outbound = <String, Object?>{
      'type': 'vless',
      'tag': 'proxy',
      'server': _requiredHost(uri),
      'server_port': _requiredPort(uri),
      'uuid': uuid,
      'packet_encoding': uri.queryParameters['packetEncoding'] ?? 'xudp',
    };
    final flow = uri.queryParameters['flow']?.trim() ?? '';
    if (flow.isNotEmpty) {
      outbound['flow'] = flow;
    }
    final network = uri.queryParameters['type']?.trim() ?? '';
    if (network.isNotEmpty && network != 'tcp') {
      outbound['transport'] = _transportFromQuery(network, uri);
    }
    final tls = _tlsFromQuery(uri);
    if (tls != null) {
      outbound['tls'] = tls;
    }
    return outbound;
  }

  static Map<String, Object?> _parseTrojan(Uri uri) {
    final password = Uri.decodeComponent(uri.userInfo).trim();
    _require(password.isNotEmpty, 'Trojan key has no password.');
    final outbound = <String, Object?>{
      'type': 'trojan',
      'tag': 'proxy',
      'server': _requiredHost(uri),
      'server_port': _requiredPort(uri),
      'password': password,
    };
    final network = uri.queryParameters['type']?.trim() ?? '';
    if (network.isNotEmpty && network != 'tcp') {
      outbound['transport'] = _transportFromQuery(network, uri);
    }
    final tls = _tlsFromQuery(uri, defaultEnabled: true);
    if (tls != null) {
      outbound['tls'] = tls;
    }
    return outbound;
  }

  static Map<String, Object?> _parseShadowsocks(String source, Uri uri) {
    var userInfo = uri.userInfo;
    var host = uri.host;
    var port = uri.hasPort ? uri.port : 0;
    if (userInfo.isEmpty) {
      final withoutScheme = source.substring('ss://'.length).split('#').first;
      final decoded = _decodeMaybeBase64(withoutScheme.split('?').first);
      final parsed = Uri.tryParse('ss://$decoded');
      if (parsed != null) {
        userInfo = parsed.userInfo;
        host = parsed.host;
        port = parsed.hasPort ? parsed.port : 0;
      }
    } else if (!userInfo.contains(':')) {
      userInfo = _decodeMaybeBase64(userInfo);
    }
    final separator = userInfo.indexOf(':');
    _require(separator > 0, 'Shadowsocks key has no method/password pair.');
    final method = Uri.decodeComponent(userInfo.substring(0, separator));
    final password = Uri.decodeComponent(userInfo.substring(separator + 1));
    _require(host.trim().isNotEmpty, 'Shadowsocks key has no server.');
    _require(port > 0, 'Shadowsocks key has no server port.');
    return <String, Object?>{
      'type': 'shadowsocks',
      'tag': 'proxy',
      'server': host,
      'server_port': port,
      'method': method,
      'password': password,
    };
  }

  static Map<String, Object?> _parseVmess(String source) {
    final body = source.substring('vmess://'.length).trim();
    final decoded = jsonDecode(_decodeMaybeBase64(body));
    if (decoded is! Map<String, Object?>) {
      throw const _CommunityProfileImportFailure(
          'VMess key is not valid JSON.');
    }
    final host = decoded['add']?.toString().trim() ?? '';
    final port = int.tryParse(decoded['port']?.toString() ?? '') ?? 0;
    final uuid = decoded['id']?.toString().trim() ?? '';
    _require(host.isNotEmpty, 'VMess key has no server.');
    _require(port > 0, 'VMess key has no server port.');
    _require(uuid.isNotEmpty, 'VMess key has no UUID.');
    final outbound = <String, Object?>{
      'type': 'vmess',
      'tag': 'proxy',
      'server': host,
      'server_port': port,
      'uuid': uuid,
      'security': decoded['scy']?.toString().trim().isNotEmpty == true
          ? decoded['scy'].toString().trim()
          : 'auto',
      'alter_id': int.tryParse(decoded['aid']?.toString() ?? '') ?? 0,
    };
    final network = decoded['net']?.toString().trim() ?? '';
    if (network.isNotEmpty && network != 'tcp') {
      outbound['transport'] = _transportFromVmess(decoded, network);
    }
    final tlsMode = decoded['tls']?.toString().trim().toLowerCase() ?? '';
    if (tlsMode == 'tls') {
      outbound['tls'] = <String, Object?>{
        'enabled': true,
        if ((decoded['sni']?.toString().trim() ?? '').isNotEmpty)
          'server_name': decoded['sni'].toString().trim(),
      };
    }
    return outbound;
  }

  static Map<String, Object?>? _tlsFromQuery(
    Uri uri, {
    bool defaultEnabled = false,
  }) {
    final security = uri.queryParameters['security']?.toLowerCase().trim();
    final tlsEnabled =
        defaultEnabled || security == 'tls' || security == 'reality';
    if (!tlsEnabled) {
      return null;
    }
    final tls = <String, Object?>{'enabled': true};
    final sni = (uri.queryParameters['sni'] ??
            uri.queryParameters['serverName'] ??
            uri.queryParameters['peer'])
        ?.trim();
    if (sni != null && sni.isNotEmpty) {
      tls['server_name'] = sni;
    }
    final fingerprint = uri.queryParameters['fp']?.trim();
    if (fingerprint != null && fingerprint.isNotEmpty) {
      tls['utls'] = <String, Object?>{
        'enabled': true,
        'fingerprint': fingerprint,
      };
    }
    if (security == 'reality') {
      final publicKey = uri.queryParameters['pbk']?.trim() ?? '';
      _require(publicKey.isNotEmpty, 'Reality key has no public key.');
      tls['reality'] = <String, Object?>{
        'enabled': true,
        'public_key': publicKey,
        if ((uri.queryParameters['sid']?.trim() ?? '').isNotEmpty)
          'short_id': uri.queryParameters['sid']!.trim(),
      };
    }
    return tls;
  }

  static Map<String, Object?> _transportFromQuery(String network, Uri uri) {
    return switch (network) {
      'ws' => <String, Object?>{
          'type': 'ws',
          if ((uri.queryParameters['path']?.trim() ?? '').isNotEmpty)
            'path': uri.queryParameters['path']!.trim(),
          if ((uri.queryParameters['host']?.trim() ?? '').isNotEmpty)
            'headers': <String, Object?>{
              'Host': uri.queryParameters['host']!.trim(),
            },
        },
      'grpc' => <String, Object?>{
          'type': 'grpc',
          if ((uri.queryParameters['serviceName']?.trim() ?? '').isNotEmpty)
            'service_name': uri.queryParameters['serviceName']!.trim(),
        },
      _ => <String, Object?>{'type': network},
    };
  }

  static Map<String, Object?> _transportFromVmess(
    Map<String, Object?> decoded,
    String network,
  ) {
    return switch (network) {
      'ws' => <String, Object?>{
          'type': 'ws',
          if ((decoded['path']?.toString().trim() ?? '').isNotEmpty)
            'path': decoded['path'].toString().trim(),
          if ((decoded['host']?.toString().trim() ?? '').isNotEmpty)
            'headers': <String, Object?>{
              'Host': decoded['host'].toString().trim(),
            },
        },
      'grpc' => <String, Object?>{
          'type': 'grpc',
          if ((decoded['path']?.toString().trim() ?? '').isNotEmpty)
            'service_name': decoded['path'].toString().trim(),
        },
      _ => <String, Object?>{'type': network},
    };
  }

  static String _decodeMaybeBase64(String value) {
    final normalized = value.trim();
    try {
      final padded = normalized.padRight(
        normalized.length + ((4 - normalized.length % 4) % 4),
        '=',
      );
      return utf8.decode(base64Url.decode(padded));
    } catch (_) {
      try {
        final padded = normalized.padRight(
          normalized.length + ((4 - normalized.length % 4) % 4),
          '=',
        );
        return utf8.decode(base64.decode(padded));
      } catch (_) {
        return Uri.decodeComponent(normalized);
      }
    }
  }

  static String _requiredHost(Uri uri) {
    final host = uri.host.trim();
    _require(host.isNotEmpty, 'Proxy key has no server.');
    return host;
  }

  static int _requiredPort(Uri uri) {
    final port = uri.hasPort ? uri.port : 0;
    _require(port > 0, 'Proxy key has no server port.');
    return port;
  }

  static String _profileNameFromUri(Uri uri, {required String fallback}) {
    final fragment = Uri.decodeComponent(uri.fragment).trim();
    if (fragment.isNotEmpty) {
      return fragment;
    }
    final host = uri.host.trim();
    return host.isEmpty ? fallback : host;
  }

  static String _profileNameFromSource({
    required String source,
    required Uri uri,
    required String fallback,
  }) {
    if (uri.scheme.toLowerCase() == 'vmess') {
      try {
        final body = source.substring('vmess://'.length).trim();
        final decoded = jsonDecode(_decodeMaybeBase64(body));
        if (decoded is Map<String, Object?>) {
          final ps = decoded['ps']?.toString().trim() ?? '';
          if (ps.isNotEmpty) {
            return ps;
          }
        }
      } on Object {
        // Fall back to the generic URI label; parse() reports invalid VMess.
      }
    }
    return _profileNameFromUri(uri, fallback: fallback);
  }

  static String _safeProfileName(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return normalized.isEmpty
        ? 'open-client-imported'
        : 'open-client-$normalized';
  }

  static void _require(bool condition, String message) {
    if (!condition) {
      throw _CommunityProfileImportFailure(message);
    }
  }
}

class _OfflineSupportTicketService implements SupportTicketService {
  const _OfflineSupportTicketService();

  @override
  Future<List<SupportTicketThread>> listTickets({
    required HostPlatform hostPlatform,
    int limit = 20,
  }) async {
    return const <SupportTicketThread>[];
  }

  @override
  Future<SupportTicketThread> getTicket({
    required HostPlatform hostPlatform,
    required int ticketId,
  }) async {
    throw const SupportTicketFailure(
      'Support API is not configured for this open client build.',
    );
  }

  @override
  Future<SupportTicketReceipt> createTicket({
    required HostPlatform hostPlatform,
    required RouteMode routeMode,
    required String statusLabel,
    required String body,
    String subject = '',
    Map<String, Object?> diagnostics = const <String, Object?>{},
  }) async {
    if (body.trim().isEmpty) {
      throw const SupportTicketFailure('Message must not be empty.');
    }
    return const SupportTicketReceipt(
      ticketId: 0,
      statusTitle: 'Local draft',
      messageCount: 1,
    );
  }

  @override
  Future<SupportTicketThread> sendMessage({
    required HostPlatform hostPlatform,
    required int ticketId,
    required String body,
    RouteMode? routeMode,
    String statusLabel = '',
    Map<String, Object?> diagnostics = const <String, Object?>{},
  }) async {
    throw const SupportTicketFailure(
      'Support API is not configured for this open client build.',
    );
  }
}

class _PokrovSeedShellState extends State<PokrovSeedShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late RouteMode _selectedRouteMode;
  late final PokrovRuntimeEngine _runtimeEngine;
  late final ManagedProfileBootstrapper _bootstrapper;
  late final AppFirstAccountActionService? _accountActionService;
  late final AppFirstBonusActionService? _bonusActionService;
  late final AppFirstWarpActionService? _warpActionService;
  late final AppFirstReleaseActionService? _releaseActionService;
  late final AppFirstNodePreferenceService? _nodePreferenceService;
  late final SupportTicketService _supportTicketService;
  late final PokrovFirstLaunchStore _firstLaunchStore;
  late final _LocalManagedProfileBootstrapper? _localProfileBootstrapper;
  _CommunityProfileState _communityProfileState =
      const _CommunityProfileState.empty();
  int _communityProfileRevision = 0;
  Timer? _communitySubscriptionRefreshTimer;
  bool _communitySubscriptionRefreshInFlight = false;

  String _brand(String value) {
    return _brandText(value, widget.appContext.variantProfile);
  }

  final TextEditingController _firstLaunchRestoreCodeController =
      TextEditingController();
  RuntimeSnapshot? _runtimeSnapshot;
  bool _runtimeBusy = false;
  bool _firstLaunchBusy = false;
  bool _managedProfileDirty = true;
  _FirstLaunchStep _firstLaunchStep = _FirstLaunchStep.choice;
  String? _runtimeHeadline;
  String _telegramBonusStatus = 'Получить код';
  bool _telegramBonusBusy = false;
  bool _telegramBonusCanClaim = false;
  String? _telegramBonusError;
  AppFirstBonusSummary? _bonusSummary;
  bool _bonusSummaryBusy = false;
  bool _bonusSummaryRequested = false;
  String? _bonusSummaryError;
  bool _bonusRewardBusy = false;
  final List<String> _selectedAppIds = <String>[];
  WarpRuntimePolicy _managedWarpPolicy = WarpRuntimePolicy.disabled;
  bool _warpRuntimeConsent = false;
  bool _warpPolicyBusy = false;
  SmartConnectProfile? _smartConnectProfile;
  String _preferredNodeCode = '';
  bool _nodePreferenceBusy = false;
  bool _clientUpdateCheckBusy = false;
  bool _clientUpdatePromptVisible = false;
  String _lastPromptedUpdateKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedRouteMode = widget.appContext.runtimeProfile.defaultRouteMode;
    _runtimeEngine = createRuntimeEngine(
      hostPlatform: widget.appContext.hostPlatform,
    );
    _localProfileBootstrapper =
        !widget.appContext.variantProfile.usesApiServices &&
                widget.bootstrapper == null
            ? _LocalManagedProfileBootstrapper(
                fallback: widget.appContext.managedProfileSeed,
              )
            : null;
    final bootstrapper = widget.bootstrapper ??
        (widget.appContext.variantProfile.usesApiServices
            ? AppFirstRuntimeBootstrapper(
                apiBaseUrl: widget.appContext.apiBaseUrl,
              )
            : _localProfileBootstrapper ??
                _StaticManagedProfileBootstrapper(
                  widget.appContext.managedProfileSeed,
                ));
    _bootstrapper = bootstrapper;
    _accountActionService = bootstrapper is AppFirstAccountActionService
        ? bootstrapper as AppFirstAccountActionService
        : null;
    _bonusActionService = bootstrapper is AppFirstBonusActionService
        ? bootstrapper as AppFirstBonusActionService
        : null;
    _warpActionService = bootstrapper is AppFirstWarpActionService
        ? bootstrapper as AppFirstWarpActionService
        : null;
    _releaseActionService = bootstrapper is AppFirstReleaseActionService
        ? bootstrapper as AppFirstReleaseActionService
        : null;
    _nodePreferenceService = bootstrapper is AppFirstNodePreferenceService
        ? bootstrapper as AppFirstNodePreferenceService
        : null;
    _supportTicketService = widget.supportTicketService ??
        (widget.appContext.variantProfile.usesApiServices
            ? AppFirstSupportTicketService(
                apiBaseUrl: widget.appContext.apiBaseUrl,
              )
            : const _OfflineSupportTicketService());
    _firstLaunchStore =
        widget.firstLaunchStore ?? const PokrovFileFirstLaunchStore();
    unawaited(_loadCommunityProfile());
    unawaited(_loadFirstLaunchState());
    _refreshRuntimeSnapshot();
    _ensureCommunitySubscriptionRefreshTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForClientUpdate());
    });
  }

  void _selectRouteMode(RouteMode mode) {
    setState(() {
      _selectedRouteMode = mode;
      _managedProfileDirty = true;
    });
  }

  Future<void> _setPreferredLocation(String nodeCode) async {
    final smartConnect = _smartConnectProfile;
    final normalized = nodeCode.trim().toLowerCase();
    if (smartConnect == null || normalized.isEmpty || _nodePreferenceBusy) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _nodePreferenceBusy = true;
      _preferredNodeCode = normalized;
      _managedProfileDirty = true;
      _runtimeHeadline =
          'Локация сохранена. Применим при следующем подключении.';
    });
    try {
      final service = _nodePreferenceService;
      if (service != null) {
        final result = await service.setPreferredSmartConnectNode(
          hostPlatform: widget.appContext.hostPlatform,
          smartConnect: smartConnect,
          nodeCode: normalized,
        );
        if (!mounted) {
          return;
        }
        if (result.preferredNodeCode.trim().isNotEmpty) {
          setState(() {
            _preferredNodeCode = result.preferredNodeCode.trim().toLowerCase();
          });
        }
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_brand('Локация сохранена. Переподключите POKROV.')),
        ),
      );
    } on BootstrapFailure catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _nodePreferenceBusy = false;
        });
      }
    }
  }

  void _addSelectedAppId(String value) {
    final normalized = _normalizeSelectedAppIdentifier(value);
    if (normalized == null || _selectedAppIds.contains(normalized)) {
      return;
    }
    setState(() {
      _selectedAppIds.add(normalized);
      if (widget.appContext.runtimeProfile.supportedRouteModes
          .contains(RouteMode.selectedApps)) {
        _selectedRouteMode = RouteMode.selectedApps;
      }
      _managedProfileDirty = true;
    });
  }

  void _removeSelectedAppId(String value) {
    setState(() {
      _selectedAppIds.remove(value);
      _managedProfileDirty = true;
    });
  }

  void _selectTab(SeedTab tab) {
    setState(() {
      _selectedIndex = tab.index;
    });
    if (tab == SeedTab.profile && widget.bootstrapper != null) {
      unawaited(_loadBonusSummary());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _communitySubscriptionRefreshTimer?.cancel();
    _firstLaunchRestoreCodeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_runtimeBusy) {
      _ensureCommunitySubscriptionRefreshTimer();
      unawaited(_refreshRuntimeSnapshot());
      unawaited(_checkForClientUpdate());
      unawaited(_refreshCommunitySubscriptionsIfDue(quiet: true));
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _communitySubscriptionRefreshTimer?.cancel();
      _communitySubscriptionRefreshTimer = null;
    }
  }

  bool get _communitySubscriptionAutoRefreshEnabled =>
      !widget.appContext.variantProfile.usesApiServices &&
      widget.communitySubscriptionAutoRefreshInterval > Duration.zero &&
      widget.communitySubscriptionStaleAfter >= Duration.zero;

  void _ensureCommunitySubscriptionRefreshTimer() {
    if (!_communitySubscriptionAutoRefreshEnabled ||
        _communitySubscriptionRefreshTimer != null) {
      return;
    }
    _communitySubscriptionRefreshTimer = Timer.periodic(
      widget.communitySubscriptionAutoRefreshInterval,
      (_) => unawaited(_refreshCommunitySubscriptionsIfDue(quiet: true)),
    );
  }

  Future<bool> _launchExternalHandoff(Uri uri) {
    final launcher = widget.handoffLauncher ??
        (Uri target) => launchUrl(
              target,
              mode: LaunchMode.externalApplication,
            );
    return launcher(uri);
  }

  Future<void> _checkForClientUpdate() async {
    final releaseActions = _releaseActionService;
    if (releaseActions == null ||
        _clientUpdateCheckBusy ||
        _clientUpdatePromptVisible) {
      return;
    }
    _clientUpdateCheckBusy = true;
    try {
      final metadata = await releaseActions.fetchClientApps(
        hostPlatform: widget.appContext.hostPlatform,
        currentVersion: _pokrovAppVersion,
      );
      if (!mounted || metadata.silentUpdate) {
        return;
      }
      final update = metadata.updateFor(widget.appContext.hostPlatform);
      final promptKey =
          '${update.platform}:${update.latestVersion}:${update.updatePolicy}';
      if (!update.shouldPrompt || promptKey == _lastPromptedUpdateKey) {
        return;
      }
      _lastPromptedUpdateKey = promptKey;
      await _showClientUpdatePrompt(update);
    } catch (_) {
      // Update checks are advisory; never block the app on startup.
    } finally {
      _clientUpdateCheckBusy = false;
    }
  }

  Future<void> _showClientUpdatePrompt(ClientAppUpdateInfo update) async {
    if (!mounted || _clientUpdatePromptVisible) {
      return;
    }
    _clientUpdatePromptVisible = true;
    final title = update.isRequired
        ? _brand('Нужно обновить POKROV')
        : 'Доступно обновление';
    final version = update.latestVersion.trim();
    final notes = update.releaseNotes.trim();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !update.isRequired,
        builder: (dialogContext) {
          return AlertDialog(
            key: const ValueKey('client-update-prompt'),
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  version.isEmpty
                      ? 'Установите свежую сборку, чтобы получить исправления и актуальные правила.'
                      : 'Свежая версия: $version.',
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(notes),
                ],
              ],
            ),
            actions: [
              if (!update.isRequired)
                TextButton(
                  key: const ValueKey('client-update-later'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Позже'),
                ),
              FilledButton(
                key: const ValueKey('client-update-download'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  unawaited(_openSafeHandoff('download', update.url));
                },
                child: const Text('Скачать'),
              ),
            ],
          );
        },
      );
    } finally {
      _clientUpdatePromptVisible = false;
    }
  }

  Future<void> _openSafeHandoff(String label, String value) async {
    final uri = _safeHandoffUri(
      label: label,
      value: value,
      cabinetUrl: widget.appContext.cabinetUrl,
    );
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала введите код активации.')),
      );
      return;
    }

    final opened = await _launchExternalHandoff(uri);
    if (!mounted) {
      return;
    }
    if (!opened) {
      final fallback = _safeHandoffFallbackUri(
        label: label,
        value: value,
      );
      if (fallback != null && fallback != uri) {
        final fallbackOpened = await _launchExternalHandoff(fallback);
        if (!mounted) {
          return;
        }
        if (fallbackOpened) {
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть: $uri')),
      );
    }
  }

  Future<bool> _redeemCodeInApp(String value) async {
    final code = value.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.appContext.variantProfile.usesApiServices
                ? 'Введите код активации.'
                : 'Вставьте одиночный ключ.',
          ),
        ),
      );
      return false;
    }
    if (!widget.appContext.variantProfile.usesApiServices) {
      return _importCommunityProfile(code);
    }
    if (_looksLikeSubscriptionOrProxyLink(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ссылка подключения не привязывает аккаунт. Введите одноразовый код или ключ активации.',
          ),
        ),
      );
      return false;
    }

    final accountActions = _accountActionService;
    if (accountActions == null) {
      await _openSafeHandoff('redeem', code);
      return false;
    }

    try {
      HapticFeedback.selectionClick();
      final result = await accountActions.redeemCode(
        hostPlatform: widget.appContext.hostPlatform,
        code: code,
      );
      if (!mounted) {
        return true;
      }
      final updatesAccess =
          result.kind == 'access_key' || result.kind == 'gift';
      setState(() {
        _managedProfileDirty = true;
        _runtimeHeadline = updatesAccess
            ? 'Код активирован. Доступ обновлен.'
            : 'Код обработан.';
      });
      final confirmationText = _runtimeHeadline ?? '';
      unawaited(_loadBonusSummary(force: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmationText),
        ),
      );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось активировать код: $error')),
      );
      return false;
    }
  }

  Future<bool> _importCommunityProfile(String value) async {
    final importer = _localProfileBootstrapper;
    if (importer == null) {
      return false;
    }
    try {
      final uri = Uri.tryParse(value.trim());
      if (uri != null &&
          (uri.scheme.toLowerCase() == 'http' ||
              uri.scheme.toLowerCase() == 'https')) {
        return _importCommunitySubscriptionUrl(uri);
      }
      final imported = _CommunityProfileImporter.parse(
        value,
        routeMode: _selectedRouteMode,
      );
      HapticFeedback.selectionClick();
      final optimisticState = _communityProfileState.upsertAll(
        [imported.record],
      );
      setState(() {
        _communityProfileRevision += 1;
        _communityProfileState = optimisticState;
        _managedProfileDirty = true;
        _runtimeHeadline =
            'Profile imported: ${imported.displayName}. Tap Connect to apply it.';
      });
      final savedState = await importer.saveState(optimisticState);
      if (!mounted) {
        return true;
      }
      setState(() {
        _communityProfileState = savedState;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${imported.displayName}. Tap Connect.'),
        ),
      );
      return true;
    } on _CommunityProfileImportFailure catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not import this key. Check the format.'),
        ),
      );
      return false;
    }
  }

  Future<bool> _importCommunitySubscriptionUrl(Uri uri) async {
    final importer = _localProfileBootstrapper;
    if (importer == null) {
      return false;
    }
    try {
      final fetcher =
          widget.communitySubscriptionFetcher ?? _fetchCommunitySubscription;
      final body = await fetcher(uri);
      final imported = _CommunityProfileImporter.parseMany(
        body,
        routeMode: _selectedRouteMode,
        sourceKind: 'subscription_url',
      );
      final fetchedAt = DateTime.now().toUtc().toIso8601String();
      final records = imported
          .map(
            (result) => result.record.copyWith(
              sourceUrl: uri.toString(),
              lastFetchedAt: fetchedAt,
              lastRefreshStatus: 'ok',
              refreshError: '',
              entryCount: imported.length,
            ),
          )
          .toList();
      final optimisticState = _communityProfileState.upsertAll(records);
      HapticFeedback.selectionClick();
      setState(() {
        _communityProfileRevision += 1;
        _communityProfileState = optimisticState;
        _managedProfileDirty = true;
        _runtimeHeadline =
            'Subscription imported ${records.length} profile${records.length == 1 ? '' : 's'}. Tap Connect to apply.';
      });
      final savedState = await importer.saveState(optimisticState);
      if (!mounted) {
        return true;
      }
      setState(() {
        _communityProfileState = savedState;
      });
      _ensureCommunitySubscriptionRefreshTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${records.length} subscription profile(s).'),
        ),
      );
      return true;
    } on _CommunityProfileImportFailure catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not refresh this subscription URL.'),
        ),
      );
      return false;
    }
  }

  Future<void> _refreshCommunitySubscriptionsIfDue({
    bool quiet = false,
  }) async {
    if (!_communitySubscriptionRefreshDue(DateTime.now().toUtc())) {
      return;
    }
    await _refreshCommunitySubscriptions(quiet: quiet);
  }

  bool _communitySubscriptionRefreshDue(DateTime now) {
    final sourceUrls = _communityProfileState.subscriptionSourceUrls;
    if (sourceUrls.isEmpty) {
      return false;
    }
    if (widget.communitySubscriptionStaleAfter <= Duration.zero) {
      return true;
    }
    for (final sourceUrl in sourceUrls) {
      final profiles = _communityProfileState.profiles
          .where((profile) => profile.sourceUrl == sourceUrl)
          .toList(growable: false);
      if (profiles.isEmpty) {
        return true;
      }
      if (profiles.any((profile) => profile.lastRefreshStatus == 'failed')) {
        return true;
      }
      final fetchedAt = profiles
          .map((profile) => DateTime.tryParse(profile.lastFetchedAt))
          .whereType<DateTime>()
          .fold<DateTime?>(null, (latest, value) {
        final utc = value.toUtc();
        return latest == null || utc.isAfter(latest) ? utc : latest;
      });
      if (fetchedAt == null) {
        return true;
      }
      final age = now.difference(fetchedAt);
      if (!age.isNegative && age >= widget.communitySubscriptionStaleAfter) {
        return true;
      }
    }
    return false;
  }

  Future<void> _refreshCommunitySubscriptions({bool quiet = false}) async {
    final importer = _localProfileBootstrapper;
    if (importer == null || _communitySubscriptionRefreshInFlight) {
      return;
    }
    final sourceUrls = _communityProfileState.subscriptionSourceUrls;
    if (sourceUrls.isEmpty) {
      return;
    }
    _communitySubscriptionRefreshInFlight = true;
    final fetcher =
        widget.communitySubscriptionFetcher ?? _fetchCommunitySubscription;
    try {
      var nextState = _communityProfileState;
      var refreshed = 0;
      var failed = 0;
      for (final sourceUrl in sourceUrls) {
        try {
          final uri = Uri.parse(sourceUrl);
          final body = await fetcher(uri);
          final imported = _CommunityProfileImporter.parseMany(
            body,
            routeMode: _selectedRouteMode,
            sourceKind: 'subscription_url',
          );
          final fetchedAt = DateTime.now().toUtc().toIso8601String();
          final records = imported
              .map(
                (result) => result.record.copyWith(
                  sourceUrl: sourceUrl,
                  lastFetchedAt: fetchedAt,
                  lastRefreshStatus: 'ok',
                  refreshError: '',
                  entryCount: imported.length,
                ),
              )
              .toList();
          nextState = nextState.upsertAll(
            records,
            activeProfileName: nextState.activeProfileName,
          );
          refreshed += records.length;
        } catch (_) {
          failed += 1;
          nextState = nextState.markSubscriptionRefreshFailed(
            sourceUrl,
            'Refresh failed. Keeping the last local profiles.',
          );
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _communityProfileRevision += 1;
        _communityProfileState = nextState;
        _managedProfileDirty = refreshed > 0 || _managedProfileDirty;
        if (!quiet) {
          _runtimeHeadline = failed == 0
              ? 'Subscription refresh updated $refreshed profile${refreshed == 1 ? '' : 's'}.'
              : 'Some subscriptions could not refresh. Last working profiles were kept.';
        }
      });
      final savedState = await importer.saveState(nextState);
      if (!mounted) {
        return;
      }
      setState(() {
        _communityProfileState = savedState;
      });
      if (!quiet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failed == 0
                  ? 'Subscription refresh updated $refreshed profile(s).'
                  : 'Could not refresh this subscription URL.',
            ),
          ),
        );
      }
    } finally {
      _communitySubscriptionRefreshInFlight = false;
    }
  }

  Future<void> _scanCommunityQr(BuildContext context) async {
    final scanner = widget.communityQrScanner;
    if (scanner == null) {
      return;
    }
    try {
      final scanned = await scanner(context);
      if (!mounted || scanned == null || scanned.trim().isEmpty) {
        return;
      }
      await _importCommunityProfile(scanned);
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read this QR code.'),
        ),
      );
    }
  }

  Future<String> _fetchCommunitySubscription(Uri uri) async {
    if (uri.scheme.toLowerCase() != 'https' &&
        uri.host != 'localhost' &&
        uri.host != '127.0.0.1') {
      throw const _CommunityProfileImportFailure(
        'Use HTTPS subscription URLs, or localhost for development.',
      );
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 10),
          );
      request.headers.set(HttpHeaders.acceptHeader, 'text/plain,*/*');
      final response = await request.close().timeout(
            const Duration(seconds: 12),
          );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _CommunityProfileImportFailure(
          'Subscription returned HTTP ${response.statusCode}.',
        );
      }
      final chunks = <int>[];
      await for (final chunk in response) {
        chunks.addAll(chunk);
        if (chunks.length > 512 * 1024) {
          throw const _CommunityProfileImportFailure(
            'Subscription is too large for local import.',
          );
        }
      }
      return utf8.decode(chunks, allowMalformed: false);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _loadCommunityProfile() async {
    final importer = _localProfileBootstrapper;
    if (importer == null) {
      return;
    }
    final revision = _communityProfileRevision;
    final state = await importer.loadImportedState();
    if (!mounted || revision != _communityProfileRevision) {
      return;
    }
    setState(() {
      _communityProfileState = state;
    });
  }

  Future<void> _activateCommunityProfile(String profileName) async {
    final importer = _localProfileBootstrapper;
    if (importer == null) {
      return;
    }
    HapticFeedback.selectionClick();
    final optimisticState = _communityProfileState.setActive(profileName);
    setState(() {
      _communityProfileRevision += 1;
      _communityProfileState = optimisticState;
      _managedProfileDirty = true;
      _runtimeHeadline = 'Profile selected. Tap Connect to apply it.';
    });
    final savedState = await importer.saveState(optimisticState);
    if (!mounted) {
      return;
    }
    setState(() {
      _communityProfileState = savedState;
    });
  }

  Future<void> _removeCommunityProfile(String profileName) async {
    final importer = _localProfileBootstrapper;
    if (importer == null) {
      return;
    }
    HapticFeedback.selectionClick();
    final optimisticState = _communityProfileState.remove(profileName);
    setState(() {
      _communityProfileRevision += 1;
      _communityProfileState = optimisticState;
      _managedProfileDirty = true;
      _runtimeHeadline = optimisticState.profiles.isEmpty
          ? 'Local profile removed. Add a key to connect.'
          : 'Profile removed. Tap Connect to apply the active profile.';
    });
    final savedState = await importer.saveState(optimisticState);
    if (!mounted) {
      return;
    }
    setState(() {
      _communityProfileState = savedState;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local profile removed.')),
    );
  }

  bool _looksLikeSubscriptionOrProxyLink(String value) {
    final text = value.trim().toLowerCase();
    if (text.isEmpty) {
      return false;
    }
    final parsed = Uri.tryParse(text);
    if (parsed != null && parsed.hasScheme) {
      final scheme = parsed.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') {
        final host = parsed.host.toLowerCase();
        final path = parsed.path.toLowerCase();
        return host == 'connect.pokrov.space' ||
            host.endsWith('.pokrov.space') && path.contains('s8kx2mp7qr4wt') ||
            path.contains('subscription') ||
            path.contains('/sub/') ||
            path.contains('/config/');
      }
      return const <String>{
        'vless',
        'vmess',
        'trojan',
        'ss',
        'socks',
        'wireguard',
        'hysteria2',
        'tuic',
      }.contains(scheme);
    }
    return text.contains('subscription_url=') ||
        text.contains('vless://') ||
        text.contains('vmess://') ||
        text.contains('trojan://');
  }

  Future<void> _openCabinetWithHandoff(String value) async {
    final accountActions = _accountActionService;
    if (accountActions == null) {
      await _openSafeHandoff('cabinet', value);
      return;
    }

    try {
      final handoff = await accountActions.createCabinetHandoff(
        hostPlatform: widget.appContext.hostPlatform,
        targetPath: _cabinetTargetPathFromValue(value),
      );
      final opened = await _launchExternalHandoff(handoff.handoffUrl);
      if (!mounted || opened) {
        return;
      }
      await _openSafeHandoff('cabinet', value);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final fallback = _safeHandoffUri(
        label: 'cabinet',
        value: value,
        cabinetUrl: widget.appContext.cabinetUrl,
      );
      if (fallback != null && await _launchExternalHandoff(fallback)) {
        return;
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть кабинет: $error')),
      );
    }
  }

  Future<void> _createTelegramLinkInApp() async {
    final bonusActions = _bonusActionService;
    if (bonusActions == null) {
      await _openSafeHandoff(
        'community',
        widget.appContext.supportSnapshot.publicChannel,
      );
      return;
    }

    setState(() {
      _telegramBonusBusy = true;
      _telegramBonusError = null;
    });
    try {
      HapticFeedback.selectionClick();
      final result = await bonusActions.createTelegramLink(
        hostPlatform: widget.appContext.hostPlatform,
      );
      final opened = await _launchExternalHandoff(result.botUrl);
      if (!mounted) {
        return;
      }
      setState(() {
        _telegramBonusBusy = false;
        _telegramBonusStatus =
            result.linked ? 'Telegram привязан' : 'Код открыт в Telegram';
        if (!opened) {
          _telegramBonusError = 'Не удалось открыть Telegram автоматически.';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _telegramBonusBusy = false;
        _telegramBonusError = 'Не удалось получить код: $error';
      });
    }
  }

  Future<void> _checkTelegramBonusInApp() async {
    final bonusActions = _bonusActionService;
    if (bonusActions == null) {
      await _openSafeHandoff(
        'community',
        widget.appContext.supportSnapshot.publicChannel,
      );
      return;
    }

    setState(() {
      _telegramBonusBusy = true;
      _telegramBonusError = null;
    });
    try {
      HapticFeedback.selectionClick();
      final status = await bonusActions.checkChannelBonus(
        hostPlatform: widget.appContext.hostPlatform,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _telegramBonusBusy = false;
        _telegramBonusCanClaim = status.claimRequired;
        _telegramBonusStatus = _telegramBonusStatusForStatus(status);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _telegramBonusBusy = false;
        _telegramBonusError = 'Не удалось проверить бонус: $error';
      });
    }
  }

  Future<void> _claimTelegramBonusInApp() async {
    final bonusActions = _bonusActionService;
    if (bonusActions == null || !_telegramBonusCanClaim) {
      await _checkTelegramBonusInApp();
      return;
    }

    setState(() {
      _telegramBonusBusy = true;
      _telegramBonusError = null;
    });
    try {
      HapticFeedback.selectionClick();
      final result = await bonusActions.claimChannelBonus(
        hostPlatform: widget.appContext.hostPlatform,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _telegramBonusBusy = false;
        _telegramBonusCanClaim = false;
        _telegramBonusStatus = result.alreadyClaimed
            ? '+${result.premiumDays} дней уже активированы'
            : '+${result.premiumDays} дней активированы';
        _managedProfileDirty = true;
        _runtimeHeadline = 'Telegram-бонус активирован.';
      });
      unawaited(_loadBonusSummary(force: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+${result.premiumDays} дней добавлены к доступу.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _telegramBonusBusy = false;
        _telegramBonusError = 'Не удалось активировать бонус: $error';
      });
    }
  }

  Future<void> _loadBonusSummary({bool force = false}) async {
    if (_bonusSummaryBusy) {
      return;
    }
    if (!force && _bonusSummaryRequested) {
      return;
    }

    final bonusActions = _bonusActionService;
    if (bonusActions == null) {
      setState(() {
        _bonusSummaryRequested = true;
        _bonusSummaryError = null;
      });
      return;
    }

    setState(() {
      _bonusSummaryBusy = true;
      _bonusSummaryRequested = true;
      _bonusSummaryError = null;
    });
    try {
      if (force) {
        HapticFeedback.selectionClick();
      }
      final summary = await bonusActions.fetchBonusSummary(
        hostPlatform: widget.appContext.hostPlatform,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bonusSummary = summary;
        _bonusSummaryBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bonusSummaryBusy = false;
        _bonusSummaryError = 'Не удалось обновить сводку: $error';
      });
    }
  }

  Future<void> _spinBonusWheelInApp() async {
    await _runBonusRewardInApp(
      actionName: 'Рулетка',
      run: (service) => service.spinBonusWheel(
        hostPlatform: widget.appContext.hostPlatform,
      ),
    );
  }

  Future<void> _checkInBonusCalendarInApp() async {
    await _runBonusRewardInApp(
      actionName: 'Календарь',
      run: (service) => service.checkInBonusCalendar(
        hostPlatform: widget.appContext.hostPlatform,
      ),
    );
  }

  Future<void> _runBonusRewardInApp({
    required String actionName,
    required Future<AppFirstBonusRewardResult> Function(
      AppFirstBonusActionService service,
    ) run,
  }) async {
    if (_bonusRewardBusy) {
      return;
    }
    final bonusActions = _bonusActionService;
    if (bonusActions == null) {
      await _loadBonusSummary(force: true);
      return;
    }

    setState(() {
      _bonusRewardBusy = true;
      _bonusSummaryError = null;
    });
    try {
      HapticFeedback.selectionClick();
      final result = await run(bonusActions);
      if (!mounted) {
        return;
      }
      setState(() {
        _bonusRewardBusy = false;
        _bonusSummary = result.summary;
        _managedProfileDirty = true;
        _runtimeHeadline = '$actionName: награда активирована.';
      });
      HapticFeedback.heavyImpact();
      final days = result.rewardDays;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            days > 0
                ? '$actionName: +$days дн. добавлены.'
                : '$actionName: отметка сохранена.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bonusRewardBusy = false;
        _bonusSummaryError = 'Не удалось выполнить действие: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось выполнить действие: $error')),
      );
    }
  }

  String _telegramBonusStatusForStatus(ChannelBonusStatus status) {
    if (status.alreadyClaimed) {
      return '+${status.bonusDays} дней активированы';
    }
    if (status.claimRequired) {
      return '+${status.bonusDays} дней готовы';
    }
    if (status.linkRequired) {
      return 'Сначала привяжите Telegram';
    }
    if (!status.subscriber) {
      return 'Подпишитесь и проверьте';
    }
    return 'Проверено';
  }

  String _cabinetTargetPathFromValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '/';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return '/';
    }
    if (uri.path.isEmpty) {
      return '/';
    }
    if (uri.query.isEmpty) {
      return uri.path;
    }
    return '${uri.path}?${uri.query}';
  }

  void _showSeedHandoff(String label, String value) {
    switch (label) {
      case 'redeem':
        unawaited(_redeemCodeInApp(value));
        return;
      case 'cabinet':
        unawaited(_openCabinetWithHandoff(value));
        return;
      default:
        unawaited(_openSafeHandoff(label, value));
        return;
    }
  }

  Future<void> _loadFirstLaunchState() async {
    var completed = false;
    try {
      completed = await _firstLaunchStore.isCompleted();
    } catch (_) {
      completed = false;
    }
    if (!mounted || !completed) {
      return;
    }
    setState(() {
      _firstLaunchStep = _FirstLaunchStep.ready;
    });
  }

  Future<void> _markFirstLaunchCompleted() async {
    try {
      await _firstLaunchStore.markCompleted();
    } catch (_) {
      // Local persistence is best-effort; access must not be blocked by it.
    }
  }

  void _completeFirstLaunchAsNewUser() {
    HapticFeedback.selectionClick();
    unawaited(_markFirstLaunchCompleted());
    setState(() {
      _firstLaunchStep = _FirstLaunchStep.ready;
    });
  }

  Future<void> _toggleRuntimeFromHome() async {
    if (_firstLaunchStep != _FirstLaunchStep.ready) {
      _completeFirstLaunchAsNewUser();
    }
    await _toggleRuntime();
  }

  void _openFirstLaunchRestore() {
    HapticFeedback.selectionClick();
    setState(() {
      _firstLaunchStep = _FirstLaunchStep.restore;
    });
  }

  void _backToFirstLaunchChoice() {
    setState(() {
      _firstLaunchStep = _FirstLaunchStep.choice;
    });
  }

  Future<void> _redeemFirstLaunchRestoreCode() async {
    if (_firstLaunchBusy) {
      return;
    }
    setState(() {
      _firstLaunchBusy = true;
    });
    final ok = await _redeemCodeInApp(
      _firstLaunchRestoreCodeController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _firstLaunchBusy = false;
      if (ok) {
        unawaited(_markFirstLaunchCompleted());
        _firstLaunchStep = _FirstLaunchStep.ready;
      }
    });
  }

  Future<void> _showSupportHub() {
    HapticFeedback.selectionClick();
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) {
          return _SupportChatScreen(
            appContext: widget.appContext,
            selectedRouteMode: _selectedRouteMode,
            statusLabel: _consumerProtectionStatusLabel(
              _runtimeSnapshot,
              busy: _runtimeBusy,
            ),
            extraDiagnostics: _extendedProtectionDiagnostics(),
            supportTicketService: _supportTicketService,
            onOpenHandoff: _showSeedHandoff,
          );
        },
      ),
    );
  }

  Map<String, Object?> _extendedProtectionDiagnostics() {
    return PokrovWarpSupportDiagnostics.fromLifecycle(
      PokrovWarpLifecycle.resolve(
        policy: _managedWarpPolicy,
        consented: _warpRuntimeConsent,
        busy: _warpPolicyBusy,
        lastError: _runtimeSnapshot?.lastFailureKind ?? '',
      ),
    ).toJson();
  }

  Uri? _safeHandoffUri({
    required String label,
    required String value,
    required String cabinetUrl,
  }) {
    final trimmed = value.trim();
    switch (label) {
      case 'checkout':
      case 'cabinet':
      case 'download':
        return Uri.tryParse(trimmed);
      case 'redeem':
        if (trimmed.isEmpty) {
          return null;
        }
        return Uri.parse(cabinetUrl).replace(
          path: '/redeem',
          queryParameters: <String, String>{'code': trimmed},
        );
      case 'community':
      case 'support':
      case 'feedback':
        final handle = trimmed.replaceFirst('@', '');
        if (handle.isEmpty) {
          return null;
        }
        return Uri(
          scheme: 'tg',
          host: 'resolve',
          queryParameters: <String, String>{'domain': handle},
        );
      default:
        return Uri.tryParse(trimmed);
    }
  }

  Uri? _safeHandoffFallbackUri({
    required String label,
    required String value,
  }) {
    final trimmed = value.trim();
    switch (label) {
      case 'community':
      case 'support':
      case 'feedback':
        final handle = trimmed.replaceFirst('@', '');
        if (handle.isEmpty) {
          return null;
        }
        return Uri.https('t.me', '/$handle');
      default:
        return null;
    }
  }

  Future<RuntimeSnapshot> _runRuntimeAction(
    Future<RuntimeSnapshot> Function() action,
  ) async {
    setState(() {
      _runtimeBusy = true;
    });

    try {
      final snapshot = await action();
      if (!mounted) {
        return snapshot;
      }

      setState(() {
        _runtimeSnapshot = snapshot;
        _runtimeHeadline = null;
      });
      return snapshot;
    } finally {
      if (mounted) {
        setState(() {
          _runtimeBusy = false;
        });
      }
    }
  }

  Future<void> _refreshRuntimeSnapshot() async {
    await _runRuntimeAction(_runtimeEngine.snapshot);
  }

  Future<T> _withRuntimeActionTimeout<T>(
    String operation,
    Future<T> Function() action,
  ) {
    return action().timeout(
      widget.runtimeActionTimeout,
      onTimeout: () => throw TimeoutException(
        'runtime action timed out: $operation',
        widget.runtimeActionTimeout,
      ),
    );
  }

  Future<ManagedProfilePayload> _resolveManagedProfile() async {
    final profileRevision = _communityProfileRevision;
    final payload = await _bootstrapper.resolveManagedProfile(
      hostPlatform: widget.appContext.hostPlatform,
      routeMode: _selectedRouteMode,
      selectedApps: _selectedRouteMode == RouteMode.selectedApps
          ? _selectedAppIds
          : const <String>[],
    );
    final warpStatus = await _fetchWarpStatusOrNull();
    final displayWarpPolicy =
        warpStatus?.applyTo(payload.warpPolicy) ?? payload.warpPolicy;
    final warpConsentStillValid =
        (warpStatus?.consented ?? _warpRuntimeConsent) &&
            displayWarpPolicy.canOfferRuntime;
    final runtimePayload = payload.copyWith(
      warpPolicy: displayWarpPolicy.withUserConsent(warpConsentStillValid),
    );
    if (mounted) {
      setState(() {
        if (profileRevision == _communityProfileRevision) {
          _managedProfileDirty = false;
        }
        _managedWarpPolicy = displayWarpPolicy;
        _warpRuntimeConsent = warpConsentStillValid;
        _smartConnectProfile = payload.smartConnect;
        _preferredNodeCode =
            payload.smartConnect?.stickiness.preferredNodeCode.trim() ?? '';
        _runtimeHeadline = widget.appContext.variantProfile.usesApiServices
            ? 'Настройки обновлены с ${Uri.parse(widget.appContext.apiBaseUrl).host}.'
            : 'Local profile is ready on this device.';
      });
    }
    return runtimePayload;
  }

  Future<WarpControlStatus?> _fetchWarpStatusOrNull() async {
    final service = _warpActionService;
    if (service == null) {
      return null;
    }
    try {
      return await service.fetchWarpStatus(
        hostPlatform: widget.appContext.hostPlatform,
      );
    } on BootstrapFailure catch (error) {
      if (mounted && error.statusCode != null) {
        setState(() {
          _runtimeHeadline = error.message;
        });
      }
      return null;
    }
  }

  Future<void> _openWarpControl() async {
    if (_warpPolicyBusy) {
      return;
    }

    var policy = _managedWarpPolicy;
    if (!policy.canOfferRuntime) {
      setState(() {
        _warpPolicyBusy = true;
      });
      try {
        await _resolveManagedProfile();
        policy = _managedWarpPolicy;
      } on BootstrapFailure catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _runtimeHeadline = error.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
        return;
      } finally {
        if (mounted) {
          setState(() {
            _warpPolicyBusy = false;
          });
        }
      }
    }

    if (!mounted) {
      return;
    }

    if (!policy.canOfferRuntime) {
      _showInfoSheet(
        context,
        title: 'Расширенная приватность',
        lines: const [
          'Дополнительный режим пока готовится для этого устройства.',
          'Когда backend пришлет проверенную конфигурацию, здесь появится отдельное включение.',
        ],
      );
      return;
    }

    _showWarpConsentSheet(
      context,
      lifecycle: PokrovWarpLifecycle.resolve(
        policy: _managedWarpPolicy,
        consented: _warpRuntimeConsent,
        busy: _warpPolicyBusy,
      ),
      enabled: _warpRuntimeConsent,
      onChanged: _setWarpRuntimeConsent,
    );
  }

  Future<void> _setWarpRuntimeConsent(bool value) async {
    if (_warpPolicyBusy) {
      return;
    }
    final requestedEnabled = value && _managedWarpPolicy.canOfferRuntime;
    HapticFeedback.selectionClick();
    setState(() {
      _warpPolicyBusy = true;
    });
    try {
      final service = _warpActionService;
      final status = service == null
          ? WarpControlStatus.fromPolicy(_managedWarpPolicy).copyWith(
              consented: requestedEnabled,
              canEnable: !requestedEnabled,
              state: requestedEnabled ? 'consented' : 'revoked',
            )
          : await service.setWarpConsent(
              hostPlatform: widget.appContext.hostPlatform,
              enabled: requestedEnabled,
              reasonCode: requestedEnabled ? 'user_consented' : 'user_disabled',
            );
      final servicePolicy = status.applyTo(_managedWarpPolicy);
      final nextPolicy = requestedEnabled
          ? servicePolicy
          : WarpRuntimePolicy.disabled.copyWith(
              state: status.state.isEmpty ? 'revoked' : status.state,
              mode: servicePolicy.mode,
              source: servicePolicy.source,
            );
      final enabled =
          requestedEnabled && status.consented && nextPolicy.canOfferRuntime;
      if (!mounted) {
        return;
      }
      setState(() {
        _managedWarpPolicy = nextPolicy;
        _warpRuntimeConsent = enabled;
        _managedProfileDirty = true;
        _runtimeHeadline = enabled
            ? 'Расширенная защита включится при следующем подключении.'
            : 'Расширенная защита выключена для следующих подключений.';
      });
    } on BootstrapFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _runtimeHeadline = error.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _warpPolicyBusy = false;
        });
      }
    }
  }

  Future<void> _toggleRuntime() async {
    if (_runtimeBusy) {
      setState(() {
        _runtimeHeadline = _brand('POKROV уже обновляется. Подождите немного.');
      });
      return;
    }

    setState(() {
      _runtimeBusy = true;
    });

    try {
      final RuntimeSnapshot snapshot = _runtimeSnapshot ??
          await _withRuntimeActionTimeout(
            'snapshot',
            _runtimeEngine.snapshot,
          );
      if (!mounted) {
        return;
      }

      if (snapshot.phase == RuntimePhase.running) {
        var current = await _withRuntimeActionTimeout(
          'disconnect',
          _runtimeEngine.disconnect,
        );
        current = await _settleRuntimeDisconnectTransition(current);
        if (!mounted) {
          return;
        }
        setState(() {
          _runtimeSnapshot = current;
          _runtimeHeadline = current.message;
        });
        return;
      }

      if (!_canPrimaryConnect(snapshot)) {
        setState(() {
          _runtimeHeadline =
              'На этом устройстве еще нужно завершить подготовку.';
        });
        return;
      }

      RuntimeSnapshot current = snapshot;

      if (current.canInitialize &&
          current.phase == RuntimePhase.artifactReady) {
        current = await _withRuntimeActionTimeout(
          'initialize',
          _runtimeEngine.initialize,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _runtimeSnapshot = current;
          _runtimeHeadline = null;
        });
      }

      final shouldRefreshManagedProfile =
          _managedProfileDirty || (current.stagedConfigPath ?? '').isEmpty;
      if (shouldRefreshManagedProfile) {
        final managedProfile = await _resolveManagedProfile();
        current = await _withRuntimeActionTimeout(
          'stageManagedProfile',
          () => _runtimeEngine.stageManagedProfile(managedProfile),
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _runtimeSnapshot = current;
          _runtimeHeadline = null;
        });
      }

      if ((current.stagedConfigPath ?? '').isNotEmpty || current.canConnect) {
        current = await _withRuntimeActionTimeout(
          'connect',
          _runtimeEngine.connect,
        );
        current = await _settleRuntimeTransition(current);
        if (!mounted) {
          return;
        }
        setState(() {
          _runtimeSnapshot = current;
          _runtimeHeadline = current.phase == RuntimePhase.running
              ? current.isCleanlyHealthy
                  ? _brand('POKROV включен.')
                  : _brand('POKROV включен, но требует внимания.')
              : current.message;
        });
        if (current.phase != RuntimePhase.running &&
            current.message.trim().isNotEmpty) {
          unawaited(_reportWarpRuntimeFallback(current));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(current.message)),
          );
        }
      }
    } on BootstrapFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _runtimeHeadline = error.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final message = _runtimeUnexpectedErrorMessage(error);
      setState(() {
        _runtimeHeadline = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _runtimeBusy = false;
        });
      }
    }
  }

  String _runtimeUnexpectedErrorMessage(Object error) {
    final rawDetail = switch (error) {
      TimeoutException() =>
        'системный модуль не ответил вовремя. Попробуйте еще раз или откройте поддержку.',
      PlatformException(:final message, :final code) =>
        (message?.trim().isNotEmpty == true ? message!.trim() : code),
      _ => error.toString().trim(),
    };
    final normalizedDetail = rawDetail.replaceFirst('Bad state: ', '').trim();
    final detail = normalizedDetail.length > 180
        ? '${normalizedDetail.substring(0, 180)}...'
        : normalizedDetail;
    if (detail.isEmpty) {
      return _brand(
        'POKROV не смог начать подключение. Откройте поддержку и приложите диагностику.',
      );
    }
    return _brand('POKROV не смог начать подключение: $detail');
  }

  Future<void> _reportWarpRuntimeFallback(RuntimeSnapshot snapshot) async {
    final service = _warpActionService;
    if (service == null ||
        !_warpRuntimeConsent ||
        !_managedWarpPolicy.canOfferRuntime) {
      return;
    }
    try {
      final failureKind = snapshot.lastFailureKind?.trim() ?? '';
      final diagnosticsSummary = snapshot.hostDiagnosticsSummary?.trim() ?? '';
      final status = await service.reportWarpRuntimeEvent(
        hostPlatform: widget.appContext.hostPlatform,
        eventName: 'runtime_fallback',
        state: 'fallback',
        reasonCode:
            failureKind.isNotEmpty ? failureKind : 'connect_not_running',
        message: snapshot.message,
        meta: <String, Object?>{
          'phase': snapshot.phase.name,
          'lane': snapshot.lane.name,
          'host_health': snapshot.hostHealth.name,
          'dns_state': snapshot.dnsState.name,
          'uplink_state': snapshot.uplinkState.name,
          if (diagnosticsSummary.isNotEmpty)
            'host_diagnostics_summary': diagnosticsSummary,
        },
      );
      if (!mounted) {
        return;
      }
      final nextPolicy = status.applyTo(_managedWarpPolicy);
      setState(() {
        _managedWarpPolicy = nextPolicy;
        _warpRuntimeConsent = status.consented && nextPolicy.canOfferRuntime;
      });
    } on BootstrapFailure {
      // Runtime fallback telemetry must never block the user's connect flow.
    }
  }

  Future<RuntimeSnapshot> _settleRuntimeTransition(
    RuntimeSnapshot snapshot,
  ) async {
    if (snapshot.phase == RuntimePhase.running ||
        !snapshot.supportsLiveConnect ||
        _isTerminalConnectMessage(snapshot.message)) {
      return snapshot;
    }

    var current = snapshot;
    final maxAttempts = current.message.toLowerCase().contains(
              'permission requested',
            )
        ? 40
        : 10;
    for (var attempt = 0; attempt < maxAttempts; attempt += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      current = await _withRuntimeActionTimeout(
        'settleSnapshot',
        _runtimeEngine.snapshot,
      );
      if (!mounted) {
        return current;
      }
      setState(() {
        _runtimeSnapshot = current;
        _runtimeHeadline = null;
      });
      if (current.phase == RuntimePhase.running) {
        return current;
      }
      if (_isTerminalConnectMessage(current.message)) {
        return current;
      }
    }
    return current;
  }

  Future<RuntimeSnapshot> _settleRuntimeDisconnectTransition(
    RuntimeSnapshot snapshot,
  ) async {
    if (snapshot.phase != RuntimePhase.running) {
      return snapshot;
    }

    var current = snapshot;
    for (var attempt = 0; attempt < 15; attempt += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      current = await _withRuntimeActionTimeout(
        'disconnectSnapshot',
        _runtimeEngine.snapshot,
      );
      if (!mounted) {
        return current;
      }
      setState(() {
        _runtimeSnapshot = current;
        _runtimeHeadline = null;
      });
      if (current.phase != RuntimePhase.running) {
        return current;
      }
    }
    return current;
  }

  bool _isTerminalConnectMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('failed') ||
        normalized.contains('denied') ||
        normalized.contains('error') ||
        normalized.contains('stopped') ||
        normalized.contains('не удалось') ||
        normalized.contains('отказ') ||
        normalized.contains('ошиб') ||
        normalized.contains('останов');
  }

  bool _canPrimaryConnect(RuntimeSnapshot? snapshot) {
    if (snapshot == null) {
      return false;
    }
    if (snapshot.phase == RuntimePhase.running) {
      return true;
    }
    if (!snapshot.supportsLiveConnect) {
      return false;
    }
    return snapshot.phase != RuntimePhase.artifactMissing;
  }

  Map<ShortcutActivator, Intent> _desktopNavigationShortcuts() {
    return const <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.digit1, control: true):
          _SelectSeedTabIntent(SeedTab.protection),
      SingleActivator(LogicalKeyboardKey.digit2, control: true):
          _SelectSeedTabIntent(SeedTab.locations),
      SingleActivator(LogicalKeyboardKey.digit3, control: true):
          _SelectSeedTabIntent(SeedTab.rules),
      SingleActivator(LogicalKeyboardKey.digit4, control: true):
          _SelectSeedTabIntent(SeedTab.profile),
      SingleActivator(LogicalKeyboardKey.numpad1, control: true):
          _SelectSeedTabIntent(SeedTab.protection),
      SingleActivator(LogicalKeyboardKey.numpad2, control: true):
          _SelectSeedTabIntent(SeedTab.locations),
      SingleActivator(LogicalKeyboardKey.numpad3, control: true):
          _SelectSeedTabIntent(SeedTab.rules),
      SingleActivator(LogicalKeyboardKey.numpad4, control: true):
          _SelectSeedTabIntent(SeedTab.profile),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasProvisionedAccess = !_managedProfileDirty ||
        (_runtimeSnapshot?.phase == RuntimePhase.running) ||
        ((_runtimeSnapshot?.stagedConfigPath ?? '').isNotEmpty);
    final sections = <Widget>[
      _QuickConnectSection(
        appContext: widget.appContext,
        selectedRouteMode: _selectedRouteMode,
        runtimeSnapshot: _runtimeSnapshot,
        runtimeHeadline: _runtimeHeadline,
        runtimeBusy: _runtimeBusy,
        primaryConnectEnabled: _canPrimaryConnect(_runtimeSnapshot),
        bonusSummary: _bonusSummary,
        telegramBonusBusy: _telegramBonusBusy,
        warpPolicy: _managedWarpPolicy,
        warpRuntimeConsent: _warpRuntimeConsent,
        warpBusy: _warpPolicyBusy,
        onToggleRuntime: _toggleRuntimeFromHome,
        onTelegramBonus: _telegramBonusBusy
            ? null
            : () {
                if (_telegramBonusCanClaim) {
                  unawaited(_claimTelegramBonusInApp());
                } else {
                  unawaited(_createTelegramLinkInApp());
                }
              },
        onOpenLocations: () => _selectTab(SeedTab.locations),
        onOpenRules: () => _selectTab(SeedTab.rules),
        onOpenWarp: _openWarpControl,
      ),
      _LocationsSection(
        appContext: widget.appContext,
        selectedRouteMode: _selectedRouteMode,
        hasProvisionedAccess: hasProvisionedAccess,
        smartConnectProfile: _smartConnectProfile,
        preferredNodeCode: _preferredNodeCode,
        nodePreferenceBusy: _nodePreferenceBusy,
        onPreferredNodeSelected: _setPreferredLocation,
      ),
      _RulesSection(
        appContext: widget.appContext,
        selectedRouteMode: _selectedRouteMode,
        selectedAppIds: _selectedAppIds,
        onRouteModeSelected: (mode) {
          _selectRouteMode(mode);
        },
        onSelectedAppAdded: _addSelectedAppId,
        onSelectedAppRemoved: _removeSelectedAppId,
      ),
      _ProfileSection(
        appContext: widget.appContext,
        selectedRouteMode: _selectedRouteMode,
        hasProvisionedAccess: hasProvisionedAccess,
        onOpenHandoff: _showSeedHandoff,
        onOpenSupportHub: _showSupportHub,
        onCreateTelegramLink: _createTelegramLinkInApp,
        onCheckTelegramBonus: _checkTelegramBonusInApp,
        onClaimTelegramBonus: _claimTelegramBonusInApp,
        telegramBonusStatus: _telegramBonusStatus,
        telegramBonusBusy: _telegramBonusBusy,
        telegramBonusCanClaim: _telegramBonusCanClaim,
        telegramBonusError: _telegramBonusError,
        bonusSummary: _bonusSummary,
        bonusSummaryBusy: _bonusSummaryBusy,
        bonusSummaryError: _bonusSummaryError,
        bonusRewardBusy: _bonusRewardBusy,
        onRefreshBonusSummary: () => _loadBonusSummary(force: true),
        onSpinWheel: _spinBonusWheelInApp,
        onCheckInCalendar: _checkInBonusCalendarInApp,
        runtimeSnapshot: _runtimeSnapshot,
        runtimeHeadline: _runtimeHeadline,
        onOpenWarp: _openWarpControl,
        communityProfileState: _communityProfileState,
        onActivateCommunityProfile: _activateCommunityProfile,
        onRemoveCommunityProfile: _removeCommunityProfile,
        onScanCommunityQr: widget.communityQrScanner == null
            ? null
            : () => _scanCommunityQr(context),
        onRefreshCommunitySubscriptions: _refreshCommunitySubscriptions,
      ),
    ];

    final isDesktopShell = switch (widget.appContext.hostPlatform) {
      HostPlatform.windows || HostPlatform.macos => true,
      HostPlatform.android || HostPlatform.ios => false,
    };

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    final shell = isDesktopShell
        ? _DesktopShell(
            appContext: widget.appContext,
            selectedIndex: _selectedIndex,
            sections: sections,
            onSelected: (index) {
              _selectTab(SeedTab.values[index]);
            },
          )
        : _MobileShell(
            selectedIndex: _selectedIndex,
            sections: sections,
            onSelected: (index) {
              _selectTab(SeedTab.values[index]);
            },
          );

    return _MotionScope(
      key: const ValueKey('motion-policy'),
      disableAnimations: disableAnimations,
      child: Shortcuts(
        key: const ValueKey('desktop-shell-shortcuts'),
        shortcuts: isDesktopShell && _firstLaunchStep == _FirstLaunchStep.ready
            ? _desktopNavigationShortcuts()
            : const <ShortcutActivator, Intent>{},
        child: Actions(
          actions: <Type, Action<Intent>>{
            _SelectSeedTabIntent: CallbackAction<_SelectSeedTabIntent>(
              onInvoke: (intent) {
                _selectTab(intent.tab);
                return null;
              },
            ),
          },
          child: Focus(
            key: const ValueKey('desktop-shell-focus-root'),
            autofocus: true,
            child: Scaffold(
              extendBody: !isDesktopShell,
              body: _SeedBackdrop(
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned.fill(child: shell),
                      if (_firstLaunchStep != _FirstLaunchStep.ready)
                        _FirstLaunchGate(
                          appContext: widget.appContext,
                          step: _firstLaunchStep,
                          restoreCodeController:
                              _firstLaunchRestoreCodeController,
                          busy: _firstLaunchBusy,
                          onNewUser: _completeFirstLaunchAsNewUser,
                          onReturningUser: _openFirstLaunchRestore,
                          onBack: _backToFirstLaunchChoice,
                          onRedeemCode: _redeemFirstLaunchRestoreCode,
                          onOpenTelegram: _createTelegramLinkInApp,
                          onOpenCabinet: () => _openCabinetWithHandoff(
                            widget.appContext.cabinetUrl,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeedContentList extends StatelessWidget {
  const _SeedContentList({
    required this.children,
    this.top = 12,
  });

  final List<Widget> children;
  final double top;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sidePadding = constraints.maxWidth >= 980
            ? (constraints.maxWidth - 900) / 2
            : 24.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(sidePadding, top, sidePadding, 160),
          children: children,
        );
      },
    );
  }
}

class _FirstLaunchGate extends StatelessWidget {
  const _FirstLaunchGate({
    required this.appContext,
    required this.step,
    required this.restoreCodeController,
    required this.busy,
    required this.onNewUser,
    required this.onReturningUser,
    required this.onBack,
    required this.onRedeemCode,
    required this.onOpenTelegram,
    required this.onOpenCabinet,
  });

  final SeedAppContext appContext;
  final _FirstLaunchStep step;
  final TextEditingController restoreCodeController;
  final bool busy;
  final VoidCallback onNewUser;
  final VoidCallback onReturningUser;
  final VoidCallback onBack;
  final VoidCallback onRedeemCode;
  final VoidCallback onOpenTelegram;
  final VoidCallback onOpenCabinet;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: step == _FirstLaunchStep.restore ? 18 : 96,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: step == _FirstLaunchStep.restore ? 520 : 460,
              ),
              child: step == _FirstLaunchStep.restore
                  ? _FirstLaunchRestoreScreen(
                      codeController: restoreCodeController,
                      busy: busy,
                      onBack: onBack,
                      onRedeemCode: onRedeemCode,
                      onOpenTelegram: onOpenTelegram,
                      onOpenCabinet: onOpenCabinet,
                    )
                  : _FirstLaunchChoiceScreen(
                      appContext: appContext,
                      onNewUser: onNewUser,
                      onReturningUser: onReturningUser,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FirstLaunchChoiceScreen extends StatelessWidget {
  const _FirstLaunchChoiceScreen({
    required this.appContext,
    required this.onNewUser,
    required this.onReturningUser,
  });

  final SeedAppContext appContext;
  final VoidCallback onNewUser;
  final VoidCallback onReturningUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('first-launch-choice-screen'),
      color: _SeedPalette.surface.withValues(alpha: 0.96),
      elevation: 10,
      shadowColor: _SeedPalette.ink.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _SeedPalette.line),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 380;
            final copy = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Можно сразу подключиться',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _SeedPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${appContext.runtimeProfile.trialDays} дней доступа без карты.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _SeedPalette.muted,
                    height: 1.25,
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: compact ? WrapAlignment.center : WrapAlignment.end,
              children: [
                TextButton.icon(
                  key: const ValueKey('first-launch-returning-user'),
                  onPressed: onReturningUser,
                  icon: const Icon(Icons.key_rounded),
                  label: const Text('Есть код'),
                ),
                FilledButton.icon(
                  key: const ValueKey('first-launch-new-user'),
                  onPressed: onNewUser,
                  icon: const Icon(Icons.flash_on_rounded),
                  label: const Text('Начать'),
                ),
              ],
            );
            if (compact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  copy,
                  const SizedBox(height: 10),
                  actions,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 12),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FirstLaunchRestoreScreen extends StatelessWidget {
  const _FirstLaunchRestoreScreen({
    required this.codeController,
    required this.busy,
    required this.onBack,
    required this.onRedeemCode,
    required this.onOpenTelegram,
    required this.onOpenCabinet,
  });

  final TextEditingController codeController;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onRedeemCode;
  final VoidCallback onOpenTelegram;
  final VoidCallback onOpenCabinet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('first-launch-restore-screen'),
      color: _SeedPalette.surface.withValues(alpha: 0.98),
      elevation: 12,
      shadowColor: _SeedPalette.ink.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(22),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('first-launch-back-to-choice'),
                  tooltip: 'Назад',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: busy ? null : onBack,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Восстановить доступ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: _SeedPalette.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Введите код из Telegram, кабинета или письма.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _SeedPalette.muted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('first-launch-restore-code-field'),
              controller: codeController,
              enabled: !busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!busy) {
                  onRedeemCode();
                }
              },
              decoration: InputDecoration(
                hintText: 'Код или ключ',
                prefixIcon: const Icon(Icons.key_rounded),
                filled: true,
                fillColor: _SeedPalette.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _SeedPalette.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _SeedPalette.line),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('first-launch-restore-redeem'),
              onPressed: busy ? null : onRedeemCode,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(busy ? 'Проверяем' : 'Восстановить'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                TextButton.icon(
                  key: const ValueKey('first-launch-open-telegram-code'),
                  onPressed: busy ? null : onOpenTelegram,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Код в Telegram'),
                ),
                TextButton.icon(
                  key: const ValueKey('first-launch-open-cabinet'),
                  onPressed: busy ? null : onOpenCabinet,
                  icon: const Icon(Icons.web_outlined),
                  label: const Text('Кабинет'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.appContext,
    required this.selectedIndex,
    required this.sections,
    required this.onSelected,
  }) : super(key: const ValueKey('desktop-shell'));

  final SeedAppContext appContext;
  final int selectedIndex;
  final List<Widget> sections;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return _DesktopDrawerShell(
            appContext: appContext,
            selectedIndex: selectedIndex,
            sections: sections,
            onSelected: onSelected,
          );
        }
        final collapsed = constraints.maxWidth < 1180;
        return Row(
          children: [
            _DesktopSidebar(
              variantProfile: appContext.variantProfile,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
              collapsed: collapsed,
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: _SeedPalette.line),
                  ),
                ),
                child: IndexedStack(
                  index: selectedIndex,
                  children: sections,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DesktopDrawerShell extends StatelessWidget {
  const _DesktopDrawerShell({
    required this.appContext,
    required this.selectedIndex,
    required this.sections,
    required this.onSelected,
  }) : super(key: const ValueKey('desktop-drawer-shell'));

  final SeedAppContext appContext;
  final int selectedIndex;
  final List<Widget> sections;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawerScrimColor: _SeedPalette.ink.withValues(alpha: 0.18),
      drawer: Drawer(
        key: const ValueKey('desktop-sidebar-drawer'),
        backgroundColor: _SeedPalette.canvas,
        child: SafeArea(
          child: _DesktopSidebar(
            variantProfile: appContext.variantProfile,
            selectedIndex: selectedIndex,
            onSelected: (index) {
              Navigator.of(context).maybePop();
              onSelected(index);
            },
            collapsed: false,
            drawer: true,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Builder(
                  builder: (buttonContext) {
                    return IconButton(
                      key: const ValueKey('desktop-sidebar-hamburger'),
                      tooltip: 'Меню',
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => Scaffold.of(buttonContext).openDrawer(),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _BrandLockup(
                  variantProfile: appContext.variantProfile,
                  markSize: 28,
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: sections,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.selectedIndex,
    required this.sections,
    required this.onSelected,
  }) : super(key: const ValueKey('mobile-shell'));

  final int selectedIndex;
  final List<Widget> sections;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: selectedIndex,
            children: sections,
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _SeedPalette.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _SeedPalette.line),
              ),
              child: NavigationBar(
                height: 64,
                selectedIndex: selectedIndex,
                onDestinationSelected: onSelected,
                destinations: const [
                  NavigationDestination(
                    key: ValueKey('nav-protection'),
                    icon: Icon(Icons.flash_on_outlined),
                    selectedIcon: Icon(Icons.flash_on),
                    label: 'Защита',
                  ),
                  NavigationDestination(
                    key: ValueKey('nav-locations'),
                    icon: Icon(Icons.public_outlined),
                    selectedIcon: Icon(Icons.public),
                    label: 'Локации',
                  ),
                  NavigationDestination(
                    key: ValueKey('nav-rules'),
                    icon: Icon(Icons.rule_folder_outlined),
                    selectedIcon: Icon(Icons.rule_folder),
                    label: 'Режим',
                  ),
                  NavigationDestination(
                    key: ValueKey('nav-profile'),
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Профиль',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopSidebar extends PokrovDesktopSidebar {
  _DesktopSidebar({
    required ClientVariantProfile variantProfile,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    required bool collapsed,
    bool drawer = false,
  }) : super(
          selectedIndex: selectedIndex,
          onSelected: onSelected,
          collapsed: collapsed,
          drawer: drawer,
          brandTitle: variantProfile.displayName,
          brandMarkAssetName: variantProfile.brandMarkAssetName,
          brandFallbackText: variantProfile.fallbackMarkText,
          versionLabel: _pokrovAppVersion,
          destinations: const [
            PokrovSidebarDestination(
              itemKey: ValueKey('nav-protection'),
              icon: Icons.flash_on_outlined,
              selectedIcon: Icons.flash_on,
              label: 'Защита',
            ),
            PokrovSidebarDestination(
              itemKey: ValueKey('nav-locations'),
              icon: Icons.public_outlined,
              selectedIcon: Icons.public,
              label: 'Локации',
            ),
            PokrovSidebarDestination(
              itemKey: ValueKey('nav-rules'),
              icon: Icons.rule_folder_outlined,
              selectedIcon: Icons.rule_folder,
              label: 'Режим',
            ),
            PokrovSidebarDestination(
              itemKey: ValueKey('nav-profile'),
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Профиль',
            ),
          ],
        );
}

class PokrovLegacyDesktopSidebar extends StatelessWidget {
  PokrovLegacyDesktopSidebar({
    required this.selectedIndex,
    required this.onSelected,
    required this.collapsed,
    ClientVariantProfile? variantProfile,
    this.drawer = false,
  })  : variantProfile = variantProfile ?? buildClientVariantProfileFor(),
        super(
          key: collapsed
              ? const ValueKey('desktop-icon-rail')
              : const ValueKey('desktop-sidebar-expanded'),
        );

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool collapsed;
  final ClientVariantProfile variantProfile;
  final bool drawer;

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 72.0 : 224.0;
    return AnimatedContainer(
      duration: _MotionScope.of(context).duration(_MotionTokens.standard),
      curve: _MotionTokens.ease,
      width: drawer ? 224 : width,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          collapsed ? 10 : 18,
          22,
          collapsed ? 10 : 18,
          18,
        ),
        child: Column(
          crossAxisAlignment:
              collapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            if (collapsed)
              const _BrandMark(size: 32)
            else ...[
              _BrandLockup(
                variantProfile: variantProfile,
                markSize: 34,
              ),
              const SizedBox(height: 4),
              Text(
                _pokrovAppVersion,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _SeedPalette.muted,
                    ),
              ),
            ],
            const SizedBox(height: 28),
            _SidebarItem(
              itemKey: const ValueKey('nav-protection'),
              index: 0,
              selectedIndex: selectedIndex,
              icon: Icons.flash_on_outlined,
              selectedIcon: Icons.flash_on,
              label: 'Защита',
              onSelected: onSelected,
              collapsed: collapsed,
            ),
            _SidebarItem(
              itemKey: const ValueKey('nav-locations'),
              index: 1,
              selectedIndex: selectedIndex,
              icon: Icons.public_outlined,
              selectedIcon: Icons.public,
              label: 'Локации',
              onSelected: onSelected,
              collapsed: collapsed,
            ),
            _SidebarItem(
              itemKey: const ValueKey('nav-rules'),
              index: 2,
              selectedIndex: selectedIndex,
              icon: Icons.rule_folder_outlined,
              selectedIcon: Icons.rule_folder,
              label: 'Режим',
              onSelected: onSelected,
              collapsed: collapsed,
            ),
            _SidebarItem(
              itemKey: const ValueKey('nav-profile'),
              index: 3,
              selectedIndex: selectedIndex,
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Профиль',
              onSelected: onSelected,
              collapsed: collapsed,
            ),
            const Spacer(),
            if (collapsed)
              Icon(
                Icons.info_outline_rounded,
                color: _SeedPalette.muted,
                size: 20,
              )
            else
              _StatusPill(
                label: 'Beta',
                icon: Icons.info_outline_rounded,
                tone: _SectionTone.muted,
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({
    required this.variantProfile,
    this.markSize = 32,
    this.center = false,
  });

  final ClientVariantProfile variantProfile;
  final double markSize;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final children = [
      _BrandMark(
        size: markSize,
        assetName: variantProfile.brandMarkAssetName,
        fallbackText: variantProfile.fallbackMarkText,
      ),
      const SizedBox(width: 10),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: center ? 220 : 180),
        child: Text(
          variantProfile.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _SeedPalette.ink,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
        ),
      ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: children,
    );
  }
}

class _BrandMark extends PokrovBrandMark {
  const _BrandMark({
    required double size,
    double opacity = 1,
    String assetName = _openClientBrandAsset,
    String fallbackText = 'O',
  }) : super(
          size: size,
          opacity: opacity,
          assetName: assetName,
          fallbackText: fallbackText,
        );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.itemKey,
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onSelected,
    this.collapsed = false,
  });

  final Key itemKey;
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final ValueChanged<int> onSelected;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    final child = Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        key: itemKey,
        borderRadius: BorderRadius.circular(10),
        onTap: () => onSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 8 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _SeedPalette.accent.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (!collapsed) ...[
                Container(
                  width: 2,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selected ? _SeedPalette.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 9),
              ],
              Icon(
                selected ? selectedIcon : icon,
                size: 20,
                color: selected ? _SeedPalette.accent : _SeedPalette.muted,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                AnimatedSize(
                  key: const ValueKey('desktop-sidebar-label-motion'),
                  duration: _MotionScope.of(context).duration(
                    _MotionTokens.short,
                  ),
                  curve: _MotionTokens.ease,
                  alignment: Alignment.centerLeft,
                  child: AnimatedOpacity(
                    duration: _MotionScope.of(context).duration(
                      _MotionTokens.short,
                    ),
                    curve: _MotionTokens.ease,
                    opacity: collapsed ? 0 : 1,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: selected
                                ? _SeedPalette.ink
                                : _SeedPalette.muted,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (collapsed) {
      return Tooltip(message: label, child: child);
    }
    return child;
  }
}

class _QuickConnectSection extends StatelessWidget {
  const _QuickConnectSection({
    required this.appContext,
    required this.selectedRouteMode,
    required this.runtimeSnapshot,
    required this.runtimeHeadline,
    required this.runtimeBusy,
    required this.primaryConnectEnabled,
    required this.bonusSummary,
    required this.telegramBonusBusy,
    required this.warpPolicy,
    required this.warpRuntimeConsent,
    required this.warpBusy,
    required this.onToggleRuntime,
    required this.onTelegramBonus,
    required this.onOpenLocations,
    required this.onOpenRules,
    required this.onOpenWarp,
  });

  final SeedAppContext appContext;
  final RouteMode selectedRouteMode;
  final RuntimeSnapshot? runtimeSnapshot;
  final String? runtimeHeadline;
  final bool runtimeBusy;
  final bool primaryConnectEnabled;
  final AppFirstBonusSummary? bonusSummary;
  final bool telegramBonusBusy;
  final WarpRuntimePolicy warpPolicy;
  final bool warpRuntimeConsent;
  final bool warpBusy;
  final Future<void> Function() onToggleRuntime;
  final VoidCallback? onTelegramBonus;
  final VoidCallback onOpenLocations;
  final VoidCallback onOpenRules;
  final Future<void> Function() onOpenWarp;

  @override
  Widget build(BuildContext context) {
    final snapshot = runtimeSnapshot;
    final isRunning = snapshot?.phase == RuntimePhase.running;
    final isHealthyRunning = snapshot?.isCleanlyHealthy ?? false;
    final statusLabel = _consumerProtectionStatusLabel(
      snapshot,
      busy: runtimeBusy,
    );
    final statusSummary = _consumerProtectionStatusSummary(
      snapshot,
      headline: runtimeHeadline,
      hostPlatform: appContext.hostPlatform,
      brandName: appContext.variantProfile.displayName,
    );
    final primaryActionEnabled = !runtimeBusy && primaryConnectEnabled;
    final isDesktop = switch (appContext.hostPlatform) {
      HostPlatform.windows || HostPlatform.macos => true,
      HostPlatform.android || HostPlatform.ios => false,
    };
    final statusColor = runtimeBusy
        ? _SeedPalette.warning
        : isRunning
            ? isHealthyRunning
                ? _SeedPalette.success
                : _SeedPalette.warning
            : _SeedPalette.muted;
    final actionLabel = runtimeBusy
        ? 'Готовим'
        : isRunning
            ? 'Отключить'
            : primaryActionEnabled
                ? 'Подключить'
                : 'Пока недоступно';
    final recoveryNotice = _motionRecoveryNotice(
      snapshot,
      headline: runtimeHeadline,
      busy: runtimeBusy,
    );

    return _SeedContentList(
      top: isDesktop ? 42 : 18,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 560 : 460),
            child: _HomeStage(
              variantProfile: appContext.variantProfile,
              statusLabel: statusLabel,
              statusColor: statusColor,
              actionLabel: actionLabel,
              actionEnabled: primaryActionEnabled,
              running: isRunning,
              busy: runtimeBusy,
              degraded: isRunning && !isHealthyRunning,
              recoveryNotice: recoveryNotice,
              accessLabel: _accessMainLabel(appContext, bonusSummary),
              accessPoolLabel: _accessPoolLabel(appContext.accessLane),
              telegramBonusLabel: telegramBonusBusy
                  ? 'Проверяем Telegram'
                  : _telegramBonusHomeLabel(appContext, bonusSummary),
              telegramBonusClaimed:
                  (bonusSummary?.channelBonusClaimedAt ?? '').trim().isNotEmpty,
              selectedRouteMode: selectedRouteMode,
              locationLabel: 'Автоматически',
              warpPolicy: warpPolicy,
              warpRuntimeConsent: warpRuntimeConsent,
              warpBusy: warpBusy,
              onToggleRuntime: onToggleRuntime,
              onTelegramBonus: onTelegramBonus,
              onOpenConnectionDetails: () => _showInfoSheet(
                context,
                title: 'Подключение',
                lines: [
                  statusSummary,
                  'Доступ: ${_accessMainLabel(appContext, bonusSummary)}.',
                  'Локация: автоматический выбор.',
                  'Режим: ${_routeModeShortLabel(selectedRouteMode)}.',
                ],
              ),
              onOpenLocations: onOpenLocations,
              onOpenRules: onOpenRules,
              onOpenWarp: onOpenWarp,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeStage extends StatefulWidget {
  const _HomeStage({
    required this.variantProfile,
    required this.statusLabel,
    required this.statusColor,
    required this.actionLabel,
    required this.actionEnabled,
    required this.running,
    required this.busy,
    required this.degraded,
    required this.recoveryNotice,
    required this.accessLabel,
    required this.accessPoolLabel,
    required this.telegramBonusLabel,
    required this.telegramBonusClaimed,
    required this.selectedRouteMode,
    required this.locationLabel,
    required this.warpPolicy,
    required this.warpRuntimeConsent,
    required this.warpBusy,
    required this.onToggleRuntime,
    required this.onTelegramBonus,
    required this.onOpenConnectionDetails,
    required this.onOpenLocations,
    required this.onOpenRules,
    required this.onOpenWarp,
  });

  final ClientVariantProfile variantProfile;
  final String statusLabel;
  final Color statusColor;
  final String actionLabel;
  final bool actionEnabled;
  final bool running;
  final bool busy;
  final bool degraded;
  final String? recoveryNotice;
  final String accessLabel;
  final String accessPoolLabel;
  final String telegramBonusLabel;
  final bool telegramBonusClaimed;
  final RouteMode selectedRouteMode;
  final String locationLabel;
  final WarpRuntimePolicy warpPolicy;
  final bool warpRuntimeConsent;
  final bool warpBusy;
  final Future<void> Function() onToggleRuntime;
  final VoidCallback? onTelegramBonus;
  final VoidCallback onOpenConnectionDetails;
  final VoidCallback onOpenLocations;
  final VoidCallback onOpenRules;
  final Future<void> Function() onOpenWarp;

  @override
  State<_HomeStage> createState() => _HomeStageState();
}

class _HomeStageState extends State<_HomeStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  bool _revealStarted = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: _MotionTokens.homeReveal,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = _MotionScope.of(context);
    if (motion.disableAnimations) {
      _revealController.value = 1;
      _revealStarted = true;
      return;
    }
    if (!_revealStarted) {
      _revealStarted = true;
      _revealController.forward();
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('home-boot-reveal'),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _HomeRevealSlice(
            controller: _revealController,
            begin: 0,
            end: 0.42,
            child: _BrandLockup(
              variantProfile: widget.variantProfile,
              markSize: 38,
              center: true,
            ),
          ),
          const SizedBox(height: 20),
          _HomeRevealSlice(
            controller: _revealController,
            begin: 0.18,
            end: 0.58,
            child: InkWell(
              key: const ValueKey('home-connection-details-action'),
              borderRadius: BorderRadius.circular(999),
              onTap: widget.onOpenConnectionDetails,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: _StatusDotLabel(
                  label: widget.statusLabel,
                  color: widget.statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _HomeRevealSlice(
            controller: _revealController,
            begin: 0.2,
            end: 0.66,
            child: _HomeAccessStrip(
              accessLabel: widget.accessLabel,
              poolLabel: widget.accessPoolLabel,
              telegramBonusLabel: widget.telegramBonusLabel,
              telegramBonusClaimed: widget.telegramBonusClaimed,
              onTelegramBonus: widget.onTelegramBonus,
            ),
          ),
          if (widget.recoveryNotice != null) ...[
            const SizedBox(height: 12),
            _HomeRevealSlice(
              controller: _revealController,
              begin: 0.22,
              end: 0.62,
              child: _MotionRecoveryBanner(message: widget.recoveryNotice!),
            ),
          ],
          const SizedBox(height: 22),
          _HomeRevealSlice(
            controller: _revealController,
            begin: 0.28,
            end: 0.78,
            child: _ConnectOrbButton(
              actionLabel: widget.actionLabel,
              enabled: widget.actionEnabled,
              running: widget.running,
              degraded: widget.degraded,
              error: widget.recoveryNotice != null,
              busy: widget.busy,
              onPressed: widget.actionEnabled ? widget.onToggleRuntime : null,
            ),
          ),
          const SizedBox(height: 22),
          _HomeRevealSlice(
            controller: _revealController,
            begin: 0.42,
            end: 0.88,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _HomeChip(
                  key: const ValueKey('home-location-chip'),
                  icon: Icons.public_rounded,
                  label: widget.locationLabel,
                  onTap: widget.onOpenLocations,
                ),
                _HomeChip(
                  key: const ValueKey('home-route-chip'),
                  icon: Icons.alt_route_rounded,
                  label: _routeModeShortLabel(widget.selectedRouteMode),
                  minLabelWidth: 142,
                  onTap: widget.onOpenRules,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _HomeRevealSlice(
            controller: _revealController,
            begin: 0.54,
            end: 1,
            child: _HomeWarpTile(
              policy: widget.warpPolicy,
              runtimeConsent: widget.warpRuntimeConsent,
              busy: widget.warpBusy,
              onOpen: widget.onOpenWarp,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAccessStrip extends StatelessWidget {
  const _HomeAccessStrip({
    required this.accessLabel,
    required this.poolLabel,
    required this.telegramBonusLabel,
    required this.telegramBonusClaimed,
    required this.onTelegramBonus,
  });

  final String accessLabel;
  final String poolLabel;
  final String telegramBonusLabel;
  final bool telegramBonusClaimed;
  final VoidCallback? onTelegramBonus;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('home-access-strip'),
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _HomeAccessPill(
          key: const ValueKey('home-trial-pill'),
          icon: Icons.workspace_premium_outlined,
          label: accessLabel,
          sublabel: poolLabel,
          tone: _SectionTone.accent,
        ),
        _HomeAccessPill(
          key: const ValueKey('home-telegram-bonus-pill'),
          icon: telegramBonusClaimed
              ? Icons.check_circle_outline_rounded
              : Icons.send_outlined,
          label: telegramBonusLabel,
          sublabel: telegramBonusClaimed ? 'Готово' : 'Бонус',
          tone: _SectionTone.reward,
          onTap: telegramBonusClaimed ? null : onTelegramBonus,
        ),
      ],
    );
  }
}

class _HomeAccessPill extends StatelessWidget {
  const _HomeAccessPill({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.tone,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final _SectionTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = tone == _SectionTone.reward
        ? _SeedPalette.warning
        : _SeedPalette.accent;
    final content = AnimatedContainer(
      duration: _MotionScope.of(context).duration(_MotionTokens.short),
      curve: _MotionTokens.ease,
      constraints: const BoxConstraints(minHeight: 44, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: accent),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _SeedPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  sublabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _SeedPalette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }
    return PokrovSettingsRowPressSurface(
      onTap: onTap!,
      child: content,
    );
  }
}

class _HomeWarpTile extends StatelessWidget {
  const _HomeWarpTile({
    required this.policy,
    required this.runtimeConsent,
    required this.busy,
    required this.onOpen,
  });

  final WarpRuntimePolicy policy;
  final bool runtimeConsent;
  final bool busy;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final motion = _MotionScope.of(context);
    final lifecycle = PokrovWarpLifecycle.resolve(
      policy: policy,
      consented: runtimeConsent,
      busy: busy,
    );
    final canOffer = lifecycle.canOffer;
    final enabled = lifecycle.highlightsEnabled;
    final title = canOffer
        ? lifecycle.publicSheetTitle
        : '${lifecycle.publicSheetTitle} · Скоро';
    final iconColor = enabled
        ? _SeedPalette.accent
        : _SeedPalette.muted.withValues(alpha: 0.8);
    final iconBackground = enabled
        ? _SeedPalette.accent.withValues(alpha: 0.12)
        : _SeedPalette.surfaceMuted.withValues(alpha: 0.86);

    return InkWell(
      key: const ValueKey('home-warp-tile'),
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        unawaited(onOpen());
      },
      child: AnimatedContainer(
        key: ValueKey(lifecycle.stateKey),
        duration: motion.duration(_MotionTokens.short),
        curve: _MotionTokens.ease,
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: enabled
              ? _SeedPalette.accent.withValues(alpha: 0.08)
              : _SeedPalette.surfaceMuted.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? _SeedPalette.accent.withValues(alpha: 0.26)
                : _SeedPalette.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                enabled
                    ? Icons.verified_user_rounded
                    : Icons.privacy_tip_outlined,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: _SeedPalette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    key: const ValueKey('home-warp-status-label'),
                    duration: motion.duration(_MotionTokens.short),
                    transitionBuilder: _fadeSlideTransition,
                    child: Text(
                      lifecycle.publicStatus,
                      key: ValueKey(lifecycle.publicStatus),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: enabled
                                ? _SeedPalette.accent
                                : _SeedPalette.muted,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              canOffer ? Icons.tune_rounded : Icons.lock_clock_outlined,
              size: 18,
              color: _SeedPalette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _HomeWarpTileLegacy extends StatelessWidget {
  const _HomeWarpTileLegacy();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('home-warp-tile'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showInfoSheet(
        context,
        title: 'Расширенная приватность',
        lines: const [
          'Дополнительный режим готовится и не активен в этой сборке.',
          'Когда режим будет проверен, клиент покажет простой тумблер и честное предупреждение о скорости.',
        ],
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _SeedPalette.surfaceMuted.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _SeedPalette.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _SeedPalette.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.privacy_tip_outlined,
                size: 18,
                color: _SeedPalette.accent,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Расширенная приватность',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: _SeedPalette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Дополнительный режим готовится',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: _SeedPalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeRevealSlice extends StatelessWidget {
  const _HomeRevealSlice({
    required this.controller,
    required this.begin,
    required this.end,
    required this.child,
  });

  final AnimationController controller;
  final double begin;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_MotionScope.of(context).disableAnimations) {
      return child;
    }
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(
          ((controller.value - begin) / (end - begin)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 12),
            child: child,
          ),
        );
      },
    );
  }
}

Widget _fadeSlideTransition(Widget child, Animation<double> animation) {
  return pokrovFadeSlideTransition(child, animation);
}

class _MotionRecoveryBanner extends StatelessWidget {
  const _MotionRecoveryBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final motion = _MotionScope.of(context);
    return AnimatedSwitcher(
      key: const ValueKey('motion-recovery-banner'),
      duration: motion.duration(_MotionTokens.standard),
      transitionBuilder: _fadeSlideTransition,
      child: Container(
        key: ValueKey(message),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _SeedPalette.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _SeedPalette.warning.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: _SeedPalette.warning.withValues(alpha: 0.92),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _SeedPalette.ink.withValues(alpha: 0.78),
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDotLabel extends PokrovStatusDotLabel {
  const _StatusDotLabel({
    required super.label,
    required super.color,
  });
}

class _HomeChip extends PokrovHomeChip {
  const _HomeChip({
    super.key,
    required super.icon,
    required super.label,
    super.minLabelWidth,
    super.onTap,
  });
}

class _MotionSkeletonList extends PokrovSkeletonList {
  const _MotionSkeletonList({
    super.key,
    super.rows = 4,
  });
}

class _AccountSkeletonSummary extends PokrovAccountSkeletonSummary {
  const _AccountSkeletonSummary();
}

class _LocationsSection extends StatelessWidget {
  const _LocationsSection({
    required this.appContext,
    required this.selectedRouteMode,
    required this.hasProvisionedAccess,
    required this.smartConnectProfile,
    required this.preferredNodeCode,
    required this.nodePreferenceBusy,
    required this.onPreferredNodeSelected,
  });

  final SeedAppContext appContext;
  final RouteMode selectedRouteMode;
  final bool hasProvisionedAccess;
  final SmartConnectProfile? smartConnectProfile;
  final String preferredNodeCode;
  final bool nodePreferenceBusy;
  final ValueChanged<String> onPreferredNodeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final smartConnect = smartConnectProfile;
    final shortlist = smartConnect?.shortlist ?? const <SmartConnectNode>[];
    final premiumPool = _accessPoolLabel(appContext.accessLane);

    return _SeedContentList(
      children: [
        Text('Локация', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        _SectionCard(
          key: const ValueKey('locations-auto-section'),
          title: 'Автоматически',
          tone:
              hasProvisionedAccess ? _SectionTone.neutral : _SectionTone.muted,
          lines: [
            hasProvisionedAccess
                ? '$premiumPool · ${_routeModeShortLabel(selectedRouteMode)}'
                : 'После подготовки',
          ],
          child: Column(
            children: [
              _SettingsRow(
                key: const ValueKey('locations-auto-help-action'),
                icon: Icons.check_circle_outline_rounded,
                title: _brandText(
                  'POKROV выберет сервер',
                  appContext.variantProfile,
                ),
                value: preferredNodeCode.trim().isEmpty
                    ? 'Авто'
                    : preferredNodeCode.trim().toUpperCase(),
                onTap: () => _showInfoSheet(
                  context,
                  title: 'Автоматически',
                  lines: [
                    _brandText(
                      'POKROV выбирает доступный сервер по вашему доступу и текущему состоянию узлов.',
                      appContext.variantProfile,
                    ),
                    'Пробный доступ использует премиум-пул, а не бесплатный узел.',
                    _brandText(
                      'Если вы выберете узел ниже, POKROV поставит его первым при следующем профиле.',
                      appContext.variantProfile,
                    ),
                  ],
                ),
              ),
              if (nodePreferenceBusy)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          ),
        ),
        if (hasProvisionedAccess && shortlist.isNotEmpty) ...[
          _SectionCard(
            title: 'Доступные узлы',
            lines: const [
              'Выбор сохранится и применится после переподключения.'
            ],
            child: Column(
              children: shortlist
                  .map(
                    (node) => _SmartConnectNodeRow(
                      node: node,
                      selected: node.code.trim().toLowerCase() ==
                          preferredNodeCode.trim().toLowerCase(),
                      disabled: nodePreferenceBusy,
                      onTap: () => onPreferredNodeSelected(node.code),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ] else if (hasProvisionedAccess) ...[
          _SectionCard(
            title: 'Выбор страны',
            tone: _SectionTone.muted,
            lines: const [
              'Пока доступен автоматический выбор. Список стран появится, когда backend вернет shortlist для этого аккаунта.',
            ],
          ),
        ] else ...[
          const _MotionSkeletonList(
            key: ValueKey('locations-skeleton-list'),
            rows: 4,
          ),
          _SectionCard(
            title: 'Появится после подготовки',
            lines: [
              'Нажмите «Подключить» на главном экране.',
            ],
          ),
        ],
      ],
    );
  }
}

class _SmartConnectNodeRow extends StatelessWidget {
  const _SmartConnectNodeRow({
    required this.node,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final SmartConnectNode node;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latency = node.rankHint.panelLatencyMs;
    final value = selected
        ? 'Выбран'
        : latency == null || latency <= 0
            ? 'Выбрать'
            : '${latency} мс';
    return _SettingsRow(
      key: ValueKey('locations-smart-node-${node.code}'),
      icon: selected ? Icons.check_circle_rounded : Icons.public_rounded,
      title: _smartConnectNodeTitle(node),
      value: value,
      onTap: disabled ? null : onTap,
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.appContext,
    required this.selectedRouteMode,
    required this.hasProvisionedAccess,
    required this.onOpenHandoff,
    required this.onOpenSupportHub,
    required this.onCreateTelegramLink,
    required this.onCheckTelegramBonus,
    required this.onClaimTelegramBonus,
    required this.telegramBonusStatus,
    required this.telegramBonusBusy,
    required this.telegramBonusCanClaim,
    required this.telegramBonusError,
    required this.bonusSummary,
    required this.bonusSummaryBusy,
    required this.bonusSummaryError,
    required this.bonusRewardBusy,
    required this.onRefreshBonusSummary,
    required this.onSpinWheel,
    required this.onCheckInCalendar,
    required this.runtimeSnapshot,
    required this.runtimeHeadline,
    required this.onOpenWarp,
    required this.communityProfileState,
    required this.onActivateCommunityProfile,
    required this.onRemoveCommunityProfile,
    required this.onScanCommunityQr,
    required this.onRefreshCommunitySubscriptions,
  });

  final SeedAppContext appContext;
  final RouteMode selectedRouteMode;
  final bool hasProvisionedAccess;
  final void Function(String label, String value) onOpenHandoff;
  final VoidCallback onOpenSupportHub;
  final VoidCallback onCreateTelegramLink;
  final VoidCallback onCheckTelegramBonus;
  final VoidCallback onClaimTelegramBonus;
  final String telegramBonusStatus;
  final bool telegramBonusBusy;
  final bool telegramBonusCanClaim;
  final String? telegramBonusError;
  final AppFirstBonusSummary? bonusSummary;
  final bool bonusSummaryBusy;
  final String? bonusSummaryError;
  final bool bonusRewardBusy;
  final VoidCallback onRefreshBonusSummary;
  final VoidCallback onSpinWheel;
  final VoidCallback onCheckInCalendar;
  final RuntimeSnapshot? runtimeSnapshot;
  final String? runtimeHeadline;
  final Future<void> Function() onOpenWarp;
  final _CommunityProfileState communityProfileState;
  final ValueChanged<String> onActivateCommunityProfile;
  final ValueChanged<String> onRemoveCommunityProfile;
  final Future<void> Function()? onScanCommunityQr;
  final Future<void> Function() onRefreshCommunitySubscriptions;

  List<String> _bonusSummaryLines() {
    final summary = bonusSummary;
    if (summary == null && bonusSummaryBusy) {
      return const ['Обновляем Telegram, рефералы и промокоды.'];
    }
    if (summary == null) {
      return const ['Telegram · рефералы · промокоды'];
    }
    final referralCode =
        summary.referralCode.isEmpty ? '' : ' · ${summary.referralCode}';
    return [
      'Telegram +${summary.channelBonusPremiumDays} дней · рефералы ${summary.referralCount}$referralCode',
    ];
  }

  String _bonusHubValue() {
    final summary = bonusSummary;
    if (bonusSummaryBusy) {
      return 'Обновляем';
    }
    if (summary == null) {
      return 'Открыть';
    }
    final parts = <String>[
      if (summary.channelBonusPremiumDays > 0)
        '+${summary.channelBonusPremiumDays} дней',
      if (summary.referralCount > 0) '${summary.referralCount} реф.',
    ];
    return parts.isEmpty ? 'Открыть' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = _consumerProtectionStatusLabel(runtimeSnapshot);
    final statusSummary = _consumerProtectionStatusSummary(
      runtimeSnapshot,
      headline: runtimeHeadline,
      hostPlatform: appContext.hostPlatform,
      brandName: appContext.variantProfile.displayName,
    );
    final usesApiServices = appContext.variantProfile.usesApiServices;
    final hasCheckoutUrl = appContext.checkoutUrl.trim().isNotEmpty;
    final hasCabinetUrl = appContext.cabinetUrl.trim().isNotEmpty;
    final activeCommunityProfile = communityProfileState.activeProfile;
    final hasSubscriptionRefreshFailure = communityProfileState.profiles.any(
      (profile) =>
          profile.sourceUrl.trim().isNotEmpty &&
          profile.lastRefreshStatus == 'failed',
    );
    final subscriptionSourceCount =
        communityProfileState.subscriptionSourceUrls.length;
    final communityProfileSummary = activeCommunityProfile == null
        ? 'Add a key, scan QR, or import an HTTPS subscription. Everything stays local.'
        : subscriptionSourceCount == 0
            ? 'Active: ${activeCommunityProfile.displayName}. Local key profile.'
            : 'Active: ${activeCommunityProfile.displayName}. $subscriptionSourceCount subscription source(s).';
    void openCommunityKeyImport() => _showRedeemSheet(
          context,
          hintCode: appContext.redeemHint,
          hintPlaceholder: appContext.variantProfile.isOfficialPokrov
              ? 'POKROV-XXXX-XXXX'
              : 'vless://, ss://, trojan:// or vmess://',
          title: 'Add profile key',
          body: _communityKeyImportBody,
          submitLabel: 'Save profile',
          onRedeem: (code) => onOpenHandoff('redeem', code),
        );
    void openCommunitySubscriptionImport() => _showRedeemSheet(
          context,
          hintCode: '',
          hintPlaceholder: 'https://example.com/sub.txt',
          title: 'Add subscription URL',
          body: _communitySubscriptionImportBody,
          submitLabel: 'Import profiles',
          onRedeem: (code) => onOpenHandoff('redeem', code),
        );
    void openCommunityQrImport() {
      final scanner = onScanCommunityQr;
      if (scanner != null) {
        unawaited(scanner());
        return;
      }
      _showRedeemSheet(
        context,
        hintCode: '',
        hintPlaceholder: 'vless://, ss://, trojan:// or vmess://',
        title: 'Import QR text',
        body: _communityQrImportBody,
        submitLabel: 'Import QR',
        onRedeem: (code) => onOpenHandoff('redeem', code),
      );
    }

    void openCommunityFreeCatalog() => _showInfoSheet(
          context,
          title: 'Free VPN catalog',
          lines: _communityFreeCatalogLines,
        );

    return _SeedContentList(
      top: 24,
      children: [
        Text('Профиль', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey('profile-compact-account-layer'),
          child: Column(
            children: [
              _SectionCard(
                key: const ValueKey('profile-section-plan-access'),
                title: 'Мой доступ',
                tone: _SectionTone.accent,
                lines: [
                  '${_accessMainLabel(appContext, bonusSummary)} · ${_accessPoolLabel(appContext.accessLane)}',
                ],
                child: Column(
                  children: [
                    if (!hasProvisionedAccess)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _AccountSkeletonSummary(),
                      ),
                    _SettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: 'Статус',
                      value: statusLabel,
                      onTap: () => _showInfoSheet(
                        context,
                        title: 'Статус',
                        lines: [statusSummary],
                      ),
                    ),
                    if (usesApiServices)
                      _SettingsRow(
                        key: const ValueKey('profile-plan-details-action'),
                        icon: Icons.workspace_premium_outlined,
                        title: 'Подписка',
                        value: _accessShortValue(appContext, bonusSummary),
                        onTap: () => _showSubscriptionSheet(
                          context,
                          appContext: appContext,
                          hasProvisionedAccess: hasProvisionedAccess,
                          onOpenHandoff: onOpenHandoff,
                        ),
                      ),
                    if (hasCheckoutUrl)
                      _SettingsRow(
                        key: const ValueKey('profile-checkout-action'),
                        icon: Icons.shopping_bag_outlined,
                        title: 'Оплата',
                        value: 'Продлить',
                        onTap: () =>
                            onOpenHandoff('checkout', appContext.checkoutUrl),
                      ),
                    if (hasCabinetUrl)
                      _SettingsRow(
                        key: const ValueKey('profile-open-cabinet-action'),
                        icon: Icons.web_outlined,
                        title: 'Кабинет',
                        value: 'Открыть',
                        onTap: () =>
                            onOpenHandoff('cabinet', appContext.cabinetUrl),
                      ),
                  ],
                ),
              ),
              _SectionCard(
                key: const ValueKey('profile-section-sync'),
                title: usesApiServices
                    ? 'Привязать доступ'
                    : 'Open Client profiles',
                tone: _SectionTone.reward,
                lines: [
                  usesApiServices
                      ? 'Код из Telegram, кабинета, сайта или письма.'
                      : communityProfileSummary,
                ],
                child: Column(
                  children: [
                    _SettingsRow(
                      key: const ValueKey('profile-redeem-code-action'),
                      icon: Icons.key_rounded,
                      title: usesApiServices
                          ? 'Код активации'
                          : activeCommunityProfile == null
                              ? 'Add profile key'
                              : 'Replace profile key',
                      value: usesApiServices ? 'Ввести' : 'Open',
                      onTap: () => _showRedeemSheet(
                        context,
                        hintCode: appContext.redeemHint,
                        hintPlaceholder:
                            appContext.variantProfile.isOfficialPokrov
                                ? 'POKROV-XXXX-XXXX'
                                : 'vless://, ss://, trojan:// or vmess://',
                        title: usesApiServices
                            ? 'Код активации'
                            : 'Add profile key',
                        body: usesApiServices
                            ? 'Введите код из приложения, кабинета, Telegram или письма.'
                            : _communityKeyImportBody,
                        submitLabel:
                            usesApiServices ? 'Ввести код' : 'Save profile',
                        onRedeem: (code) => onOpenHandoff('redeem', code),
                      ),
                    ),
                    if (!usesApiServices) ...[
                      _SettingsRow(
                        key: const ValueKey('profile-import-hub-action'),
                        icon: Icons.add_link_rounded,
                        title: 'Import hub',
                        value: 'Open',
                        onTap: () => _showCommunityImportHubSheet(
                          context,
                          profileCount: communityProfileState.profiles.length,
                          subscriptionSourceCount: subscriptionSourceCount,
                          hasCameraQr: onScanCommunityQr != null,
                          onAddKey: openCommunityKeyImport,
                          onAddSubscription: openCommunitySubscriptionImport,
                          onImportQr: openCommunityQrImport,
                          onOpenFreeCatalog: openCommunityFreeCatalog,
                        ),
                      ),
                      _SettingsRow(
                        key: const ValueKey('profile-subscription-url-action'),
                        icon: Icons.sync_rounded,
                        title: 'Add subscription URL',
                        value: 'Refresh',
                        onTap: openCommunitySubscriptionImport,
                      ),
                      _SettingsRow(
                        key: const ValueKey('profile-qr-import-action'),
                        icon: Icons.qr_code_scanner_rounded,
                        title: onScanCommunityQr == null
                            ? 'Import QR text'
                            : 'Scan QR code',
                        value: onScanCommunityQr == null ? 'Paste' : 'Camera',
                        onTap: openCommunityQrImport,
                      ),
                      _SettingsRow(
                        key: const ValueKey('profile-active-local-profile'),
                        icon: Icons.dns_outlined,
                        title: 'Active profile',
                        value: activeCommunityProfile?.payload.profileName ??
                            'None',
                        onTap: activeCommunityProfile == null
                            ? null
                            : () => _showInfoSheet(
                                  context,
                                  title: 'Active profile',
                                  lines: [
                                    activeCommunityProfile.displayName,
                                    activeCommunityProfile.payload.profileName,
                                    'Route mode: ${_routeModeShortLabel(selectedRouteMode)}',
                                  ],
                                ),
                      ),
                      if (communityProfileState
                          .subscriptionSourceUrls.isNotEmpty)
                        _SettingsRow(
                          key: const ValueKey(
                            'profile-refresh-subscriptions-action',
                          ),
                          icon: Icons.refresh_rounded,
                          title: 'Refresh subscriptions',
                          value: hasSubscriptionRefreshFailure
                              ? 'Error'
                              : '$subscriptionSourceCount source(s)',
                          onTap: onRefreshCommunitySubscriptions,
                        ),
                      _SettingsRow(
                        key: const ValueKey('profile-free-vpn-catalog-action'),
                        icon: Icons.public_rounded,
                        title: 'Free VPN catalog',
                        value: 'Off',
                        onTap: openCommunityFreeCatalog,
                      ),
                      for (final profile in communityProfileState.profiles)
                        _SettingsRow(
                          key: ValueKey(
                            'profile-local-profile-${profile.payload.profileName}',
                          ),
                          icon: profile.payload.profileName ==
                                  activeCommunityProfile?.payload.profileName
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          title: profile.displayName,
                          value: profile.payload.profileName ==
                                  activeCommunityProfile?.payload.profileName
                              ? 'Active'
                              : 'Use',
                          onTap: () => onActivateCommunityProfile(
                            profile.payload.profileName,
                          ),
                        ),
                      if (activeCommunityProfile != null)
                        _SettingsRow(
                          key: const ValueKey('profile-remove-local-profile'),
                          icon: Icons.delete_outline_rounded,
                          title: 'Remove active profile',
                          value: 'Clear',
                          onTap: () => onRemoveCommunityProfile(
                            activeCommunityProfile.payload.profileName,
                          ),
                        ),
                    ],
                    if (usesApiServices) ...[
                      _SettingsRow(
                        key: const ValueKey('profile-telegram-link-action'),
                        icon: Icons.send_outlined,
                        title:
                            'Telegram +${appContext.runtimeProfile.telegramBonusDays} дней',
                        value: telegramBonusBusy
                            ? 'Проверяем'
                            : telegramBonusStatus,
                        onTap: telegramBonusBusy ? null : onCreateTelegramLink,
                      ),
                      _SettingsRow(
                        key: const ValueKey('profile-telegram-check-action'),
                        icon: Icons.fact_check_outlined,
                        title: 'Проверить подписку',
                        value: 'Канал',
                        onTap: telegramBonusBusy ? null : onCheckTelegramBonus,
                      ),
                      _SettingsRow(
                        key: const ValueKey('profile-telegram-claim-action'),
                        icon: Icons.add_circle_outline_rounded,
                        title:
                            'Получить +${appContext.runtimeProfile.telegramBonusDays} дней',
                        value: telegramBonusCanClaim
                            ? 'Активировать'
                            : 'После проверки',
                        onTap: telegramBonusBusy ? null : onClaimTelegramBonus,
                      ),
                    ],
                    if ((telegramBonusError ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          telegramBonusError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _SectionCard(
                key: const ValueKey('profile-section-bonus-summary'),
                title: 'Бонусы',
                tone: _SectionTone.reward,
                lines: _bonusSummaryLines(),
                child: Column(
                  children: [
                    if (bonusSummary == null && bonusSummaryBusy)
                      const _MotionSkeletonList(
                        key: ValueKey('rewards-skeleton-summary'),
                        rows: 3,
                      ),
                    _SettingsRow(
                      key: const ValueKey('profile-bonus-summary-refresh'),
                      icon: Icons.refresh_rounded,
                      title: 'Обновить бонусы',
                      value: bonusSummaryBusy ? 'Секунду' : 'Сводка',
                      onTap: bonusSummaryBusy ? null : onRefreshBonusSummary,
                    ),
                    _SettingsRow(
                      key: const ValueKey('profile-bonus-wheel-action'),
                      icon: Icons.auto_awesome_outlined,
                      title: 'Бонусы и история',
                      value: _bonusHubValue(),
                      onTap: () => _showRewardsHubSheet(
                        context,
                        summary: bonusSummary,
                        rewardBusy: bonusRewardBusy,
                        onRefreshBonusSummary: onRefreshBonusSummary,
                        onSpinWheel: onSpinWheel,
                        onCheckInCalendar: onCheckInCalendar,
                        onOpenHandoff: onOpenHandoff,
                      ),
                    ),
                    if ((bonusSummaryError ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          bonusSummaryError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _SectionCard(
                key: const ValueKey('profile-section-app'),
                title: 'Настройки',
                lines: [
                  '${appContext.hostPlatform.label} · ${_routeModeShortLabel(selectedRouteMode)}'
                ],
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.devices_outlined,
                      title: 'Устройство',
                      value: appContext.hostPlatform.label,
                    ),
                    _SettingsRow(
                      icon: Icons.alt_route_rounded,
                      title: 'Режим работы',
                      value: _routeModeShortLabel(selectedRouteMode),
                    ),
                    _SettingsRow(
                      key: const ValueKey(
                        'profile-enhanced-protection-action',
                      ),
                      icon: Icons.privacy_tip_outlined,
                      title: 'Расширенная защита',
                      value: 'Скоро',
                      onTap: () {
                        unawaited(onOpenWarp());
                      },
                    ),
                    _SettingsRow(
                      key: const ValueKey('profile-account-details-action'),
                      icon: Icons.manage_accounts_outlined,
                      title: 'Детали профиля',
                      value: 'Детали',
                      onTap: () => _showAccountDetailsSheet(
                        context,
                        appContext: appContext,
                        selectedRouteMode: selectedRouteMode,
                        statusLabel: statusLabel,
                        hasProvisionedAccess: hasProvisionedAccess,
                        onOpenHandoff: onOpenHandoff,
                      ),
                    ),
                    _SettingsRow(
                      icon: Icons.download_outlined,
                      title: 'Загрузки',
                      value: 'Билды',
                      onTap: () => onOpenHandoff(
                        'download',
                        Uri.parse(appContext.cabinetUrl)
                            .replace(path: '/downloads')
                            .toString(),
                      ),
                    ),
                    _SettingsRow(
                      key: const ValueKey('profile-email-action'),
                      icon: Icons.alternate_email_rounded,
                      title: 'Email',
                      value: 'Кабинет',
                      onTap: () => _showEmailRecoverySheet(
                        context,
                        appContext: appContext,
                        onOpenHandoff: onOpenHandoff,
                      ),
                    ),
                    _SettingsRow(
                      key: const ValueKey('profile-section-support'),
                      icon: Icons.support_agent_rounded,
                      title: 'Чат поддержки',
                      value: 'Открыть',
                      onTap: onOpenSupportHub,
                    ),
                    _SettingsRow(
                      key: const ValueKey('profile-section-advanced'),
                      icon: Icons.tune_rounded,
                      title: 'Диагностика',
                      value: _pokrovAppVersion,
                      onTap: () => _showAdvancedSettingsSheet(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _showSubscriptionSheet(
  BuildContext context, {
  required SeedAppContext appContext,
  required bool hasProvisionedAccess,
  required void Function(String label, String value) onOpenHandoff,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _SeedPalette.surface,
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('profile-subscription-sheet'),
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Подписка',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _SeedPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasProvisionedAccess
                  ? 'Доступ активен. Продление открывается на защищенной странице оплаты.'
                  : 'Сначала подготовьте устройство, затем продлите доступ через защищенную оплату.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _SeedPalette.ink.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 16),
            _KeyValueLine(
              label: 'Текущий доступ',
              value: appContext.accessLane.label,
            ),
            _KeyValueLine(
              label: 'Устройство',
              value: appContext.hostPlatform.label,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: const ValueKey('subscription-checkout-primary'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenHandoff('checkout', appContext.checkoutUrl);
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Перейти к оплате'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('subscription-cabinet-primary'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenHandoff('cabinet', appContext.cabinetUrl);
                  },
                  icon: const Icon(Icons.web_outlined),
                  label: const Text('Открыть кабинет'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void _showAccountDetailsSheet(
  BuildContext context, {
  required SeedAppContext appContext,
  required RouteMode selectedRouteMode,
  required String statusLabel,
  required bool hasProvisionedAccess,
  required void Function(String label, String value) onOpenHandoff,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _SeedPalette.surface,
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('profile-account-details-sheet'),
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Аккаунт',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _SeedPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            _KeyValueLine(
              label: 'Доступ',
              value: appContext.accessLane.label,
            ),
            _KeyValueLine(
              label: 'Статус',
              value: statusLabel,
            ),
            _KeyValueLine(
              label: 'Устройство',
              value: appContext.hostPlatform.label,
            ),
            _KeyValueLine(
              label: 'Режим',
              value: selectedRouteMode.label,
            ),
            _KeyValueLine(
              label: 'Профиль',
              value: hasProvisionedAccess ? 'Готов' : 'Готовится',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: const ValueKey('profile-account-details-cabinet'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenHandoff('cabinet', appContext.cabinetUrl);
                  },
                  icon: const Icon(Icons.web_outlined),
                  label: const Text('Кабинет'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('profile-account-details-downloads'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenHandoff(
                      'download',
                      Uri.parse(appContext.cabinetUrl)
                          .replace(path: '/downloads')
                          .toString(),
                    );
                  },
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Загрузки'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('profile-account-details-email'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenHandoff(
                      'download',
                      Uri.parse(appContext.cabinetUrl)
                          .replace(path: '/account/email')
                          .toString(),
                    );
                  },
                  icon: const Icon(Icons.alternate_email_rounded),
                  label: const Text('Email'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void _showEmailRecoverySheet(
  BuildContext context, {
  required SeedAppContext appContext,
  required void Function(String label, String value) onOpenHandoff,
}) {
  final emailUrl =
      Uri.parse(appContext.cabinetUrl).replace(path: '/account/email');
  final recoveryUrl =
      Uri.parse(appContext.cabinetUrl).replace(path: '/auth/recovery');
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _SeedPalette.surface,
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('profile-email-recovery-sheet'),
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email и восстановление',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _SeedPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Email нужен для восстановления доступа и входа в кабинет. Все действия открываются через короткую защищенную сессию.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _SeedPalette.ink.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: const ValueKey('profile-email-add-action'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenHandoff('download', emailUrl.toString());
                  },
                  icon: const Icon(Icons.alternate_email_rounded),
                  label: const Text('Добавить email'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('profile-email-cabinet-action'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenHandoff('cabinet', appContext.cabinetUrl);
                  },
                  icon: const Icon(Icons.web_outlined),
                  label: const Text('Кабинет'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('profile-email-recovery-action'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenHandoff('download', recoveryUrl.toString());
                  },
                  icon: const Icon(Icons.lock_reset_rounded),
                  label: const Text('Восстановить'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void _showRewardsHubSheet(
  BuildContext context, {
  required AppFirstBonusSummary? summary,
  required bool rewardBusy,
  required VoidCallback onRefreshBonusSummary,
  required VoidCallback onSpinWheel,
  required VoidCallback onCheckInCalendar,
  required void Function(String label, String value) onOpenHandoff,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _SeedPalette.surface,
    isScrollControlled: true,
    builder: (context) => _RewardsHubSheet(
      summary: summary,
      rewardBusy: rewardBusy,
      onRefreshBonusSummary: onRefreshBonusSummary,
      onSpinWheel: onSpinWheel,
      onCheckInCalendar: onCheckInCalendar,
      onOpenHandoff: onOpenHandoff,
    ),
  );
}

class _RewardsHubSheet extends StatelessWidget {
  const _RewardsHubSheet({
    required this.summary,
    required this.rewardBusy,
    required this.onRefreshBonusSummary,
    required this.onSpinWheel,
    required this.onCheckInCalendar,
    required this.onOpenHandoff,
  });

  final AppFirstBonusSummary? summary;
  final bool rewardBusy;
  final VoidCallback onRefreshBonusSummary;
  final VoidCallback onSpinWheel;
  final VoidCallback onCheckInCalendar;
  final void Function(String label, String value) onOpenHandoff;

  @override
  Widget build(BuildContext context) {
    final wheel =
        summary?.wheelState ?? AppFirstBonusFeatureState.wheelDisabled;
    final calendar =
        summary?.calendarState ?? AppFirstBonusFeatureState.calendarDisabled;
    final referralSummary = summary == null
        ? AppFirstReferralSummary.empty
        : _rewardsReferralSummary(summary!);
    final referralCode = summary?.referralCode.trim() ?? '';
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('rewards-hub-sheet'),
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Бонусы',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _SeedPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Рабочие бонусы и история сверху. Эксперименты появятся ниже, когда backend включит feature flag.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _SeedPalette.ink.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 14),
            _RewardsReferralCard(
              referralCode: referralCode,
              referralSummary: referralSummary,
              onOpenHandoff: onOpenHandoff,
            ),
            const SizedBox(height: 12),
            _RewardsPromoSlotsSection(
              promoSlots: summary?.promoSlots ?? AppFirstPromoSlots.empty,
              onOpenHandoff: onOpenHandoff,
            ),
            const SizedBox(height: 12),
            _RewardsHistorySection(
              summary: summary,
            ),
            const SizedBox(height: 12),
            _RewardsAchievements(
              summary: summary,
            ),
            const SizedBox(height: 12),
            _RewardsFeatureCard(
              key: const ValueKey('rewards-wheel-card'),
              icon: Icons.casino_outlined,
              title: 'Рулетка',
              status: wheel.statusLabel,
              detail: wheel.availabilityText,
              lastActionAt: wheel.lastActionAt,
              actionKey: const ValueKey('rewards-wheel-spin-action'),
              mutedKey: const ValueKey('rewards-wheel-muted-state'),
              actionLabel: rewardBusy
                  ? 'Готовим'
                  : wheel.canRun
                      ? 'Крутить'
                      : 'Отключено',
              actionEnabled: wheel.canRun && !rewardBusy,
              onAction: () {
                Navigator.of(context).pop();
                onSpinWheel();
              },
            ),
            const SizedBox(height: 10),
            _RewardsFeatureCard(
              key: const ValueKey('rewards-calendar-card'),
              icon: Icons.calendar_month_outlined,
              title: 'Календарь активности',
              status: calendar.statusLabel,
              detail: calendar.availabilityText,
              lastActionAt: calendar.lastActionAt,
              actionKey: const ValueKey('rewards-calendar-checkin-action'),
              mutedKey: const ValueKey('rewards-calendar-muted-state'),
              actionLabel: rewardBusy
                  ? 'Готовим'
                  : calendar.canRun
                      ? 'Отметиться'
                      : 'Отключено',
              actionEnabled: calendar.canRun && !rewardBusy,
              onAction: () {
                Navigator.of(context).pop();
                onCheckInCalendar();
              },
            ),
            const SizedBox(height: 12),
            _RewardsCalendarGrid(
              activeDays: _rewardActiveDays(summary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('rewards-refresh-action'),
              onPressed: () {
                Navigator.of(context).pop();
                onRefreshBonusSummary();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Обновить сводку'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsFeatureCard extends StatelessWidget {
  const _RewardsFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    required this.detail,
    required this.lastActionAt,
    required this.actionKey,
    required this.mutedKey,
    required this.actionLabel,
    required this.actionEnabled,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String status;
  final String detail;
  final String lastActionAt;
  final Key actionKey;
  final Key mutedKey;
  final String actionLabel;
  final bool actionEnabled;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final inactiveReason = detail.trim().isEmpty ? status : detail;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SeedPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SeedPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _SeedPalette.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _SeedPalette.accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _SeedPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _StatusPill(
                label: status,
                icon: Icons.info_outline_rounded,
                tone: _SectionTone.reward,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _SeedPalette.ink.withValues(alpha: 0.70),
                  height: 1.32,
                ),
          ),
          if (lastActionAt.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Последнее действие: $lastActionAt',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _SeedPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          if (actionEnabled)
            FilledButton.icon(
              key: actionKey,
              onPressed: () {
                Feedback.forTap(context);
                onAction?.call();
              },
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(actionLabel),
            )
          else
            KeyedSubtree(
              key: actionKey,
              child: Container(
                key: mutedKey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _SeedPalette.ink.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _SeedPalette.line.withValues(alpha: 0.75),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      size: 18,
                      color: _SeedPalette.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        inactiveReason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: _SeedPalette.muted,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: _SeedPalette.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardsCalendarGrid extends StatelessWidget {
  const _RewardsCalendarGrid({
    required this.activeDays,
  });

  final int activeDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('rewards-calendar-grid'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SeedPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SeedPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Активность',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: _SeedPalette.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: 21,
            itemBuilder: (context, index) {
              final active = index < activeDays;
              return Container(
                key: ValueKey('rewards-calendar-day-$index'),
                decoration: BoxDecoration(
                  color: active
                      ? _SeedPalette.accent.withValues(alpha: 0.16)
                      : _SeedPalette.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active
                        ? _SeedPalette.accent.withValues(alpha: 0.22)
                        : _SeedPalette.line,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RewardsAchievements extends StatelessWidget {
  const _RewardsAchievements({
    required this.summary,
  });

  final AppFirstBonusSummary? summary;

  @override
  Widget build(BuildContext context) {
    final achievements = <({String title, bool active})>[
      (title: 'Первый старт', active: summary?.openingBonusClaimed ?? false),
      (title: 'Telegram', active: summary?.channelBonusClaimed ?? false),
      (title: 'Рефералы', active: (summary?.referralCount ?? 0) > 0),
      (title: 'Серия', active: (summary?.streakMonths ?? 0) > 0),
    ];
    return Container(
      key: const ValueKey('rewards-achievements-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SeedPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SeedPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Достижения',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: _SeedPalette.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: achievements
                .map(
                  (achievement) => _StatusPill(
                    label: achievement.title,
                    icon: achievement.active
                        ? Icons.check_circle_rounded
                        : Icons.lock_clock_outlined,
                    tone: achievement.active
                        ? _SectionTone.accent
                        : _SectionTone.muted,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _RewardsHistorySection extends StatelessWidget {
  const _RewardsHistorySection({
    required this.summary,
  });

  final AppFirstBonusSummary? summary;

  IconData _historyIcon(AppFirstBonusHistoryItem item) {
    switch (item.kind) {
      case 'telegram_channel':
        return Icons.send_outlined;
      case 'promo':
        return Icons.card_giftcard_outlined;
      case 'opening_bonus':
        return Icons.auto_awesome_outlined;
      default:
        return Icons.history_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = summary?.historyItems ?? const <AppFirstBonusHistoryItem>[];
    return Container(
      key: const ValueKey('rewards-history-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SeedPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SeedPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'История',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: _SeedPalette.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'Пока пусто.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _SeedPalette.muted,
                    height: 1.35,
                  ),
            )
          else
            for (final entry in items.indexed)
              _SettingsRow(
                key: ValueKey('rewards-history-item-${entry.$1}'),
                icon: _historyIcon(entry.$2),
                title: entry.$2.title,
                value: entry.$2.compactValue,
              ),
        ],
      ),
    );
  }
}

class _RewardsPromoSlotsSection extends StatelessWidget {
  const _RewardsPromoSlotsSection({
    required this.promoSlots,
    required this.onOpenHandoff,
  });

  final AppFirstPromoSlots promoSlots;
  final void Function(String label, String value) onOpenHandoff;

  @override
  Widget build(BuildContext context) {
    final slots = promoSlots.visibleSlots;
    return Container(
      key: const ValueKey('rewards-promo-slots-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SeedPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SeedPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                color: _SeedPalette.accent,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Акции',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _SeedPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _StatusPill(
                label: promoSlots.remoteAvailable ? 'Обновлено' : 'Нет акций',
                icon: Icons.verified_outlined,
                tone: promoSlots.remoteAvailable
                    ? _SectionTone.accent
                    : _SectionTone.muted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (slots.isEmpty)
            Text(
              key: const ValueKey('rewards-promo-slot-empty'),
              'Сейчас нет персональных акций. Промокод можно ввести в поле кода выше.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _SeedPalette.muted,
                    height: 1.35,
                  ),
            )
          else
            ...slots.map(
              (slot) => _RewardsPromoSlotRow(
                key: ValueKey('rewards-promo-slot-${slot.slotId}'),
                slot: slot,
                onOpenHandoff: onOpenHandoff,
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardsPromoSlotRow extends StatelessWidget {
  const _RewardsPromoSlotRow({
    super.key,
    required this.slot,
    required this.onOpenHandoff,
  });

  final AppFirstPromoSlot slot;
  final void Function(String label, String value) onOpenHandoff;

  @override
  Widget build(BuildContext context) {
    final safeHref = _safePromoSlotHref(slot.ctaHref);
    final ctaLabel = slot.ctaLabel.trim().isEmpty ? 'Открыть' : slot.ctaLabel;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _SeedPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _SeedPalette.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.title.trim().isEmpty ? 'POKROV' : slot.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _SeedPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (slot.body.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    slot.body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _SeedPalette.muted,
                          height: 1.3,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            key: ValueKey('rewards-promo-slot-cta-${slot.slotId}'),
            onPressed: safeHref == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    onOpenHandoff('download', safeHref.toString());
                  },
            child: Text(ctaLabel),
          ),
        ],
      ),
    );
  }
}

Uri? _safePromoSlotHref(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || !uri.hasScheme) {
    return null;
  }
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'https' && scheme != 'tg') {
    return null;
  }
  if (scheme == 'tg') {
    return uri;
  }
  final host = uri.host.toLowerCase();
  if (host == 't.me' ||
      host == 'pokrov.space' ||
      host.endsWith('.pokrov.space')) {
    return uri;
  }
  return null;
}

class _RewardsReferralCard extends StatelessWidget {
  const _RewardsReferralCard({
    required this.referralCode,
    required this.referralSummary,
    required this.onOpenHandoff,
  });

  final String referralCode;
  final AppFirstReferralSummary referralSummary;
  final void Function(String label, String value) onOpenHandoff;

  @override
  Widget build(BuildContext context) {
    final code = referralSummary.code.trim().isNotEmpty
        ? referralSummary.code.trim()
        : referralCode.isEmpty
            ? 'POKROV'
            : referralCode;
    final referralShareLink = referralSummary.shareLink.trim().isNotEmpty
        ? referralSummary.shareLink
        : code == 'POKROV'
            ? ''
            : 'https://t.me/pokrov_vpnbot?start=ref_$code';
    final shareLink = _safeReferralShareHref(referralShareLink);
    return Container(
      key: const ValueKey('rewards-referral-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SeedPalette.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SeedPalette.warning.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_add_outlined, color: _SeedPalette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _SeedPalette.ink,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  referralSummary.bonusDays > 0
                      ? 'Приглашений: ${referralSummary.count} · бонус +${referralSummary.bonusDays} дней'
                      : 'Приглашений: ${referralSummary.count}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _SeedPalette.muted,
                      ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            key: const ValueKey('rewards-referral-copy-action'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Код скопирован')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Копия'),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            key: const ValueKey('rewards-referral-copy-link-action'),
            tooltip: 'Скопировать ссылку',
            onPressed: shareLink == null
                ? null
                : () {
                    Clipboard.setData(
                      ClipboardData(text: shareLink.toString()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ссылка скопирована')),
                    );
                  },
            icon: const Icon(Icons.link_rounded),
          ),
          IconButton.filled(
            key: const ValueKey('rewards-referral-share-action'),
            tooltip: 'Открыть ссылку',
            onPressed: shareLink == null
                ? null
                : () => onOpenHandoff('download', shareLink.toString()),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
    );
  }
}

AppFirstReferralSummary _rewardsReferralSummary(AppFirstBonusSummary summary) {
  final remote = summary.referralSummary;
  if (remote.code.trim().isNotEmpty ||
      remote.link.trim().isNotEmpty ||
      remote.count > 0 ||
      remote.bonusDays > 0) {
    return remote;
  }
  return AppFirstReferralSummary(
    count: summary.referralCount,
    code: summary.referralCode,
    link: '',
    bonusDays: summary.referralBonusDays,
    tierKey: summary.tierKey,
    tierPercent: summary.tierPercent,
    paidReferrals: summary.paidReferrals,
    nextTierKey: summary.nextTierKey,
    nextTierAt: summary.nextTierAt,
  );
}

Uri? _safeReferralShareHref(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || !uri.hasScheme) {
    return null;
  }
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'tg') {
    return uri;
  }
  if (scheme != 'https') {
    return null;
  }
  if (uri.host.toLowerCase() != 't.me') {
    return null;
  }
  return uri;
}

int _rewardActiveDays(AppFirstBonusSummary? summary) {
  if (summary == null) {
    return 0;
  }
  final historyDays = summary.historyItems.length;
  final streakDays = summary.streakMonths * 3;
  return (historyDays + streakDays).clamp(0, 21);
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({
    required this.appContext,
    required this.selectedRouteMode,
    required this.selectedAppIds,
    required this.onRouteModeSelected,
    required this.onSelectedAppAdded,
    required this.onSelectedAppRemoved,
  });

  final SeedAppContext appContext;
  final RouteMode selectedRouteMode;
  final List<String> selectedAppIds;
  final ValueChanged<RouteMode> onRouteModeSelected;
  final ValueChanged<String> onSelectedAppAdded;
  final ValueChanged<String> onSelectedAppRemoved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeChoices = appContext.runtimeProfile.supportedRouteModes;
    final selectedAppsActive = routeChoices.contains(RouteMode.selectedApps);
    final selectedAppsStaged =
        appContext.bootstrapContract.supportsSelectedAppsMode &&
            !selectedAppsActive;
    final rulesContract = appContext.rulesPresetContract;
    final isWindows = appContext.hostPlatform == HostPlatform.windows;

    return _SeedContentList(
      top: 24,
      children: [
        Text('Режим работы', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        _SectionCard(
          title: _brandText('Что идет через POKROV', appContext.variantProfile),
          tone: _SectionTone.accent,
          lines: ['Сейчас · ${_routeModeShortLabel(selectedRouteMode)}'],
          child: Column(
            children: <Widget>[
              ...routeChoices.map(
                (mode) => _SettingsRow(
                  key: ValueKey('rules-mode-row-${mode.name}'),
                  icon: switch (mode) {
                    RouteMode.allExceptRu => Icons.shield_outlined,
                    RouteMode.fullTunnel => Icons.public_rounded,
                    RouteMode.selectedApps => Icons.apps_rounded,
                  },
                  title: _routeModeRowTitle(
                    mode,
                    appContext.variantProfile.displayName,
                  ),
                  value: selectedRouteMode == mode ? 'Выбран' : 'Выбрать',
                  onTap: () => onRouteModeSelected(mode),
                ),
              ),
              _SettingsRow(
                key: const ValueKey('rules-mode-help-action'),
                icon: Icons.info_outline_rounded,
                title: 'Как выбрать',
                value: 'Коротко',
                onTap: () => _showInfoSheet(
                  context,
                  title: 'Режим работы',
                  lines: [
                    '${_routeModeShortLabel(RouteMode.allExceptRu)}: ${_routeModeRowSummary(RouteMode.allExceptRu, appContext.variantProfile.displayName)}',
                    '${_routeModeShortLabel(RouteMode.fullTunnel)}: ${_routeModeRowSummary(RouteMode.fullTunnel, appContext.variantProfile.displayName)}',
                    selectedAppsActive
                        ? '${_routeModeShortLabel(RouteMode.selectedApps)}: ${_routeModeRowSummary(RouteMode.selectedApps, appContext.variantProfile.displayName)}'
                        : selectedAppsStaged
                            ? '${_routeModeShortLabel(RouteMode.selectedApps)}: появится после системной проверки.'
                            : '${_routeModeShortLabel(RouteMode.selectedApps)}: недоступно на ${appContext.hostPlatform.label}.',
                  ],
                ),
              ),
            ],
          ),
        ),
        _SectionCard(
          title: _brandText('Напрямую без POKROV', appContext.variantProfile),
          lines: [
            'Российские и локальные сервисы не ломаются из-за маршрута.',
          ],
          child: Column(
            children: [
              ...rulesContract.presets.map(
                (preset) => _PresetRow(
                  key: ValueKey('rules-preset-${preset.id}'),
                  icon: _rulesPresetIcon(preset.id),
                  title: preset.title,
                  subtitle: preset.subtitle,
                  brandName: appContext.variantProfile.displayName,
                  enabled: preset.enabled,
                  statusLabel: _rulesPresetStatusLabel(preset.state),
                ),
              ),
            ],
          ),
        ),
        if (selectedAppsActive || selectedAppsStaged)
          _SectionCard(
            key: const ValueKey('rules-section-selected-apps'),
            title: 'Выбранные приложения',
            lines: [
              selectedAppIds.isEmpty
                  ? isWindows
                      ? _brandText(
                          'Выберите .exe, которые должны идти через POKROV.',
                          appContext.variantProfile,
                        )
                      : 'Добавьте приложения для режима «только выбранные».'
                  : 'Выбрано: ${selectedAppIds.length}',
            ],
            child: _SelectedAppsEditor(
              hostPlatform: appContext.hostPlatform,
              brandName: appContext.variantProfile.displayName,
              selectedAppIds: selectedAppIds,
              onAdd: onSelectedAppAdded,
              onRemove: onSelectedAppRemoved,
            ),
          ),
      ],
    );
  }
}

class _SelectedAppsEditor extends StatefulWidget {
  const _SelectedAppsEditor({
    required this.hostPlatform,
    required this.brandName,
    required this.selectedAppIds,
    required this.onAdd,
    required this.onRemove,
  });

  final HostPlatform hostPlatform;
  final String brandName;
  final List<String> selectedAppIds;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_SelectedAppsEditor> createState() => _SelectedAppsEditorState();
}

class _SelectedAppsEditorState extends State<_SelectedAppsEditor> {
  late final TextEditingController _controller;
  Future<List<_SelectedAppCandidate>>? _candidateFuture;
  bool _manualEntryVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SelectedAppsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hostPlatform != widget.hostPlatform) {
      _candidateFuture = null;
    }
  }

  void _submit() {
    final normalized = _normalizeSelectedAppIdentifier(_controller.text);
    if (normalized == null) {
      return;
    }
    widget.onAdd(normalized);
    _controller.clear();
  }

  Future<void> _openPicker() async {
    final candidateFuture =
        _candidateFuture ??= _loadSelectedAppCandidates(widget.hostPlatform);
    final candidate = await showModalBottomSheet<_SelectedAppCandidate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _SeedPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SelectedAppsPickerSheet(
        hostPlatform: widget.hostPlatform,
        candidatesFuture: candidateFuture,
        selectedAppIds: widget.selectedAppIds,
      ),
    );
    if (candidate == null) {
      return;
    }
    Feedback.forTap(context);
    widget.onAdd(candidate.identifier);
  }

  @override
  Widget build(BuildContext context) {
    final hint = switch (widget.hostPlatform) {
      HostPlatform.windows => 'telegram.exe',
      HostPlatform.android => 'org.telegram.messenger',
      HostPlatform.ios || HostPlatform.macos => 'app.identifier',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('rules-selected-app-pick'),
          onPressed: _openPicker,
          icon: const Icon(Icons.apps_rounded),
          label: Text(
            widget.hostPlatform == HostPlatform.windows
                ? 'Выбрать процесс'
                : 'Выбрать приложение',
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          key: const ValueKey('rules-selected-app-manual-toggle'),
          onPressed: () {
            setState(() {
              _manualEntryVisible = !_manualEntryVisible;
            });
          },
          icon: Icon(
            _manualEntryVisible
                ? Icons.expand_less_rounded
                : Icons.edit_outlined,
          ),
          label: Text(
            _manualEntryVisible ? 'Скрыть ручной ввод' : 'Добавить вручную',
          ),
        ),
        AnimatedSwitcher(
          duration: _MotionScope.of(context).duration(_MotionTokens.short),
          transitionBuilder: _fadeSlideTransition,
          child: _manualEntryVisible
              ? Padding(
                  key: const ValueKey('rules-selected-app-manual-fields'),
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('rules-selected-app-input'),
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: 'Название или ID',
                            hintText: hint,
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        key: const ValueKey('rules-selected-app-add'),
                        tooltip: 'Добавить приложение',
                        onPressed: _submit,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                )
              : Align(
                  key: const ValueKey('rules-selected-app-manual-hint'),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Если приложения нет в списке, добавьте его вручную.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _SeedPalette.muted,
                          height: 1.35,
                        ),
                  ),
                ),
        ),
        const SizedBox(height: 10),
        if (widget.selectedAppIds.isEmpty)
          Text(
            _brandTextForName(
              'POKROV применит выбранные приложения сам.',
              widget.brandName,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _SeedPalette.muted,
                  height: 1.35,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedAppIds
                .map(
                  (appId) => InputChip(
                    key: ValueKey('rules-selected-app-$appId'),
                    label: Text(appId),
                    avatar: const Icon(Icons.apps_rounded, size: 16),
                    onDeleted: () => widget.onRemove(appId),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

enum _SelectedAppCandidateSource {
  installed,
  installedExecutable,
  runningProcess,
  suggested,
}

class _SelectedAppCandidate {
  const _SelectedAppCandidate({
    required this.label,
    required this.identifier,
    required this.subtitle,
    required this.source,
    required this.icon,
  });

  final String label;
  final String identifier;
  final String subtitle;
  final _SelectedAppCandidateSource source;
  final IconData icon;

  String get searchText => '$label $identifier $subtitle'.toLowerCase().trim();

  String get sourceLabel {
    switch (source) {
      case _SelectedAppCandidateSource.installed:
        return 'Установлено';
      case _SelectedAppCandidateSource.installedExecutable:
        return 'Файл';
      case _SelectedAppCandidateSource.runningProcess:
        return 'Запущено';
      case _SelectedAppCandidateSource.suggested:
        return 'Подсказка';
    }
  }
}

class _SelectedAppsPickerSheet extends StatefulWidget {
  const _SelectedAppsPickerSheet({
    required this.hostPlatform,
    required this.candidatesFuture,
    required this.selectedAppIds,
  });

  final HostPlatform hostPlatform;
  final Future<List<_SelectedAppCandidate>> candidatesFuture;
  final List<String> selectedAppIds;

  @override
  State<_SelectedAppsPickerSheet> createState() =>
      _SelectedAppsPickerSheetState();
}

class _SelectedAppsPickerSheetState extends State<_SelectedAppsPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = _MotionScope.of(context);
    final title = widget.hostPlatform == HostPlatform.windows
        ? 'Процессы Windows'
        : 'Приложения';
    return SizedBox(
      key: const ValueKey('rules-selected-app-picker-sheet'),
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('rules-selected-app-search'),
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  labelText: 'Поиск',
                ),
                onChanged: (value) => setState(() {
                  _query = value.trim().toLowerCase();
                }),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<_SelectedAppCandidate>>(
                  future: widget.candidatesFuture,
                  builder: (context, snapshot) {
                    final fallbackCandidates = _suggestedSelectedAppCandidates(
                      widget.hostPlatform,
                    );
                    if (snapshot.connectionState != ConnectionState.done &&
                        fallbackCandidates.isEmpty) {
                      return const _MotionSkeletonList(
                        rows: 5,
                      );
                    }
                    final rawCandidates =
                        snapshot.connectionState == ConnectionState.done &&
                                snapshot.data != null
                            ? snapshot.data!
                            : fallbackCandidates;
                    final candidates = rawCandidates
                        .where(
                          (candidate) =>
                              _query.isEmpty ||
                              candidate.searchText.contains(_query),
                        )
                        .toList(growable: false);
                    if (candidates.isEmpty) {
                      return Center(
                        child: Text(
                          'Ничего не найдено. Введите ID вручную ниже.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _SeedPalette.muted,
                                  ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: candidates.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: _SeedPalette.line,
                      ),
                      itemBuilder: (context, index) {
                        final candidate = candidates[index];
                        final selected = widget.selectedAppIds
                            .contains(candidate.identifier);
                        return AnimatedOpacity(
                          duration: motion.duration(_MotionTokens.short),
                          opacity: selected ? 0.62 : 1,
                          child: ListTile(
                            key: ValueKey(
                              'rules-selected-app-option-${candidate.identifier}',
                            ),
                            contentPadding: EdgeInsets.zero,
                            enabled: !selected,
                            leading: CircleAvatar(
                              backgroundColor:
                                  _SeedPalette.accent.withValues(alpha: 0.1),
                              foregroundColor: _SeedPalette.accent,
                              child: Icon(candidate.icon, size: 20),
                            ),
                            title: Text(
                              candidate.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  key: ValueKey(
                                    'rules-selected-app-source-${candidate.identifier}',
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _SeedPalette.accent
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    candidate.sourceLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: _SeedPalette.accent,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    candidate.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              color: selected
                                  ? _SeedPalette.success
                                  : _SeedPalette.accent,
                            ),
                            onTap: selected
                                ? null
                                : () => Navigator.of(context).pop(candidate),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _selectedAppsRuntimeChannel =
    MethodChannel('space.pokrov/runtime_engine');

Future<List<_SelectedAppCandidate>> _loadSelectedAppCandidates(
  HostPlatform hostPlatform,
) async {
  final nativeCandidates = switch (hostPlatform) {
    HostPlatform.android => await _loadAndroidInstalledAppCandidates(),
    HostPlatform.windows => <_SelectedAppCandidate>[
        ...await _loadWindowsProcessCandidates(),
        ...await _loadWindowsExecutableCandidates(),
      ],
    HostPlatform.ios || HostPlatform.macos => const <_SelectedAppCandidate>[],
  };
  return _mergeSelectedAppCandidates(
    <_SelectedAppCandidate>[
      ...nativeCandidates,
      ..._suggestedSelectedAppCandidates(hostPlatform),
    ],
  );
}

Future<List<_SelectedAppCandidate>> _loadAndroidInstalledAppCandidates() async {
  try {
    final response = await _selectedAppsRuntimeChannel
        .invokeListMethod<Object?>('runtimeEngine.listInstalledApps')
        .timeout(const Duration(seconds: 2));
    return _candidatesFromHostMaps(
      response,
      source: _SelectedAppCandidateSource.installed,
      icon: Icons.android_rounded,
    );
  } on TimeoutException {
    return const <_SelectedAppCandidate>[];
  } on MissingPluginException {
    return const <_SelectedAppCandidate>[];
  } on PlatformException {
    return const <_SelectedAppCandidate>[];
  }
}

Future<List<_SelectedAppCandidate>> _loadWindowsProcessCandidates() async {
  if (!Platform.isWindows) {
    return const <_SelectedAppCandidate>[];
  }
  try {
    final result = await Process.run(
      'powershell',
      <String>[
        '-NoProfile',
        '-Command',
        r'[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Get-Process | Select-Object -ExpandProperty ProcessName | Sort-Object -Unique | ConvertTo-Json -Compress',
      ],
    ).timeout(const Duration(seconds: 3));
    if (result.exitCode != 0) {
      return const <_SelectedAppCandidate>[];
    }
    final decoded = jsonDecode(result.stdout.toString());
    final names = switch (decoded) {
      final List<Object?> list => list.whereType<String>(),
      final String single => <String>[single],
      _ => const <String>[],
    };
    return names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .map((name) {
          final identifier = name.toLowerCase().endsWith('.exe')
              ? name.toLowerCase()
              : '${name.toLowerCase()}.exe';
          return _SelectedAppCandidate(
            label: identifier,
            identifier: identifier,
            subtitle: identifier,
            source: _SelectedAppCandidateSource.runningProcess,
            icon: Icons.memory_rounded,
          );
        })
        .where((candidate) =>
            _normalizeSelectedAppIdentifier(candidate.identifier) != null)
        .take(120)
        .toList(growable: false);
  } on Object {
    return const <_SelectedAppCandidate>[];
  }
}

Future<List<_SelectedAppCandidate>> _loadWindowsExecutableCandidates() async {
  if (!Platform.isWindows) {
    return const <_SelectedAppCandidate>[];
  }
  try {
    final result = await Process.run(
      'powershell',
      <String>[
        '-NoProfile',
        '-Command',
        r'''
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;
$roots = @(
  $env:ProgramFiles,
  ${env:ProgramFiles(x86)},
  (Join-Path $env:LOCALAPPDATA 'Programs')
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) };
if (-not $roots) { @() | ConvertTo-Json -Compress; exit 0 }
Get-ChildItem -LiteralPath $roots -Filter *.exe -File -Recurse -Depth 3 -ErrorAction SilentlyContinue |
  Sort-Object Name -Unique |
  Select-Object -First 160 `
    @{Name='label';Expression={ if ($_.VersionInfo.FileDescription) { $_.VersionInfo.FileDescription } else { $_.BaseName } }},
    @{Name='identifier';Expression={ $_.Name.ToLowerInvariant() }},
    @{Name='subtitle';Expression={ $_.FullName }} |
  ConvertTo-Json -Compress
''',
      ],
    ).timeout(const Duration(seconds: 3));
    if (result.exitCode != 0) {
      return const <_SelectedAppCandidate>[];
    }
    final decoded = jsonDecode(result.stdout.toString());
    return _candidatesFromHostMaps(
      switch (decoded) {
        final List<Object?> list => list,
        final Map<String, Object?> single => <Object?>[single],
        _ => const <Object?>[],
      },
      source: _SelectedAppCandidateSource.installedExecutable,
      icon: Icons.folder_open_rounded,
    ).take(160).toList(growable: false);
  } on Object {
    return const <_SelectedAppCandidate>[];
  }
}

List<_SelectedAppCandidate> _candidatesFromHostMaps(
  List<Object?>? response, {
  required _SelectedAppCandidateSource source,
  required IconData icon,
}) {
  if (response == null) {
    return const <_SelectedAppCandidate>[];
  }
  final candidates = <_SelectedAppCandidate>[];
  for (final item in response) {
    if (item is! Map) {
      continue;
    }
    final identifier = _normalizeSelectedAppIdentifier(
      item['identifier']?.toString() ?? '',
    );
    if (identifier == null) {
      continue;
    }
    final label = item['label']?.toString().trim();
    final subtitle = item['subtitle']?.toString().trim();
    candidates.add(
      _SelectedAppCandidate(
        label: label == null || label.isEmpty ? identifier : label,
        identifier: identifier,
        subtitle: subtitle == null || subtitle.isEmpty ? identifier : subtitle,
        source: source,
        icon: icon,
      ),
    );
  }
  return candidates;
}

List<_SelectedAppCandidate> _suggestedSelectedAppCandidates(
  HostPlatform hostPlatform,
) {
  switch (hostPlatform) {
    case HostPlatform.android:
      return const <_SelectedAppCandidate>[
        _SelectedAppCandidate(
          label: 'Telegram',
          identifier: 'org.telegram.messenger',
          subtitle: 'org.telegram.messenger',
          source: _SelectedAppCandidateSource.suggested,
          icon: Icons.send_rounded,
        ),
        _SelectedAppCandidate(
          label: 'YouTube',
          identifier: 'com.google.android.youtube',
          subtitle: 'com.google.android.youtube',
          source: _SelectedAppCandidateSource.suggested,
          icon: Icons.play_circle_fill_rounded,
        ),
        _SelectedAppCandidate(
          label: 'Chrome',
          identifier: 'com.android.chrome',
          subtitle: 'com.android.chrome',
          source: _SelectedAppCandidateSource.suggested,
          icon: Icons.public_rounded,
        ),
        _SelectedAppCandidate(
          label: 'Discord',
          identifier: 'com.discord',
          subtitle: 'com.discord',
          source: _SelectedAppCandidateSource.suggested,
          icon: Icons.forum_rounded,
        ),
      ];
    case HostPlatform.windows:
      return const <_SelectedAppCandidate>[
        _SelectedAppCandidate(
          label: 'Telegram',
          identifier: 'telegram.exe',
          subtitle: 'telegram.exe',
          source: _SelectedAppCandidateSource.suggested,
          icon: Icons.send_rounded,
        ),
        _SelectedAppCandidate(
          label: 'Chrome',
          identifier: 'chrome.exe',
          subtitle: 'chrome.exe',
          source: _SelectedAppCandidateSource.suggested,
          icon: Icons.public_rounded,
        ),
        _SelectedAppCandidate(
          label: 'Edge',
          identifier: 'msedge.exe',
          subtitle: 'msedge.exe',
          source: _SelectedAppCandidateSource.suggested,
          icon: Icons.public_rounded,
        ),
        _SelectedAppCandidate(
          label: 'Discord',
          identifier: 'discord.exe',
          subtitle: 'discord.exe',
          source: _SelectedAppCandidateSource.suggested,
          icon: Icons.forum_rounded,
        ),
      ];
    case HostPlatform.ios:
    case HostPlatform.macos:
      return const <_SelectedAppCandidate>[];
  }
}

List<_SelectedAppCandidate> _mergeSelectedAppCandidates(
  List<_SelectedAppCandidate> candidates,
) {
  final seen = <String>{};
  final merged = <_SelectedAppCandidate>[];
  for (final candidate in candidates) {
    final key = candidate.identifier.toLowerCase();
    if (!seen.add(key)) {
      continue;
    }
    merged.add(candidate);
  }
  return merged;
}

String? _normalizeSelectedAppIdentifier(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > 96) {
    return null;
  }
  final safe = RegExp(r'^[a-zA-Z0-9._:-]+$');
  if (!safe.hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

void _showAdvancedSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _SeedPalette.surface,
    builder: (context) {
      return const SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: _AdvancedSettingsCard(
            key: ValueKey('profile-advanced-settings-sheet'),
          ),
        ),
      );
    },
  );
}

void _showRedeemSheet(
  BuildContext context, {
  required String hintCode,
  required String hintPlaceholder,
  required ValueChanged<String> onRedeem,
  String title = 'Код активации',
  String body = 'Введите код из приложения, кабинета, Telegram или письма.',
  String submitLabel = 'Ввести код',
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _SeedPalette.surface,
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('profile-redeem-sheet'),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _SeedPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _SeedPalette.muted,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 14),
            _RedeemFields(
              hintCode: hintCode,
              labelText: hintPlaceholder.startsWith('POKROV-')
                  ? 'Код активации'
                  : 'Ключ профиля',
              hintPlaceholder: hintPlaceholder,
              submitLabel: submitLabel,
              onRedeem: (code) {
                Navigator.of(context).pop();
                onRedeem(code);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _RedeemFields extends StatefulWidget {
  const _RedeemFields({
    required this.hintCode,
    required this.labelText,
    required this.hintPlaceholder,
    required this.submitLabel,
    required this.onRedeem,
  });

  final String hintCode;
  final String labelText;
  final String hintPlaceholder;
  final String submitLabel;
  final ValueChanged<String> onRedeem;

  @override
  State<_RedeemFields> createState() => _RedeemFieldsState();
}

class _RedeemFieldsState extends State<_RedeemFields> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.hintCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('profile-redeem-code-field'),
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintPlaceholder,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('profile-redeem-submit'),
          onPressed: () => widget.onRedeem(_controller.text.trim()),
          icon: const Icon(Icons.verified_outlined),
          label: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _AdvancedSettingsCard extends StatelessWidget {
  const _AdvancedSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Диагностика',
      lines: const [
        'Системные параметры для теста и поддержки.',
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SettingsRow(
            key: ValueKey('advanced-app-version'),
            icon: Icons.info_outline_rounded,
            title: 'Версия приложения',
            value: _pokrovAppVersion,
          ),
          _SettingsRow(
            key: ValueKey('advanced-runtime-core'),
            icon: Icons.memory_rounded,
            title: 'Core',
            value: 'sing-box',
          ),
          _SettingsRow(
            key: ValueKey('advanced-windows-route'),
            icon: Icons.desktop_windows_outlined,
            title: 'Windows-подключение',
            value: 'Системный прокси',
          ),
          _SettingsRow(
            key: ValueKey('advanced-tun-status'),
            icon: Icons.apps_rounded,
            title: 'TUN по приложениям',
            value: 'Готовится',
          ),
          _SettingsRow(
            key: ValueKey('advanced-warp-status'),
            icon: Icons.privacy_tip_outlined,
            title: 'WARP',
            value: 'Скоро',
          ),
          _SettingsRow(
            key: ValueKey('advanced-xray-fallback'),
            icon: Icons.construction_rounded,
            title: 'Совместимый режим',
            value: 'Через поддержку',
          ),
          _SettingsRow(
            key: ValueKey('advanced-support-diagnostics'),
            icon: Icons.support_agent_rounded,
            title: 'Логи и диагностика',
            value: 'В чате поддержки',
          ),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.brandName,
    required this.enabled,
    required this.statusLabel,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String brandName;
  final bool enabled;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: icon,
      title: title,
      value: statusLabel,
      onTap: () => _showInfoSheet(
        context,
        title: title,
        lines: [
          subtitle,
          enabled
              ? 'Этот пресет уже учитывается в текущей карте правил.'
              : _brandTextForName(
                  'POKROV покажет включение, когда пресет пройдет проверку.',
                  brandName,
                ),
        ],
      ),
    );
  }
}

IconData _rulesPresetIcon(String id) {
  return switch (id) {
    'ru-banks' => Icons.account_balance_outlined,
    'gosuslugi' => Icons.verified_user_outlined,
    'marketplaces' => Icons.shopping_bag_outlined,
    'messengers' => Icons.forum_outlined,
    'ru-region' => Icons.travel_explore_outlined,
    'local-network' => Icons.router_outlined,
    'full-tunnel' => Icons.public_outlined,
    'selected-apps' => Icons.add_box_outlined,
    _ => Icons.rule_folder_outlined,
  };
}

String _rulesPresetStatusLabel(RulesPresetState state) {
  return switch (state) {
    RulesPresetState.enabled => 'Активно',
    RulesPresetState.staged => 'Готовится',
    RulesPresetState.locked => 'Недоступно',
  };
}

String _accessPoolLabel(AccessLane lane) {
  return switch (lane) {
    AccessLane.trialPremium ||
    AccessLane.bonusPremium ||
    AccessLane.paidUnlimited =>
      'Премиум-пул',
    AccessLane.freeMonthly || AccessLane.freeSoftMode => 'Бесплатный узел',
  };
}

String _accessMainLabel(
    SeedAppContext appContext, AppFirstBonusSummary? bonus) {
  final baseDays = appContext.runtimeProfile.trialDays;
  final bonusDays = bonus?.channelBonusPremiumDays ?? 0;
  final claimed = (bonus?.channelBonusClaimedAt ?? '').trim().isNotEmpty;
  final totalDays = baseDays + (claimed ? bonusDays : 0);
  return switch (appContext.accessLane) {
    AccessLane.trialPremium =>
      claimed ? '$totalDays дней доступа' : '$baseDays дней пробного доступа',
    AccessLane.bonusPremium => '$totalDays дней доступа',
    AccessLane.paidUnlimited => 'Премиум активен',
    AccessLane.freeMonthly => 'Базовый режим',
    AccessLane.freeSoftMode => 'Лимит закончился',
  };
}

String _accessShortValue(
  SeedAppContext appContext,
  AppFirstBonusSummary? bonus,
) {
  final baseDays = appContext.runtimeProfile.trialDays;
  final bonusDays = bonus?.channelBonusPremiumDays ?? 0;
  final claimed = (bonus?.channelBonusClaimedAt ?? '').trim().isNotEmpty;
  final totalDays = baseDays + (claimed ? bonusDays : 0);
  return switch (appContext.accessLane) {
    AccessLane.trialPremium => claimed ? '$totalDays дней' : '$baseDays дней',
    AccessLane.bonusPremium => '$totalDays дней',
    AccessLane.paidUnlimited => 'Премиум',
    AccessLane.freeMonthly => 'Базовый',
    AccessLane.freeSoftMode => 'Лимит',
  };
}

String _telegramBonusHomeLabel(
  SeedAppContext appContext,
  AppFirstBonusSummary? bonus,
) {
  final claimed = (bonus?.channelBonusClaimedAt ?? '').trim().isNotEmpty;
  if (claimed) {
    return 'Telegram-бонус активен';
  }
  return '+${appContext.runtimeProfile.telegramBonusDays} дней за Telegram';
}

String _routeModeShortLabel(RouteMode mode) {
  return switch (mode) {
    RouteMode.allExceptRu => 'Всё, кроме РФ',
    RouteMode.fullTunnel => 'Всё устройство',
    RouteMode.selectedApps => 'Выбранные приложения',
  };
}

String _routeModeRowTitle(RouteMode mode, String brandName) {
  final value = switch (mode) {
    RouteMode.allExceptRu => 'Российские сервисы напрямую',
    RouteMode.fullTunnel => 'Всё устройство через POKROV',
    RouteMode.selectedApps => 'Только выбранные приложения',
  };
  return _brandTextForName(value, brandName);
}

String _routeModeRowSummary(RouteMode mode, String brandName) {
  final value = switch (mode) {
    RouteMode.allExceptRu =>
      'Российские и локальные сервисы работают напрямую, остальное идет через POKROV.',
    RouteMode.fullTunnel => 'Весь трафик устройства идет через POKROV.',
    RouteMode.selectedApps =>
      'POKROV используют только выбранные приложения или .exe.',
  };
  return _brandTextForName(value, brandName);
}

String _smartConnectNodeTitle(SmartConnectNode node) {
  final country = node.country.trim();
  final code = node.code.trim().toUpperCase();
  if (country.isNotEmpty && code.isNotEmpty) {
    return '$country · $code';
  }
  if (country.isNotEmpty) {
    return country;
  }
  return code.isEmpty ? 'POKROV' : code;
}

class _SettingsRow extends PokrovSettingsRow {
  const _SettingsRow({
    super.key,
    required super.icon,
    required super.title,
    required super.value,
    super.onTap,
  });
}

const _communityKeyImportBody =
    'Paste one VLESS, Trojan, Shadowsocks, or VMess key. The key is parsed on this device and is not sent to POKROV.';
const _communitySubscriptionImportBody =
    'The client fetches the URL, parses supported keys, and stores profiles locally. Refresh runs only when you tap it or when the app returns to foreground.';
const _communityQrImportBody =
    'Paste the decoded QR payload. Camera scanning and pasted QR text stay local and use the same profile parser.';
const _communityFreeCatalogLines = <String>[
  'This section is opt-in and disabled by default.',
  'Candidate feed: AvenCores/goida-vpn-configs.',
  'Third-party public configs are not official POKROV nodes.',
  'The client does not promise speed, privacy, uptime, safety, legality, or availability for third-party public configs.',
];

void _showInfoSheet(
  BuildContext context, {
  required String title,
  required List<String> lines,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _SeedPalette.surface,
    builder: (context) => _InfoSheet(title: title, lines: lines),
  );
}

void _showCommunityImportHubSheet(
  BuildContext context, {
  required VoidCallback onAddKey,
  required VoidCallback onAddSubscription,
  required VoidCallback onImportQr,
  required VoidCallback onOpenFreeCatalog,
  required bool hasCameraQr,
  required int profileCount,
  required int subscriptionSourceCount,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _SeedPalette.surface,
    builder: (sheetContext) => _CommunityImportHubSheet(
      hasCameraQr: hasCameraQr,
      profileCount: profileCount,
      subscriptionSourceCount: subscriptionSourceCount,
      onAddKey: () {
        Navigator.of(sheetContext).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) => onAddKey());
      },
      onAddSubscription: () {
        Navigator.of(sheetContext).pop();
        WidgetsBinding.instance
            .addPostFrameCallback((_) => onAddSubscription());
      },
      onImportQr: () {
        Navigator.of(sheetContext).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) => onImportQr());
      },
      onOpenFreeCatalog: () {
        Navigator.of(sheetContext).pop();
        WidgetsBinding.instance
            .addPostFrameCallback((_) => onOpenFreeCatalog());
      },
    ),
  );
}

class _CommunityImportHubSheet extends StatelessWidget {
  const _CommunityImportHubSheet({
    required this.onAddKey,
    required this.onAddSubscription,
    required this.onImportQr,
    required this.onOpenFreeCatalog,
    required this.hasCameraQr,
    required this.profileCount,
    required this.subscriptionSourceCount,
  });

  final VoidCallback onAddKey;
  final VoidCallback onAddSubscription;
  final VoidCallback onImportQr;
  final VoidCallback onOpenFreeCatalog;
  final bool hasCameraQr;
  final int profileCount;
  final int subscriptionSourceCount;

  @override
  Widget build(BuildContext context) {
    final qrTitle = hasCameraQr ? 'Scan QR code' : 'Import QR text';
    final qrValue = hasCameraQr ? 'Camera' : 'Paste';
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('profile-import-hub-sheet'),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import profiles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _SeedPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how to add local Open Client profiles. Keys, QR payloads, and subscription URLs stay on this device.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _SeedPalette.muted,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$profileCount local profile(s) · $subscriptionSourceCount subscription source(s)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _SeedPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),
            _SettingsRow(
              key: const ValueKey('import-hub-key-action'),
              icon: Icons.key_rounded,
              title: 'Add profile key',
              value: 'Paste',
              onTap: onAddKey,
            ),
            _SettingsRow(
              key: const ValueKey('import-hub-subscription-action'),
              icon: Icons.sync_rounded,
              title: 'Add subscription URL',
              value: 'Fetch',
              onTap: onAddSubscription,
            ),
            _SettingsRow(
              key: const ValueKey('import-hub-qr-action'),
              icon: Icons.qr_code_scanner_rounded,
              title: qrTitle,
              value: qrValue,
              onTap: onImportQr,
            ),
            _SettingsRow(
              key: const ValueKey('import-hub-free-catalog-action'),
              icon: Icons.public_rounded,
              title: 'Free VPN catalog',
              value: 'Off',
              onTap: onOpenFreeCatalog,
            ),
          ],
        ),
      ),
    );
  }
}

void _showWarpConsentSheet(
  BuildContext context, {
  required PokrovWarpLifecycle lifecycle,
  required bool enabled,
  required Future<void> Function(bool value) onChanged,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: _SeedPalette.surface,
    builder: (context) => _WarpConsentSheet(
      lifecycle: lifecycle,
      enabled: enabled,
      onChanged: onChanged,
    ),
  );
}

class _WarpConsentSheet extends StatelessWidget {
  const _WarpConsentSheet({
    required this.lifecycle,
    required this.enabled,
    required this.onChanged,
  });

  final PokrovWarpLifecycle lifecycle;
  final bool enabled;
  final Future<void> Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final nextValue = !enabled;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('home-warp-sheet'),
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _SeedPalette.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: _SeedPalette.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lifecycle.publicSheetTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _SeedPalette.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lifecycle.publicSheetBody,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _SeedPalette.muted,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  key: const ValueKey('home-warp-consent-switch'),
                  value: enabled,
                  activeThumbColor: _SeedPalette.accent,
                  onChanged: (value) {
                    unawaited(onChanged(value));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('home-warp-enable-action'),
              icon: enabled
                  ? const Icon(Icons.shield_outlined)
                  : const Icon(Icons.verified_user_rounded),
              label: Text(lifecycle.publicActionLabel),
              onPressed: () {
                unawaited(onChanged(nextValue));
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _SeedPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _SeedPalette.ink.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportChatScreen extends StatefulWidget {
  const _SupportChatScreen({
    required this.appContext,
    required this.selectedRouteMode,
    required this.statusLabel,
    required this.extraDiagnostics,
    required this.supportTicketService,
    required this.onOpenHandoff,
  });

  final SeedAppContext appContext;
  final RouteMode selectedRouteMode;
  final String statusLabel;
  final Map<String, Object?> extraDiagnostics;
  final SupportTicketService supportTicketService;
  final void Function(String label, String value) onOpenHandoff;

  @override
  State<_SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<_SupportChatScreen> {
  static const _threadPollInterval = Duration(seconds: 10);

  late final TextEditingController _composer;
  late final FocusNode _composerFocusNode;
  Timer? _threadPollTimer;
  bool _sending = false;
  bool _loadingThread = true;
  bool _refreshingThread = false;
  bool _threadRefreshFailed = false;
  bool _threadClosed = false;
  bool _hasOperatorReply = false;
  int? _ticketId;
  String _threadStatus = 'AI помощник';
  String? _threadError;
  late List<_SupportChatMessage> _messages;
  bool _attachDiagnosticsToNextMessage = false;

  @override
  void initState() {
    super.initState();
    _composer = TextEditingController();
    _composerFocusNode = FocusNode(debugLabel: 'support-composer');
    _messages =
        _supportGreetingMessages(widget.appContext.variantProfile.displayName);
    unawaited(_loadInitialThread());
  }

  @override
  void dispose() {
    _threadPollTimer?.cancel();
    _composerFocusNode.dispose();
    _composer.dispose();
    super.dispose();
  }

  Future<void> _loadInitialThread() async {
    setState(() {
      _loadingThread = true;
      _threadError = null;
    });

    try {
      final tickets = await widget.supportTicketService.listTickets(
        hostPlatform: widget.appContext.hostPlatform,
        limit: 5,
      );
      SupportTicketThread? selected;
      for (final ticket in tickets) {
        if (!ticket.isClosed) {
          selected = ticket;
          break;
        }
      }
      selected ??= tickets.isEmpty ? null : tickets.first;

      if (selected == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _ticketId = null;
          _threadClosed = false;
          _threadRefreshFailed = false;
          _hasOperatorReply = false;
          _loadingThread = false;
          _messages = _supportGreetingMessages(
            widget.appContext.variantProfile.displayName,
          );
          _threadStatus = 'AI помощник';
        });
        _syncThreadPolling();
        return;
      }

      final thread = await widget.supportTicketService.getTicket(
        hostPlatform: widget.appContext.hostPlatform,
        ticketId: selected.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingThread = false;
        _applyThread(thread);
      });
      _syncThreadPolling();
    } on SupportTicketFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingThread = false;
        _threadClosed = false;
        _threadRefreshFailed = false;
        _hasOperatorReply = false;
        _threadError = error.message;
      });
      _syncThreadPolling();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingThread = false;
        _threadError = 'Не удалось загрузить историю поддержки.';
      });
    }
  }

  void _applyThread(SupportTicketThread thread) {
    _ticketId = thread.id;
    _threadClosed = thread.isClosed;
    _threadStatus =
        thread.statusTitle.isEmpty ? thread.status : thread.statusTitle;
    final nextMessages = _messagesFromThread(thread);
    _messages = nextMessages.isEmpty
        ? _supportGreetingMessages(
            widget.appContext.variantProfile.displayName,
          )
        : nextMessages;
    _hasOperatorReply = nextMessages
        .any((message) => message.role == _SupportChatRole.operator);
    _threadRefreshFailed = false;
  }

  void _syncThreadPolling() {
    _threadPollTimer?.cancel();
    _threadPollTimer = null;
    if (!mounted ||
        _ticketId == null ||
        _threadClosed ||
        _loadingThread ||
        _threadError != null) {
      return;
    }
    _threadPollTimer = Timer.periodic(
      _threadPollInterval,
      (_) => unawaited(_refreshActiveThread()),
    );
  }

  Future<void> _refreshActiveThread() async {
    final activeTicketId = _ticketId;
    if (activeTicketId == null ||
        _threadClosed ||
        _loadingThread ||
        _sending ||
        _refreshingThread) {
      return;
    }
    setState(() {
      _refreshingThread = true;
    });
    try {
      final thread = await widget.supportTicketService.getTicket(
        hostPlatform: widget.appContext.hostPlatform,
        ticketId: activeTicketId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _refreshingThread = false;
        _threadError = null;
        _applyThread(thread);
      });
      _syncThreadPolling();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _refreshingThread = false;
        _threadRefreshFailed = true;
      });
    }
  }

  _SupportLifecycleState get _supportLifecycleState {
    if (_loadingThread) {
      return _SupportLifecycleState.loading;
    }
    if (_threadError != null || _threadRefreshFailed) {
      return _SupportLifecycleState.offline;
    }
    if (_refreshingThread) {
      return _SupportLifecycleState.refreshing;
    }
    if (_threadClosed) {
      return _SupportLifecycleState.closed;
    }
    if (_hasOperatorReply) {
      return _SupportLifecycleState.operator;
    }
    if (_ticketId != null) {
      return _SupportLifecycleState.tracking;
    }
    return _SupportLifecycleState.ready;
  }

  void _retrySupportLifecycle() {
    if (_ticketId == null) {
      unawaited(_loadInitialThread());
      return;
    }
    setState(() {
      _threadRefreshFailed = false;
    });
    unawaited(_refreshActiveThread());
  }

  void _applyAssistantSuggestion(PokrovAssistantSuggestion suggestion) {
    setState(() {
      _composer.text = suggestion.prompt;
      _composer.selection = TextSelection.collapsed(
        offset: _composer.text.length,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending || _loadingThread) {
      return;
    }
    final attachDiagnostics = _attachDiagnosticsToNextMessage;
    final diagnostics =
        attachDiagnostics ? _supportDiagnostics() : const <String, Object?>{};
    setState(() {
      _messages
          .add(_SupportChatMessage(role: _SupportChatRole.user, body: text));
      _composer.clear();
      _sending = true;
    });

    try {
      final activeTicketId = _ticketId;
      if (activeTicketId != null) {
        final thread = await widget.supportTicketService.sendMessage(
          hostPlatform: widget.appContext.hostPlatform,
          ticketId: activeTicketId,
          body: text,
          routeMode: attachDiagnostics ? widget.selectedRouteMode : null,
          statusLabel: attachDiagnostics ? widget.statusLabel : '',
          diagnostics: diagnostics,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _sending = false;
          _attachDiagnosticsToNextMessage = false;
          _applyThread(thread);
        });
        _syncThreadPolling();
        return;
      }

      final receipt = await widget.supportTicketService.createTicket(
        hostPlatform: widget.appContext.hostPlatform,
        routeMode: widget.selectedRouteMode,
        statusLabel: widget.statusLabel,
        subject:
            'Обращение из приложения ${widget.appContext.variantProfile.displayName}',
        body: text,
        diagnostics: _supportDiagnostics(),
      );
      _ticketId = receipt.ticketId;
      if (!mounted) {
        return;
      }
      setState(() {
        _sending = false;
        _attachDiagnosticsToNextMessage = false;
        _messages.add(
          _SupportChatMessage(
            role: _SupportChatRole.assistant,
            label: 'Поддержка',
            body:
                'Обращение #${receipt.ticketId} создано. Ответ появится здесь; Telegram остается запасным каналом.',
          ),
        );
      });
      _syncThreadPolling();
      try {
        final thread = await widget.supportTicketService.getTicket(
          hostPlatform: widget.appContext.hostPlatform,
          ticketId: receipt.ticketId,
        );
        if (!mounted || thread.messages.isEmpty) {
          return;
        }
        setState(() {
          _applyThread(thread);
        });
        _syncThreadPolling();
      } catch (_) {
        // Keep the local confirmation when the immediate refresh is unavailable.
      }
    } on SupportTicketFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sending = false;
        _messages.add(
          _SupportChatMessage(
            role: _SupportChatRole.assistant,
            body:
                'Не удалось отправить обращение: ${error.message}. Откройте Telegram сверху или попробуйте еще раз.',
          ),
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sending = false;
        _messages.add(
          const _SupportChatMessage(
            role: _SupportChatRole.assistant,
            body:
                'Не удалось отправить обращение. Откройте Telegram сверху или попробуйте еще раз.',
          ),
        );
      });
    }
  }

  Map<String, Object?> _supportDiagnostics() {
    return <String, Object?>{
      'app_version': _pokrovAppVersion,
      'platform': widget.appContext.hostPlatform.name,
      'route_mode': widget.selectedRouteMode.name,
      'connection_status': widget.statusLabel,
      'selected_region': '${widget.appContext.variantProfile.displayName} auto',
      ...widget.extraDiagnostics,
    };
  }

  List<_SupportChatMessage> _messagesFromThread(SupportTicketThread thread) {
    final messages = <_SupportChatMessage>[];
    for (final message in thread.messages) {
      final body = message.body.trim();
      if (body.isEmpty) {
        continue;
      }
      final role = _supportRoleFromSender(message.senderRole);
      messages.add(
        _SupportChatMessage(
          role: role,
          label: _supportLabelForRole(role),
          body: body,
        ),
      );
    }
    return messages;
  }

  _SupportChatRole _supportRoleFromSender(String senderRole) {
    final role = senderRole.toLowerCase();
    if (role == 'user') {
      return _SupportChatRole.user;
    }
    if (role == 'admin' || role == 'operator' || role == 'support') {
      return _SupportChatRole.operator;
    }
    return _SupportChatRole.assistant;
  }

  String _supportLabelForRole(_SupportChatRole role) {
    return switch (role) {
      _SupportChatRole.user => '',
      _SupportChatRole.operator => 'Поддержка',
      _SupportChatRole.assistant => 'AI помощник',
    };
  }

  void _showDiagnosticsPreview() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _SeedPalette.surface,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            key: const ValueKey('support-diagnostics-preview'),
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Диагностика',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _SeedPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                _KeyValueLine(
                  label: 'Устройство',
                  value: widget.appContext.hostPlatform.label,
                ),
                _KeyValueLine(
                  label: 'Режим',
                  value: widget.selectedRouteMode.label,
                ),
                _KeyValueLine(
                  label: 'Статус',
                  value: widget.statusLabel,
                ),
                _KeyValueLine(
                  label: 'Версия',
                  value: _pokrovAppVersion,
                ),
                const SizedBox(height: 10),
                Text(
                  'Мы прикрепим только безопасную сводку: устройство, режим, статус и версию.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _SeedPalette.muted,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: const ValueKey('support-diagnostics-close'),
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Готово'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      key: const ValueKey('support-diagnostics-attach-next'),
                      onPressed: () {
                        setState(() {
                          _attachDiagnosticsToNextMessage = true;
                        });
                        Navigator.of(context).maybePop();
                      },
                      icon: const Icon(Icons.attach_file_rounded, size: 18),
                      label: const Text('Прикрепить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      key: const ValueKey('support-chat-shortcuts'),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _FocusSupportComposerIntent(),
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            _SendSupportMessageIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FocusSupportComposerIntent:
              CallbackAction<_FocusSupportComposerIntent>(
            onInvoke: (_) {
              _composerFocusNode.requestFocus();
              return null;
            },
          ),
          _SendSupportMessageIntent: CallbackAction<_SendSupportMessageIntent>(
            onInvoke: (_) {
              if (!_sending && !_loadingThread) {
                unawaited(_sendMessage());
              }
              return null;
            },
          ),
        },
        child: Focus(
          key: const ValueKey('support-chat-focus-root'),
          autofocus: true,
          child: Scaffold(
            key: const ValueKey('support-chat-screen'),
            backgroundColor: _SeedPalette.canvas,
            appBar: AppBar(
              title: const Text('Поддержка'),
              actions: [
                TextButton(
                  key: const ValueKey('support-chat-telegram-fallback'),
                  onPressed: () => widget.onOpenHandoff(
                    'support',
                    widget.appContext.supportSnapshot.supportBot,
                  ),
                  child: Text(widget.appContext.supportSnapshot.supportBot),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                    child: _SupportChatHeader(
                      status: _loadingThread
                          ? 'Загружаем'
                          : _sending
                              ? 'Отправляем'
                              : _refreshingThread
                                  ? 'Обновляем чат'
                                  : _threadStatus,
                      details:
                          '${widget.appContext.hostPlatform.label} · ${widget.selectedRouteMode.label} · ${widget.statusLabel}',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    child: _SupportLifecycleHint(
                      state: _supportLifecycleState,
                      brandName: widget.appContext.variantProfile.displayName,
                      onRetry: _retrySupportLifecycle,
                    ),
                  ),
                  if (_threadError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: _SupportChatNotice(
                        body: _threadError!,
                        onRetry: () => unawaited(_loadInitialThread()),
                      ),
                    ),
                  Expanded(
                    child: _loadingThread
                        ? const _SupportChatSkeleton()
                        : ListView.builder(
                            key: const ValueKey('support-chat-message-list'),
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return _SupportChatBubble(
                                message: _messages[index],
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_loadingThread)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SupportAssistantSuggestions(
                              suggestions: PokrovAssistantContract
                                  .defaultSupportSuggestions,
                              onSelected: _applyAssistantSuggestion,
                            ),
                          ),
                        if (_attachDiagnosticsToNextMessage)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SupportDiagnosticsQueuedPill(
                              onClear: () {
                                setState(() {
                                  _attachDiagnosticsToNextMessage = false;
                                });
                              },
                            ),
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: _SeedPalette.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _SeedPalette.line),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                IconButton(
                                  key: const ValueKey(
                                    'support-attach-diagnostics',
                                  ),
                                  tooltip: 'Диагностика',
                                  icon: const Icon(Icons.attach_file_rounded),
                                  onPressed: _showDiagnosticsPreview,
                                ),
                                Expanded(
                                  child: TextField(
                                    key: const ValueKey(
                                      'support-chat-composer',
                                    ),
                                    controller: _composer,
                                    focusNode: _composerFocusNode,
                                    minLines: 1,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      hintText: 'Напишите сообщение',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onSubmitted: (_) =>
                                        unawaited(_sendMessage()),
                                  ),
                                ),
                                IconButton(
                                  key: const ValueKey('support-chat-send'),
                                  tooltip: 'Отправить',
                                  icon: _sending
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send_rounded),
                                  onPressed: (_sending || _loadingThread)
                                      ? null
                                      : () => unawaited(_sendMessage()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportChatSkeleton extends StatelessWidget {
  const _SupportChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('support-chat-skeleton'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      children: const [
        PokrovSkeletonLine(width: 210, height: 12),
        SizedBox(height: 14),
        PokrovSkeletonLine(height: 72, radius: 16, opacity: 0.08),
        SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: PokrovSkeletonLine(width: 240, height: 64, radius: 16),
        ),
        SizedBox(height: 10),
        PokrovSkeletonLine(width: 280, height: 74, radius: 16, opacity: 0.08),
      ],
    );
  }
}

class _SupportDiagnosticsQueuedPill extends StatelessWidget {
  const _SupportDiagnosticsQueuedPill({
    required this.onClear,
  });

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const ValueKey('support-diagnostics-queued'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _SeedPalette.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _SeedPalette.accent.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: _SeedPalette.accent,
            ),
            const SizedBox(width: 6),
            Text(
              'Диагностика будет приложена',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _SeedPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 4),
            IconButton(
              key: const ValueKey('support-diagnostics-clear'),
              tooltip: 'Не прикладывать',
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              constraints: const BoxConstraints(
                minWidth: 26,
                minHeight: 26,
              ),
              padding: EdgeInsets.zero,
              onPressed: onClear,
              icon: const Icon(
                Icons.close_rounded,
                color: _SeedPalette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportAssistantSuggestions extends StatelessWidget {
  const _SupportAssistantSuggestions({
    required this.suggestions,
    required this.onSelected,
  });

  final List<PokrovAssistantSuggestion> suggestions;
  final ValueChanged<PokrovAssistantSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        key: const ValueKey('support-assistant-suggestions'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final suggestion in suggestions) ...[
              ActionChip(
                key: ValueKey(suggestion.key),
                avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(suggestion.title),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: _SeedPalette.line),
                backgroundColor: _SeedPalette.surface,
                onPressed: () => onSelected(suggestion),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

enum _SupportChatRole {
  user,
  assistant,
  operator,
}

class _SupportChatMessage {
  const _SupportChatMessage({
    required this.role,
    required this.body,
    this.label = '',
  });

  final _SupportChatRole role;
  final String body;
  final String label;
}

List<_SupportChatMessage> _supportGreetingMessages(String brandName) {
  return <_SupportChatMessage>[
    _SupportChatMessage(
      role: _SupportChatRole.assistant,
      label: 'AI помощник',
      body: _brandTextForName(
        'Напишите, что случилось. POKROV приложит безопасный контекст и покажет ответ в этом чате.',
        brandName,
      ),
    ),
  ];
}

enum _SupportLifecycleState {
  loading,
  ready,
  tracking,
  refreshing,
  operator,
  closed,
  offline,
}

class _SupportLifecycleHint extends StatelessWidget {
  const _SupportLifecycleHint({
    required this.state,
    required this.brandName,
    required this.onRetry,
  });

  final _SupportLifecycleState state;
  final String brandName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final data = switch (state) {
      _SupportLifecycleState.loading => (
          key: 'loading',
          icon: Icons.sync_rounded,
          label: 'Загружаем диалог',
          detail: 'История поддержки появится здесь.',
          accent: _SeedPalette.muted,
          retry: false,
        ),
      _SupportLifecycleState.ready => (
          key: 'ready',
          icon: Icons.smart_toy_outlined,
          label: 'AI помощник на месте',
          detail: 'Оператор подключится через тикет, если вопрос не решится.',
          accent: _SeedPalette.muted,
          retry: false,
        ),
      _SupportLifecycleState.tracking => (
          key: 'tracking',
          icon: Icons.mark_chat_unread_outlined,
          label: 'Ответ появится здесь',
          detail: _brandTextForName(
            'POKROV проверяет тикет в фоне. Telegram остается запасным.',
            brandName,
          ),
          accent: _SeedPalette.accent,
          retry: false,
        ),
      _SupportLifecycleState.refreshing => (
          key: 'refreshing',
          icon: Icons.sync_rounded,
          label: 'Обновляем диалог',
          detail: 'Проверяем новые ответы без перехода в Telegram.',
          accent: _SeedPalette.accent,
          retry: false,
        ),
      _SupportLifecycleState.operator => (
          key: 'operator',
          icon: Icons.support_agent_rounded,
          label: 'Поддержка ответила',
          detail: 'Продолжайте диалог здесь или через Telegram.',
          accent: _SeedPalette.accent,
          retry: false,
        ),
      _SupportLifecycleState.closed => (
          key: 'closed',
          icon: Icons.check_circle_outline_rounded,
          label: 'Обращение закрыто',
          detail: 'Можно написать новое сообщение, если вопрос вернулся.',
          accent: _SeedPalette.success,
          retry: false,
        ),
      _SupportLifecycleState.offline => (
          key: 'offline',
          icon: Icons.cloud_off_outlined,
          label: 'Чат временно не обновился',
          detail:
              'Сообщения не потеряны. Можно повторить или открыть Telegram.',
          accent: _SeedPalette.warning,
          retry: true,
        ),
    };

    return Container(
      key: ValueKey('support-thread-lifecycle-${data.key}'),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: data.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(data.icon, size: 18, color: data.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _SeedPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _SeedPalette.muted,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
          if (data.retry) ...[
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('support-thread-refresh-action'),
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportChatHeader extends StatelessWidget {
  const _SupportChatHeader({
    required this.status,
    required this.details,
  });

  final String status;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SeedPalette.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _SeedPalette.accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _SeedPalette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: _SeedPalette.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _SeedPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _SeedPalette.muted,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportChatNotice extends StatelessWidget {
  const _SupportChatNotice({
    required this.body,
    required this.onRetry,
  });

  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _SeedPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _SeedPalette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: _SeedPalette.muted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _SeedPalette.muted,
                      height: 1.25,
                    ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportChatBubble extends StatelessWidget {
  const _SupportChatBubble({
    required this.message,
  });

  final _SupportChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _SupportChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? _SeedPalette.accent : _SeedPalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: _SeedPalette.line),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser && message.label.isNotEmpty) ...[
              Text(
                message.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _SeedPalette.muted,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isUser ? Colors.white : _SeedPalette.ink,
                    height: 1.3,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _consumerProtectionStatusLabel(
  RuntimeSnapshot? snapshot, {
  bool busy = false,
}) {
  if (busy) {
    return 'Готовим';
  }
  if (snapshot == null) {
    return 'Проверяем статус';
  }
  if (snapshot.phase == RuntimePhase.running) {
    return snapshot.isCleanlyHealthy ? 'Включено' : 'Нужно внимание';
  }
  if (snapshot.phase == RuntimePhase.artifactMissing) {
    return 'Недоступно';
  }
  if ((snapshot.stagedConfigPath ?? '').isNotEmpty) {
    return 'Готово к подключению';
  }
  return 'Готово';
}

String? _motionRecoveryNotice(
  RuntimeSnapshot? snapshot, {
  required String? headline,
  required bool busy,
}) {
  if (busy) {
    return null;
  }
  final text = (headline ?? '').trim();
  if (text.isEmpty) {
    return null;
  }
  final normalized = text.toLowerCase();
  final looksRecoverable = normalized.contains('не смог') ||
      normalized.contains('не удалось') ||
      normalized.contains('ошиб') ||
      normalized.contains('отказ') ||
      normalized.contains('failed') ||
      normalized.contains('denied') ||
      normalized.contains('error') ||
      normalized.contains('недоступ');
  if (looksRecoverable) {
    return text;
  }
  if (snapshot != null &&
      snapshot.phase != RuntimePhase.running &&
      normalized.contains('подготов')) {
    return text;
  }
  if (snapshot != null && snapshot.phase != RuntimePhase.running) {
    return text;
  }
  return null;
}

String _consumerProtectionStatusSummary(
  RuntimeSnapshot? snapshot, {
  required String? headline,
  required HostPlatform hostPlatform,
  required String brandName,
}) {
  if ((headline ?? '').trim().isNotEmpty) {
    return headline!.trim();
  }
  if (snapshot == null) {
    return 'Проверяем, готово ли устройство ${hostPlatform.label}.';
  }
  if (snapshot.phase == RuntimePhase.running) {
    final value = snapshot.isCleanlyHealthy
        ? 'POKROV работает на этом устройстве.'
        : 'POKROV включен, но заметил состояние, которое стоит проверить.';
    return _brandTextForName(value, brandName);
  }
  if (snapshot.phase == RuntimePhase.artifactMissing) {
    return 'Устройство еще завершает подготовку перед подключением.';
  }
  if ((snapshot.stagedConfigPath ?? '').isNotEmpty) {
    return 'Все готово. Нажмите главную кнопку, чтобы подключиться.';
  }
  return _brandTextForName(
    'POKROV готовит подключение в фоне, чтобы на первом экране осталась одна понятная кнопка.',
    brandName,
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.lines,
    this.child,
    this.tone = _SectionTone.neutral,
  });

  final String title;
  final List<String> lines;
  final Widget? child;
  final _SectionTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _SectionTone.accent => (
          background: _SeedPalette.accent.withValues(alpha: 0.06),
          border: _SeedPalette.accent.withValues(alpha: 0.14),
        ),
      _SectionTone.muted => (
          background: _SeedPalette.surfaceMuted,
          border: _SeedPalette.line,
        ),
      _SectionTone.neutral => (
          background: _SeedPalette.surface,
          border: _SeedPalette.line,
        ),
      _SectionTone.reward => (
          background: const Color(0xFFFFF8E1),
          border: Color(0x33B99745),
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _SeedPalette.ink.withValues(alpha: 0.76),
                          height: 1.32,
                        ),
                  ),
                ),
              ),
            ],
            if (child != null) ...[
              SizedBox(height: lines.isEmpty ? 12 : 14),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SeedBackdrop extends StatelessWidget {
  const _SeedBackdrop({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_SeedPalette.canvas, _SeedPalette.canvasAlt],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    this.tone = _SectionTone.neutral,
  });

  final String label;
  final IconData icon;
  final _SectionTone tone;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      _SectionTone.accent => _SeedPalette.accent.withValues(alpha: 0.12),
      _SectionTone.muted => _SeedPalette.surfaceMuted.withValues(alpha: 0.92),
      _SectionTone.neutral => Colors.white.withValues(alpha: 0.86),
      _SectionTone.reward => const Color(0xFFFFF3CF),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _SeedPalette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _SeedPalette.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _SeedPalette.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ConnectOrbButton extends StatefulWidget {
  const _ConnectOrbButton({
    required this.actionLabel,
    required this.enabled,
    required this.running,
    required this.degraded,
    required this.error,
    required this.busy,
    required this.onPressed,
  });

  final String actionLabel;
  final bool enabled;
  final bool running;
  final bool degraded;
  final bool error;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<_ConnectOrbButton> createState() => _ConnectOrbButtonState();
}

class _ConnectOrbButtonState extends State<_ConnectOrbButton>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _sweepController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: PokrovConnectDiscMotion.breathDuration,
    );
    _sweepController = AnimationController(
      vsync: this,
      duration: PokrovConnectDiscMotion.sweepDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _ConnectOrbButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.running != widget.running ||
        oldWidget.degraded != widget.degraded ||
        oldWidget.error != widget.error ||
        oldWidget.busy != widget.busy) {
      _breathController.reset();
      _sweepController.reset();
    }
    _syncControllers();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  PokrovConnectDiscState get _discState => PokrovConnectDiscState.resolve(
        enabled: widget.enabled,
        running: widget.running,
        degraded: widget.degraded,
        error: widget.error,
        busy: widget.busy,
      );

  void _syncControllers() {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    final state = _discState;
    final canAnimate = state.enabled && !disableAnimations;

    if (canAnimate && !state.runsSweep) {
      if (!_breathController.isAnimating &&
          _breathController.status != AnimationStatus.completed) {
        _breathController.forward();
      }
    } else {
      _breathController.stop();
      _breathController.value = 0;
    }

    if (canAnimate && state.runsSweep) {
      if (!_sweepController.isAnimating &&
          _sweepController.status != AnimationStatus.completed) {
        _sweepController.forward(from: 0);
      }
    } else {
      _sweepController.stop();
      _sweepController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = _MotionScope.of(context);
    final state = _discState;
    final accent = (widget.degraded || widget.error)
        ? const Color(0xFFB5673A)
        : widget.running
            ? _SeedPalette.accentBright
            : _SeedPalette.accent;
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    final diameter = switch (MediaQuery.sizeOf(context).width) {
      >= 720 => 210.0,
      _ => 182.0,
    };
    final labelColor = widget.enabled ? _SeedPalette.ink : _SeedPalette.muted;
    final markOpacity = !widget.enabled
        ? 0.34
        : (widget.degraded || widget.error)
            ? 0.62
            : widget.busy
                ? 0.72
                : 1.0;

    return Semantics(
      key: const ValueKey('primary-connect-action'),
      button: true,
      enabled: widget.enabled,
      label: widget.actionLabel,
      child: MouseRegion(
        cursor: widget.onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed == null
              ? null
              : () {
                  Feedback.forTap(context);
                  widget.onPressed?.call();
                },
          onTapDown: widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = false),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  key: const ValueKey('connect-disc-motion'),
                  animation:
                      Listenable.merge([_breathController, _sweepController]),
                  builder: (context, child) {
                    final breath = disableAnimations
                        ? 0.0
                        : Curves.easeInOut.transform(_breathController.value);
                    return Transform.scale(
                      scale: PokrovConnectDiscMotion.scale(
                        pressed: _pressed,
                        runsSweep: state.runsSweep,
                        breathValue: breath,
                        disableAnimations: disableAnimations,
                      ),
                      child: child,
                    );
                  },
                  child: AnimatedContainer(
                    duration: motion.duration(_MotionTokens.standard),
                    curve: _MotionTokens.ease,
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.running
                          ? _SeedPalette.accent.withValues(alpha: 0.11)
                          : _SeedPalette.surface,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.running ? accent : _SeedPalette.ink)
                              .withValues(alpha: widget.running ? 0.14 : 0.07),
                          blurRadius: widget.running ? 26 : 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: Listenable.merge(
                              [_breathController, _sweepController]),
                          builder: (context, _) {
                            return CustomPaint(
                              size: Size.square(diameter),
                              painter: _ConnectDiscRimPainter(
                                accent: accent,
                                enabled: widget.enabled,
                                running: widget.running,
                                degraded: widget.degraded || widget.error,
                                busy: state.runsSweep,
                                disableAnimations: disableAnimations,
                                breathValue: _breathController.value,
                                sweepValue: _sweepController.value,
                              ),
                            );
                          },
                        ),
                        _ConnectSettleLayer(
                          diameter: diameter,
                          accent: accent,
                          enabled: widget.enabled,
                          running: widget.running,
                          degraded: widget.degraded,
                          error: widget.error,
                          busy: widget.busy,
                          disableAnimations: disableAnimations,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: _SeedPalette.surface.withValues(alpha: 0.74),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(
                                  alpha: widget.running ? 0.18 : 0.10),
                            ),
                          ),
                          child: SizedBox.square(
                            dimension: diameter * 0.58,
                            child: Center(
                              child: _BrandMark(
                                size: diameter * 0.42,
                                opacity: markOpacity,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                key: const ValueKey('connect-disc-label'),
                duration: motion.duration(_MotionTokens.short),
                transitionBuilder: _fadeSlideTransition,
                child: Text(
                  widget.actionLabel,
                  key: ValueKey(widget.actionLabel),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectSettleLayer extends StatelessWidget {
  const _ConnectSettleLayer({
    required this.diameter,
    required this.accent,
    required this.enabled,
    required this.running,
    required this.degraded,
    required this.error,
    required this.busy,
    required this.disableAnimations,
  });

  final double diameter;
  final Color accent;
  final bool enabled;
  final bool running;
  final bool degraded;
  final bool error;
  final bool busy;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    final motion = _MotionScope.of(context);
    final state = PokrovConnectDiscState.resolve(
      enabled: enabled,
      running: running,
      degraded: degraded,
      error: error,
      busy: busy,
    );
    final isError = state.isError;
    final isActive = state.isActive;
    final settleColor = isError ? _SeedPalette.warning : accent;
    final inset = state.settleInset;
    final opacity = state.settleOpacity;

    return IgnorePointer(
      key: const ValueKey('connect-disc-settle-layer'),
      child: AnimatedSwitcher(
        duration: motion.duration(_MotionTokens.standard),
        switchInCurve: _MotionTokens.ease,
        switchOutCurve: _MotionTokens.ease,
        transitionBuilder: (child, animation) {
          if (disableAnimations) {
            return FadeTransition(opacity: animation, child: child);
          }
          final curved = CurvedAnimation(
            parent: animation,
            curve: _MotionTokens.ease,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: PokrovConnectDiscMotion.settleScaleBegin,
                end: 1,
              ).animate(curved),
              child: child,
            ),
          );
        },
        child: SizedBox.square(
          key: state.settleKey,
          dimension: diameter,
          child: AnimatedOpacity(
            duration: motion.duration(_MotionTokens.short),
            opacity: isActive ? 1 : 0,
            curve: _MotionTokens.ease,
            child: Padding(
              padding: EdgeInsets.all(inset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: settleColor.withValues(alpha: opacity),
                  border: Border.all(
                    color: settleColor.withValues(
                      alpha: isError ? 0.28 : 0.18,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: settleColor.withValues(alpha: opacity * 0.7),
                      blurRadius: isError ? 18 : 24,
                      spreadRadius: isError ? 1 : 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectDiscRimPainter extends CustomPainter {
  const _ConnectDiscRimPainter({
    required this.accent,
    required this.enabled,
    required this.running,
    required this.degraded,
    required this.busy,
    required this.disableAnimations,
    required this.breathValue,
    required this.sweepValue,
  });

  final Color accent;
  final bool enabled;
  final bool running;
  final bool degraded;
  final bool busy;
  final bool disableAnimations;
  final double breathValue;
  final double sweepValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final breath =
        disableAnimations ? 0.0 : Curves.easeInOut.transform(breathValue);
    final baseOpacity = enabled
        ? running
            ? 0.36
            : 0.16 + breath * 0.08
        : 0.08;
    final basePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = running ? 3.2 : 2.2
      ..color = accent.withValues(alpha: baseOpacity);

    canvas.drawCircle(center, radius, basePaint);

    if (busy && enabled) {
      final sweepPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..color = accent.withValues(alpha: disableAnimations ? 0.42 : 0.74);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final startAngle = PokrovConnectDiscMotion.sweepStartAngle(
        disableAnimations: disableAnimations,
        sweepValue: sweepValue,
      );
      canvas.drawArc(
        rect,
        startAngle,
        PokrovConnectDiscMotion.busySweepArcRadians,
        false,
        sweepPaint,
      );
    } else if (degraded && enabled) {
      final warningPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _SeedPalette.warning.withValues(alpha: 0.72);
      canvas.drawCircle(center, radius - 1.5, warningPaint);
    } else if (running && enabled) {
      final activePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..color = accent.withValues(alpha: 0.56);
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        PokrovConnectDiscMotion.connectedArcStartAngle,
        PokrovConnectDiscMotion.connectedArcSweepRadians,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectDiscRimPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.enabled != enabled ||
        oldDelegate.running != running ||
        oldDelegate.degraded != degraded ||
        oldDelegate.busy != busy ||
        oldDelegate.disableAnimations != disableAnimations ||
        oldDelegate.breathValue != breathValue ||
        oldDelegate.sweepValue != sweepValue;
  }
}
