# Daniel Bypass - Termux AI & Coding Setup

Welcome to the official **Daniel Bypass** repository! This ecosystem provides automated Termux scripts, OpenCode environment, and local workspace tools to build custom AI assistants and Android apps directly from your phone.

## 🚀 Quick Installation (Step 1)

Open your Termux and run the following single-line command to execute the setup:
Daniel Bypass - Termux AI & Coding Setup
```bash
bash <(curl -s https://raw.githubusercontent.com/dipendragupta748-lang/Daniel-Bypass/refs/heads/main/daniel.sh)
```
Project Directory में जाने के लिए:
```bash
cd ~/danielbypass
```
OpenCode AI एनवायरनमेंट लॉन्च करने के लिए:
```bash
opencode
```
ऐप का APK कंपाइल (Build) करने के लिए:
```bash
./gradlew assembleDebug
```
बने हुए APK को फोन के Download फोल्डर में भेजने के लिए:
```bash
cp app/build/outputs/apk/debug/app-debug.apk ~/storage/shared/Download/daniel-bypass.apk
```
