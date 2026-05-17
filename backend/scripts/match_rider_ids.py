#!/usr/bin/env python3
"""
match_rider_ids.py
──────────────────
Matches riders from platform export files (Keeta CSV, Ninja Excel)
against Supabase profiles by name similarity, then writes the
platform courier IDs back to profiles.keeta_id / profiles.ninja_id.

Usage:
  python3 match_rider_ids.py --dry-run          # preview only, no writes
  python3 match_rider_ids.py                    # apply high-confidence matches
  python3 match_rider_ids.py --threshold 0.7   # lower threshold (more matches, more risk)

Output:
  match_results.csv   – full match report (review before applying)
"""

import os, re, csv, sys, json, argparse
import urllib.request, urllib.parse
from difflib import SequenceMatcher

# ── Config ────────────────────────────────────────────────────────────────────

SUPABASE_URL = "https://yotkztmstrhrdqffcciz.supabase.co"
SERVICE_KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdGt6dG1zdHJocmRxZmZjY2l6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njk0MjA4MCwiZXhwIjoyMDkyNTE4MDgwfQ.v0ghVggD7sMOiwjgxueGAR24c60G2web-XarP7CGnHY"

KEETA_CSV    = os.path.expanduser("~/Downloads/captain_performance_2026-05-05T12_57_31.611Z.csv")
NINJA_XLSX   = os.path.expanduser("~/Downloads/Ninja grocery Shift May.xlsx")
OUTPUT_CSV   = os.path.join(os.path.dirname(__file__), "match_results.csv")

HIGH_CONFIDENCE = 0.82   # auto-apply above this
REVIEW_MIN      = 0.60   # show in report above this (below = rejected)

HEADERS = {
    "apikey":        SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type":  "application/json",
    "Prefer":        "return=minimal",
}

# ── Helpers ───────────────────────────────────────────────────────────────────

def _clean(name: str) -> str:
    """Lowercase, remove company suffix (Walim), collapse whitespace."""
    name = re.sub(r'\s*\([^)]+\)\s*$', '', name)
    name = re.sub(r'\s+', ' ', name).strip().lower()
    return name

def _tokens(name: str) -> set:
    return set(_clean(name).split())

def _score(a: str, b: str) -> float:
    """Combined token overlap + sequence similarity."""
    ca, cb = _clean(a), _clean(b)
    seq  = SequenceMatcher(None, ca, cb).ratio()
    ta, tb = _tokens(a), _tokens(b)
    tok  = len(ta & tb) / max(len(ta), len(tb), 1)
    return round(0.5 * seq + 0.5 * tok, 4)

def _supabase_get(path: str) -> list:
    req = urllib.request.Request(f"{SUPABASE_URL}/rest/v1/{path}", headers=HEADERS)
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())

def _supabase_patch(table: str, row_id: str, payload: dict):
    data = json.dumps(payload).encode()
    req  = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/{table}?id=eq.{row_id}",
        data=data, headers=HEADERS, method="PATCH",
    )
    urllib.request.urlopen(req)

# ── Fetch all rider profiles ──────────────────────────────────────────────────

def fetch_profiles() -> list:
    print("Fetching profiles from Supabase…")
    profiles = _supabase_get(
        "profiles?select=id,full_name,keeta_id,ninja_id,amazon_id,iqama_number,status"
        "&limit=1000"
    )
    print(f"  {len(profiles)} profiles loaded.")
    return profiles

# ── Load platform files ───────────────────────────────────────────────────────

def load_keeta_csv(path: str) -> list[dict]:
    """Returns list of {captain_id, name}."""
    riders = []
    with open(path, newline='', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            cid  = row.get('Captain ID', '').strip()
            name = row.get('Captain Name', '').strip()
            if cid and name and cid != 'Captain ID':
                riders.append({'platform': 'keeta', 'platform_id': cid, 'name': name})
    print(f"  Keeta CSV: {len(riders)} riders")
    return riders

def load_ninja_xlsx(path: str) -> list[dict]:
    """Returns list of {da_id, name} across all sheets."""
    try:
        import openpyxl
    except ImportError:
        print("  openpyxl not installed, skipping Ninja file.")
        return []

    wb = openpyxl.load_workbook(path, data_only=True)
    seen, riders = set(), []
    skip_sheets = {'sheet1', 'sheet2', 'sheet3'}
    for ws in wb.worksheets:
        if ws.title.lower() in skip_sheets:
            continue
        for row in ws.iter_rows(min_row=2, values_only=True):
            if not row or len(row) < 5:
                continue
            da_name = str(row[1] or '').strip()
            da_id   = str(row[3] or '').strip()
            if not da_name or da_name == 'DA Name':
                continue
            key = (da_id, da_name)
            if key not in seen:
                seen.add(key)
                riders.append({'platform': 'ninja', 'platform_id': da_id, 'name': da_name})
    print(f"  Ninja XLSX: {len(riders)} riders")
    return riders

# ── Match ─────────────────────────────────────────────────────────────────────

def match(platform_riders: list[dict], profiles: list[dict], review_min: float = REVIEW_MIN) -> list[dict]:
    results = []

    for rider in platform_riders:
        best_score, best_profile = 0.0, None
        for p in profiles:
            s = _score(rider['name'], p['full_name'])
            if s > best_score:
                best_score, best_profile = s, p

        # Determine existing DB value for this platform column
        col      = f"{rider['platform']}_id"
        existing = best_profile.get(col) if best_profile else None

        if best_score >= review_min and best_profile:
            results.append({
                'platform':         rider['platform'],
                'platform_id':      rider['platform_id'],
                'platform_name':    rider['name'],
                'db_profile_id':    best_profile['id'],
                'db_full_name':     best_profile['full_name'],
                'db_iqama':         best_profile.get('iqama_number', ''),
                'db_status':        best_profile.get('status', ''),
                'score':            best_score,
                'confidence':       'HIGH' if best_score >= HIGH_CONFIDENCE else 'REVIEW',
                'existing_db_id':   existing or '',
                'action':           'SKIP (already set)' if existing else ('APPLY' if best_score >= HIGH_CONFIDENCE else 'MANUAL REVIEW'),
            })
        else:
            results.append({
                'platform':         rider['platform'],
                'platform_id':      rider['platform_id'],
                'platform_name':    rider['name'],
                'db_profile_id':    '',
                'db_full_name':     '',
                'db_iqama':         '',
                'db_status':        '',
                'score':            best_score,
                'confidence':       'NO MATCH',
                'existing_db_id':   '',
                'action':           'NO MATCH',
            })

    return results

# ── Write CSV report ──────────────────────────────────────────────────────────

def write_report(results: list[dict], path: str):
    fields = ['platform','platform_id','platform_name','score','confidence','action',
              'db_profile_id','db_full_name','db_iqama','db_status','existing_db_id']
    with open(path, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for r in sorted(results, key=lambda x: (-x['score'])):
            w.writerow(r)
    print(f"\nReport written → {path}")

# ── Apply ─────────────────────────────────────────────────────────────────────

def apply_matches(results: list[dict], dry_run: bool):
    to_apply = [r for r in results if r['action'] == 'APPLY']
    col_map  = {'keeta': 'keeta_id', 'ninja': 'ninja_id', 'amazon': 'amazon_id'}
    print(f"\n{'[DRY RUN] ' if dry_run else ''}Applying {len(to_apply)} high-confidence matches…\n")

    applied = skipped = errors = 0
    for r in to_apply:
        col = col_map[r['platform']]
        print(f"  {r['platform'].upper()} {r['platform_id']:>10} → {r['db_full_name'][:45]:<45} score={r['score']:.2f}")
        if not dry_run:
            try:
                _supabase_patch('profiles', r['db_profile_id'], {col: r['platform_id']})
                applied += 1
            except Exception as e:
                print(f"    ✗ ERROR: {e}")
                errors += 1
        else:
            applied += 1

    review = [r for r in results if r['confidence'] == 'REVIEW']
    no_match = [r for r in results if r['confidence'] == 'NO MATCH']

    print(f"\n{'=' * 60}")
    print(f"  Applied (HIGH confidence ≥{HIGH_CONFIDENCE:.0%}): {applied}")
    print(f"  Needs manual review:                  {len(review)}")
    print(f"  No match found:                       {len(no_match)}")
    if errors:
        print(f"  Errors:                               {errors}")
    print(f"{'=' * 60}")

    if review:
        print(f"\n⚠  MANUAL REVIEW needed ({len(review)} riders):")
        print(f"   Open match_results.csv, check these rows, then run:")
        print(f"   UPDATE profiles SET keeta_id='<id>' WHERE id='<profile_id>';")
        for r in sorted(review, key=lambda x: -x['score']):
            print(f"   [{r['score']:.2f}] {r['platform_id']:>10} {r['platform_name'][:30]:<30} → {r['db_full_name'][:35]}")

    if no_match:
        print(f"\n✗  NO MATCH ({len(no_match)} riders — not in Supabase):")
        for r in no_match:
            print(f"   {r['platform_id']:>10}  {r['platform_name']}")

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Match platform rider IDs to Supabase profiles")
    parser.add_argument('--dry-run',   action='store_true', help="Preview only, no DB writes")
    parser.add_argument('--threshold', type=float, default=0.60,
                        help="Minimum score to include in report (default 0.60)")
    parser.add_argument('--keeta-csv', default=KEETA_CSV, help="Path to Keeta captain_performance CSV")
    parser.add_argument('--ninja-xlsx', default=NINJA_XLSX, help="Path to Ninja shift XLSX")
    args = parser.parse_args()

    review_min = args.threshold

    print("=" * 60)
    print("  Rider ID Matching Script")
    print("=" * 60)

    profiles = fetch_profiles()

    all_riders = []
    if os.path.exists(args.keeta_csv):
        print(f"\nLoading Keeta CSV: {args.keeta_csv}")
        all_riders += load_keeta_csv(args.keeta_csv)
    else:
        print(f"\n⚠  Keeta CSV not found: {args.keeta_csv}")

    if os.path.exists(args.ninja_xlsx):
        print(f"Loading Ninja XLSX: {args.ninja_xlsx}")
        all_riders += load_ninja_xlsx(args.ninja_xlsx)
    else:
        print(f"⚠  Ninja XLSX not found: {args.ninja_xlsx}")

    if not all_riders:
        print("No rider files found. Exiting.")
        sys.exit(1)

    print(f"\nMatching {len(all_riders)} riders against {len(profiles)} profiles…")
    results = match(all_riders, profiles, review_min=review_min)

    write_report(results, OUTPUT_CSV)
    apply_matches(results, dry_run=args.dry_run)

if __name__ == '__main__':
    main()
