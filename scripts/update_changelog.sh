#!/bin/bash
#
# Updates CHANGELOG.md with the latest commit messages.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <version>" >&2
    exit 1
fi

NEW_VERSION=$1
CHANGELOG="CHANGELOG.md"
HEADING="# CHANGELOG"

# Get the latest tag to use as the starting point for the log.
LATEST_TAG=$(git tag --sort=-v:refname | head -n 1)

# Get the commit log.
if [ -z "$LATEST_TAG" ]; then
    # No tags yet, so we get all commits.
    LOG=$(git log --pretty=format:"- %s")
else
    # Get commits since the last tag.
    LOG=$(git log --pretty=format:"- %s" "${LATEST_TAG}"..HEAD)
fi

# Create the new changelog entry.
CHANGELOG_ENTRY="## ${NEW_VERSION}\n\n${LOG}\n"

# Read the existing changelog content, skipping the main heading.
if [ -f "$CHANGELOG" ]; then
    EXISTING_CONTENT=$(tail -n +2 "$CHANGELOG")
else
    EXISTING_CONTENT=""
fi

# Write the new changelog file.
echo -e "${HEADING}\n\n${CHANGELOG_ENTRY}\n${EXISTING_CONTENT}" > "$CHANGELOG"

echo "CHANGELOG.md updated for version ${NEW_VERSION}"
