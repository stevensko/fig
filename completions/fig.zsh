#compdef fig

function __fig_repositories () {
	local -a repos
	repos=( ${(f)"$(_call_program repositories fig list)"} )
	_describe -t repositories 'repository' repos
}

function __fig_not_implemented_yet () {
	_message "Subcommand completion '${1#*-}': not implemented yet"
}

function _fig-clone () {
	__fig_not_implemented_yet "$0" #TODO
}

function _fig-delete () {
	(( CURRENT == 2 )) && __fig_repositories
}

function _fig-enter () {
	(( CURRENT == 2 )) && __fig_repositories
}

function _fig-foreach () {
	_dispatch fig-foreach git
}

function _fig-help () {
	_nothing
}

function _fig-init () {
	_nothing
}

function _fig-list () {
	_nothing
}

function _fig-list-tracked () {
	(( CURRENT == 2 )) && __fig_repositories
}

function _fig-list-untracked () {
	_nothing
}

function _fig-pull () {
	_nothing
}

function _fig-push () {
	_nothing
}

function _fig-rename () {
	case $CURRENT in
		2) __fig_repositories ;;
		3) _message "new repository name" ;;
		*) _nothing ;;
	esac
}

function _fig-run () {
	(( CURRENT == 2 )) && __fig_repositories
	(( CURRENT == 3 )) && _command_names -e
	if (( CURRENT >= 4 )); then
		# see _precommand in zsh
		words=( "${(@)words[3,-1]}" )
		(( CURRENT -= 2 ))
		_normal
	fi
}

function _fig-status () {
	(( CURRENT == 2 )) && __fig_repositories
}

function _fig-upgrade () {
	(( CURRENT == 2 )) && __fig_repositories
}

function _fig-version () {
	_nothing
}

function _fig-which () {
	_files
}

function _fig-write-gitignore () {
	(( CURRENT == 2 )) && __fig_repositories
}

function _fig () {
	local curcontext="${curcontext}" ret=1
	local state figcommand
	local -a args subcommands

	local FIG_REPO_D
	: ${FIG_REPO_D:="${XDG_CONFIG_HOME:-"$HOME/.config"}/fig"}

	subcommands=(
		"add:add a repo (or --all) to .repos"
		"clone:clone an existing repository"
		"commit:commit in all repositories"
		"delete:delete an existing repository"
		"enter:enter repository; spawn new <\$SHELL>"
		"foreach:execute for all repos"
		"help:display help"
		"init:initialize an empty repository"
		"list:list all local fig repositories"
		"list-tracked:list all files tracked by fig"
		"list-untracked:list all files not tracked by fig"
		"pull:pull from all fig remotes"
		"push:push to fig remotes"
		"rename:rename a repository"
		"run:run command with <\$GIT_DIR> and <\$GIT_WORK_TREE> set"
		"status:show statuses of all/one fig repositories"
		"sync:add -u, commit, and push every repo in one step"
		"upgrade:upgrade repository to currently recommended settings"
		"version:print version information"
		"which:find <substring> in name of any tracked file"
		"config:edit shared git config included by every repo"
		"bootstrap:clone every repo in .repos not already present"
		"write-gitignore:write <repo>.config/.gitignore via git ls-files"
	)

	args=(
		'-c[source <file> prior to other configuration files]:config files:_path_files'
		'-d[enable debug mode]'
		'-v[enable verbose mode]'
		'*:: :->subcommand_or_options_or_repo'
	)

	_arguments -C ${args} && ret=0

	if [[ ${state} == "subcommand_or_options_or_repo" ]]; then
		if (( CURRENT == 1 )); then
			_describe -t subcommands 'fig sub-commands' subcommands && ret=0
			__fig_repositories && ret=0
		else
			figcommand="${words[1]}"
			if ! (( ${+functions[_fig-$figcommand]} )); then
				# There is no handler function, so this is probably the name
				# of a repository. Act accordingly.
				# FIXME: this may want to use '_dispatch fig git'
				GIT_DIR=$FIG_REPO_D/$words[1].config/$words[1].git _dispatch git git && ret=0
			else
				curcontext="${curcontext%:*:*}:fig-${figcommand}:"
				_call_function ret _fig-${figcommand} && (( ret ))
			fi
		fi
	fi
	return ret
}

_fig "$@"
