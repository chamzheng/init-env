#!/bin/sh

SYSTEMD_EXE="/lib/systemd/systemd --system-unit=basic.target"
SYSTEMD_PID="$(ps -eo pid=,args= | awk '$2" "$3=="'"$SYSTEMD_EXE"'" {print $1}')"
if [ "$LOGNAME" != "root" ] && ( [ -z "$SYSTEMD_PID" ] || [ "$SYSTEMD_PID" != "1" ] ); then
    export | sed -e 's/^declare -x //;/^IFS=".*[^"]$/{N;s/\n//}' | \
        grep -E -v "^(BASH|BASH_ENV|DIRSTACK|EUID|GROUPS|HOME|HOSTNAME|\
IFS|LANG|LOGNAME|MACHTYPE|MAIL|NAME|OLDPWD|OPTERR|\
OSTYPE|PATH|PIPESTATUS|POSIXLY_CORRECT|PPID|PS1|PS4|\
SHELL|SHELLOPTS|SHLVL|SYSTEMD_PID|UID|USER|_)(=|\$)" > "$HOME/.systemd-env"
    export PRE_NAMESPACE_PATH="$PATH"
    export PRE_NAMESPACE_PWD="$(pwd)"
    exec sudo $HOME/.setup/enter-systemd-namespace.sh "$BASH_EXECUTION_STRING"
fi
if [ -n "$PRE_NAMESPACE_PATH" ]; then
    export PATH="$PRE_NAMESPACE_PATH"
    unset PRE_NAMESPACE_PATH
fi
if [ -n "$PRE_NAMESPACE_PWD" ]; then
    cd "$PRE_NAMESPACE_PWD"
    unset PRE_NAMESPACE_PWD
fi
