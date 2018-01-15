#!/bin/bash

### cumul.sh Usage:help
#
# cumul.sh SOURCE -- COMMAND ...
#
# cumul.sh add SOURCE CONTENT ...
#
###/doc

### Safe mode Usage:bbuild
#
# Set safe mode options
#
# * Script bails on error
# * Accessing a variable that is not set is an error
# * If a file glob does not expand, cause an error condition
# * If a component of a pipe fails, the entire pipe is a failure
#
###/doc

set -eufo pipefail
#!/bin/bash

### autohelp:print Usage:bbuild
# Write your help as documentation comments in your script
#
# If you need to output the help from a running script, call the
# `autohelp:print` function and it will print the help documentation
# in the current script to stdout
#
# A help comment looks like this:
#
#	### <title> Usage:help
#	#
#	# <some content>
#	#
#	# end with "###/doc" on its own line (whitespaces before
#	# and after are OK)
#	#
#	###/doc
#
# You can set a different comment character by setting the 'HELPCHAR' environment variable:
#
# 	HELPCHAR=%
# 	autohelp:print
#
# You can set a different help section by specifying the 'SECTION_STRING' variable
#
# 	SECTION_STRING=subsection autohelp:print
#
###/doc

HELPCHAR='#'

function autohelp:print {
	local SECTION_STRING="${1:-}"; shift
	local TARGETFILE="${1:-}"; shift
	[[ -n "$SECTION_STRING" ]] || SECTION_STRING=help
	[[ -n "$TARGETFILE" ]] || TARGETFILE="$0"

        echo -e "\n$(basename "$TARGETFILE")\n===\n"
        local SECSTART='^\s*'"$HELPCHAR$HELPCHAR$HELPCHAR"'\s+(.+?)\s+Usage:'"$SECTION_STRING"'\s*$'
        local SECEND='^\s*'"$HELPCHAR$HELPCHAR$HELPCHAR"'\s*/doc\s*$'
        local insec=false

        while read secline; do
                if [[ "$secline" =~ $SECSTART ]]; then
                        insec=true
                        echo -e "\n${BASH_REMATCH[1]}\n---\n"

                elif [[ "$insec" = true ]]; then
                        if [[ "$secline" =~ $SECEND ]]; then
                                insec=false
                        else
				echo "$secline" | sed -r "s/^\s*$HELPCHAR//g"
                        fi
                fi
        done < "$TARGETFILE"

        if [[ "$insec" = true ]]; then
                echo "WARNING: Non-terminated help block." 1>&2
        fi
	echo ""
}

### automatic help Usage:main
#
# automatically call help if "--help" is detected in arguments
#
###/doc
if [[ "$*" =~ --help ]]; then
	cols="$(tput cols)"
	autohelp:print | fold -w "$cols" -s || autohelp:print
	exit 0
fi
#!/bin/bash

#!/bin/bash

### Colours for bash Usage:bbuild
# A series of colour flags for use in outputs.
#
# Example:
# 	
# 	echo "${CRED}Some red text ${CBBLU} some blue text $CDEF some text in the terminal's default colour"
#
# Colours available:
#
# CDEF -- switches to the terminal default
#
# CRED, CBRED -- red, bold red
# CGRN, CBGRN -- green, bold green
# CYEL, CBYEL -- yellow, bold yellow
# CBLU, CBBLU -- blue, bold blue
# CPUR, CBPUR -- purple, bold purple
#
###/doc

export CRED="\033[0;31m"
export CGRN="\033[0;32m"
export CYEL="\033[0;33m"
export CBLU="\033[0;34m"
export CPUR="\033[0;35m"
export CBRED="\033[1;31m"
export CBGRN="\033[1;32m"
export CBYEL="\033[1;33m"
export CBBLU="\033[1;34m"
export CBPUR="\033[1;35m"
export CDEF="\033[0m"

### Console output handlers Usage:bbuild
#
# Write data to console stderr using colouring
#
###/doc

### Environment Variables Usage:bbuild
#
# MODE_DEBUG : set to 'true' to enable debugging output
# MODE_DEBUG_VERBOSE : set to 'true' to enable command echoing
#
###/doc

: ${MODE_DEBUG=false}
: ${MODE_DEBUG_VERBOSE=false}

### out:debug MESSAGE Usage:bbuild
# print a blue debug message to stderr
# only prints if MODE_DEBUG is set to "true"
###/doc
function out:debug {
	if [[ "$MODE_DEBUG" = true ]]; then
		echo -e "${CBBLU}DEBUG:$CBLU$*$CDEF" 1>&2
	fi
}

### out:info MESSAGE Usage:bbuild
# print a green informational message to stderr
###/doc
function out:info {
	echo -e "$CGRN$*$CDEF" 1>&2
}

### out:warn MESSAGE Usage:bbuild
# print a yellow warning message to stderr
###/doc
function out:warn {
	echo -e "${CBYEL}WARN:$CYEL $*$CDEF" 1>&2
}

### out:fail [CODE] MESSAGE Usage:bbuild
# print a red failure message to stderr and exit with CODE
# CODE must be a number
# if no code is specified, error code 127 is used
###/doc
function out:fail {
	local ERCODE=127
	local numpat='^[0-9]+$'

	if [[ "$1" =~ $numpat ]]; then
		ERCODE="$1"; shift
	fi

	echo -e "${CBRED}ERROR FAIL:$CRED$*$CDEF" 1>&2
	exit $ERCODE
}

### out:dump Usage:bbuild
#
# Dump stdin contents to console stderr. Requires debug mode.
#
# Example
#
# 	action_command 2>&1 | out:dump
#
###/doc

function out:dump {
	echo -e -n "${CBPUR}$*" 1>&2
	echo -e -n "$CPUR" 1>&2
	cat - 1>&2
	echo -e -n "$CDEF" 1>&2
}

### out:break MESSAGE Usage:bbuild
#
# Add break points to a script
#
# Requires debug mode set to true
#
# When the script runs, the message is printed with a propmt, and execution pauses.
#
# Type `exit`, `quit` or `stop` to stop the program. If the breakpoint is in a subshell,
#  execution from after the subshell will be resumed.
#
# Press return to continue execution.
#
###/doc

function out:break {
	[[ "$MODE_DEBUG" = true ]] || return

	read -p "${CRED}BREAKPOINT: $* >$CDEF " >&2
	if [[ "$REPLY" =~ quit|exit|stop ]]; then
		out:fail "ABORT"
	fi
}

[[ "$MODE_DEBUG_VERBOSE" = true ]] && set -x || :

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
