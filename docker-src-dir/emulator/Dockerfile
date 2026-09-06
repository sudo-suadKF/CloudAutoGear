# Copyright 2019 - The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
FROM sys-33-automotive-x64:latest AS emulator

RUN echo "deb http://mirrors.kernel.org/ubuntu/ focal main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://mirrors.kernel.org/ubuntu/ focal-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.kernel.org/ubuntu/ focal-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.kernel.org/ubuntu/ focal-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::http::Timeout "120";' >> /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::https::Timeout "120";' >> /etc/apt/apt.conf.d/80-retries && \
    apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
# Emulator & video bridge dependencies
    libc6=2.31-0ubuntu9.18 libdbus-1-3=1.12.16-2ubuntu2.3 libfontconfig1=2.13.1-2ubuntu3 libgcc1=1:10.5.0-1ubuntu1~20.04 \
    libpulse0=1:13.99.1-1ubuntu3.13 libtinfo5=6.2-0ubuntu2.1 libx11-6=2:1.6.9-2ubuntu1.6 libxcb1=1.14-2 libxdamage1=1:1.1.5-2 \
    libnss3=2:3.98-0ubuntu0.20.04.2 libxcomposite1=1:0.4.5-1 libxcursor1=1:1.2.0-2 libxi6=2:1.7.10-0ubuntu1 \
    libxext6=2:1.3.4-0ubuntu1 libxfixes3=1:5.0.3-2 zlib1g=1:1.2.11.dfsg-2ubuntu1.5 libgl1=1.3.2-1~ubuntu0.20.04.2 pulseaudio=1:13.99.1-1ubuntu3.13 \
    socat=1.7.3.3-2 iputils-ping=3:20190709-3ubuntu1 \
# Enable turncfg through usage of curl
    curl=7.68.0-1ubuntu2.25 ca-certificates=20240203~20.04.1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Now we configure the user account under which we will be running the emulator
RUN  mkdir -p /android-home

# Make sure to place files that do not change often in the higher layers
# as this will improve caching.
COPY launch-emulator.sh /android/sdk/
COPY default.pa /etc/pulse/default.pa

RUN gpasswd -a root audio && \
    chmod +x /android/sdk/launch-emulator.sh

COPY emu/ /android/sdk/
COPY avd/ /android-home
# Create an initial snapshot so we will boot fast next time around,
# This is currently an experimental feature, and is not easily configurable//
# RUN --security=insecure cd /android/sdk && ./launch-emulator.sh -quit-after-boot 120

# This is the console port, you usually want to keep this closed.
EXPOSE 5554

# This is the ADB port, useful.
EXPOSE 5555

# This is the gRPC port, also useful, we don't want ADB to incorrectly identify this.
EXPOSE 8554

WORKDIR /android/sdk

# You will need to make use of the grpc snapshot/webrtc functionality to actually interact with
# the emulator.
CMD ["/android/sdk/launch-emulator.sh"]

# Note we should use gRPC status endpoint to check for health once the canary release is out.
HEALTHCHECK --interval=30s \
            --timeout=30s \
            --start-period=30s \
            --retries=3 \
            CMD /android/sdk/platform-tools/adb shell getprop dev.bootcomplete | grep "1"

LABEL maintainer="" \
      com.google.android.emulator.version="15917651"