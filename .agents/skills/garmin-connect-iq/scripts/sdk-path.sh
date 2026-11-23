#!/bin/sh
# Print the active SDK root without altering SDK Manager or shell configuration.
set -eu

if [ -n "${CIQ_SDK:-}" ]; then
    sdk_root=$CIQ_SDK
else
    case "$(uname -s)" in
        Darwin) sdk_config="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg" ;;
        Linux) sdk_config="$HOME/.Garmin/ConnectIQ/current-sdk.cfg" ;;
        *) printf '%s\n' 'Set CIQ_SDK to the SDK root; see toolchain.md for Windows.' >&2; exit 1 ;;
    esac
    if [ ! -r "$sdk_config" ]; then
        printf 'Cannot read SDK Manager config: %s\nSet CIQ_SDK to an installed SDK root.\n' "$sdk_config" >&2
        exit 1
    fi
    sdk_root=$(tr -d '\r\n' < "$sdk_config")
fi

if [ -z "$sdk_root" ] || [ ! -f "$sdk_root/bin/monkeybrains.jar" ] || [ ! -f "$sdk_root/bin/monkeyc" ]; then
    printf 'Invalid Connect IQ SDK root: %s\n' "$sdk_root" >&2
    exit 1
fi
printf '%s\n' "${sdk_root%/}"
