#!/bin/bash
set -xe
OCEAN_D1_REPO="https://github.com/sociomantic-tsunami/ocean.git"
OCEAN_D2_REPO="https://github.com/sociomantic-tsunami/ocean-d2.git"
# Define the ocean-d2 link to use in pushing, set verbose mode off
set +x
OCEAN_D2_REPO_PUSH="https://${GI_USER}:${GIT_OAUTH}github.com/sociomantic-tsunami/ocean-d2.git"
set -x
OCEAN_D2_SYNC_BRANCH="cli_sync"
README_WARNING_PATH="README_INJECT.rst"

# Clone first the D1 ocean
git clone "$OCEAN_D1_REPO" ocean -o ocean_d1
cd ocean
# Also add th D22 ocean repo as a remote repo and fetch its branches
git remote add --fetch ocean_d2 "$OCEAN_D2_REPO"

# Load the content of the files that we will inject in converted D2 code into
# variables. In such way we can switch branches safely later. The files to inject
# are located in a special D2 branch.
git checkout --quiet ocean_d2/$OCEAN_D2_SYNC_BRANCH
README_WARNING=`cat $README_WARNING_PATH`

# Get the tags of ocean D1 repo
LOCAL_TAGS=`git ls-remote -t ocean_d1 | \
            awk -F"refs/tags/" '{print $2}' | cut -d"^" -f 1 | uniq`
# Get the tags of ocean D2 repo
REMOTE_TAGS=`git ls-remote -t ocean_d2 | \
             awk -F"refs/tags/" '{print $2}' | cut -d"^" -f 1 | uniq`
# Store the tags that are in this repo but not in the remote repo
ONLY_IN_LOCAL=`comm -1 -3  <(sort <<< "$REMOTE_TAGS") \
                           <(sort <<< "$LOCAL_TAGS")`
# Store the tags that are in the remote repo but not in this one
ONLY_IN_REMOTE=`comm -1 -3  <(sort <<< "$LOCAL_TAGS") \
                            <(sort <<< "$REMOTE_TAGS")`

# Remove from the remote repo all tags that doesn't exist in this repo
for TAG in $ONLY_IN_REMOTE
do
    set +x
    git push $OCEAN_D2_REPO_PUSH :"$TAG"
    set -x
done

# Loop on each tag that exists in the D1 repo but not in the D2 repo. The loop
# will convert each tag to D2 and push it to the remote repo.
for LOCAL_TAG in $ONLY_IN_LOCAL
do
    # Checkout our tag
    git checkout --quiet "$LOCAL_TAG"
    # Update submodules in case they affect the conversion at one point later
    git submodule init
    if [ $LOCAL_TAG == "v2.0.0-preview" ]
    then
        # This version of ocean had a broken submodule, so we have to add it
        # manually
        git submodule add https://github.com/sociomantic-tsunami/makd.git \
            submodules/makd
        cd submodules/makd && git checkout --quiet 86d6985 && cd -
    else
        git submodule update
    fi
    # Convert to D2, clean to remove any previous code conversion
    git clean --quiet --force
    make clean
    make d2conv
    # Add the warning to the D2 readme file
    cat<<<"$README_WARNING" > _tmp && cat README.rst >> _tmp && mv _tmp README.rst
    # Commit the converted code
    git add -u
    git commit -m "Auto-convert $LOCAL_TAG to D2"
    # We need to create a tag that we can push. Since that tag name is already
    # taken so we force the tag to point the new converted code
    git tag -f -a -m "$LOCAL_TAG" "$LOCAL_TAG"
    set +x
    git push $OCEAN_D2_REPO_PUSH  "$LOCAL_TAG"
    set -x
    # Get clean heads so no errors happen on checking out the next tag's commit
    git reset --hard
    git submodule foreach --recursive git reset --hard
done
