######################################################
# File:                  Makefile                    #
# App Name:              REALTIME_ONI                #
# Functionality:         Installation and Setup      #
# Author:                Adam Allgood                #
# Date Makefile created: 2017-11-14                  #
######################################################

ARCH_STRT := $(shell echo `date +%d%b%Y --d "120 days ago"`)

# --- Rules ---

.PHONY: permissions
.PHONY: dirs
.PHONY: copyctl
.PHONY: setupsst

# --- make install ---

install: permissions dirs makectl setupsst

# --- permissions ---

permissions:
	chmod 755 ./drivers/daily/*.csh
	chmod 755 ./scripts/*.pl
	chmod 755 ./scripts/*.csh

# --- dirs ---

dirs:
	mkdir -p ./logs
	mkdir -p ./work

# --- makectl ---

makectl:
	mkdir -p ${DATA_OUT}/observations/ocean/short_range/global/sst-avhrr/daily-data
	echo 'dset ^%y4/ncei-avhrr-only-v2-%y4%m2%d2.nc' > ${DATA_OUT}/observations/ocean/short_range/global/sst-avhrr/daily-data/ncei-avhrr-only-v2.ctl
	echo 'options template' >> ${DATA_OUT}/observations/ocean/short_range/global/sst-avhrr/daily-data/ncei-avhrr-only-v2.ctl
	echo tdef time 20000 linear $(ARCH_STRT) 1dy >> ${DATA_OUT}/observations/ocean/short_range/global/sst-avhrr/daily-data/ncei-avhrr-only-v2.ctl

# --- setupsst ---

setupsst:
	./scripts/initialize-sst-archive.csh
