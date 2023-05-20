# https://docs.cachix.org/pushing#pushing-flake-inputs

usage () {
    program=$(basename "$0")
    echo "Usage: $program FLAKE CACHIX_CONFIG_PATH CACHIX_CACHE_NAME" >&2
    echo >&2
    echo "Archive a Nix flake's inputs to Cachix." >&2
    echo >&2
}

if [ "$#" -ne 3 ]; then
    usage
    exit 1
fi

FLAKE="$1"
CACHIX_CONFIG_PATH="$2"
CACHIX_CACHE_NAME="$3"

if [ ! -f "$CACHIX_CONFIG_PATH" ]; then
    echo "Cachix config file not found: $CACHIX_CONFIG_PATH" >&2
    exit 2
fi

nix flake archive --json "$FLAKE" \
  | jq -r '.path,(.inputs|to_entries[].value.path)' \
  | cachix --config "$CACHIX_CONFIG_PATH" push "$CACHIX_CACHE_NAME"
