#!/usr/bin/env bash
# Заливка колоды таро в aura-assets (AURAD-0012).
#
# usage: R2_ENDPOINT=https://<account>.r2.cloudflarestorage.com \
#        AWS_PROFILE=r2-aura-assets \
#        ./AURAD-0012-upload.sh /path/to/deck-images
#
# Файлы ищутся по sha256 из манифеста, а не по имени: имя источника может
# смениться, содержимое — нет.
set -euo pipefail

MANIFEST="$(cd "$(dirname "$0")" && pwd)/AURAD-0012-deck-manifest.json"
BUCKET="${BUCKET:-aura-assets}"
PUBLIC="${PUBLIC:-https://assets.aura-app.cc}"
SRC="${1:?usage: $0 <каталог с картинками>}"

command -v aws >/dev/null || { echo "нужен aws cli" >&2; exit 1; }
command -v jq  >/dev/null || { echo "нужен jq" >&2; exit 1; }
: "${R2_ENDPOINT:?задай R2_ENDPOINT}"

cd "$SRC"

# --- 1. Сверка до единой записи в бакет -------------------------------------
# Полколоды в бакете — это поломка, которую заметит первый человек, которому
# выпадет недостающая карта. Поэтому сначала проверяем всё, потом льём.
declare -A BY_HASH
for f in *.png; do
  BY_HASH["$(shasum -a 256 "$f" | cut -d' ' -f1)"]="$f"
done

missing=0
while IFS=$'\t' read -r sha key; do
  [[ -n "${BY_HASH[$sha]:-}" ]] || { echo "нет файла для $key ($sha)" >&2; missing=1; }
done < <(jq -r '.[] | "\(.sha256)\t\(.key)"' "$MANIFEST")
[[ $missing -eq 0 ]] || { echo "заливка не начата" >&2; exit 1; }
echo "→ все $(jq length "$MANIFEST") файла на месте"

# --- 2. Заливка -------------------------------------------------------------
while IFS=$'\t' read -r sha key; do
  src="${BY_HASH[$sha]}"
  aws s3api put-object \
    --bucket "$BUCKET" --key "$key" --body "$src" \
    --content-type image/png \
    --cache-control 'public, max-age=31536000, immutable' \
    --endpoint-url "$R2_ENDPOINT" >/dev/null
  printf '.'
done < <(jq -r '.[] | "\(.sha256)\t\(.key)"' "$MANIFEST")
echo
echo "→ залито"

# --- 3. Проверка через публичный домен, а не через бакет ---------------------
# Именно то, чем пользуется приложение: адрес, а не ключ.
bad=0
while IFS=$'\t' read -r key bytes; do
  got=$(curl -sfI "$PUBLIC/$key" | awk -F': *' 'tolower($1)=="content-length"{print $2+0}')
  [[ "$got" == "$bytes" ]] || { echo "ПЛОХО $key: ждали $bytes, получили ${got:-нет ответа}" >&2; bad=1; }
done < <(jq -r '.[] | "\(.key)\t\(.bytes)"' "$MANIFEST")
[[ $bad -eq 0 ]] && echo "→ все объекты отдаются с верным размером" || exit 1
