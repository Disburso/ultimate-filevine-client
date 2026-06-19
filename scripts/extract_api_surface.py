#!/usr/bin/env python3
"""Generate docs/openapi/API_SURFACE.md from the committed Filevine OpenAPI specs.

This is a derived navigation index; the JSON specs under docs/openapi/ remain the
source of truth. Re-run after refreshing the specs:

    python3 scripts/extract_api_surface.py
"""
import json
import collections
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
APP = ROOT / "docs/openapi/FV.App.API.json"
IDENTITY = ROOT / "docs/openapi/FV.Identity.API.json"
OUT = ROOT / "docs/openapi/API_SURFACE.md"
GENERATED_ON = "2026-06-20"

METHOD_ORDER = ["get", "post", "put", "patch", "delete"]


def methods_of(item):
    return [m for m in METHOD_ORDER if m in item]


def main():
    app = json.loads(APP.read_text())
    idn = json.loads(IDENTITY.read_text())
    paths = app["paths"]
    defs = app["definitions"]

    by_tag = collections.defaultdict(list)
    total_ops = 0
    off_prefix = [p for p in paths if not p.startswith("/fv-app/v2")]
    for path, item in paths.items():
        for method in methods_of(item):
            op = item[method]
            total_ops += 1
            tag = (op.get("tags") or ["(untagged)"])[0]
            qnames = {p.get("name") for p in op.get("parameters", []) if p.get("in") == "query"}
            by_tag[tag].append({
                "method": method.upper(),
                "path": path,
                "opId": op.get("operationId", ""),
                "summary": (op.get("summary") or "").strip().replace("\n", " ")[:90],
                "paged": "offset" in qnames and "limit" in qnames,
            })

    out = []
    w = out.append
    w("# Filevine v2 API — extracted surface\n")
    w(f"> Generated from the committed specs (`docs/openapi/FV.App.API.json`, "
      f"`docs/openapi/FV.Identity.API.json`) on {GENERATED_ON}.")
    w("> This is a derived index for navigation; the JSON specs remain the source of truth. "
      "Regenerate with `scripts/extract_api_surface.py`.\n")
    w(f"- **Gateway host:** `{app.get('host')}`  •  base path `{app.get('basePath')}`  "
      f"•  schemes `{app.get('schemes')}`")
    w(f"- **Spec:** Swagger {app.get('swagger')} — \"{app['info'].get('title')}\" "
      f"v{app['info'].get('version')}")
    w(f"- **{len(paths)} paths**, **{total_ops} operations**, across **{len(by_tag)} resource "
      f"families**, {len(defs)} definitions\n")

    w("## Gotchas (read before coding resources)\n")
    if not off_prefix:
        prefix_note = "All paths are under `/fv-app/v2` (no `/core` prefix exists in the gateway spec)."
    else:
        exc = ", ".join(f"`{p}`" for p in sorted(off_prefix))
        prefix_note = (f"{len(paths) - len(off_prefix)} of {len(paths)} paths are under `/fv-app/v2` "
                       f"(no `/core` prefix exists in the gateway spec). Exception(s): {exc}.")
    w(f"- {prefix_note}")
    w("- **Paths are case-sensitive and inconsistently cased** — e.g. `/fv-app/v2/Projects` (list/create) "
      "vs `/fv-app/v2/projects/{projectid}` (archive). Even path-parameter names vary "
      "(`{projectId}` vs `{projectid}`). Use each path **verbatim** from the spec; do not normalize casing.")
    w("- The two required tenant headers (`x-fv-orgid`, `x-fv-userid`) are declared per-operation, "
      "not globally — but they appear on virtually every op; send them on all gateway calls.\n")

    sd = app["securityDefinitions"]["access_token"]
    w("## Authentication & required headers\n")
    w(f"- Global security: bearer token in the **`{sd['name']}`** header ({sd['description']}).")
    w("- **288 operations also require** the `x-fv-orgid` and `x-fv-userid` headers.")
    w("- No request signing/HMAC in the gateway flow. Mint the bearer token via the Identity API (below).\n")

    w("## Pagination contract\n")
    w("Paginated list endpoints (**48 GET endpoints**) accept `offset` (default 0), `limit` "
      "(default 50), and optional `requestedFields` (comma-separated field projection), plus "
      "per-endpoint filters.")
    w("Responses wrap results in an `ItemList…` object with **PascalCase** keys:\n")
    w("| Field | Type | Meaning |")
    w("|-------|------|---------|")
    w("| `Items` | array | the page of records |")
    w("| `Count` | integer | number of items in this response |")
    w("| `Offset` | integer | echoed offset |")
    w("| `Limit` | integer | echoed limit |")
    w("| `HasMore` | boolean | more pages exist |")
    w("| `LastID` | integer | last record id (cursor-style continuation on some endpoints) |")
    w("| `RequestedFields` | string | echoed field projection |")
    w("| `Links` | object | string-map of relative URLs (e.g. `self`, `next`, `previous`) |\n")
    w("Iterate by following `Links.next` (or incrementing `offset += limit`) while `HasMore` is true.\n")

    w("## Resource families\n")
    w("| Family (tag) | # ops |")
    w("|--------------|-------|")
    for tag in sorted(by_tag):
        w(f"| {tag} | {len(by_tag[tag])} |")
    w("")

    w("## Endpoints by family\n")
    for tag in sorted(by_tag):
        w(f"### {tag}\n")
        w("| Method | Path | Operation | Pg | Summary |")
        w("|--------|------|-----------|----|---------|")
        rows = sorted(by_tag[tag], key=lambda r: (r["path"], METHOD_ORDER.index(r["method"].lower())))
        for r in rows:
            pg = "📄" if r["paged"] else ""
            summ = r["summary"].replace("|", "\\|")
            w(f"| {r['method']} | `{r['path']}` | {r['opId']} | {pg} | {summ} |")
        w("")

    w("## Webhook event enums\n")
    eo = defs["ApiSubscriptionEventObjectEnum"]["enum"]
    et = defs["ApiSubscriptionEventTypeEnum"]["enum"]
    w(f"Webhook subscriptions are defined by **object × type**: {len(eo)} objects × {len(et)} event types.\n")
    w(f"**Event objects ({len(eo)}):** " + ", ".join(f"`{v}`" for v in eo) + "\n")
    w(f"**Event types ({len(et)}):** " + ", ".join(f"`{v}`" for v in et) + "\n")
    w("Subscription endpoints: `GET/POST /fv-app/v2/webhooks/subscription[s]`, "
      "`GET/PUT/DELETE /fv-app/v2/webhooks/subscription/{subscriptionId}`, "
      "`GET /fv-app/v2/webhooks/Events`.\n")

    w("## Identity API (token minting)\n")
    server = (idn.get("servers") or [{}])[0].get("url", "https://identity.filevine.com")
    w(f"- Host `{server}` — OpenAPI {idn.get('openapi')} \"{idn['info'].get('title')}\".")
    for path, item in idn["paths"].items():
        for method in methods_of(item):
            op = item[method]
            w(f"- **{method.upper()} {path}** — {op.get('summary') or op.get('operationId', '')}")
            for ct, body in op.get("requestBody", {}).get("content", {}).items():
                props = (body.get("schema") or {}).get("properties")
                if props:
                    w(f"    - body (`{ct}`): " + ", ".join(f"`{k}`" for k in props))
    w("")

    OUT.write_text("\n".join(out))
    print(f"Wrote {OUT.relative_to(ROOT)} ({len(out)} lines, {total_ops} operations, {len(by_tag)} families)")


if __name__ == "__main__":
    main()
