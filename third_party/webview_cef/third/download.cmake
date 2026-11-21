# Alexandria fork of webview_cef 0.6.2: patched file (see FORK.md).
#
# Official CEF "Standard Distribution" from the Spotify automated builds CDN
# (https://cef-builds.spotifycdn.com). All platforms are kept on the same
# CEF/Chromium version. To bump CEF, change CEF_VERSION below, and each
# archive's SHA-1 with it: the CDN publishes them in its index.json and beside
# each archive as <archive>.sha1.
set(CEF_CDN "https://cef-builds.spotifycdn.com")
set(CEF_VERSION "149.0.4+g2f1bfd8+chromium-149.0.7827.156")

# A download is checked against these before it is unpacked. A connection
# dropped part-way leaves a file that is only part of the archive, and nothing
# else says so: unpacking it fails, and the build then reports that CEF cannot
# be found.
set(cef_sha1_linux64 "85b9988783117089ae70b15241371155f4471723")
set(cef_sha1_linuxarm64 "fbf55f854fd821e2ec0ab14f53c6c423af5d4b7c")
set(cef_sha1_windows64 "90bbfdd4d6da76c6a96865e3d4f1b88e5302a1dc")
set(cef_sha1_macosarm64 "c1d95dcea7b3ee57ed1c3157b40078c0c8ee0045")
set(cef_sha1_macosx64 "ad755b892b5862932b67d5e6a76b1c63c6d9697e")

# Named in errors: the functions below run in the caller's list file.
set(cef_download_cmake "${CMAKE_CURRENT_LIST_FILE}")

# How many times a download is tried, and how long to wait between tries.
set(cef_download_attempts 3)
set(cef_download_retry_seconds 10)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(WARNING "current system is Linux")
        if(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64" OR
           CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64" OR
           CMAKE_CXX_COMPILER_TARGET MATCHES "aarch64" OR
           CMAKE_CXX_COMPILER_TARGET MATCHES "arm64")
        set(cef_prebuilt_version "cef_binary_${CEF_VERSION}_linuxarm64.tar.bz2")
        set(cef_prebuilt_sha1 "${cef_sha1_linuxarm64}")
    else()
        set(cef_prebuilt_version "cef_binary_${CEF_VERSION}_linux64.tar.bz2")
        set(cef_prebuilt_sha1 "${cef_sha1_linux64}")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(WARNING "current system is Windows")
    # Use the official CEF standard distribution and build libcef_dll_wrapper
    # from source (see windows/CMakeLists.txt), the same way Linux does.
    set(cef_prebuilt_version "cef_binary_${CEF_VERSION}_windows64.tar.bz2")
    set(cef_prebuilt_sha1 "${cef_sha1_windows64}")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    message(WARNING "current system is macOS")
    if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "arm64")
        set(cef_prebuilt_version "cef_binary_${CEF_VERSION}_macosarm64.tar.bz2")
        set(cef_prebuilt_sha1 "${cef_sha1_macosarm64}")
    else()
        set(cef_prebuilt_version "cef_binary_${CEF_VERSION}_macosx64.tar.bz2")
        set(cef_prebuilt_sha1 "${cef_sha1_macosx64}")
    endif()
endif()

# The CDN path requires '+' to be percent-encoded as %2B.
string(REPLACE "+" "%2B" cef_prebuilt_url_name "${cef_prebuilt_version}")
set(cef_prebuilt_path "${CEF_CDN}/${cef_prebuilt_url_name}")


function(extract_file filename extract_dir)
    message(WARNING "${filename} will extract to ${extract_dir} ...")

    set(temp_dir ${CMAKE_BINARY_DIR}/tmp_for_extract.dir)
    if(EXISTS ${temp_dir})
        file(REMOVE_RECURSE ${temp_dir})
    endif()
    file(MAKE_DIRECTORY ${temp_dir})
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar -xf ${filename}
            WORKING_DIRECTORY ${temp_dir}
            RESULT_VARIABLE unpacked)
    if(NOT unpacked EQUAL 0)
        file(REMOVE_RECURSE ${temp_dir})
        message(FATAL_ERROR "Could not unpack ${filename}")
    endif()

    file(GLOB contents "${temp_dir}/*")
    list(LENGTH contents n)
    if(NOT n EQUAL 1 OR NOT IS_DIRECTORY "${contents}")
        set(contents "${temp_dir}")
    endif()

    get_filename_component(contents ${contents} ABSOLUTE)

    file(INSTALL "${contents}/" DESTINATION ${extract_dir})

    file(REMOVE_RECURSE ${temp_dir})
endfunction()

# Downloads url to filename, and keeps it only if its SHA-1 is expected_sha1,
# trying again on a failed or incomplete download; stops the build when no
# attempt succeeds.
function(download_file url filename expected_sha1)
    foreach(attempt RANGE 1 ${cef_download_attempts})
        if(attempt GREATER 1)
            execute_process(COMMAND ${CMAKE_COMMAND} -E sleep ${cef_download_retry_seconds})
        endif()
        message(WARNING "Downloading ${filename} from ${url} (attempt ${attempt} of ${cef_download_attempts})")
        file(DOWNLOAD ${url} ${filename} STATUS status INACTIVITY_TIMEOUT 120 SHOW_PROGRESS)
        list(GET status 0 code)
        if(code EQUAL 0)
            file(SHA1 ${filename} actual_sha1)
            if(actual_sha1 STREQUAL expected_sha1)
                return()
            endif()
            message(WARNING "${url} arrived with SHA-1 ${actual_sha1}, not ${expected_sha1}: it is incomplete or not the archive expected")
        else()
            list(GET status 1 reason)
            message(WARNING "Downloading ${url} failed: ${reason}")
        endif()
        file(REMOVE ${filename})
    endforeach()
    message(FATAL_ERROR "Could not download ${url} with SHA-1 ${expected_sha1} in ${cef_download_attempts} attempts")
endfunction(download_file)

function(prepare_prebuilt_files filepath)
    set(need_download FALSE)

    if(NOT EXISTS ${filepath})
        message(WARNING "No ${filepath} found")
        set(need_download TRUE)
    else()
        if(NOT EXISTS ${filepath}/version.txt)
            message(WARNING "No ${filepath}/version.txt found")
            set(need_download TRUE)
        else()
            file(READ ${filepath}/version.txt local_version)
            if(local_version STREQUAL cef_prebuilt_version)
                message(WARNING "No need to update ${filepath}")
            else()
                set(need_download TRUE)
            endif()
            file(REMOVE_RECURSE ${filepath}/new_version.txt)
        endif()
    endif()

    if(need_download)
        message(WARNING "Need to update ${filepath}")
        file(REMOVE_RECURSE ${filepath}/cmake ${filepath}/Debug ${filepath}/Release ${filepath}/Resources ${filepath}/libcef_dll ${filepath}/libcef_dll_wrapper ${filepath}/include)
        # Also remove the legacy lower-case layout from the old custom Windows package.
        file(REMOVE_RECURSE ${filepath}/debug ${filepath}/release ${filepath}/resources)
        if(NOT cef_prebuilt_sha1)
            message(FATAL_ERROR "No SHA-1 is recorded for ${cef_prebuilt_version} in ${cef_download_cmake}")
        endif()
        download_file(${cef_prebuilt_path} ${CMAKE_CURRENT_SOURCE_DIR}/prebuilt.zip ${cef_prebuilt_sha1})
        file(MAKE_DIRECTORY ${filepath})
        extract_file(${CMAKE_CURRENT_SOURCE_DIR}/prebuilt.zip ${filepath})

        ## Needed for making it run on arm64 Linux (makes it check for arm64 or aarch64 instead of just arm64)
        if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
            execute_process(
                COMMAND sed -i "s/\"\\\${CMAKE_HOST_SYSTEM_PROCESSOR}\" STREQUAL \"arm64\"/(\"\\\${CMAKE_HOST_SYSTEM_PROCESSOR}\" STREQUAL \"arm64\" OR \"\\\${CMAKE_HOST_SYSTEM_PROCESSOR}\" STREQUAL \"aarch64\")/" ${filepath}/cmake/cef_variables.cmake
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            )
        endif()

        file(WRITE "${filepath}/version.txt" "${cef_prebuilt_version}")
        file(REMOVE_RECURSE ${CMAKE_CURRENT_SOURCE_DIR}/prebuilt.zip)
    endif()
endfunction(prepare_prebuilt_files)
