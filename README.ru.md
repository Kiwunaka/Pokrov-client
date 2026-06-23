# POKROV Client

Source readiness note: `v0.90.0-source` is a pending stacked PR for artifact
fingerprint integrity checks across release evidence, publication dry-run, and
release merge handoff; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.91.0-source` is a pending stacked PR for commit SHA
consistency checks across release evidence, publication dry-run, and release
merge handoff; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.92.0-source` is a pending stacked PR for resolved ref
commit SHA consistency checks across source preflight, release evidence,
publication dry-run, and release merge handoff; it is not tagged and does not
ship APK/EXE binaries.

Source readiness note: `v0.93.0-source` is a pending stacked PR for carrying
the latest stacked PR URL from release stack status into release merge handoff;
it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.94.0-source` is a pending stacked PR for verifying
latest stacked PR URLs stay inside the expected public repository boundary; it
is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.95.0-source` is a pending stacked PR for verifying
that release merge handoff consumes GitHub status summaries with the same
expected PR URL prefix as the configured public repository boundary; it is not
tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.96.0-source` is a pending stacked PR for verifying
that release merge handoff validates GitHub status summary counts against the
merge stack and required status checks; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.97.0-source` is a pending stacked PR for verifying
that release merge handoff validates GitHub status pull request entries before
maintainer review; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.98.0-source` is a pending stacked PR for verifying
that release merge handoff validates GitHub status PR sequence against the
merge-order stack before maintainer review; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.99.0-source` is a pending stacked PR for verifying
that release merge handoff validates GitHub status PR base/head refs against
the merge-order stack before maintainer review; it is not tagged and does not
ship APK/EXE binaries.

Source readiness note: `v0.100.0-source` is a pending stacked PR for verifying
that release merge handoff validates every GitHub status PR URL against the
expected public repository and PR number before maintainer review; it is not
tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.101.0-source` is a pending stacked PR for verifying
that release merge handoff validates every GitHub status PR is clean and not
draft before maintainer review; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.102.0-source` is a pending stacked PR for verifying
that release merge handoff validates per-PR required GitHub status checks before
maintainer review; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.103.0-source` is a pending stacked PR for verifying
that release merge handoff validates per-check GitHub Actions trace evidence
before maintainer review; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.104.0-source` is a pending stacked PR for verifying
that publication dry-run validates the evidence bundle preflight input
fingerprint before maintainer review; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.105.0-source` is a pending stacked PR for verifying
that release merge handoff validates publication dry-run preflight input
fingerprints before maintainer review; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.106.0-source` is a pending stacked PR for verifying
that release merge handoff validates publication dry-run evidence-bundle and
release-notes input fingerprints before maintainer review; it is not tagged
and does not ship APK/EXE binaries.

Source readiness note: `v0.107.0-source` is a pending stacked PR for verifying
that release merge handoff validates tag readiness blocker-inventory and
source-readiness input fingerprints before maintainer review; it is not tagged
and does not ship APK/EXE binaries.

Source readiness note: `v0.108.0-source` is a pending stacked PR for verifying
that release merge handoff validates publication dry-run artifact fingerprints
against the real proof files before maintainer review; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.109.0-source` is a pending stacked PR for verifying
that optional GitHub ruleset report input fingerprints are carried through
release evidence, publication dry-run, and release merge handoff before
maintainer review; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.110.0-source` is a pending stacked PR for verifying
that malformed GitHub ruleset reports are rejected before enforcement claims
can reach publication dry-run or release merge handoff; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.111.0-source` is a pending stacked PR for verifying
that publication dry-run rejects malformed GitHub ruleset reports before manual
release review or release merge handoff; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.112.0-source` is a pending stacked PR for verifying
that release merge handoff rejects malformed GitHub ruleset reports before
maintainer handoff can be marked ready; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.113.0-source` is a pending stacked PR for verifying
that release evidence, publication dry-run, and release merge handoff reject
GitHub ruleset reports for the wrong repository or branch; it is not tagged
and does not ship APK/EXE binaries.

Source readiness note: `v0.114.0-source` is a pending stacked PR for verifying
that release evidence, publication dry-run, and release merge handoff reject
GitHub ruleset reports that claim `ok` while verifier checks are missing or
failed; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.115.0-source` is a pending stacked PR for verifying
that release evidence, publication dry-run, and release merge handoff reject
GitHub ruleset report checks without traceable name or status fields; it is not
tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.116.0-source` is a pending stacked PR for verifying
that release evidence, publication dry-run, and release merge handoff reject
GitHub ruleset reports whose required status checks do not match the canonical
CI list; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.117.0-source` is a pending stacked PR for verifying
that release evidence, publication dry-run, and release merge handoff reject
GitHub ruleset reports whose passing verifier checks do not cover every
canonical required CI job; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.118.0-source` is a pending stacked PR for verifying
that GitHub ruleset reports carry explicit `covered_required_status_checks` and
that release evidence, publication dry-run, and release merge handoff reject
`ok` reports whose covered checks do not match the canonical CI list; it is not
tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.119.0-source` is a pending stacked PR for verifying
that release evidence, publication dry-run, and release merge handoff reject
GitHub ruleset reports without a fresh `checked_at` timestamp; it is not tagged
and does not ship APK/EXE binaries.

Source readiness note: `v0.120.0-source` is a pending stacked PR for verifying
that release merge handoff rejects stale generated input summaries before
maintainer review; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.121.0-source` is a pending stacked PR for verifying
that release evidence and publication dry-run reject stale generated input
artifacts before handoff; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.122.0-source` is a pending stacked PR for verifying
that source tag readiness rejects contradictory blocker inventories that allow
tag creation while required blockers remain open or inventory status is not
ready; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.123.0-source` is a pending stacked PR for verifying
that source tag readiness rejects blocker inventories that claim ready status
while required release blockers remain open; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.124.0-source` is a pending stacked PR for verifying
that source tag readiness rejects tag allowance while the selected
source-readiness milestone is still pending or not tagged; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.125.0-source` is a pending stacked PR for verifying
that source tag readiness requires an explicit ready milestone status before
tag creation can be allowed; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.126.0-source` is a pending stacked PR for verifying
that source tag readiness requires milestone evidence to match the canonical
public repository PR URL; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.127.0-source` is a pending stacked PR for verifying
that seed validation requires the source tag-readiness evidence policy and
canonical PR URL guard phrases; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.128.0-source` is a pending stacked PR for verifying
that seed validation requires the latest source-readiness milestone evidence to
match the blocker inventory latest candidate and PR; it is not tagged and does
not ship APK/EXE binaries.

Source readiness note: `v0.129.0-source` is a pending stacked PR for verifying
that seed validation requires the latest release merge-order PR and candidate
to match the blocker inventory latest candidate and PR; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.130.0-source` is a pending stacked PR for verifying
that seed validation requires the release blocker inventory covered range to
match its base and latest candidates; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.131.0-source` is a pending stacked PR for verifying
that seed validation requires unique source-readiness milestone tags; it is not
tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.132.0-source` is a pending stacked PR for verifying
that seed validation requires stacked PR milestone evidence to use canonical
repository PR URLs; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.133.0-source` is a pending stacked PR for verifying
that seed validation requires unique stacked PR milestone evidence URLs; it is
not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.134.0-source` is a pending stacked PR for verifying
that seed validation requires stacked PR milestone evidence PR numbers to
increase with the candidate sequence; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.135.0-source` is a pending stacked PR for verifying
that seed validation requires source-readiness stacked PR evidence to match the
release merge-order stack; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.136.0-source` is a pending stacked PR for verifying
that seed validation requires release stack GitHub status required checks to
match the canonical required-checks seed exactly; it is not tagged and does not
ship APK/EXE binaries.

Source readiness note: `v0.137.0-source` is a pending stacked PR for verifying
that seed validation requires active-range source-readiness stacked PR
milestones to be covered by the release merge-order stack; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.138.0-source` is a pending stacked PR for verifying
that the source publication packet consolidates release handoff, publication
dry-run, source proof artifacts, and source-only flags for manual GitHub
Release review; it is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.139.0-source` is a pending stacked PR for verifying
that the source publication packet validates release handoff and publication
dry-run generated_at timestamps before manual GitHub Release review; it is not
tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.140.0-source` is a pending stacked PR for verifying
that the source publication packet validates handoff-carried publication dry-run
fingerprints against the direct dry-run summary before manual release review; it
is not tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.141.0-source` is a pending stacked PR for verifying
that the source publication packet recalculates release artifact file
fingerprints before manual GitHub Release review; it is not tagged and does not
ship APK/EXE binaries.

Source readiness note: `v0.142.0-source` is a pending stacked PR for verifying
that the source publication packet rejects release artifact paths outside the
expected build output roots before manual GitHub Release review; it is not
tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.143.0-source` is a pending stacked PR for verifying
that the source publication packet rejects unexpected non-source release asset
fingerprints before manual GitHub Release review; it is not tagged and does not
ship APK/EXE binaries.

Source readiness note: `v0.144.0-source` is a pending stacked PR for verifying
that the source publication packet rejects release artifact files whose
extensions do not match the source-only artifact contract; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.145.0-source` is a pending stacked PR for verifying
that the source publication packet validates source release artifact contents
before manual GitHub Release review; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.146.0-source` is a pending stacked PR for verifying
that the source publication packet validates source release artifact JSON
schemas before manual GitHub Release review; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.147.0-source` is a pending stacked PR for verifying
that the source publication packet validates release notes claim and
known-limitation markers before manual GitHub Release review; it is not tagged
and does not ship APK/EXE binaries.

Source readiness note: `v0.148.0-source` is a pending stacked PR for verifying
that the source publication packet validates release notes tag and source
archive SHA proof before manual GitHub Release review; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.149.0-source` is a pending stacked PR for verifying
that the source publication packet validates proof manifest source archive SHA
binding before manual GitHub Release review; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.150.0-source` is a pending stacked PR for verifying
that the source publication packet validates proof manifest source archive
filename binding before manual GitHub Release review; it is not tagged and does
not ship APK/EXE binaries.

Source readiness note: `v0.53.0-source` is a pending stacked PR for Windows
verifier CI/preflight enforcement; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.54.0-source` is a pending stacked PR for the release
evidence bundle Windows proof gate; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.55.0-source` is a pending stacked PR for the
publication dry-run Windows proof gate; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.56.0-source` is a pending stacked PR for the release
merge handoff publication proof gate; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.57.0-source` is a pending stacked PR for release
merge handoff input fingerprints; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.58.0-source` is a pending stacked PR for release
merge handoff source-only flags; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.59.0-source` is a pending stacked PR for release
merge handoff canonical input roots; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.60.0-source` is a pending stacked PR for release
merge handoff input timestamps; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.61.0-source` is a pending stacked PR for release
merge handoff input schema/read-only checks; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.62.0-source` is a pending stacked PR for release
merge handoff stack-count consistency checks; it is not tagged and does not
ship APK/EXE binaries.

Source readiness note: `v0.63.0-source` is a pending stacked PR for release
merge handoff input-error checks; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.64.0-source` is a pending stacked PR for release
merge handoff tag-readiness input-error coverage; it is not tagged and does
not ship APK/EXE binaries.

Source readiness note: `v0.65.0-source` is a pending stacked PR for release
merge handoff tag-readiness blocker-count consistency; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.66.0-source` is a pending stacked PR for release
merge handoff tag-readiness blocker entry-shape checks; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.67.0-source` is a pending stacked PR for release
merge handoff tag-readiness ready-flag consistency; it is not tagged and does
not ship APK/EXE binaries.

Source readiness note: `v0.68.0-source` is a pending stacked PR for release
merge handoff tag-readiness blocker-absence consistency; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.69.0-source` is a pending stacked PR for source
tag-readiness open-blocker evidence fields; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.70.0-source` is a pending stacked PR for release
merge handoff tag-readiness latest stacked PR consistency; it is not tagged and
does not ship APK/EXE binaries.

Source readiness note: `v0.71.0-source` is a pending stacked PR for release
merge handoff default candidate path consistency; it is not tagged and does
not ship APK/EXE binaries.

Source readiness note: `v0.72.0-source` is a pending stacked PR for release
merge handoff blocker inventory consistency; it is not tagged and does not
ship APK/EXE binaries.

Source readiness note: `v0.73.0-source` is a pending stacked PR for source tag
readiness stale-tag rejection; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.74.0-source` is a pending stacked PR for source tag
readiness milestone evidence PR checks; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.75.0-source` is a pending stacked PR for source tag
readiness milestone source-only flag checks; it is not tagged and does not
ship APK/EXE binaries.

Source readiness note: `v0.76.0-source` is a pending stacked PR for source tag
readiness blocker-inventory source-only flag checks; it is not tagged and does
not ship APK/EXE binaries.

Source readiness note: `v0.77.0-source` is a pending stacked PR for source tag
readiness open-blocker evidence checks; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.78.0-source` is a pending stacked PR for source tag
readiness open-blocker identifier checks; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.79.0-source` is a pending stacked PR for source tag
readiness open-blocker status checks; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.80.0-source` is a pending stacked PR for source tag
readiness required-before-tag blocker flag checks; it is not tagged and does
not ship APK/EXE binaries.

Source readiness note: `v0.81.0-source` is a pending stacked PR for source tag
readiness milestone status checks; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.82.0-source` is a pending stacked PR for source tag
readiness milestone evidence checks; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.83.0-source` is a pending stacked PR for source tag
readiness milestone scope checks; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.84.0-source` is a pending stacked PR for read-only
source tag readiness summaries; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.85.0-source` is a pending stacked PR for source tag
readiness input fingerprints; it is not tagged and does not ship APK/EXE
binaries.

Source readiness note: `v0.86.0-source` is a pending stacked PR for release
merge handoff tag-readiness input fingerprint checks; it is not tagged and does
not ship APK/EXE binaries.

Source readiness note: `v0.87.0-source` is a pending stacked PR for publication
dry-run input fingerprints and handoff proof; it is not tagged and does not ship
APK/EXE binaries.

Source readiness note: `v0.88.0-source` is a pending stacked PR for release
evidence bundle preflight input fingerprints and handoff proof; it is not
tagged and does not ship APK/EXE binaries.

Source readiness note: `v0.89.0-source` is a pending stacked PR for source
preflight artifact fingerprints and handoff proof; it is not tagged and does
not ship APK/EXE binaries.

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
  <a href="docs/ENTERPRISE.md">Enterprise</a>
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
| `v0.23.0-source` | Pending stacked PR, tag еще не создан | CI source-release preflight smoke находится в stacked PR queue. |
| `v0.24.0-source` | Pending stacked PR, tag еще не создан | Specialized GitHub triage templates находятся в stacked PR queue. |
| `v0.25.0-source` | Pending stacked PR, tag еще не создан | GitHub label catalog and triage policy находятся в stacked PR queue. |
| `v0.26.0-source` | Pending stacked PR, tag еще не создан | Runtime artifact manifest gate и local-only libcore review metadata находятся в stacked PR queue. |
| `v0.27.0-source` | Pending stacked PR, tag еще не создан | Source release copy-claims gate находится в stacked PR queue. |
| `v0.28.0-source` | Pending stacked PR, tag еще не создан | Free VPN catalog provenance gate находится в stacked PR queue. |
| `v0.29.0-source` | Pending stacked PR, tag еще не создан | Private security intake gate находится в stacked PR queue. |
| `v0.30.0-source` | Pending stacked PR, tag еще не создан | Changelog and release-history gate находится в stacked PR queue. |
| `v0.31.0-source` | Pending stacked PR, tag еще не создан | Contributor doctor and docs index gate находится в stacked PR queue. |
| `v0.32.0-source` | Pending stacked PR, tag еще не создан | Build troubleshooting router находится в stacked PR queue. |
| `v0.33.0-source` | Pending stacked PR, tag еще не создан | CODEOWNERS review-routing gate находится в stacked PR queue. |
| `v0.34.0-source` | Pending stacked PR, tag еще не создан | Dependabot dependency update policy gate находится в stacked PR queue. |
| `v0.35.0-source` | Pending stacked PR, tag еще не создан | Required checks policy gate находится в stacked PR queue. |
| `v0.36.0-source` | Pending stacked PR, tag еще не создан | GitHub ruleset setup gate находится в stacked PR queue. |
| `v0.37.0-source` | Pending stacked PR, tag еще не создан | GitHub ruleset verifier находится в stacked PR queue. |
| `v0.38.0-source` | Pending stacked PR, tag еще не создан | Release evidence bundle helper находится в stacked PR queue. |
| `v0.39.0-source` | Pending stacked PR, tag еще не создан | Source release publication dry-run validator находится в stacked PR queue. |
| `v0.40.0-source` | Pending stacked PR, tag еще не создан | Enterprise boundary and operator commercial-license guard находится в stacked PR queue. |
| `v0.41.0-source` | Pending stacked PR, tag еще не создан | Safe diagnostics copy/export для support без keys или subscription links находится в stacked PR queue. |
| `v0.42.0-source` | Pending stacked PR, tag еще не создан | Privacy-first diagnostics export policy gate находится в stacked PR queue. |
| `v0.43.0-source` | Pending stacked PR, tag еще не создан | Release blocker inventory для source tag readiness находится в stacked PR queue. |
| `v0.44.0-source` | Pending stacked PR, tag еще не создан | Source tag readiness command находится в stacked PR queue. |
| `v0.45.0-source` | Pending stacked PR, tag еще не создан | Release merge-order verifier находится в stacked PR queue. |
| `v0.46.0-source` | Pending stacked PR, tag еще не создан | Release stack GitHub status verifier находится в stacked PR queue. |
| `v0.47.0-source` | Pending stacked PR, tag еще не создан | Release merge handoff helper находится в stacked PR queue. |
| `v0.48.0-source` | Pending stacked PR, tag еще не создан | Android device validation и release merge handoff default-path fix находятся в stacked PR queue. |
| `v0.49.0-source` | Pending stacked PR, tag еще не создан | Operator request trace и client-version headers находятся в stacked PR queue. |
| `v0.50.0-source` | Pending stacked PR, tag еще не создан | Android native Gradle CI через source-only stubs находится в stacked PR queue. |
| `v0.51.0-source` | Pending stacked PR, tag еще не создан | Windows bundle verifier source-only proof находится в stacked PR queue. |
| `v0.52.0-source` | Pending stacked PR, tag еще не создан | Runtime archive extraction hardening находится в stacked PR queue. |

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
|   |-- GITHUB_TRIAGE.md
|   |-- SOURCE_IMPORT_PLAYBOOK.md
|   |-- PRODUCT_VARIANTS.md
|   |-- OPERATOR_INTEGRATION.md
|   |-- ENTERPRISE.md
|   `-- GOVERNANCE.md
`-- assets/
    |-- brand/
    `-- diagrams/
```

## Сборка Из Исходников

Инструкция по сборке лежит в
[docs/BUILD_FROM_SOURCE.md](docs/BUILD_FROM_SOURCE.md).
Troubleshooting лежит в
[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

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
- [docs/README.md](docs/README.md)
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- [docs/REQUIRED_CHECKS.md](docs/REQUIRED_CHECKS.md)
- [docs/DEPENDENCY_UPDATE_POLICY.md](docs/DEPENDENCY_UPDATE_POLICY.md)
- [docs/MAINTAINER_CHECKLIST.md](docs/MAINTAINER_CHECKLIST.md)
- [docs/PROJECT_PRINCIPLES.md](docs/PROJECT_PRINCIPLES.md)
- [docs/GITHUB_TRIAGE.md](docs/GITHUB_TRIAGE.md)
- [docs/SOURCE_IMPORT_PLAYBOOK.md](docs/SOURCE_IMPORT_PLAYBOOK.md)
- [docs/PRODUCT_VARIANTS.md](docs/PRODUCT_VARIANTS.md)
- [docs/OPERATOR_INTEGRATION.md](docs/OPERATOR_INTEGRATION.md)
- [docs/ENTERPRISE.md](docs/ENTERPRISE.md)
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

См. [Enterprise boundary](docs/ENTERPRISE.md) для operator and commercial
license boundary. Этот документ не меняет GPLv3 license и не предлагает
commercial license by default.

Название POKROV, логотипы, домены, официальные каналы, signing identities и
release distribution channels регулируются отдельно в [BRAND.md](BRAND.md).
