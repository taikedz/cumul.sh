#!/bin/bash

### cumul.sh Usage:help
#
# cumul.sh SOURCE -- COMMAND ...
#
# cumul.sh add SOURCE CONTENT ...
#
###/doc

#%include safe.sh autohelp.sh out.sh

cumul:run() {
	local token="${1:-}"; shift

	if [[ "$token" != "--" ]]; then
		out:fail "Use '--' to start the command section"
	fi

	if [[ -z "$*" ]]; then
		out:fail "Specify a command to run. Optionally use '{%}' to indicate where to place your line arguments."
	fi

	while cumul:next ; do
		local execution_template=("$@")
		if [[ "${execution_template[*]}" =~ '{%}' ]]; then
			local i=0
			while [[ $i -lt ${#execution_template[@]} ]]; do
				[[ "${execution_template[$i]}" = '{%}' ]] || {
					i=$((i+1))
					continue
				}

				execution_template[$i]="$CURRENT_LINE"
				i=$((i+1))
			done
		else
			execution_template[${#execution_template[@]}]="$CURRENT_LINE"
		fi

		( set -x
			"${execution_template[@]}"
		)
	done
}

cumul:next() {
	[[ "$(wc -l "$SOURCEFILE"|cut -d' ' -f1)" -gt 0 ]] || return 1

	local firstline="$(head -n 1 "$SOURCEFILE")"
	sed '1 d' -i "$SOURCEFILE"
	CURRENT_LINE="$firstline"

	if [[ -z "$CURRENT_LINE" ]] || [[ "$CURRENT_LINE" =~ ^\s*# ]]; then
		cumul:next
		return "$?"
	fi

	return 0
}

cumul:add() {
	: ${EDITOR=nano}
	if [[ -z "$*" ]]; then
		"$EDITOR" ".$SOURCEFILE.tmp"
		if [[ -f ".$SOURCEFILE.tmp" ]]; then
			cat ".$SOURCEFILE.tmp" >> "$SOURCEFILE"
		fi
	else
		for token in "$@"; do
			echo "$token" >> "$SOURCEFILE"
		done
	fi
}

main() {
	SOURCEFILE="${1:-}"; shift || :

	if [[ "$SOURCEFILE" = add ]]; then
		SOURCEFILE="${1:-}"; shift
		cumul:add "$@"
	elif [[ -z "$SOURCEFILE" ]]; then
		autohelp:print
	else
		cumul:run "$@"
	fi
}

main "$@"
