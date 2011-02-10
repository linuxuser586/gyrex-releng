#!/bin/bash

# generate local build properties from environment template
buildLocalProps=releng/org.eclipse.gyrex.releng/builder/build.local.properties
buildLocalPropsTemplate=releng/org.eclipse.gyrex.releng/builder/environments/hudson.eclipse.org/build.local.properties
if [ ! -f $buildLocalPropsTemplate ]; then
	echo "Build environment template ($buildLocalPropsTemplate) not found. Please check the job is setup correctly!"
	exit 1
fi
rm -f $buildLocalProps
cp $buildLocalPropsTemplate $buildLocalProps

# set build type specific properties
if [ "$BUILD_TYPE" = "N" ]; then
    echo '# customization for nightly builds' >> $buildLocalProps
    echo fetchTag=HEAD >> $buildLocalProps
    echo skipSign=true >> $buildLocalProps
elif [ "$BUILD_TYPE" = "I" ]; then
    echo '# customization for integration builds' >> $buildLocalProps
    echo skipSign=true >> $buildLocalProps
fi

# print generated properties to log
echo "Generated build environment properties: $buildLocalProps"
cat $buildLocalProps
