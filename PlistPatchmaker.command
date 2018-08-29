#!/usr/bin/python
import plistlib
import os
import sys
import time

script_path = os.path.dirname(os.path.realpath(__file__))

def create_patch(add_plist = {}, rem_plist = {}, desc = "", gen = None):
    new_plist = { "Add": add_plist, "Remove": rem_plist, "Description": desc }
    if gen:
        new_plist["GenSMBIOS"] = gen
    return new_plist

def grab(prompt):
    if sys.version_info >= (3, 0):
        return input(prompt)
    else:
        return str(raw_input(prompt))

# OS Independent clear method
def cls():
    os.system('cls' if os.name=='nt' else 'clear')
    # Set Windows color to blue background, white foreground
    if os.name=='nt':
        os.system('COLOR 17')

def check_path(path):
    # Add os checks for path escaping/quote stripping
    if os.name == 'nt':
        # Windows - remove quotes
        path = path.replace('"', "")
    else:
        # Unix - remove quotes and space-escapes
        path = path.replace("\\", "").replace('"', "")
    # Remove trailing space if drag and dropped
    if path[len(path)-1:] == " ":
        path = path[:-1]
    # Expand tilde
    path = os.path.expanduser(path)
    if not os.path.exists(path):
        print("That file doesn't exist!")
        return None
    return path

def main():
    
    add_plist = None
    rem_plist = None
    desc      = ""
    smbios    = ""
    name      = ""
    existing_add = None
    existing_rem = None
    existing_des = None

    cls()

    print("This script can help make plist patches for Plist-Tool")
    print("Each entry must have at least an Add or Remove section")
    print("and a description.")
    print(" ")
    print("To leave a section empty (eg you're adding but not")
    print("removing), simply press enter at the prompt.")
    print(" ")
    print("If you'd like to edit an existing patch, drag and")
    print("drop it on the chat now - if you'd like to create")
    edit_plist = grab("a new patch, just press enter:  ")
    print(" ")

    if not edit_plist == "":
        # We need to edit
        edit_plist = check_path(edit_plist)
        if not edit_plist:
            exit(1)
        test_plist = plistlib.readPlist(edit_plist)
        existing_add = test_plist["Add"]
        existing_rem = test_plist["Remove"]
        existing_des = test_plist["Description"]

    add_plist = grab("Please select the plist containing the information to add:  ")
    if not add_plist == "":
        add_plist = check_path(add_plist)
        if not add_plist:
            exit(1)
        add_plist = plistlib.readPlist(add_plist)
        if "Add" in add_plist:
            # Only get the add sections
            add_plist = add_plist["Add"]
    else:
        add_plist = {}

    if add_plist == {} and existing_add:
        add_plist = existing_add

    print(" ")

    rem_plist = grab("Please select the plist containing the information to remove:  ")
    if not rem_plist == "":
        rem_plist = check_path(rem_plist)
        if not rem_plist:
            exit(1)
        rem_plist = plistlib.readPlist(rem_plist)
        if "Remove" in rem_plist:
            # Only get the remove sections
            rem_plist = rem_plist["Remove"]
    else:
        rem_plist = {}

    if rem_plist == {} and existing_rem:
        rem_plist = existing_rem

    print(" ")

    if add_plist == {} and rem_plist == {}:
        print("You need to at least add or remove something...")
        exit(1)

    while desc == "":
        desc = grab("Please enter the description for the patch:  ")
        if existing_des and desc == "":
            break

    if desc == "" and existing_des:
        desc = existing_des

    smbios = grab("Please enter the SMBIOS to gen (leave blank for none):  ")
    if not len(smbios):
        smbios = None

    plist_patch = create_patch(add_plist, rem_plist, desc, smbios)

    if not plist_patch:
        print("Something went wrong!")
        exit(1)

    print(" ")

    if edit_plist == "":

        while name == "":
            name = grab("Please enter the name for your patch - It will be \nlocated in the same directory as this script:  ")
            if not name.lower().endswith(".plist"):
                name = name + ".plist"
            if os.path.exists(script_path + "/" + name):
                print("That file already exists...\n")
                name = ""
        print("\nWriting plist...\n")
        plistlib.writePlist(plist_patch, script_path + "/" + name)
    else:
        print("\nWriting plist...\n")
        plistlib.writePlist(plist_patch, edit_plist)

    print("Done!\n\n")
    again = grab("Work on another patch? (y/n):  ")
    if again[:1].lower() == "y":
        main()
    else:
        exit(0)

main()