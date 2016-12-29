#!/usr/bin/env python3
from os import listdir
from os.path import isfile, join
import subprocess
import argparse

parser = argparse.ArgumentParser(description='Push .nar files to an IPFS Mirror')

parser.add_argument('--ssh', default='127.0.0.1', type=str, required=True)
parser.add_argument('--path', default='/var/www/cache/', type=str, required=True)

args = parser.parse_args()

narinfo_files = [join(args.path, f) for f in listdir(args.path)
                                    if isfile(join(args.path, f))
                                    and f.endswith("narinfo")]
ipfsHashes = []
for narinfo_file in narinfo_files:
    with open(narinfo_file, 'rb') as narinfo:
        content = narinfo.readlines()
        for line in content:
            if line.decode("utf-8").startswith("IPFSHash:"):
                print("Found IPFSHash in {}".format(narinfo_file))
                ipfsHashes.append(line.decode("utf-8").split(' ')[1])

print("Exporting Hashes to Mirror...")

for ipfsHash in ipfsHashes:
    getCommand = "ipfs --api /ip4/127.0.0.1/tcp/5001 get {}"
    conn = subprocess.Popen(["ssh", "%s" % args.ssh, getCommand.format(ipfsHash)],
                            shell=False,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    res = conn.stdout.readlines()
    if res == []:
        print("SSH Command failed with {}".format(conn.stderr.readlines()))
        exit(1)
    else:
        print("SSH Command result {}".format(res))
