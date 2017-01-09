IPFS Nix/Hydra Config
=====================

Test Repository for IPFS in Nix together with Hydra

For how to setup the network, checkout HYDRA_README.md

If you want to use a IPFS-enabled nix, you can get it from
here:

https://github.com/mguentner/nix/tree/ipfs

Cherry-pick this commit for the `nixIPFS` attribute:

https://github.com/mguentner/nixpkgs/commit/d5ea24ebd885d693ea4fa3ad1150fc75b5303c64

If you want to deploy the network using `nixops`, you should use the same branch.

Design
======

I want to describe how I imagine the workflow to be.

Machines
--------

* a machine (A) from where `/nix/store` should be published to a binary cache
* a second machine (B) which will act as a IPFS mirror
* a third machine (C) which wants to use A/B as a binary cache

Workflow
--------

On A, which could be a Hydra, a signed binary cache is being generated:
```
nix copy --to file:///var/www/example.org/cache?secret-key=/etc/nix/hydra.example.org-1/secret\&compression=none\&publish-to-ipfs=1 -r /nix/store/wkhdf9jinag5750mqlax6z2zbwhqb76n-hello-2.10/
```

Each `.nar` is being exported to a IPFS repository running on A. The `compression` is set to `none` to make
deduplication in IPFS possible.
Code: https://github.com/mguentner/nix/blob/ipfs/src/libstore/binary-cache-store.cc#L259
After the cache is complete a resulting `.narinfo` might look like this:

```
StorePath: /nix/store/8lbpq1vmajrbnc96xhv84r87fa4wvfds-glibc-2.24
URL: nar/0bl38619jq6p2jqk0xjz8rkgdvs0ljvzc71jmha7mh5r1xix375g.nar
Compression: none
FileHash: sha256:0bl38619jq6p2jqk0xjz8rkgdvs0ljvzc71jmha7mh5r1xix375g
FileSize: 20742128
NarHash: sha256:0bl38619jq6p2jqk0xjz8rkgdvs0ljvzc71jmha7mh5r1xix375g
NarSize: 20742128
References: 8lbpq1vmajrbnc96xhv84r87fa4wvfds-glibc-2.24
Deriver: n9j6dbab59jcm9wic0g44xw8gcm32vxb-glibc-2.24.drv
Sig: hydra.example.org-1:eVg2Xe22OpwnAB6Baw022lWvTSbB7cAWDBcLn9bTpSOJmozzk3FS0SVLdeEkoVZn55xZ78Y07XUL5RMEcXniCA==
IPFSHash: QmNu8CKWDm5nKfmLjQQNRdaKgYxfLG5fCYU2gyrgNhDEbU
```

The IPFSHash is not signed through the signed fingerprint (`Sig:`), however once
the file behind `IPFSHash` has been fetched completely it will be validated
against `NarHash` which is part of the fingerprint.
Relevant Code: https://github.com/NixOS/nix/blob/215b70f51e5abd350c9b7db656aedac9d96d0046/src/libstore/store-api.cc#L523

The IPFS repository on A should be periodically cleaned in order to free space. This, 
however would make the hash inaccessible. That's why everything is mirrored on B using
`ipfs-mirror-push.py`

Now on A, this can be executed

```
python3 ipfs-mirror-push.py --ssh admin@B --path /var/www/example.org/cache
```

The script will collect all IPFS hashes from the `.narinfo` files in
`/var/www/example.org/cache` and download them on B, thus making them
available.

If C now uses A as binary cache, it will first download the `.narinfo` using HTTP
and find a `IPFSHash` inside it.
Instead of downloading this file using HTTP, it will be downloaded using IPFS.
If no local IPFS daemon should be used, a IPFS Gateway can be used on C.
Code: https://github.com/mguentner/nix/blob/ipfs/src/libstore/binary-cache-store.cc#L316
