#!/bin/sh
set -eu

# The types are generated from the schema. A hand edit here is a second source
# of truth for a contract two tools read, so it must not survive a build.

oapi-codegen -config hack/oapi-types.yaml spec/register.v1.yaml

if ! git diff --quiet -- pkg/registertypes; then
    echo "the generated types are stale. run the build." >&2
    git --no-pager diff --stat -- pkg/registertypes >&2
    exit 1
fi

if ! head -3 pkg/registertypes/zz_generated.types.go | grep -q "DO NOT EDIT"; then
    echo "the generated types carry no DO NOT EDIT header" >&2
    exit 1
fi

echo "the Go types match the schema they come from"
