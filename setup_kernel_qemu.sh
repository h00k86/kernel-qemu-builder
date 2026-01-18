
// Download the source from git 
function download_kernel(){
  git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
}

// Create the initramfs 
function initialize(){
  mkdir -p initramfs/{bin,proc,sys,dev}
  cp /usr/bin/busybox initramfs/bin/
  cd initramfs
  cat > init <<'EOF'
#!/bin/busybox sh
/bin/busybox mount -t proc none /proc
/bin/busybox mount -t sysfs none /sys
/bin/busybox mount -t devtmpfs none /dev



bin/busybox mkdir -p /newroot

echo "Mounting ext4 rootfs..."
/bin/busybox mount -t ext4 /dev/vda /newroot || exec /bin/busybox sh

echo "Switching root..."
exec /bin/busybox switch_root /newroot /init


EOF

  chmod +x init
  find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz        
  cd ..
}


function config_and_build(){

    cd linux
    make defconfig
    make -j$(nproc)
    cd ..
}

function initialize_fs(){

    qemu-img create rootfs.img 10G
    mkfs.ext4 rootfs.img 
    mkdir rootfs
    sudo mount rootfs.img rootfs

    sudo mkdir -p rootfs/bin
    sudo cp /bin/busybox rootfs/bin/
    sudo ln -s /bin/busybox rootfs/init
    sudo mkdir -p rootfs/{dev,proc,sys,tmp,var,etc}
    sudo umount rootfs

}


function start_kernel_script(){

  qemu-system-x86_64 -kernel linux/arch/x86/boot/bzImage -initrd initramfs.cpio.gz -append "console=ttyS0 earlyprintk=serial nokaslr panic=-1"   -drive file=rootfs.img,format=raw,if=virtio  -nographic -no-reboot -S -s
}

function clear_kernel_script(){
  rm -r initramfs
  rm initramfs.cpio.gz
}


case "$1" in 
    download)
        download_kernel
        ;;

    start)
        echo "start kernel"
        ;;


    fs)
        initialize_fs
        ;;

    all)
        download_kernel
        config_and_build
        start_kernel_script
        ;;
    
    clean)
        clear_kernel_script
        ;;    
    *)
        echo "usage: $0 {download | start | fs | all | clean } "
        ;;
esac
        



