# POKROV Client

<p align="center">
  <img src="assets/brand/pokrov-oss-hero.png" alt="POKROV Client open-source hero artwork" width="100%">
</p>

<p align="center">
  <a href="README.md">Выбор языка</a>
  &middot;
  <a href="README.en.md">English</a>
  &middot;
  <a href="docs/OPEN_SOURCE_SCOPE.md">Scope</a>
  &middot;
  <a href="docs/ENTERPRISE.md">Enterprise</a>
  &middot;
  <a href="SECURITY.md">Security</a>
  &middot;
  <a href="BRAND.md">Brand</a>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: GPLv3" src="https://img.shields.io/badge/license-GPLv3-0f766e?style=for-the-badge"></a>
  <a href="https://github.com/Kiwunaka/Pokrov-client/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/Kiwunaka/Pokrov-client/ci.yml?branch=main&style=for-the-badge&label=CI"></a>
  <a href="https://github.com/Kiwunaka/Pokrov-client/releases/tag/v0.172.0-source"><img alt="Source release" src="https://img.shields.io/badge/source-v0.172.0--source-111827?style=for-the-badge"></a>
  <img alt="Platforms: Android and Windows" src="https://img.shields.io/badge/platforms-Android%20%2B%20Windows-2563eb?style=for-the-badge">
</p>

<p align="center">
  <strong>Открытый клиент. Приватная операционная часть. База для своих сборок.</strong>
  <br>
  Сначала Android и Windows. GPLv3. Source-only релиз.
</p>

---

<p align="center">
  <img src="assets/brand/open-source-showroom.png" alt="POKROV Client open-source направления: обычный клиент, operator-ready source и честная source-only граница" width="100%">
</p>

## Что Это

POKROV Client - публичный source-only репозиторий Android/Windows клиента.
Внутри лежит очищенный исходный snapshot, tooling для proof/release, правила
контрибьюта, security routing, локальный импорт для обычных пользователей и
operator path для команд, которые хотят собрать клиент под свой сервис.

Этот репозиторий не публикует официальные APK/EXE, store builds, trusted
Windows signing, приватный POKROV backend, billing, admin, signing material или
private release evidence.

Contract markers:

- no POKROV API calls by default
- does not provide POKROV nodes or a default free service
- forks and operator builds are not official POKROV builds
- Enterprise boundary and commercial license notes live in
  [Enterprise](docs/ENTERPRISE.md); no commercial license is offered by default.

## Flow Preview

<p align="center">
  <img src="assets/brand/client-flow-loop.gif" alt="Local-first import flow: ключи, локальный parser, routing и operator build boundary" width="100%">
</p>

Это визуальная карта публичного направления: локальный импорт, локальный
парсер, routing controls и граница operator-owned build. Она не обещает
официальный APK, EXE, store build, trusted signing или live POKROV service.

## Два Главных Направления

### Personal Key Client

Для людей, у которых уже есть ключ, QR-код или subscription URL.

- Нейтральный open-source режим без official POKROV branding.
- По умолчанию без POKROV API calls.
- Локальный импорт `vless://`, `trojan://`, `ss://`, `vmess://`.
- Android и Windows QR import.
- Импорт и refresh subscription URL.
- Routing controls и WARP consent boundaries там, где они реализованы.
- Optional third-party public config catalog, gated и disabled by default.

### Operator / Company Client

Для компаний, команд и сообществ, которым нужен клиент под свой VPN-сервис.

Operator отвечает за:

- backend API и managed-profile delivery
- brand, icons, app name, package identifiers и metadata
- support, privacy policy, abuse handling и billing
- signing, checksums, release notes и distribution
- GPLv3 compliance своей сборки

Начинать лучше с [Operator integration](docs/OPERATOR_INTEGRATION.md),
[Product variants](docs/PRODUCT_VARIANTS.md) и
[White-label branding](docs/WHITE_LABEL_BRANDING.md).

### Official POKROV Service Mode

Официальные POKROV builds отделены от forks и operator builds.
Форки не должны использовать official POKROV branding, endpoints, support
channels или release claims, если это отдельно не разрешено owner-approved
policy.

## Текущий Релиз

| Поле | Значение |
| --- | --- |
| Source release | [`v0.172.0-source`](https://github.com/Kiwunaka/Pokrov-client/releases/tag/v0.172.0-source) |
| Commit | `e1fef5520190dc6fb0efbe8c1bfd666fac07d2db` |
| Source archive SHA-256 | `84c53d20e5f53253fdaeb5cae1d310327e331c0a462683eb9eee7903d6846367` |
| Platforms | Android и Windows |
| License | GNU GPLv3 |
| Binary assets | Нет |
| Store release | Нет |
| Trusted signing claim | Нет |

## Build From Source

```powershell
git clone https://github.com/Kiwunaka/Pokrov-client.git
cd Pokrov-client
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
```

Для platform setup, runtime-artifact boundaries и clean-clone checks см.
[Build from source](docs/BUILD_FROM_SOURCE.md).

## Карта Репозитория

| Path | Назначение |
| --- | --- |
| `apps/android_shell/` | Android host shell и native Android contracts. |
| `apps/windows_shell/` | Windows host shell, runner metadata и Windows QR host. |
| `packages/app_shell/` | Общий Flutter app shell и продуктовые flows. |
| `packages/core_domain/` | Domain models и public contracts. |
| `packages/runtime_engine/` | Runtime staging и connect/disconnect boundary. |
| `packages/platform_contracts/` | Platform-facing contracts. |
| `docs/` | Build, release, operator, security и governance docs. |
| `scripts/` | Source import, release proof, preflight и verification tooling. |

## Free VPN Catalog Boundary

Optional Free VPN catalog - это reviewed third-party public config feed path.
Он opt-in, disabled by default и не является official POKROV node pool.
Клиент не должен обещать speed, safety, privacy, uptime, legality или
availability для third-party public configs.

См. [Free VPN catalog gate](docs/FREE_VPN_CATALOG_GATE.md).

## Контрибьют

Перед PR прочитай [CONTRIBUTING.md](CONTRIBUTING.md).

Хорошие задачи на этом этапе:

- улучшения build-from-source
- parser fixtures и tests для local import
- Android/Windows source-build fixes
- operator integration docs
- source-release и trust-boundary hardening

Не публикуй в issues secrets, QR payloads, subscription URLs, signing material,
private POKROV endpoints или vulnerability details.

## Security

Используй [SECURITY.md](SECURITY.md). Public issues не подходят для
vulnerabilities, private keys, exploit details или live subscription URLs.

## License

POKROV Client распространяется по GNU General Public License v3.0. См.
[LICENSE](LICENSE).

POKROV name, logo, official endpoints, release claims и service operation
остаются в рамках brand и official-build boundary из [BRAND.md](BRAND.md).
