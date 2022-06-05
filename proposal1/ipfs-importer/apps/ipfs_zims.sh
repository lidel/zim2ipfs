#!/bin/sh
#
# Checks if all ZIM files have CID and runs IPFS import for new ones.
# Each newly imported ZIM's CID is appended to ipfs-cids.txt


find "$ZIM_DIR" -iname '*.zim'

## TODO: check if each filename is present in ipfs-cids.txt, and run IPFS import if not
