#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# 1. Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root or using sudo."
  exit 1
fi

echo "==> Checking system resources..."

# Check available disk space on root (Requires at least 5 GB / 5242880 KB)
AVAILABLE_SPACE=$(df / --output=avail | tail -n 1)
REQUIRED_SPACE=5242880 

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
  echo "Warning: Less than 5GB of free disk space available on root partition."
  echo "Large source code compilations may run out of space."
else
  echo "-> Disk space check passed."
fi

# Check system memory (RAM)
TOTAL_MEM=$(free -m | awk '/Mem:/ {print $2}')
echo "-> Total RAM available: ${TOTAL_MEM} MB"
if [ "$TOTAL_MEM" -lt 2048 ]; then
  echo "Warning: Less than 2GB of RAM detected. Heavy compilation jobs might be slow or require swap space."
fi

echo "==> Updating package repositories..."
dnf -y update

echo "==> Installing requested build tools and utilities..."

# Install compilers, make, utility packages, and download/archive tools
dnf install -y \
    gcc \
    gcc-c++ \
    gcc-gfortran \
    make \
    tcsh \
    csh \
    m4 \
    perl \
    patch \
    wget \
    curl \
    tar \
    gzip \
    bzip2

echo "==> Verification of installed packages:"
gcc --version | head -n 1
g++ --version | head -n 1
gfortran --version | head -n 1
make --version | head -n 1

echo "==> All packages successfully installed and verified!"

