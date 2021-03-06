# cumul.sh

A cumulative executor - most practical for not having to wait until a locking process finishes before issuing a new command.

Queue items cumulatively for a command to run

	cumul SOURCEFILE -- COMMAND ...

Pops the top line of the file, and runs it as argument to the command

	cumul add SOURCEFILE [TOKENS ...]

Add each token as a line to the bottom of the file for execution. If CONTENTLINE is not specified, uses $EDITOR to supply lines.

If `EDITOR` is not set, uses nano

## Examples

### Installing packages

Session 1 - set up queued execution

	cumul.sh add packages htop tmux
	cumul.sh packages -- apt-get install -y {%}

Session 2 - remember other things you want to add

	cumul.sh add packages apache2 php libapache2-mod-php

### Copying files

Session 1

	cumul.sh add dirs Music Pictures
	cumul.sh dirs -- rsync -az {%} me@server:./

	# note -- "cumul.sh dirs -- rsync -az {%} me@server:./{%}" would not work

Session 2 - remember you wanted to sync something else

	cumul.sh add dirs Videos Documents
