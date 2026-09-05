# Copyright 2021 - The Android Open Source Project
#
# Licensed under the Apache License, Version 2_0 (the "License");
# you may not use this file except in compliance with the License_
# You may obtain a copy of the License at
#
#     http://www_apache_org/licenses/LICENSE-2_0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied_
# See the License for the specific language governing permissions and
# limitations under the License_
FROM alpine:3.18 AS unzipper

RUN apk add --no-cache unzip=6.0-r14

# Barely changes
FROM unzipper AS sys_unzipper

COPY android-automotive-33.zip /tmp/

RUN unzip -u -o /tmp/android-automotive-33.zip -d /sysimg/ && \
  rm -rf /sysimg/data/media/0/test /sysimg/NOTICE.txt

FROM nvidia/opengl:1.2-glvnd-runtime-ubuntu20.04

ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES},display

# Now we configure the user account under which we will be running the emulator
RUN mkdir -p /android/sdk/platforms && \
    mkdir -p /android/sdk/platform-tools && \
    mkdir -p /android/sdk/system-images

# Make sure to place files that do not change often in the higher layers
# as this will improve caching_
COPY platform-tools/adb /android/sdk/platform-tools/adb

ENV ANDROID_SDK_ROOT /android/sdk
WORKDIR /android/sdk
COPY --from=sys_unzipper --chown=1000:1000 /sysimg/ /android/sdk/system-images/android/
RUN chmod +x /android/sdk/platform-tools/adb

LABEL maintainer="" \
    ro.system.build.fingerprint="google/sdk_gcar_x86_64/emulator_car64_x86_64:13/TEA1.250515.001/13505934:userdebug/dev-keys" \
    ro.product.cpu.abi="x86_64" \
    ro.build.version.incremental="13505934" \
    ro.build.version.sdk="33" \
    ro.build.flavor="sdk_gcar_x86_64-userdebug" \
    ro.product.cpu.abilist="" \
    ro.build.type="userdebug" \
    systemimage.tagid="android-automotive,google_apis" \
    qemu.tag="android-automotive" \
    qemu.cpu="x86_64" \
    qemu.short_tag="automotive" \
    qemu.short_abi="x64" \
    qemu.is_16k="false"

# We adopt the following naimg convention <ro.build.version.sdk>-<qem>-<ro.product.cpu.abi>
# SystemImage.TagId in 'aosp', 'google', 'playstore'ß