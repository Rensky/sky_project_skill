---
name: figma-campaign-slicing
description: 銀行活動頁(landing page)照 Figma 切版/改版的完整工作流程,適用富邦、永豐等各銀行客戶共用 boilerplate 的靜態 HTML + SCSS + Prepros 專案。以問答方式引導整個專案:開場收集 Figma 連結與素材、提出 section 拆分計畫、逐 section 實作、埋 meta、壓圖收尾。當使用者提到「切版」「改版」「活動頁」「landing page」「改 XX section」、貼 Figma 連結要求實作或修改頁面、丟 meta 資料表或追蹤碼文件要求埋設、或說「收尾」「定稿」「壓圖」時,務必使用此 skill,即使使用者沒有明講要照什麼流程。
---

# 銀行活動頁 Figma 切版流程(問答引導式)

## 總原則:用問的,不用猜的

整個流程靠問答推進,skill 主動帶流程、使用者回答與確認。寫 code 時遇到規格不明 —— 間距、斷點、互動行為、動畫細節、圖片對應、文字內容有出入 —— 一律先問使用者,不要自行腦補。寧可多問一句,不要改錯一輪重來。但問要有效率:一次問一件事或一組相關的事,不要一次丟十個問題轟炸。

## 前提(接手任何案子先知道這些)

- 專案是**複製同客戶舊案**而來的靜態 HTML + SCSS 專案:富邦的案子從富邦舊案複製、永豐從永豐複製,由使用者先 push 好 init 版。所以永遠有「舊碼」存在,流程建立在「改一個既有基底」之上。
- 用 **Prepros** 編譯(根目錄有 `prepros.config`,watch 存檔後 2-3 秒自動編譯)。專案裡可能殘留 `config.rb`,那是 Compass 時代的遺留,忽略它。
- 技術棧固定:jQuery + scrollreveal + animate.css,無打包工具、無框架。
- **git 由使用者自己管理**:不要主動 commit、push,也不要建議 commit 時機。
- 開工先載入 Figma 相關 skill(如 figma-design-to-code),用 Figma MCP 的 `get_design_context` 抓設計規格。

## Step 1:開場問答(依序問,拿齊才往下)

skill 一啟動就開始問,一題拿到答案再問下一題:

1. 「請提供 **desktop** 版的 Figma 連結(帶 node-id)」
2. 「請提供 **mobile** 版的 Figma 連結(帶 node-id)」
3. 「新的圖片素材是否都已放在 `images/new/`?(@2x)」—— 還沒的話,可提議用 `scripts/figma-export.sh` 從 Figma frame 批次匯出
4. 「Prepros dev server 的 port 是多少?」
5. 「Figma 留言(comment pin)裡的內容請貼給我 —— CTA 連結網址、動態需求通常寫在留言,MCP 讀不到留言」

meta 資料與追蹤碼是後期才會有的,這裡**不問**,不擋開工。

## Step 2:section 拆分計畫(動工前先對齊)

拿到兩條連結後,用 `get_design_context` / `get_metadata` 讀整頁結構,並對照舊專案 HTML 既有的 section,提出拆分計畫給使用者確認:

- 列表:預計拆成幾個 section、每個 section 的內容摘要(如 KV、方案卡片、試算、QA、注意事項)、對應的 Figma frame、對應的舊碼區塊(或標記「全新,無舊碼」)
- 每次設計不同,拆分沒有固定答案 —— 這張計畫表的目的就是讓使用者**確認或調整**拆法與順序,同時讓雙方知道總共要做幾輪
- 使用者確認計畫後才進 Step 3

## Step 3:逐 section 實作(核心循環)

照拆分計畫從第一個 section 開始,每個 section 跑同一輪;**做完一個、使用者看過瀏覽器說 OK,才進下一個**:

1. 用 `get_design_context` 抓這個 section 的 desktop + mobile 兩份規格。
2. 找到舊版對應的 HTML 區塊與 SCSS。
3. **列新舊差異表**給使用者確認:背景、字級、行距、layout、圖片、文字、URL,一項一列。
4. 使用者確認後才動手改。**確認前不寫任何 code** —— 差異表是讓使用者提前抓錯的機會,跳過它等於把錯誤成本往後搬。
5. 改法:舊 code 用註解包起來保留,新版另寫。SCSS 用 `/* === OLD: 說明 === */ ... /* === /OLD === */`,HTML 用 `<!-- === OLD === --> ... <!-- === /OLD === -->`。保留舊碼是為了反饋輪隨時回頭比對;全部 OLD 要等收尾階段才拔。
6. 存檔後等 Prepros 編譯(2-3 秒),用瀏覽器開 `http://localhost:<port>` 驗證。
7. 驗證方式(inspect 數值為主、截圖為輔):
   - 截圖與 Figma 同 frame 目視比對
   - `getComputedStyle` / `getBoundingClientRect` 對數值:background、font-size、line-height、寬高、位置
   - 每張圖 `naturalWidth > 0`(抓破圖)
   - 互動行為:收合、動畫、hover
   - 注意:scrollreveal 進場動畫中元素 rect 會縮到 0.9 倍,等約 2 秒動畫跑完再量;單張截圖也常拍到動畫進行中,以 inspect 數值為準。
8. 回報:改動摘要 + **憑自己判斷做的決定明確標出來**(照總原則,能問就先問,真的動手後才發現的判斷要標注)+ 請使用者看瀏覽器確認。

廠商後續的反饋輪(字級行距微調、動態調整)也走同一輪,不另開流程。

## Step 4:全部 section 完成後 → 問 meta 與追蹤碼

1. 問:「meta 資料有了嗎?Title / Keywords / OG Title / OG Image / OG Description / canonical(上線網址)」
   - 有 → 埋好;拿到上線網址時全案檢查 canonical、OG URL 與相對/絕對路徑
   - 還沒有 → 明確標記「**meta 待補**」,列入未完成清單,之後使用者丟來再埋
2. 問:「有沒有廠商要埋的追蹤碼?(txt / excel 文件)」
   - 有 → 解析文件,列「每段 code 埋在哪裡(head / body / 特定按鈕)」的對照表給使用者確認,**確認後才埋** —— 追蹤碼埋錯位置廠商端看不到數據,而且很難發現
   - 還沒有 → 標記「**追蹤碼待補**」

## Step 5:圖片壓縮與收尾

1. 問壓縮方式:「要用哪種壓縮?oxipng(無損)/ pngquant(有損減色,省最多)/ TinyPNG API(需環境變數 `TINIFY_KEY`)」。用 `scripts/compress-images.sh` 壓 `images/new/`,或直接下等效指令(如 `pngquant --quality=65-90 --skip-if-larger --strip`)。
2. 壓縮後的圖放進 `images/`,全案把 `images/new/` 路徑改成 `images/`。
3. 瀏覽器再驗一次所有圖 `naturalWidth > 0`。
4. 拔掉全部 OLD 註解區塊;刪掉沒用到的 js、圖檔(含被換掉的舊圖)、class。
5. 對照 Figma 整頁逐 section 掃一遍:有沒有漏改、CTA URL 是否對照 Figma 留言、meta 是否齊全、console 有沒有錯誤。
6. 回報:完成清單 + 待補清單(meta、追蹤碼若還沒給就列在這)。git 由使用者自己 commit。

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

## scripts/

- `compress-images.sh`:互動式圖片壓縮,三種引擎(oxipng / pngquant / TinyPNG),輸出到 `<來源資料夾>/new`。TinyPNG 需環境變數 `TINIFY_KEY`。
- `figma-export.sh`:把 Figma frame 裡的 asset 批次匯出成 PNG(1x/2x,可只抓有標 export 的圖層),需環境變數 `FIGMA_TOKEN`,匯完可接力壓縮。
- 兩支都是互動式腳本;由 Claude 執行時可以 pipe 答案進去(如 `echo "2" | bash compress-images.sh <dir>`),或改用上面提到的等效指令。
