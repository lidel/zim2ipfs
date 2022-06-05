# zim2ipfs: proposal 1; full control

This directory attempts to flesh out details around having full control over
the way ZIM archive is imported and published on IPFS

## Intended audience

Below is written for someone familiar with Kiwix but not familiar with IPFS.

## Key requirements

- full control over the CID that is produced by the import
  - this is important because we will start with default import parameters from
    go-ipfs, but want to have ability to switch to custom ones, or even
    replace/augument go-ipfs with custom chunker that is aware of OpenZIM
    format
- no storage duplication
  - https://farm.openzim.org/pipeline/filter-doing produces a ZIM which will
    eventually get published at https://download.kiwix.org/zim/wikipedia/.
    Kiwix is already under storage constraint and can only store two months of
    snapshots, IPFS publishing should reuse existing storage and not require
    copying data to internal datastore.
- no vendor lock-in
  - the process should not depend on any specific service
  - every third-party pinning service used should use vendor-agnostic protocols
    and APIs, so there is no hidden switching tax if they go away or we want to
    try a new one


## Building blocks

- [openzim/zimfarm](https://github.com/openzim/zimfarm)
  - a semi-decentralised software solution to build ZIM files
  - runs distinct pipeline stages in isolated  Docker containers
  - we are mostly interested in creating something similar to the
    [`receiver`](https://github.com/openzim/zimfarm/tree/master/receiver)
    component which might act as integration point for IPFS publishing
- [go-ipfs](https://github.com/ipfs/go-ipfs#readme)
  - Mature implementation of IPFS that won't go away any time soon
    - Prebuilt [Docker images](https://hub.docker.com/r/ipfs/go-ipfs/) provided,
      [easy to customize](https://github.com/ipfs/ipfs-docs/pull/1115/files)
    - Prebuilt [binaries](https://dist.ipfs.io/go-ipfs/) are available too
  - Supports `--no-copy` import to IPFS
    ([filestore](https://github.com/ipfs/go-ipfs/blob/master/docs/experimental-features.md#ipfs-filestore)
    or [urlstore](https://github.com/ipfs/go-ipfs/blob/master/docs/experimental-features.md#ipfs-urlstore))
- [pinning service api spec](https://ipfs.github.io/pinning-services-api-spec/)
  - vendor-agnostic API for asking remote services to pin specific CID and provide ("seed") it to the network
  - go-ipfs provides a compatible CLI client at `ipfs pin remote --help`
    - multiple pinning services can be added and used at the same time
    - pinning can happen in the background, and we can block
      until N out of M services confirms to have a full copy of the data
    - `ipfs pin remote add` implements best practices
      for [provider hints](https://ipfs.github.io/pinning-services-api-spec/#section/Provider-hints)
      (announcing own multiaddrs as origins and preconnecting to delegate notes from the pinning service)
- Protocol Labs sponsoring pinning to 2+ services for redundancy and robustness
    - https://web3.storage
    - https://estuary.tech
    - (we most likely can add more)

## Architecture (WIP)

Pipeline at [openzim/zimfarm](https://github.com/openzim/zimfarm) is split into distinct stages.

The [`receiver`](https://github.com/openzim/zimfarm/tree/master/receive) runs
`zimcheck` on produced ZIM and moves valid ones to `/mnt/quarantine`(?).

We want to perform IPFS import only once per ZIM, and only do it for valid ones.

Need to understand what would be the best integration point for IPFS publishing:

- (X) add it to `receiver` stage (after `zimcheck` but before upload/move)
- (Y) make it a distinct `ipfs-importer` stage which picks up where `receiver` left,
  adds .zim to IPFS, and after data is pinned  remotely, adds CID as metadata attribute via `https://api.farm.openzim.org/v1`

I am assuming (Y) is better because it keeps IPFS logic isolated, does not
impact existing infra, and maybe even allows Protocol Labs to sponsor
IPFS-related workers, removing any financial burden it could generate for Kiwix.

We don't need to run IPFS node all the time. Cron job could check for new ZIMs
and perform IPFS import only when a new one is detected. Import would
start an ephemeral IPFS node with filestore enabled (or urlstore), produce CID
via `ipfs add --nocopy`, and pin it to remote services.

When we have remote copies confirmed, local IPFS node will be shut down to save
resources.

### To move forward, need answers for these questions

- should I continue with `./ipfs-importer` and create Dockerfile for running cron-based checker similar to `receiver`, or is there a better way?
- how to track which ZIMs already have a CID?
- where to store secret API keys used for remote pinning?
