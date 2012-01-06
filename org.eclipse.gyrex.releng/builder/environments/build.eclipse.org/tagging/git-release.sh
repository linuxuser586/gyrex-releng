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


# Generate directory name used in gitCache from repo Url
# Usage: gitCacheDirName repositoryURL
gitCacheDirName() {
	echo $(echo $1 | sed 's/ssh:.*@git.eclipse.org/git:\/\/git.eclipse.org/g' | sed 's/ssh:\/\/git.eclipse.org/git:\/\/git.eclipse.org/g' | sed 's/[^a-z0-9A-Z]/_/g')
}

#Pull or clone a branch from a repository
#Usage: pull repositoryURL branch
pull() {
        pushd $gitCache >/dev/null
        directory=$(gitCacheDirName "$1")
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
        popd >/dev/null
}

#Nothing to do for nightly builds, or if $noTag is specified
if $noTag || [ "$buildType" == "N" ]; then
        echo Skipping build tagging for nightly build or -tag false build
        exit
fi

pushd $buildTagRoot >/dev/null

# the releng repository
relengRepo=$gitCache/$(gitCacheDirName 'ssh://git.eclipse.org/gitroot/gyrex/platform.git')/releng/org.eclipse.gyrex.releng

# pull the releng project to get the list of repositories to tag
pull "ssh://git.eclipse.org/gitroot/gyrex/platform.git" $relengBranch

# cleanup temp files (from last build)
rm -f $buildTagRoot/$buildTag/repos-clean.txt $buildTagRoot/$buildTag/clones.txt $buildTagRoot/$buildTag/repos-report.txt

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
mkdir $buildTagRoot/$buildTag
echo "[git-release]" git-submission.sh $gitCache $buildTagRoot/$buildTag $( cat $buildTagRoot/$buildTag/repos-report.txt )
/bin/bash git-submission.sh $gitCache $buildTagRoot/$buildTag $( cat $buildTagRoot/$buildTag/repos-report.txt ) > $buildTagRoot/$buildTag/report.txt

# generate commands for updating maps and tagging projects
cat $buildTagRoot/$buildTag/clones.txt| xargs /bin/bash git-map.sh $gitCache $buildTag \
        $relengRepo > $buildTagRoot/$buildTag/maps.txt

# trim out lines that don't require execution
grep -v ^OK $buildTagRoot/$buildTag/maps.txt | grep -v ^Executed >$buildTagRoot/$buildTag/run.txt

# abort if nothing to tag
if [ $(wc -l < $buildTagRoot/$buildTag/run.txt ) <= 1 ]; then
	echo "Nothing to update"
	popd >/dev/null
	exit
fi

# perform tagging
/bin/bash $buildTagRoot/$buildTag/run.txt

# commit & tag updated maps
cd $relengRepo
git add $( find . -name "*.map" )
git commit -m "Releng build tagging for $buildTag"
git tag -f -a $buildTag -m "Build Submission Tag"  #tag the map file change

# push
git push
git push --tags

popd >/dev/null
