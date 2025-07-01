# some of the scripts call tools that require sudo
# sudo fails when it runs in non-interactive mode
# unless passwordless sudo is allowed for those tools
# add these lines to /etc/sudoers to make it work
# safest to edit with: sudo visudo
akocis ALL=(ALL) NOPASSWD:SETENV: /usr/bin/timeout
akocis ALL=(ALL) NOPASSWD:SETENV: /usr/bin/eject

