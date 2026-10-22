# brushio.github.io

Сайт iOS-приложения Brushio: https://brushio.github.io/

## Что где

| Путь | Что это |
|---|---|
| `index.md`, `uk/index.md` | Главная (лендинг) на английском и украинском |
| `privacy.html`, `terms.html` | Privacy Policy и Terms of Use (пока только на английском) |
| `support.md`, `uk/support.md` | Поддержка; тексты - раздел `support` в `_data/<язык>.yml`, разметка - `_layouts/support.html` |
| `_data/<язык>.yml` | Все тексты страницы на этом языке (главная - раздел `v1`) |
| `_layouts/v1.html` | Разметка главной (название `v1` - от макета «вариант 1») |
| `_layouts/legal.html` | Разметка Privacy / Terms |
| `_includes/` | `<head>`, шапка `v1-header.html`, подвал `v1-footer.html`, меню языков и т.п. |
| `assets/css/v1.css`, `assets/js/v1.js` | Стили сайта и анимации главной |
| `assets/img/` | Иконки сайта (из иконки приложения), значок App Store, скриншоты |
| `_config.yml` | Ссылки на App Store, почту поддержки, privacy/terms/support, список языков |
| `scripts/check-site.sh` | Проверка собранного сайта |
| `scripts/make-icons.swift` | Сделать иконки сайта из PNG иконки приложения |
| `scripts/make-screens.swift` | Сделать скриншоты для сайта (AVIF) из `../design/screens/<язык>/` |
| `_includes/screen.html` | Вставить скриншот на языке страницы (нет такого - английский) |

Privacy, Terms и Support - на этом сайте. Старые страницы
`brushio.github.io/brushio-legal/...` не трогаем: на них ссылается приложение.

Меню языков показывает только языки, на которые переведена текущая страница;
у страницы без переводов (пока Privacy и Terms) меню нет.

## Публикация

`.github/workflows/pages.yml` собирает сайт через Jekyll, запускает
`scripts/check-site.sh` и публикует его на GitHub Pages при каждом пуше в `main`.
Один раз в настройках репозитория: **Settings → Pages → Source = GitHub Actions**.

Сборка падает, если:
- есть битая внутренняя ссылка или якорь;
- нет главной страницы для языка из `_config.yml`;
- страница грузит что-то со стороннего адреса (шрифты, скрипты, аналитика) -
  политика конфиденциальности обещает «без трекинга»;
- в тексте есть длинное тире «—» (в проекте пишем «-»).

## Локальный просмотр

Нужен Jekyll 3.10 (та же версия, что у GitHub Pages):

```sh
JEKYLL_NO_BUNDLER_REQUIRE=true jekyll build && bash scripts/check-site.sh
python3 -m http.server 4000 --directory _site
```

Открыть http://127.0.0.1:4000/

## Скриншоты

Оригиналы из Figma (PNG в рамке iPhone) лежат в `../design/screens/<язык>/<экран>.png`,
имена одинаковые во всех языках (`timer.png`, `calendar.png`, ...). После новых
скриншотов или нового языка (на Mac):

```sh
swift scripts/make-screens.swift
```

Получатся `assets/img/screens/<язык>/<экран>.avif` (720 px, ~30-40 КБ).

## Privacy Policy

Текст - из генератора Termly (анкета пройдена 21-22.10.2026), страница `privacy.html`
(`/privacy/`, шаблон `_layouts/legal.html`). Термли выдаёт HTML с кучей служебных тегов,
поэтому текст перенесён вручную в чистую разметку. При новом экспорте из Termly
нужно повторить наши правки:

- «…for troubleshooting, and for our internal analytics and reporting purposes» →
  «…and for troubleshooting.» (аналитики нет);
- раздел 7: убрать «deactivate the account and» (аккаунтов нет);
- раздел 8, «In Short»: убрать фразу «You may review, change, or terminate your account…»;
- раздел 10: убрать пункт «Participation in customer surveys or contests»;
- раздел 14: убрать почтовый адрес («contact us by post at: Brushio, Kyiv, Ukraine»),
  оставить только email - как в старой версии;
- раздел 5 и раздел 12: Termly переводит наш текст в нижний регистр и теряет абзацы -
  вернуть заглавные буквы (iCloud, Brushio, Settings) и разбивку на абзацы/список;
- «apple health» → «Apple Health»;
- ссылки на старую поддержку `brushio-legal/support.html` (3 шт.: «Summary», разделы 10 и 15) →
  новая `https://brushio.github.io/support/`;
- дата «Last updated» - день публикации на сайте.

Строку «This Privacy Policy was created using Termly's Privacy Policy Generator»
не убирать.

## Terms of Use

Текст - из генератора Termly (анкета пройдена 22.10.2026), страница `terms.html`
(`/terms/`). Оригинал экспорта - `../termly/terms-of-use-termly-2026-10-22.html`.
При новом экспорте нужно повторить наши правки:

- вступление: «a company registered in Ukraine at ___, Kyiv» → «an app made by an
  independent developer based in Kyiv, Ukraine»; убрать термин «Company»;
- вступление: убрать «or by mail to ___, Kyiv, Ukraine» (только email);
- раздел 3: «suspend or terminate your account and refuse…» → «refuse…» (аккаунтов нет);
- раздел 4, Free Trial: «to new users who register with the Services» →
  «We offer a 3-day free trial of Brushio Pro.»;
- раздел 6: оставить одно предложение «The Services do not allow users to post content
  or share it with other users.» (Termly добавляет противоречащий ему список);
- раздел 8: «Apple and Android Devices / Apple Store or Google Play» → только Apple
  App Store, iOS и watchOS;
- раздел 11: вместо «hosted in Ukraine… transferring your data to Ukraine» -
  «Brushio does not send your personal data to us…» (данные на устройстве и в iCloud);
- раздел 12: убрать абзац про блокировку аккаунта и запрет создавать новый,
  оставить последнее предложение про legal action;
- раздел 20: вместо «We will maintain… regular routine backups» - данные на
  устройствах и в iCloud, у нас доступа нет, копий не делаем;
- опечатки Termly: «or arbitration» → «of arbitration», «negotiations binding» →
  «negotiations and binding», «six (6) mONTH» → «SIX (6) MONTH»;
- дата «Last updated» - день публикации на сайте.

Строку «This Terms and Conditions was created using Termly's…» не убирать.

## Иконки

После смены иконки приложения: экспортировать её из Icon Composer
(File → Export, iOS, Default, 1024×1024 PNG) в `../design/icon.png` и на Mac:

```sh
swift scripts/make-icons.swift ../design/icon.png
```
