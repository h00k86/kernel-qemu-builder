

function download_kernel(){
  git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
}


function initialize(){
  mkdir -p initramfs/{bin,proc,sys,dev}
  cp /usr/bin/busybox initramfs/bin/
  cd initramfs
  cat > init <<'EOF'
#!/bin/busybox sh
/bin/busybox mount -t proc none /proc
/bin/busybox mount -t sysfs none /sys
/bin/busybox mount -t devtmpfs none /dev
exec /bin/busybox sh
EOF

  chmod +x init
  find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz        
  cd ..
}


function start_kernel_script(){

  qemu-system-x86_64 -kernel linux/arch/x86/boot/bzImage -initrd initramfs.cpio.gz -append "console=ttyS0 earlyprintk=serial nokaslr panic=-1" -nographic -no-reboot
}

function clear_kernel_script(){
  rm -r initramfs
  rm initramfs.cpio.gz
}

