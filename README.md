# sky_project_skill — 銀行活動頁切版 Skill

把「照 Figma 切版/改版銀行活動頁」的完整流程做成 Claude skill,打包成 plugin。裝了之後,Claude 接手任何富邦/永豐等銀行活動頁專案,都會照同一套流程做:逐 section 實作、差異表先確認、OLD 註解保留舊碼、瀏覽器數值驗證、壓圖收尾。

## 安裝(團隊成員)

在 Claude Code 輸入:

```
/plugin marketplace add <GitHub帳號>/sky_project_skill
/plugin install figma-campaign-slicing@sky-project-skill
```

私有 repo 的話,你的 git 憑證要有這個 repo 的讀取權限。Cowork 桌面版也支援 plugin,在設定的 Plugins 加入同一個 marketplace 即可。

裝完不用背指令 —— 對 Claude 講「照 Figma 切版」「改版活動頁」「改 section2」就會自動進入流程。

## 前置需求

- **Figma MCP** 已連接(Claude 要用 `get_design_context` 抓設計規格)
- **Prepros** 開著 watch 專案(Claude 會等編譯後開 localhost 驗證)
- Claude 能開瀏覽器驗證(Claude 內建瀏覽器或 Chrome 擴充功能)
- 用到腳本時的環境變數(放 shell 設定檔或執行時帶入):
  - `FIGMA_TOKEN`:Figma personal access token(figma-export.sh 用)
  - `TINIFY_KEY`:TinyPNG API key(選 TinyPNG 引擎壓圖時才需要)

## 怎麼用

你的輸入永遠只有三種:**一句話 + Figma 連結**、**丟檔案**、**說收尾**。

### 情境 1:開新案

自己先做:複製同客戶最像的舊專案、push init。然後跟 Claude 說:

> 新案,富邦的,port 8848。desktop:<Figma URL>、mobile:<Figma URL>

Claude 會跟你要缺的東西(素材、Figma 留言內容),要齊了等你點第一個 section。

**注意:Figma 設計稿上的留言(CTA 網址、動態需求)Claude 讀不到,要自己複製貼給它。**

### 情境 2:改 section(最常用)

> 改 section2 <Figma 連結>

Claude 會:抓規格 → 列新舊差異表給你確認 → 你說 OK 才動手 → 舊碼包 OLD 註解 → 開瀏覽器驗證 → 回報改了什麼、哪裡是它自己判斷的。

廠商反饋輪一樣講:「section2 行距改 1.6」。

### 情境 3:丟文件

- 丟 meta 資料表 → Claude 埋 title/OG/canonical 後回報
- 丟追蹤碼文件(txt/excel)→ Claude 列「哪段埋哪裡」對照表給你確認,確認才埋

### 情境 4:收尾

> 收尾

Claude 會:問你壓縮引擎(無損/有損/TinyPNG)→ 壓 `images/new/` → 圖搬進 `images/` 並全案改路徑 → 驗證圖片都載入 → 拔光 OLD 註解、刪沒用到的檔案 → 對 Figma 整頁掃一遍找漏 → 回報清單。

git 全程自己 commit,Claude 不碰。

## Repo 結構

```
sky_project_skill/
├── .claude-plugin/marketplace.json      # marketplace 定義
├── plugins/figma-campaign-slicing/
│   ├── .claude-plugin/plugin.json       # plugin 定義
│   └── skills/figma-campaign-slicing/
│       ├── SKILL.md                     # 流程本體(慣例、踩坑、驗證方法都在這)
│       └── scripts/
│           ├── compress-images.sh       # 圖片壓縮(oxipng/pngquant/TinyPNG)
│           └── figma-export.sh          # Figma frame assets 批次匯出
└── README.md
```

## 更新 skill

改 `SKILL.md` → push → 團隊成員 `/plugin marketplace update sky-project-skill` 後重新安裝或更新 plugin 即可。

## 安全注意

腳本裡**不要**寫死任何金鑰(Figma token、TinyPNG key),一律走環境變數 —— repo 是共享的,寫死等於把你個人 Figma 全部檔案的讀取權交出去。
