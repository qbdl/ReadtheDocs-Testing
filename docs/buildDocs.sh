#!/bin/bash
set -x
################################################################################
# File:    buildDocs.sh
# Purpose: Script that builds our documentation using sphinx and updates GitHub
#          Pages. This script is executed by:
#            .github/workflows/docs_pages_workflow.yml
################################################################################

###################
# INSTALL DEPENDS #
###################

apt-get update
# apt-get -y install git rsync python3-sphinx python3-sphinx-rtd-theme python3-pip
apt-get -y install git rsync python3-pip
# pip3 install -r docs/requirements.txt
pip3 install --no-cache-dir -r docs/requirements.txt

#####################
# DECLARE VARIABLES #
#####################

git config --global --add safe.directory /__w/ReadtheDocs-Testing/ReadtheDocs-Testing

pwd
ls -lah
export SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct)

##############
# BUILD DOCS #
##############

# build our documentation with sphinx (see docs/conf.py)
# * https://www.sphinx-doc.org/en/master/usage/quickstart.html#running-the-build
make -C docs clean
make -C docs html

#######################
# Update GitHub Pages #
#######################

git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"

docroot=`mktemp -d`
# rsync -av "docs/_build/html/" "${docroot}/"
rsync -av "docs/build/html/" "${docroot}/"

pushd "${docroot}"

# don't bother maintaining history; just generate fresh

git init
# git remote add deploy "https://token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git remote add deploy "https://token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git checkout -b gh-pages
# add .nojekyll to the root so that github won't 404 on content added to dirs
# that start with an underscore (_), such as our "_content" dir..
touch .nojekyll
# copy the resulting html pages built from sphinx above to our new git repo
git add .

# commit all the new files
msg="Updating Docs for commit ${GITHUB_SHA} made on `date -d"@${SOURCE_DATE_EPOCH}" --iso-8601=seconds` from ${GITHUB_REF} by ${GITHUB_ACTOR}"
git commit -am "${msg}"
# overwrite the contents of the gh-pages branch on our github.com repo
git push deploy gh-pages --force

popd # return to main repo sandbox root
# exit cleanly
exit 0
