Nook Home Manager - multiple Git repositories in $HOME

A fork of vcsh (https://github.com/RichiH/vcsh). The command is `nook`. Everything
lives under `~/.config/nook/` -- one `<name>.nook/` directory per repo; nothing
is created in `$HOME`.


# Index

1. [30 Second How-to](#30-second-how-to)
2. [Introduction](#introduction)
3. [Usage Examples](#usage-examples)
4. [Overview](#overview)
5. [Getting Started](#getting-started)
6. [Contact](#contact)


# 30 Second How-to

While it may appear that there's an overwhelming amount of documentation and
while the explanation of the concepts behind `nook` needs to touch a few gory
details of `git` internals, getting started with `nook` is extremely simple.

Let's say you want to version control your `vim` configuration:

    nook init vim
    nook vim add ~/.vimrc ~/.vim
    nook vim commit -m 'Initial commit of my Vim configuration'
    # optionally push your files to a remote
    nook vim remote add origin <remote>
    nook vim push -u origin main
    # from now on you can push additional commits like this
    nook vim push

If all that looks a _lot_ like standard `git`, that's no coincidence; it's
a design feature.


# Introduction

[nook][nook] allows you to maintain several Git repositories in one single
directory. They all maintain their working trees without clobbering each other
or interfering otherwise. By default, all Git repositories maintained via
`nook` store the actual files in `$HOME` but you can override this setting if
you want to.

All this means that you can have one repository per application or application
family, i.e. `zsh`, `vim`, `ssh`, etc. This, in turn, allows you to clone
custom sets of configurations onto different machines or even for different
users; picking and mixing which configurations you want to use where.
For example, you may not need to have your `mplayer` configuration on a server
or available to root and you may want to maintain different configuration for
`ssh` on your personal and your work machines.

See [INSTALL.md](INSTALL.md) for how to install `nook`.

## Talks

Some people found it useful to look at slides and videos explaining how `nook`
works instead of working through the docs.
All slides, videos, and further information can be found
[on the author's talk page][talks].


# Usage Examples

The common way to work with a repo is `nook <repo> <git command>`, shown below.
`nook enter <repo>` (a shell with `$GIT_DIR` set) and `nook run <repo> <cmd>`
are covered in nook(1).


| Task                                                  | Command                                           |
| ----------------------------------------------------- | ------------------------------------------------- |
| _Initialize a new repository called "vim"_            |   `nook init vim`                                 |
| _Clone an existing repository_                        |   `nook clone <remote> <repository_name>`         |
| _Add files to repository "vim"_                       |   `nook vim add ~/.vimrc ~/.vim`                  |
|                                                       |   `nook vim commit -m 'Update Vim configuration'` |
| _Add a remote for repository "vim"_                   |   `nook vim remote add origin <remote>`           |
|                                                       |   `nook vim push origin main:main`            |
|                                                       |   `nook vim branch --track main origin/main`  |
| _Push to remote of repository "vim"_                  |   `nook vim push`                                 |
| _Pull from remote of repository "vim"_                |   `nook vim pull`                                 |
| _Show status of changed files in all repositories_    |   `nook status`                                   |
| _Pull from all repositories_                          |   `nook pull`                                     |
| _Push to all repositories_                            |   `nook push`                                     |


# Overview

## From zero to nook

You put a lot of effort into your configuration and want to both protect and
distribute this configuration.

Most people who decide to put their dotfiles under version control start with a
single repository in `$HOME`, adding all their dotfiles (and possibly more)
to it. This works, of course, but can become a nuisance as soon as you try to
manage more than one host.

The next logical step is to create single-purpose repositories in, for example,
`~/.dotfiles` and to create symbolic links into `$HOME`. This gives you the
flexibility to check out only certain repositories on different hosts. The
downsides of this approach are the necessary manual steps of cloning and
symlinking the individual repositories.

`nook` takes this approach one step further. It enables single-purpose
repositories and stores them in a hidden directory. However, it does not create
symbolic links in `$HOME`; it puts the actual files right into `$HOME`.

As `nook` allows you to put an arbitrary number of distinct repositories into
your `$HOME`, you will end up with a lot of repositories very quickly.

`nook` has a built-in bootstrap. You populate
`~/.config/nook/.repos` -- one line per repo, `<name> <url> <branch> @tags,` --
with **`nook add <repo> [<tags>]`** (or `nook add --all` to append every local
repo that has a remote and isn't listed yet). Nothing else writes that file;
`delete` and `rename` leave stale lines for you to edit out.

Tags are an optional comma-separated list written after the branch, always
stored with a leading `@` and a trailing `,` (`nook add nvim laptop,work` ->
`nvim <url> main @laptop,work,`). A tagged row is **opt-in**: it clones only
when one of its tags is passed via `nook bootstrap --include=laptop` -- or the
shorthand `nook bootstrap @laptop` (a bare `@tag` / `@a,b` positional means
`--include`). A bare `nook bootstrap` clones the untagged rows only;
`--exclude` always wins. The `@` is optional wherever you type a tag -- on
`add`, `--include`/`--exclude`, and the `@tag` positional it's just the
column delimiter in the file.

Track the file in one of your repos. On a new machine, clone that repo and run
`nook bootstrap` (or `nook clone --all` / `-a` / `@<tags>` -- with `clone`,
that word must come first), and every other repo in the list is cloned for you.

    nook add --all
    nook dotfiles add -f ~/.config/nook/.repos
    nook dotfiles commit -m 'track repo list' && nook dotfiles push

    # on a new machine, after installing nook:
    nook clone <url-of-the-repo-holding-.repos> dotfiles
    nook bootstrap

`nook pull` / `nook push` / `nook status` then operate on the whole set.
Repositories that are not `nook` repos (a plain `~/src/project`, work
checkouts) are out of scope; use a separate tool for those if you need it.

## Directory layout

Everything `nook` uses lives under `$XDG_CONFIG_HOME/nook/`
(`~/.config/nook/` by default). **Nothing is created in `$HOME`** except the
tracked files themselves.

    ~/.config/nook/
        .nookrc               # optional: shell rc sourced on every run (NOOK_* vars)
        .gitconfig              # git config included by every repo (edit: nook config ...)
        .gitignore              # shared fallback ignore file (seeded with '*')
        .gitattributes          # shared fallback attributes file
        .repos                  # repo list for `bootstrap` (curate with `nook add`)
        hooks/                  # optional: hook scripts
        overlays/               # optional: function overrides
        <name>.nook/          # one directory per repo, containing:
            <name>.git/         #   the git directory
            .nookrc           #   optional: shell rc sourced when acting on this repo
            .gitignore          #   optional: per-repo ignore file
            .gitattributes      #   optional: per-repo attributes file

Each `<name>.git` is an ordinary git directory with `core.worktree` set to
`$HOME` and `core.bare` false, so the working files land straight in `$HOME`;
`nook` never creates symlinks. `upgrade` sets `core.excludesfile` /
`core.attributesfile` to the per-repo file in `<name>.nook/` if it exists,
otherwise to the shared `~/.config/nook/.gitignore` /
`~/.config/nook/.gitattributes` (see `$NOOK_GITIGNORE`). Unlike vcsh, these
files are **not** tracked by the repo and do not clone to other machines --
regenerate with `nook write-gitignore <repo>` if you want a per-repo one.

The shared `~/.config/nook/.gitignore` is seeded with a single `*`, so
`git add .` in a nook repo can't sweep up all of `$HOME`. To spare you a
`-f` on every deliberate add, `nook <repo> add <path>` supplies `-f`
automatically **when that catch-all `*` is the only thing in the way**. A
path matched by a real rule (a line you wrote in `<name>.nook/.gitignore`,
`.git/info/exclude`, ...) is **not** force-added -- git's normal "use -f"
refusal still stands, so a deliberate ignore is never bypassed. The implicit
`-f` is skipped for bulk forms (`nook <repo> add .` / `-A` / `-u` / `-n`
...), when you pass `-f` yourself, and when `NOOK_ADD_FORCE=no`.

`nook` refuses to overwrite an existing file: if a checkout would clobber
something already in `$HOME`, it warns and exits. Move the old file aside and
retry, then merge and `nook <name> push`.


# Getting Started

Install `nook` -- see [INSTALL.md](INSTALL.md). Then:

    nook init zsh                          # new repo
    nook zsh add ~/.zshrc                  # track files
    nook zsh commit -m 'initial zsh config'
    nook zsh remote add origin <url>
    nook zsh push -u origin main

Day to day:

    nook zsh add -u && nook zsh commit -m '...' && nook zsh push
    nook pull       # every repo that has a remote
    nook push
    nook status     # every repo

## New machine

    # install nook, then:
    nook clone <url-of-repo-holding-.repos> dotfiles
    nook bootstrap                                   # clone the untagged rows
    nook bootstrap @laptop                           # ...plus the @laptop rows
    nook bootstrap --include=laptop --exclude=work   # ...long form, with excludes

You curate `.repos` yourself with `nook add`; nothing writes it automatically.


# Contact

* Issues and pull requests: <https://github.com/stevensko/nook>
* Upstream project (vcsh): <https://github.com/RichiH/vcsh>

[talks]: http://richardhartmann.de/talks/
[nook]: https://github.com/stevensko/nook
[vcs-home-list]: http://lists.madduck.net/listinfo/vcs-home
