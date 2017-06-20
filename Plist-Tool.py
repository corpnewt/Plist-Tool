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
		print("That file doesn't exist!")
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
	print("  {}".format("#"*width))
	mid_len = int(round(width/2-len(text)/2)-2)
	middle = " #{}{}{}#".format(" "*mid_len, text, " "*((width - mid_len - len(text))-2))
	print(middle)
	print("#"*width)

###########################################
#               Main Method               #
###########################################

def main():
	cls()
	head("Plist Tool - CorpNewt")
	print(" ")
	if current_plist:
		print("Current Plist: {}".format(current_plist))
		print(" ")
	print("1. Clean plist of comments")
	print("2. Patch Menu")
	#print("3. Update/Install kexts")
	print(" ")
	print("P. Select Plist")
	print("Q. Quit")
	print(" ")
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
	print(" ")
	file_input = grab("Please drag and drop the plist on the terminal:  ")
	print(" ")
	file_input = check_path(file_input)
	if not file_input:
		# No dice
		print("That plist doesn't exist!")
		time.sleep(5)
		return None
	global current_plist 
	current_plist = file_input
	return current_plist

def clean_plist():
	cls()
	head("Clean Plist")
	print(" ")
	# Let's load it as a plist
	plist = None
	plist = plistlib.readPlist(current_plist)
	# Check if we got anything
	if plist == None:
		print("That plist either failed to load - or was empty!")
		exit(1)
	# Iterate and strip comments
	new_dict = check_keys(plist)
	# Write the new file
	plistlib.writePlist(new_dict, current_plist)
	print("Done!\n")
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
	print(" ")
	file_input = grab("Please drag and drop the plist on the terminal:  ")
	print(" ")
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
	print(" ")
	if current_plist:
		print("Current Plist: {}".format(current_plist))
		print(" ")
	print("1. Add Patches")
	print("2. [someday] Gen SMBIOS")
	print(" ")
	print("M. Main Menu")
	print(" ")
	menu = grab("Please select an option:  ")
	if menu.lower()[:1] == "m":
		return
	elif menu[:1] == "1":
		add_patches()
		return
	patch_menu()
	return

def gen_smbios():
	print("No dice, grandma.  This feature isn't added yet.")
	time.sleep(5)

def add_patches():
	cls()
	head("Plist Patches")
	print(" ")
	if current_plist:
		print("Current Plist: {}".format(current_plist))
		print(" ")
	# List the types of patches we have
	dir_list = []
	for d in os.listdir(script_path+"/Resources"):
		if os.path.isdir(script_path+"/Resources/"+d):
			dir_list.append(d)
	if not len(dir_list):
		print("No patches available!")
		time.sleep(5)
		return
	
	count = 0
	m = ""
	for d in dir_list:
		count += 1
		m += str(count) + ". " + d + "\n"
	
	m += "\nP. Patch Menu\n"
	m += "M. Main Menu\n"


	print(m)
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
	print(" ")
	if current_plist:
		print("Current Plist: {}".format(current_plist))
		print(" ")
	# List the types of patches we have
	plist_list = []
	for d in os.listdir(script_path+"/Resources/"+name):
		if d.lower().endswith(".plist"):
			plist_list.append(d)
	if not len(plist_list):
		print("No patches available!")
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

	print(m)
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
		if plist_list[menu-1].lower().startswith("remove"):
			# We are removing things
			remove_patch(plist_list[menu-1], os.path.abspath(script_path+"/Resources/"+name+"/"+plist_list[menu-1]))
		else:
			merge_patch(plist_list[menu-1], os.path.abspath(script_path+"/Resources/"+name+"/"+plist_list[menu-1]))
	list_patches(name)
	return

def remove_patch(patch, p):
	cls()
	head("Patching {}".format(patch[:-len(".plist")]))
	print(" ")
	plist = None
	plist = plistlib.readPlist(current_plist)
	# Check if we got anything
	if plist == None:
		print("That plist either failed to load - or was empty!")
		exit(1)
	patch_plist = None
	patch_plist = plistlib.readPlist(p)
	if p == None:
		print("That plist either failed to load - or was empty!")
		exit(1)
	final = remerge(patch_plist, plist)
	plistlib.writePlist(final, current_plist)
	print("Done!\n")
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
		elif type(w[key]) is list:
			if not len(w[key]):
				del temp[key]
			temp[key] = remerge_list(w[key], f[key])
		else:
			# Not a list or dict - remove it
			del temp[key]
	return temp

def remerge_list(w, f):
	# Remove patches with from
	temp = copy.deepcopy(f)
	for item in w:
		if type(item) is plistlib._InternalDict:
			if "Find" in item and "Replace" in item:
				find = item["Find"]
				replace = item["Replace"]
				for test in f:
					try:
						f_check = test["Find"]
						r_check = test["Replace"]
						if f_check == find and r_check == replace:
							temp.remove(item)
							break
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
							temp.remove(item)
							break
					except Exception:
						continue
			elif item in f:
				temp.remove(item)
		else:
			if item in f:
				temp.remove(item)
	return temp


def merge_patch(patch, p):
	cls()
	head("Patching {}".format(patch[:-len(".plist")]))
	print(" ")
	# Let's load it as a plist
	plist = None
	plist = plistlib.readPlist(current_plist)
	# Check if we got anything
	if plist == None:
		print("That plist either failed to load - or was empty!")
		exit(1)
	patch_plist = None
	patch_plist = plistlib.readPlist(p)
	if p == None:
		print("That plist either failed to load - or was empty!")
		exit(1)
	# Both plists have loaded
	final = merge_dicts(patch_plist, plist)
	# Write the new file
	plistlib.writePlist(final, current_plist)
	print("Done!\n")
	time.sleep(5)

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
							try:
								# Clone disable flag if exists
								index = temp.index(test)
								temp[index]["Disabled"] = item["Disabled"]
							except Exception:
								pass
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
							try:
								# Clone disable flag if exists
								index = temp.index(test)
								temp[index]["Disabled"] = item["Disabled"]
							except Exception:
								pass
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
