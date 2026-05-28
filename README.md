# local-repo

A small bash tool for solo developers who want the versioning of git but
self-hosted on a server they control (NAS, VPS, home Pi) and reached over SSH —
no GitHub, no GitLab, no third party.

It manages bare git repos on the remote and prints the remote URL ready to
paste into `git remote add origin ...`.

## Install

The script reads `local-repo.conf` from its own directory, so the cleanest
install is **clone + symlink** rather than copying the script into `~/.local/bin`:

```
git clone <this-repo-url> ~/projects/local-repo
ln -s ~/projects/local-repo/local-repo ~/.local/bin/local-repo
```

The symlink lets `local-repo` be on your `PATH` while the script still finds
its config next to the real file in the cloned directory.

(If you'd rather copy the script outright, copy `local-repo.conf.example` to
the same target directory as the script and rename it to `local-repo.conf`.)

### Optional: `lr` alias

Add to your `~/.bashrc` or `~/.zshrc`:

```
alias lr='local-repo'
```

### Optional: tab completion

Add to your `~/.bashrc`:

```
source ~/projects/local-repo/completion/local-repo.bash
```

Completes subcommands, `config` keys, and `delete -f`. Works for both
`local-repo` and the `lr` alias.

## Setup

You need passwordless SSH to your server (`ssh-copy-id user@host`).

Configure the connection:

```
local-repo config set user <username>
local-repo config set host <hostname-or-ip>
local-repo config set port <port>          # optional, default 22
local-repo config set repos-dir <dir>      # optional, default "repos"
```

This writes `local-repo.conf` next to the script. You can also copy
`local-repo.conf.example` and edit it by hand. The personal `.conf` is
gitignored.

Check it works:

```
local-repo status
```

## Usage

```
local-repo create <name>         # create bare repo at ~/<repos-dir>/<name>.git
local-repo list                  # list bare repos with disk sizes  (alias: ls)
local-repo delete <name> [-f]    # delete a repo (prompts unless -f) (alias: rm)
local-repo url <name>            # print the git remote URL for <name>
local-repo status                # show SSH connection status and current config
local-repo config                # show / change settings (see below)
```

After `create`, the script prints the remote URL ready to paste:

```
git remote add origin <user>@<host>:~/<repos-dir>/<name>.git
```

If a non-default SSH port is configured, the URL uses the `ssh://` form:

```
git remote add origin ssh://<user>@<host>:<port>/~/<repos-dir>/<name>.git
```

A trailing `.git` in `<name>` is stripped automatically. Names are restricted
to letters, digits, `.`, `_`, `-`.

## Config

```
local-repo config                   # show current settings
local-repo config set <key> <val>   # set a value (writes local-repo.conf)
local-repo config unset <key>       # clear a value
local-repo config path              # print path to config file
```

Keys: `user`, `host`, `port`, `repos-dir`.

The config file is plain bash and lives next to the script (`local-repo.conf`).
You can edit it by hand if you prefer — the format matches
`local-repo.conf.example`.

## License

MIT. See [LICENSE](LICENSE).
