#!/bin/bash

# path to the releng builder within the Hudson workspace
# (this might vary between Hudson jobs)
builderHome=releng/org.eclipse.gyrex.releng/builder
if [ ! -d $builderHome ]; then
	echo "Builder could not be found ($builderHome). Please check the Hudson job is setup correctly!"
	exit 1
fi
# generate local build properties from environment template
buildLocalProps=$builderHome/build.local.properties
buildLocalPropsTemplate=$builderHome/environments/hudson.eclipse.org/build.local.properties
if [ ! -f $buildLocalPropsTemplate ]; then
	echo "Build environment template ($buildLocalPropsTemplate) not found. Please check the Hudson job is setup correctly!"
	exit 1
fi
rm -f $buildLocalProps
cp $buildLocalPropsTemplate $buildLocalProps

# set build type specific properties
echo '' >> $buildLocalProps
if [ "$BUILD_TYPE" = "N" ]; then
    echo '# customization for nightly builds' >> $buildLocalProps
    echo fetchTag=HEAD >> $buildLocalProps
    echo skipSign=true >> $buildLocalProps
elif [ "$BUILD_TYPE" = "I" ]; then
    echo '# customization for integration builds' >> $buildLocalProps
    echo skipSign=true >> $buildLocalProps
	echo publishRepoStream=1.0/integration >> $buildLocalProps
elif [ "$BUILD_TYPE" = "M" ]; then
    echo '# customization for maintenance builds' >> $buildLocalProps
	echo publishRepoStream=1.0/maintenance >> $buildLocalProps
elif [ "$BUILD_TYPE" = "S" ]; then
    echo '# customization for stable builds' >> $buildLocalProps
	echo publishRepoStream=1.0/milestones >> $buildLocalProps
fi
echo '#' >> $buildLocalProps
echo "# generated `date`" >> $buildLocalProps
echo '#' >> $buildLocalProps

# print generated properties to log
echo "Generated build environment properties: $buildLocalProps"
cat $buildLocalProps
