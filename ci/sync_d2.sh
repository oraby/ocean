#!/bin/bash
set -xe

OCEAN_D2_REPO="https://github.com/sociomantic-tsunami/ocean-d2.git"
README_WARNING="ci/WARNING_README.rst"
# Add the remote repo if it doesn't exist
if ! git config remote.ocean_d2.url  > /dev/null
then
    git remote add ocean_d2 "$OCEAN_D2_REPO"
fi

# Get the tags of the current repo
LOCAL_TAGS=`git tag`
# Get the tags of the remote repo
REMOTE_TAGS=`git ls-remote -t ../ocean_remote | \
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
    git push ocean_d2 :"$TAG"
done

# Stash any dirty changes if necessary
git submodule foreach --recursive git stash # TODO: Only stash changed
git submodule update --recursive
STASHED=`git diff-index --quiet HEAD -- || ( echo "1" && git stash )`
# Remember the current head so we can switch back to it later
CUR_HEAD="`git symbolic-ref -q --short HEAD || \
           git describe --tags --exact-match 2>/dev/null || git rev-parse HEAD`"
# Loop on each tag that exists in this repo but not in the remote repo. The
# loop will convert each tag to D2 and push it to the remote repo.
for LOCAL_TAG in $ONLY_IN_LOCAL
do
    # Checkout our tag
    git checkout -q "$LOCAL_TAG"
    # Store the tag's original commit hash
    ORIGINA_COMMIT="`git rev-parse HEAD`"
    # Update submodules in case they affect the conversion at one point later
    git submodule update
    # Convert to D2
    make clean
    make d2conv
    # Add the warning to the D2 readme file
    cat $README_WARNING README.rst > _tmp && mv _tmp README.rst
    # Commit the converted code
    git add -u
    git commit -m "Auto-convert $LOCAL_TAG to D2"
    # We need to create a tag that we can push. Since that tag name is already
    # taken so we force the tag to point the new converted code and we will
    # copy it back later
    git tag -f -a -m "$LOCAL_TAG" "$LOCAL_TAG"
    git push ocean_d2 "$LOCAL_TAG"
    # Get clean heads so no errors happen on checking out the next tag's commit
    git reset --hard
    git submodule foreach --recursive git reset --hard
    # Force the tag back to its original name
    git checkout "$ORIGINA_COMMIT"
    git tag -f -a -m "$LOCAL_TAG" "$LOCAL_TAG"
done

# Restore the head we were originally at
git checkout "$CUR_HEAD"
git submodule update --recursive
git submodule foreach --recursive "git stash list | wc -l | \
                                   xargs test "0" == || git stash pop"
# Check whether to unstash
if [ -n "$STASHED" ]
then
    git stash pop
fi
