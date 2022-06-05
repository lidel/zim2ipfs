# ipfs-importer

Zimfarm stage for chunking and importing ZIM to IPFS and pinning it to remote services

# Usage

```bash
$ docker build -t ipfs-importer .
$ docker run
    -v /data/zim:/mnt/zim:rw \
    ipfs-importer
```

