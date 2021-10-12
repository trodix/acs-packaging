#!/usr/bin/env bash
echo "=========================== Starting Update Downstream Script ==========================="
PS4="\[\e[35m\]+ \[\e[m\]"
set -vex
pushd "$(dirname "${BASH_SOURCE[0]}")/../../"

source "$(dirname "${BASH_SOURCE[0]}")/build_functions.sh"

#Fetch the latest changes, as Travis will only checkout the PR commit
git fetch origin "${TRAVIS_BRANCH}"
git checkout "${TRAVIS_BRANCH}"
git pull

# Retrieve the latest (just released) latest tag on the current branch
VERSION="$(git describe --abbrev=0 --tags)"

# Retrieve the Community Repo version
COM_VERSION="$(evaluatePomProperty "dependency.alfresco-community-repo.version")"

# Retrieve the Enterprise Share version
SHA_VERSION="$(evaluatePomProperty "dependency.alfresco-enterprise-share.version")"

DOWNSTREAM_REPO="github.com/Alfresco/acs-community-packaging.git"

cloneRepo "${DOWNSTREAM_REPO}" "${TRAVIS_BRANCH}"

cd "$(dirname "${BASH_SOURCE[0]}")/../../../$(basename "${DOWNSTREAM_REPO%.git}")"

# Update parent version
mvn -B versions:update-parent versions:commit "-DparentVersion=[${COM_VERSION}]"

# Update dependency version
mvn -B versions:set-property versions:commit \
  -Dproperty=dependency.alfresco-community-repo.version \
  "-DnewVersion=${COM_VERSION}"

mvn -B versions:set-property versions:commit \
  -Dproperty=dependency.alfresco-community-share.version \
  "-DnewVersion=${SHA_VERSION}"

mvn -B versions:set-property versions:commit \
  -Dproperty=dependency.acs-packaging.version \
  "-DnewVersion=${VERSION}"

# Commit changes
git status
git --no-pager diff pom.xml
git add pom.xml

if git status --untracked-files=no --porcelain | grep -q '^' ; then
  git commit -m "Update upstream versions

    - alfresco-community-repo:   ${COM_VERSION}
    - alfresco-enterprise-share: ${SHA_VERSION}
    - acs-packaging:             ${VERSION}"
  git push
else
  echo "Dependencies are already up to date."
  git status
fi


popd
set +vex
echo "=========================== Finishing Update Downstream Script =========================="

