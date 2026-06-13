# POKROV Client

<p align="center">
  <img src="assets/brand/pokrov-oss-hero.png" alt="POKROV Client open-source hero artwork" width="100%">
</p>

<p align="center">
  <a href="LICENSE"><img alt="Лицензия: GPLv3" src="https://img.shields.io/badge/license-GPLv3-0f766e?style=for-the-badge"></a>
  <a href="https://github.com/Kiwunaka/Pokrov-client/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/Kiwunaka/Pokrov-client/ci.yml?branch=main&style=for-the-badge&label=CI"></a>
  <img alt="Статус исходников: snapshot imported" src="https://img.shields.io/badge/source-snapshot%20imported-0f766e?style=for-the-badge">
  <img alt="Платформы: Android и Windows" src="https://img.shields.io/badge/platforms-Android%20%2B%20Windows-2563eb?style=for-the-badge">
  <img alt="Режимы клиента: community и operator" src="https://img.shields.io/badge/modes-community%20%2B%20operator-111827?style=for-the-badge">
</p>

<p align="center">
  <strong>Открытый клиент для спокойного app-first подключения.</strong>
  <br>
  Сначала Android и Windows. GPLv3. Санитизированный snapshot исходников уже импортирован.
</p>

<p align="center">
  <a href="README.md">Выбор языка</a>
  &middot;
  <a href="README.en.md">English</a>
  &middot;
  <a href="docs/OPEN_SOURCE_SCOPE.md">Scope</a>
  &middot;
  <a href="SECURITY.md">Security</a>
  &middot;
  <a href="BRAND.md">Brand</a>
</p>

---

## Что Это

POKROV Client - публичный репозиторий исходного кода клиента POKROV для
Android и Windows.

В репозитории лежит публичная структура проекта, правила контрибьюта, security
policy, release policy, граница бренда, чеклист импорта исходников и первый
санитизированный snapshot Android + Windows клиента.

## Режимы Продукта

- Personal Key Client / Community client: нейтральный клиент без брендинга POKROV и без обращений к
  POKROV API по умолчанию. Уже есть MVP локального импорта одиночных ключей
  `vless://`, `trojan://`, `ss://` и `vmess://`, локальный список профилей,
  импорт и refresh URL-подписки, Android/Windows QR import и gated metadata для
  third-party catalog.
- Operator / Company Client: white-label путь для компаний, которые хотят подключить
  приложение к своему backend, billing, support и бренду.
- POKROV Service Mode: описан только для официальных сборок POKROV. Forks и
  operators не должны распространять сборки с именем, логотипом, endpoints,
  support или release claims POKROV.

Опциональный каталог third-party public configs остается выключенным по
умолчанию и должен явно маркироваться как неофициальные узлы POKROV. Это не
default free service от POKROV и не обещание availability, safety, privacy,
speed или uptime.

## Первые Шаги

| Track | Когда выбирать | С чего начать |
| --- | --- | --- |
| Personal Key Client | У тебя уже есть ключ, QR-код или subscription URL, и нужен локальный клиент. | Собери `community` variant, затем вставь `vless://`, `trojan://`, `ss://` или `vmess://` key, scan a QR code, or add a subscription URL. |
| Operator / Company Client | У тебя компания, команда или свой сервис, и нужен клиент в своём дизайне. | Run the local fixture backend, export white-label color tokens, implement the minimal managed-profile contract, затем подключи свой API, support, billing, signing и release channels. |
| POKROV Service Mode | Только для официальных сборок POKROV. | Используй официальные release channels POKROV. Forks и operator builds are not official POKROV builds. |

Personal Key Client делает no POKROV API calls by default. Этот репозиторий
does not provide POKROV nodes or a default free service.

## Какую Версию Использовать?

- Пользователи официального POKROV используют официальные release channels и
  support links POKROV.
- Community source users приносят свои локальные ключи или URL-подписки. Этот
  репозиторий не предоставляет узлы POKROV или бесплатный сервис по умолчанию.
- Operator builds поддерживает тот оператор, который собрал и распространил
  приложение, а не официальный support POKROV.

## Статус

<p align="center">
  <img src="assets/brand/oss-status-card.png" alt="POKROV Client repository status artwork" width="100%">
</p>

| Область | Текущее состояние |
| --- | --- |
| Репозиторий | Публичная база готова |
| Исходники | Санитизированный Android + Windows snapshot импортирован |
| Community mode | Локальные профили, импорт/refresh подписок, Android/Windows QR import |
| Operator mode | Fixture API, OpenAPI contract и white-label token export задокументированы |
| Platforms | Сначала Android и Windows |
| License | GNU GPLv3 |
| Official backend | Работает отдельно под управлением POKROV |
| Public releases | Только beta-safe и evidence-based формулировки |

## Статус Source Release

| Milestone | Статус | Объем |
| --- | --- | --- |
| `v0.1.0-source` | Tag создан | Первый source-only snapshot Android/Windows с локальным community import. Без APK/EXE. |
| `v0.2.0-source` | Tag еще не создан | Community import hub polish, variant-boundary enforcement и source-import hardening уже на `main`; release tag pending. |
| `v0.3.0-source` | Tag еще не создан | Operator fixture, Free VPN catalog gate, white-label token export и foreground subscription scheduler уже на `main`; release tag pending. |
| `v0.4.0-source` | Pending stacked PR, tag еще не создан | Native Android/Windows host brand-boundary hardening находится в stacked PR queue. |
| `v0.5.0-source` | Pending stacked PR, tag еще не создан | Community routing и WARP copy honesty hardening находится в stacked PR queue. |
| `v0.6.0-source` | Pending stacked PR, tag еще не создан | Dependency/license и generated-asset provenance gates находятся в stacked PR queue. |
| `v0.7.0-source` | Pending stacked PR, tag еще не создан | Source-release proof helper для archive SHA-256 и proof manifest находится в stacked PR queue. |
| `v0.8.0-source` | Pending stacked PR, tag еще не создан | Source readiness matrix for tracked source-only milestones находится в stacked PR queue. |
| `v0.9.0-source` | Pending stacked PR, tag еще не создан | Public onboarding and triage hardening находится в stacked PR queue. |
| `v0.10.0-source` | Pending stacked PR, tag еще не создан | Operator API contract hardening находится в stacked PR queue. |
| `v0.11.0-source` | Pending stacked PR, tag еще не создан | Gated Free VPN catalog cache actions находятся в stacked PR queue. |
| `v0.12.0-source` | Pending stacked PR, tag еще не создан | Source-readiness synchronization through the catalog cache slice находится в stacked PR queue. |
| `v0.13.0-source` | Pending stacked PR, tag еще не создан | Default-disabled `OPEN_CLIENT_ENABLE_FREE_CATALOG` import gate находится в stacked PR queue. |
| `v0.14.0-source` | Pending stacked PR, tag еще не создан | Source-readiness synchronization through the feature-flag slice находится в stacked PR queue. |
| `v0.15.0-source` | Pending stacked PR, tag еще не создан | Operator support ticket path canonicalization находится в stacked PR queue. |
| `v0.16.0-source` | Pending stacked PR, tag еще не создан | Community local-access wording and model guards находятся в stacked PR queue. |
| `v0.17.0-source` | Pending stacked PR, tag еще не создан | Seed-backed variant command preview tooling находится в stacked PR queue. |
| `v0.18.0-source` | Pending stacked PR, tag еще не создан | Proof-backed source release notes rendering находится в stacked PR queue. |
| `v0.19.0-source` | Pending stacked PR, tag еще не создан | Annotated source tag enforcement находится в stacked PR queue. |
| `v0.20.0-source` | Pending stacked PR, tag еще не создан | End-to-end proof-to-release-notes smoke находится в stacked PR queue. |
| `v0.21.0-source` | Pending stacked PR, tag еще не создан | Self-documenting release-note verification находится в stacked PR queue. |
| `v0.22.0-source` | Pending stacked PR, tag еще не создан | One-command source-release preflight находится в stacked PR queue. |

## Архитектурная Граница

<p align="center">
  <img src="assets/diagrams/open-source-boundary.png" alt="Open-source client and private service boundary artwork" width="100%">
</p>

Этот репозиторий только про клиентское приложение. Здесь нет официального
backend POKROV, billing system, admin tools, deployment scripts, signing
material, private release evidence или operator runbooks.

Полная граница описана в [docs/OPEN_SOURCE_SCOPE.md](docs/OPEN_SOURCE_SCOPE.md).

## Карта Репозитория

```text
.
|-- README.md                  Language gateway
|-- README.en.md               English project README
|-- README.ru.md               Русская версия README
|-- apps/                      Android and Windows Flutter hosts
|-- packages/                  Shared Flutter packages
|-- config/                    Public seed config and runtime contracts
|-- scripts/                   Local bootstrap, runtime-fetch, and test scripts
|-- BRAND.md                   Brand and official-build boundary
|-- SECURITY.md                Private security-reporting process
|-- CONTRIBUTING.md            Contribution rules
|-- ROADMAP.md                 Public repository roadmap
|-- docs/
|   |-- OPEN_SOURCE_SCOPE.md
|   |-- RELEASE_POLICY.md
|   |-- DEPENDENCY_LICENSE_AUDIT.md
|   |-- MAINTAINER_CHECKLIST.md
|   |-- PROJECT_PRINCIPLES.md
|   |-- SOURCE_IMPORT_PLAYBOOK.md
|   |-- PRODUCT_VARIANTS.md
|   |-- OPERATOR_INTEGRATION.md
|   `-- GOVERNANCE.md
`-- assets/
    |-- brand/
    `-- diagrams/
```

## Сборка Из Исходников

Инструкция по сборке лежит в
[docs/BUILD_FROM_SOURCE.md](docs/BUILD_FROM_SOURCE.md).

Инструменты source import для maintainers:

```powershell
python -m pytest tests/test_source_import.py
python -m tools.source_import.safe_import --source <snapshot> --staging <stage> --manifest <manifest.json>
```

Clean-clone проверка:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1
```

Планка приемки для исходников простая:

- clean clone должен собираться без приватных файлов;
- secrets, certificates и signing identities не должны требоваться;
- config examples должны использовать placeholders;
- official release metadata не должна указывать на private repositories.

## Контрибьют

Контрибьюты приветствуются, особенно вокруг документации, release hygiene,
build reproducibility, local profile import, operator integration и public
source readiness.

Перед контрибьютом прочитай:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md)
- [BRAND.md](BRAND.md)
- [docs/MAINTAINER_CHECKLIST.md](docs/MAINTAINER_CHECKLIST.md)
- [docs/PROJECT_PRINCIPLES.md](docs/PROJECT_PRINCIPLES.md)
- [docs/SOURCE_IMPORT_PLAYBOOK.md](docs/SOURCE_IMPORT_PLAYBOOK.md)
- [docs/PRODUCT_VARIANTS.md](docs/PRODUCT_VARIANTS.md)
- [docs/OPERATOR_INTEGRATION.md](docs/OPERATOR_INTEGRATION.md)
- [docs/FREE_VPN_CATALOG_GATE.md](docs/FREE_VPN_CATALOG_GATE.md)
- [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)
- [docs/GOVERNANCE.md](docs/GOVERNANCE.md)

Не открывай публичные issues с secrets, QR payloads, subscription URLs, личными
connection links, private backend details, account data или vulnerability
reproduction details.

## Ссылки Официального Сервиса POKROV

Эти ссылки относятся только к официальному сервису/приложению POKROV. Это не
support и не backend endpoints для community builds, forks или operator builds.

- Website: https://pokrov.space/
- Cabinet: https://app.pokrov.space/
- Public channel: https://t.me/pokrov_vpn
- Support bot: https://t.me/pokrov_supportbot

Официальные бинарники публикуются только через release channels POKROV. Forks и
пересобранные клиенты не должны выдавать себя за официальные сборки POKROV.

## Лицензия

Репозиторий распространяется по GNU General Public License v3.0. См.
[LICENSE](LICENSE).

Название POKROV, логотипы, домены, официальные каналы, signing identities и
release distribution channels регулируются отдельно в [BRAND.md](BRAND.md).
