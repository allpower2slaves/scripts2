#!/usr/bin/env python

import os
import sys
import shutil
import magic
import argparse

import logging
logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)

def main (): # it just collects the options and sanitizes input, nothing more. firectory checks and whatever will be handled later
    filelist = [] # for storing stuff like... filenames. you know
    excludelist = ['.git'] # for storing git and other cruft

    prs = argparse.ArgumentParser(description="hello world")
    prs.add_argument("directory_tree",
                     help="directory",
                     action="store",
                     nargs='*')
    prs.add_argument("-v", "--version",
                    help="print author information",
                    action="store_true",
                    )
    prs.add_argument("-G", "--git",
                    help="also index .git/ directories",
                    action="store_true")
    prs.add_argument("-b", "--binary",
                    help="also index binary files",
                    action="store_true")
    grp = prs.add_mutually_exclusive_group()
    #grp.add_argument("-R", "--raw"
    #                help="read files as is, conflicts with -c",
    #                action="store_true",)
    grp.add_argument("-c", "--command",
                    help="command to run on indexed files",
                    action="store",
                    type=str)
    prs.add_argument("-e", "--exclude",
                    help="patterns to exclude",
                    action="store",
                    type=str) # will be converted to array later idk

    args=prs.parse_args()
    logging.debug(args)

    #DEBUG:root:Namespace(directory_tree='/tmp', version=False, git=False, binary=False)

    # excludelist manipulation i
    if args.git:
        excludelist.remove(".git")

    # excludelist manipulation ii
    if args.exclude != None:
        for file in args.exclude.split():
            excludelist.append(file)

    logging.debug(excludelist)

    # main functionality
    for file in (make_filelist(args.directory_tree, excludelist)):
        if not args.binary:
            if is_textfile(file):
                filelist.append(file)
        else:
            filelist.append(file)

    logging.debug(filelist)

    for file in filelist:
        print_header(file)
        print_file(file, args.command)

def make_filelist(paths=[], excludelist = [], depth="placeholder", sorting=False):
    returnlist = []

    # quick checks
    for path in paths:
        if not os.path.exists(path):
            raise ValueError("path not found")

        if os.path.isfile(path):
        #raise ValueError("Not a directory, exiting...")
            returnlist.append(path)
    
        # the main thing
        if os.path.isdir(path):
            for root, dirs, files in os.walk(path, topdown=True):
                dirs[:] = [d for d in dirs if d not in excludelist]
                for file in files:
                    file = (os.path.join(root, file))
                    returnlist.append(file)

    return returnlist




def is_textfile(file): # returns bool
    try:
        filetype = magic.detect_from_filename(file)
        filetype = (filetype.mime_type).partition('/')[0]
    except Valueerror:
        pass

    return(filetype == "text")




def print_header(file, method=''):
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
        print(colors.YELLOW + (method + ' ' + file).strip() + colors.RESET)
    else:
        print((method + ' ' + file).strip())

def print_file(file, method=None):
    if method == None:
       try:
            with open(file, 'r') as file:
                print(file.read()[:-1])
       except UnicodeDecodeError:
           pass
    else:
        command = method + ' ' + file
        os.system(command)


def print_help():
    print("hello")

main()
