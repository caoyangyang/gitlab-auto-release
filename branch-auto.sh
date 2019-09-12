#!/bin/sh
projectId=$form_git_lab
projectToken=$form_git_lab
#more detail please visit https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html

release(){
  release_version=$1
  #prepare
  gitCheckoutAndPullLatestBranch release/$release_version
  gitCheckoutAndPullLatestBranch master
  releaseBranchCommitLog=$(git log origin/master..origin/release/$1 --pretty=format:"- %an %s %cd [%T] \\\r\\\n"  --no-merges)

  #merge and push
  mergeReleaseAndPushMaster $release_version

  #release note
  generateReleaseNote $release_version $releaseBranchCommitLog

  #rebase unreleased branch
}

gitCheckoutAndPullLatestBranch(){
  git stash
  git checkout $1
  git pull origin $1 --rebase
}

addTagAndPush(){
 git tag $1
 git push origin $1
}

mergeReleaseAndPushMaster(){
  git merge --no-ff release/$1
  git push origin master
  addTagAndPush $1
}

generateReleaseNote(){
  releaseNote=`echo "${@:2}"`
  curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: $projectToken" \
       --data '{"name": '\"$1\"',"tag_name": '\"$1\"',"description": "'"$releaseNote"'"}' \
       --request POST "https://gitlab.com/api/v4/projects/$projectId/releases"
  echo "release note as below\n $releaseNote"
}

if [ ! -z $1 ]; then
  echo "start release $1"
  release $1
else
  echo "Empty release version"
fi
