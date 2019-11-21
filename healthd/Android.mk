# Copyright 2013 The Android Open Source Project

LOCAL_PATH := $(call my-dir)

### libhealthd_draw ###
include $(CLEAR_VARS)

LOCAL_MODULE := libhealthd_draw

LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)
LOCAL_STATIC_LIBRARIES := libminui
LOCAL_SHARED_LIBRARIES := libbase
LOCAL_SRC_FILES := healthd_draw.cpp

ifneq ($(TARGET_HEALTHD_DRAW_SPLIT_SCREEN),)
LOCAL_CFLAGS += -DHEALTHD_DRAW_SPLIT_SCREEN=$(TARGET_HEALTHD_DRAW_SPLIT_SCREEN)
else
LOCAL_CFLAGS += -DHEALTHD_DRAW_SPLIT_SCREEN=0
endif

ifneq ($(TARGET_HEALTHD_DRAW_SPLIT_OFFSET),)
LOCAL_CFLAGS += -DHEALTHD_DRAW_SPLIT_OFFSET=$(TARGET_HEALTHD_DRAW_SPLIT_OFFSET)
else
LOCAL_CFLAGS += -DHEALTHD_DRAW_SPLIT_OFFSET=0
endif

LOCAL_HEADER_LIBRARIES := libbatteryservice_headers

include $(BUILD_STATIC_LIBRARY)

### libhealthd_charger ###
include $(CLEAR_VARS)

LOCAL_CFLAGS := -Werror
ifeq ($(strip $(BOARD_CHARGER_DISABLE_INIT_BLANK)),true)
LOCAL_CFLAGS += -DCHARGER_DISABLE_INIT_BLANK
endif
ifeq ($(strip $(BOARD_CHARGER_ENABLE_SUSPEND)),true)
LOCAL_CFLAGS += -DCHARGER_ENABLE_SUSPEND
endif

LOCAL_SRC_FILES := \
    healthd_mode_charger.cpp \
    AnimationParser.cpp

LOCAL_MODULE := libhealthd_charger
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include
LOCAL_EXPORT_C_INCLUDE_DIRS := \
    $(LOCAL_PATH) \
    $(LOCAL_PATH)/include

LOCAL_STATIC_LIBRARIES := \
    android.hardware.health@2.0-impl \
    android.hardware.health@1.0-convert \
    libhealthstoragedefault \
    libhealthd_draw \
    libminui \

LOCAL_SHARED_LIBRARIES := \
    android.hardware.health@2.0 \
    libbase \
    libcutils \
    liblog \
    libpng \
    libutils \

ifeq ($(strip $(BOARD_CHARGER_ENABLE_SUSPEND)),true)
LOCAL_SHARED_LIBRARIES += libsuspend
endif

include $(BUILD_STATIC_LIBRARY)

### charger ###
include $(CLEAR_VARS)
ifeq ($(strip $(BOARD_CHARGER_NO_UI)),true)
LOCAL_CHARGER_NO_UI := true
endif

LOCAL_SRC_FILES := \
    charger.cpp \

LOCAL_MODULE := charger
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include

LOCAL_CFLAGS := -Werror
ifeq ($(strip $(LOCAL_CHARGER_NO_UI)),true)
LOCAL_CFLAGS += -DCHARGER_NO_UI
endif

CHARGER_STATIC_LIBRARIES := \
    android.hardware.health@2.0-impl \
    android.hardware.health@1.0-convert \
    libbinderthreadstate \
    libhidltransport \
    libhidlbase \
    libhealthstoragedefault \
    libvndksupport \
    libhealthd_charger \
    libhealthd_charger_nops \
    libhealthd_draw \
    libbatterymonitor \

CHARGER_SHARED_LIBRARIES := \
    android.hardware.health@2.0 \
    libbase \
    libcutils \
    libjsoncpp \
    libprocessgroup \
    liblog \
    libutils \

ifneq ($(strip $(LOCAL_CHARGER_NO_UI)),true)
CHARGER_STATIC_LIBRARIES += libminui
CHARGER_SHARED_LIBRARIES += libpng
endif

ifeq ($(strip $(BOARD_CHARGER_ENABLE_SUSPEND)),true)
CHARGER_SHARED_LIBRARIES += libsuspend
endif

LOCAL_STATIC_LIBRARIES := $(CHARGER_STATIC_LIBRARIES)
LOCAL_SHARED_LIBRARIES := $(CHARGER_SHARED_LIBRARIES)

LOCAL_HAL_STATIC_LIBRARIES := libhealthd

# Symlink /charger to /system/bin/charger
LOCAL_POST_INSTALL_CMD := $(hide) mkdir -p $(TARGET_ROOT_OUT) \
    && ln -sf /system/bin/charger $(TARGET_ROOT_OUT)/charger

include $(BUILD_EXECUTABLE)

### charger.recovery ###
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    charger.cpp \

LOCAL_MODULE := charger.recovery
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)/system/bin
LOCAL_MODULE_STEM := charger

LOCAL_C_INCLUDES := $(LOCAL_PATH)/include
LOCAL_CFLAGS := -Wall -Werror
LOCAL_CFLAGS += -DCHARGER_NO_UI

# charger.recovery doesn't link against libhealthd_{charger,draw} or libminui, since it doesn't need
# any UI support.
LOCAL_STATIC_LIBRARIES := \
    android.hardware.health@2.0-impl \
    android.hardware.health@1.0-convert \
    libbinderthreadstate \
    libhidltransport \
    libhidlbase \
    libhealthstoragedefault \
    libvndksupport \
    libhealthd_charger_nops \
    libbatterymonitor \

# These shared libs will be installed to recovery image because of the dependency in `recovery`
# module.
LOCAL_SHARED_LIBRARIES := \
    android.hardware.health@2.0 \
    libbase \
    libcutils \
    liblog \
    libutils \

# The use of LOCAL_HAL_STATIC_LIBRARIES prevents from building this module with Android.bp.
LOCAL_HAL_STATIC_LIBRARIES := libhealthd

include $(BUILD_EXECUTABLE)

### charger_test ###
include $(CLEAR_VARS)
LOCAL_MODULE := charger_test
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include
LOCAL_CFLAGS := -Wall -Werror -DCHARGER_NO_UI
LOCAL_STATIC_LIBRARIES := $(CHARGER_STATIC_LIBRARIES)
LOCAL_SHARED_LIBRARIES := $(CHARGER_SHARED_LIBRARIES)
LOCAL_SRC_FILES := \
    charger_test.cpp \

include $(BUILD_EXECUTABLE)

CHARGER_STATIC_LIBRARIES :=
CHARGER_SHARED_LIBRARIES :=

### charger_res_images ###
ifneq ($(strip $(LOCAL_CHARGER_NO_UI)),true)
define _add-charger-image
include $$(CLEAR_VARS)
LOCAL_MODULE := system_core_charger_res_images_$(notdir $(1))
LOCAL_MODULE_STEM := $(notdir $(1))
_img_modules += $$(LOCAL_MODULE)
LOCAL_SRC_FILES := $1
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $$(TARGET_OUT_PRODUCT)/etc/res/images/charger
include $$(BUILD_PREBUILT)
endef

_img_modules :=
ifeq ($(strip $(BOARD_HEALTHD_CUSTOM_CHARGER_RES)),)
IMAGES_DIR := images
else
IMAGES_DIR := ../../../$(BOARD_HEALTHD_CUSTOM_CHARGER_RES)
endif
_images :=
$(foreach _img, $(call find-subdir-subdir-files, "$(IMAGES_DIR)", "*.png"), \
  $(eval $(call _add-charger-image,$(_img))))

include $(CLEAR_VARS)
LOCAL_MODULE := charger_res_images
LOCAL_MODULE_TAGS := optional
LOCAL_REQUIRED_MODULES := $(_img_modules)
include $(BUILD_PHONY_PACKAGE)

_add-charger-image :=
_img_modules :=
endif # LOCAL_CHARGER_NO_UI
