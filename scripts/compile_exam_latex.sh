#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: compile_exam_latex.sh <tex_file> [--engine xelatex|pdflatex|lualatex] [--use-latexmk] [--preview] [--preview-dir DIR] [--clean]
EOF
}

detect_texbin() {
  if [[ -n "${TEXBIN:-}" && -d "${TEXBIN}" ]]; then
    echo "$TEXBIN"
    return
  fi

  local candidates=(
    "/Library/TeX/texbin"
    "/usr/local/texlive/2026/bin/universal-darwin"
    "/usr/local/texlive/2025/bin/universal-darwin"
    "/usr/local/texlive/2024/bin/universal-darwin"
    "$HOME/texlive/2026/bin/universal-darwin"
    "$HOME/texlive/2025/bin/universal-darwin"
    "$HOME/texlive/2024/bin/universal-darwin"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" ]]; then
      echo "$candidate"
      return
    fi
  done

  echo ""
}

pick_engine() {
  local tex_file="$1"
  if grep -Eq 'ctexart|ctexbook|xeCJK|fontspec|polyglossia' "$tex_file"; then
    echo "xelatex"
  elif grep -Eq 'luacode|luatextra' "$tex_file"; then
    echo "lualatex"
  else
    echo "pdflatex"
  fi
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TEX_FILE="${1/#\~/$HOME}"
shift

if [[ ! -f "$TEX_FILE" ]]; then
  echo "[ERROR] TeX file not found: $TEX_FILE" >&2
  exit 1
fi

ENGINE=""
USE_LATEXMK=0
PREVIEW=0
PREVIEW_DIR=""
CLEAN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)
      ENGINE="${2:-}"
      shift 2
      ;;
    --use-latexmk)
      USE_LATEXMK=1
      shift
      ;;
    --preview)
      PREVIEW=1
      shift
      ;;
    --preview-dir)
      PREVIEW_DIR="${2:-}"
      shift 2
      ;;
    --clean)
      CLEAN=1
      shift
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

TEXBIN_PATH="$(detect_texbin)"
if [[ -n "$TEXBIN_PATH" ]]; then
  export PATH="$TEXBIN_PATH:$PATH"
fi

ENGINE="${ENGINE:-$(pick_engine "$TEX_FILE")}"
TEX_DIR="$(cd "$(dirname "$TEX_FILE")" && pwd)"
TEX_NAME="$(basename "$TEX_FILE")"
BASE_NAME="${TEX_NAME%.tex}"

if [[ "$CLEAN" -eq 1 ]]; then
  rm -f "$TEX_DIR/$BASE_NAME".{aux,log,out,toc,lof,lot,fls,fdb_latexmk,synctex.gz,bbl,bcf,blg,run.xml,xdv}
  echo "[OK] Cleaned auxiliary files in $TEX_DIR"
  exit 0
fi

if ! command -v "$ENGINE" >/dev/null 2>&1; then
  echo "[ERROR] Cannot find LaTeX engine: $ENGINE" >&2
  echo "[HINT] Set TEXBIN to your TeX bin directory, e.g. export TEXBIN=/Library/TeX/texbin" >&2
  exit 1
fi

compile_manual() {
  (cd "$TEX_DIR" && "$ENGINE" -interaction=nonstopmode -halt-on-error "$TEX_NAME")
  (cd "$TEX_DIR" && "$ENGINE" -interaction=nonstopmode -halt-on-error "$TEX_NAME")
}

if [[ "$USE_LATEXMK" -eq 1 && "$(command -v latexmk >/dev/null 2>&1; echo $?)" -eq 0 ]]; then
  (cd "$TEX_DIR" && latexmk "-${ENGINE}" -interaction=nonstopmode -halt-on-error "$TEX_NAME")
else
  compile_manual
fi

PDF_FILE="$TEX_DIR/$BASE_NAME.pdf"
if [[ ! -f "$PDF_FILE" ]]; then
  echo "[ERROR] PDF not produced: $PDF_FILE" >&2
  exit 1
fi

if [[ "$PREVIEW" -eq 1 ]]; then
  PREVIEW_DIR="${PREVIEW_DIR:-$TEX_DIR/previews}"
  mkdir -p "$PREVIEW_DIR"
  if command -v pdftoppm >/dev/null 2>&1; then
    pdftoppm -png "$PDF_FILE" "$PREVIEW_DIR/$BASE_NAME" >/dev/null 2>&1
    echo "[OK] Preview images -> $PREVIEW_DIR"
  else
    echo "[WARN] pdftoppm not found, skipped preview generation" >&2
  fi
fi

echo "[OK] Engine: $ENGINE"
echo "[OK] PDF: $PDF_FILE"
