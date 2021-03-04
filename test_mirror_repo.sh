#!/usr/bin/env bash


function short_repo() {
  # strip off everything before the last '/' leaving "dna.git"
  with_git=$(echo "${1}" | rev | cut -d/ -f1 | rev)
  # strip the .git and return it
  echo "${with_git%.git}"
}

. ./env.sh
build_dir=$(mktemp -d)
mirror_dir=$(mktemp -d)


# add this flag if needed
# --verbose \

./mirror_repo.sh \
--build "${build_dir}" \
--mirror "${mirror_dir}" \
--remote https://"${STASH_USERNAME}":"${STASH_PAT}"@"${STASH_REPO}" \
clone

cat << EOF
Rn these to cleanup:
rm -rf ${build_dir}
rm -rf ${mirror_dir}

EOF


test_data="$(date +"%Y%m%d-%H%M%S")"
short=$(short_repo https://"${STASH_USERNAME}":"${STASH_PAT}"@"${STASH_REPO}")
git -C "${build_dir}/${short}" checkout -b "${test_data}"
echo "${test_data}" >> "${build_dir}/${short}"/README.md
git -C "${build_dir}/${short}" commit -am "${test_data}"


# add this flag if needed
# --verbose \

./mirror_repo.sh \
--build "${build_dir}" \
--mirror "${mirror_dir}" \
--remote https://"${STASH_USERNAME}":"${STASH_PAT}"@"${STASH_REPO}" \
push