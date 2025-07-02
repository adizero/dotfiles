#!/usr/bin/env bash
# current_layout=$(i3-msg -t get_tree | jq -r 'recurse(.nodes[];.nodes!=null)|select(.nodes[].focused).layout')
# currently_focused_workspace=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).name')

show_usage()
{
    printf "%s\n" "Usage: ${0} {left|right}"
    cat << EOF

    Switches to neighboring i3wm workspace.
    E.g.: ${0} right
EOF
}

function get_focused_container()
{
    local __resultvar=$1
    local myresult="$(i3-msg -t get_tree | jq '.. | objects | select(.focused==true) | .id')"
    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$myresult'"
    else
        echo "$myresult"
    fi
}

function get_focused_container_x_pos()
{
    local __resultvar=$1
    local myresult="$(i3-msg -t get_tree | jq '.. | objects | select(.focused==true) | .rect.x')"
    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$myresult'"
    else
        echo "$myresult"
    fi
}

if [ ! "${#}" -eq 1 ] || [ "${1}" == "--help" ]; then
    show_usage
    exit 0
fi

get_focused_container_x_pos original_x

if [ "${1}" == "right" ]; then
        i3-msg focus right
else
        i3-msg focus left
fi

get_focused_container_x_pos current_x

if ([[ ${original_x} -ge ${current_x} ]] && [ "${1}" == "right" ]) ||
   ([[ ${original_x} -le ${current_x} ]] && [ "${1}" == "left" ]); then
    # i3-msg workspace next
    # using `next_on_output` should be better than just `next` in multi-monitor situation
    # move back to original window in the current workspace
    if [ "${1}" == "right" ]; then
        i3-msg focus left
    else
        i3-msg focus right
    fi
    # move on to another workspace
    if [ "${1}" == "right" ]; then
        i3-msg workspace next_on_output
    else
        i3-msg workspace prev_on_output
    fi
fi

# i3-msg '[con_id="94471992617168"]' focus
# i3-msg -t subscribe -m '[ "window" ]' | jq --unbuffered '. | select(.change=="focus") | .container.id' > /tmp/i3_previous_container
