# Multi-Locale Architecture and LNI Specification

## Overview

`w3x2lni` provides native multi-locale (i18n) support for Warcraft III maps.
The design adheres to the **"LNI as the Single Source of Truth"** principle:
- All localization variants are embedded directly inside `table/*.ini`, `table/w3i.ini` and `table/skin.ini`.
- No separate `locales/` directory or raw SLK shards exist in LNI project directories.
- When packing to binary maps (`w2l obj` or `w2l slk`), `w3x2lni` automatically distributes translations into MPQ localized `war3map.wts`, `Units/*Strings.txt` and `war3mapskin.txt` files under their respective Windows LCIDs.
- Unpacking (`w2l lni`) from both OBJ maps and SLK maps dynamically extracts all localized variants from the MPQ and consolidates them into the LNI tables.

---

## LNI Multi-Locale Syntax

### 1. Single-String Fields (Flat Localized Table)
Applies to non-repeating string fields such as object `Name`, `Description`, and map metadata in `table/w3i.ini`:

```ini
[AHtb]
_parent = "AHtb"
Name = {
    "風暴之錘",                     -- Neutral fallback (LCID 0x0000)
    enUS = "Storm Bolt",           -- English (LCID 0x0409)
    koKR = "폭풍의 망치",           -- Korean (LCID 0x0412)
    zhTW = "風暴之錘",             -- Traditional Chinese (LCID 0x0404)
}
```

### 2. Multi-Level String Fields (Locale-First Array / 語系陣列)
Applies to repeating string fields such as `Tip`, `Ubertip`, and `Researchubertip`:

```ini
[AIWT]
_parent = "AHtb"
Tip = {
    {
        "|c00ffff80肅清之意|r(|cffffcc00W|r) - [|cffffcc00等級 1|r]",
        "|c00ffff80肅清之意|r(|cffffcc00W|r) - [|cffffcc00等級 2|r]",
        "|c00ffff80肅清之意|r(|cffffcc00W|r) - [|cffffcc00等級 3|r]",
    },
    enUS = {
        "|c00ffff80Will of Purge|r(|cffffcc00W|r) - [|cffffcc00Level 1|r]",
        "|c00ffff80Will of Purge|r(|cffffcc00W|r) - [|cffffcc00Level 2|r]",
        "|c00ffff80Will of Purge|r(|cffffcc00W|r) - [|cffffcc00Level 3|r]",
    },
    koKR = {
        "|c00ffff80숙청의 의|r(|cffffcc00W|r) - [|cffffcc00레벨 1|r]",
        "|c00ffff80숙청의 의|r(|cffffcc00W|r) - [|cffffcc00레벨 2|r]",
        "|c00ffff80숙청의 의|r(|cffffcc00W|r) - [|cffffcc00레벨 3|r]",
    },
}
```

Multiline strings use Lua's `[=[ ... ]=]` delimiter:

```ini
Ubertip = {
    {
        [=[
向目標投擲魔法戰錘，造成傷害並使其眩暈。
]=],
    },
    enUS = {
        [=[
Throws a magical hammer that damages and stuns the target.
]=],
    },
}
```

### 3. Map Information (`table/w3i.ini`)

```ini
[地图]
地图名称 = {
    "盜賊山嶺 (Bandit Ridge)",
    enUS = "Bandit Ridge",
    koKR = "밴디트 릿지 (Bandit Ridge)",
    zhTW = "盜賊山嶺 (Bandit Ridge)",
}
地图描述 = {
    "鵝卵石鋪成的道路，穿越這片盜賊肆虐的山嶺...",
    enUS = "A cobblestone path offers a treacherous route through this mountain...",
    koKR = "자갈길은 산적들이 들끓는 이 산을 넘는 위험한 경로입니다...",
}
```

### 4. Game Interface (`table/skin.ini`)

`war3mapskin.txt` (the World Editor's Game Interface) lives in `table/skin.ini`. Sections and keys are the ones of `war3mapskin.txt`; each value is a plain string or a flat localized table:

```ini
[FrameDef]
BONUS_HITPOINTS = {
    " - 該能力每提高1點，會增加18點HP",
    enUS = " - Each point increases HP by 18",
    koKR = " - 능력치 1당 체력 18 증가",
}
UPKEEP_NONE = "|Cff00ff00My Map"
```

- Packing writes the default values to the neutral `war3mapskin.txt`, plus one complete `war3mapskin.txt` per LCID that appears in the table (untranslated keys fall back to the default). The game picks the variant of the client's locale, as it does for `war3map.wts`.
- A locale value equal to the default is dropped when unpacking. A key with locale values but no default (`{ enUS = "..." }`) is written only to those locales' files.
- Once `table/skin.ini` exists it is the only source and `map/war3mapskin.txt` is dropped. Projects without `table/skin.ini` keep reading `map/war3mapskin.txt`.

---

## Supported Locale Tags and LCID Mapping

| Locale Tag | Windows LCID | Description |
| :--- | :---: | :--- |
| `default` / `[1]` | `0x0000` | Neutral / Fallback |
| `zhTW` | `0x0404` | Traditional Chinese |
| `zhCN` | `0x0804` | Simplified Chinese |
| `enUS` | `0x0409` | English (United States) |
| `koKR` | `0x0412` | Korean |
| `jaJP` | `0x0411` | Japanese |
| `deDE` | `0x0407` | German |
| `frFR` | `0x040c` | French |
| `esES` | `0x0c0a` | Spanish |
| `ruRU` | `0x0419` | Russian |
| `plPL` | `0x0415` | Polish |
| `itIT` | `0x0410` | Italian |

---

## Conversion Modes

1. **`w2l obj <lni_dir> <out.w3x>`**:
   - Analyzes localized strings and allocates `TRIGSTR_xxx` tokens in binary object data (`war3map.w3a`, etc.) and `war3map.w3i`.
   - Creates a dedicated `war3map.wts` and `war3mapskin.txt` in the MPQ archive for each referenced LCID.
2. **`w2l slk <lni_dir> <out.w3x>`**:
   - Writes localized strings to MPQ localized `Units/*Strings.txt` files, `war3map.wts` and `war3mapskin.txt`.
   - Supports `-remove_we_only=false` to preserve `(listfile)` for round-trip unpacking.
3. **`w2l lni <in.w3x> <lni_dir>`**:
   - Inspects MPQ archive members across all LCIDs.
   - Merges localized strings into `table/*.ini` (the `war3mapskin.txt` variants into `table/skin.ini`) without exporting raw `locales/` directories.
