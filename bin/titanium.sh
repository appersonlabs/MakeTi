#!/bin/bash

# Utility script to start Titanium Mobile project from the command line.
PROJECT_ROOT=${PROJECT_ROOT:-../}
APP_DEVICE=${DEVICE_TYPE}
TI_SDK_VERSION=`cat tiapp.xml | grep "<sdk-version>" | sed -e "s/<\/*sdk-version>//g"`
TI_SDK_HIGHEST_VERSION=`ls  ~/library/Application\ Support/titanium/mobilesdk/osx | tail -1`
IOS_SDK_VERSION=`cat tiapp.xml | grep "<ios-version>" | sed -e "s/[ \t]*<\/*ios-version>//g"`
TI_DIR="Library/Application Support/Titanium"
BUILD_TYPE=${BUILD_TYPE}
TESTFLIGHT_ENABLED=${testflight}
HOCKEY_ENABLED=${hockey}
APK_ONLY=${apkonly}
RELEASE_NOTES=${notes}
IPHONE_DEV_CERT=${cert}
PROVISIONING_PROFILE_NAME=${profile_file}
BUILD_ACTION=${action}
PROFILE_TYPE=iphone_dev_name
PACKAGE_APP=false
NO_COLOR=${no_color}

function pretty_print {
	if [ $NO_COLOR ]
	then
		exec perl -pe ''
	else
		exec perl -pe 's/^\[DEBUG\].*$/\e[35m$&\e[0m/g;s/^\[INFO\].*$/\e[36m$&\e[0m/g;s/^\[WARN\].*$/\e[33m$&\e[0m/g;s/^\[ERROR\].*$/\e[31m$&\e[0m/g;'
	fi
}

# Look all over for a titanium install
for d in /Users/*
do
    if [ -d "$d/${TI_DIR}" ]
    then
        TI_DIR="$d/${TI_DIR}"
        echo "[DEBUG] Titanium exists..."

        break
    else
        echo "[DEBUG] Titanium not found... Testing another directory"

        # not the most efficient place to have this, but it gets the job done
		if [ -d "/$TI_DIR" ]; then
            TI_DIR="/${TI_DIR}"
			echo "[DEBUG] Titanium found..."

			break
		fi
    fi
done

# if no platform is set, use iphone as a default
if [ "${APP_DEVICE}" == "" ]; then
	APP_DEVICE="iphone"
fi

# only install|adhoc are supported as install actions
if [ ! "${BUILD_ACTION}" == "install" ] && [ ! "${BUILD_ACTION}" == "adhoc" ]; then
	echo ""
	echo "[WARN] Only action=install and action=adhoc are supported. Choosing action=install."
	echo ""
	BUILD_ACTION="install"
fi

if [ "${BUILD_ACTION}" == "adhoc" ]; then
	PROFILE_TYPE=iphone_dist_name
fi

# provisioning profile name must be specified
if [ "${PROVISIONING_PROFILE_NAME}" == "" ]; then
	echo ""
	echo "[WARN] Defaulting profile_file to 'development'."
	echo ""
	PROVISIONING_PROFILE_NAME="development"
fi


# Make sure an SDK version is set
if [ "${TI_SDK_VERSION}" == "" ]; then
	if [ ! "${tisdk}" == "" ]; then
		TI_SDK_VERSION="${tisdk}"
	elif [ ! "${TI_SDK_HIGHEST_VERSION}" == "" ]; then
    TI_SDK_VERSION="${TI_SDK_HIGHEST_VERSION}"
  else
		echo ""
		echo "[ERROR] <sdk-version> is not defined in tiapp.xml, please define it, or add a tisdk argument to your command."
		echo ""
		exit 1
	fi
fi

# Both iOS and Android SDKs are linked in this directory
TI_ASSETS_DIR="$TI_DIR/mobilesdk/osx/$(echo $TI_SDK_VERSION)"

# Make sure this version exists
if [ -d "${TI_ASSETS_DIR}" ]; then
	echo "[DEBUG] Titanium SDK $(echo $TI_SDK_VERSION) found..."
else
	echo "[ERROR] Titanium SDK $(echo $TI_SDK_VERSION) not found... "
	exit 1
fi

# iPhone settings
if [ "${iphone}" == "" ]; then
  if [ "${IOS_SDK_VERSION}" == "" ]; then
	  iphone="6.0"
  else
    iphone="${IOS_SDK_VERSION}"
  fi
fi
TI_IPHONE_DIR="${TI_ASSETS_DIR}/iphone"
TI_IPHONE_BUILD="${TI_IPHONE_DIR}/builder.py"

# Android settings
if [ "${android}" == "" ]; then
	android="titanium_2_WVGA854"
fi
TI_ANDROID_DIR="${TI_ASSETS_DIR}/android"
TI_ANDROID_BUILD="${TI_ANDROID_DIR}/builder.py"
ANDROID_SDK_PATH='~/Android'

# Get APP parameters from current tiapp.xml
APP_ID=`cat tiapp.xml | grep "<id>" | sed -e "s/<\/*id>//g"`
APP_NAME=`cat tiapp.xml | grep "<name>" | sed -e "s/<\/*name>//g"`
APP_NAME=$(echo ${APP_NAME//    /})

if [ "APP_ID" == "" ] || [ "APP_NAME" == "" ]; then
	echo "[ERROR] Could not obtain APP parameters from tiapp.xml file (does the file exist?)."
	exit 1
fi

# build commands based on the platform
if [ ${APP_DEVICE} == "iphone" -o ${APP_DEVICE} == "ipad" ]; then

	# Run the app in the simulator
	if [ "${BUILD_TYPE}" == "" ]; then
		if [ "$(ps -Ac | egrep -i 'iPhone Simulator' | awk '{print $1}')" ]; then
			killall "iPhone Simulator"
		fi
		echo "'${TI_IPHONE_BUILD}' run '${PROJECT_ROOT}/' ${iphone} ${APP_ID} '${APP_NAME}' ${APP_DEVICE}"
		bash -c "'${TI_IPHONE_BUILD}' run '${PROJECT_ROOT}/' ${iphone} ${APP_ID} '${APP_NAME}' ${APP_DEVICE}" \
		| pretty_print

	# Build an IPA and load it through iTunes
	else

		bash -c "'${TI_IPHONE_DIR}/prereq.py' package" | \
		while read prov
		do
			temp_iphone_dev_names=`echo $prov | python -c 'import json,sys;obj=json.loads(sys.stdin.read());print obj["'"$PROFILE_TYPE"'"]'| sed 's/ u//g' | sed 's/\[u//g' | sed 's/\[//g'| sed 's/\]//g'| sed "s/\ '//g"| sed "s/\'//g"`
			IFS=,
			IPHONE_DEV_NAMES=(${temp_iphone_dev_names//,iphone_dev_name:/})

			if [ "${IPHONE_DEV_CERT}" == '' ] || [ $IPHONE_DEV_CERT -ge ${#IPHONE_DEV_NAMES[@]} ] ; then

				dev_name_count=0

				echo
				echo "*****************************************************************************************************************"
				echo "Please re-run the build command using a 'cert' flag, with the value set to the index of one of the certs below..."
				for dev_name in "${IPHONE_DEV_NAMES[@]}"
				do
					echo "[${dev_name_count}] ${dev_name}"
					dev_name_count=`expr $dev_name_count + 1`
				done
				echo "*****************************************************************************************************************"
				echo
				exit
			fi

			SIGNING_IDENTITY=${IPHONE_DEV_NAMES[$IPHONE_DEV_CERT]}
			PROVISIONING_PROFILE="${PROJECT_ROOT}/certs/${PROVISIONING_PROFILE_NAME}.mobileprovision"

            if [ ! -r 'certs/'$PROVISIONING_PROFILE_NAME'.mobileprovision' ];then
				echo "You must have a file called ${PROVISIONING_PROFILE_NAME} to build for device..."
				exit
            fi

			DATE=$( /bin/date +"%Y-%m-%d" )

			echo "'${TI_IPHONE_DIR}/provisioner.py' '${PROVISIONING_PROFILE}'"
			echo "Loading provisioning profile..."
			bash -c "'${TI_IPHONE_DIR}/provisioner.py' '${PROVISIONING_PROFILE}'" | \
			while read line
			do
				temp_array=(${line//{\"uuid\": \"/})

				UUID=${temp_array[0]//\"/}
                echo "'${TI_IPHONE_BUILD}' $BUILD_ACTION ${iphone} '${PROJECT_ROOT}/' $(echo $APP_ID) '$(echo $APP_NAME)' '$(echo $UUID | sed -e "s/uuid: //g")' '${SIGNING_IDENTITY}' '$(echo ${APP_DEVICE})'"
				bash -c "'${TI_IPHONE_BUILD}' $BUILD_ACTION ${iphone} '${PROJECT_ROOT}/' $(echo $APP_ID) '$(echo $APP_NAME)' '$(echo $UUID | sed -e "s/uuid: //g")' '${SIGNING_IDENTITY}' '$(echo ${APP_DEVICE})'" | \
				while read build_log
				do
					MAY_SYNC=0
					if [ $BUILD_ACTION == "install" ] && [ "${build_log}" == '[INFO] iTunes sync initiated' ]; then
						MAY_SYNC=1
						BUILD_LOCATION="Debug-iphoneos"
					elif [ $BUILD_ACTION == "adhoc" ] && [[ "${build_log}" =~ 'PackageApplication' ]]; then
						MAY_SYNC=1
						BUILD_LOCATION="Release-iphoneos"
						SIGNING_IDENTITY="iPhone Distribution: $SIGNING_IDENTITY"
						PACKAGE_APP=true
					fi

					if [ $MAY_SYNC -eq 1 ]; then
						echo "[INFO] Done building app..."\
						| pretty_print

						APP="${PROJECT_ROOT}/build/iphone/build/$BUILD_LOCATION/$(echo $APP_NAME).app"

						# Check if TestFlight or Hockey deploy was mandated
						if [ $TESTFLIGHT_ENABLED ] || [ $HOCKEY_ENABLED ]; then
							PACKAGE_APP=true
						fi

						if [ $PACKAGE_APP ]; then
							echo "[INFO] Creating .ipa from compiled app"\
							| pretty_print

							if [ -f /tmp/$(echo $APP_NAME).ipa ]; then
								/bin/rm "/tmp/$(echo $APP_NAME).ipa"
							fi
							/usr/bin/xcrun -sdk iphoneos PackageApplication -v "${APP}" -o "/tmp/$(echo $APP_NAME).ipa" --sign "${SIGNING_IDENTITY}" --embed "${PROVISIONING_PROFILE}" | \
							while read package_log
							do
								DATE=$( /bin/date +"%Y-%m-%d" )
							done
						fi

						if [ $TESTFLIGHT_ENABLED ]; then

							API_TOKEN=`cat tiapp.xml | grep "<tf_api>" | sed -e "s/<\/*tf_api>//g"`
							API_TOKEN=$(echo ${API_TOKEN//    /})
							TEAM_TOKEN=`cat tiapp.xml | grep "<tf_token>" | sed -e "s/<\/*tf_token>//g"`
							TEAM_TOKEN=$(echo ${TEAM_TOKEN//    /})

							if [ "${API_TOKEN}" == '' -o "${TEAM_TOKEN}" == '' ]; then
								echo "[ERROR] Testflight API key (tf_api) and Testflight team token (tf_token) must be defined in your tiapp.xml to upload with testflight"\
								| pretty_print

								exit 0
							fi

							echo "[INFO] Preping to upload to TestFlight..."\
							| pretty_print

							echo "[INFO] Uploading .ipa to TestFlight..." \
							| pretty_print

							if [ "${RELEASE_NOTES}" == '' ]; then
								RELEASE_NOTES='Build uploaded automatically from MakeTi.'
							fi

							/usr/bin/curl "http://testflightapp.com/api/builds.json" \
							  -F file=@"/tmp/$(echo $APP_NAME).ipa" \
							  -F api_token=${API_TOKEN} \
							  -F notify="True" \
							  -F replace="True" \
							  -F team_token=${TEAM_TOKEN} \
							  -F distribution_lists=`cat tiapp.xml | grep "<tf_dist>" | sed -e "s/<\/*tf_dist>//g"` \
							  -F notes="${RELEASE_NOTES}" | \
							while read upload_log
							do
								DATE=$( /bin/date +"%Y-%m-%d" )
							done

						fi

                        if [ $HOCKEY_ENABLED ]; then

                            API_TOKEN=`cat tiapp.xml | grep "<hockey_api>" | sed -e "s/<\/*hockey_api>//g"`
                            API_TOKEN=$(echo ${API_TOKEN//    /})
                            APP_ID=`cat tiapp.xml | grep "<hockey_id>" | sed -e "s/<\/*hockey_id>//g"`
                            APP_ID=$(echo ${APP_ID//    /})

                            if [ "${API_TOKEN}" == '' -o "${APP_ID}" == '' ]; then
                                echo "[ERROR] HockeyApp API key (hockey_api) and HockeyApp app ID (hockey_id) must be defined in your tiapp.xml to upload with HockeyApp"\
                                | pretty_print

                                exit 0
                            fi

                            echo "[INFO] Preping to upload to HockeyApp..."\
                            | pretty_print

                            echo "[INFO] Uploading .ipa to HockeyApp..." \
                            | pretty_print

                            if [ "${RELEASE_NOTES}" == '' ]; then
                                RELEASE_NOTES='Build uploaded automatically from MakeTi.'
                            fi

                            /usr/bin/curl \
                            -F "status=2" \
                            -F "notify=1" \
                            -F "notes=${RELEASE_NOTES}" \
                            -F "notes_type=0" \
                            -F "ipa=@/tmp/$(echo $APP_NAME).ipa" \
                            -H "X-HockeyAppToken: ${API_TOKEN}" \
                            https://rink.hockeyapp.net/api/2/apps/${APP_ID}/app_versions | \
                            while read upload_log
                            do
                                DATE=$( /bin/date +"%Y-%m-%d" )
                            done

                        fi

					else
						echo ${build_log}  \
						| pretty_print
					fi
				done
			done

		done


	fi

elif [ ${APP_DEVICE} == "android" ]; then
	# Run the app in the simulator
	if [ ${APK_ONLY} ]; then
    	bash -c "'${TI_ANDROID_BUILD}' build '${APP_NAME}'  '${ANDROID_SDK_PATH}' '${PROJECT_ROOT}/' ${APP_ID} ${android}" \
    		| pretty_print
	elif [ "${BUILD_TYPE}" == "" ]; then
		# Check for Android Virtual Device (AVD)
		if [ "$(ps -Ac | egrep -i 'emulator-arm' | awk '{print $1}')" ]; then
			bash -c "'${TI_ANDROID_BUILD}' simulator '${APP_NAME}'  '${ANDROID_SDK_PATH}' '${PROJECT_ROOT}/' ${APP_ID} ${android} && adb logcat | grep Ti" \
			| pretty_print
		else
			echo "[ERROR] Could not find a running emulator."
		  	echo "[ERROR] Run this command in a separate terminal session: ${ANDROID_SDK_PATH}/tools/emulator-arm -avd ${android}"
		  	exit 0
		fi
	else
		list_called="false"
		device_found="false"
		bash -c "${ANDROID_SDK_PATH}/platform-tools/adb devices" | \
		while read adb_output
		do

            if [ $HOCKEY_ENABLED ]; then
                bash -c "'${TI_ANDROID_BUILD}' build '${APP_NAME}'  '${ANDROID_SDK_PATH}' '${PROJECT_ROOT}/' ${APP_ID} ${android}" | \
                while read build_log
                do
                    echo "${build_log}" \
                    | pretty_print

                    if [[ "$build_log" == *zipalign* ]]; then
                        sleep 2

                        echo "APK is now located in: ${PROJECT_ROOT}/build/android/bin/app.apk"
                        API_TOKEN=`cat tiapp.xml | grep "<hockey_api>" | sed -e "s/<\/*hockey_api>//g"`
                        API_TOKEN=$(echo ${API_TOKEN//    /})
                        APP_ID=`cat tiapp.xml | grep "<hockey_android_id>" | sed -e "s/<\/*hockey_android_id>//g"`
                        APP_ID=$(echo ${APP_ID//    /})

                        if [ "${API_TOKEN}" == '' -o "${APP_ID}" == '' ]; then
                            echo "[ERROR] HockeyApp API key (hockey_api) and HockeyApp app ID (hockey_android_id) must be defined in your tiapp.xml to upload with HockeyApp"\
                            | pretty_print

                            exit 0
                        fi

                        echo "[INFO] Preping to upload to HockeyApp..."\
                        | pretty_print

                        APP="${PROJECT_ROOT}/build/android/bin/app.apk"

                        echo "[INFO] Uploading .ipa to HockeyApp..." \
                        | pretty_print

                        if [ "${RELEASE_NOTES}" == '' ]; then
                            RELEASE_NOTES='Build uploaded automatically from MakeTi.'
                        fi

                        echo "${APP_ID}"

                        /usr/bin/curl \
                        -F "status=2" \
                        -F "notify=1" \
                        -F "notes=${RELEASE_NOTES}" \
                        -F "notes_type=0" \
                        -F "ipa=@$(echo $APP)" \
                        -H "X-HockeyAppToken: ${API_TOKEN}" \
                        https://rink.hockeyapp.net/api/2/apps/${APP_ID}/app_versions
                    fi
                done
			elif [ "${list_called}" == "True" ]; then
                if [ "${adb_output}" == "" ]; then
                    if [ "${device_found}" == "false" ]; then
                        echo "[ERROR] Could not find an attached android device with development mode enabled."
                        exit 0
                    fi
                fi

				device_found="True"

				bash -c "'${TI_ANDROID_BUILD}' install '${APP_NAME}'  '${ANDROID_SDK_PATH}' '${PROJECT_ROOT}/' ${APP_ID} ${android}" \
				| pretty_print
				break
			fi

			if [ "${adb_output}" == "List of devices attached" ]; then
				list_called="True"
			fi
		done
	fi


elif [ ${APP_DEVICE} == "web" ]; then

	# Web settings
	TI_WEB_DIR="${TI_ASSETS_DIR}/mobileweb"

	# make sure this SDK has mobileweb
	if [ -d "${TI_WEB_DIR}" ]; then
		echo "[DEBUG] Mobileweb is installed..."
	else
		echo "[ERROR] This Ti SDK does not support mobileweb... "
		exit 1
	fi

	bash -c "'/usr/bin/python' '${TI_ASSETS_DIR}/mobileweb/builder.py' '${PROJECT_ROOT}' 'development'" \
	| pretty_print

	echo "Files are now located in '${PROJECT_ROOT}/build/mobileweb/' Copy to a webserver and launch index.html in a web browser"
	# bash -c "open '${PROJECT_ROOT}/build/mobileweb/index.html'"

else
	echo "[ERROR] platform ${APP_DEVICE} is not supported!"
	echo ${APP_DEVICE}
fi
