#!/bin/sh
set -eu

exec uv run --quiet --with jsonschema --with pyyaml python3 - "$@" <<'PY'
import json
import sys

import yaml
from jsonschema import Draft202012Validator

spec = yaml.safe_load(open("spec/register.v1.yaml"))
schemas = spec["components"]["schemas"]
cases = json.load(open("testdata/cases.json"))

failures = []


def inline(node, seen=()):
    if isinstance(node, dict):
        ref = node.get("$ref", "")

        if ref.startswith("#/components/schemas/"):
            name = ref.rsplit("/", 1)[1]

            if name in seen:
                return {"type": "object"}

            return inline(schemas[name], seen + (name,))

        return {k: inline(v, seen) for k, v in node.items()}

    if isinstance(node, list):
        return [inline(v, seen) for v in node]

    return node


def errors_for(schema_name, doc):
    if schema_name not in schemas:
        failures.append("no schema named %s" % schema_name)

        return []

    return list(Draft202012Validator(inline(schemas[schema_name])).iter_errors(doc))


for case in cases["schema"]["valid"]:
    errs = errors_for(case["schema"], case["doc"])

    if errs:
        failures.append("schema/valid/%s must pass %s but got: %s"
                        % (case["case"], case["schema"], errs[0].message))

for case in cases["schema"]["invalid"]:
    if not errors_for(case["schema"], case["doc"]):
        failures.append("schema/invalid/%s must fail %s and did not"
                        % (case["case"], case["schema"]))


def in_prefix(version, prefix):
    return version == prefix or version.startswith(prefix + ".")


def semantic_errors(schema_name, doc):
    """Rules a schema cannot express, because each one spans two fields.

    Encoding these in the schema is how a schema grows a rule it should not
    have, so they live here and the vectors assert they fail here only.
    """
    out = []

    if schema_name == "Track":
        prefix = doc.get("prefix", "")
        current = doc.get("current", "")

        if prefix and current and not in_prefix(current, prefix):
            out.append("current does not belong to the track prefix")

        history = doc.get("history") or []

        if history:
            adopted = [e.get("adoptedAt", "") for e in history]

            if adopted != sorted(adopted):
                out.append("history is not in adoption order")
            elif history[-1].get("version") != current:
                out.append("current is not the last adopted entry")

    if schema_name == "Request":
        if doc.get("type") == "open-track" and not doc.get("track"):
            out.append("an open-track request names no track")

    if schema_name == "Verdict":
        code = doc.get("code", "")

        if code.startswith("denied-") and not doc.get("message"):
            out.append("a denial carries no message")

        if code == "adopted" and not doc.get("adopted"):
            out.append("an adoption names no version")

    return out


# Both halves. A semantic vector must pass the schema, and must fail here.
for case in cases["schema"].get("semantic", []):
    errs = errors_for(case["schema"], case["doc"])

    if errs:
        failures.append("schema/semantic/%s must PASS the schema and did not: %s"
                        % (case["case"], errs[0].message))

    reasons = semantic_errors(case["schema"], case["doc"])

    if case["error"] not in reasons:
        failures.append("schema/semantic/%s must fail the validator with %r, got %r"
                        % (case["case"], case["error"], reasons))

# A vector that is meant to be valid must be clean on both halves too.
for case in cases["schema"]["valid"]:
    reasons = semantic_errors(case["schema"], case["doc"])

    if reasons:
        failures.append("schema/valid/%s must satisfy the validator too, got %r"
                        % (case["case"], reasons))

for f in failures:
    print("FAIL " + f, file=sys.stderr)

print("checked %d schema vectors" % (
    len(cases["schema"]["valid"])
    + len(cases["schema"]["invalid"])
    + len(cases["schema"].get("semantic", [])),
))

if failures:
    sys.exit(1)

print("the schema and the vectors agree")
PY
