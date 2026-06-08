# POKROV Client

<p align="center">
  <img src="assets/brand/pokrov-oss-hero.png" alt="POKROV Client open-source hero artwork" width="100%">
</p>

<p align="center">
  <a href="LICENSE"><img alt="Лицензия: GPLv3" src="https://img.shields.io/badge/license-GPLv3-0f766e?style=for-the-badge"></a>
  <img alt="Статус исходников: импорт готовится" src="https://img.shields.io/badge/source-pending%20import-f59e0b?style=for-the-badge">
  <img alt="Платформы: Android и Windows" src="https://img.shields.io/badge/platforms-Android%20%2B%20Windows-2563eb?style=for-the-badge">
  <img alt="Официальный сервис: POKROV" src="https://img.shields.io/badge/service-POKROV%20operated-111827?style=for-the-badge">
</p>

<p align="center">
  <strong>Открытый клиент для спокойного app-first подключения.</strong>
  <br>
  Сначала Android и Windows. GPLv3. Публичный импорт исходников готовится.
</p>

<p align="center">
  <a href="README.md">Выбор языка</a>
  ·
  <a href="README.en.md">English</a>
  ·
  <a href="docs/OPEN_SOURCE_SCOPE.md">Scope</a>
  ·
  <a href="SECURITY.md">Security</a>
  ·
  <a href="BRAND.md">Brand</a>
</p>

---

## Что Это

POKROV Client - будущий публичный репозиторий исходного кода клиента POKROV для
Android и Windows.

Сейчас репозиторий находится в режиме open-source foundation: здесь уже есть
публичная структура проекта, правила контрибьюта, security policy, release
policy, граница бренда и чеклист импорта исходников. Санитизированный snapshot
приложения будет добавлен только после проверки приватной client-lane.

## Чем Клиент Отличается

Публичный клиент готовится вокруг нескольких принципов:

- app-first onboarding вместо обязательного входа через бота
- Android и Windows как текущий публичный beta-фокус
- спокойный consumer-интерфейс поверх более сложного routing/runtime слоя
- открытый клиентский код без раскрытия приватных операций сервиса
- честные release notes без неподтвержденных обещаний про store, signing или
  production-ready статус

## Статус

<p align="center">
  <img src="assets/brand/oss-status-card.png" alt="POKROV Client repository status artwork" width="100%">
</p>

| Область | Текущее состояние |
| --- | --- |
| Репозиторий | Public foundation готов |
| Исходники | Санитизированный импорт готовится |
| Платформы | Сначала Android и Windows |
| Лицензия | GNU GPLv3 |
| Официальный backend | Работает отдельно под управлением POKROV |
| Публичные релизы | Только beta-safe и evidence-based формулировки |

## Граница Архитектуры

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
├── README.md                  выбор языка
├── README.en.md               английская версия
├── README.ru.md               русская версия
├── BRAND.md                   граница бренда и official builds
├── SECURITY.md                приватный security-reporting
├── CONTRIBUTING.md            правила контрибьюта
├── ROADMAP.md                 публичная roadmap репозитория
├── docs/
│   ├── OPEN_SOURCE_SCOPE.md
│   ├── RELEASE_POLICY.md
│   ├── DEPENDENCY_LICENSE_AUDIT.md
│   ├── MAINTAINER_CHECKLIST.md
│   ├── PROJECT_PRINCIPLES.md
│   ├── SOURCE_IMPORT_PLAYBOOK.md
│   └── GOVERNANCE.md
└── assets/
    ├── brand/
    └── diagrams/
```

## Сборка Из Исходников

Инструкции по сборке появятся вместе с первым санитизированным snapshot
исходников.

Для maintainers уже есть инструмент подготовки импорта:

```powershell
python -m pytest tests/test_source_import.py
python -m tools.source_import.safe_import --source <snapshot> --staging <stage> --manifest <manifest.json>
```

Планка приемки для импорта простая:

- clean clone должен собираться без приватных файлов
- secrets, certificates и signing identities не должны требоваться для базовой
  локальной сборки
- config examples должны использовать placeholders
- official release metadata не должна указывать на приватные репозитории

## Как Помочь

Контрибьюты приветствуются, особенно вокруг документации, release hygiene,
build reproducibility и подготовки публичного source snapshot.

Перед участием прочитай:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md)
- [BRAND.md](BRAND.md)
- [docs/MAINTAINER_CHECKLIST.md](docs/MAINTAINER_CHECKLIST.md)
- [docs/PROJECT_PRINCIPLES.md](docs/PROJECT_PRINCIPLES.md)
- [docs/SOURCE_IMPORT_PLAYBOOK.md](docs/SOURCE_IMPORT_PLAYBOOK.md)
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
