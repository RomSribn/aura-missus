# AURAI-0012 — приложение: право и приватность ИИ-перевода (решения 6, 7, 10 и §6)

Дата: 2026-11-07 · Статус: **решения 6, 7, 10 приняты владельцем 2026-11-07** — рекомендации ниже подтверждены как
ответы (через координатора slave-1-ac). Черновики DPIA / TIA / записи об обработке не заказаны.
Юриста у проекта нет («нет юриста, я бедный разработчик» — владелец). Это **не юридическая консультация**, а разбор
по открытым источникам. Ссылки — в конце. Отправная точка — опубликованная политика `aura-app.cc/privacy/` (снимок
текста — `AURAT-0042-118-published-pages.md`, «Last updated 1 October 2026», `AURAT-0042-119`).

## Что уже есть

- **Контролёр** — Silvermind OÜ (Эстония). Надзорный орган — Andmekaitse Inspektsioon (AKI), он назван в политике §08.
- **§04:** если человек сам пишет о болезни или вере, это обрабатывается «on the basis of your explicit consent (GDPR
  Art. 9(2)(a)) for the sole purpose of delivering that conversation».
- **§05–§06:** список обработчиков; передача за пределы ЕЭЗ — «adequacy decision … including the EU–US Data Privacy
  Framework where the provider is certified under it, or … Standard Contractual Clauses».
- **§11 и Terms §02:** сервис 18+, «you confirm this when you sign in».

## Две дыры, которые есть и без перевода

1. **«Сам написал» — не явное согласие.** EDPB требует для явного согласия прямого заявления человека: письменное
   заявление, онлайн-форма, подтверждающее письмо. Сообщение в чате таким заявлением не является. Основание §04 сейчас
   слабое.
2. **18+ никто не подтверждает.** `AURAT-0042-107` (строка Terms §02 / Privacy §11): «возраст нигде не спрашивается;
   есть только "By continuing you agree to Terms/Privacy"».

Обе закрываются теми же экранами, что нужны для перевода (ниже).

## Решение 6 — согласие

**Рекомендация: отдельная галочка явного согласия.** Она не склеена с Terms (ст. 7(2) требует, чтобы согласие
отличалось от прочих условий) и показывается **всем** перед первым сообщением в чат:

> ☐ I agree that Aura may process sensitive information I choose to share in chats (for example about health,
> relationships or beliefs) to deliver my readings — including machine translation of my messages by our AI
> provider, Anthropic (USA). I can switch translation off in my profile and withdraw this consent at any time.

Почему так:

- Anthropic — обработчик (ст. 28), а не новая цель. Отдельное основание «на перевод» не нужно. Но основание для
  чувствительных данных — явное согласие, а оно должно быть конкретным и информированным. Поэтому ИИ-перевод и
  Anthropic названы прямо.
- Одна галочка чинит дыру 1 и покрывает перевод.
- В данных хранятся версия текста и время — `chatTranslationConsentAt` / `chatTranslationConsentVersion` (§2 основного
  документа).
- Переключатель «Переводить мой чат» — в профиле. После галочки перевод включён.
- Отзыв согласия выключает перевод. Чат целиком — через удаление аккаунта, как сейчас.

**Поправка владельца 2026-11-08 (до релиза, `AURAT-0200`).** Источник — проверка текста координатором: вывод
«не оптимален, но близок». Владелец: «Давай чуть более обще напишем за провадейра, ибо люди могут испгугаться увидева
AI». На вопросы ответил «Машинный, внешний сервис (Recommended)» и «Да, «Machine-translated» (Recommended)». Новый
текст карточки (версия согласия остаётся 1 — в проде согласий ещё нет):

> ☐ I agree that Aura may use sensitive details I choose to share in chat, like health, love life or beliefs, for my
> readings, and that my chat is machine-translated by an external translation service. I can turn translation off or
> withdraw this consent at any time in my profile.

- «my chat», а не «my messages»: ответы чаттера тоже уходят на перевод. «love life» ближе к категории ст. 9, чем
  «relationships». Перевод — отдельная часть фразы, а не хвост после тире.
- **Anthropic и США с карточки ушли в политику.** Для действительности согласия имя обработчика не нужно: его требует
  прозрачность (ст. 13(1)(e), (f)), а не согласие. На карточке остаётся существенное: перевод машинный и делает внешний
  сервис. Поэтому **до релиза политика §04–§06 обязана назвать** машинный перевод чата, Anthropic как обработчика и
  передачу в США по SCC (задача 9). Без этого согласие не информированное.
- Подпись под переводом и подсказка переключателя — «Machine-translated» вместо «Translated by AI», во всех языках.
- Осталось спорным: полный отзыв — только удалением аккаунта, при одной галочке на согласие (ст. 7(3)). Галочка
  закрывает и чат на английском (ст. 7(4)). Оба пункта — в DPIA; отдельная кнопка отзыва — позже.

**Третьи лица** (человек пишет о болезни родственника). Чистого основания нет ни сейчас (Chatwoot хранит эти тексты),
ни с переводом: перевод добавляет обработчика, а не новую обработку. Меры:

- минимизация — провайдеру уходят 2–4 сообщения контекста, без метаданных;
- фраза политики «Please do not send us more than a reading requires»;
- запись риска в DPIA.

## Решение 7 — регион обработки

**Рекомендация: основной API Anthropic + SCC + короткая TIA.** Bedrock в ЕС — запасной план через адаптер (порт это
позволяет).

Что дают условия Anthropic:

- **DPA** входит в Commercial Terms по ссылке («incorporated into these Terms by reference»). SCC в нём — модуль 2
  (контролёр → обработчик) / модуль 3, плюс приложения для Великобритании и Швейцарии. Подписывать отдельно не нужно.
- **Утечки:** уведомление «without undue delay, but in any event within 48 hours».
- **Расторжение:** данные удаляются в течение 30 дней.
- **Хранение входов и выходов API:**
  - privacy center: «we automatically delete inputs and outputs on our backend within 30 days»;
  - документация API строже: по умолчанию не хранятся, кроме Covered Models (Fable / Mythos, мы их не используем);
  - помеченное системами безопасности — до 2 лет, оценки классификаторов — до 7 лет;
  - обучение: «never used for model training without your express permission»;
  - ZDR — только через отдел продаж.
- **Срок хранения у провайдера — граница удаления** при стирании аккаунта. Записать в политику §07 и DPIA.

**Обратить внимание:**

- **DPF.** DPA Anthropic о DPF не упоминает. Есть ли Anthropic в списке DPF, проверить не удалось: страница
  dataprivacyframework.gov грузится скриптом. Опираться на SCC.
- **Судьба DPF.** Общий суд ЕС оставил DPF в силе (Latombe, T-553/23, 3 сентября 2025), апелляция C-703/25 P ещё
  рассматривается. SCC от её исхода не зависят.
- **TIA** — 1–2 страницы. Комментаторы считают, что гарантии указа 14086 можно учитывать в оценке передачи по SCC.
  Позицию Еврокомиссии из первоисточника не проверял.
- **В приложении 1 DPA** (описание обработки) стоит «Special categories of personal data (if applicable): None».
  Запрета в условиях нет, но разумно один раз написать в privacy Anthropic, что пользователи сами пишут чувствительные
  данные, и сохранить ответ для DPIA.
- **Bedrock, EU cross-region inference** — запросы ходят только между регионами ЕС. Кредиты подписки там не действуют,
  наличие Opus / Sonnet / Haiku 5.5 в ЕС проверить. Claude on Google Cloud (Anthropic-managed) работает только в
  `global` — для ЕС не подходит.

## Решение 10 — возраст

Ст. 8 (порог цифрового согласия 13–16, в Эстонии 13) почти не касается: сервис сам объявлен 18+. Задача —
**выполнить уже данное обещание**:

- при входе — галочка «I confirm I am 18 or older» (или дата рождения);
- если дата рождения в профиле меньше 18 лет — закрыть аккаунт по §11.

Проверка документов для такого сервиса, по открытым источникам, не требуется.

## Остальное из §6 основного документа

- **DPIA (ст. 35) — делать.** Из девяти критериев WP248 у нас минимум два:
  - особые категории;
  - инновационная технология (ИИ);
  - возможно, уязвимые люди: к экстрасенсам приходят в трудный момент.

  При двух и больше DPIA обычно нужна. Бесплатно: руководство и форма AKI (раздел EDPB для малого бизнеса) или
  открытая программа CNIL PIA. Объём — 4–6 страниц.
- **Запись об обработке (ст. 30)** нужна: исключение для компаний меньше 250 человек не действует, раз есть особые
  категории. Можно сделать частью DPIA.
- **AI Act, ст. 50.** Действует с 2 августа 2026 и не отложена Digital Omnibus. Касается систем, которые сами
  общаются с человеком. Перевод между двумя людьми под неё, вероятно, не подпадает. Пометка «Переведено ИИ» (§7
  основного документа) снимает вопрос в любом случае.
- **Новое хранение у нас:**
  - кэш Redis 24 ч;
  - `MessageTranslation`;
  - очереди (политика §07 уже описывает 25 ч / 8 дней).

  Дописать строку про переводы.

**Дописать в политику** (черновики, стиль выровнять):

| Раздел | Что добавить |
|---|---|
| §04 | Ссылка на галочку явного согласия |
| §05 | «Anthropic — machine translation of chat messages; receives the message text only, never your name, phone number or account identifiers» |
| §06 | Anthropic (USA), Standard Contractual Clauses |
| §07 | Переводы хранятся и удаляются вместе с перепиской; у Anthropic входы удаляются в течение 30 дней (до 2 лет, если их пометили системы безопасности) |

## Порядок действий

1. **Галочки 18+ и явного согласия** в приложении и вебе. Нужны даже без перевода; входят в задачи клиентов
   (строки 7–8 разбивки основного документа).
2. **Абзацы политики** (таблица выше).
3. **DPIA, TIA и запись об обработке** — черновики можно составить в brain по фактам основного документа; владелец
   читает и подписывает.
4. **Письмо в privacy Anthropic про особые категории** — по желанию.
5. **Включение в проде** (строка 10 разбивки).

## Sources

- [Claude API — API and data retention](https://platform.claude.com/docs/en/manage-claude/api-and-data-retention)
- [Anthropic Privacy Center — How long do you store my organization's data](https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data)
- [Anthropic Data Processing Addendum](https://www.anthropic.com/legal/data-processing-addendum)
- [Anthropic Commercial Terms](https://www.anthropic.com/legal/commercial-terms)
- [Anthropic — how to view the DPA](https://privacy.claude.com/en/articles/7996862-how-do-i-view-and-sign-your-data-processing-addendum-dpa)
- [EDPB — summary on consent (2026)](https://www.edpb.europa.eu/system/files/2026-04/edpb-summary-consent_en.pdf)
- [Hunton — EDPB updated consent guidelines](https://www.hunton.com/privacy-and-cybersecurity-law-blog/2020/05/07/edpb-publishes-updated-guidelines-on-consent-under-the-gdpr/)
- [SCL — When to conduct DPIAs (WP248 criteria)](https://www.scl.org/10311-when-to-conduct-dpias/)
- [Malta IDPC — DPIA](https://idpc.org.mt/for-organisations/data-protection-impact-assessment/)
- [EDPB — DPIA lists register](https://www.edpb.europa.eu/node/568_en)
- [EDPB SME guide — AKI DPIA guidance and form](https://edpb.europa.eu/sme-data-protection-guide/practical-resources-for-smes/estonia/andmekaitse-moju-hindamise-juhend-ja_pl)
- [WilmerHale — CJEU to review DPF challenge](https://www.wilmerhale.com/en/insights/blogs/wilmerhale-privacy-and-cybersecurity-law/20251201-european-court-of-justice-to-review-challenge-to-eu-us-data-privacy-framework)
- [EDPL — Latombe v Commission](https://edpl.lexxion.eu/article/EDPL/2026/1/15)
- [Linklaters — EU-US DPF](https://www.linklaters.com/insights/blogs/digilinks/2023/july/eu-and-us--the-new-eu-us-data-privacy-framework--third-time-lucky)
- [Freshfields — EO 14086 and TIAs](https://blog.freshfields.us/post/102hyzu/glimmers-of-a-new-shinier-privacy-shield-executive-order-released-for-the-late)
- [Bird & Bird — Children in the digital world (EU)](https://childreninthedigitalworld.twobirds.com/home/eu)
- [AWS — Bedrock cross-region inference](https://docs.aws.eu/bedrock/latest/userguide/cross-region-inference.html)
- [AWS — cross-region inference for EU data processing](https://aihub.hkuspace.hku.hk/2026/06/09/unlocking-ai-flexibility-in-europe-a-guide-to-cross-region-inference-for-eu-data-processing-and-model-access/)
- [Goodwin — AI Act transparency obligations now in force](https://www.goodwinlaw.com/en/insights/publications/2026/08/alerts-technology-dpc-eu-ai-act-transparency-obligations-now-in-force)
- [Houthoff — AI Act transparency and the AI Omnibus](https://www.houthoff.com/insights/news/ai-act-transparency-obligations-and-the-ai-omnibus-regulation/)
