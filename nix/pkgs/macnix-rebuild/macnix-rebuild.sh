set -euo pipefail

usage() {
    echo "usage: macnix-rebuild [options] <cmd> ..."                                        1>&2
    echo ""                                                                                 1>&2
    echo "OPTIONS:"                                                                         1>&2
    echo ""                                                                                 1>&2
    echo "  -c PATH             Specify the path to the darwin-config file. If this option" 1>&2
    echo  "                     is not specified, the value of the environment variable"    1>&2
    echo  "                     DARWIN_CONFIG will be used."                                1>&2
    echo ""                                                                                 1>&2
    echo "Any arguments after <cmd> will be passed to 'darwin-rebuild <cmd>'"               1>&2
    exit 1
}

while getopts "c:" opt; do
    case "${opt}" in
        c)
            darwin_config=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

[[ $# -gt 0 ]] || usage

if [ -z ${darwin_config+x} ] ; then
    if [ -z ${DARWIN_CONFIG+x} ] ; then
        echo "DARWIN_CONFIG environment variable is not set and you didn't specify a config file option" 1>&2
        echo "" 1>&2
        usage
    else
        darwin_config=${DARWIN_CONFIG}
    fi
fi

nix_darwin_config=$(dirname "$darwin_config")/..
darwin_rebuild_cmd="$1"
shift

[[ -f "$darwin_config" ]] || (echo "$darwin_config is not a valid darwin-config config file." && exit 1)
[[ -d "$nix_darwin_config/lib" ]] || (echo "$nix_darwin_config does not appear to be a valid nix-darwin-config repo," && echo "because $nix_darwin_config/lib does not exist" && exit 1)

set_nix_path() {
    unset NIX_PATH

    nixpkgs=$(nix eval -f $nix_darwin_config/lib fixedNixpkgs.url | tr -d \")
    echo "Using nixpkgs=$nixpkgs"
    export NIX_PATH="nixpkgs=$nixpkgs"

    darwin=$(nix eval -f $nix_darwin_config/lib fixedNixDarwin.url | tr -d \")
    echo "Using darwin=$darwin"
    export NIX_PATH="$NIX_PATH:darwin=$darwin"

    echo "Using darwin-config=$darwin_config"
    export NIX_PATH="$NIX_PATH:darwin-config=$darwin_config"

    echo "Using nix-darwin-config=$nix_darwin_config"
    export NIX_PATH="$NIX_PATH:nix-darwin-config=$nix_darwin_config"
}

case "$darwin_rebuild_cmd" in
    *)
        set_nix_path
        darwin-rebuild $darwin_rebuild_cmd $*
    ;;
esac

exit 0
