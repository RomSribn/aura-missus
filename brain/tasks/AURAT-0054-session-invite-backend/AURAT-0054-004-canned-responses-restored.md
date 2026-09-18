# AURAT-0054-004 — Быстрые ответы Chatwoot: где они живут и как их восстановить

Дата: 2026-09-18
Повод: владелец не нашёл «кастомные команды» в Chatwoot.

## Что выяснилось

Быстрые ответы (`canned responses`) **привязаны к аккаунту Chatwoot**, а не к
установке. С `AURAD-0016` аккаунтов два:

| Аккаунт | Куда идут диалоги | Быстрых ответов было |
|---|---|---|
| 1 «Aura» | прод-приложение, здесь работают чаттеры | **80** — все на месте |
| 2 «Aura Dev» | dev-сборка приложения | **0** |

Ничего не пропадало: залитые в `AURAT-0054-003` ответы лежат в аккаунте 1, а
аккаунт 2 создан позже и пустым.

**Разовый скрипт `project/manor/chatwoot-canned-responses.sh` не сохранился** —
удалён при уборке временных файлов во время разделения окружений. Поэтому он
воспроизведён здесь: brain под контролем версий, манор — нет.

## Сделано 2026-09-18

Все 80 ответов скопированы из аккаунта 1 в аккаунт 2 (`rails runner` в
прод-контейнере `rails-forqvdvibl9wjec2yk0mqkeo`): `created=80 skipped=0`,
в «Aura Dev» стало 80.

## Скрипт: залить набор в любой аккаунт

Идемпотентен: существующий `short_code` пропускается, ничего не
перезаписывается и не удаляется. `ACCOUNT_ID` — номер аккаунта Chatwoot.

```bash
R=$(docker ps --format '{{.Names}}' | grep '^rails-' | head -1)
docker exec -i $R sh -c 'cat > /tmp/seed-canned.rb' <<'RB'
ACCOUNT_ID = (ENV['ACCOUNT_ID'] || '1').to_i
PAIRS = {
  "the_lovers" => "::LOVERS::",
  "session" => "::SESSION::",
  "major_00_fool" => "::MAJOR_00_FOOL::",
  "major_01_magician" => "::MAJOR_01_MAGICIAN::",
  "major_02_high_priestess" => "::MAJOR_02_HIGH_PRIESTESS::",
  "major_03_empress" => "::MAJOR_03_EMPRESS::",
  "major_04_emperor" => "::MAJOR_04_EMPEROR::",
  "major_05_hierophant" => "::MAJOR_05_HIEROPHANT::",
  "major_06_lovers" => "::MAJOR_06_LOVERS::",
  "major_07_chariot" => "::MAJOR_07_CHARIOT::",
  "major_08_strength" => "::MAJOR_08_STRENGTH::",
  "major_09_hermit" => "::MAJOR_09_HERMIT::",
  "major_10_wheel" => "::MAJOR_10_WHEEL::",
  "major_11_justice" => "::MAJOR_11_JUSTICE::",
  "major_12_hanged_man" => "::MAJOR_12_HANGED_MAN::",
  "major_13_death" => "::MAJOR_13_DEATH::",
  "major_14_temperance" => "::MAJOR_14_TEMPERANCE::",
  "major_15_devil" => "::MAJOR_15_DEVIL::",
  "major_16_tower" => "::MAJOR_16_TOWER::",
  "major_17_star" => "::MAJOR_17_STAR::",
  "major_18_moon" => "::MAJOR_18_MOON::",
  "major_19_sun" => "::MAJOR_19_SUN::",
  "major_20_judgement" => "::MAJOR_20_JUDGEMENT::",
  "major_21_world" => "::MAJOR_21_WORLD::",
  "wands_ace" => "::WANDS_ACE::",
  "wands_02" => "::WANDS_02::",
  "wands_03" => "::WANDS_03::",
  "wands_04" => "::WANDS_04::",
  "wands_05" => "::WANDS_05::",
  "wands_06" => "::WANDS_06::",
  "wands_07" => "::WANDS_07::",
  "wands_08" => "::WANDS_08::",
  "wands_09" => "::WANDS_09::",
  "wands_10" => "::WANDS_10::",
  "wands_page" => "::WANDS_PAGE::",
  "wands_knight" => "::WANDS_KNIGHT::",
  "wands_queen" => "::WANDS_QUEEN::",
  "wands_king" => "::WANDS_KING::",
  "cups_ace" => "::CUPS_ACE::",
  "cups_02" => "::CUPS_02::",
  "cups_03" => "::CUPS_03::",
  "cups_04" => "::CUPS_04::",
  "cups_05" => "::CUPS_05::",
  "cups_06" => "::CUPS_06::",
  "cups_07" => "::CUPS_07::",
  "cups_08" => "::CUPS_08::",
  "cups_09" => "::CUPS_09::",
  "cups_10" => "::CUPS_10::",
  "cups_page" => "::CUPS_PAGE::",
  "cups_knight" => "::CUPS_KNIGHT::",
  "cups_queen" => "::CUPS_QUEEN::",
  "cups_king" => "::CUPS_KING::",
  "swords_ace" => "::SWORDS_ACE::",
  "swords_02" => "::SWORDS_02::",
  "swords_03" => "::SWORDS_03::",
  "swords_04" => "::SWORDS_04::",
  "swords_05" => "::SWORDS_05::",
  "swords_06" => "::SWORDS_06::",
  "swords_07" => "::SWORDS_07::",
  "swords_08" => "::SWORDS_08::",
  "swords_09" => "::SWORDS_09::",
  "swords_10" => "::SWORDS_10::",
  "swords_page" => "::SWORDS_PAGE::",
  "swords_knight" => "::SWORDS_KNIGHT::",
  "swords_queen" => "::SWORDS_QUEEN::",
  "swords_king" => "::SWORDS_KING::",
  "pentacles_ace" => "::PENTACLES_ACE::",
  "pentacles_02" => "::PENTACLES_02::",
  "pentacles_03" => "::PENTACLES_03::",
  "pentacles_04" => "::PENTACLES_04::",
  "pentacles_05" => "::PENTACLES_05::",
  "pentacles_06" => "::PENTACLES_06::",
  "pentacles_07" => "::PENTACLES_07::",
  "pentacles_08" => "::PENTACLES_08::",
  "pentacles_09" => "::PENTACLES_09::",
  "pentacles_10" => "::PENTACLES_10::",
  "pentacles_page" => "::PENTACLES_PAGE::",
  "pentacles_knight" => "::PENTACLES_KNIGHT::",
  "pentacles_queen" => "::PENTACLES_QUEEN::",
  "pentacles_king" => "::PENTACLES_KING::",
}
account = Account.find(ACCOUNT_ID)
created = 0
skipped = 0
PAIRS.each do |short_code, content|
  if account.canned_responses.exists?(short_code: short_code)
    skipped += 1
  else
    account.canned_responses.create!(short_code: short_code, content: content)
    created += 1
  end
end
puts "account=#{account.name} created=#{created} skipped=#{skipped} total=#{account.canned_responses.count}"
RB
docker exec -e ACCOUNT_ID=2 $R bundle exec rails runner /tmp/seed-canned.rb
docker exec $R rm -f /tmp/seed-canned.rb
```

## Скрипт: скопировать из одного аккаунта в другой

```ruby
src = Account.find(1)
dst = Account.find(2)
created = 0
skipped = 0
src.canned_responses.order(:id).each do |cr|
  if dst.canned_responses.exists?(short_code: cr.short_code)
    skipped += 1
  else
    dst.canned_responses.create!(short_code: cr.short_code, content: cr.content)
    created += 1
  end
end
puts "created=#{created} skipped=#{skipped} dest=#{dst.canned_responses.count}"
```

## Почему это важно

Оператор набирает `/cups_10`, и в сообщение подставляется токен `::CUPS_10::`,
который BFF превращает в карту. Опечатка в токене стоит целого сообщения:
сломанный токен отвергается до записи, оператор получает приватную заметку, а
человек не получает ничего (`AURAT-0054-002`). `/session` — приглашение на
платную сессию.

**Новому аккаунту Chatwoot набор нужно заливать отдельно.** Это же относится к
письмам о назначении диалога, которые Chatwoot включает каждому новому
оператору (`AURAS-0004`, «Adding a colleague»).
