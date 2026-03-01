#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "requests>=2.31.0",
# ]
# ///
"""
Query the OpenFEC API for filings by committee ID.

Examples:
  uv run python fec_find_filings.py C00770941
  uv run python fec_find_filings.py C00770941 --most-recent --limit 10
  uv run python fec_find_filings.py C00770941 --form-type F3X --report-year 2024
  uv run python fec_find_filings.py C00770941 --format json --limit 5
  uv run python fec_find_filings.py C00770941 --format csv --limit 5

Notes:
- The output field `file_number` is the filing ID used by fecfile scripts.
- Provide an API key via --api-key, or set FEC_API_KEY / DATA_GOV_API_KEY.
- committee_name is included in all outputs.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from typing import Iterable, List, Optional

import requests

DEFAULT_FIELDS = [
    "committee_name",
    "file_number",
    "form_type",
    "report_type",
    "report_year",
    "coverage_start_date",
    "coverage_end_date",
    "receipt_date",
    "amendment_indicator",
    "amendment_version",
    "is_amended",
    "most_recent",
]


def _split_list(values: Optional[List[str]]) -> Optional[List[str]]:
    if not values:
        return None
    out: List[str] = []
    for value in values:
        parts = [p.strip() for p in value.split(",") if p.strip()]
        out.extend(parts)
    return out or None


def _coerce_bool(value: bool) -> Optional[str]:
    return "true" if value else None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="List FEC filings for a committee ID via the OpenFEC API."
    )
    parser.add_argument("committee_id", help="FEC committee ID (e.g., C00770941)")
    parser.add_argument(
        "--api-key",
        dest="api_key",
        help="OpenFEC API key (fallback to FEC_API_KEY / DATA_GOV_API_KEY)",
    )
    parser.add_argument(
        "--base-url",
        default="https://api.open.fec.gov/v1",
        help="OpenFEC API base URL",
    )
    parser.add_argument("--per-page", type=int, default=20)
    parser.add_argument("--page", type=int, default=1, help="Starting page")
    parser.add_argument(
        "--max-pages",
        type=int,
        help="Maximum number of pages to fetch (starting from --page)",
    )
    parser.add_argument("--limit", type=int, help="Maximum number of filings")
    parser.add_argument(
        "--sort",
        action="append",
        help="Sort fields (repeatable or comma-separated; prefix with '-' for desc)",
    )
    parser.add_argument("--form-type", action="append")
    parser.add_argument("--report-type", action="append")
    parser.add_argument("--cycle", action="append")
    parser.add_argument("--report-year", action="append")
    parser.add_argument("--amendment-indicator", action="append")
    parser.add_argument("--min-receipt-date")
    parser.add_argument("--max-receipt-date")
    parser.add_argument(
        "--most-recent",
        action="store_true",
        help="Return only the most recent report per report_type",
    )
    parser.add_argument(
        "--fields",
        default=",".join(DEFAULT_FIELDS),
        help="Comma-separated list of fields to output",
    )
    parser.add_argument(
        "--format",
        choices=["table", "json", "ndjson", "csv"],
        default="table",
    )
    return parser.parse_args()


def build_params(args: argparse.Namespace, page: int) -> dict:
    params: dict = {
        "api_key": args.api_key,
        "per_page": args.per_page,
        "page": page,
    }

    sort = _split_list(args.sort)
    if sort:
        params["sort"] = sort

    form_type = _split_list(args.form_type)
    if form_type:
        params["form_type"] = form_type

    report_type = _split_list(args.report_type)
    if report_type:
        params["report_type"] = report_type

    cycle = _split_list(args.cycle)
    if cycle:
        params["cycle"] = cycle

    report_year = _split_list(args.report_year)
    if report_year:
        params["report_year"] = report_year

    amendment_indicator = _split_list(args.amendment_indicator)
    if amendment_indicator:
        params["amendment_indicator"] = amendment_indicator

    if args.min_receipt_date:
        params["min_receipt_date"] = args.min_receipt_date
    if args.max_receipt_date:
        params["max_receipt_date"] = args.max_receipt_date

    most_recent = _coerce_bool(args.most_recent)
    if most_recent:
        params["most_recent"] = most_recent

    return params


def iter_filings(args: argparse.Namespace) -> Iterable[dict]:
    base_url = args.base_url.rstrip("/")
    url = f"{base_url}/committee/{args.committee_id}/filings/"

    api_key = (
        args.api_key
        or os.environ.get("FEC_API_KEY")
        or os.environ.get("DATA_GOV_API_KEY")
        or "DEMO_KEY"
    )
    args.api_key = api_key

    page = args.page
    fetched = 0
    pages_seen = 0

    while True:
        params = build_params(args, page)
        resp = requests.get(url, params=params, timeout=30)
        try:
            resp.raise_for_status()
        except requests.HTTPError as exc:
            raise SystemExit(
                f"Request failed ({resp.status_code}): {resp.text.strip()}"
            ) from exc

        payload = resp.json()
        results = payload.get("results", [])
        pagination = payload.get("pagination", {}) or {}

        if not results:
            break

        for item in results:
            yield item
            fetched += 1
            if args.limit and fetched >= args.limit:
                return

        pages_seen += 1
        if args.max_pages and pages_seen >= args.max_pages:
            return

        total_pages = pagination.get("pages")
        if total_pages and page >= total_pages:
            return

        page += 1


def format_value(value) -> str:
    if value is None:
        return ""
    if isinstance(value, (list, dict)):
        return json.dumps(value, ensure_ascii=True)
    return str(value)


def output_table(rows: Iterable[dict], fields: List[str]) -> None:
    print("\t".join(fields))
    for row in rows:
        print("\t".join(format_value(row.get(f)) for f in fields))


def output_csv(rows: Iterable[dict], fields: List[str]) -> None:
    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(fields)
    for row in rows:
        writer.writerow([format_value(row.get(f)) for f in fields])


def fetch_committee_name(args: argparse.Namespace) -> Optional[str]:
    base_url = args.base_url.rstrip("/")
    url = f"{base_url}/committee/{args.committee_id}/"
    params = {"api_key": args.api_key}
    try:
        resp = requests.get(url, params=params, timeout=30)
        resp.raise_for_status()
    except requests.RequestException:
        return None
    payload = resp.json()
    results = payload.get("results") or []
    if not results:
        return None
    return results[0].get("name")


def inject_committee_name(
    args: argparse.Namespace, fields: List[str], rows: List[dict]
) -> None:
    if not rows:
        return
    name = None
    if all(row.get("committee_name") for row in rows):
        name = rows[0].get("committee_name")
    if not name:
        name = fetch_committee_name(args)
    if not name:
        return
    for row in rows:
        row.setdefault("committee_name", name)
    if "committee_name" not in fields:
        fields.insert(0, "committee_name")


def main() -> None:
    args = parse_args()
    fields = [f.strip() for f in args.fields.split(",") if f.strip()]

    rows = list(iter_filings(args))
    inject_committee_name(args, fields, rows)

    if args.format == "json":
        print(json.dumps(rows, indent=2, ensure_ascii=True))
        return

    if args.format == "ndjson":
        for row in rows:
            print(json.dumps(row, ensure_ascii=True))
        return

    if args.format == "csv":
        output_csv(rows, fields)
        return

    output_table(rows, fields)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
