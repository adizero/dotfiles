function starship_git_upstream_commit()
{
  local git_root git_root_base_dir_name branch_name
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "${git_root}" ]; then
      echo "Not a git repository"
      return 3
  fi
  git_root_base_dir_name=$(basename "${git_root}")
  branch_name=$(git symbolic-ref --short HEAD)
  [ "${git_root_base_dir_name}" = "srlinux" ] && [ "${branch_name}" = "master" ] && git describe --match=v0.0* "@{u}" 2>/dev/null && return 0
  git describe "@{u}" 2>/dev/null && return 0
  git log -1 --pretty=format:%h "@{u}" 2>/dev/null && return 0
  # try to describe the current commit (probably detached HEAD, or purely local branch/git)
  git describe 2>/dev/null && return 1
  git log -1 --pretty=format:%h 2>/dev/null && return 1
  echo "???"
  return 2
}

commit=$(starship_git_upstream_commit)
ret="${?}"

if [ "${ret}" -eq 0 ]; then
  upstream_tag="upstream "
elif [ "${ret}" -eq 1 ]; then
  upstream_tag="local "
else
  upstream_tag=""
fi

[ -n "${commit}" ] && echo "${upstream_tag}${commit}"
