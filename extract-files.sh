#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=rmx3371
VENDOR=realme

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true


KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        product/etc/sysconfig/com.android.hotwordenrollment.common.util.xml)
            sed -i "s|my_product|product|" "${2}"
            ;;
        vendor/lib64/hw/camera.qcom.so)
            grep -q libcamera_metadata_shim.so "${2}" || "${PATCHELF}" --add-needed "libcamera_metadata_shim.so" "${2}"
            ;;
        vendor/lib64/vendor.qti.hardware.camera.postproc@1.0-service-impl.so)
            "${SIGSCAN}" -p "AF 0B 00 94" -P "1F 20 03 D5" -f "${2}"
            ;;
        vendor/lib/libgui1_vendor.so)
            patchelf --replace-needed "libui.so" "libui-v30.so" "${2}"
            ;;
        vendor/lib/libstagefright_soft_ac4dec.so | vendor/lib/libstagefright_soft_ddpdec.so | vendor/lib/libstagefrightdolby.so | vendor/lib64/libdlbdsservice.so | vendor/lib64/libstagefright_soft_ac4dec.so | vendor/lib64/libstagefright_soft_ddpdec.so | vendor/lib64/libstagefrightdolby.so)
            grep -q "libstagefright_foundation-v33.so" "${2}" || "${PATCHELF}" --replace-needed "libstagefright_foundation.so" "libstagefright_foundation-v33.so" "${2}"
            ;;
        vendor/lib/libstagefright_soft_ac4dec.so | vendor/lib/libstagefright_soft_ddpdec.so | vendor/lib/libstagefright_soft_qtiflacdec.so | vendor/lib/libstagefrightdolby.so | vendor/lib64/libdlbdsservice.so | vendor/lib64/libstagefright_soft_ac4dec.so | vendor/lib64/libstagefright_soft_ddpdec.so | vendor/lib64/libstagefrightdolby.so)
            "${PATCHELF}" --replace-needed "libstagefright_foundation.so" "libstagefright_foundation-v33.so" "${2}"
            ;;
        odm/lib/libdlbdsservice_v3_6.so | odm/lib/libstagefright_soft_ddpdec.so | odm/lib/libstagefrightdolby.so | odm/lib64/libdlbdsservice_v3_6.so)
            "${PATCHELF}" --replace-needed "libstagefright_foundation.so" "libstagefright_foundation-v33.so" "${2}"
            :;    
        odm/lib64/libAncSegmentSdk.so | odm/lib64/libstblur_capture_api.so | odm/lib64/libAncHumanSegFigureFusion.so | odm/lib64/libaps_frame_registration.so | odm/lib64/libAncHumanRetain.so | odm/lib64/liblvimfs_wrapper.so | odm/lib64/libYTCommon.so | odm/lib/libYTCommon.so | odm/lib64/libAncSegBaseSdk.so | odm/lib64/libCOppLceTonemapAPI.so | odm/lib64/libcvface_api.so)
            "${PATCHELF}" --replace-needed "libstdc++.so" "${2}"
            :;   
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
