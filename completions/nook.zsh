#compdef nook

function __nook_repositories () {
	local -a repos
	repos=( ${(f)"$(_call_program repositories nook list)"} )
	_describe -t repositories 'repository' repos
}

function __nook_not_implemented_yet () {
	_message "Subcommand completion '${1#*-}': not implemented yet"
}

function _nook-clone () {
	__nook_not_implemented_yet "$0" #TODO
}

function _nook-delete () {
	(( CURRENT == 2 )) && __nook_repositories
}

function _nook-enter () {
	(( CURRENT == 2 )) && __nook_repositories
}

function _nook-foreach () {
	_dispatch nook-foreach git
}

function _nook-help () {
	_nothing
}

function _nook-init () {
	_nothing
}

function _nook-list () {
	_nothing
}

function _nook-list-tracked () {
	(( CURRENT == 2 )) && __nook_repositories
}

function _nook-list-untracked () {
	_nothing
}

function _nook-pull () {
	_nothing
}

function _nook-push () {
	_nothing
}

function _nook-rename () {
	case $CURRENT in
		2) __nook_repositories ;;
		3) _message "new repository name" ;;
		*) _nothing ;;
	esac
}

function _nook-run () {
	(( CURRENT == 2 )) && __nook_repositories
	(( CURRENT == 3 )) && _command_names -e
	if (( CURRENT >= 4 )); then
		# see _precommand in zsh
		words=( "${(@)words[3,-1]}" )
		(( CURRENT -= 2 ))
		_normal
	fi
}

function _nook-status () {
	(( CURRENT == 2 )) && __nook_repositories
}

function _nook-upgrade () {
	(( CURRENT == 2 )) && __nook_repositories
}

function _nook-version () {
	_nothing
}

function _nook-which () {
	_files
}

function _nook-write-gitignore () {
	(( CURRENT == 2 )) && __nook_repositories
}

function _nook () {
	local curcontext="${curcontext}" ret=1
	local state nookcommand
	local -a args subcommands

	local NOOK_REPO_D
	: ${NOOK_REPO_D:="${XDG_CONFIG_HOME:-"$HOME/.config"}/nook"}

	subcommands=(
		"add:add a repo (or --all) to .repos"
		"clone:clone an existing repository"
		"commit:commit in all repositories"
		"delete:delete an existing repository"
		"enter:enter repository; spawn new <\$SHELL>"
		"foreach:execute for all repos"
		"help:display help"
		"init:initialize an empty repository"
		"list:list all local nook repositories"
		"list-tracked:list all files tracked by nook"
		"list-untracked:list all files not tracked by nook"
		"pull:pull from all nook remotes"
		"push:push to nook remotes"
		"rename:rename a repository"
		"run:run command with <\$GIT_DIR> and <\$GIT_WORK_TREE> set"
		"status:show statuses of all/one nook repositories"
		"sync:add -u, commit, and push every repo in one step"
		"upgrade:upgrade repository to currently recommended settings"
		"version:print version information"
		"which:find <substring> in name of any tracked file"
		"config:edit shared git config included by every repo"
		"bootstrap:clone every repo in .repos not already present"
		"write-gitignore:write <repo>.nook/.gitignore via git ls-files"
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
			_describe -t subcommands 'nook sub-commands' subcommands && ret=0
			__nook_repositories && ret=0
		else
			nookcommand="${words[1]}"
			if ! (( ${+functions[_nook-$nookcommand]} )); then
				# There is no handler function, so this is probably the name
				# of a repository. Act accordingly.
				# FIXME: this may want to use '_dispatch nook git'
				GIT_DIR=$NOOK_REPO_D/$words[1].nook/$words[1].git _dispatch git git && ret=0
			else
				curcontext="${curcontext%:*:*}:nook-${nookcommand}:"
				_call_function ret _nook-${nookcommand} && (( ret ))
			fi
		fi
	fi
	return ret
}

_nook "$@"
