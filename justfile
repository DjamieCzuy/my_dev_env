# First one is run by default if no command is given
@_default:
    just --list

check_tools *ARGS:
    #!/usr/bin/env bash
    ./bin/check_tools.sh
