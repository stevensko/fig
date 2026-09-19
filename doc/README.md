conFig Files Manager - multiple Git repositories in $HOME

A fork of vcsh (https://github.com/RichiH/vcsh). The command is `fig`. Everything
lives under `~/.config/fig/` -- one `<name>.fig/` directory per repo; nothing
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
while the explanation of the concepts behind `fig` needs to touch a few gory
details of `git` internals, getting started with `fig` is extremely simple.

Let's say you want to version control your `vim` configuration:

    fig init vim
    fig vim add ~/.vimrc ~/.vim
    fig vim commit -m 'Initial commit of my Vim configuration'
    # optionally push your files to a remote
    fig vim remote add origin <remote>
    fig vim push -u origin main
    # from now on you can push additional commits like this
    fig vim push

If all that looks a _lot_ like standard `git`, that's no coincidence; it's
a design feature.


# Introduction

[fig][fig] allows you to maintain several Git repositories in one single
directory. They all maintain their working trees without clobbering each other
or interfering otherwise. By default, all Git repositories maintained via
`fig` store the actual files in `$HOME` but you can override this setting if
you want to.

All this means that you can have one repository per application or application
family, i.e. `zsh`, `vim`, `ssh`, etc. This, in turn, allows you to clone
custom sets of configurations onto different machines or even for different
users; picking and mixing which configurations you want to use where.
For example, you may not need to have your `mplayer` configuration on a server
or available to root and you may want to maintain different configuration for
`ssh` on your personal and your work machines.

See [INSTALL.md](INSTALL.md) for how to install `fig`.

## Talks

Some people found it useful to look at slides and videos explaining how `fig`
works instead of working through the docs.
All slides, videos, and further information can be found
[on the author's talk page][talks].


# Usage Examples

The common way to work with a repo is `fig <repo> <git command>`, shown below.
`fig enter <repo>` (a shell with `$GIT_DIR` set) and `fig run <repo> <cmd>`
are covered in fig(1).


| Task                                                  | Command                                           |
| ----------------------------------------------------- | ------------------------------------------------- |
| _Initialize a new repository called "vim"_            |   `fig init vim`                                 |
| _Clone an existing repository_                        |   `fig clone <remote> <repository_name>`         |
| _Add files to repository "vim"_                       |   `fig vim add ~/.vimrc ~/.vim`                  |
|                                                       |   `fig vim commit -m 'Update Vim configuration'` |
| _Add a remote for repository "vim"_                   |   `fig vim remote add origin <remote>`           |
|                                                       |   `fig vim push origin main:main`            |
|                                                       |   `fig vim branch --track main origin/main`  |
| _Push to remote of repository "vim"_                  |   `fig vim push`                                 |
| _Pull from remote of repository "vim"_                |   `fig vim pull`                                 |
| _Show status of changed files in all repositories_    |   `fig status`                                   |
| _Pull from all repositories_                          |   `fig pull`                                     |
| _Push to all repositories_                            |   `fig push`                                     |
| _Add -u, commit, and push everything in one step_     |   `fig sync [<message>]`                         |


# Overview

## From zero to fig

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

`fig` takes this approach one step further. It enables single-purpose
repositories and stores them in a hidden directory. However, it does not create
symbolic links in `$HOME`; it puts the actual files right into `$HOME`.

As `fig` allows you to put an arbitrary number of distinct repositories into
your `$HOME`, you will end up with a lot of repositories very quickly.

`fig` has a built-in bootstrap. You populate
`~/.config/fig/.repos` -- one line per repo, `<name> <url> <branch> @tags,` --
with **`fig add <repo> [<tags>]`** (or `fig add --all` to append every local
repo that has a remote and isn't listed yet). Nothing else writes that file;
`delete` and `rename` leave stale lines for you to edit out.

Tags are an optional comma-separated list written after the branch, always
stored with a leading `@` and a trailing `,` (`fig add nvim laptop,work` ->
`nvim <url> main @laptop,work,`). A tagged row is **opt-in**: it clones only
when one of its tags is passed via `fig bootstrap --include=laptop` -- or the
shorthand `fig bootstrap @laptop` (a bare `@tag` / `@a,b` positional means
`--include`). A bare `fig bootstrap` clones the untagged rows only;
`--exclude` always wins. The `@` is optional wherever you type a tag -- on
`add`, `--include`/`--exclude`, and the `@tag` positional it's just the
column delimiter in the file.

Track the file in one of your repos. On a new machine, clone that repo and run
`fig bootstrap` (or `fig clone --all` / `-a` / `@<tags>` -- with `clone`,
that word must come first), and every other repo in the list is cloned for you.

    fig add --all
    fig dotfiles add -f ~/.config/fig/.repos
    fig dotfiles commit -m 'track repo list' && fig dotfiles push

    # on a new machine, after installing fig:
    fig clone <url-of-the-repo-holding-.repos> dotfiles
    fig bootstrap

`fig pull` / `fig push` / `fig status` then operate on the whole set, and
`fig sync [<message>]` does `add -u` + `commit` + `push` in one step (default
message "update"). Repositories that are not `fig` repos (a plain
`~/src/project`, work checkouts) are out of scope; use a separate tool for
those if you need it.

## Directory layout

Everything `fig` uses lives under `$XDG_CONFIG_HOME/fig/`
(`~/.config/fig/` by default). **Nothing is created in `$HOME`** except the
tracked files themselves.

    ~/.config/fig/
        .figrc               # optional: shell rc sourced on every run (FIG_* vars)
        .gitconfig              # git config included by every repo (edit: fig config ...)
        .gitignore              # shared fallback ignore file (seeded with '*')
        .gitattributes          # shared fallback attributes file
        .repos                  # repo list for `bootstrap` (curate with `fig add`)
        hooks/                  # optional: hook scripts
        overlays/               # optional: function overrides
        <name>.fig/          # one directory per repo, containing:
            <name>.git/         #   the git directory
            .figrc           #   optional: shell rc sourced when acting on this repo
            .gitignore          #   optional: per-repo ignore file
            .gitattributes      #   optional: per-repo attributes file

Each `<name>.git` is an ordinary git directory with `core.worktree` set to
`$HOME` and `core.bare` false, so the working files land straight in `$HOME`;
`fig` never creates symlinks. `upgrade` sets `core.excludesfile` /
`core.attributesfile` to the per-repo file in `<name>.fig/` if it exists,
otherwise to the shared `~/.config/fig/.gitignore` /
`~/.config/fig/.gitattributes` (see `$FIG_GITIGNORE`). Unlike vcsh, these
files are **not** tracked by the repo and do not clone to other machines --
regenerate with `fig write-gitignore <repo>` if you want a per-repo one.

The shared `~/.config/fig/.gitignore` is seeded with a single `*`, so
`git add .` in a fig repo can't sweep up all of `$HOME`. To spare you a
`-f` on every deliberate add, `fig <repo> add <path>` supplies `-f`
automatically **when that catch-all `*` is the only thing in the way**. A
path matched by a real rule (a line you wrote in `<name>.fig/.gitignore`,
`.git/info/exclude`, ...) is **not** force-added -- git's normal "use -f"
refusal still stands, so a deliberate ignore is never bypassed. The implicit
`-f` is skipped for bulk forms (`fig <repo> add .` / `-A` / `-u` / `-n`
...), when you pass `-f` yourself, and when `FIG_ADD_FORCE=no`.

`fig` refuses to overwrite an existing file: if a checkout would clobber
something already in `$HOME`, it warns and exits. Move the old file aside and
retry, then merge and `fig <name> push`.


# Getting Started

Install `fig` -- see [INSTALL.md](INSTALL.md). Then:

    fig init zsh                          # new repo
    fig zsh add ~/.zshrc                  # track files
    fig zsh commit -m 'initial zsh config'
    fig zsh remote add origin <url>
    fig zsh push -u origin main

Day to day:

    fig zsh add -u && fig zsh commit -m '...' && fig zsh push
    fig pull       # every repo that has a remote
    fig push
    fig status     # every repo

## New machine

    # install fig, then:
    fig clone <url-of-repo-holding-.repos> dotfiles
    fig bootstrap                                   # clone the untagged rows
    fig bootstrap @laptop                           # ...plus the @laptop rows
    fig bootstrap --include=laptop --exclude=work   # ...long form, with excludes

You curate `.repos` yourself with `fig add`; nothing writes it automatically.


# Contact

* Issues and pull requests: <https://github.com/stevensko/fig>
* Upstream project (vcsh): <https://github.com/RichiH/vcsh>

[talks]: http://richardhartmann.de/talks/
[fig]: https://github.com/stevensko/fig
[vcs-home-list]: http://lists.madduck.net/listinfo/vcs-home
