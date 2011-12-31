#!/bin/bash

# Utility script to start Titanium Mobile project from the command line.

PROJECT_ROOT=${PROJECT_ROOT:-../}
APP_DEVICE=${DEVICE_TYPE}
TI_SDK_VERSION=`cat tiapp.xml | grep "<sdk-version>" | sed -e "s/<\/*sdk-version>//g"`
TI_DIR="Library/Application Support/Titanium"

for d in /Users/*
do
    if [ -d "$d/${TI_DIR}" ]
    then
        TI_DIR="$d/${TI_DIR}"
        echo "[DEBUG] Titanium exists..."

        break
    else
        echo "[DEBUG] Titanium not found... Testing another directory"

		if [ -d "$TI_DIR" ]; then
			echo "[DEBUG] Titanium found..."
		else
			echo "[ERROR] Titanium not found... Please make sure it is installed correctly..."
			exit 1
		fi
    fi
done

if [ "${TI_SDK_VERSION}" == "" ]; then
	echo "[ERROR] sdk-version is not defined in tiapp.xml"
	exit 1
fi

if [ "${APP_DEVICE}" == "" ]; then
	APP_DEVICE="iphone"
fi

# Both iOS and Android SDKs are linked in this directory
TI_ASSETS_DIR="${TI_DIR}/mobilesdk/osx/${TI_SDK_VERSION}"

if [ -d "${TI_DIR}" ]; then
	echo "[DEBUG] Titanium SDK ${TI_SDK_VERSION} found..."
else
	echo "[ERROR] Titanium SDK ${TI_SDK_VERSION} not found... "
	exit 1
fi

# iPhone settings
if [ "${iphone}" == "" ]; then
	iphone="5.0"
fi
TI_IPHONE_DIR="${TI_ASSETS_DIR}/iphone"
TI_IPHONE_BUILD="${TI_IPHONE_DIR}/builder.py"

# Android settings
if [ "${android}" == "" ]; then
	android="10"
fi
TI_ANDROID_DIR="${TI_ASSETS_DIR}/android"
TI_ANDROID_BUILD="${TI_ANDROID_DIR}/builder.py"
ANDROID_SDK_PATH='~/Android'

if [ "DEVICE_TYPE" == "" ]; then
	echo "[ERROR] Please inform DEVICE_TYPE ('ipad' or 'iphone' or 'android')."
	exit 1
fi

# Get APP parameters from current tiapp.xml
APP_ID=`cat tiapp.xml | grep "<id>" | sed -e "s/<\/*id>//g"`
APP_NAME=`cat tiapp.xml | grep "<name>" | sed -e "s/<\/*name>//g"`

if [ "APP_ID" == "" ] || [ "APP_NAME" == "" ]; then
	echo "[ERROR] Could not obtain APP parameters from tiapp.xml file (does the file exist?)."
	exit 1
fi

if [ ${APP_DEVICE} == "iphone" ]; then
	echo "${TI_IPHONE_BUILD}"
	killall "iPhone Simulator"
	bash -c "'${TI_IPHONE_BUILD}' run ${PROJECT_ROOT}/ ${iphone} ${APP_ID} ${APP_NAME} ${APP_DEVICE}" \
	| perl -pe 's/^\[DEBUG\].*$/\e[35m$&\e[0m/g;s/^\[INFO\].*$/\e[36m$&\e[0m/g;s/^\[WARN\].*$/\e[33m$&\e[0m/g;s/^\[ERROR\].*$/\e[31m$&\e[0m/g;'
elif [ ${APP_DEVICE} == "android" ]; then
	# Check for Android Virtual Device (AVD)
	if [ "$(pidof emulator-arm)" ]
	  then
	  	echo "[INFO] Emulator already running, going to launch with that."
	  else
	  	echo "[ERROR] Could not find a running emulator."
	  	echo "[ERROR] Run this command in a separate terminal session: ${ANDROID_SDK_PATH}/tools/emulator-arm -avd ${android}"
	  	exit 1
	fi
	ARGS="${APP_NAME}  ${ANDROID_SDK_PATH} ${PROJECT_ROOT}/ ${APP_ID} ${android}"
	bash -c "${TI_ANDROID_BUILD} simulator ${ARGS}" \
	| perl -pe 's/^\[DEBUG\].*$/\e[35m$&\e[0m/g;s/^\[INFO\].*$/\e[36m$&\e[0m/g;s/^\[WARN\].*$/\e[33m$&\e[0m/g;s/^\[ERROR\].*$/\e[31m$&\e[0m/g;'
else
	echo "[ERROR] not supported!"
	echo ${APP_DEVICE}
fi

killall "iPhone Simulator"