#!/bin/bash

#default values, overridden by command line
relengBranch=master
committerId=gyrex
gitEmail=gyrex-dev@eclipse.org
gitName="Gyrex Build Submission"

ARGS="$@"

while [ $# -gt 0 ]
do
        case "$1" in
                "-branch")
                        relengBranch="$2"; shift;;
                "-committerId")
                        committerId="$2"; shift;;
                "-gitEmail")
                        gitEmail="$2"; shift;;
                "-gitName")
                        gitName="$2"; shift;;
                 *) break;;      # terminate while loop
        esac
        shift
done

# where all the build tagging happens
buildTagRoot=/shared/technology/gyrex/tagging/work
if [ ! -d $buildTagRoot ]; then
	mkdir $buildTagRoot
fi

# the git cache
gitCache=/shared/technology/gyrex/tagging/gitcache
if [ ! -d $gitCache ]; then
	mkdir $gitCache
fi

tagRepo () {
	# find the last used tag
	buildTag=v$(date +%Y%m%d)-$(date +%H%M)
	oldBuildTag=$( cat $buildTagRoot/last-buildTag.properties )
	echo "Using build tag: $buildTag"
	echo "Last build tag: $oldBuildTag"
	echo $buildTag >$buildTagRoot/last-${BUILD_TYPE}-buildTag.properties

    # switch to root dir	
	pushd $buildTagRoot

	# fetch tag helper scripts
	wget -O git-release.sh http://git.eclipse.org/c/gyrex/platform.git/plain/releng/org.eclipse.gyrex.releng/builder/environments/build.eclipse.org/tagging/git-release.sh
	wget -O git-map.sh http://git.eclipse.org/c/gyrex/platform.git/plain/releng/org.eclipse.gyrex.releng/builder/environments/build.eclipse.org/tagging/git-map.sh
	wget -O git-submission.sh http://git.eclipse.org/c/gyrex/platform.git/plain/releng/org.eclipse.gyrex.releng/builder/environments/build.eclipse.org/tagging/git-submission.sh

	# call tag script
	/bin/bash git-release.sh \
		-buildType "${BUILD_TYPE}" -gitCache "$gitCache" -root "$buildTagRoot" \
		-committerId "${committerId}" -gitEmail "${gitEmail}" -gitName "${gitName}" \
		-oldBuildTag "$oldBuildTag" -buildTag "$buildTag"
	popd
	mailx -s "Gyrex Build Submission: $buildTag" gunnar@eclipse.org <$buildTagRoot/$buildTag/report.txt
	
	# ensure that the git cache is also writable by the groups so that we can cleanup later
	chmod g+rwX -R $gitCache/* >/dev/null
}


generateLocalBuildProperties
tagRepo

