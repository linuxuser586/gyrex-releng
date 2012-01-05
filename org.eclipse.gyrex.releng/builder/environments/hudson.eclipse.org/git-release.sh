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
buildType=I
committerId=hudson
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
                "-buildType")
                        buildType="$2"; shift;;
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
                "-basebuilderBranch")
                        basebuilderBranch="$2"; shift;;
                "-eclipsebuilderBranch")
                        eclipsebuilderBranch="$2"; shift;;
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
	echo $(echo $1 | sed 's/ssh:.*@git.eclipse.org/git:\/\/git.eclipse.org/g' | sed 's/[^a-z0-9A-Z]/_/g')
}

#Pull or clone a branch from a repository
#Usage: pull repositoryURL branch
pull() {
        pushd $gitCache
        directory=$(gitCacheDirName "$1")
        if [ ! -d $directory ]; then
                echo git clone $1 $directory
                git clone $1 $directory
                cd $directory
                git config --add user.email "$gitEmail"
                git config --add user.name "$gitName"
        fi
        popd
        pushd $gitCache/$directory
        echo git checkout $2
        git checkout $2
        echo git pull
        git pull
        popd
}

#Nothing to do for nightly builds, or if $noTag is specified
if $noTag || [ "$buildType" == "N" ]; then
        echo Skipping build tagging for nightly build or -tag false build
        exit
fi

pushd $buildTagRoot

# the releng repository
relengRepo=$gitCache/$(gitCacheDirName 'git://git.eclipse.org/gitroot/gyrex/platform.git')/releng/org.eclipse.gyrex.releng

# pull the releng project to get the list of repositories to tag
#pull "git://git.eclipse.org/gitroot/gyrex/platform.git" $relengBranch

# cleanup temp files (from last build)
rm -f repos-clean.txt clones.txt repos-report.txt

# remove comments from pulled repository list
cat "$relengRepo/maps/repositories.txt" | grep -v "^#" > repos-clean.txt

# clone or pull each repository and checkout the appropriate branch
while read line; do
        #each line is of the form <repository> <branch>
        set -- $line
        pull $1 $2
        echo $1 | sed 's/ssh:.*@git.eclipse.org/git:\/\/git.eclipse.org/g' >> clones.txt
done < repos-clean.txt

cat repos-clean.txt | sed "s/ / $oldBuildTag /" >repos-report.txt

# generate the change report
mkdir $buildTagRoot/$buildTag
echo "[git-release]" git-submission.sh $gitCache $( cat repos-report.txt )
/bin/bash git-submission.sh $gitCache $( cat repos-report.txt ) > $buildTagRoot/$buildTag/report.txt


cat clones.txt| xargs /bin/bash git-map.sh $gitCache $buildTag \
        $relengRepo > maps.txt

#Trim out lines that don't require execution
grep -v ^OK maps.txt | grep -v ^Executed >run.txt
/bin/bash run.txt


cd $relengRepo
git add $( find . -name "*.map" )
git commit -m "Releng build tagging for $buildTag"
git tag -f $buildTag   #tag the map file change

git push
git push --tags

popd