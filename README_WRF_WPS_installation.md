

# 🌪️ WRF 4.6.0 Unified Local Installation Script

`💻 Platform: Linux / Unix`

A robust, all-in-one automation script designed for non-root users to compile and configure **WRF 4.6.0**, **WPS 4.6.0**, and all required local libraries entirely from source inside `$HOME/Build_WRF`.

---

## 💡 Overview

This script eliminates common path conflicts, duplicate compilation steps, and silent compilation failures often encountered when mixing local dependencies with system-level paths. This method is adapted from `uems_install.pl` (special thanks to Dr. Robert Rozumalski and AI technology).

### ✨ Key Features

- **100% Localized:** Installs all external dependencies into a custom prefix directory (`$HOME/Build_WRF/local`), requiring **no root/sudo privileges**.
- **Multi-Mode Support:** Supports standard ARW, WRF-Chem (with KPP), and WRF-Hydro configurations via simple command-line flags.
- **Automated Dependency Chain:** Compiles `zlib`, `HDF5`, `NetCDF-C`, `NetCDF-Fortran`, `MPICH`, `libpng`, `JasPer`, `Flex`, and `Byacc` in the correct sequential order.
- **Smart Environment Configuration:** Automatically appends and exports necessary environment variables to your `~/.bashrc`.


```markdown 

## 📂 Directory Structure After Installation

Once the script completes successfully, your workspace will be organized as follows:

```text
$HOME/
└── Build_WRF/
    ├── LIBRARIES/             # Source code tarballs and build directories for dependencies
    ├── local/                 # Prefix folder containing compiled bins, libs, and includes
    ├── WRF-4.6.0-ARW/         # Compiled WRF source directory (or -Chem / -Hydro)
    ├── WPS-4.6.0/             # WPS source directory
    └── WPS_GEOG/              # High-resolution mandatory geography datasets (and chemistry data if enabled)

```

---

## 🛠️ Prerequisites

Ensure your system has basic build utilities and compilers available:

* GNU Compiler Collection (`gcc`, `g++`, `gfortran`)
* Build essentials (`make`, `m4`, `perl`)
* Download tools (`wget` or `curl`)
[Install WRF system dependencies](https://github.com/goikelem/WRF-installation-automation/blob/main/install_wrf_system_dependencies_debian_ubuntu_packages.sh
 "For Debian and Ubuntu distribution families")

[Install WRF system dependencies](https://github.com/goikelem/WRF-installation-automation/blob/main/install_wrf_system_dependencies_redhatfamily_packages.sh
 "For RedHat distribution families")
 
> **⚠️ Note:** A disk space of at least **25–30 GB** is recommended, as compiling WRF/WPS and downloading geography data requires substantial storage.

---

## 🚀 Usage Instructions

1. Clone the installation repository and change your working directory:
```bash
git clone [https://github.com/goikelem/WRF-installation-automation.git](https://github.com/goikelem/WRF-installation-automation.git)
cd WRF-installation-automation

```


2. Make the script executable:
```bash
chmod +x install_wrf_4.6.0.sh

```


3. Run the script choosing your desired configuration mode:
* **For Standard WRF-ARW:**
```bash
bash install_wrf_4.6.0.sh -arw

```


* **For WRF-Chem (includes KPP & chemical emissions geography):**
```bash
bash install_wrf_4.6.0.sh -chem

```


* **For WRF-Hydro:**
```bash
bash install_wrf_4.6.0.sh -hydro

```





---

## ⚙️ Post-Installation

After the script finishes execution, reload your shell profile to update your environment path variables:

```bash
source ~/.bashrc

```

### 🔍 Verifying the Installation

* **Check WRF Executables:** Navigate to your WRF main directory and look for real-time model executables (`wrf.exe`, `real.exe`):
```bash
cd ~/Build_WRF/WRF-4.6.0-ARW/main
ls -l *.exe

```


* **Check WPS Executables:** Navigate to your WPS directory and look for WPS executables (`ungrib.exe`, `metgrid.exe`, `geogrid.exe`):
```bash
cd ~/Build_WRF/WPS-4.6.0
ls -l *.exe

```



### 📋 Checking Your Instructions Guide

Review your instruction guide generated during the build process:

```bash
cat ~/WRF-DoList.txt

```

### 🎛️ Loading Environment Modules (Alternative Method)

If you prefer using Environment Modules rather than global exports, load them via:

```bash
export MODULEPATH="${MODULEPATH}:$HOME/Build_WRF/etc/modulefiles"
module load WRFARW  # (or WRFChem / WRFHydro)

```

Alternatively, source the environment file directly:

```bash
source $HOME/Build_WRF/etc/modulefiles/WRFARW.sh

```

```

```
