#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Licence guard (PRD D6). Fails if:
#   a) a spec/dependencies.md row marked "app binary" has a licence not on the allow-list,
#      or a row's "Runs in" is not one of the three allowed values,
#   d) a package the project actually declares (SwiftPM .package(url:), XcodeGen packages url:)
#      has no row in spec/dependencies.md (matched on its source URL),
#   b) a tracked or new source file carries GPL/AGPL/LGPL/non-commercial licence markers,
#   c) a .swift file under App/, Packages/, Tests/ or a .sh under scripts/ has no SPDX line.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

ALLOWED=(MIT BSD-2-Clause BSD-3-Clause Apache-2.0 Zlib MPL-2.0 ISC BSL-1.0 Unlicense)
SELF="scripts/check-licences.sh"
fail=0

report() { echo "check-licences: $*" >&2; fail=1; }

# (a) allow-list for the app binary
[[ -f spec/dependencies.md ]] || { echo "check-licences: spec/dependencies.md missing" >&2; exit 1; }
rows=0
sources=()
while IFS='|' read -r _ dep lic runs src _; do
  dep="$(echo "$dep" | xargs)"; lic="$(echo "$lic" | xargs)"; runs="$(echo "$runs" | xargs)"; src="$(echo "$src" | xargs)"
  case "$dep" in Dependency|---*) continue ;; esac
  sources+=("$src")
  case "$runs" in
    "app binary") ;;
    "server only"|"build tool") continue ;;
    *) report "(a) '$dep' has \"Runs in\" '$runs'; use app binary, server only or build tool"; continue ;;
  esac
  rows=$((rows + 1))
  ok=0
  for a in "${ALLOWED[@]}"; do [[ "$lic" == "$a" ]] && ok=1; done
  [[ $ok -eq 1 ]] || report "(a) '$dep' is marked app binary with licence '$lic', which is not on the allow-list"
done < <(grep '^|' spec/dependencies.md)
[[ $rows -gt 0 ]] || report "(a) no 'app binary' rows found in spec/dependencies.md (table format changed?)"

# (d) every declared package needs a row. Normalise URLs: no scheme, no .git, lower case.
normalise() { echo "$1" | sed -E 's#^[a-z+]+://##; s#\.git$##; s#/+$##' | tr '[:upper:]' '[:lower:]'; }
declared=()
while IFS= read -r url; do declared+=("$url"); done < <(
  # Each lookup may find nothing; `|| true` stops errexit/pipefail ending the subshell before the next runs.
  { grep -hoE '\.package\([^)]*url: *"[^"]+"' Packages/*/Package.swift 2>/dev/null | sed -E 's/.*url: *"([^"]+)".*/\1/' || true
    grep -hE '^ +url: ' project.yml 2>/dev/null | sed -E 's/^ +url: *//; s/["'"'"']//g' || true
  } | sort -u)
for url in ${declared[@]+"${declared[@]}"}; do
  want="$(normalise "$url")"
  found=0
  for src in ${sources[@]+"${sources[@]}"}; do [[ "$(normalise "$src")" == "$want" ]] && found=1; done
  [[ $found -eq 1 ]] || report "(d) $url is declared as a package but has no row in spec/dependencies.md"
done

# Tracked plus new, non-ignored files (so it also works before the first commit).
files=()
while IFS= read -r f; do [[ -f "$f" ]] && files+=("$f"); done < <(git ls-files --cached --others --exclude-standard)

# (b) forbidden licence markers
pattern='GNU General Public License|GNU Affero|GNU Lesser General Public|SPDX-License-Identifier: *(GPL|AGPL|LGPL)|CC-BY-NC|non-commercial'
for f in ${files[@]+"${files[@]}"}; do
  case "$f" in docs/*|spec/*|*.md|"$SELF") continue ;; esac
  if grep -IqiE "$pattern" "$f"; then
    report "(b) forbidden licence marker in $f: $(grep -IiEn -m1 "$pattern" "$f" | cut -c1-100)"
  fi
done

# (c) SPDX header on source files
for f in ${files[@]+"${files[@]}"}; do
  case "$f" in
    App/*.swift|Packages/*.swift|Tests/*.swift|scripts/*.sh) ;;
    *) continue ;;
  esac
  grep -q 'SPDX-License-Identifier' "$f" || report "(c) missing SPDX-License-Identifier in $f"
done

if [[ $fail -ne 0 ]]; then
  echo "check-licences: FAILED" >&2
  exit 1
fi
echo "check-licences: OK ($rows app-binary dependencies checked, ${#declared[@]} declared packages matched, ${#files[@]} files scanned)"
