#!/usr/bin/env python3

import sys
import os

def calculate_directory_hash(top_dir):
    import hashlib

    filepaths = []
    for (dirpath, dirnames, filenames) in os.walk(top_dir, False):
        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            filepaths.append(filepath.replace('\\', '/'))

    filepaths.sort()

    hashes = []
    for filepath in filepaths:
        (fileroot, fileext) = os.path.splitext(filepath)
        try:
            data = open(filepath, 'rt').read().encode('utf-8')
        except UnicodeError:
            data = open(filepath, 'rb').read()
        filehash = hashlib.md5(data).hexdigest()
        hashes.append(filehash + "  " + filepath)

    return hashlib.md5('\n'.join(hashes).encode('utf-8')).hexdigest()

if __name__ == '__main__':
    print(calculate_directory_hash(sys.argv[1]))

