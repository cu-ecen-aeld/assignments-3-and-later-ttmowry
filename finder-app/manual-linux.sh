#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

sudo mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # Apply patch to the kernel build regarding multiple definitiuon of yylloc
    git apply ${FINDER_APP_DIR}/e33a814e772cdc36436c8c188d8c42d019fda639.patch

    # TODO: Add your kernel build steps here
    echo "Building kernel"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
sudo cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
echo "Creating base directories"
sudo mkdir -p ${OUTDIR}/rootfs/bin
sudo mkdir -p ${OUTDIR}/rootfs/dev
sudo mkdir -p ${OUTDIR}/rootfs/etc
sudo mkdir -p ${OUTDIR}/rootfs/home
sudo mkdir -p ${OUTDIR}/rootfs/lib
sudo mkdir -p ${OUTDIR}/rootfs/lib64
sudo mkdir -p ${OUTDIR}/rootfs/proc
sudo mkdir -p ${OUTDIR}/rootfs/sbin
sudo mkdir -p ${OUTDIR}/rootfs/sys
sudo mkdir -p ${OUTDIR}/rootfs/tmp
sudo mkdir -p ${OUTDIR}/rootfs/usr
sudo mkdir -p ${OUTDIR}/rootfs/var
sudo mkdir -p ${OUTDIR}/rootfs/usr/bin 
sudo mkdir -p ${OUTDIR}/rootfs/usr/sbin
sudo mkdir -p ${OUTDIR}/rootfs/var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    echo "Configuring busybox"
    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
echo "Building busybox"
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs

echo "adding library dependencies to rootfs"
SYSINT=$(${CROSS_COMPILE}readelf -a ${OUTDIR}/bin/busybox | grep "program interpreter" | awk -F ': ' '{print $2}' | tr -d '[]')
sudo cp -L $SYSINT ${OUTDIR}/rootfs/lib64

# Extract shared libraries required by busybox
SYSLIBS=$(${CROSS_COMPILE}readelf -a ${OUTDIR}/bin/busybox | grep "Shared library" | awk -F '\\[|\\]' '{print $2}')

for i in $SYSLIBS
do
    sudo cp -L /lib64/$i ${OUTDIR}/rootfs/lib64
done

# TODO: Make device nodes
echo "Making device nodes"
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/tty c 5 1

# TODO: Clean and build the writer utility
echo "Building writer utility"
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
sudo cp writer ${OUTDIR}/rootfs/home

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "Copying finder related scripts and executables to the /home directory"
sudo cp ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home
sudo cp ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home
sudo cp -r ${FINDER_APP_DIR}/conf/ ${OUTDIR}/rootfs/home
sudo cp ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home

# TODO: Chown the root directory
echo "Changing ownership of root directory"
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
echo "Creating initramfs.cpio.gz"
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root | gzip > ../initramfs.cpio.gz