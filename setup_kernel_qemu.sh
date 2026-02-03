#!/bin/bash 



# Download the source from git 
download_kernel(){
  git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
}

# Create the initramfs 
initialize(){
  mkdir -p initramfs/{bin,proc,sys,dev}
  cp /usr/bin/busybox initramfs/bin/
  cd initramfs
  cat > init <<'EOF'
#!/bin/busybox sh
echo "initramfs???"

/bin/busybox mount -t proc none /proc
/bin/busybox mount -t sysfs none /sys
/bin/busybox mount -t devtmpfs none /dev



/bin/busybox mkdir -p /newroot 

echo "Mounting ext4 rootfs..."
/bin/busybox mount -t ext4 /dev/sda /newroot || exec /bin/busybox sh
echo "Mount result: $?"


# debug prima di switch_root
echo "Debug /newroot/bin:"


# Ensure console devices exist in new root
/bin/busybox mkdir -p /newroot/dev
/bin/busybox mknod /newroot/dev/consolenita c 5 1
/bin/busybox mknod /newroot/dev/null c 1 3

echo "Switching root..."
exec /bin/busybox switch_root /newroot /init

EOF

  chmod +x init
  find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz        
  cd ..
}


config_and_build(){

    cd linux
    make defconfig
    make -j$(nproc)
    cd ..
}

initialize_fs(){

    # Crea immagine e formatta
    qemu-img create rootfs.img 10G
    mkfs.ext4 rootfs.img

    # Crea mount temporaneo
    mkdir -p rootfs
    sudo mount rootfs.img rootfs

    # Crea directory di base
    sudo mkdir -p rootfs/{bin,dev,proc,sys,tmp,var,etc}

    # Copia BusyBox statico
    sudo cp /bin/busybox rootfs/bin/
    sudo chmod +x rootfs/bin/busybox

    # Link /bin/sh dentro il rootfs
    sudo ln -sf busybox rootfs/bin/sh
    sudo chmod +x rootfs/bin/sh

    # Device nodes necessari
    sudo mknod -m 600 rootfs/dev/console c 5 1
    sudo mknod -m 666 rootfs/dev/null c 1 3
    ls -l /dev/console /dev/null
    # Assicurati che il link punti correttamente
    ls -l rootfs/bin
    file rootfs/bin/busybox
    file rootfs/bin/sh

    # Crea init del root reale
sudo bash -c 'cat > rootfs/init <<EOF
#!/bin/busybox sh
echo "Root reale init partito"

# Monta filesystem virtuali
/bin/busybox mount -t proc none /proc
/bin/busybox mount -t sysfs none /sys
/bin/busybox mount -t devtmpfs none /dev

# Crea directory tmp
/bin/busybox mkdir -p /var/tmp

# Test di persistenza

/bin/busybox sync 
# Avvia shell interattiva
exec /bin/busybox sh </dev/console >/dev/console 2>&1
EOF'


sudo chmod +x rootfs/init


    # Smonta rootfs
    sudo umount rootfs
    rmdir rootfs
}


start_kernel_script(){

  qemu-system-x86_64 \
      -kernel linux/arch/x86/boot/bzImage \
      -initrd initramfs.cpio.gz \
 -append "console=ttyS0,115200 root=/dev/sda rw earlyprintk=serial nokaslr panic=-1"  \
      -drive file=rootfs.img,format=raw,if=ide\
      -nographic -no-reboot 
}



clear_kernel_script(){
  rm -r initramfs
  rm initramfs.cpio.gz
}


case "$1" in 
    download)
        download_kernel
        ;;

    start)
        echo "start kernel"
        start_kernel_script
        ;;

    build)
        config_and_build
        ;;
    fs)
        initialize_fs
        ;;

    initram)
        initialize
        ;;

    init_and_fs)
            initialize
            initialize_fs
        ;;
    all)
        download_kernel
        config_and_build
        initialize
        initialize_fs
        start_kernel_script
        ;;
    
    clean)
        clear_kernel_script
        ;;    
    *)
        echo "usage: $0 {download | start | fs | initram | init_and_fs | all | clean } "
        ;;
esac
        



