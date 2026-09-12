#!/bin/bash

sudo apt update
sudo apt install -y python3 python3-venv python3-pip make protobuf-compiler git curl unzip openjdk-17-jdk

egrep -c '(vmx|svm)' /proc/cpuinfo
sudo apt-get install -y qemu-system-x86 libvirt-daemon-system libvirt-clients bridge-utils cpu-checker
kvm-ok

curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker

sudo apt-get install -y ca-certificates gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs

mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools
curl -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q cmdline-tools.zip
mv cmdline-tools latest
rm cmdline-tools.zip
echo 'export ANDROID_HOME=$HOME/android-sdk' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH' >> ~/.bashrc
source ~/.bashrc
yes | sdkmanager --licenses
sdkmanager --install "platform-tools"

cd ~
git clone https://github.com/sudo-suadKF/CloudAutoGear.git

gcloud auth configure-docker europe-north2-docker.pkg.dev --quiet
docker pull europe-north2-docker.pkg.dev/cloudautogear/claugr-repo/aaos-emulator:api33-build1

CONTAINER_ID=$(docker run -d --device /dev/kvm \
  --group-add $(stat -c '%g' /dev/kvm) \
  --publish 8554:8554/tcp --publish 5555:5555/tcp \
  europe-north2-docker.pkg.dev/cloudautogear/claugr-repo/aaos-emulator:api33-build1)
echo $CONTAINER_ID

TIMEOUT=300
ELAPSED=0
until [ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER_ID")" = "healthy" ]; do
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "ERROR: containern blev aldrig healthy inom ${TIMEOUT}s"
        exit 1
    fi
done

adb connect localhost:5555

mkdir -p ~/CloudAutoGear/emulator-config
docker cp "$CONTAINER_ID":/home/emulator/.android/avd/running/pid_1.ini ~/CloudAutoGear/emulator-config/pid_1.ini

echo 'export BAZEL_ROOT=$HOME/CloudAutoGear/aemu-main-next' >> ~/.bashrc
source ~/.bashrc
cd ~/CloudAutoGear/android-emulator-container-scripts/gateway
./setup_env.sh
source venv/bin/activate
nohup videobridge-gateway --port=8080 --discovery_file ~/CloudAutoGear/emulator-config/pid_1.ini > ~/gateway.log 2>&1 &
disown

cd ~/CloudAutoGear/android-emulator-container-scripts/js
npm ci
make build
cd example
npm ci

cd ~/CloudAutoGear/android-emulator-container-scripts/js/example
nohup npm run dev -- --host 0.0.0.0 > ~/frontend.log 2>&1 &
disown

cd ~/CloudAutoGear/car-samples/car-lib/CarGearViewerKotlin
./gradlew :automotive:assembleDebug

adb -s localhost:5555 install automotive/build/outputs/apk/debug/automotive-debug.apk
adb -s localhost:5555 shell am start -n com.example.cargearviewer/.MainActivity