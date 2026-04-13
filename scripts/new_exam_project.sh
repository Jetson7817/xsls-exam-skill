#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: new_exam_project.sh <project_dir>" >&2
  exit 1
fi

PROJECT_DIR="${1/#\~/$HOME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$SKILL_DIR/assets/templates"

mkdir -p "$PROJECT_DIR/source" "$PROJECT_DIR/build"
cp "$TEMPLATE_DIR/exam-paper.tex" "$PROJECT_DIR/main.tex"
cp "$TEMPLATE_DIR/pagination-plan.md" "$PROJECT_DIR/pagination-plan.md"
cp "$TEMPLATE_DIR/review.md" "$PROJECT_DIR/review.md"

echo "[OK] Created XSLS exam project: $PROJECT_DIR"
echo "[OK] main.tex -> $PROJECT_DIR/main.tex"
echo "[OK] pagination-plan.md -> $PROJECT_DIR/pagination-plan.md"
echo "[OK] review.md -> $PROJECT_DIR/review.md"
