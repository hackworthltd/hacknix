# https://docs.cachix.org/pushing#pushing-flake-inputs

usage () {
    program=$(basename "$0")
    echo "Usage: $program FLAKE CACHIX_CACHE_NAME" >&2
    echo >&2
    echo "Archive a Nix flake's inputs to Cachix." >&2
    echo >&2
}

if [ "$#" -ne 2 ]; then
    usage
    exit 1
fi

FLAKE="$1"
CACHIX_CACHE_NAME="$2"

if [[ ! -v CACHIX_AUTH_TOKEN ]]; then
    echo "CACHIX_AUTH_TOKEN environment variable is not set, aborting."
    exit 2
fi

nix flake archive --json "$FLAKE" \
  | jq -r '.path,(.inputs|to_entries[].value.path)' \
  | cachix push "$CACHIX_CACHE_NAME"
