# Makefile to start Titanium Mobile project from the command line.

# This is the ONLY option you should / need to configure
ANDROID_SDK_PATH='~/Android'

# Please dont change settings below here
PROJECT_ROOT=$(shell pwd)

iphone=$(iphone)

android=$(android)

BUILD_TYPE=$(build_type)

DEVICE_TYPE=$(platform)

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

	@echo "Building with Titanium... as ${BUILD_TYPE}"
	@mkdir -p '${PROJECT_ROOT}/${PROJECT_NAME}/build/iphone/'
	@mkdir -p '${PROJECT_ROOT}/${PROJECT_NAME}/build/android/'
	PROJECT_ROOT='${PROJECT_ROOT}' DEVICE_TYPE=${DEVICE_TYPE} bash '${PROJECT_ROOT}/bin/titanium.sh'

deploy:
	@if [ "${DEVICE_TYPE}" == "" ]; then\
		echo "No platform selected... building for iphone.";\
	fi

	@echo "Building with Titanium... as ${BUILD_TYPE}"
	@mkdir -p '${PROJECT_ROOT}/${PROJECT_NAME}/build/iphone/'
	@mkdir -p '${PROJECT_ROOT}/${PROJECT_NAME}/build/android/'
	PROJECT_ROOT='${PROJECT_ROOT}' DEVICE_TYPE=${DEVICE_TYPE} BUILD_TYPE='device' bash '${PROJECT_ROOT}/bin/titanium.sh'

clean:
	@rm -rf '${PROJECT_ROOT}/build/iphone/'
	@mkdir -p '${PROJECT_ROOT}/build/iphone/'
	@echo "Deleted: ${PROJECT_ROOT}/build/iphone/*"
	@rm -rf '${PROJECT_ROOT}/build/android/'
	@mkdir -p '${PROJECT_ROOT}/build/android/'
	@echo "Deleted: ${PROJECT_ROOT}/build/android/*"
