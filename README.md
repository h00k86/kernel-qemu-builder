# kernel_utility

## TO DO
- [] add build,temp and config file to .ignore

## TEST FUNCTION

- [OK] download_kernel ; 
- [OK] init

## STEP BY STEP

- [] download the kernel
- [] make defconfig (per iniziare la configurazione di default va piu' che bene),in seguito make menuconfig

- [] make -j$(nproc) (queto compila il kernel)
- [] run script for create init file, create dir {proc,bin,dev} and copy busybox



