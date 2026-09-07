---
name: figma-campaign-slicing
description: 銀行活動頁(landing page)照 Figma 切版/改版的完整工作流程,適用富邦、永豐等各銀行客戶共用 boilerplate 的靜態 HTML + SCSS + Prepros 專案。當使用者提到「切版」「改版」「活動頁」「landing page」「改 XX section」、貼 Figma 連結要求實作或修改頁面、丟 meta 資料表或追蹤碼文件要求埋設、或說「收尾」「定稿」「壓圖」時,務必使用此 skill,即使使用者沒有明講要照什麼流程。
---

# 銀行活動頁 Figma 切版流程

## 前提(接手任何案子先知道這些)

- 專案是**複製同客戶舊案**而來的靜態 HTML + SCSS 專案:富邦的案子從富邦舊案複製、永豐從永豐複製。所以永遠有「舊碼」存在,流程建立在「改一個既有基底」之上。
- 用 **Prepros** 編譯(根目錄有 `prepros.config`,watch 存檔後 2-3 秒自動編譯)。專案裡可能殘留 `config.rb`,那是 Compass 時代的遺留,忽略它。
- 技術棧固定:jQuery + scrollreveal + animate.css,無打包工具、無框架。
- **git 由使用者自己管理**:不要主動 commit、push,也不要建議 commit 時機。
- 開工先載入 Figma 相關 skill(如 figma-design-to-code),用 Figma MCP 的 `get_design_context` 抓設計規格。

## 開工收料(缺什麼就主動要,不要自己猜)

- Desktop + Mobile **兩條** Figma URL(帶 node-id)。兩個版型分開驗,不能只看 desktop。
- 新素材:放在 `images/new/`(@2x 圖)。若使用者還沒匯出,可用 `scripts/figma-export.sh` 從 frame 批次匯出。
- **Figma 留言(comment pin)內容**:CTA 連結網址、動態需求通常寫在設計稿留言裡,MCP 讀不到留言,一定要請使用者貼過來。
- Prepros dev server 的 port(每台機器設定不同)。
- meta 資料表與追蹤碼文件是後期才會給的,不用等,先開工。

## 核心循環:一次只改一個 section

這是整個 skill 的主流程。使用者說「改 XX section」+ Figma 連結,就跑這一輪:

1. 用 `get_design_context` 抓 desktop + mobile 兩份規格。
2. 找到舊版對應的 HTML 區塊與 SCSS。
3. **列新舊差異表**給使用者確認:背景、字級、行距、layout、圖片、文字、URL,一項一列。
4. 使用者確認後才動手改。**確認前不寫任何 code** —— 差異表是讓使用者提前抓錯的機會,跳過它等於把錯誤成本往後搬。
5. 改法:舊 code 用註解包起來保留,新版另寫。SCSS 用 `/* === OLD: 說明 === */ ... /* === /OLD === */`,HTML 用 `<!-- === OLD === --> ... <!-- === /OLD === -->`。保留舊碼是為了廠商反饋輪隨時要回頭比對;全部 OLD 要等收尾階段才拔。
6. 存檔後等 Prepros 編譯(2-3 秒),用瀏覽器開 `http://localhost:<port>` 驗證。
7. 驗證方式(inspect 數值為主、截圖為輔):
   - 截圖與 Figma 同 frame 目視比對
   - `getComputedStyle` / `getBoundingClientRect` 對數值:background、font-size、line-height、寬高、位置
   - 每張圖 `naturalWidth > 0`(抓破圖)
   - 互動行為:收合、動畫、hover
   - 注意:scrollreveal 進場動畫中元素 rect 會縮到 0.9 倍,等約 2 秒動畫跑完再量;單張截圖也常拍到動畫進行中,以 inspect 數值為準。
8. 回報:改動摘要 + **憑自己判斷做的決定明確標出來** + 請使用者看瀏覽器確認。

廠商後續的反饋輪(字級行距微調、動態調整)也走同一輪,不另開流程。

## SCSS / 專案慣例速查

- 字級直接寫 px、顏色直接寫 hex,**不用**變數或 mixin 包裝。
- 絕對定位換算成 %:`layoutCustom($px, $base)` 算寬度、`layoutPos($px, $base, 'left'|'top')` 算位置。基準:desktop 1440、mobile 375。Figma 上水平置中的元素,換算成 left px 用 layoutPos,不要用 translateX。
- 無背景圖的滿版 section 用 `&::before { padding-top: (高/寬)*100% }` 撐比例。
- RWD 斷點預設 `rwd_down(500)`($mobile-size),個別 section 視內容改用 768 或 1080。
- 命名:section 用 `.section-xxx`;圖檔小寫底線(`section1_btn.png`),mobile 版圖檔 `_m` 後綴,放 `images/mobile/`。
- scrollreveal hook 前綴**沿用該專案既有寫法**:有的案子用 `js-a-<section名>-<n>`,有的用 `js-a-0-` 數字前綴搭配 `setScrollReveal(classPrefix, ...)` helper。動手前先看 index.html 底部既有的註冊方式,照著加。
- 重複出現的元件(如 pill 按鈕)抽共用 class,不要每個 section 複製樣式。

## 踩坑 checklist(動手前後各過一遍)

1. 動工前先 grep 全域 class(`.section-title`、`.section` 的 padding 等)有沒有會污染新 section 的樣式 —— 有的案子全域 .section-title 帶 max-width 500、顏色、裝飾線甚至 debug 紅框。新 section 一律覆寫確認,不假設全域是乾淨的。
2. 覆寫 `.section` padding 時保留左右 20px,否則手機版內容貼邊。
3. 並排卡片要對齊:容器 `align-items: stretch` + 按鈕 `margin-top: auto`,文案行數不同時按鈕才會齊底。
4. **固定寬元件決定 RWD 斷點**:先算最小 row 寬(固定寬總和 + gap + padding),斷點取在那之上。不能無腦沿用 768 —— 內容在斷點前就會爆版。
5. `<object>` 嵌 SVG:SVG 只有 viewBox 沒有 width/height 時,要給 CSS `aspect-ratio`,並準備 PNG fallback。
6. keyframe 要做呼吸/來回效果必加 `alternate`;「一直循環不停頓」= from/to 兩格 + `ease-in-out` + `alternate`,不要留靜止的百分比段。
7. 手機按鈕等比縮放需求(如縮 90%):寬、高、字級、圓角、箭頭全部等比算 px,寫在共用 class 的 `rwd_down` 裡一次生效,不要一顆一顆改。

## 收尾動作(事件驅動:使用者丟什麼就做什麼,沒有固定順序)

### 使用者丟 meta 資料表
埋 Title / Keywords / OG Title / OG Image / OG Description / canonical。拿到正式上線網址時,全案檢查 canonical、OG URL 與相對/絕對路徑是否一致。

### 使用者丟追蹤碼文件(txt 或 excel,格式每次不同)
先解析文件,列一張「每段 code 埋在哪裡(head / body / 特定按鈕的 onclick)」的對照表給使用者確認,**確認後才埋**。追蹤碼埋錯位置廠商端看不到數據,而且很難發現,所以這裡必須先對表。

### 使用者說「收尾」「定稿」
1. 問使用者壓縮引擎要用哪個:oxipng(無損)/ pngquant(有損減色,省最多)/ TinyPNG API(需 `TINIFY_KEY`)。用 `scripts/compress-images.sh` 壓 `images/new/`,或直接下等效指令(如 `pngquant --quality=65-90 --skip-if-larger --strip`)。
2. 壓縮後的圖放進 `images/`,全案把 `images/new/` 路徑改成 `images/`。
3. 瀏覽器再驗一次所有圖 `naturalWidth > 0`。
4. 拔掉全部 OLD 註解區塊;刪掉沒用到的 js、圖檔(含被換掉的舊圖)、class。
5. 對照 Figma 整頁逐 section 掃一遍:有沒有漏改、CTA URL 是否對照 Figma 留言、meta 是否齊全、console 有沒有錯誤。
6. 回報清理與掃描結果清單。git 由使用者自己 commit。

## scripts/

- `compress-images.sh`:互動式圖片壓縮,三種引擎(oxipng / pngquant / TinyPNG),輸出到 `<來源資料夾>/new`。TinyPNG 需環境變數 `TINIFY_KEY`。
- `figma-export.sh`:把 Figma frame 裡的 asset 批次匯出成 PNG(1x/2x,可只抓有標 export 的圖層),需環境變數 `FIGMA_TOKEN`,匯完可接力壓縮。
- 兩支都是互動式腳本;由 Claude 執行時可以 pipe 答案進去(如 `echo "2" | bash compress-images.sh <dir>`),或改用上面提到的等效指令。
