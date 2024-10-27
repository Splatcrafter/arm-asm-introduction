init: init.s
	arm-none-eabi-gcc -nostdlib -static init.s -o init

initramfs: init
	echo init|cpio -o --format=newc > initramfs

initramfs.gz: initramfs
	gzip -f initramfs

initramfs.gz.uboot: initramfs.gz
	## nix shell nixpkgs#ubootTools
	mkimage -A arm -O linux -T ramdisk -C gzip -n "Build Root File System" -d initramfs.gz initramfs.gz.uboot
	## could now be used as initrd for linux



u-boot.bin:
	nix build nixpkgs#pkgsCross.aarch64-multiplatform.ubootQemuAarch64a -o u-boot.bin

linuxImage:
	nix build nixpkgs#pkgsCross.aarch64-multiplatform.linuxKernel.kernels.linux_rpi3 -o linuxImage


.DEFAULT_GOAL := run
run: u-boot.bin linuxImage initramfs.gz.uboot
	qemu-system-aarch64 -nographic -machine virt -cpu cortex-a57 -m 4G -bios u-boot.bin -kernel linuxImage -initrd initramfs.gz.uboot
