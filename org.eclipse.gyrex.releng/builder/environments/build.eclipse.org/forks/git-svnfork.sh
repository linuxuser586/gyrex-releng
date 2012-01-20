#!/bin/sh
set -u
set -e

# base dir of all the forks
forkCache=~/forks

# note, forks must be initialized manually using the following commands
#
#   git svn init --stdlayout svn://dev.eclipse.org/svnroot/rt/org.eclipse.gemini.jpa/
#   git svn fetch
#   git gc
#   git remote add origin /gitroot/gyrex/forks/gyrex-gemini-jpa.git
#   git push origin master
#   git checkout -b vendor
#   git push origin vendor
#   git svn rebase
#

# check vendor branch, hard reset, SVN rebase and push
# Usage: sync 'path to forked Git clone'
sync() {
	directory="$forkCache/$(basename $1 .git).git"
	if [ ! -d "$directory" ]; then
		echo "Fork $directory does not exist. Please initialize it!"
		exit 1
	fi
	pushd "$directory" >/dev/null
	echo "[git-svnfork] Using fork $directory"
	echo "[git-svnfork] Checkout and reset vendor branch..."
	git checkout vendor
	git reset --hard
	echo "[git-svnfork] Apply updates from SVN..."
	git svn rebase
	echo "[git-svnfork] Pushing to origin..."
	git push origin vendor
	popd >/dev/null
}

sync $1
