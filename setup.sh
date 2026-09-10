#!/usr/bin/env bash
# Renamed to install.sh, to match https://github.com/sarsanaee/dot_tmux.
# Kept as a forwarder so an old command line still works.
echo "setup.sh is now install.sh — forwarding..." >&2
exec "$(dirname -- "${BASH_SOURCE[0]}")/install.sh" "$@"
