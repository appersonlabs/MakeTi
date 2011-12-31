# Makefile to start Titanium Mobile project from the command line.

PROJECT_ROOT=$(shell pwd)

iphone=$(iphone)

android=$(android)

DEVICE_TYPE=$(platform)

help:
	@echo ""
	@echo "Welcome to MakeTi, the make system for Titanium!"
	@echo ""
	@echo "Your options are as follows:"
	@echo ""
	@echo "   $ make run - (will run as iphone for default, use the platform flag to set the platform)"
	@echo "   $ make clean - (will clean your build directory)"
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
	PROJECT_ROOT=${PROJECT_ROOT} DEVICE_TYPE=${DEVICE_TYPE} bash ${PROJECT_ROOT}/bin/titanium.sh