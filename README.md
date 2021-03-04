# git_cache_repo



## Usage

### Clone a repo to my build directory from the cache reference repo
Using bitbucket, clone a repo into  the agent build directory using the local mirror of the repo (on the agent), run this command:

**NOTE** : The mirror will be created if it doesn't exist

```bash
./clone_repo.sh \
# --build is the temporary build directory. this will add the repo dir there
--build /tmp/mirror/build \
# --mirror is the directory that contains all the local mirror (cache) repos
--mirror /tmp/mirror/mirror \
# the stas remote to clone
--remote https://"${STASH_USERNAME}":${STASH_PAT}@"${STASH_REPO}" \
# clone commmand 
clone

```