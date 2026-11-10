# shellcheck shell=bash
# Tests of scripts/check/eol.sh.
# shellcheck disable=SC2154 # work comes from setup of the harness.

: "${root:?}"

# eol_run NAME EXPECTED CONTENT MESSAGE [TODAY]: run the script on an EOL
# file with CONTENT, given to printf %b, and TODAY; EXPECTED is ok or fail,
# and its output has MESSAGE.
eol_run() {
  local name=$1 expected=$2 content=$3 message=$4
  shift 4
  setup
  printf '%b' "$content" >"$work/eol"
  run "eol: $name" "$expected" scripts/check/eol.sh -- "$work/eol" "$@"
  expect message "$message"
  finish
}

for case in "2026-10-29 ok supported" "2026-12-10 ok in 21 days" "2027-01-02 fail reached its end of life"; do
  read -r today expected message <<<"$case"
  eol_run "$today" "$expected" '# comment\nnixos-26.05 2026-12-31\n' "$message" "$today"
done

# A malformed EOL file fails with a message instead of counting from today.
while IFS='|' read -r name content message; do
  eol_run "$name" fail "$content" "$message" 2026-10-29
done <<'CASES'
no date|# comment\nnixos-26.05\n|'' is not a date
an invalid date|nixos-26.05 2026-02-30\n|'2026-02-30' is not a date
another date format|nixos-26.05 31.12.2026\n|'31.12.2026' is not a date
no data line|# comment\n\n|no data line
an empty file||no data line
two data lines|nixos-26.05 2026-12-31\nnixos-26.11 2027-06-30\n|more than one data line
not a branch|2026-12-31\n|'2026-12-31' is not a branch
an extra field|nixos-26.05 2026-12-31 x\n|unexpected 'x'
CASES

eol_run "a last line without a newline" ok 'nixos-26.05 2026-12-31' \
  "supported until 2026-12-31" 2026-10-29
eol_run "an invalid today" fail 'nixos-26.05 2026-12-31\n' "'' is not a date" ""

setup
run "eol: a missing file" fail scripts/check/eol.sh -- "$work/none"
finish

# eol_branch: print the branch that nixpkgs-eol of this repository names.
eol_branch() {
  local line
  while IFS= read -r line; do
    [[ $line == '#'* || -z $line ]] || {
      printf '%s\n' "${line%% *}"
      return 0
    }
  done <"$root/nixpkgs-eol"
}

# locks_eol_branch: flake.lock follows the branch of nixpkgs-eol.
locks_eol_branch() {
  jq -e --arg branch "$(eol_branch)" '.nodes.nixpkgs.original.ref == $branch' "$root/flake.lock" >/dev/null \
    || echo "nixpkgs-eol names $(eol_branch), flake.lock follows another branch"
}

setup
run_lib "eol: nixpkgs-eol names the branch of flake.lock" ok "" locks_eol_branch
expect stdout ""
finish
