import plistlib
import os
import sys
import time

script_path = os.path.dirname(os.path.realpath(__file__))

def create_patch(add, remove, description):
    if add == "":
        add_plist = {}
    else:
        add_plist = plistlib.readPlist(add)
    if remove == "":
        rem_plist = {}
    else:
        rem_plist = plistlib.readPlist(remove)
    try:
        new_plist = { "Add": add_plist, "Remove": rem_plist, "Description": desc }
    except Exception:
        new_plist = None
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

add_plist = None
rem_plist = None
desc      = ""
name      = ""

cls()

print("This script can help make plist patches for Plist-Tool")
print("Each entry must have at least an Add or Remove section")
print("and a description.")
print(" ")
print("To leave a section empty (eg you're adding but not")
print("removing), simply press enter at the prompt.")
print(" ")

add_plist = grab("Please select the plist containing the information to add:  ")
if not add_plist == "":
    add_plist = check_path(add_plist)
    if not add_plist:
        exit(1)

print(" ")

rem_plist = grab("Please select the plist containing the information to remove:  ")
if not rem_plist == "":
    rem_plist = check_path(rem_plist)
    if not rem_plist:
        exit(1)

print(" ")

if add_plist == "" and rem_plist == "":
    print("You need to at least add or remove something...")
    exit(1)

while desc == "":
    desc = grab("Please enter the description for the patch:  ")

plist_patch = create_patch(add_plist, rem_plist, desc)

if not plist_patch:
    print("Something went wrong!")
    exit(1)

print(" ")

while name == "":
    name = grab("Please enter the name for your patch - It will be \nlocated in the same directory as this script:  ")
    if not name.lower().endswith(".plist"):
        name = name + ".plist"
    if os.path.exists(script_path + "/" + name):
        print("That file already exists...\n")
        name = ""

print("\nWriting plist...\n")
plistlib.writePlist(plist_patch, script_path + "/" + name)
print("Done!\n\n")
grab("Press enter to exit...")
exit(0)
