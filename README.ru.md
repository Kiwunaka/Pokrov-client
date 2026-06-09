# POKROV Client

<p align="center">
  <img src="assets/brand/pokrov-oss-hero.png" alt="POKROV Client open-source hero artwork" width="100%">
</p>

<p align="center">
  <a href="LICENSE"><img alt="Лицензия: GPLv3" src="https://img.shields.io/badge/license-GPLv3-0f766e?style=for-the-badge"></a>
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

- Community client: нейтральный клиент без брендинга POKROV и без обращений к
  POKROV API по умолчанию. Уже есть MVP локального импорта одиночных ключей
  `vless://`, `trojan://`, `ss://` и `vmess://`, а один активный локальный
  профиль можно заменить или удалить.
- Operator client: white-label путь для компаний, которые хотят подключить
  приложение к своему backend, billing, support и бренду.
- POKROV service mode: только для официальных сборок POKROV и официальных
  endpoint'ов POKROV.

URL-подписки, QR-импорт, список нескольких сохранённых профилей и опциональный каталог
бесплатных VPN-конфигов запланированы отдельными этапами с проверкой парсеров,
лицензий и безопасного поведения.

## Статус

<p align="center">
  <img src="assets/brand/oss-status-card.png" alt="POKROV Client repository status artwork" width="100%">
</p>

| Область | Текущее состояние |
| --- | --- |
| Репозиторий | Публичная база готова |
| Исходники | Санитизированный Android + Windows snapshot импортирован |
| Community mode | MVP локального импорта ключа и активного профиля |
| Operator mode | White-label контракты задокументированы |
| Платформы | Сначала Android и Windows |
| Лицензия | GNU GPLv3 |
| Официальный backend | Работает отдельно под управлением POKROV |
| Публичные релизы | Только beta-safe и evidence-based формулировки |

## Архитектурная Граница

<p align="center">
  <img src="assets/diagrams/open-source-boundary.png" alt="Open-source client and private service boundary artwork" width="100%">
</p>

Этот репозиторий предназначен для клиентского приложения. Здесь нет
официального backend POKROV, billing-системы, admin tools, deploy scripts,
signing material, private release evidence или operator runbooks.

Полная граница описана в
[docs/OPEN_SOURCE_SCOPE.md](docs/OPEN_SOURCE_SCOPE.md).

## Карта Репозитория

```text
.
|-- README.md                  выбор языка
|-- README.en.md               английская версия
|-- README.ru.md               русская версия
|-- apps/                      Android и Windows Flutter hosts
|-- packages/                  shared Flutter packages
|-- config/                    public seed config и runtime contracts
|-- scripts/                   local bootstrap, runtime-fetch и test scripts
|-- BRAND.md                   граница бренда и official builds
|-- SECURITY.md                приватный security-reporting
|-- CONTRIBUTING.md            правила контрибьюта
|-- ROADMAP.md                 публичная roadmap репозитория
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

Инструкции по сборке доступны в
[docs/BUILD_FROM_SOURCE.md](docs/BUILD_FROM_SOURCE.md).

Для maintainers уже есть инструмент подготовки импорта:

```powershell
python -m pytest tests/test_source_import.py
python -m tools.source_import.safe_import --source <snapshot> --staging <stage> --manifest <manifest.json>
```

Планка приёмки для импорта простая:

- clean clone должен собираться без приватных файлов
- secrets, certificates и signing identities не должны требоваться для базовой
  локальной сборки
- config examples должны использовать placeholders
- official release metadata не должна указывать на приватные репозитории

## Как Помочь

Контрибьюты приветствуются, особенно вокруг документации, release hygiene,
build reproducibility, локального импорта профилей, operator integration и
подготовки публичного source snapshot.

Перед участием прочитай:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md)
- [BRAND.md](BRAND.md)
- [docs/MAINTAINER_CHECKLIST.md](docs/MAINTAINER_CHECKLIST.md)
- [docs/PROJECT_PRINCIPLES.md](docs/PROJECT_PRINCIPLES.md)
- [docs/SOURCE_IMPORT_PLAYBOOK.md](docs/SOURCE_IMPORT_PLAYBOOK.md)
- [docs/PRODUCT_VARIANTS.md](docs/PRODUCT_VARIANTS.md)
- [docs/OPERATOR_INTEGRATION.md](docs/OPERATOR_INTEGRATION.md)
- [docs/GOVERNANCE.md](docs/GOVERNANCE.md)

Пожалуйста, не открывай публичные issues с secrets, личными connection links,
private backend details, account data или подробностями уязвимостей.

## Официальные Ссылки

- Сайт: https://pokrov.space/
- Кабинет: https://app.pokrov.space/
- Публичный канал: https://t.me/pokrov_vpn
- Support bot: https://t.me/pokrov_supportbot

Официальные binaries публикуются только через release-каналы POKROV. Форки и
пересобранные клиенты не должны выглядеть как official POKROV builds.

## Лицензия

Репозиторий распространяется под GNU General Public License v3.0. См.
[LICENSE](LICENSE).

Имя POKROV, логотипы, домены, официальные каналы, signing identities и release
distribution channels регулируются отдельно в [BRAND.md](BRAND.md).
