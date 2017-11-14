######################################################
# File:                  Makefile                    #
# Process Name:          REALTIME_ONI                #
# Functionality:         Installation and Setup      #
# Author:                Adam Allgood                #
# Date Makefile created: 2017-11-14                  #
######################################################

# --- Rules ---

.PHONY: permissions
.PHONY: dirs
.PHONY: copyctl

# --- make install ---

install: permissions dirs copyctl

# --- permissions ---

permissions:
	chmod 755 ./drivers/daily/*.csh
	chmod 755 ./scripts/*.pl

# --- dirs ---

dirs:
	mkdir -p ./logs
	mkdir -p ./work

# --- copyctl ---

copyctl:
	mkdir -p ${DATA_OUT}/observations/ocean/short_range/global/sst-avhrr/daily-data
	cp ./ctl/*.ctl ${DATA_OUT}/observations/ocean/short_range/global/sst-avhrr/daily-data
