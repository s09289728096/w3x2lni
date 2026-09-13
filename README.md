# W3x2Lni

[![Build Status](https://github.com/sumneko/w3x2lni/workflows/build/badge.svg)](https://github.com/sumneko/w3x2lni/actions?workflow=build)

* [文档](https://sumneko.github.io/w3x2lni/#/zh-cn/)
* [English Documents](https://sumneko.github.io/w3x2lni/#/en-us/)

## 多語系 (Multi-Locale / i18n) 支援

w3x2lni 支援魔獸爭霸 3 地圖的全方位多語系架構，秉持 **「LNI 即單一真理來源 (Single Source of Truth)」** 的設計：
- **專案結構乾淨統一**：所有語系翻譯直接於 `table/*.ini` 與 `table/w3i.ini` 編輯，專案目錄下**完全不產生或依賴任何 `locales/` 目錄或 SLK 碎片**。
- **自動產出 MPQ 多語系結構**：轉為 OBJ 地圖時，自動生成各語系 LCID 的 `war3map.wts` 並配發 `TRIGSTR_`；轉為 SLK 地圖時，自動為各語系產出專屬的 `Units/*Strings.txt` 與 `war3map.wts`。
- **支援無損雙向轉換**：支援 `LNI <-> OBJ` 與 `LNI <-> SLK` 雙向 round-trip，語系資料不失真。

### 1. 語法教學 (Syntax Guide)

#### (1) 單一字串欄位（扁平多語系表格）
適用於物件名稱（`Name`）、單位說明、`table/w3i.ini` 地圖資訊等非重複欄位：

```ini
[AHtb]
_parent = "AHtb"
Name = {
    "風暴之錘",                     -- 預設字串 (Neutral / 0x0000)
    enUS = "Storm Bolt",           -- 英文 (enUS / 0x0409)
    koKR = "폭풍의 망치",           -- 韓文 (koKR / 0x0412)
    zhTW = "風暴之錘",             -- 繁體中文 (zhTW / 0x0404)
}
```

#### (2) 多等級技能字串欄位（語系陣列 Locale-First Array）
適用於技能 `Tip`、`Ubertip`、`Researchubertip` 等隨等級變化的重複欄位。以語系標籤為鍵，每個語系下展開對應各等級文字的陣列，便於翻譯人員成組對照與擴充：

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

多行長文本可搭配 Lua 的 `[=[ ... ]=]` 語法：

```ini
Ubertip = {
    {
        [=[
向目標投擲魔法戰錘，造成傷害並使其眩暈。|n|n|cffffcc00等級 1|r - 100點傷害
]=],
        [=[
向目標投擲魔法戰錘，造成傷害並使其眩暈。|n|n|cffffcc00等級 2|r - 200點傷害
]=],
    },
    enUS = {
        [=[
Throws a magical hammer that damages and stuns the target.|n|n|cffffcc00Level 1|r - 100 damage
]=],
        [=[
Throws a magical hammer that damages and stuns the target.|n|n|cffffcc00Level 2|r - 200 damage
]=],
    },
}
```

#### (3) 地圖資訊 (`table/w3i.ini`)
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

### 2. 支援的語系標籤 (Supported Locale Tags)

| 語系標籤 (Tag) | Windows LCID | 語系說明 |
| :--- | :---: | :--- |
| *(預設第一項 / default)* | `0x0000` | 通用中立回退 (Neutral Fallback) |
| `zhTW` | `0x0404` | 繁體中文 (Traditional Chinese) |
| `zhCN` | `0x0804` | 簡體中文 (Simplified Chinese) |
| `enUS` | `0x0409` | 英文 (English - United States) |
| `koKR` | `0x0412` | 韓文 (Korean) |
| `jaJP` | `0x0411` | 日文 (Japanese) |
| `deDE` | `0x0407` | 德文 (German) |
| `frFR` | `0x040c` | 法文 (French) |
| `esES` | `0x0c0a` | 西班牙文 (Spanish) |
| `ruRU` | `0x0419` | 俄文 (Russian) |
| `plPL` | `0x0415` | 波蘭文 (Polish) |
| `itIT` | `0x0410` | 義大利文 (Italian) |

### 3. 打包與轉換運作機制

- **LNI 模式 (`w2l lni`)**：
  不論輸入地圖為 OBJ 或 SLK 格式，皆動態比對所有語系分區（`war3map.wts`、`Units/*Strings.txt`），將差異直接整合為 LNI 語系表格。**LNI 專案目錄下完全不建立 `locales/` 資料夾**。
- **OBJ 模式 (`w2l obj`)**：
  為所有帶語系差異的字串分配 `TRIGSTR_xxx`，並於輸出的 MPQ 中為各語系建立專屬的 `war3map.wts`（分別指定對應的 LCID）。
- **SLK 模式 (`w2l slk`)**：
  將語系字串分別寫入各 LCID 的 `Units/*Strings.txt` 與 `war3map.wts`。若欲保留 `(listfile)` 便於後續轉回 LNI，可加上 `-remove_we_only=false`。
- **單語系相容性**：
  未標註語系的純字串完全相容於既有行為，既有地圖無損轉換。

## TODO

* 等级数据的压缩
* 地形文件
* 管理模型文件
* 自动生成暗图标
* 转换doo, w3s, w3r等文件
* 新UI
* 完善文档
