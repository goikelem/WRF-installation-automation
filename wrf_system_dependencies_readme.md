<div align="center">

# 🌍 WRF / WPS System Dependencies Installer

> **Automated dependency installation scripts for Weather Research and Forecasting (WRF) and WPS modeling systems.**

[![Platform](https://img.shields.io/badge/Platform-Linux-blue?style=flat-square&logo=linux)](https://www.linux.org/)
[![Distributions](https://img.shields.io/badge/Distributions-Ubuntu%20%7C%20Debian%20%7C%20RHEL%20%7C%20CentOS-orange?style=flat-square)](https://www.linux.org/distros/)
[![Status](https://img.shields.io/badge/Status-Active%20Ready-success?style=flat-square)]()

</div>

---

## 📋 Overview

If the required system dependencies are not yet installed on your machine and you have **root privileges**, you can quickly set up your environment using the provided Bash scripts tailored for your Linux distribution.

Once the dependencies are successfully installed, you can seamlessly proceed with your **WRF / WPS installation**.

---

## 🐧 Installation Instructions

Choose the appropriate script corresponding to your operating system family below.

### 1. Debian & Ubuntu Systems

If you are running a Debian-based or Ubuntu-based distribution, use the dedicated Debian/Ubuntu package script:

```bash
# 1. Grant execution permissions to the script

git clone https://github.com/goikelem/WRF-installation-automation.git

cd WRF-installation-automation

chmod +x install_wrf_system_dependencies_debian_ubuntu_packages.sh

# 2. Run the script with sudo privileges
sudo ./install_wrf_system_dependencies_debian_ubuntu_packages.sh
```

---

### 2. Red Hat Family (RHEL, CentOS, Rocky Linux, AlmaLinux)

If you are running a Red Hat-based distribution, use the Red Hat family package script:

```bash
# 1. Grant execution permissions to the script

git clone https://github.com/goikelem/WRF-installation-automation.git

cd WRF-installation-automation
chmod +x install_wrf_system_dependencies_redhatfamily_packages.sh

# 2. Log in as the root user or switch to root
su -
# (or use sudo depending on your system configuration)

# 3. Execute the script directly as root
./install_wrf_system_dependencies_redhatfamily_packages.sh
```

> **Note:** Ensure that you have an active internet connection during execution so that all necessary compiler packages, libraries (such as NetCDF, MPICH/OpenMPI), and development tools can be fetched and configured correctly.

---

## 🚀 Next Steps

After successfully running the dependency installation script for your respective platform, you are ready to proceed with downloading and compiling:
1. **WRF (Weather Research and Forecasting Model)**
2. **WPS (WRF Preprocessing System)**

---

<div align="center">
  <sub>Maintained for atmospheric research and meteorological modeling environments.</sub>
</div>
