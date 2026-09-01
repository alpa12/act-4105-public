#!/usr/bin/env bash
set -euo pipefail

pdf_dir="${1:-${EXERCICES_PDF_DIR:-site/vieux-materiel/exercices}}"

chapters=(
  "1:site/chapitres/01-introduction/exercices.qmd:chap1-exercices.pdf:9"
  "2:site/chapitres/02-principes-tarif-cas/exercices.qmd:chap2-exercices.pdf:3"
  "3:site/chapitres/03-donnees/exercices.qmd:chap3-exercices.pdf:3"
  "4:site/chapitres/04-base-exposition/exercices.qmd:chap4-exercices.pdf:10"
  "5:site/chapitres/05-primes/exercices.qmd:chap5-exercices.pdf:12"
  "6:site/chapitres/06-sinistres/exercices.qmd:chap6-exercices.pdf:13"
  "7:site/chapitres/07-autres-frais-et-profit/exercices.qmd:chap7-exercices.pdf:4"
  "8:site/chapitres/08-indique-global/exercices.qmd:chap8-exercices.pdf:3"
  "9:site/chapitres/09-classification-traditionnelle-des-risques/exercices.qmd:chap9-exercices.pdf:10"
)

count_top_level_questions() {
  awk '
    /^:{3,}[[:space:]]+\{\.question\}[[:space:]]*$/ {
      if (depth == 0) count++
      depth++
      next
    }
    /^:{3,}[[:space:]]+\{\.solution\}[[:space:]]*$/ {
      depth++
      next
    }
    /^:{3,}[[:space:]]*$/ {
      if (depth > 0) depth--
      next
    }
    END { print count + 0 }
  ' "$1"
}

count_blocks() {
  local block="$1"
  local file="$2"
  grep -Ec "^:{3,}[[:space:]]+\\{\\.${block}\\}[[:space:]]*$" "$file" || true
}

status=0

echo "PDF directory: ${pdf_dir}"
echo

for chapter in "${chapters[@]}"; do
  IFS=":" read -r number qmd pdf_name expected_questions <<< "$chapter"
  pdf_path="${pdf_dir}/${pdf_name}"

  echo "Chapter ${number}: ${qmd}"

  if [[ ! -f "$qmd" ]]; then
    echo "  ERROR: missing QMD file"
    status=1
    continue
  fi

  if [[ ! -f "$pdf_path" ]]; then
    echo "  ERROR: missing PDF source: ${pdf_path}"
    status=1
  fi

  if ! sed -n '1,4p' "$qmd" | grep -q "metadata-files:" ||
     ! sed -n '1,4p' "$qmd" | grep -q "../_exercices.yml"; then
    echo "  ERROR: missing required exercise YAML header"
    status=1
  fi

  top_level_questions="$(count_top_level_questions "$qmd")"
  solution_blocks="$(count_blocks solution "$qmd")"
  grading_blocks="$(count_blocks grading "$qmd")"

  echo "  top-level questions: ${top_level_questions} (expected ${expected_questions})"
  echo "  solution blocks: ${solution_blocks}"

  if [[ "$top_level_questions" != "$expected_questions" ]]; then
    echo "  ERROR: top-level question count does not match expected count"
    status=1
  fi

  if [[ "$grading_blocks" != "0" ]]; then
    echo "  ERROR: .grading blocks are not used during PDF conversion"
    status=1
  fi

  if grep -Eq "Exercices Chapitre|Solutions Chapitre|Tarification en assurance IARD|ACT-4105|ACT-6006" "$qmd"; then
    echo "  ERROR: PDF title/header/footer text appears to remain in QMD"
    status=1
  fi

  if grep -Eq "Calculé|est a lieu|polices écrite([^s]|$)|celle permet|couteuse|choix suivant([^s]|$)|est nouveau|police annuelles|commencé à écrite|en court de terme|recalcule la prime|chaque deux ans|i\\.e\\." "$qmd"; then
    echo "  WARN: common transcription/French issue pattern found; inspect with rg"
  fi

  if [[ -f "$pdf_path" ]] && command -v pdfimages >/dev/null 2>&1; then
    image_count="$(pdfimages -list "$pdf_path" | awk 'NR > 2 && $2 ~ /^[0-9]+$/ { count++ } END { print count + 0 }')"
    if [[ "$image_count" -gt 0 ]]; then
      echo "  WARN: PDF contains ${image_count} images; visually verify or OCR image-based solutions"
    fi
  fi

  if [[ -f "$pdf_path" ]] && command -v pdftotext >/dev/null 2>&1; then
    tmp_text="$(mktemp)"
    pdftotext -layout "$pdf_path" "$tmp_text"
    pdf_question_count="$(grep -Ec "^[[:space:]]+[0-9]+\\. \\(" "$tmp_text" || true)"
    rm -f "$tmp_text"
    echo "  CAS-numbered PDF questions detected by text extraction: ${pdf_question_count}"
  fi

  echo
done

exit "$status"
