#!/usr/bin/env bash
#
# compress-images.sh
# 一鍵壓縮資料夾內的 PNG（可選 JPG）。可選三種引擎：
#   1) oxipng   —— 無損，畫質完全不變
#   2) pngquant —— 有損減色，檔案小很多（TinyPNG 同類，本機免費）
#   3) TinyPNG  —— 有損，用官方免費 API（每月 500 張）
#
# 用法：
#   ./compress-images.sh                # 互動模式，會問你資料夾與工具
#   ./compress-images.sh ./img ./out    # 指定 輸入資料夾 輸出資料夾
#
set -uo pipefail
shopt -s nullglob nocaseglob   # 沒對到檔案時不留下 *.png 字面；副檔名不分大小寫

# 結束前停住，避免雙擊執行時視窗瞬間關閉、看不到結果或錯誤
pause_exit(){ [[ -n "${NO_PAUSE:-}" ]] && return 0; echo; read -r -p "按 Enter 關閉視窗…" _ || true; }
trap pause_exit EXIT
trap 'err "發生錯誤（行號 ${LINENO}）。"' ERR

# ---------- 設定 ----------
# TinyPNG API key（每月 500 張免費）。由環境變數 TINIFY_KEY 提供，不要寫死在檔案裡。
# 也可改用環境變數 TINIFY_KEY 覆蓋。
TINIFY_KEY="${TINIFY_KEY:-}"

# ---------- 顏色 ----------
B="\033[1m"; G="\033[32m"; Y="\033[33m"; R="\033[31m"; C="\033[36m"; N="\033[0m"
say(){ printf "${C}%s${N}\n" "$1"; }
ok(){  printf "${G}%s${N}\n" "$1"; }
warn(){ printf "${Y}%s${N}\n" "$1"; }
err(){ printf "${R}%s${N}\n" "$1" >&2; }

# ---------- 環境自我檢查 ----------
check_brew(){
  if ! command -v brew >/dev/null 2>&1; then
    err "找不到 Homebrew。請先安裝：https://brew.sh"
    return 1
  fi
}

# ---------- 取得輸入資料夾 ----------
SRC="${1:-}"
if [[ -z "$SRC" ]]; then
  read -r -p "要壓縮的資料夾路徑（直接 Enter = 目前資料夾）: " SRC
  SRC="${SRC:-.}"
fi
if [[ ! -d "$SRC" ]]; then err "資料夾不存在：$SRC"; exit 1; fi
# 輸出固定為來源資料夾底下的 new 子資料夾
DST="${SRC%/}/new"
mkdir -p "$DST"

# ---------- 選工具 ----------
echo
echo -e "${B}請選擇壓縮工具：${N}"
echo "  1) oxipng    —— 無損（畫質 100% 不變，省的較少）"
echo "  2) pngquant  —— 有損減色（檔案小很多，肉眼幾乎看不出）"
echo "  3) TinyPNG   —— 有損，官方免費 API（每月 500 張）"
read -r -p "輸入 1 / 2 / 3： " CHOICE

# 統計用
human(){ awk -v b="$1" 'BEGIN{u="B";if(b>1024){b/=1024;u="KB"}if(b>1024){b/=1024;u="MB"}printf "%.1f%s",b,u}'; }
TOT_IN=0; TOT_OUT=0; CNT=0

process_done(){
  local f="$1" out="$2"
  local i o
  i=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
  o=$(stat -f%z "$out" 2>/dev/null || stat -c%s "$out")
  TOT_IN=$((TOT_IN+i)); TOT_OUT=$((TOT_OUT+o)); CNT=$((CNT+1))
  local pct=0
  [[ $i -gt 0 ]] && pct=$(awk -v i="$i" -v o="$o" 'BEGIN{printf "%.1f",(1-o/i)*100}')
  printf "  %-34s %8s -> %8s  (%5s%%)\n" "$(basename "$f")" "$(human $i)" "$(human $o)" "$pct"
}

case "$CHOICE" in
  1) # ---------- oxipng ----------
    if ! command -v oxipng >/dev/null 2>&1; then
      warn "尚未安裝 oxipng。"
      check_brew && { read -r -p "要現在用 brew 安裝嗎？(y/n) " a; [[ "$a" == "y" ]] && brew install oxipng || exit 1; }
    fi
    say "用 oxipng 無損壓縮中…"
    for f in "$SRC"/*.png; do
      [[ -e "$f" ]] || continue
      out="$DST/$(basename "$f")"
      oxipng -o max --strip safe -a "$f" --out "$out" >/dev/null 2>&1
      process_done "$f" "$out"
    done
    ;;

  2) # ---------- pngquant ----------
    if ! command -v pngquant >/dev/null 2>&1; then
      warn "尚未安裝 pngquant。"
      check_brew && { read -r -p "要現在用 brew 安裝嗎？(y/n) " a; [[ "$a" == "y" ]] && brew install pngquant || exit 1; }
    fi
    read -r -p "品質範圍（直接 Enter = 65-90，數字越高畫質越好檔案越大）: " Q
    Q="${Q:-65-90}"
    say "用 pngquant 壓縮中（品質 ${Q}）…"
    for f in "$SRC"/*.png; do
      [[ -e "$f" ]] || continue
      out="$DST/$(basename "$f")"
      # --skip-if-larger：若壓完反而更大就直接複製原檔，確保不會變大
      if pngquant --quality="$Q" --skip-if-larger --strip --force --output "$out" "$f" 2>/dev/null; then
        process_done "$f" "$out"
      else
        cp "$f" "$out"; process_done "$f" "$out"
      fi
    done
    ;;

  3) # ---------- TinyPNG API ----------
    if [[ -z "${TINIFY_KEY:-}" ]]; then
      warn "需要 TinyPNG API key。"
      echo "申請免費 key（每月 500 張）：https://tinypng.com/developers"
      read -r -p "貼上你的 API key： " TINIFY_KEY
      [[ -z "$TINIFY_KEY" ]] && { err "沒有 key，無法使用 TinyPNG。"; exit 1; }
    fi
    say "用 TinyPNG API 壓縮中…"
    for f in "$SRC"/*.png "$SRC"/*.jpg "$SRC"/*.jpeg; do
      [[ -e "$f" ]] || continue
      out="$DST/$(basename "$f")"
      url=$(curl -s -i --user "api:$TINIFY_KEY" --data-binary @"$f" \
            https://api.tinify.com/shrink | grep -i '^location:' | awk '{print $2}' | tr -d '\r')
      if [[ -n "$url" ]]; then
        curl -s --user "api:$TINIFY_KEY" "$url" -o "$out"
        process_done "$f" "$out"
      else
        err "  $(basename "$f") 失敗（可能額度用完或 key 錯誤）"
      fi
    done
    ;;

  *) err "無效選項。"; exit 1 ;;
esac

# ---------- 總結 ----------
echo "----------------------------------------------------------------------"
if [[ $CNT -gt 0 ]]; then
  PCT=$(awk -v i="$TOT_IN" -v o="$TOT_OUT" 'BEGIN{printf "%.1f",(1-o/i)*100}')
  ok "完成！共 $CNT 張：$(human $TOT_IN) -> $(human $TOT_OUT)（省 ${PCT}%）"
  echo "輸出位置：$DST"
else
  warn "沒有找到任何圖片。"
fi
