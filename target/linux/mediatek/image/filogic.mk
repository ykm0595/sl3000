# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

# ===== 平台公共逻辑（保留但不破坏标准变量） =====

# 不重定义全局 DTS_DIR；设备内使用 DEVICE_DTS_DIR
# DTSDIR := $(DTSDIR)  # <-- 删除或注释

define Image/Prepare
	rm -f $(KDIR)/ubi_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/ubi_mark
endef

# 统一使用标准变量名：STAGING_DIR_IMAGE
define Build/mt7981-bl2
	cat $(STAGING_DIR_IMAGE)/mt7981-$1-bl2.img >> $@
endef

define Build/mt7981-bl31-uboot
	cat $(STAGING_DIR_IMAGE)/mt7981_$1-u-boot.fip >> $@
endef

# GPT 仅在需要整盘镜像时使用；保留宏但不影响 sysupgrade
define Build/mt798x-gpt
	cp $@ $@.tmp 2>/dev/null || true
	ptgen -g -o $@.tmp -a 1 -l 1024 \
		-t 0x2e -N production -p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M
	cat $@.tmp >> $@
	rm $@.tmp
endef

# ===== GL 风格 metadata（修正变量名与 json_quote/quote 一致性） =====

metadatagljson = \
	'{ \
		"metadata_version": "1.1", \
		"version": { \
			"release": "$(call json_quote,$(VERSION_NUMBER))", \
			"dist": "$(call json_quote,$(VERSION_DIST))", \
			"revision": "$(call json_quote,$(REVISION))", \
			"target": "$(call json_quote,$(TARGETID))", \
			"board": "$(call json_quote,$(if $(BOARDNAME),$(BOARDNAME),$(DEVICENAME)))" \
		} \
	}'

define Build/append-gl-metadata
	$(if $(SUPPORTED_DEVICES),echo $(call metadatagljson,$(SUPPORTED_DEVICES)) | fwtool -I - $@)
	sha256sum "$@" | cut -d" " -f1 > "$@.sha256sum"
endef

# ===== 标准 FitImage 定义（依赖 DEVICE_DTS/DEVICE_DTS_DIR） =====

define Device/FitImage
  KERNEL := kernel-bin | lzma | fit lzma $$(DEVICE_DTS_DIR)/$$(DEVICE_DTS).dts
  KERNEL_INITRAMFS := kernel-bin | lzma | fit lzma $$(DEVICE_DTS_DIR)/$$(DEVICE_DTS).dts
endef

# ===== 设备定义：SL3000-EMMC =====

define Device/sl3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := EMMC

  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek

  SUPPORTED_DEVICES := sl3000-emmc

  # 仅保留必要包，避免无关驱动与复杂依赖阻塞镜像阶段
  DEVICE_PACKAGES := \
    kmod-usb3 \
    kmod-mt76 \
    kmod-mt7981-firmware \
    kmod-mediatek_eth kmod-mediatek_hnat \
    kmod-mt7531 \
    kmod-mmc kmod-mmc-mtk \
    block-mount e2fsprogs mkf2fs f2fsck \
    wireless-regdb wpad-basic-mbedtls

  # 如需 UI/容器等，可在 feeds 层或自定义 profile 追加，避免影响镜像生成
  # luci luci-theme-argon docker dockerd docker-compose containerd runc lxc lxc-templates cgroupfs-mount

  BLOCKSIZE := 128k
  PAGESIZE := 2k
  IMAGE_SIZE := 256m

  # 产出两类镜像：标准 sysupgrade 与 initramfs（用于恢复/临时启动）
  IMAGES += sysupgrade.bin
  IMAGES += initramfs-recovery.bin

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata | append-gl-metadata | check-size
  IMAGE/initramfs-recovery.bin := append-gl-metadata

  $(call Device/FitImage)
endef
TARGET_DEVICES += sl3000-emmc
