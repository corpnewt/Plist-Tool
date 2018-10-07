import sys, os, time
# Python-aware urllib stuff
if sys.version_info >= (3, 0):
    from urllib.request import urlopen
else:
    from urllib2 import urlopen

class Downloader:

    def __init__(self):
        return

    def get_size(self, size, suff=None):
        if size == -1:
            return "Unknown"
        ext = ["B","KB","MB","GB","PB"]
        s = float(size)
        s_dict = {}
        # Iterate the ext list, and divide by 1000 each time
        for e in ext:
            s_dict[e] = s
            s /= 1000
        if suff and suff.upper() in s_dict:
            # We supplied the suffix - use it \o/
            bval = round(s_dict[suff.upper()], 2)
            biggest = suff.upper()
        else:
            # Get the maximum >= 1 type
            biggest = next((x for x in ext[::-1] if s_dict[x] >= 1), "B")
            # Round to 2 decimal places
            bval = round(s_dict[biggest], 2)
        return "{:,.2f} {}".format(bval, biggest)

    def _progress_hook(self, response, bytes_so_far, total_size):
        if total_size > 0:
            percent = float(bytes_so_far) / total_size
            percent = round(percent*100, 2)
            t_s = self.get_size(total_size)
            try:
                b_s = self.get_size(bytes_so_far, t_s.split(" ")[1])
            except:
                b_s = self.get_size(bytes_so_far)
            sys.stdout.write("Downloaded {} of {} ({:.2f}%)\r".format(b_s, t_s, percent))
        else:
            sys.stdout.write("Downloaded {}\r".format(b_s))

    def get_string(self, url, progress = True):
        try:
            response = urlopen(url)
            CHUNK = 16 * 1024
            bytes_so_far = 0
            try:
                total_size = int(response.headers['Content-Length'])
            except:
                total_size = -1
            chunk_so_far = "".encode("utf-8")
            while True:
                chunk = response.read(CHUNK)
                bytes_so_far += len(chunk)
                if progress:
                    self._progress_hook(response, bytes_so_far, total_size)
                if not chunk:
                    break
                chunk_so_far += chunk
            return chunk_so_far.decode("utf-8")
        except:
            return None

    def get_bytes(self, url, progress = True):
        try:
            response = urlopen(url)
            CHUNK = 16 * 1024
            bytes_so_far = 0
            try:
                total_size = int(response.headers['Content-Length'])
            except:
                total_size = -1
            chunk_so_far = "".encode("utf-8")
            while True:
                chunk = response.read(CHUNK)
                bytes_so_far += len(chunk)
                if progress:
                    self._progress_hook(response, bytes_so_far, total_size)
                if not chunk:
                    break
                chunk_so_far += chunk
            return chunk_so_far
        except:
            return None

    def stream_to_file(self, url, file, progress = True):
        try:
            response = urlopen(url)
            CHUNK = 16 * 1024
            bytes_so_far = 0
            try:
                total_size = int(response.headers['Content-Length'])
            except:
                total_size = -1
            with open(file, 'wb') as f:
                while True:
                    chunk = response.read(CHUNK)
                    bytes_so_far += len(chunk)
                    if progress:
                        self._progress_hook(response, bytes_so_far, total_size)
                    if not chunk:
                        break
                    f.write(chunk)
            if os.path.exists(file):
                return file
            else:
                return None
        except:
            return None
