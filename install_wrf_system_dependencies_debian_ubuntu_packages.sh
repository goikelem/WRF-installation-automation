#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Checking System Prerequisites ==="

# 1. Check for root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script with sudo or as root." >&2
    exit 1
fi

# 2. Check for sufficient disk space (minimum ~5GB recommended for heavy builds)
REQUIRED_SPACE_MB=5120 # 5 GB
AVAILABLE_SPACE_MB=$(df -m / | awk 'NR==2 {print $4}')

echo "Available disk space on /: ${AVAILABLE_SPACE_MB} MB"
if [ "$AVAILABLE_SPACE_MB" -lt "$REQUIRED_SPACE_MB" ]; then
    echo "Warning: Available disk space is less than 5 GB. Large builds might fail."
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "Disk space check passed."
fi

echo "=== Updating Package Lists ==="
apt-get update -y

echo "=== Installing Required Packages ==="
# build-essential includes GCC, G++, and GNU Make.
# We explicitly list all requested packages to ensure complete coverage.
apt-get install -y \
    build-essential \
    gfortran \
    make \
    m4 \
    csh \
    tcsh \
    perl \
    patch \
    wget \
    curl \
    tar \
    gzip \
    bzip2

echo "=== Installation Complete Successfully! ==="
echo "All requested packages have been installed."
