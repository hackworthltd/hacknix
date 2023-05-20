# https://docs.cachix.org/pushing#pushing-build-and-runtime-dependencies

usage () {
    program=$(basename "$0")
    echo "Usage: $program ATTR_PATH CACHIX_CONFIG_PATH CACHIX_CACHE_NAME" >&2
    echo >&2
    echo "Push build and runtime dependencies of a Nix attribute to Cachix." >&2
    echo >&2
}

if [ "$#" -ne 3 ]; then
    usage
    exit 1
fi

ATTR_PATH="$1"
CACHIX_CONFIG_PATH="$2"
CACHIX_CACHE_NAME="$3"

if [ ! -f "$CACHIX_CONFIG_PATH" ]; then
    echo "Cachix config file not found: $CACHIX_CONFIG_PATH" >&2
    exit 2
fi

# shellcheck disable=SC2046
nix-store -qR --include-outputs $(nix-store -qd $(nix-build -A "$ATTR_PATH")) \
 | grep -v '\.drv$' \
 | cachix --config "$CACHIX_CONFIG_PATH" push "$CACHIX_CACHE_NAME"
