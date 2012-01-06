#!/bin/bash

# check required input
if [ -z $WORKSPACE ]; then
	echo "Environment variable WORKSPACE not set. Please check the Hudson job is setup correctly!"
	exit 1
fi
if [ -z $BUILD_TYPE ]; then
	echo "Environment variable BUILD_TYPE not set. Please check the Hudson job is setup correctly!"
	exit 1
fi
if [ -z $BUILD_NUMBER ]; then
	echo "Environment variable BUILD_NUMBER not set. Please check the Hudson job is setup correctly!"
	exit 1
fi

# path to the releng builder within the Hudson workspace
# (this might vary between Hudson jobs)
builderHome=$WORKSPACE/platform-source/releng/org.eclipse.gyrex.releng/builder
if [ ! -d $builderHome ]; then
	echo "Builder could not be found ($builderHome). Please check the Hudson job is setup correctly!"
	exit 1
fi

# where all the build tagging happens
buildTagRoot=$WORKSPACE/tags
if [ ! -d $buildTagRoot ]; then
	mkdir $buildTagRoot
fi

# the git cache
gitCache=/shared/technology/gyrex/gitCache
if [ ! -d $gitCache ]; then
	mkdir $gitCache
fi

# execute all git commands as a user that has git push permissions
alias git='/shared/technology/gyrex/tagging/gits.sh'


generateLocalBuildProperties () {
	# generate local build properties from environment template
	buildLocalProps=$builderHome/build.local.properties
	buildLocalPropsTemplate=$builderHome/environments/hudson.eclipse.org/build.local.properties
	if [ ! -f $buildLocalPropsTemplate ]; then
		echo "Build environment template ($buildLocalPropsTemplate) not found. Please check the Hudson job is setup correctly!"
		exit 1
	fi
	rm -f $buildLocalProps
	cp $buildLocalPropsTemplate $buildLocalProps
	
	# inject git cache location
	echo '' >> $buildLocalProps
	echo "fetchCacheLocation=${gitCache}" >> $buildLocalProps

	# set build type specific properties
	echo '' >> $buildLocalProps
	if [ "$BUILD_TYPE" = "N" ]; then
		echo '# customization for nightly builds' >> $buildLocalProps
		echo fetchTag=CVS=HEAD,GIT=origin/master >> $buildLocalProps
		echo skipSign=true >> $buildLocalProps
		echo skipPublish=true >> $buildLocalProps
	elif [ "$BUILD_TYPE" = "I" ]; then
		echo '# customization for integration builds' >> $buildLocalProps
		echo skipSign=true >> $buildLocalProps
		echo publishRepoStream=1.0/integration >> $buildLocalProps
	elif [ "$BUILD_TYPE" = "M" ]; then
		echo '# customization for maintenance builds' >> $buildLocalProps
		echo publishRepoStream=0.11/maintenance >> $buildLocalProps
	elif [ "$BUILD_TYPE" = "S" ]; then
		echo '# customization for stable builds' >> $buildLocalProps
		echo publishRepoStream=1.0/milestones >> $buildLocalProps
	elif [ "$BUILD_TYPE" = "R" ]; then
		echo '# customization for release builds' >> $buildLocalProps
		echo publishRepoStream=1.0 >> $buildLocalProps
	fi
	echo '#' >> $buildLocalProps
	echo "# generated `date`" >> $buildLocalProps
	echo '#' >> $buildLocalProps

	# print generated properties to log
	echo "Generated build environment properties: $buildLocalProps"
	cat $buildLocalProps
}


tagRepo () {
	# find the last used tag
	buildTag=${BUILD_TYPE}$(date +%Y%m%d)-$(date +%H%M)-b${BUILD_NUMBER}
	oldBuildTag=$( cat $buildTagRoot/last-${BUILD_TYPE}-buildTag.properties )
	echo "Using build tag: $buildTag"
	echo "Last build tag: $oldBuildTag"
	echo $buildTag >$buildTagRoot/last-${BUILD_TYPE}-buildTag.properties
	
	# fetch tag helper scripts
	cp -f $builderHome/environments/hudson.eclipse.org/git*.sh $buildTagRoot

	# call tag script
	pushd $buildTagRoot
	/bin/bash git-release.sh \
   -buildType "${BUILD_TYPE}" -gitCache "$gitCache" -root "$buildTagRoot" \
   -oldBuildTag "$oldBuildTag" -buildTag "$buildTag"
	popd
	mailx -s "$eclipseStream SDK Build: $buildTag submission" gunnar@eclipse.org <$buildTagRoot/$buildTag/report.txt
}


generateLocalBuildProperties
tagRepo

