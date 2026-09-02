#!/usr/bin/env bash
#
# find-next-candidate.sh — rank the remaining Objective-C classes in radar-sdk-ios
# by how good a next ObjC→Swift migration target they are.
#
# The backlog = every RadarSDK/*.m that has NO RadarSDK/<base>.swift twin yet.
# (A class with a .swift twin is fully migrated or mid-migration, so it is excluded.)
# For each backlog file the script reports:
#   LINES     — size of the .m
#   COUPLING  — how many other RadarSDK files reference the class (grep -lw)
#   TESTS     — whether any existing test references it
#   KIND      — "model" if it has the Radar dictionaryValue/initWithObject: serialization
#               convention (an ideal Strategy D value-type target), else "other"
#   FLAGS     — deprioritizers: sys (CLLocationManager/dispatch/timer), manager, large
#               (>300 lines), covered (already modeled by a Swift value type elsewhere),
#               partial (a <base>Swift symbol already exists)
#
# Ranking (most-trivial-first): flag-free files come before flagged ("risky") ones, and
# within each group the smallest file wins, then the least-coupled, then value models
# (which convert most mechanically) as a tiebreaker. So the single most trivial safe file
# surfaces at the top. The script only NARROWS and SIGNALS; you must still open the top few
# and confirm the pick is a self-contained leaf (watch for tightly-coupled clusters like
# Route*/Trip*/Geometry), and confirm the target with the user before migrating.
#
# Read-only. Writes nothing.
#   Usage: find-next-candidate.sh [REPO_ROOT] [-n TOP_N]
#   REPO_ROOT defaults to `git rev-parse --show-toplevel` from the current directory.

set -u

# Classes whose Swift representation already lives in another file, so they should NOT
# be converted as standalone Swift types. Keep this short and documented.
#   Radar{Geofence,Circle,Polygon}Geometry -> modeled by RadarGeofenceGeometrySwift
#   (enum with .circle/.polygon cases) in RadarSDK/RadarGeofence.swift.
COVERED_ELSEWHERE=" RadarGeofenceGeometry RadarCircleGeometry RadarPolygonGeometry "

TOP_N=0 # 0 = show all
REPO=""
while [ $# -gt 0 ]; do
    case "$1" in
        -n)
            TOP_N="${2:-0}"
            shift 2
            ;;
        *)
            REPO="$1"
            shift
            ;;
    esac
done

if [ -z "$REPO" ]; then
    REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [ -z "$REPO" ] || [ ! -d "$REPO/RadarSDK" ]; then
    echo "error: could not locate the radar-sdk-ios repo (no RadarSDK/ under '$REPO')." >&2
    echo "       run this from inside the repo, or pass the repo root as the first argument." >&2
    exit 1
fi

SDK="$REPO/RadarSDK"
TESTS="$REPO/RadarSDKTests"

# One tab-separated row per backlog file:
#   <tier>\t<lines>\t<coupling>\t<base>\t<test>\t<kind>\t<flags>
# tier: 0 = flag-free (safe), 1 = flagged (risky). Within a tier, smaller + less-coupled
# ranks first, so the most trivial file surfaces at the top.
rows=""
for m in "$SDK"/*.m; do
    [ -e "$m" ] || continue
    base="$(basename "$m" .m)"
    [ -f "$SDK/$base.swift" ] && continue # has a Swift twin already

    lines="$(wc -l <"$m" | tr -d ' ')"

    coupling="$(grep -rlw "$base" "$SDK" --include='*.m' --include='*.h' --include='*.swift' 2>/dev/null \
        | grep -Ev "/$base\.(m|h|swift)$" | wc -l | tr -d ' ')"

    if ls "$TESTS/$base"*[Tt]est*.swift >/dev/null 2>&1 \
        || grep -rlqw "$base" "$TESTS" --include='*.m' --include='*.swift' 2>/dev/null; then
        test="yes"
    else
        test="no"
    fi

    if grep -qE 'dictionaryValue|initWithObject:' "$m" 2>/dev/null; then
        kind="model"
    else
        kind="other"
    fi

    # Flags (deprioritizers).
    flags=""
    add_flag() { if [ -z "$flags" ]; then flags="$1"; else flags="$flags,$1"; fi; }
    grep -qE 'CLLocationManager|dispatch_|NSTimer|CMMotion' "$m" 2>/dev/null && add_flag "sys"
    case "$base" in *Manager) add_flag "manager" ;; esac
    [ "$lines" -gt 300 ] && add_flag "large"
    case "$COVERED_ELSEWHERE" in *" $base "*) add_flag "covered" ;; esac
    grep -rqw "${base}Swift" "$SDK" --include='*.swift' 2>/dev/null && add_flag "partial"

    if [ -n "$flags" ]; then
        tier=1 # risky — has a deprioritizer flag
    else
        tier=0 # safe — flag-free leaf; ranked among peers by size then coupling
    fi

    rows="${rows}${tier}	${lines}	${coupling}	${base}	${test}	${kind}	${flags:--}
"
done

if [ -z "$rows" ]; then
    echo "No un-migrated Objective-C classes found under $SDK — the backlog is empty. 🎉"
    exit 0
fi

# Rank most-trivial-first: safe-before-risky, then fewest lines, then lowest coupling,
# then value models first (kind "model" sorts before "other") as a final tiebreaker.
sorted="$(printf '%s' "$rows" | sort -t'	' -k1,1n -k2,2n -k3,3n -k6,6)"
total="$(printf '%s\n' "$sorted" | grep -c .)"

echo "ObjC → Swift migration backlog in $SDK"
echo "$total un-migrated classes (no .swift twin). Most-trivial-first ranking:"
echo
printf '%-4s %-28s %6s %8s %6s %-6s %s\n' "RANK" "CLASS (.m)" "LINES" "COUPLING" "TESTS" "KIND" "FLAGS"
printf '%-4s %-28s %6s %8s %6s %-6s %s\n' "----" "----------------------------" "-----" "--------" "-----" "------" "-----"

rank=0
top_safe=""
while IFS='	' read -r tier lines coupling base test kind flags; do
    [ -n "$base" ] || continue
    rank=$((rank + 1))
    printf '%-4s %-28s %6s %8s %6s %-6s %s\n' "$rank" "$base.m" "$lines" "$coupling" "$test" "$kind" "$flags"
    if [ "$tier" = "0" ]; then
        count="$(printf '%s' "$top_safe" | wc -w | tr -d ' ')"
        [ "$count" -lt 3 ] && top_safe="$top_safe $base"
    fi
    if [ "$TOP_N" -gt 0 ] && [ "$rank" -ge "$TOP_N" ]; then break; fi
done <<EOF
$sorted
EOF

echo
if [ -n "$top_safe" ]; then
    echo "Most trivial candidates (smallest, least-coupled, flag-free — convert these first):"
    for b in $top_safe; do echo "  • RadarSDK/$b.m"; done
    echo
    echo "These are ranked most-trivial-first (fewest lines, then lowest coupling). Pick the"
    echo "most self-contained one that is NOT part of a tightly-coupled cluster (the Route* and"
    echo "Trip* families reference each other; converting one drags the rest). A KIND=model file"
    echo "converts most mechanically via Strategy D."
else
    echo "No flag-free file left — everything remaining is a manager, system-touching, large,"
    echo "or already modeled elsewhere. Consider a Strategy B per-method seam (patterns.md)."
fi
echo
echo "Reminder: this script only narrows + signals. Confirm the target with the user before"
echo "migrating (repo policy: never migrate a file without asking)."
