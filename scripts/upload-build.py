#!/usr/bin/env python3

import sys
import os
import paramiko

def sftp_ensure_path(sftp, path):
    path_parts = path.split('/')
    check_parts = path_parts[:]

    # Walk up parents until we find a directory that exists.
    while len(check_parts) > 0:
        try:
            sftp.stat('/'.join(check_parts))
        except FileNotFoundError:
            check_parts.pop()
            continue
        break

    # Walk back down creating directories as we go.
    remaining_parts = path_parts[len(check_parts):]
    for part in remaining_parts:
        check_parts.append(part)
        sftp.mkdir('/'.join(check_parts))

    # One last check to make sure the final path exists.
    sftp.stat(path)

def sftp_upload_dir(sftp, src_dir, dst_dir):
    for (dirpath, dirnames, filenames) in os.walk(src_dir):
        reldirpath = dirpath[len(src_dir):]
        for dirname in dirnames:
            full_dirname = dst_dir + '/' + ((reldirpath + '/') if reldirpath else '') + dirname
            try:
                sftp.stat(full_dirname)
            except FileNotFoundError:
                sftp.mkdir(full_dirname)

        for filename in filenames:
            full_filename = ((reldirpath + '/') if reldirpath else '') + filename
            print (F"Uploading {full_filename}...")
            sftp.put(os.path.join(dirpath, filename), dst_dir + '/' + full_filename)

def main():
    try:
        (src_dir, username, host, dst_dir) = sys.argv[1:]
    except ValueError:
        print ("Needs exactly 4 arguments: src_dir, username, host, dst_dir")
        sys.exit(1)

    if not os.path.isdir(src_dir):
        print (F"Source dir doesn't exist: {src_dir}")
        sys.exit(1)

    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.connect(host, username=username, compress=True)

    try:
        sftp = client.open_sftp()
        sftp_ensure_path(sftp, dst_dir)
        sftp_upload_dir(sftp, src_dir, dst_dir)
    finally:
        client.close()

if __name__ == '__main__': main()

