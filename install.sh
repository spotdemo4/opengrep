#!/usr/bin/env bash 
set -euo pipefail
# Opengrep installation script

print_usage() {

    echo "Usage:"
    echo "install.sh  -v version   Specify version to install (optional, default: latest) warns if you cannot verify signatures"
    echo "install.sh  -v version --verify-signatures   Specify version to install (optional, default: latest) failing if you cannot verify signatures "
    echo "install.sh  -l    List available versions (latest 3)"
    echo "install.sh  -h    Show this help message"
}

# Function to get available versions - already checked when running main
get_available_versions() {
    command -v curl > /dev/null 2>&1 || {
        echo >&2 "Required tool curl could not be found. Aborting."
        exit 1
    }
    curl -s https://api.github.com/repos/opengrep/opengrep/releases | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Function to validate version
validate_version() {
    local VERSION="$1"
    local AVAILABLE_VERSIONS
    AVAILABLE_VERSIONS=$(get_available_versions)
    if echo "$AVAILABLE_VERSIONS" | grep -q "^$VERSION$"; then
        return 0
    else
        echo "Error: Version $VERSION not found"
        echo "Available versions (latest 3):"
        echo "$AVAILABLE_VERSIONS" | head -3
        exit 1
    fi
}
validate_signature() {
    local P="$1"
    if $HAS_COSIGN; then

        echo "Verifying signatures for ${P}/opengrep.cert"
        if cosign verify-blob \
            --cert "$P/opengrep.cert" \
            --signature "${P}/opengrep.sig" \
            --certificate-identity-regexp "https://github.com/opengrep/opengrep.+" \
            --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
            "${P}/opengrep"; then
            echo "Signature valid."
            exit 0
        else
            if [[ "$VERIFY_SIGNATURES" == true ]]; then
                echo "Error: Signature validation error. Deleting downloaded package"
                rm -rf "${P}"
                exit 1
            else
                echo "Warning  Signature validation error; the package is still installed."
                echo "If this was not intended, delete and rerun with --verify-signatures"
                exit 0
            fi
        fi
    fi
}

main() {
    local VERSION="$1"
    local VERIFY_SIGNATURES="$2"
    PREFIX="${HOME}/.opengrep/cli"
    INST="${PREFIX}/${VERSION}"
    LATEST="${PREFIX}/latest"

    OS="${OS:-$(uname -s)}"
    ARCH="${ARCH:-$(uname -m)}"
    DIST=""

    command -v curl > /dev/null 2>&1 || {
        echo >&2 "Required tool curl could not be found. Aborting."
        exit 1
    }

    # check and set "os_arch"
    if [ "$OS" = "Linux" ]; then
        if ldd --version 2>&1 | grep -qi musl; then
            if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
                DIST="opengrep_musllinux_x86"
            elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
                DIST="opengrep_musllinux_aarch64"
            fi
        else
            if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
                DIST="opengrep_manylinux_x86"
            elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
                DIST="opengrep_manylinux_aarch64"
            fi
        fi
    elif [ "$OS" = "Darwin" ]; then
        if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
            DIST="opengrep_osx_x86"
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            DIST="opengrep_osx_arm64"
        fi
    fi

    if [ -z "${DIST}" ]; then
        echo "Operating system '${OS}' / architecture '${ARCH}' is unsupported." 1>&2
        exit 1
    fi

    URL="https://github.com/opengrep/opengrep/releases/download/${VERSION}/${DIST}"
    echo
    echo "*** Installing Opengrep ${VERSION} for ${OS} (${ARCH}) ***"
    

    # check if binary already exists
    if [ -f "${INST}/opengrep" ]; then
        echo "Destination binary ${INST}/opengrep already exists."
    else
        mkdir -p "${INST}"
        if [ ! -d "${INST}" ]; then
            echo "Failed to create install directory ${INST}." 1>&2
            exit 1
        fi

        curl --fail --location --progress-bar "${URL}" > "${INST}/opengrep"
        curl --fail --location --progress-bar "${URL}.cert" > "${INST}/opengrep.cert"
        curl --fail --location --progress-bar "${URL}.sig" > "${INST}/opengrep.sig"

        # check signature

        validate_signature "${INST}"

        # make executable by all users
        chmod a+x "${INST}/opengrep" || exit 1

        if [ ! -f "${INST}/opengrep" ]; then
            echo "Failed to download binary at ${INST}/opengrep" 1>&2
            exit 1
        fi

        # Test by calling --version on the downloaded binary
        TEST=$("${INST}/opengrep" --version 2> /dev/null || true)
        if [ -z "$TEST" ]; then
            echo "Failed to execute installed binary: ${INST}/opengrep." 1>&2
            exit 1
        fi

        echo
        echo "Successfully installed Opengrep binary at ${INST}/opengrep"

        rm -f "${LATEST}" || exit 1
        ln -s "${INST}" "${LATEST}" || exit 1
        echo "with a symlink from ${LATEST}/opengrep"
    fi

    LOCALBIN="${HOME}/.local/bin"

    # Only need to create the symlink from .local/bin once if not created before.
    # For all subsequent installations, the ./local/bin symlink will still point
    # to the updated symlink (created above).
    if [ -d "${LOCALBIN}" ] && [ -w "${LOCALBIN}" ]; then
        # Only create the symlink if it doesn't already exist
        if [ ! -f "${LOCALBIN}/opengrep" ]; then
            ln -s "${LATEST}/opengrep" "${LOCALBIN}/opengrep"
            echo "Created symlink from ${LOCALBIN}/opengrep to ${LATEST}/opengrep"
        fi

        echo
        echo "To launch Opengrep now, type:"
        # Do not assume that ~/.local/bin is in the PATH even if it exists,
        # as it is not always the case.
        if echo "$PATH" | tr ':' '\n' | grep -Fxq "$HOME/.local/bin"; then
            echo "opengrep"
        else
            echo "${LOCALBIN}/opengrep"
        fi
        echo
    else
        echo
        echo "To launch Opengrep now, type:"
        echo "${LATEST}/opengrep"
        echo
        echo "Hint: Append the following line to your shell profile:"
        echo "export PATH='${LATEST}':\$PATH"
        echo
    fi
}

# Argument parsing
if command -v cosign &> /dev/null; then
    HAS_COSIGN=true
else
    HAS_COSIGN=false
fi

HELP=false
LIST=false
VERIFY_SIGNATURES=false
VERSION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h)
            HELP=true
            shift
            ;;
        -l)
            LIST=true
            shift
            ;;
        --verify-signatures)
            VERIFY_SIGNATURES=true
            shift
            ;;
        -v)
            if [[ -n "$2" && "$2" != -* ]]; then
                VERSION="$2"
                shift 2
            else
                echo "Error: -v requires a version argument"
                exit 1
            fi
            ;;
        *)
            echo "Error: Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

if { { $VERIFY_SIGNATURES || [[ -n "$VERSION" ]] || $LIST; } && $HELP; } || { { $VERIFY_SIGNATURES || [[ -n "$VERSION" ]] || $HELP; } && $LIST; }; then
    echo "Error: incorrect arguments:"
    print_usage
    exit 1

fi

if $VERIFY_SIGNATURES && ! $HAS_COSIGN; then
    echo "Error: cosign is required for --verify-signatures but not installed."
    echo "Go to https://github.com/sigstore/cosign to install or run without the --verify-signatures flag to install without verifying."
    exit 1
elif ! $HAS_COSIGN; then
    echo "Warning: cosign is required for --verify-signatures but not installed. Skipping signature validation"
    echo "Go to https:/github.com/sigstore/cosign to install."
fi


if "$HELP"; then
    print_usage
    exit 0
fi

if $LIST; then
    echo "Available versions (latest 3):"
    get_available_versions | head -3
    exit 0
fi

shift $((OPTIND - 1))

if [ -z "$VERSION" ]; then
    VERSION=$(get_available_versions | head -1)
else
    validate_version "$VERSION"
fi

main "$VERSION" "$VERIFY_SIGNATURES"
