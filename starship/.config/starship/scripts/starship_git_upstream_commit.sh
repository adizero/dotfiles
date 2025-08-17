#!/usr/bin/env bash

function starship_git_upstream_commit()
{
  local git_root_base_dir_name branch_name
  git_root_base_dir_name=$(basename "${git_root}")
  branch_name=$(git symbolic-ref --short HEAD)
  # first try git describe with narrow match pattern specific for srlinux/panos git repos for faster resolution, fallback to full git describe
  [ "${git_root_base_dir_name}" = "srlinux" ] && [ "${branch_name}" = "master" ] && git describe --match=v0.0* "@{u}" 2>/dev/null && return 0
  [ "${git_root_base_dir_name}" = "panos" ] && [ "${branch_name}" = "master" ] && git describe --match=TiMOS_0_0_I8* "@{u}" 2>/dev/null && return 0
  git describe "@{u}" 2>/dev/null && return 0
  git log -1 --pretty=format:%h "@{u}" 2>/dev/null && return 0
  # try to describe the current commit (probably detached HEAD, or purely local branch/git)
  git describe 2>/dev/null && return 1
  git log -1 --pretty=format:%h 2>/dev/null && return 1
  echo "???"
  return 2
}

# Check if git is available and the current directory is a git repository
git_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "${git_root}" ]; then
    echo "Not a git repository"
    exit 1
fi

# Check if the cache file exists and if the current HEAD commit matches the cached one
# Use cache filename based on the git_root directory to avoid conflicts in different git repositories
# Place the cache directory under tmp, replace / with % in the git_root path to make it a valid cache filename
cache_directory="/tmp/.upstream_commit_tag"
if [ ! -d "${cache_directory}" ]; then
  mkdir -p "${cache_directory}"
fi
cache_filename="${cache_directory}/cache${git_root//\//%}"
cached_head_commit="(none)"
cached_upstream_tag=""
if [ -r "${cache_filename}" ]; then
  cached_line=$(cat "${cache_filename}")
  # cached_line should be in the format: <head_commit> <upstream_tag>
  cached_head_commit=${cached_line%% *}
  cached_upstream_tag=${cached_line#* }
fi
head_commit=$(git rev-parse --short HEAD)
if [ "${head_commit}" == "${cached_head_commit}" ]; then
    echo "${cached_upstream_tag}"
    exit 0
fi

# If the cache is not valid, compute the upstream commit
commit=$(starship_git_upstream_commit)
ret="${?}"

if [ "${ret}" -eq 0 ]; then
  upstream_tag="upstream "
elif [ "${ret}" -eq 1 ]; then
  upstream_tag="local "
else
  upstream_tag=""
fi
upstream_tag="${upstream_tag}${commit}"

# Print the upstream tag
echo "${upstream_tag}"

# Update the cache file with the current HEAD commit and upstream tag
echo "${head_commit} ${upstream_tag}" > "${cache_filename}"
