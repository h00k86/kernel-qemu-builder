# kernel_utility

## TO DO
- [] add build,temp and config file to .ignore

## TEST FUNCTION

- [x] download_kernel ; 
- [x] init

## STEP BY STEP

- [ ] download the kernel
- [ ] make defconfig (per iniziare la configurazione di default va piu' che bene),in seguito make menuconfig
--[ ] in menuconfig, flag debug options
- [ ] make -j$(nproc) ( compile the kernel)
- [ ] run script for create init file, create dir {proc,bin,dev} and copy busybox



