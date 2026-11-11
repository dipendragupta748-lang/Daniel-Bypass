#!/bin/bash

# Banner and user prompt
echo "=========================================="
echo "    DANIEL BYPASS - TERMUX SETUP SCRIPT   "
echo "=========================================="

echo "Enter your name for the terminal banner:"
read -r user_name

# 1. Update and Upgrade packages
echo "[*] Updating Termux packages..."
pkg update -y && pkg upgrade -y

# 2. Install essential dependencies
echo "[*] Installing essential tools (curl, git, nodejs, python)..."
pkg install -y curl git wget nodejs python build-essential

# 3. Setup Node.js tools & Open Code / DeepSeek environment
echo "[*] Setting up coding environment and Node.js dependencies..."
npm install -g npm@latest
npm i -g open-code

# 4. Create custom directory structure & Android SDK folders placeholder
echo "[*] Creating workspace directories..."
mkdir -p ~/danielbypass
mkdir -p ~/danielbypass/app
mkdir -p ~/AndroidSDK/build-tools
mkdir -p ~/AndroidSDK/platform-tools

# 5. Configure custom bash banner and aliases
echo "[*] Configuring aliases and terminal banner..."
echo "clear" >> ~/.bashrc
echo "echo '=================================='" >> ~/.bashrc
echo "echo '  Welcome back, $user_name!       '" >> ~/.bashrc
echo "echo '  Ecosystem: DANIEL BYPASS        '" >> ~/.bashrc
echo "echo '=================================='" >> ~/.bashrc
echo "alias c='clear'" >> ~/.bashrc

# 6. Cleanup
echo "[*] Cleaning up package cache..."
pkg clean

echo "=========================================="
echo "    DANIEL BYPASS SETUP COMPLETED!        "
echo "=========================================="
echo "Please restart your Termux session."
