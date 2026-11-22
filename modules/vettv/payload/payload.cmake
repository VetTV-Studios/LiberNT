# SPDX-License-Identifier: GPL-2.0-or-later
#
# VetTV RetroOS on LiberNT: the %SystemDrive%\VetTV\ tree.
#
# Included from modules/CMakeLists.txt. LiberNT's boot CD is a live tree (the
# ISO root becomes the system drive and "reactos/" becomes "Windows/"), so a
# DESTINATION of VetTV/<dir> lands at C:\VetTV\<dir> on the live desktop and
# in the preinstall image. No txtsetup.sif edits and no reactos.cab
# (the ReactOS 0.4.16/0.4.17 payload.cmake needed both).
#
# profiles/ (vetvdm per-game DOSBox-X profiles, by-name/ and by-hash/<sha256>.json)
# is ours, GPL-compatible JSON next to this file, so it always ships.
#
# VETTV_PAYLOAD_DIR (empty by default): a staging folder OUTSIDE the source tree
# holding the pinned third-party programs, never committed:
#   dosbox-x/        DOSBox-X (GPL-2.0-or-later), dosbox-x.exe pinned by sha256
#   winevdm/         WineVDM / otvdm (GPL-2.0-only), a separate program, with its LICENSE
#   winevdm-source/  (optional) the corresponding WineVDM source + VetTV patches
#   dosbox-x-source/ (optional) the corresponding DOSBox-X source
# WineVDM is GPL-2.0-only: it is never linked into LiberNT binaries; it ships as
# a separate program next to its source (aggregation).

set(VETTV_PAYLOAD_DIR "" CACHE PATH "VetTV: optional payload dir with dosbox-x/ and winevdm/ (empty = profiles only)")
set(VETTV_DOSBOXX_SHA256 "4ac5774f987c2fbde68893646877ce0cbef8a793f58a195f6fbb52d949a6cc96" CACHE STRING "VetTV: pinned dosbox-x.exe sha256")
set(VETTV_KRNL386_SHA256 "89eaf2bd8560c75ccbc8e16ef95474c60bb76151a01b24c10f85ee03fd0906fd" CACHE STRING "VetTV: pinned (patched) winevdm krnl386.exe16 sha256 (dosmem-low-guard + no-strnlen + reactos-family-subsystemtib)")

set(_vt_stage "${CMAKE_CURRENT_LIST_DIR}|profiles")

if(VETTV_PAYLOAD_DIR AND NOT WOW64_I386_RUNTIME)
    if(NOT EXISTS "${VETTV_PAYLOAD_DIR}/dosbox-x/dosbox-x.exe" OR NOT EXISTS "${VETTV_PAYLOAD_DIR}/winevdm/otvdmw.exe")
        message(FATAL_ERROR "VetTV: VETTV_PAYLOAD_DIR=${VETTV_PAYLOAD_DIR} needs dosbox-x/dosbox-x.exe and winevdm/otvdmw.exe")
    endif()
    file(SHA256 "${VETTV_PAYLOAD_DIR}/dosbox-x/dosbox-x.exe" _vt_dbx_sha)
    if(NOT _vt_dbx_sha STREQUAL VETTV_DOSBOXX_SHA256)
        message(FATAL_ERROR "VetTV: dosbox-x.exe sha256 ${_vt_dbx_sha} != pin ${VETTV_DOSBOXX_SHA256}")
    endif()
    file(SHA256 "${VETTV_PAYLOAD_DIR}/winevdm/krnl386.exe16" _vt_k386_sha)
    if(NOT _vt_k386_sha STREQUAL VETTV_KRNL386_SHA256)
        message(FATAL_ERROR "VetTV: winevdm/krnl386.exe16 sha256 ${_vt_k386_sha} != pin ${VETTV_KRNL386_SHA256} (never ship the stock a1111648...)")
    endif()
    message(STATUS "VetTV: payload from ${VETTV_PAYLOAD_DIR} (dosbox-x ${_vt_dbx_sha}, krnl386 ${_vt_k386_sha})")
    foreach(_vt_top dosbox-x winevdm winevdm-source dosbox-x-source)
        if(EXISTS "${VETTV_PAYLOAD_DIR}/${_vt_top}")
            list(APPEND _vt_stage "${VETTV_PAYLOAD_DIR}|${_vt_top}")
        endif()
    endforeach()
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
        "${VETTV_PAYLOAD_DIR}/dosbox-x/dosbox-x.exe" "${VETTV_PAYLOAD_DIR}/winevdm/krnl386.exe16")
endif()

if(NOT WOW64_I386_RUNTIME)
    foreach(_vt_entry ${_vt_stage})
        string(REPLACE "|" ";" _vt_entry "${_vt_entry}")
        list(GET _vt_entry 0 _vt_root)
        list(GET _vt_entry 1 _vt_top)
        file(GLOB_RECURSE _vt_list LIST_DIRECTORIES FALSE RELATIVE ${_vt_root} ${_vt_root}/${_vt_top}/*)
        list(SORT _vt_list)
        foreach(_p ${_vt_list})
            get_filename_component(_d ${_p} DIRECTORY)
            add_cd_file(FILE ${_vt_root}/${_p} DESTINATION VetTV/${_d} FOR all)
        endforeach()
    endforeach()
endif()
