# https://docs.cachix.org/pushing#pushing-build-and-runtime-dependencies

usage () {
    program=$(basename "$0")
    echo "Usage: $program ATTR_PATH CACHIX_CACHE_NAME" >&2
    echo >&2
    echo "Push build and runtime dependencies of a Nix attribute to Cachix." >&2
    echo >&2
}

if [ "$#" -ne 2 ]; then
    usage
    exit 1
fi

ATTR_PATH="$1"
CACHIX_CACHE_NAME="$2"

if [[ ! -v CACHIX_AUTH_TOKEN ]]; then
    echo "CACHIX_AUTH_TOKEN environment variable is not set, aborting."
    exit 2
fi

# shellcheck disable=SC2046
nix-store -qR --include-outputs $(nix-store -qd $(nix-build -A "$ATTR_PATH")) \
 | grep -v '\.drv$' \
 | cachix push "$CACHIX_CACHE_NAME"
