# sky_project_skill — 銀行活動頁切版 Skill

把「照 Figma 切版/改版銀行活動頁」的完整流程做成 Claude skill,打包成 plugin。裝了之後,Claude 接手任何富邦/永豐等銀行活動頁專案,都會照同一套流程做:問答引導開工、逐 section 實作、差異表先確認、OLD 註解保留舊碼、瀏覽器數值驗證、壓圖收尾。

## 安裝(團隊成員)

在 Claude Code 輸入:

```
/plugin marketplace add Rensky/sky_project_skill
/plugin install super-sky@sky-project-skill
```

(repo 是 private 的話,你的 git 憑證要有這個 repo 的讀取權限。也可以先 `git clone` 下來,再 `/plugin marketplace add <本機路徑>` 安裝,效果相同,但更新要自己 pull。)

裝完後輸入 `/super-sky` 直接啟動流程;或自然地講「照 Figma 切版」「改版活動頁」也會自動觸發。

## 前置需求

- **Figma MCP** 已連接(Claude 要用 `get_design_context` 抓設計規格)
- **Prepros** 開著 watch 專案(Claude 會等編譯後開 localhost 驗證)
- Claude 能開瀏覽器驗證(Claude 內建瀏覽器或 Chrome 擴充功能)
- 用到腳本時的環境變數(放 shell 設定檔或執行時帶入):
  - `FIGMA_TOKEN`:Figma personal access token(figma-export.sh 用)
  - `TINIFY_KEY`:TinyPNG API key(選 TinyPNG 引擎壓圖時才需要)

## 怎麼用

整個流程是**問答引導式**的:skill 主動問、你回答,規格不明時 Claude 會問你而不是自己猜。

開工前自己先做:複製同客戶最像的舊專案、push 一版 init。

之後啟動 skill(講「照 Figma 切版」或 `/figma-campaign-slicing`),流程會這樣走:

1. **開場問答** —— Claude 依序問你:
   - desktop 版 Figma 連結(帶 node-id)
   - mobile 版 Figma 連結(帶 node-id)
   - 新圖是否已放 `images/new/`(還沒的話它可以用腳本從 Figma 匯)
   - Prepros dev server 的 port
   - Figma 留言內容(CTA 網址、動態需求 —— MCP 讀不到留言,要自己貼)

2. **section 拆分計畫** —— Claude 讀完整頁設計後,列出「預計拆成幾個 section、每個做什麼、對應哪段舊碼」給你確認。每次設計不同,拆法你說了算,確認後才開工。

3. **逐 section 實作** —— 每個 section:抓規格 → 列新舊差異表給你確認 → 你說 OK 才動手(舊碼包 OLD 註解)→ 瀏覽器驗證 → 回報。你看過沒問題,才做下一個 section。廠商反饋輪(「section2 行距改 1.6」)也走同一輪。

4. **meta 與追蹤碼** —— 全部 section 做完,Claude 會問你 title/OG/canonical 那些有沒有;還沒有就標記「待補」不擋流程。追蹤碼文件(txt/excel)丟給它,它會列「哪段埋哪裡」對照表,你確認才埋。

5. **壓圖收尾** —— Claude 問你壓縮方式(無損 oxipng / 有損 pngquant / TinyPNG API)→ 壓 `images/new/` → 圖搬進 `images/` 並全案改路徑 → 拔光 OLD、刪沒用到的檔案 → 對 Figma 整頁掃漏 → 回報完成清單 + 待補清單。

git 全程自己 commit,Claude 不碰。

## Repo 結構

```
sky_project_skill/
├── .claude-plugin/marketplace.json      # marketplace 定義
├── plugins/super-sky/
│   ├── .claude-plugin/plugin.json       # plugin 定義
│   └── skills/super-sky/
│       ├── SKILL.md                     # 流程本體(慣例、踩坑、驗證方法都在這)
│       └── scripts/
│           ├── compress-images.sh       # 圖片壓縮(oxipng/pngquant/TinyPNG)
│           └── figma-export.sh          # Figma frame assets 批次匯出
└── README.md
```

## 更新 skill

改 `SKILL.md` → push → 團隊成員 `/plugin marketplace update sky-project-skill` 後更新 plugin 即可。

## 安全注意

腳本裡**不要**寫死任何金鑰(Figma token、TinyPNG key),一律走環境變數 —— repo 是共享的,寫死等於把你個人 Figma 全部檔案的讀取權交出去。
