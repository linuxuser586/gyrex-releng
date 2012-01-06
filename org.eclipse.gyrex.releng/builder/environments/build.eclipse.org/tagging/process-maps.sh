#!/bin/bash
#
# Check Gyrex Git repos for new commits and update build submissions.
#
# Add to your crontab like this:
#   05 */4 * * * ~/bin/process-maps.sh -gitEmail 'your-comitter-email' -committerId 'your-committer-id' -hudsonBuildTriggerToken 'secrettoken' > ~/process-maps.log
#

#default values, overridden by command line
relengBranch=master
committerId=gyrex
gitEmail=gyrex-dev@eclipse.org
gitName="Gyrex Build Submission"
hudsonBuildTriggerToken="secret"

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
                "-hudsonBuildTriggerToken")
                        hudsonBuildTriggerToken="$2"; shift;;
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

# generate new tag and also find the last used tag
buildTag=v$(date -u +%Y%m%d)-$(date -u +%H%M)
oldBuildTag=$( cat $buildTagRoot/lastBuildTag.properties )
echo "Using build tag: $buildTag"
echo "Last build tag: $oldBuildTag"


# switch to root dir	
pushd $buildTagRoot >/dev/null

# fetch tag helper scripts
wget -O git-release.sh "http://git.eclipse.org/c/gyrex/platform.git/plain/releng/org.eclipse.gyrex.releng/builder/environments/build.eclipse.org/tagging/git-release.sh?$buildTag"
wget -O git-map.sh "http://git.eclipse.org/c/gyrex/platform.git/plain/releng/org.eclipse.gyrex.releng/builder/environments/build.eclipse.org/tagging/git-map.sh?$buildTag"
wget -O git-submission.sh "http://git.eclipse.org/c/gyrex/platform.git/plain/releng/org.eclipse.gyrex.releng/builder/environments/build.eclipse.org/tagging/git-submission.sh?$buildTag"

# call tag script
/bin/bash git-release.sh \
	-gitCache "$gitCache" -root "$buildTagRoot" \
	-committerId "${committerId}" -gitEmail "${gitEmail}" -gitName "${gitName}" \
	-oldBuildTag "$oldBuildTag" -buildTag "$buildTag"

# additional processing on success	
if [ "$?" -eq "0" ]; then
	# remember tag
	echo "[process-maps] Saving tag $buildTag..."
	echo $buildTag >$buildTagRoot/lastBuildTag.properties
	# send mail with change report
	echo "[process-maps] Sending mail with submission report..."
	mailx -s "Gyrex Build Submission: $buildTag" gunnar@eclipse.org <$buildTagRoot/$buildTag/report.txt
	# trigger build
	echo "[process-maps] Triggering build..."
	curl -I "https://hudson.eclipse.org/hudson/view/Technology/job/gyrex-integration/buildWithParameters?token=${hudsonBuildTriggerToken}&cause=Build+Submission+${buildTag}"
fi

popd >/dev/null

echo "[process-maps] Done."
