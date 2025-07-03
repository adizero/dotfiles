# _fpp() {
#   tmux capture-pane -J -S - -E - -b "fpp-$1" -t "$1"
#   tmux split-window "tmux show-buffer -b fpp-$1 | ~/install/PathPicker/fpp || true; tmux delete-buffer -b fpp-$1"
# }

_urlview() {
  tmux capture-pane -J -S - -E - -b "urlview-$1" -t "$1"
  tmux split-window "tmux show-buffer -b urlview-$1 | urlview || true; tmux delete-buffer -b urlview-$1"
}

"$@"
