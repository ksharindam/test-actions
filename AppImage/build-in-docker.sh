#! /bin/bash

set -euxo pipefail

ARCH=x86_64
platform=linux/amd64
image=ubuntu:22.04

repo_root="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")"/..)"

# run the build with the current user to
#   a) make sure root is not required for builds
#   b) allow the build scripts to "mv" the binaries into the /out directory
uid="$(id -u)"

# make sure Docker image is up to date
#docker pull "$image"

# mount workspace read-only, trying to make sure the build doesn't ever touch the source code files
# of course, this only works reliably if you don't run this script from that directory
# but it's still not the worst idea to do so
docker run \
    --platform "$platform" \
    --rm \
    -i \
    -e ARCH \
    -e GITHUB_ACTIONS \
    -e GITHUB_RUN_NUMBER \
    -e OUT_UID="$uid" \
    -v "$repo_root":/source:ro \
    -v "$PWD":/out \
    -w /out \
    "$image" \
    sh <<\EOF

set -eux

apt update
apt install -y python3-pyqt5 pyqt5-dev-tools python3 python3-pip wget git gcc

pip3 install -y pyinstaller
wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
wget -q "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"

chmod 755 *.AppImage
mv appimagetool*AppImage /usr/bin/appimagetool
mv linuxdeploy*AppImage /usr/bin/linuxdeploy



# in a Docker container, we can safely disable this check
git config --global --add safe.directory '*'

bash -eux /source/AppImage/appimage_gen.sh

chown "$OUT_UID" appimagetool*.AppImage

EOF
