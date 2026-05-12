#!/usr/bin/env bash
# Compila poster.tex ou fazzle_apresentacao.tex a partir do diretório deste script.
# Uso: ./compile.sh          → poster.tex (padrão)
#      ./compile.sh poster   → poster.tex
#      ./compile.sh fazzle   → fazzle_apresentacao.tex (2+ passes LaTeX, sem BibTeX)
# — Dois passes de pdfLaTeX quando não há BibTeX no meio (cross-refs, outlines).
# — Com poster.bib: BibTeX após o 1.º passe e um terceiro pdfLaTeX para estabilizar
#   referências (prática habitual: LaTeX → BibTeX → LaTeX → LaTeX).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TARGET="${1:-poster}"
case "$TARGET" in
  poster)
    readonly TEXFILE="poster.tex"
    readonly JOB="poster"
    ;;
  fazzle)
    readonly TEXFILE="fazzle_apresentacao.tex"
    readonly JOB="fazzle_apresentacao"
    ;;
  *)
    echo "Uso: $0 [poster|fazzle]" >&2
    exit 2
    ;;
esac

readonly LATEX="${LATEX:-pdflatex}"
readonly LATEX_FLAGS=(-interaction=nonstopmode -file-line-error -halt-on-error)

run_latex() {
  "$LATEX" "${LATEX_FLAGS[@]}" "$TEXFILE"
}

run_bibtex() {
  local status=0
  set +e
  bibtex "$JOB"
  status=$?
  set -e
  if [[ "$status" -ne 0 && "$status" -ne 2 ]]; then
    return "$status"
  fi
  return 0
}

need_third_pass=false

run_latex

if [[ "$TARGET" == "poster" ]] && [[ -f "${JOB}.bib" && -f "${JOB}.aux" ]] && grep -q '\\bibdata{' "${JOB}.aux"; then
  run_bibtex
  need_third_pass=true
fi

run_latex

if [[ "$need_third_pass" == true ]]; then
  run_latex
fi

echo "Concluído: ${SCRIPT_DIR}/${JOB}.pdf"
