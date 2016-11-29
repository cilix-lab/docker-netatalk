#!/bin/bash

set -o nounset # treat unset variables as errors

# share options:
# <name>;<path>;[rolist;rwlist;guest;users;tmach]
share() { local share="$1" path="$2" rolist=${3:-""} rwlist=${4:-""}\
                guest=${5:-yes} users=${6:-""} tmach=${7:-no}

    echo "Adding Netatalk share: $share."

    # Netatalk config
    file=/etc/afp.conf
    echo >> $file
    [ ! -d "$path" ] && mkdir -p "$path"
    sed -i "/\\[$share\\]/,/^\$/d" $file
    echo "[$share]" >> $file
    echo "   path = $path" >> $file
    [ "$rolist" != "" ] && echo "   rolist = $(tr ',' ' ' <<< $rolist)" >> $file
		[ "$rwlist" != "" ] && echo "   rwlist = $(tr ',' ' ' <<< $rwlist)" >> $file
    [ "$guest" == "no" ] && echo "   uam list = uams_dhx.so,uams_dhx2.so" >> $file
    [[ ${users:-""} ]] && echo "   valid users = $(tr ',' ' ' <<< $users)" >> $file
    [ "$tmach" == "yes" ] && echo "   time machine = $tmach" >> $file
    echo -e "" >> $file

    # Set permissions if p flag used
    if $permissions; then

      echo "Checking permissions for $share..."

      chmod u+rwx,g+rwx,o+rwx "$path"
      find "$path" -type d \( ! -perm -u+rwx -o ! -perm -g+rx -o ! -perm -o+rx \) \
        -exec chmod u+rwx,g+rx,o+rx {} \;
      find "$path" -type f \( ! -perm -u+rw -o ! -perm -g+r -o ! -perm -o+r \) \
        -exec chmod u+rw,g+r,o+r {} \;

    fi
}

# user options:
# <name>;<password>;[uid;group]
user() { local name="${1}" passwd="${2}" uid="${3:-}" gid="${4:-}"
    local ua_args=""

    [ "$uid" ] && ua_args="$ua_args -o -u $uid"
    [ "$gid" ] && ua_args="$ua_args -g $gid" &&\
      ! cat /etc/group | grep -q "$gid" && group "$name" "$gid"

    echo "Adding user: $name."

    useradd "$name" -M $ua_args || usermod $ua_args "$name"
    [ "$passwd" ] && echo "$name:$passwd" | chpasswd

}

# group options:
# <groupname>;[gid]
group() { local name="${1}" gid="${2:-}"
    local ua_args=""

    echo "Adding group: $name."

    [ "$gid" ] && ua_args="$ua_args -o -g $gid"
    groupadd "$name" $ua_args || groupmod $ua_args "$name"
}

usage() { local RC=${1:-0}
    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -h          This help
    -p          Set file and directory permissions for shared folders
    -s \"<name;/path>[;rolist;rwlist;guest;users;time-machine]\" Configure a share
                required arg: \"<name>;</path>\"
                <name> is how it's called for clients
                <path> path to share
                [rolist] read only users default: 'none' or list of users
                [rwlist] read/write users default: 'none' or list of users
                [guest] allowed default:'yes' or 'no'
                [users] allowed default:'all' or list of allowed users
                [time-machine] allowed default:'no' or 'yes'
    -u \"<username;password>[;uid;group]\" Add a user
                required arg: \"<username>;<passwd>\"
                <username> for user
                <password> for user
                [uid] user id
                [group] primary group or group id
    -g \"<groupname>[;gid]\" Add a group.

The 'command' (if provided and valid) will be run instead of Netatalk.
" >&2
    exit $RC
}

permissions=false # default to not setting permissions
optstring=":hpg:u:s:"

# First loop to get permissions flag and adding groups
while getopts "$optstring" opt; do
	case "$opt" in
		h) usage ;;
    p) permissions=true ;; # set permissions if p flag used
    g) eval group $(sed 's/^\|$/"/g; s/;/" "/g' <<< $OPTARG) ;;
		"?") echo "Unknown option: -$OPTARG"; usage 1 ;;
		":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
	esac
done

# Second loop for users and shares
OPTIND=1
while getopts "$optstring" opt; do
	case "$opt" in
    u) eval user $(sed 's/^\|$/"/g; s/;/" "/g' <<< $OPTARG) ;;
		s) eval share $(sed 's/^\|$/"/g; s/;/" "/g' <<< $OPTARG);;
	esac
done
shift $(( OPTIND - 1 ))

if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
  exec "$@"
elif [[ $# -ge 1 ]]; then
  echo "ERROR: command not found: $1"
  exit 13
elif ps -ef | egrep -v grep | grep -q netatalk; then
    echo "Service already running, please restart container to apply changes"
else
    echo "Starting Netatalk... "
    exec ionice -c 3 netatalk -d
fi
