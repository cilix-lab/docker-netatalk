# This repository is no longer mantained.

# Netatalk Docker Image

This docker image is designed to make it easy to run an AFP server with Netatalk 3.1.10.

# How to use this image

There are no shares configured by default.

You can start with:

```bash
  docker run -it --rm cilix/netatalk -h

  Usage: afpd.sh [-opt] [command]
  Options (fields in '[]' are optional, '<>' are required):
      -h          This help
      -p          Set file and directory permissions for shared folders
      -s <name;/path>[;rolist;rwlist;guest;users;time-machine] Configure a share
                  required arg: <name>;</path>
                  <name> is how it's called for clients
                  <path> path to share
                  [rolist] read only users default: 'none' or list of users
                  [rwlist] read/write users default: 'none' or list of users
                  [guest] allowed default:'yes' or 'no'
                  [users] allowed default:'all' or list of allowed users
                  [time-machine] allowed default:'no' or 'yes'
      -u <username;password>[;uid;group] Add a user
                  required arg: <username>;<passwd>
                  <username> for user
                  <password> for user
                  [uid] user id
                  [group] primary group or group id
      -g <groupname>[;gid] Add a group.

  The 'command' (if provided and valid) will be run instead of Netatalk.

```

## Hosting an AFP server with Netatalk

To host an AFP server with this container, you can run:

```bash
  docker run -it -p 548:548 cilix/netatalk -s "Shared;/shares"
```

This will create a share for the /shares folder in the container. It will be accessible with read only access by the guest user.

To set local storage:

```bash
  docker run -it -p 548:548 -v "<local-folder>:/shares" cilix/netatalk -s "Shared;/shares"
```

## Configuration and examples

To further setup the server, follow the help provided with the -h flag.

For instance, to set up three shares with read/write access for the user 'user1' and 'user2' and read access to the guest user 'nobody', run:

```bash
  docker run -it -p 548:548 \
    -v "/media/documents:/shares/documents" \
    -v "/media/music:/shares/music" \
    -v "/media/movies:/shares/movies" \
    cilix/netatalk \
    -u "user1;password1" \
    -u "user2;password2" \
    -s "Documents;/shares/documents;nobody;user1,user2;yes" \
    -s "Music;/shares/music;nobody;user1,user2;yes" \
    -s "Movies;/movies/documents;nobody;user1,user2;yes"
```

If you wish to detach from the running container, use ^P ^Q or start detached using the docker run -d flag.

# Important notice

Netatalk does not provide any more access rights than the ones provided by the system, so make sure proper permissions are set. The container allows you to add specific users and setup their UID and GID to match your system.

If the -p flag is provided, when starting up the container, it will make sure that at least there is read/write/execute permissions for the user, read/execute for group and others, in case of directories, and read/write permissions for the user, read permissions for group and others, in case of files. Just provide the -p flag:

```bash
  docker run -it -p 548:548 \
    -v "/media/documents:/shares/documents" \
    -v "/media/music:/shares/music" \
    -v "/media/movies:/shares/movies" \
    cilix/netatalk \
    -p \
    -u "user;password" \
    -s "Documents;/shares/documents;nobody;user;yes" \
    -s "Music;/shares/music;nobody;user;yes" \
    -s "Movies;/movies/documents;nobody;user;yes"
```

# Feedback

If you find any issues with the container, please contact me through github (https://github.com/cilix-lab/docker-netatalk/issues).
