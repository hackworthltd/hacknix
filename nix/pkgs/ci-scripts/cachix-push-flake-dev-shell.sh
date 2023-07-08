# https://docs.cachix.org/pushing#id1

usage () {
    program=$(basename "$0")
    echo "Usage: $program PROFILE_NAME CACHIX_CONFIG_PATH CACHIX_CACHE_NAME" >&2
    echo >&2
    echo "Push a Nix flake's devShell to Cachix." >&2
    echo >&2
    echo "Note that the PROFILE_NAME is just used for caching, and can be valid Nix profile name." >&2
}

if [ "$#" -ne 3 ]; then
    usage
    exit 1
fi

PROFILE_NAME="$1"
CACHIX_CONFIG_PATH="$2"
CACHIX_CACHE_NAME="$3"

if [ ! -f "$CACHIX_CONFIG_PATH" ]; then
    echo "Cachix config file not found: $CACHIX_CONFIG_PATH" >&2
    exit 2
fi

nix develop --print-build-logs --profile "$PROFILE_NAME" --command echo "done"
cachix --config "$CACHIX_CONFIG_PATH" push "$CACHIX_CACHE_NAME" "$PROFILE_NAME"