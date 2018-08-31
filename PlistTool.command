#!/usr/bin/python
from Scripts import *
import os, tempfile, datetime, shutil, time, json, sys, plistlib, copy, zipfile, uuid

class PlistTool:

    def __init__(self):
        # Set our working dir to the script itself
        os.chdir(os.path.dirname(os.path.realpath(__file__)))
        # Setup some initial vars
        self.comment_prefix = "#"
        self.script_path = os.path.dirname(os.path.realpath(__file__))
        self.scripts = "Scripts"
        self.sleep_time = 3
        self.available_args = [
                "-v",
                "-x",
                "npci=0x2000",
                "npci=0x3000",
                "dart=0",
                "nv_disable=1",
                "nvda_drv=1",
                "-xcpm",
                "slide=0",
                "cpus=1",
                "-no-zp",
                "-gux_defer_usb2",
                "-gux_no_idle",
                "-gux_nosleep",
                "kext-dev-mode=1",
                "rootless=0",
                "-disablegfxfirmware",
                "debug=0x100",
                "keepsyms=1"
        ]
        self.plist_dict_checks = [
            {"match":["Find","Replace"]},
            {"match":["Key","Value"]},
            {"match":["Name"],"wildcard":True},
            {"match":["Device"],"wildcard":True}
        ]
        self.u = utils.Utils("Plist Tool")
        self.d = downloader.Downloader()
        self.r = run.Run()
        self.url = "https://github.com/acidanthera/macserial/releases/latest"
        self.plist = None
        self.plist_data = None
        if os.name == "nt":
            self.macserial = self._get_binary("macserial32.exe")
        else:
            self.macserial = self._get_binary("macserial")
        self.remote = self._get_remote_version()
        self.okay_keys = [
            "SerialNumber",
            "BoardSerialNumber",
            "SmUUID",
            "ProductName",
            "Trust",
            "Memory"
        ]

      ######################
   ### GenSMBIOS commands ###
    ######################

    def _get_macserial_url(self):
        # Get the latest version of macserial
        try:
            urlsource = self.d.get_string(self.url,False)
            versions = [[y for y in x.split('"') if ".zip" in y and "download" in y] for x in urlsource.lower().split("\n") if ("mac.zip" in x or "win32.zip" in x) and "download" in x]
            versions = [x[0] for x in versions]
            mac_version = next(("https://github.com" + x for x in versions if "mac.zip" in x),None)
            win_version = next(("https://github.com" + x for x in versions if "win32.zip" in x),None)
        except:
            # Not valid data
            return None
        return (mac_version,win_version)

    def _get_binary(self,binary_name=None):
        if not binary_name:
            return None
        # Check locally
        cwd = os.getcwd()
        os.chdir(os.path.dirname(os.path.realpath(__file__)))
        path = None
        if os.path.exists(binary_name):
            path = os.path.join(os.getcwd(), binary_name)
        elif os.path.exists(os.path.join(os.getcwd(), self.scripts, binary_name)):
            path = os.path.join(os.getcwd(),self.scripts,binary_name)
        os.chdir(cwd)
        return path

    def _get_version(self):
        # Gets the macserial version
        out, error, code = self.r.run({"args":[self.macserial]})
        if not len(out):
            return None
        for line in out.split("\n"):
            if not line.lower().startswith("version"):
                continue
            vers = next((x for x in line.lower().strip().split() if len(x) and x[0] in "0123456789"),None)
            if not vers == None and vers[-1] == ".":
                vers = vers[:-1]
            return vers
        return None

    def _download_and_extract(self, temp, url):
        ztemp = tempfile.mkdtemp(dir=temp)
        zfile = os.path.basename(url)
        print("Downloading {}...".format(os.path.basename(url)))
        self.d.stream_to_file(url, os.path.join(ztemp,zfile), False)
        print(" - Extracting...")
        btemp = tempfile.mkdtemp(dir=temp)
        os.chdir(os.path.join(temp,btemp))
        # Extract with built-in tools \o/
        # self.r.run({"args":["unzip",os.path.join(ztemp,zfile)]})
        with zipfile.ZipFile(os.path.join(ztemp,zfile)) as z:
            z.extractall(os.path.join(temp,btemp))
        script_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)),self.scripts)
        for x in os.listdir(os.path.join(temp,btemp)):
            print(x)
            if "macserial" in x.lower():
                # Found one
                print(" - Found {}".format(x))
                if os.name != "nt":
                    print("   - Chmod +x...")
                    self.r.run({"args":["chmod","+x",os.path.join(btemp,x)]})
                print("   - Copying to {} directory...".format(self.scripts))
                if not os.path.exists(script_dir):
                    os.mkdir(script_dir)
                shutil.copy(os.path.join(btemp,x), os.path.join(script_dir,x))

    def _get_macserial(self):
        # Download both the windows and mac versions of macserial and expand them to the Scripts dir
        self.u.head("Getting MacSerial")
        print("")
        print("Gathering latest macserial info...")
        urls = self._get_macserial_url()
        if not urls:
            print("Error checking for updates (network issue)\n")
            self.u.grab("Press [enter] to return...")
            return
        macurl,winurl = urls[0],urls[1]
        print(" - MacURL: {}\n - WinURL: {}\n".format(macurl,winurl))
        # Download the zips
        temp = tempfile.mkdtemp()
        cwd = os.getcwd()
        try:
            self._download_and_extract(temp,macurl)
            self._download_and_extract(temp,winurl)
        except Exception as e:
            print("We ran into some problems :(\n\n{}".format(e))
        print("Cleaning up...")
        os.chdir(cwd)
        shutil.rmtree(temp)
        self.u.grab("Done.",timeout=5)
        return

    def _get_remote_version(self):
        self.u.head("Getting MacSerial Remote Version")
        print("")
        print("Gathering latest macserial info...")
        urls = self._get_macserial_url()
        if not urls:
            print("Error checking for updates (network issue)\n")
            self.u.grab("Press [enter] to return...")
            return None
        try:
            return urls[0].split("/")[7]
        except:
            print("Error parsing update url\n")
            self.u.grab("Press [enter] to return...")
            return None

    def _get_plist(self):
        self.u.head("Select Plist")
        print("")
        print("Current Plist:  {}".format(self.plist))
        print("")
        print("C. Clear Selection")
        print("M. Return To Menu")
        print("Q. Quit")
        print("")
        p = self.u.grab("Please draga and drop the target plist:  ")
        if p.lower() == "q":
            self.u.custom_quit()
        elif p.lower() == "m":
            return
        elif p.lower() == "c":
            self.plist = None
            self.plist_data = None
            return
        
        pc = self.u.check_path(p)
        if not pc:
            self.u.head("File Missing")
            print("")
            print("Plist file not found:\n\n{}".format(p))
            print("")
            self.u.grab("Press [enter] to return...")
            self._get_plist()
        try:
            with open(pc, "rb") as f:
                self.plist_data = plist.load(f)
        except Exception as e:
            self.u.head("Plist Malformed")
            print("")
            print("Plist file malformed:\n\n{}".format(e))
            print("")
            self.u.grab("Press [enter] to return...")
            self._get_plist()
        self.plist = pc

    def _key_check(self):
        # Function to verify our SMBIOS only has needed keys
        if not self.plist and not self.plist_data:
            return False
        # Got a valid plist - let's check keys
        key_check = self.plist_data.get("SMBIOS",{})
        new_smbios = {}
        removed_keys = []
        for key in key_check:
            if key not in self.okay_keys:
                removed_keys.append(key)
            else:
                # Build our new SMBIOS
                new_smbios[key] = key_check[key]
        if len(removed_keys):
            while True:
                self.u.head("Warning")
                print("")
                print("The following SMBIOS keys will be removed:\n\n{}\n".format(", ".join(removed_keys)))
                con = self.u.grab("Continue? (y/n):  ")
                if con.lower() == "y":
                    # Flush settings
                    self.plist_data["SMBIOS"] = new_smbios
                    break
                elif con.lower() == "n":
                    return False
        return True

    def _get_smbios(self, smbios_type, times=1):
        # Returns a list of SMBIOS lines that match
        total = []
        while len(total) < times:
            total_len = len(total)
            smbios, err, code = self.r.run({"args":[self.macserial,"-a"]})
            if code != 0:
                # Issues generating
                return None
            # Got our text, let's see if the SMBIOS exists
            for line in smbios.split("\n"):
                line = line.strip()
                if line.lower().startswith(smbios_type.lower()):
                    total.append(line)
                    if len(total) >= times:
                        break
            if total_len == len(total):
                # Total didn't change - return False
                return False
        # Have a list now - let's format it
        output = []
        for sm in total:
            s_list = [x.strip() for x in sm.split("|")]
            # Add a uuid
            s_list.append(str(uuid.uuid4()).upper())
            # Format the text
            output.append(s_list)
        return output

    def _generate_smbios(self):
        if not self.macserial or not os.path.exists(self.macserial):
            self.u.head("Missing MacSerial")
            print("")
            print("MacSerial binary not found.")
            print("")
            self.u.grab("Press [enter] to return...")
            return
        self.u.head("Generate SMBIOS")
        print("")
        print("M. Main Menu")
        print("Q. Quit")
        print("")
        print("Please type the SMBIOS to gen and the number")
        menu = self.u.grab("of times to generate [max 20] (i.e. iMac18,3 5):  ")
        if menu.lower() == "q":
            self.u.custom_quit()
        elif menu.lower() == "m":
            return
        menu = menu.split(" ")
        if len(menu) == 1:
            # Default of one time
            smtype = menu[0]
            times  = 1
        else:
            smtype = menu[0]
            try:
                times  = int(menu[1])
            except:
                self.u.head("Incorrect Input")
                print("")
                print("Incorrect format - must be SMBIOS times - i.e. iMac18,3 5")
                print("")
                self.u.grab("Press [enter] to return...")
                self._generate_smbios()
                return
        # Keep it between 1 and 20
        if times < 1:
            times = 1
        if times > 20:
            times = 20
        smbios = self._get_smbios(smtype,times)
        if smbios == None:
            # Issues generating
            print("Error - macserial returned an error!")
            self.u.grab("Press [enter] to return...")
            return
        if smbios == False:
            print("\nError - {} not generated by macserial\n".format(smtype))
            self.u.grab("Press [enter] to return...")
            return
        merged = False
        if self.plist_data and self.plist and os.path.exists(self.plist):
            # Let's apply - got a valid file, and plist data
            merged = self._merge_smbios(smbios[0])
        self.u.head("{} SMBIOS Info".format(smbios[0][0]))
        print("")
        print("\n\n".join(["Type:         {}\nSerial:       {}\nBoard Serial: {}\nSmUUID:       {}".format(x[0], x[1], x[2], x[3]) for x in smbios]))
        print("")
        if merged:
            if len(smbios) > 1:
                print("Flushed first generated SMBIOS entry to {}".format(self.plist))
            else:
                print("Flushed generated SMBIOS entry to {}".format(self.plist))
            print("")
        self.u.grab("Press [enter] to return...")

    def _merge_smbios(self, smbios):
        if self._key_check():
            self.plist_data["SMBIOS"]["ProductName"] = smbios[0]
            self.plist_data["SMBIOS"]["SerialNumber"] = smbios[1]
            self.plist_data["SMBIOS"]["BoardSerialNumber"] = smbios[2]
            self.plist_data["SMBIOS"]["SmUUID"] = smbios[3]
            with open(self.plist, "wb") as f:
                plist.dump(self.plist_data, f)
            return True
        return False

    def _list_current(self):
        if not self.macserial or not os.path.exists(self.macserial):
            self.u.head("Missing MacSerial")
            print("")
            print("MacSerial binary not found.")
            print("")
            self.u.grab("Press [enter] to return...")
            return
        out, err, code = self.r.run({"args":[self.macserial]})
        out = "\n".join([x for x in out.split("\n") if not x.lower().startswith("version") and len(x)])
        self.u.head("Current SMBIOS Info")
        print("")
        print(out)
        print("")
        self.u.grab("Press [enter] to return...")

    def smbiosmain(self):
        self.u.head()
        print("")
        print("Current Plist:  {}".format(self.plist))
        if os.name == "nt":
            self.macserial = self._get_binary("macserial32.exe")
        else:
            self.macserial = self._get_binary("macserial")
        if self.macserial:
            macserial_v = self._get_version()
            print("MacSerial v{}".format(macserial_v))
        else:
            macserial_v = "0.0.0"
            print("MacSerial not found!")
        # Print remote version if possible
        if self.remote and self.u.compare_versions(macserial_v, self.remote):
            print("Remote Version v{}".format(self.remote))
        print("")
        print("1. Install/Update MacSerial")
        print("2. Generate SMBIOS")
        print("3. Generate UUID")
        print("4. List Current SMBIOS")
        print("")
        print("P. Select Plist")
        print("M. Main Menu")
        print("Q. Quit")
        print("")
        menu = self.u.grab("Please select an option:  ").lower()
        if not len(menu):
            self.smbiosmain()
        if menu == "q":
            self.u.custom_quit()
        elif menu == "m":
            return
        elif menu == "p":
            self._get_plist()
        elif menu == "1":
            self._get_macserial()
        elif menu == "2":
            self._generate_smbios()
        elif menu == "3":
            self.u.head("Generated UUID")
            print("")
            print(str(uuid.uuid4()).upper())
            print("")
            self.u.grab("Press [enter] to return...")
        elif menu == "4":
            self._list_current()
        self.smbiosmain()

      ########################
   ### Plist Tool Functions ###
    ########################

    def strip_comments(self, item, prefix = "#"):
        # Recursively check each item and remove comments
        temp_item = {} if self.is_dict(item) else []
        for entry in item:
            # Get the value itself
            entry_val = item[entry] if isinstance(item, (dict, plistlib._InternalDict)) else entry
            # Check strings first
            if isinstance(entry, plist._get_inst()) and entry.startswith(prefix):
                # Skip it
                continue
            # Check if the item itself is a collection
            if isinstance(entry_val, (list, dict, plistlib._InternalDict)):
                # It is, check it too
                ret_val = self.strip_comments(entry_val)
                if not len(ret_val):
                    continue
            else:
                # No need to change it
                ret_val = entry_val
            if self.is_dict(item):
                temp_item[entry] = ret_val
            else:
                temp_item.append(ret_val)
        return temp_item

    def dict_check(self, d1, d2):
        if not type(d1) == type(d2):
            return False
        if d1 == d2:
            return True
        for check in self.plist_dict_checks:
            if all((x in d1 and x in d2) and (self.match_value(d1[x],d2[x], check.get("wildcard",False))) for x in check["match"]):
                return True
        return False

    def match_value(self, val1, val2, wildcard=False):
        # Compares val1 to val2 - wildcards are used in val1
        if not wildcard:
            return val1 == val2
        if val1[0] == "*" and val1[-1] == "*":
            return val1[1:-1] in val2
        if val1[0] == "*":
            return val2.endswith(val1[1:])
        if val1[-1] == "*":
            return val2.startswith(val1[:-1])

    def is_dict(self, val):
        return isinstance(val, (dict, plistlib._InternalDict))
    
    def remove_entries(self, f, w, exact = False):
        # Recursively removes the entries of w from f
        if not type(f) == type(w):
            # Type mismatch - return the original
            # but only if we expect an exact match
            # otherwise return an empty dict to simulate removal
            return f if exact else {}
        # Check if all keys/values match
        if f == w:
            return {} if self.is_dict(f) else []
        # Handle dicts
        if self.is_dict(f) and self.dict_check(w, f):
            # See if we even need to progress further
            return {}
        # Make a copy of our original so we can prune items at will
        for entry in w:
            if isinstance(w, list) and entry in f:
                f.remove(entry)
                continue
            if self.is_dict(w) and entry in f and w[entry] == f[entry]:
                del f[entry]
                continue
            # Get the value of the item
            entry_val = w[entry] if self.is_dict(w) else entry
            # Check if the item itself is a collection
            if isinstance(entry_val, (list, dict, plistlib._InternalDict)):
                if self.is_dict(w):
                    # Just need to compare with keys
                    test = self.remove_entries(f[entry],w[entry])
                    del f[entry]
                    if len(test):
                        f[entry] = test
                else:
                    # Create a copy list
                    test = list(f)
                    # Iterate through the elements of the list and take note of those removed
                    for x in test:
                        check = self.remove_entries(x,entry)
                        if not len(check):
                            # Found it!
                            f.remove(x)
            elif not exact and self.is_dict(w):
                # We're not looking for an exact match - but we found a non-collection endpoint
                # delete it
                del f[entry]
        return f

    def add_entries(self, f, w):
        # Recursively adds entries of w to f
        if f == w:
            return f
        if type(f) != type(w):
            # Different types - override f with w
            return w
        # Handle dicts
        if self.is_dict(f) and self.dict_check(w,f):
            # See if we even need to progress further
            for key in w:
                # Only update keys
                f[key] = w[key]
            return f
        for entry in w:
            if not entry in f:
                # Missing entirely - add it
                if self.is_dict(w):
                    f[entry] = w[entry]
                else:
                    f.append(entry)
                continue
            entry_val = w[entry] if self.is_dict(w) else entry
            # Set our stuff to the value
            if isinstance(entry_val, (list, dict, plistlib._InternalDict)):
                if self.is_dict(w):
                    test = self.add_entries(f[entry],w[entry])
                    if len(test):
                        f[entry] = test
                else:
                    test = list(f)
                    for x in test:
                        check = self.add_entries(x, entry)
                        if check != x:
                            # Changed - let's update it
                            f.remove(x)
                            f.append(check)
            elif self.is_dict(w):
                # Dictionary - just update the value
                f[entry] = w[entry]
        return f

    def list_patch(self, patch, p):
        self.u.head("{}".format(patch[:-len(".plist")]))
        print(" ")
        try:
            with open(p,"rb") as f:
                patch_plist = plist.load(f)
        except:
            patch_plist = {}
        if not any((x in patch_plist) for x in ["Add","Remove","StripComments"]):
            print("The patch is incomplete!  Not applied!\n")
            self.u.grab("Press [enter] to return...")
            return
        # Gather our info
        p_merge = patch_plist.get("Add",{})
        p_rem   = patch_plist.get("Remove",{})
        p_desc  = patch_plist.get("Description",patch[:-len(".plist")])
        p_gen   = patch_plist.get("GenSMBIOS",None)
        p_str   = patch_plist.get("StripComments",False)
        print(p_desc)
        print(" ")
        menu = self.u.grab("Apply patch? (y/n):  ")
        if menu[:1].lower() == "y":
            self.merge_patch(p_merge, p_rem, p_desc, p_gen, p_str, patch)
        elif menu[:1].lower() == "n":
            return
        else:
            list_patch(patch, p)
            return

    def merge_patch(self, p_merge, p_rem, p_desc, p_gen, p_str, patch):
        # Both plists have loaded
        if p_str:
            # Strip comments
            self.plist_data = self.strip_comments(self.plist_data)
        # Remove first - then add
        self.plist_data = self.remove_entries(self.plist_data,p_rem)
        self.plist_data = self.add_entries(self.plist_data,p_merge)
        merged = False
        if p_gen:
            try:
                smbios = self._get_smbios(p_gen)
                merged = self._merge_smbios(smbios[0])
            except:
                pass
        self.u.head("Applying {}".format(patch[:-len(".plist")]))
        print(" ")
        print(p_desc)
        print(" ")
        if p_gen and not merged:
            print("SMBIOS NOT generated!")
        # Write the new file
        with open(self.plist, "wb") as f:
            plist.dump(self.plist_data, f)
        print("Done!\n")
        self.u.grab("Press [enter] to return...")

    def add_patches(self):
        self.u.resize(80, 24)
        self.u.head("Plist Patches")
        print(" ")
        if self.plist:
            print("Current Plist: {}".format(self.plist))
            print(" ")
        # List the types of patches we have
        dir_list = [x for x in os.listdir(os.path.join(self.script_path,"Resources")) if os.path.isdir(os.path.join(self.script_path,"Resources",x))]
        dir_list.sort()
        if not len(dir_list):
            print("No patches available!")
            print("")
            self.u.grab("Press [enter] to return...")
            return
        # List the current patch directories numbered
        patch_list = ["{}. {}".format(x+1,dir_list[x]) for x in range(len(dir_list))]
        print("\n".join(patch_list))
        print("")
        print("M. Main Menu")
        print("Q. Quit")
        height = len(patch_list)+11 if len(patch_list)+11 > 24 else 24
        self.u.resize(80, height)
        menu = self.u.grab("Please select an option:  ")
        if not len(menu):
            self.add_patches()
            return
        if menu.lower() == "m":
            return
        elif menu.lower() == "q":
            self.u.custom_quit()
        try:
            menu = int(menu)
        except Exception:
            self.add_patches()
            return
        if menu > 0 and menu <= len(dir_list):
            self.list_patches(dir_list[menu-1])
        self.add_patches()
        return

    def list_patches(self, name):
        self.u.resize(80, 24)
        self.u.head("{} Patches".format(name))
        print(" ")
        if self.plist:
            print("Current Plist: {}".format(self.plist))
            print(" ")
        # List the types of patches we have
        plist_list = [x for x in os.listdir(os.path.join(self.script_path,"Resources",name)) if x.lower().endswith(".plist")]
        plist_list.sort()
        if not len(plist_list):
            print("No patches available!")
            print("")
            self.u.grab("Press [enter] to return...")
            return
        patch_list = ["{}. {}".format(x+1,plist_list[x][:-len(".plist")]) for x in range(len(plist_list))]
        print("\n".join(patch_list))
        print("")
        print("P. Plist Patches")
        print("M. Return To Menu")
        print("Q. Quit")
        height = len(patch_list)+12 if len(patch_list)+12 > 24 else 24
        self.u.resize(80, height)
        menu = self.u.grab("Please select an option:  ")
        if not len(menu):
            self.list_patches(name)
            return
        if menu.lower() == "m":
            self.main()
            return
        elif menu.lower() == "p":
            return
        elif menu.lower() == "q":
            self.u.custom_quit()
        try:
            menu = int(menu)
        except Exception:
            self.list_patches(name)
            return
        if menu > 0 and menu <= len(patch_list):
            # Handle all patching at once
            self.list_patch(plist_list[menu-1], os.path.abspath(os.path.join(self.script_path,"Resources",name,plist_list[menu-1])))
        self.list_patches(name)
        return

    def get_boot_args(self):
        # Sets the Boot -> Arguments path
        # Then returns a list of args
        if not "Boot" in self.plist_data:
            self.plist_data["Boot"] = {"Arguments":""}
        if not "Arguments" in self.plist_data["Boot"]:
            self.plist_data["Boot"]["Arguments"] = ""
        return self.plist_data["Boot"]["Arguments"].split(" ")

    def boot_args(self):
        self.u.resize(80, 24)
        self.u.head("Boot Args")
        print("")
        current_args = self.get_boot_args()
        if not len(current_args):
            print("No current boot args.")
        else:
            print("Boot args:  {}".format(" ".join(current_args)))
        print("")
        print("1. Add Argument")
        print("2. Remove Argument")
        print("")
        print("M. Main Menu")
        print("Q. Quit")
        print("")
        menu = self.u.grab("Please select an option:  ").lower()
        if not len(menu):
            self.boot_args()
            return
        if menu == "q":
            self.u.custom_quit()
        elif menu == "m":
            self.main()
            return
        elif menu == "1":
            self.add_args()
        elif menu == "2":
            self.rem_args()
        self.boot_args()

    def add_args(self):
        self.u.resize(80, 24)
        self.u.head("Add Boot Args")
        print("")
        current_args = self.get_boot_args()
        if not len(current_args):
            print("No current boot args.")
        else:
            print("Boot args:  {}".format(" ".join(current_args)))
        print("")
        arg_list = ["{}. {}".format(x+1, self.available_args[x]) for x in range(len(self.available_args))]
        print("\n".join(arg_list))
        print("")
        print("C. Custom Arg")
        print("B. Boot Arg Menu")
        print("M. Main Menu")
        print("Q. Quit")
        height = len(arg_list)+13 if len(arg_list)+13 > 24 else 24
        self.u.resize(80, height)
        menu = self.u.grab("Please select an option:  ").lower()
        if not len(menu):
            self.add_args()
            return
        if menu == "q":
            self.u.custom_quit()
        elif menu == "m":
            self.main()
            return
        elif menu == "b":
            self.boot_args()
            return
        elif menu == "c":
            self.custom_arg()
            return
        try:
            menu = int(menu)
        except Exception:
            self.add_args()
            return
        if menu > 0 and menu <= len(self.available_args):
            current_args.append(self.available_args[menu-1])
            self.plist_data["Boot"]["Arguments"] = " ".join(current_args)
            with open(self.plist, "wb") as f:
                plist.dump(self.plist_data, f)
        self.add_args()
        return

    def custom_arg(self):
        self.u.resize(80, 24)
        self.u.head("Add Custom Boot Arg")
        print("")
        current_args = self.get_boot_args()
        if not len(current_args):
            print("No current boot args.")
        else:
            print("Boot args:  {}".format(" ".join(current_args)))
        print("")
        print("A. Add Arg Menu")
        print("M. Main Menu")
        print("Q. Quit")
        print("")
        menu = self.u.grab("Please type the argument to add:  ")
        if not len(menu):
            self.custom_arg()
            return
        if menu.lower() == "a":
            return
        elif menu.lower() == "m":
            self.main()
            return
        elif menu.lower() == "q":
            self.u.custom_quit()
        # If we're here, we have an arg to add
        current_args.append(menu)
        # Strip any extra spaces
        current_args = " ".join(current_args)
        current_args = [x for x in current_args.split(" ") if len(x)]
        self.plist_data["Boot"]["Arguments"] = " ".join(current_args)
        with open(self.plist, "wb") as f:
            plist.dump(self.plist_data, f)

    def rem_args(self):
        self.u.head("Remove Boot Args")
        print("")
        current_args = self.get_boot_args()
        if not len(current_args):
            print("No current boot args.")
        else:
            arg_list = ["{}. {}".format(x+1, current_args[x]) for x in range(len(current_args))]
            print("\n".join(arg_list))
        print("")
        print("B. Boot Arg Menu")
        print("M. Main Menu")
        print("Q. Quit")
        print("")
        menu = self.u.grab("Please select an option:  ")
        if not len(menu):
            self.rem_args()
            return
        if menu.lower() == "b":
            return
        elif menu.lower() == "m":
            self.main()
            return
        elif menu.lower() == "q":
            self.u.custom_quit()
        try:
            menu = int(menu)
        except Exception:
            self.rem_args()
            return
        if menu > 0 and menu <= len(self.available_args):
            del current_args[menu-1]
            self.plist_data["Boot"]["Arguments"] = " ".join(current_args)
            with open(self.plist, "wb") as f:
                plist.dump(self.plist_data, f)
        self.rem_args()
        return

    def main(self):
        self.u.resize(80, 24)
        self.u.head("Plist Tool")
        print("")
        print("Current Plist:  {}".format(self.plist))
        if os.name == "nt":
            self.macserial = self._get_binary("macserial32.exe")
        else:
            self.macserial = self._get_binary("macserial")
        if self.macserial:
            macserial_v = self._get_version()
            print("MacSerial v{}".format(macserial_v))
        else:
            macserial_v = "0.0.0"
            print("MacSerial not found!")
        # Print remote version if possible
        if self.remote and self.u.compare_versions(macserial_v, self.remote):
            print("Remote Version v{}".format(self.remote))
        print("")
        print("1. Install/Update MacSerial")
        print("2. SMBIOS")
        if self.plist:
            print("3. Patch Menu")
            print("4. Boot Args")
            print("5. Clean Plist of Comments")
        print("")
        print("P. Select Plist")
        print("Q. Quit")
        print("")
        menu = self.u.grab("Please select and option:  ")
        if not len(menu):
            return
        if menu.lower() == "q":
            self.u.custom_quit()
        elif menu.lower() == "p":
            self._get_plist()
        elif menu == "1":
            self._get_macserial()
        elif menu == "2":
            self.smbiosmain()
        if self.plist:
            if menu == "3":
                self.add_patches()
            elif menu == "4":
                self.boot_args()
            elif menu == "5":
                self.u.head("Cleaning Comments")
                print("")
                out = self.strip_comments(self.plist_data)
                with open(self.plist, "wb") as f:
                    plist.dump(out, f)
                print("Done!\n")
                self.u.grab("Press [enter] to return...")
        self.main()

if __name__ == '__main__':
    p = PlistTool()
    p.main()
