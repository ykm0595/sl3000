include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

# ===== 保留官方的公共宏和构建逻辑（如需整盘镜像可扩展使用） =====

# 不要重定义全局 DTS_DIR
# DTS_DIR := $(DTS_DIR)/mediatek   # <-- 删除这行

define Image/Prepare
	rm -f $(KDIR)/ubi_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/ubi_mark
endef

define Build/mt7981-bl2
	cat $(STAGING_DIR_IMAGE)/mt7981-$1-bl2.img >> $@
endef

define Build/mt7981-bl31-uboot
	cat $(STAGING_DIR_IMAGE)/mt7981_$1-u-boot.fip >> $@
endef

define Build/mt7986-bl2
	cat $(STAGING_DIR_IMAGE)/mt7986-$1-bl2.img >> $@
endef

define Build/mt7986-bl31-uboot
	cat $(STAGING_DIR_IMAGE)/mt7986_$1-u-boot.fip >> $@
endef

define Build/mt7988-bl2
	cat $(STAGING_DIR_IMAGE)/mt7988-$1-bl2.img >> $@
endef

define Build/mt7988-bl31-uboot
	cat $(STAGING_DIR_IMAGE)/mt7988_$1-u-boot.fip >> $@
endef

define Build/mt798x-gpt
	cp $@ $@.tmp 2>/dev/null || true
	ptgen -g -o $@.tmp -a 1 -l 1024 \
		$(if $(findstring sdmmc,$1), \
			-H \
			-t 0x83	-N bl2		-r	-p 4079k@17k \
		) \
			-t 0x83	-N ubootenv	-r	-p 512k@4M \
			-t 0x83	-N factory	-r	-p 2M@4608k \
			-t 0xef	-N fip		-r	-p 4M@6656k \
				-N recovery	-r	-p 32M@12M \
		$(if $(findstring sdmmc,$1), \
				-N install	-r	-p 20M@44M \
			-t 0x2e -N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M \
		) \
		$(if $(findstring emmc,$1), \
			-t 0x2e -N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M \
		)
	cat $@.tmp >> $@
	rm $@.tmp
endef

# 标准 FitImage，使用 DEVICE_DTS 和 DEVICE_DTS_DIR
define Device/FitImage
  KERNEL := kernel-bin | lzma | fit lzma $$(DEVICE_DTS_DIR)/$$(DEVICE_DTS).dts
  KERNEL_INITRAMFS := kernel-bin | lzma | fit lzma $$(DEVICE_DTS_DIR)/$$(DEVICE_DTS).dts
endef

# ===== SL3000-EMMC 设备定义 =====

define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := EMMC

  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  DEVICE_PACKAGES := \
        kmod-usb3 kmod-usb2 kmod-usb-ohci kmod-usb-uhci \
        kmod-mt7981-firmware kmod-mt76 kmod-mt76-core kmod-mt76-connac \
        kmod-mediatek_eth kmod-mediatek_hnat kmod-mt7531 \
        kmod-mmc kmod-mmc-mtk \
        block-mount e2fsprogs mkf2fs f2fsck \
        wireless-regdb wpad-basic-mbedtls

  SUPPORTED_DEVICES := sl3000-emmc
  BLOCKSIZE := 128k
  PAGESIZE := 2k
  IMAGE_SIZE := 256m

  IMAGES += sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata | check-size

  $(call Device/FitImage)
endef
TARGET_DEVICES += sl3000-emmc
