#!/bin/bash
#
# When the map file has been updated, this can be used to generate
# the releng build submission report
# USAGE: git-submission.sh repoRoot workDir repoURL last_tag build_tag [repoURL...] >report.txt
#

ROOT=$1; shift
WORKDIR=$1; shift
rm -f $WORKDIR/proj_changed.txt $WORKDIR/bug_list.txt $WORKDIR/bug_info.txt

# Generate directory name used in gitCache from repo Url
# Usage: gitCacheDirName repositoryURL
gitCacheDirName() {
	echo $(echo $1 | sed 's/ssh:.*@git.eclipse.org/git:\/\/git.eclipse.org/g' | sed 's/ssh:\/\/git.eclipse.org/git:\/\/git.eclipse.org/g' | sed 's/[^a-z0-9A-Z]/_/g')
}


while [ $# -gt 0 ]; do
	REPO="$1"; shift
	REPO_DIR=$( gitCacheDirName $REPO )
	LAST_TAG="$1"; shift
	BUILD_TAG="$1"; shift
	cd $ROOT/$REPO_DIR
	git diff --name-only ${LAST_TAG} ${BUILD_TAG} | cut -f2 -d/ | sort -u >>$WORKDIR/proj_changed.txt
	git log --first-parent ${LAST_TAG}..${BUILD_TAG} \
		| grep '[Bb]ug[^0-9]*[0-9][0-9][0-9][0-9][0-9]*[^0-9]'  \
		| sed 's/.*[Bb]ug[^0-9]*\([0-9][0-9][0-9][0-9][0-9]*\)[^0-9].*$/\1/g' >>$WORKDIR/bug_list.txt
done

# abort processing if nothing changed
if [ ! -d $WORKDIR/proj_changed.txt ]; then
	echo "No changes found." 1>&2
	exit 1
fi

touch $WORKDIR/bug_info.txt

for BUG in $( cat $WORKDIR/bug_list.txt | sort -n -u ); do
	BUGT2=$WORKDIR/buginfo_${BUG}.txt
	curl -k https://bugs.eclipse.org/bugs/show_bug.cgi?id=${BUG}\&ctype=xml >$BUGT2 2>/dev/null
	TITLE=$( grep short_desc $BUGT2 | sed 's/^.*<short_desc.//g' | sed 's/<\/short_desc.*$//g' )
    STATUS=$( grep bug_status $BUGT2 | sed 's/^.*<bug_status.//g' | sed 's/<\/bug_status.*$//g' )
    if [ RESOLVED = "$STATUS" -o VERIFIED = "$STATUS" ]; then
        STATUS=$( grep '<resolution>' $BUGT2 | sed 's/^.*<resolution.//g' | sed 's/<\/resolution.*$//g' )
    fi
    echo + Bug $BUG - $TITLE \(${STATUS}\) >>$WORKDIR/bug_info.txt
done

echo The build contains the following changes:
cat $WORKDIR/bug_info.txt
echo ""
echo The following projects have changed:
cat $WORKDIR/proj_changed.txt | sort -u