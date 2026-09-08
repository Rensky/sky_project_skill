#!/usr/bin/env bash
#
# figma-export.sh
# 把一個 Figma frame 裡的每個 asset（子圖層）各自匯出成 PNG 並下載。
#
# 用法：
#   ./figma-export.sh                # 互動模式，貼上 frame 連結即可
#   FIGMA_TOKEN=xxx ./figma-export.sh
#
set -uo pipefail
shopt -s nullglob nocaseglob

# 結束前停住，避免雙擊執行時視窗瞬間關閉
pause_exit(){ echo; read -r -p "按 Enter 關閉視窗…" _ || true; }
trap pause_exit EXIT
trap 'err "發生錯誤（行號 ${LINENO}）。"' ERR

B="\033[1m"; G="\033[32m"; Y="\033[33m"; R="\033[31m"; C="\033[36m"; N="\033[0m"
say(){ printf "${C}%s${N}\n" "$1"; }
ok(){  printf "${G}%s${N}\n" "$1"; }
warn(){ printf "${Y}%s${N}\n" "$1"; }
err(){ printf "${R}%s${N}\n" "$1" >&2; }

# ---------- 相依檢查：jq、curl ----------
if ! command -v curl >/dev/null 2>&1; then err "找不到 curl。"; exit 1; fi
if ! command -v jq >/dev/null 2>&1; then
  warn "需要 jq 來解析 Figma 回傳的 JSON。"
  if command -v brew >/dev/null 2>&1; then
    read -r -p "要現在用 brew 安裝 jq 嗎？(y/n) " a
    [[ "$a" == "y" ]] && brew install jq || { err "沒有 jq 無法繼續。"; exit 1; }
  else
    err "請先安裝 jq（https://jqlang.github.io/jq/）。"; exit 1
  fi
fi

# ---------- Token ----------
# Token 由環境變數 FIGMA_TOKEN 提供，不要寫死在檔案裡。
FIGMA_TOKEN="${FIGMA_TOKEN:-}"
if [[ -z "$FIGMA_TOKEN" ]]; then
  echo "取得 token：Figma → 頭像 → Settings → Security → Personal access tokens"
  read -r -p "貼上你的 Figma token： " FIGMA_TOKEN
  [[ -z "$FIGMA_TOKEN" ]] && { err "沒有 token。"; exit 1; }
fi

# ---------- 貼 frame 連結，解析 key 與 node-id ----------
echo "在 Figma 對 frame 按右鍵 → Copy link to selection，貼到這裡："
read -r -p "Frame 連結： " URL
KEY=$(printf '%s' "$URL" | sed -E 's#.*/(design|file)/([^/?]+).*#\2#')
NODE=$(printf '%s' "$URL" | sed -E 's#.*[?&]node-id=([0-9]+-[0-9]+).*#\1#' | tr '-' ':')
if [[ -z "$KEY" || -z "$NODE" || "$KEY" == "$URL" ]]; then
  err "無法從連結解析出 file key / node-id。請確認是用『Copy link to selection』複製的連結。"
  exit 1
fi
say "檔案 key：$KEY    frame node：$NODE"

TS=$(date +%Y%m%d-%H%M%S)
read -r -p "輸出資料夾（直接 Enter = ~/Downloads/figma-export-${TS}）: " DST
DST="${DST:-$HOME/Downloads/figma-export-$TS}"
mkdir -p "$DST"
echo
echo -e "${B}選擇匯出倍率：${N}"
echo "  1) 1x（原尺寸）"
echo "  2) 2x（兩倍，較清晰）"
read -r -p "輸入 1 / 2（直接 Enter = 2）： " S
case "$S" in
  1) SCALE=1 ;;
  ""|2) SCALE=2 ;;
  *) warn "無效選項，改用 2x。"; SCALE=2 ;;
esac
say "使用 ${SCALE}x 匯出。"

echo
echo -e "${B}要匯出哪些圖層？${N}"
echo "  1) 只匯出 Figma 有標記匯出的圖層（跟右側 Export 面板一致）"
echo "  2) 所有含圖片的圖層（image fill，連設計零件都抓）"
read -r -p "輸入 1 / 2（直接 Enter = 1）： " MODE
MODE="${MODE:-1}"

API="https://api.figma.com"
auth=(-H "X-Figma-Token: $FIGMA_TOKEN")

# ---------- 取得 frame 的子節點（assets）----------
say "讀取 frame 結構…"
NODES_JSON=$(curl -s "${auth[@]}" "$API/v1/files/$KEY/nodes?ids=$NODE")
if echo "$NODES_JSON" | jq -e '.err // .status >= 400' >/dev/null 2>&1; then
  err "Figma API 回傳錯誤：$(echo "$NODES_JSON" | jq -r '.err // .message // .')"; exit 1
fi

# 遞迴走訪整個 frame，依模式挑出要匯出的圖層
WALK='def walk: ., (.children[]? | walk);'
if [[ "$MODE" == "2" ]]; then
  # 模式 2：所有含圖片填充（image fill）的圖層
  mapfile -t CHILDREN < <(echo "$NODES_JSON" | jq -r --arg n "$NODE" \
    "$WALK"' .nodes[$n].document | walk | select((.fills // []) | any(.type=="IMAGE")) | "\(.id)\t\(.name)"')
else
  # 模式 1（預設）：只抓有設定匯出（export settings）的圖層 = 跟 Figma Export 面板一致
  mapfile -t CHILDREN < <(echo "$NODES_JSON" | jq -r --arg n "$NODE" \
    "$WALK"' .nodes[$n].document | walk | select((.exportSettings // []) | length > 0) | "\(.id)\t\(.name)"')
  if [[ ${#CHILDREN[@]} -eq 0 ]]; then
    warn "找不到有標記匯出的圖層，改抓所有含圖片填充的圖層…"
    mapfile -t CHILDREN < <(echo "$NODES_JSON" | jq -r --arg n "$NODE" \
      "$WALK"' .nodes[$n].document | walk | select((.fills // []) | any(.type=="IMAGE")) | "\(.id)\t\(.name)"')
  fi
fi
if [[ ${#CHILDREN[@]} -eq 0 ]]; then
  err "這個 frame 底下找不到可匯出的圖層，或 node-id 不對。"; exit 1
fi
ok "找到 ${#CHILDREN[@]} 個圖層。"

# 組出 ids 字串（給 /v1/images 一次算完）
IDS=""
declare -A NAME_OF
for line in "${CHILDREN[@]}"; do
  id="${line%%$'\t'*}"; name="${line#*$'\t'}"
  NAME_OF["$id"]="$name"
  IDS="${IDS:+$IDS,}$id"
done

# ---------- 要圖片網址 ----------
say "請 Figma 算圖中…"
IMG_JSON=$(curl -s "${auth[@]}" "$API/v1/images/$KEY?ids=$IDS&format=png&scale=$SCALE")
if echo "$IMG_JSON" | jq -e '.err' >/dev/null 2>&1 && [[ "$(echo "$IMG_JSON" | jq -r '.err')" != "null" ]]; then
  err "算圖失敗：$(echo "$IMG_JSON" | jq -r '.err')"; exit 1
fi

# ---------- 下載 ----------
sanitize(){ printf '%s' "$1" | tr '/\\:*?"<>|' '_________' | sed 's/[[:space:]]\+/_/g'; }
CNT=0; FAIL=0; declare -A USED
while IFS=$'\t' read -r id url; do
  [[ -z "$id" ]] && continue
  raw="${NAME_OF[$id]:-$id}"
  base="$(sanitize "$raw")"; base="${base:-$id}"
  fn="$base"; i=2
  while [[ -n "${USED[$fn]:-}" ]]; do fn="${base}_${i}"; ((i++)); done
  USED["$fn"]=1
  if [[ "$url" == "null" || -z "$url" ]]; then
    warn "  跳過 ${raw}（Figma 沒有回傳圖片，可能是空圖層）"; FAIL=$((FAIL+1)); continue
  fi
  if curl -s -L "$url" -o "$DST/$fn.png"; then
    printf "  ✓ %s.png\n" "$fn"; CNT=$((CNT+1))
  else
    warn "  下載失敗：$raw"; FAIL=$((FAIL+1))
  fi
done < <(echo "$IMG_JSON" | jq -r '.images | to_entries[] | "\(.key)\t\(.value)"')

echo "----------------------------------------------------------------------"
ok "完成！下載 $CNT 張，失敗/跳過 $FAIL 張。"
echo "輸出位置：$DST"

# ---------- 接力：問要不要壓縮 ----------
if [[ $CNT -gt 0 ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  COMPRESS="$SCRIPT_DIR/compress-images.sh"
  echo
  read -r -p "要接著壓縮剛剛下載的圖片嗎？(y/n) " DOC
  if [[ "$DOC" == "y" ]]; then
    if [[ -f "$COMPRESS" ]]; then
      # 交給壓縮腳本處理；它會問你方式並在 ${DST}/new 產生結果
      NO_PAUSE=1 bash "$COMPRESS" "$DST"
    else
      warn "找不到 compress-images.sh（預期在 $COMPRESS），略過壓縮。"
    fi
  fi
fi
