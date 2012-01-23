# Makefile to start Titanium Mobile project from the command line.

# This is the ONLY option you should / need to configure
ANDROID_SDK_PATH='~/Android'

# Please dont change settings below here
PROJECT_ROOT=$(shell pwd)

iphone=$(iphone)

android=$(android)

DEVICE_TYPE=$(platform)

ANDROID_SDK_PATH = $(android_sdk_path)

help:
	@echo ""
	@echo "**************************************************************"
	@echo "* Welcome to MakeTi, the make system for Titanium!           *"
	@echo "**************************************************************"
	@echo "The commands avaliable to you are as follows:"
	@echo ""
	@echo "   $ make run - (will run as iphone for default, use the platform flag to set the platform)"
	@echo "   $ make clean - (will clean your build directory)"
	@echo ""
	@echo "The options for the build command are:"
	@echo ""
	@echo "   $ make run platform=ipad - (Other platforms are iphone, ipad, or android)"
	@echo "   $ make run iphone=4.3 - (Where 4.3 is, put whatever iOS SDK you want to use)"
	@echo "   $ make run android=10 - (Where 10 is, put the Android API level you wish to use)"
	@echo ""
	@echo "**************************************************************"
	@echo ""

run:
	@if [ "${DEVICE_TYPE}" == "" ]; then\
		echo "No platform selected... running as iphone.";\
	fi
	@make launch-titanium

clean:
	@rm -rf ${PROJECT_ROOT}/build/iphone/*
	@mkdir -p ${PROJECT_ROOT}/build/iphone/
	@echo "Deleted: ${PROJECT_ROOT}/build/iphone/*"
	@rm -rf ${PROJECT_ROOT}/build/android/*
	@mkdir -p ${PROJECT_ROOT}/build/android/
	@echo "Deleted: ${PROJECT_ROOT}/build/android/*"

launch-titanium:
	@echo "Building with Titanium..."
	@mkdir -p ${PROJECT_ROOT}/${PROJECT_NAME}/build/iphone/
	@mkdir -p ${PROJECT_ROOT}/${PROJECT_NAME}/build/android/
	PROJECT_ROOT='${PROJECT_ROOT}' DEVICE_TYPE=${DEVICE_TYPE} ANDROID_SDK_PATH=${ANDROID_SDK_PATH} bash '${PROJECT_ROOT}/bin/titanium.sh'