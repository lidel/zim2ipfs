#!/bin/sh

# initialize ipfs repo and adjust config
# (when pinning to remote services this can be ephemeral, no need to persis this)
if [ ! -d ~/.ipfs ]; then
    ## init repo
    ipfs init -e -p server

    ## Manually enable the hole punching feature https://blog.ipfs.io/2022-01-20-libp2p-hole-punching/
    ## (may improve connectivity without having to mess with infra used for running the container)
    ipfs config --json Swarm.EnableHolePunching true
    ipfs config --json Swarm.RelayClient.Enabled true

    ## Enable Filestore (ipfs add --nocopy <file>)
    ## https://github.com/ipfs/go-ipfs/blob/master/docs/experimental-features.md#ipfs-filestore
    ipfs config --json Experimental.FilestoreEnabled true

    ## Enable URLstore (ipfs urlstore add <url>)
    ## https://github.com/ipfs/go-ipfs/blob/master/docs/experimental-features.md#ipfs-urlstore
    ipfs config --json Experimental.UrlstoreEnabled true

    ## TODO: add pinning services
    ## TODO: set up peering with pinning services  where possible
fi

# Create cron entry for ZIM publisher check
echo "* *  * * *  root  /usr/bin/flock -w 0 /dev/shm/cron.lock /usr/local/bin/ipfs_zims.sh $ZIM_DIR >> /dev/shm/ipfs_zims.log 2>&1" >> /etc/cron.d/ipfs_zims
chmod +x /etc/cron.d/ipfs_zims

exec "$@"
