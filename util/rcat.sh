#!/bin/sh
# a simple utility to recursive cat files in a dir

# original author
# https://github.com/allpower2slaves

# by default, it should print out headers (i think)
# must be posix-compatible(!!!) NOTE: this thing can also use realpath, which is a part of GNU coreutils and BSD utils so i guess im clear

# positional variables (or whatever you can call em)
# DO NOT INDEX by '.' symbol -- find will show it no matter what options i use

# TODO:
# disable command output (aka no 'cat' in front of the filename) (debatable)
# option to disable filename output completely
# option to just list the indexed files (btw i think -c '' construction is ok
# just make the parser because if its empty as is it will try to launch every
# indexed file which is bad and insecure and whatever) (i mean instead of
# reinventing the wheel just use working -c '' construction and just make the
# check IF the $rcat_cat_executable is empty, dont actually exec anything)
# (also this check will actually INCREASE security so uhh we can call it a security feature :))
# actually it was wrong and i disabled it but whatever
# option to filter the file output via something
# option maybe some kind of switch to handle empty files

# todo secondary
# option to disable color (probably create a new color variable and make stdout
# check much earlier then) (i think theres no need for moving stdout after
# having a second thought) (actually i should assign the variable FIRST via
# parsing options or checking stdout, and only check the variable and print
# colors based on that variable)
# option to set the custom delimiter (its a very hackable solution because the
# end user could use $rcat_* variables with them)
# option to reenable commadn output (aka `cat` in front of the filename)
# (actually thing thing is A overkill, B can be implemented with setting custom delimiter)

# notes
# thanks to the modular design of this program (all functions are indepent of
# each other and only use shared global main level variables), its easy to add
# new features. also it seems that the indexer function doesnt even need any
# tweaking
# interesting thing -- this script actually can print out the same file twice
# if it meets a symlink to a text file. disabling POSIXLY_CORRECT in find
# part is not an option, because it will break POSIX compatibility. is
# dublicate output even a problem? POSIX find has -h option to actually print
# out if a symbolic link is a symbolic link. ill keep it as it for now


rcat_index="" # variable for dir\file setting


# varbiables for options
rcat_insert_newline="0"
rcat_insert_filename="0"
# variable for separator
rcat_quiet="0"
rcat_sep="\n" # maybe use it with printf idk; currently unused

# advanced
rcat_cat_variables=""
rcat_ignore_git="1" # ignore .git directory :)
rcat_ignore_dot="1" # ignore all files starting with .
rcat_ignore_binary="1" # do not cat binary files
rcat_realpath="0" # if 1, print out realpath

rcat_cat_executable="cat"

rcat_skip_executable="0" # if yes, dont execute anything (dont open the file)

# stuff that will source itself (DO NOT TOUCH)
rcat_cat_printname="" 
rcat_print_file_filename=""

find_options="" # options for find thing
find_after_pipe=""

parse_options(){
while :; do
	case $1 in
		-h | --help)
			print_help
			exit 0;;
		-v | --verbose) 
			set -o xtrace # TODO: posixfy
			shift
			;;
		-q | --quiet) # disable separator newline and newfile
			rcat_quiet="1"
			shift
			;;
		-a) # show files starting with dot, excluding git
			rcat_ignore_dot="0"
			shift
			;;
		-A | --all) # show everything, including .git
			rcat_ignore_dot="0"
			rcat_ignore_git="0"
			shift
			;;
		-b | --binary) # also cat binary files
			rcat_ignore_binary="0"
			shift
			;;
		-R | --realpath) # index realpath filenames
			rcat_realpath="1"
			shift
			;;
		# todo: make grep-like thing maybe(?)
		# todo: make the thing use * maybe
		-e | --exclude) # exclude pattern
			find_after_pipe="${find_after_pipe} | grep -v '$2'"
			shift
			shift
			;;
		-c | --command) # execute command on files (default:cat)
			# check if the command is even valid
			test -n "$2" && command -v $(printf "$2" | cut -d' ' -f1) 1>/dev/null || exit 1
			rcat_cat_executable="$2"
			shift
			shift
			;;
		-l | --list) # dont open the file, old -c '' behavior
			rcat_skip_executable="1"
			shift
			;;
		--) # end of all options
			shift
			break
			;;
		-*) # invalid option
			printf >&2 "ERROR: Invalid flag '%s'\n\n" "$1"
			print_help
			exit 1
			;;
		*) # when there are no more options
			if [ -n "$1" ]; then
				rcat_index="$1"
			else
				rcat_index="."
			fi
			break
	esac
done

# sanitize -c
rcat_cat_executable=$(printf "$rcat_cat_executable" | sed 's/^[ \t]*//' | sed 's/ *$//')
}

print_help(){
# i think i could use one string here...
printf '%s\n' \
'rcat' \
'made by https://github.com/allpower2slaves' \
'' \
'Options:' \
'	-h, --help -- show help' \
'	-v, --verbose -- enable verbose debug' \
'	-a -- do not ignore entries starting with . (excluding `./git/`)' \
'	-A, --all -- do not ignore entries starting with .' \
'	-q, --quiet -- do not print out filename' \
'	-b, --binary -- do not ignore non-text files' \
'	-l, --list -- print out indexed filenames' \
'	-e <PATTERN>, --exclude <PATTERN> -- exclude `<PATTERN>`' \
'	-c <COMMAND>, -command <PATTERN> -- command to execute on every indexed file' \
'	-R, --realpath -- non-POSIX option: print out absolute filenames'
}

get_files(){ 
# function to parse all uhh

# NOTE: i changed it to `find | grep` because `-not` is absent in POSIX and busybox
# actually its a lie they have ! so i changed it to proper syntax

if [ $rcat_ignore_dot -eq 1 ]; then
	find_options="${find_options} ! -name '.*'"
fi
if [ $rcat_ignore_git -eq 1 ]; then
	find_options="${find_options} ! -path '.git'"
fi

# todo: maybe add `-t` trace mode option to xtrace with -v
if [ $rcat_realpath -eq 1 ]; then
	find_after_pipe="${find_after_pipe} | xargs realpath"
fi

# return the thing #todo: reeval the 2>/dev/null thing please
#eval "find "$1" $find_options $find_after_pipe 2>/dev/null" 2>/dev/null

eval "find "$1" $find_options $find_after_pipe"
return 0
}

check_files(){
# function is basically "is this file a textfile
# do i need return here? idk

if [ $rcat_ignore_binary -ne 0 ]; then
POSIXLY_CORRECT=1 file "$1" | grep -q -e ':.*text' -e ':.*empty'
else
	return 0
fi
}

print_file(){
# add a space after a command, basically
# maybe this thing should be in `parse_options` function
if [ $rcat_skip_executable -eq 1 ]; then
	rcat_cat_printname=''
else
	rcat_cat_printname=$rcat_cat_executable
fi

# set rcat_print_file_filename
rcat_print_file_filename="$(printf "$1" | sed -e 's/[[:space:]]/\\\ /g')"


# main thing
if [ $rcat_quiet -eq 0 ]; then
	if [ -t 1 ]; then # if stdout is terminal
		printf "%b%s%b" "\033[33;1m" "$rcat_cat_printname""$rcat_print_file_filename" "\033[0m\n"
	else
		printf "%s%b" "$rcat_cat_printname""$rcat_print_file_filename" "\n"
	fi
fi

# why return 0? because otherwise test part returns 1 and theres no real problem
# in this line returning 1 because it was designed to handle fails (aka when
# the $rcat_cat_executable is empty just dont eval and thats it. we move
# forward we live we love we laugh
test $rcat_skip_executable -eq 0 && eval '$rcat_cat_executable "$1"' || return 0
}

# debug
#echo $find_after_pipe
#echo $rcat_cat_executable

#get_files "$rcat_index" | while IFS= read -r filename; do check_files "$filename" && echo "$filename" ; done

parse_options "$@"
get_files "$rcat_index" | while IFS= read -r filename; do check_files "$filename" && print_file "$filename"; done
