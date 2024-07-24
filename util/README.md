# util
## Description
POSIX sh compatible tool for recursively opening all text files in a directory.

By default, `rcat` uses `cat` to open files, but that can be changed with `-c` option.
For example, to print out first 5 lines of all text files in a directory `hello/`:
```
rcat -c 'head -n 5' 'hello/'
```

To open all hidden files (those starting with a dot) -- use `-a` option. Keep
in mind that `-a` option will still **ignore** `.git/` directory, to index it and
all hidden files there is `-A` option.

This tool can also exclude certain files with patterns (it uses `grep` to
filter out filenames, so you can use `grep` syntax)
For example, this command will print out contents of every text file in current
directory with the exception of files found in `./git/` and files that match
the name `secret`:
```
rcat -a -e `secret`
```

If for some reason you want to just print out filenames, you can set `-c` option to be empty:
```
rcat -c ``
```
This will print out relative filenames of all textfiles. To print out all
abosulute filenames, you can use `-R` option (requires `realpath` to be
installed)
```
rcat -c `` -R
```

## Options
+ `-h, --help` -- show help
+ `-v, --verbose` -- enable verbose debug
+ `-a` -- do not ignore entries starting with . (excluding `./git/`)
+ `-A, --all` -- do not ignore entries starting with .
+ `-q, --quiet` -- do not print out filename
+ `-b, --binary` -- do not ignore non-text files
+ `-e <PATTERN>, --exclude <PATTERN>` -- exclude `<PATTERN>`
+ `-c <COMMAND>, -command <PATTERN>` -- command to execute on every indexed file
+ `-R, --realpath` -- non-POSIX option: print out absolute filenames
