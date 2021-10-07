#/bin/sh
rsync --exclude=sync.sh --exclude=README.md --exclude=zpool.cache --exclude=".*" -azP --stats --rsync-path="sudo rsync" . akhil@nas:/etc/nixos/
