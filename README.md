# forge-register-spec

The register document schemas, with the vectors every implementation is
tested against.

## Why it is its own repo

forge-register writes the index. forge-factory resolves against it. **Neither
depends on the other.** They both depend on this.

The get, put and list transport is owned by forge-revision-spec. The register
is new record kinds carried over that transport, so a state engine that passes
the revision conformance suite carries register records unchanged. This repo
owns only what those records look like.

## What is here

| Path | Holds |
|---|---|
| `spec/register.v1.yaml` | OpenAPI 3.0.3. Track, VersionEntry, SeverityVector, Advisory, Deprecation, Request, Alternative, Verdict. |
| `testdata/cases.json` | Conformance vectors. Valid, invalid, and semantic. |
| `hack/validate.sh` | Checks the schema and the vectors agree. |
| `pkg/registertypes` | Go types generated from the schema. Never edited. |

It is an OpenAPI document rather than a bare JSON Schema so types can be
generated from `components.schemas`.

## The three kinds of vector

**valid** must pass the schema. **invalid** must fail it, and each names the
substring its error must contain.

**semantic** is the important kind. Each must PASS the schema and fail only in
the second-pass validator, because every semantic rule spans two fields —
current belongs to its track prefix, an adoption names a version, a denial
carries a message — and a schema that tries to express one grows a rule it
should not have. `hack/validate.sh` asserts both halves.

## What the documents fix, and what they do not

The schemas fix the shape of the register's records. How the register decides
— the severity-vector comparison, quarantine, the track deny policies — is
forge-register's business; the verdict codes here are the vocabulary those
decisions are written in, so every decision is machine-readable and a denied
request can be corrected from its verdict alone.

## Running the gate

```sh
forge test-all
```
