define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000 (eMMC)
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  DEVICE_PACKAGES := \
	kmod-usb3 \
	kmod-mt7981-firmware \
	kmod-leds-gpio \
	kmod-gpio-button-hotplug \
	kmod-sdhci-mt7981 \
	kmod-mmc \
	kmod-mt7981-eth \
	kmod-mt7981-wmac \
	kmod-mediatek_eth \
	kmod-mediatek_hnat \
	kmod-mt7531
  SUPPORTED_DEVICES := sl3000 sl3000-emmc
  IMAGES += sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata | check-size
  $(call Device/FitImage)
endef
TARGET_DEVICES += sl3000-emmc
