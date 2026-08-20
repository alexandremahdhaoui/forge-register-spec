# CLAUDE.md

This repo owns the register document schemas. Change it and you change
forge-register and forge-factory.

Read ~/.claude/CLAUDE.md first. Those rules apply here.

## The vectors are the contract

`testdata/cases.json` is what an implementation is tested against. Adding a
rule to the schema without adding a vector means nothing checks it.

Every invalid vector carries the substring its error must contain. Match on
the substring, never on the whole message.

## Semantic vectors must pass the schema

A vector marked semantic is a cross reference check. JSON Schema cannot
express a rule that spans two fields, so the second pass in
`hack/validate.sh` does it, and the same rules must be implemented by
forge-register.

`hack/validate.sh` asserts that a semantic vector passes the schema. If the
schema rejects it, the schema grew a rule it should not have.

## The transport is not here

Get, put and list belong to forge-revision-spec. Register records are new
kinds over that transport. Do not respecify it, and do not add transport
vectors here — a state engine proves itself against the revision suite.

## Verdicts are the error messages

A rejection must be correctable from its verdict alone: machine-readable
code, the requested version, alternatives with their severity vectors, and a
human message. A new failure mode is a new enum value plus a vector, never a
free-form string.

## Naming follows forge

forge parses yaml through `sigs.k8s.io/yaml`, so `json:` tags decide the key
names. Keys are lowerCamelCase, enum values are kebab-case.
