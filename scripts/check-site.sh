#!/usr/bin/env bash
# Проверка собранного сайта перед публикацией.
# Запуск: scripts/check-site.sh [папка сборки, по умолчанию _site]
#
# 1. Все языки из _config.yml собраны (главная есть для каждого).
# 2. Все внутренние ссылки и ресурсы ведут на существующие файлы.
# 3. Страницы не загружают ничего со сторонних адресов (шрифты, скрипты,
#    аналитика) - иначе политика конфиденциальности «без трекинга» станет неправдой.
#    Обычные ссылки <a href> на App Store и т.п. разрешены.
# 4. Нет длинного тире «—» в текстах (правило проекта: только «-»).

set -euo pipefail

SITE="${1:-_site}"
cd "$(dirname "$0")/.."

if [ ! -d "$SITE" ]; then
  echo "✗ Нет папки сборки $SITE - сначала соберите сайт" >&2
  exit 2
fi

python3 -I - "$SITE" <<'PY'
import os, re, sys
from html.parser import HTMLParser
from urllib.parse import urlparse, unquote

site = sys.argv[1]
errors = []

# --- 1. Языки ---
langs = []
with open("_config.yml", encoding="utf-8") as f:
    in_langs = False
    for line in f:
        if line.startswith("languages:"):
            in_langs = True
            continue
        if in_langs:
            m = re.match(r"\s+-\s+(\S+)", line)
            if m:
                langs.append(m.group(1))
            elif line.strip() and not line.startswith(" "):
                break
for i, lang in enumerate(langs):
    home = os.path.join(site, "index.html") if i == 0 else os.path.join(site, lang, "index.html")
    if not os.path.isfile(home):
        errors.append(f"нет главной для языка {lang}: {home}")
    if not os.path.isfile(os.path.join("_data", f"{lang}.yml")):
        errors.append(f"нет текстов _data/{lang}.yml")

# --- 2-4. Разбор страниц ---
class Collector(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []      # (тег, атрибут, url)
        self.ids = set()
        self.text = []
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "id" in a:
            self.ids.add(a["id"])
        for attr in ("href", "src", "srcset", "poster"):
            if a.get(attr):
                self.links.append((tag, attr, a[attr]))
        if tag == "meta" and a.get("content", "").startswith(("http://", "https://")):
            self.links.append((tag, "content", a["content"]))
    def handle_data(self, data):
        self.text.append(data)

def target_path(page_path, url):
    path = unquote(urlparse(url).path)
    if path.startswith("/"):
        full = os.path.join(site, path.lstrip("/"))
    else:
        full = os.path.join(os.path.dirname(page_path), path)
    if full.endswith("/") or os.path.isdir(full):
        full = os.path.join(full, "index.html")
    return os.path.normpath(full)

pages = {}
for dirpath, _, files in os.walk(site):
    for name in files:
        if name.endswith(".html"):
            p = os.path.join(dirpath, name)
            c = Collector()
            with open(p, encoding="utf-8") as f:
                c.feed(f.read())
            pages[os.path.normpath(p)] = c

own_hosts = {"brushio.github.io"}
for page, c in pages.items():
    rel = os.path.relpath(page, site)
    for tag, attr, url in c.links:
        u = urlparse(url)
        if u.scheme in ("mailto", "tel"):
            continue
        if u.scheme in ("http", "https"):
            # Загружаемый ресурс со стороннего хоста - запрещено.
            is_resource = tag in ("img", "script", "iframe", "source", "video", "audio") or \
                          (tag == "link" and attr == "href")
            if is_resource and u.hostname not in own_hosts:
                errors.append(f"{rel}: сторонний ресурс <{tag} {attr}={url}>")
            continue
        if u.scheme:
            continue
        if not u.path:
            # Якорь на этой же странице.
            if u.fragment and u.fragment not in c.ids:
                errors.append(f"{rel}: нет якоря #{u.fragment}")
            continue
        target = target_path(page, url)
        if not os.path.exists(target):
            errors.append(f"{rel}: битая ссылка {url}")
        elif u.fragment and target in pages and u.fragment not in pages[target].ids:
            errors.append(f"{rel}: нет якоря {url}")
    if "—" in "".join(c.text):
        errors.append(f"{rel}: в тексте длинное тире «—», нужно «-»")

# Сторонние адреса внутри CSS (url(...), @import).
for dirpath, _, files in os.walk(site):
    for name in files:
        if name.endswith(".css"):
            p = os.path.join(dirpath, name)
            css = open(p, encoding="utf-8").read()
            for m in re.finditer(r"(?:url\(\s*['\"]?|@import\s+['\"])(https?://[^'\")\s]+)", css):
                if urlparse(m.group(1)).hostname not in own_hosts:
                    errors.append(f"{os.path.relpath(p, site)}: сторонний ресурс {m.group(1)}")

if errors:
    print("✗ Проверка сайта не пройдена:")
    for e in errors:
        print("  -", e)
    sys.exit(1)
print(f"✓ Проверка сайта пройдена: {len(pages)} стр., языки: {', '.join(langs)}")
PY
