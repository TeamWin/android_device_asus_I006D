#
# Copyright 2017 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This contains the module build definitions for the hardware-specific
# components for this device.
#
# As much as possible, those components should be built unconditionally,
# with device-specific names to avoid collisions, to avoid device-specific
# bitrot and build breakages. Building a component unconditionally does
# *not* include it on all devices, so it is safe even with hardware-specific
# components.

# Inherit from asus sm8250-common
-include $(COMMON_PATH)/BoardConfigCommon.mk

# Kernel prebuilts
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/$(BOARD_KERNEL_IMAGE_NAME)

# TWRP specific build flags
TW_FRAMERATE := 120
TW_LOAD_VENDOR_MODULES := "adsp_loader_dlkm.ko aw8697.ko focaltech_fts_zf.ko msm_drm.ko q6_dlkm.ko swr_dlkm.ko swr_haptics_dlkm.ko texfat.ko tntfs.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_Y_OFFSET := 25
TW_H_OFFSET := -25
TW_CUSTOM_CPU_POS := 180
TW_CUSTOM_BATTERY_POS := 720
TW_STATUS_ICONS_ALIGN := center

#
# For local builds only
#
# Custom TWRP Versioning
ifneq ($(wildcard device/common/version-info/.),)
    # device version is optional - the default value is "0" if nothing is set in device tree
    CUSTOM_TWRP_DEVICE_VERSION := 0
endif
#
# end local build flags
#
