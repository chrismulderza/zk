#!/bin/bash
#
# Manages versioning for the project.

set -euo pipefail

# Reads the version from the VERSION file and increments it.
#
# Arguments:
#   $1: The part of the version to bump (major, minor, or patch).
#
main() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <major|minor|patch>" >&2
        return 1
    fi

    local part="$1"
    local version
    version=$(cat VERSION)

    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"

    case "$part" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo "Error: Invalid part '$part'. Must be one of major, minor, or patch." >&2
            return 1
            ;;
    esac

    local new_version="$major.$minor.$patch"
    echo "$new_version" > VERSION
    echo "Version bumped to $new_version"
}

main "$@"
