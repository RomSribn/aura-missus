// Zero-dependency-at-runtime shape: 24 make-plural rule functions + a tiny PluralRules
// exposing exactly what i18next v26 calls (constructor(locale,{type}), select, resolvedOptions().pluralCategories).
import { en, bg, cs, da, de, el, es, et, fi, fr, ga, hr, hu, it, lt, lv, mt, nl, pl, pt, ro, sk, sl, sv } from 'make-plural/plurals';
import * as Cat from 'make-plural/pluralCategories';
const RULES = { en, bg, cs, da, de, el, es, et, fi, fr, ga, hr, hu, it, lt, lv, mt, nl, pl, pt, ro, sk, sl, sv };
const pick = (locales) => {
  const list = locales == null ? [] : Array.isArray(locales) ? locales : [locales];
  for (const tag of list) { const lc = String(tag).toLowerCase().split(/[-_]/)[0]; if (RULES[lc]) return lc; }
  return 'en';
};
class PluralRules {
  constructor(locales, options) { this._lc = pick(locales); this._ord = !!options && options.type === 'ordinal'; }
  select(n) {
    const x = Math.abs(Number(n));
    if (!isFinite(x)) return 'other';
    // plural operands from a plain decimal string: no grouping, max 3 fraction digits (Intl default), trailing zeros dropped
    const s = String(Math.round(x * 1000) / 1000);
    return RULES[this._lc](s, this._ord);
  }
  resolvedOptions() { return { locale: this._lc, type: this._ord ? 'ordinal' : 'cardinal', pluralCategories: Cat[this._lc][this._ord ? 'ordinal' : 'cardinal'].slice() }; }
  static supportedLocalesOf(locales) { const list = Array.isArray(locales) ? locales : [locales]; return list.filter((t) => RULES[String(t).toLowerCase().split(/[-_]/)[0]]); }
}
if (typeof Intl.PluralRules === 'undefined') Intl.PluralRules = PluralRules;
