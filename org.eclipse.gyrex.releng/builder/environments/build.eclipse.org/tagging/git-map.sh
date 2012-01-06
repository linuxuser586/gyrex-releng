#!/bin/bash 
#
#
# example usage - you must have your repos checked out on the branch you
# expect to tag.
#
# USAGE: repoRoot buildTag relengRoot repoURL [repoURL]*
#    repoRoot   - absolute path to a folder containing cloned git repositories
#    buildTag   - build tag to tag all repositories
#    relengRoot - asolute path to releng project containing map files
#    repoURL    - git repository urls to tag, must match entries in the map files
# EXAMPLE: git-map.sh  \
#   /opt/pwebster/git/eclipse \
#   I20111122-0800 \
#   /opt/pwebster/workspaces/gitMigration/org.eclipse.releng \
#   git://git.eclipse.org/gitroot/platform/eclipse.platform.runtime.git \
#   git://git.eclipse.org/gitroot/platform/eclipse.platform.ui.git >maps.txt
# examine the file
# grep -v ^OK maps.txt >run.txt
# /bin/bash run.txt
#

PLATFORM=$( uname -s )

ARGS="$@"

# Generate directory name used in gitCache from repo Url
# Usage: gitCacheDirName repositoryURL
gitCacheDirName() {
	echo $(echo $1 | sed 's/ssh:.*@git.eclipse.org/git:\/\/git.eclipse.org/g' | sed 's/ssh:\/\/git.eclipse.org/git:\/\/git.eclipse.org/g' | sed 's/[^a-z0-9A-Z]/_/g')
}

tag_repo_commit () {
	REPO=$1
	REPO_DIR=$( gitCacheDirName $REPO )
	NEW_TAG=$2
	pushd "$gitCache/$REPO_DIR" >/dev/null
	REPO_COMMIT=$( git rev-list -1 HEAD  )
	if ! ( git log -1  --format="%d" "$REPO_COMMIT" | grep "[ (]$NEW_TAG[,)]" >/dev/null); then
		echo "pushd \"$gitCache/$REPO_DIR\" ; git tag -a \"$NEW_TAG\" -m 'Build Submission Tag' \"$REPO_COMMIT\" ; popd"
	fi
	popd >/dev/null
}

update_map () {
	#echo update_map "$@"
	REPO=$1
	REPO_DIR=$( gitCacheDirName $REPO )
	MAP=$2
	pushd "$gitCache/$REPO_DIR" >/dev/null
    grep -v '^#' "$MAP" | grep -v '^!' "$MAP" | grep "repo=${REPO}," "$MAP" >/tmp/maplines_$$.txt
	if [ ! -s /tmp/maplines_$$.txt ]; then
		return
	fi
	while read LINE; do
		LINE_START=$( echo $LINE | sed 's/^\([^=]*\)=.*$/\1/g' )
		PROJ_PATH=$( echo $LINE | sed 's/^.*path=//g' )
		CURRENT_TAG=$( echo $LINE | sed 's/.*tag=\([^,]*\),.*$/\1/g' )
		LAST_COMMIT=$( git rev-list -1 HEAD -- "$PROJ_PATH" )
        if [ -z "$LAST_COMMIT" ]; then
            echo "#SKIPPING $LINE_START, no commits for $PROJ_PATH"
            continue
        fi
		
		if ! ( git tag --contains $LAST_COMMIT | grep $CURRENT_TAG >/dev/null ); then
			NEW_DATE=$( git log -1 --format="%ct" "$LAST_COMMIT" )		
			if [ "$PLATFORM" == "Darwin" ]; then
				NEW_TAG=v$( date -u -j -f "%s" "$NEW_DATE" "+%Y%m%d-%H%M" )
			else
				NEW_TAG=v$( date -u --date="@$NEW_DATE"  "+%Y%m%d-%H%M" )
			fi
			
			if ! ( git log -1  --format="%d" "$LAST_COMMIT" | grep "[ (]$NEW_TAG[,)]" >/dev/null); then
				echo "pushd \"$gitCache/$REPO_DIR\" ; git tag -a \"$NEW_TAG\" -m 'Build Submission Tag' \"$LAST_COMMIT\" ; popd"
			fi
			echo sed -i "'s/$LINE_START=GIT,tag=$CURRENT_TAG/$LINE_START=GIT,tag=$NEW_TAG/g'" \"$MAP\"
		else
			echo OK $LINE_START $CURRENT_TAG 
		fi
	done </tmp/maplines_$$.txt
	rm -f /tmp/maplines_$$.txt
	popd >/dev/null
}


STATUS=OK
STATUS_MSG=""
LATEST_SUBMISSION=""


if [ $# -lt 4 ]; then
  echo "USAGE: $0 repoRoot buildTag relengRoot repoURL [repoURL]*"
  exit 1
fi


gitCache=$1; shift
buildTag=$1; shift
RELENG=$1; shift
REPOS="$@"


cd $gitCache
for REPO in $REPOS; do
	tag_repo_commit $REPO $buildTag
	MAPS=$( find $RELENG -name "*.map" -exec grep -l "repo=${REPO}," {} \; )
	if [ ! -z "$MAPS" ]; then
		for MAP in $MAPS; do
			update_map $REPO $MAP
		done
	fi
	REPO_DIR=$( gitCacheDirName $REPO )
	echo  pushd \"$gitCache/$REPO_DIR\" \; git push --tags \; popd 
done
