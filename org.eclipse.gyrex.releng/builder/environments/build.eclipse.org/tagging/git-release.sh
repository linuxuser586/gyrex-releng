#!/bin/bash

#*******************************************************************************
# Copyright (c) 2011 IBM Corporation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     IBM Corporation - initial API and implementation
#     Gunnar Wagenknecht - adapted for Gyrex
#*******************************************************************************

# copied from
# (http://git.eclipse.org/c/e4/org.eclipse.e4.releng.git/plain/org.eclipse.e4.builder/scripts/git-release.sh)

#default values, overridden by command line
relengBranch=master
committerId=gyrex
gitEmail=gyrex-dev@eclipse.org
gitName="Gyrex Builder"
tag=true
noTag=false

ARGS="$@"

while [ $# -gt 0 ]
do
        case "$1" in
                "-branch")
                        relengBranch="$2"; shift;;
                "-gitCache")
                        gitCache="$2"; shift;;
                "-root")
                        buildTagRoot="$2"; shift;;
                "-committerId")
                        committerId="$2"; shift;;
                "-gitEmail")
                        gitEmail="$2"; shift;;
                "-gitName")
                        gitName="$2"; shift;;
                "-oldBuildTag")
                        oldBuildTag="$2"; shift;;
                "-buildTag")
                        buildTag="$2"; shift;;
                "-tag")
                        tag="$2"; shift;;
                 *) break;;      # terminate while loop
        esac
        shift
done

if [ -z $buildTagRoot ]; then
  echo You must provide -buildTagRoot
  echo args: "$ARGS"
  exit
fi
if [ -z $oldBuildTag  ]; then
  echo You must provide -oldBuildTag
  echo args: "$ARGS"
  exit
fi
if [ -z $buildTag  ]; then
  echo You must provide -buildTag
  echo args: "$ARGS"
  exit
fi
if [ -z $gitCache  ]; then
  echo You must provide -gitCache
  echo args: "$ARGS"
  exit
fi

if ! $tag; then
	noTag=true
fi


#Pull or clone a branch from a repository
#Usage: pull repositoryURL branch
pull() {
        pushd $gitCache >/dev/null
        directory=$(basename $1 .git)
        if [ ! -d $directory ]; then
                echo git clone $1 $directory
                git clone $1 $directory
                cd $directory
                git config --add user.email "$gitEmail"
                git config --add user.name "$gitName"
        fi
        popd >/dev/null
        pushd $gitCache/$directory >/dev/null
        echo git checkout $2
        git checkout $2
        echo git pull
        git pull
        if [[ $1 == *git.eclipse.org* ]]; then
            gerritOriginRepoUrl=$(echo $1 | sed 's|ssh:.*@git.eclipse.org/gitroot|ssh://git.eclipse.org:29418|g' | sed 's|ssh://git.eclipse.org/gitroot|ssh://git.eclipse.org:29418|g')
		    echo git remote set-url --push origin $gerritOriginRepoUrl
			git remote set-url --push origin $gerritOriginRepoUrl
        fi
        popd >/dev/null
}

pushd $buildTagRoot >/dev/null

# the releng repository
relengRepoUrl='ssh://git.eclipse.org/gitroot/gyrex/gyrex-releng.git'
relengRepo=$gitCache/$(basename $relengRepoUrl .git)/org.eclipse.gyrex.releng

# pull the releng project to get the list of repositories to tag
pull $relengRepoUrl $relengBranch

# create tag working dir
if [ -d $buildTagRoot/$buildTag ]; then
	rm -rf $buildTagRoot/$buildTag
fi
mkdir $buildTagRoot/$buildTag

# remove comments from pulled repository list
cat "$relengRepo/maps/repositories.txt" | grep -v "^#" > $buildTagRoot/$buildTag/repos-clean.txt

# clone or pull each repository and checkout the appropriate branch
while read line; do
        #each line is of the form <repository> <branch>
        set -- $line
        pull $1 $2
        echo $1 | sed 's/ssh:.*@git.eclipse.org/git:\/\/git.eclipse.org/g' | sed 's/ssh:\/\/git.eclipse.org/git:\/\/git.eclipse.org/g' >> $buildTagRoot/$buildTag/clones.txt
done < $buildTagRoot/$buildTag/repos-clean.txt

cat $buildTagRoot/$buildTag/repos-clean.txt | sed "s/ / $oldBuildTag /" >$buildTagRoot/$buildTag/repos-report.txt

# generate the change report
echo "[git-release]" git-submission.sh $gitCache $buildTagRoot/$buildTag $( cat $buildTagRoot/$buildTag/repos-report.txt )
/bin/bash git-submission.sh $gitCache $buildTagRoot/$buildTag $( cat $buildTagRoot/$buildTag/repos-report.txt ) > $buildTagRoot/$buildTag/report.txt

# abort if nothing changed
if [ "$?" -ne "0" ]; then
	echo "[git-release] Nothing to update"
	popd >/dev/null
	exit 1
fi

# generate commands for updating maps and tagging projects
cat $buildTagRoot/$buildTag/clones.txt| xargs /bin/bash git-map.sh $gitCache $buildTag \
        $relengRepo > $buildTagRoot/$buildTag/maps.txt

# trim out lines that don't require execution
grep -v ^OK $buildTagRoot/$buildTag/maps.txt | grep -v ^Executed >$buildTagRoot/$buildTag/run.txt

# perform tagging
echo "[git-release] Tagging projects using $buildTag..."
/bin/bash $buildTagRoot/$buildTag/run.txt

# commit & tag updated maps
cd $relengRepo
echo "[git-release] Comitting and tagging map files..."
git add $( find . -name "*.map" )
git commit -m "Releng build tagging for $buildTag"
git tag -f -a $buildTag -m "Build Submission Tag"  #tag the map file change

# push
echo "[git-release] Push to origin..."
git push
git push --tags

echo "[git-release] Finished."

popd >/dev/null
