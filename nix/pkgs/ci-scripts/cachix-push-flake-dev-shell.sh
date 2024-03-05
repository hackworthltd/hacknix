# https://docs.cachix.org/pushing#id1

usage () {
    program=$(basename "$0")
    echo "Usage: $program PROFILE_NAME CACHIX_CACHE_NAME" >&2
    echo >&2
    echo "Push a Nix flake's devShell to Cachix." >&2
    echo >&2
    echo "Note that the PROFILE_NAME is just used for caching, and can be valid Nix profile name." >&2
}

if [ "$#" -ne 2 ]; then
    usage
    exit 1
fi

PROFILE_NAME="$1"
CACHIX_CACHE_NAME="$2"

if [[ ! -v CACHIX_AUTH_TOKEN ]]; then
    # On macOS, where we can't easily set environment variables on
    # Buildkite jobs, CACHIX_AUTH_TOKEN is very likely to be unset, so
    # we fall back to a file path where we expect the token to be
    # stored by Vault.
    CACHIX_AUTH_TOKEN_FILE="$HOME/cachix-$CACHIX_CACHE_NAME"
    if [[ -f "$CACHIX_AUTH_TOKEN_FILE" ]]; then
        CACHIX_AUTH_TOKEN=$(tr -d '\n' < "$CACHIX_AUTH_TOKEN_FILE")
        export CACHIX_AUTH_TOKEN
    else
        echo "CACHIX_AUTH_TOKEN environment variable is not set and no token file can be located, aborting." >&2
        exit 2
    fi
fi

nix develop --print-build-logs --profile "$PROFILE_NAME" --command echo "done"
cachix push "$CACHIX_CACHE_NAME" "$PROFILE_NAME"
