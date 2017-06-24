import plistlib
import os
import sys
import time
import collections
import copy

# Inital vars
comment_prefix = "#"
current_plist  = None
script_path = os.path.dirname(os.path.realpath(__file__))

# OS Independent clear method
def cls():
	os.system('cls' if os.name=='nt' else 'clear')
	# Set Windows color to blue background, white foreground
	if os.name=='nt':
		os.system('COLOR 17')
	
# Print color - found here:  https://stackoverflow.com/a/21786287
def cprint(text, color = '0;37;44'):
	if not os.name == 'nt':
		# Not windows - use ANSI escapes
		#print('\x1b[{}m{}\x1b[0m'.format(color, text))
		print(text)
	else:
		print(text)


###########################################
#         Plist cleaning methods          #
###########################################

def check_keys(a_dict):
	# Checks all keys recursively
	tempDict = {}
	for key in a_dict:
		if key.startswith(comment_prefix):
			# It's a comment
			continue
		elif type(a_dict[key]) is list:
			temp = check_array(a_dict[key])
			if len(temp):
				tempDict[key] = temp
		elif type(a_dict[key]) is plistlib._InternalDict:
			temp = check_keys(a_dict[key])
			if len(temp):
				tempDict[key] = temp
		elif type(a_dict[key]) is str:
			if a_dict[key].startswith(comment_prefix):
				continue
			else:
				tempDict[key] = a_dict[key]
		else:
			# Not a dict or array - pass it in
			tempDict[key] = a_dict[key]
	return tempDict

def check_array(an_array):
	# Checks arrays recursively
	tempArray = []
	for item in an_array:
		if type(item) is plistlib._InternalDict:
			temp = check_keys(item)
			if len(temp):
				tempArray.append(temp)
		elif type(item) is list:
			temp = check_array(item)
			if len(temp):
				tempArray.append(temp)
		elif type(item) is str:
			if item.startswith(comment_prefix):
				continue
			else:
				tempArray.append(item)
		else:
			tempArray.append(item)
	return tempArray

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
		cprint("That file doesn't exist!")
		return None
	return path

###########################################
#      Python 2/3 independent input       #
###########################################

def grab(prompt):
	if sys.version_info >= (3, 0):
		return input(prompt)
	else:
		return str(raw_input(prompt))

# Header drawing method
def head(text = "CorpTool", width = 50):
	cprint("  {}".format("#"*width))
	mid_len = int(round(width/2-len(text)/2)-2)
	middle = " #{}{}{}#".format(" "*mid_len, text, " "*((width - mid_len - len(text))-2))
	cprint(middle)
	cprint("#"*width)

###########################################
#               Main Method               #
###########################################

def main():
	cls()
	head("Plist Tool - CorpNewt")
	cprint(" ")
	if current_plist:
		cprint("Current Plist: {}".format(current_plist))
		cprint(" ")
	cprint("1. Clean plist of comments")
	cprint("2. Patch Menu")
	#cprint("3. Update/Install kexts")
	cprint(" ")
	cprint("P. Select Plist")
	cprint("Q. Quit")
	cprint(" ")
	
	menu = grab("Please select an option:  ")
	if menu.lower()[:1] == "q":
		exit(0)
	elif menu[:1].lower() == "p":
		set_plist()
	elif menu[:1] == "1":
		if not current_plist:
			set_plist()
			if current_plist:
				clean_plist()
		else:
			clean_plist()
	elif menu[:1] == "2":
		if not current_plist:
			select_plist()
		else:
			patch_menu()
	#elif menu[:1] == "3":
	#    update_kexts()
	main()

###########################################
#               Clean Plist               #
###########################################

def set_plist():
	cls()
	head("Plist Select")
	cprint(" ")
	file_input = grab("Please drag and drop the plist on the terminal:  ")
	cprint(" ")
	file_input = check_path(file_input)
	if not file_input:
		# No dice
		cprint("That plist doesn't exist!")
		time.sleep(5)
		return None
	global current_plist 
	current_plist = file_input
	return current_plist

def clean_plist():
	cls()
	head("Clean Plist")
	cprint(" ")
	# Let's load it as a plist
	plist = None
	plist = plistlib.readPlist(current_plist)
	# Check if we got anything
	if plist == None:
		cprint("That plist either failed to load - or was empty!")
		exit(1)
	# Iterate and strip comments
	new_dict = check_keys(plist)
	# Write the new file
	plistlib.writePlist(new_dict, current_plist)
	cprint("Done!\n")
	time.sleep(5)

###########################################
#                Git Pulls                #
###########################################

#def git_pull(url, compile):

###########################################
#                 Patches                 #
###########################################

def select_plist():
	cls()
	head("Plist Select")
	cprint(" ")
	file_input = grab("Please drag and drop the plist on the terminal:  ")
	cprint(" ")
	file_input = check_path(file_input)
	if not file_input:
		# No dice
		time.sleep(5)
		return
	global current_plist 
	current_plist = file_input
	patch_menu()
	return

def patch_menu():
	cls()
	head("Patch Menu")
	cprint(" ")
	if current_plist:
		cprint("Current Plist: {}".format(current_plist))
		cprint(" ")
	cprint("1. Add Patches")
	cprint("2. [someday] Gen SMBIOS")
	cprint(" ")
	cprint("M. Main Menu")
	cprint(" ")
	menu = grab("Please select an option:  ")
	if menu.lower()[:1] == "m":
		return
	elif menu[:1] == "1":
		add_patches()
		return
	patch_menu()
	return

def gen_smbios():
	cprint("No dice, grandma.  This feature isn't added yet.")
	time.sleep(5)

def add_patches():
	cls()
	head("Plist Patches")
	cprint(" ")
	if current_plist:
		cprint("Current Plist: {}".format(current_plist))
		cprint(" ")
	# List the types of patches we have
	dir_list = []
	for d in os.listdir(script_path+"/Resources"):
		if os.path.isdir(script_path+"/Resources/"+d):
			dir_list.append(d)
	if not len(dir_list):
		cprint("No patches available!")
		time.sleep(5)
		return
	
	count = 0
	m = ""
	for d in dir_list:
		count += 1
		m += str(count) + ". " + d + "\n"
	
	m += "\nP. Patch Menu\n"
	m += "M. Main Menu\n"


	cprint(m)
	menu = grab("Please select an option:  ")
	
	if menu[:1].lower() == "m":
		main()
		return
	elif menu[:1].lower() == "p":
		patch_menu()
		return
	
	try:
		menu = int(menu)
	except Exception:
		add_patches()
		return
	
	if menu > 0 and menu <= len(dir_list):
		list_patches(dir_list[menu-1])
	
	add_patches()
	return


def list_patches(name):
	cls()
	head("{} Patches".format(name))
	cprint(" ")
	if current_plist:
		cprint("Current Plist: {}".format(current_plist))
		cprint(" ")
	# List the types of patches we have
	plist_list = []
	for d in os.listdir(script_path+"/Resources/"+name):
		if d.lower().endswith(".plist"):
			plist_list.append(d)
	if not len(plist_list):
		cprint("No patches available!")
		time.sleep(5)
		return

	count = 0
	m = ""
	for d in plist_list:
		count += 1
		if d.lower().endswith(".plist"):
			d = d[:-len(".plist")]
		m += str(count) + ". " + d + "\n"
	
	m += "\nP. Plist Patches\n"
	m += "M. Main Menu\n"

	cprint(m)
	menu = grab("Please select an option:  ")

	if menu[:1].lower() == "m":
		main()
		return
	elif menu[:1].lower() == "p":
		add_patches()
		return
	try:
		menu = int(menu)
	except Exception:
		add_patches()
		return
	if menu > 0 and menu <= len(plist_list):
		# Handle all patching at once
		list_patch(plist_list[menu-1], os.path.abspath(script_path+"/Resources/"+name+"/"+plist_list[menu-1]))
	list_patches(name)
	return

def list_patch(patch, p):
	cls()
	head("{}".format(patch[:-len(".plist")]))
	cprint(" ")
	# Let's load it as a plist
	plist = None
	plist = plistlib.readPlist(current_plist)
	# Check if we got anything
	if plist == None:
		cprint("That plist either failed to load - or was empty!")
		exit(1)
	patch_plist = None
	patch_plist = plistlib.readPlist(p)
	if patch_plist == None:
		cprint("That plist either failed to load - or was empty!")
		exit(1)
	if (not "Add" in patch_plist) or (not "Remove" in patch_plist) or (not "Description" in patch_plist):
		cprint("The patch is incomplete!  Not applied!")
		time.sleep(5)
		return
	# Gather our info
	p_merge = patch_plist["Add"]
	p_rem   = patch_plist["Remove"]
	p_desc  = patch_plist["Description"]
	cprint(p_desc)
	cprint(" ")
	menu = grab("Apply patch? (y/n):  ")
	if menu[:1].lower() == "y":
		merge_patch(p_merge, p_rem, p_desc, plist, patch)
	elif menu[:1].lower() == "n":
		return
	else:
		list_patch(patch, p)
		return

def merge_patch(p_merge, p_rem, p_desc, plist, patch):
	cls()
	head("Applying {}".format(patch[:-len(".plist")]))
	cprint(" ")
	cprint(p_desc)
	cprint(" ")
	# Both plists have loaded
	# Remove first - then add
	plist = remerge(p_rem, plist)
	plist = merge_dicts(p_merge, plist)
	# Write the new file
	plistlib.writePlist(plist, current_plist)
	cprint("Done!\n")
	time.sleep(5)

def remerge(w, f):
	# Remove patches with from
	temp = copy.deepcopy(f)
	for key in w:
		if not key in f:
			# Don't have it
			continue
		if type(w[key]) is plistlib._InternalDict:
			if not len(w[key]):
				del temp[key]
				continue
			temp[key] = remerge(w[key], f[key])
			if not len(temp[key]):
				del temp[key]
		elif type(w[key]) is list:
			if not len(w[key]):
				del temp[key]
			temp[key] = remerge_list(w[key], f[key])
			if not len(temp[key]):
				del temp[key]
		else:
			# Not a list or dict - remove it
			del temp[key]
	return temp

def remerge_list(w, f):
	# Remove patches with from
	temp = copy.deepcopy(f)
	for item in w:
		if item in temp:
			temp.remove(item)
		elif type(item) is plistlib._InternalDict:
			if "Find" in item and "Replace" in item:
				find = item["Find"]
				replace = item["Replace"]
				for test in f:
					try:
						f_check = test["Find"]
						r_check = test["Replace"]
						if f_check == find and r_check == replace:
							temp.remove(test)
							# break # Replace all entries
					except Exception:
						continue
			elif "Key" in item and "Value" in item:
				key = item["Key"]
				value = item["Value"]
				for test in f:
					try:
						k_check = test["Key"]
						v_check = test["Value"]
						if k_check == key and v_check == value:
							temp.remove(test)
							# break # Replace all entries
					except Exception:
						continue
			elif "Name" in item:
				# We have a name, but no find/replace - removing the entry
				test_name = item["Name"]
				if test_name.startswith("*"):
					# Wildcard in name at beginning
					for test in f:
						if "Name" in test:
							if test["Name"].lower().endswith(test_name[1:].lower()):
								temp.remove(test)
				elif test_name.endswith("*"):
					# Wildcard in name at end
					for test in f:
						if "Name" in test:
							if test["Name"].lower().startswith(test_name[:-1].lower()):
								temp.remove(test)
				else:
					# No wildcard at either end
					for test in f:
						if "Name" in test:
							if test["Name"].lower() == test_name.lower():
								temp.remove(test)
			elif "Device" in item:
				# We have a device, but no key/value - removing the entry
				test_name = item["Device"]
				if test_name.startswith("*"):
					# Wildcard in device at beginning
					for test in f:
						if "Device" in test:
							if test["Device"].lower().endswith(test_name[1:].lower()):
								temp.remove(test)
				elif test_name.endswith("*"):
					# Wildcard in device at end
					for test in f:
						if "Device" in test:
							if test["Device"].lower().startswith(test_name[:-1].lower()):
								temp.remove(test)
				else:
					# No wildcard at either end
					for test in f:
						if "Device" in test:
							if test["Device"].lower() == test_name.lower():
								temp.remove(test)
	return temp

def merge_dicts(f, i):
	temp = copy.deepcopy(i)
	for key in f:
		if type(f[key]) is list:
			# Merge!
			if not key in i:
				temp[key] = f[key]
			else:
				temp[key] = merge_arrays(f[key], i[key])
		elif type(f[key]) is plistlib._InternalDict:
			if not key in i:
				temp[key] = f[key]
			else:
				temp[key] = merge_dicts(f[key], i[key])
		else:
			temp[key] = f[key]
	return temp

def merge_arrays(f, i):
	temp = copy.deepcopy(i)
	for item in f:
		if type(item) is str:
			if not item in i:
				temp.append(item)
		elif type(item) is plistlib._InternalDict:
			if "Find" in item and "Replace" in item:
				find = item["Find"]
				replace = item["Replace"]
				found = False
				for test in i:
					try:
						f_check = test["Find"]
						r_check = test["Replace"]
						if f_check == find and r_check == replace:
							dis = False
							if "Disabled" in item:
								dis = item["Disabled"]
							try:
								# Clone disable flag if exists
								index = temp.index(test)
								temp[index]["Disabled"] = dis
							except Exception:
								# Always set to false if failure
								temp[index]["Disabled"] = False
							found = True
							break
					except Exception:
						continue
				if not found:
					temp.append(item)
			elif "Key" in item and "Value" in item:
				key = item["Key"]
				value = item["Value"]
				found = False
				for test in i:
					try:
						k_check = test["Key"]
						v_check = test["Value"]
						if k_check == key and v_check == value:
							dis = False
							if "Disabled" in item:
								dis = item["Disabled"]
							try:
								# Clone disable flag if exists
								index = temp.index(test)
								temp[index]["Disabled"] = dis
							except Exception:
								temp[index]["Disabled"] = False
							found = True
							break
					except Exception:
						continue
				if not found:
					temp.append(item)
		else:
			if not item in i:
				temp.append(item)
	return temp

# Start the main method
main()
