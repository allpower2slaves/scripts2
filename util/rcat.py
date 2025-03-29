#!/usr/bin/env python

import os
import sys
import optparse
import shutil
import magic

import logging
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

index_git=False
index_binary=False

# parsing section
parser = optparse.OptionParser()

parser.set_defaults(filename="$PWD")

def check_filename(option, opt_str, value, parser):
    logging.debug(value)
    if not os.path.exists(value):
        raise optparse.OptionValueError("%s -- directory does not exist" % value)
    else:
        setattr(parser.values, option.dest, value)

def check_command(option, opt_str, value, parser):
    logging.debug(value)
    if not shutil.which(value):
        raise optparse.OptionValueError("%s -- command not found" % value)
    else:
        setattr(parser.values, option.dest, value)

parser.set_defaults(method="cat")
parser.set_defaults(output="color") # todo: change it. placeholder

parser.add_option('-d', '--directory',
                  action="callback", callback=check_filename, type="string", dest="filename")
parser.add_option('-c', '--command',
                  action="callback", help="command to run", callback=check_command, type="string", dest="method")
parser.add_option('-o', '--ouput',
                  help="output options", dest="separator")

parser.add_option('-G', '--git',
                  action="store_true", default=False, dest="index_git")
parser.add_option('-b', '--binary',
                  action="store_true", default=False, dest="index_binary")
(options, args) = parser.parse_args() 

logging.debug(options.index_git)
# parse end

def findfiles(filename, index_git=False, index_binary=False):
    returnlist = [] # list with all the files that got parsed and checked and whatever

    # first, set the dir
    if filename == "$PWD":
        filename = os.getcwd()

    excludelist = []
    if index_git == False:
        excludelist.append('.git')
    
    logging.debug(excludelist)

    # now create an array of files 
    for root, dirs, files in os.walk(filename, topdown=True):
        dirs[:] = [d for d in dirs if d not in excludelist] # strips directories defined in excludelist
        for file in files:
            file = (os.path.join(root, file))
            if index_binary == False:
                try:
                    filetype = magic.detect_from_filename(file)
                    filetype = (filetype.mime_type).partition('/')[0]
                    #logging.debug((filetype.mime_type).partition('/')[0]) # i need UNIX(tm) grep and sed here dammit.....
                except ValueError: # todo: replace this exception with libmagic thing? also fix the keyboard interrupt
                    pass

                if filetype == "text":
                    #logging.debug(file)
                    returnlist.append(file)

            else:
                returnlist.append(file)

    return returnlist

#for findfiles(options.filename,index_git,index_binary) # debug

def print_header(filename, method=''):
    # there should be several modes... rn ill just make one of em
    class colors(): # hardcoded colorlist, i dont care
        BLACK = '\033[30m'
        RED = '\033[31m'
        GREEN = '\033[32m'
        YELLOW = '\033[33m'
        BLUE = '\033[34m'
        MAGENTA = '\033[35m'
        CYAN = '\033[36m'
        WHITE = '\033[37m'
        UNDERLINE = '\033[4m'
        RESET = '\033[0m'

    if sys.stdout.isatty(): # maybe i should make a option to bypass it.. idk
        print(colors.YELLOW + (method + ' ' + filename).strip() + colors.RESET)
    else:
        print((method + ' ' + filename).strip())

def print_file(file,method="python"):
    if method == "python":
       try:
            with open(file, 'r') as file:
                print(file.read())
       except UnicodeDecodeError:
           pass

for file in findfiles(options.filename,index_git,index_binary):
    print_header(file)
    print_file(file)
