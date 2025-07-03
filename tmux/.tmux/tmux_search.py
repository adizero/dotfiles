#!/usr/bin/env python3

import subprocess
import sys
import re


def print_usage():
    print("Usage: tmux_search.py [--tmux] <search_term(s)>")
    print("Search for a term in all tmux windows and panes.")
    print("If --tmux is specified, the script will run in tmux mode.")
    print("If no search term is provided, the script will exit.")


def main():
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)

    tmux_binding = False
    if sys.argv[1] == "--tmux":
        tmux_binding = True
        if len(sys.argv) < 3:
            print_usage()
            sys.exit(1)

    first_search_term = 2 if tmux_binding else 1
    search_terms = " ".join(sys.argv[first_search_term:])

    try:
        # Get list of tmux windows with IDs and names
        windows_output = subprocess.run(
            ["tmux", "list-windows", "-F", "#{window_id}:#{window_name}"],
            capture_output=True,
            text=True,
            check=True
        ).stdout.strip()

        if not windows_output:
            print("No tmux windows found.")
            sys.exit(0)

        all_lower = search_terms.islower()

        windows_lines = windows_output.splitlines()
        if not tmux_binding:
            print(
                f"Scanning {len(windows_lines)} tmux windows for '{search_terms}' ..."
            )

        results = []
        for window_line in windows_lines:
            window_id, _ = window_line.split(":", 1)

            # Get list of panes in the current window
            panes_output = subprocess.run(
                ["tmux", "list-panes", "-t", window_id, "-F", "#{pane_id}"],
                capture_output=True,
                text=True,
                check=True
            ).stdout.strip()

            if not panes_output:
                continue

            for pane_id in panes_output.splitlines():
                # Capture scrollback history of the pane (-S - means start from the beginning of the scrollback history)
                # The history limit can be checked via: tmux show-options -gv history-limit
                scrollback_output = subprocess.run(
                    ["tmux", "capture-pane", "-p", "-S", "-", "-t", pane_id], capture_output=True, text=True, check=True
                ).stdout.strip()

                if not scrollback_output:
                    continue

                counter = 1
                for line in scrollback_output.splitlines():
                    # Count number of times the search term appears in the line (use smart case search)
                    occurences_count = line.lower().count(search_terms.lower()) if all_lower else line.count(search_terms)
                    if occurences_count > 0:
                        results.append(f"{window_id}:{pane_id}:{counter}:{line}")
                        counter += occurences_count

        if not results:
            print(f"No occurrences of '{search_terms}' found in any tmux window scrollback history.")
            sys.exit(0)

        # escape special characters to make the grep_term suitable for grep (like - and possible others)
        # re.escape is not perfect for grep, but should work for most cases
        grep_terms = re.escape(search_terms)

        # Pipe results to fzf
        fzf_command = [
            "fzf",
            "--delimiter",
            ":",
            "--preview-window",
            "top:10%:wrap",
            "--preview",
            f"echo {{}} | cut -d ':' -f 4- | grep {'-i' if all_lower else ''} --color=always \"{grep_terms}\"",
        ]
        if tmux_binding:
            fzf_command += [
                "--tmux",
                "center,100%",
            ]
        fzf_process = subprocess.Popen(
            fzf_command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
        )
        fzf_output, _ = fzf_process.communicate("\n".join(results))

        if fzf_process.returncode != 0 or not fzf_output.strip():
            if not tmux_binding:
                print("No item selected in fzf.")
            sys.exit(0)

        selected = fzf_output.strip()
        selected_parts = selected.split(":", 3)
        if len(selected_parts) < 3:
            print("Could not extract window and pane information from the selection.")
            sys.exit(1)

        selected_window_id = selected_parts[0]
        selected_pane_id = selected_parts[1]
        selected_counter = selected_parts[2]

        if not tmux_binding:
            print(
                f"Jumping to window: {selected_window_id}, pane: {selected_pane_id}"
                f" - searching for '{search_terms}' occurrence number {selected_counter}"
            )

        # Enter tmux copy-mode in the selected pane
        subprocess.run(["tmux", "copy-mode", "-t", selected_pane_id], check=True)

        # Jump to the end of the scrollback history (bottom)
        subprocess.run(["tmux", "send-keys", "-t", selected_pane_id, "-X", "history-bottom"], check=True)

        # Send the command to search forward
        # (wrapping around bottom to make sure we find the first occurrence at first line)
        subprocess.run(["tmux", "send-keys", "-t", selected_pane_id, "-X", "search-forward", search_terms], check=True)
        for _ in range(int(selected_counter) - 1):
            subprocess.run(["tmux", "send-keys", "-t", selected_pane_id, "-X", "search-again"], check=True)

        # Center the search result in the pane
        # bug in tmux - scroll-middle command clear the search highlight (same as nohls in vim)
        # subprocess.run(["tmux", "send-keys", "-t", selected_pane_id, "-X", "scroll-middle"], check=True)

        # Select the target pane
        subprocess.run(["tmux", "select-pane", "-t", selected_pane_id], check=True)

        # Switch to the target window
        subprocess.run(["tmux", "select-window", "-t", selected_window_id], check=True)

    except FileNotFoundError:
        print("Error: tmux or fzf not found. Please ensure they are installed and in your PATH.")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Error running tmux command: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
