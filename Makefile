# Makefile to start Titanium Mobile project from the command line.

PROJECT_ROOT=$(shell pwd)

run-iphone:
	@DEVICE_TYPE=iphone make run

run-ipad:
	@DEVICE_TYPE=ipad make run

run-android:
	@DEVICE_TYPE=android make run

run:
	@if [ "${DEVICE_TYPE}" == "" ]; then\
		echo "Please run \"make run-[iphone|ipad]\" instead.";\
		exit 1;\
	fi
	@mkdir -p ${PROJECT_ROOT}/${PROJECT_NAME}/Resources/test/
	@echo "" > ${PROJECT_ROOT}/${PROJECT_NAME}/Resources/test/enabled.js
	@make launch-titanium

clean:
	@rm -rf ${PROJECT_ROOT}/${PROJECT_NAME}/build/iphone/*
	@mkdir -p ${PROJECT_ROOT}/${PROJECT_NAME}/build/iphone/
	@echo "Deleted: ${PROJECT_ROOT}/${PROJECT_NAME}/build/iphone/*"

launch-titanium:
	@echo "Building with Titanium... (DEVICE_TYPE:${DEVICE_TYPE})"
	@mkdir -p ${PROJECT_ROOT}/${PROJECT_NAME}/build/iphone/
	@PROJECT_NAME=${PROJECT_NAME} PROJECT_ROOT=${PROJECT_ROOT} DEVICE_TYPE=${DEVICE_TYPE} bash ${PROJECT_ROOT}/bin/titanium.sh