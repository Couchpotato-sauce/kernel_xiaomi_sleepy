# auto-detect subdirs
ifeq ($(CONFIG_ARCH_MSM8953), y)
include $(srctree)/techpack/audio/config/sdm450auto.conf
export $(shell sed 's/=.*//' $(srctree)/techpack/audio/config/sdm450auto.conf)
endif
ifeq ($(CONFIG_MACH_XIAOMI_DAISY), y)
include $(srctree)/techpack/audio/config/msm8953auto-sakura.conf
export $(shell sed 's/=.*//' $(srctree)/techpack/audio/config/msm8953auto-sakura.conf)
endif

# Use USERINCLUDE when you must reference the UAPI directories only.
USERINCLUDE     += \
                -I$(srctree)/techpack/audio/include/uapi \

# Use LINUXINCLUDE when you must reference the include/ directory.
# Needed to be compatible with the O= option
LINUXINCLUDE    += \
                -I$(srctree)/techpack/audio/include/uapi \
                -I$(srctree)/techpack/audio/include

ifeq ($(CONFIG_MACH_XIAOMI_DAISY), y)
LINUXINCLUDE    += \
                -include $(srctree)/techpack/audio/config/msm8953autoconf-sakura.h
endif

obj-y += asoc/
obj-y += dsp/
obj-y += ipc/
obj-y += soc/
