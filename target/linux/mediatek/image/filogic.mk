include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

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
