#!/bin/bash
#########################################################
#   WRF 4.6.0 Unified Local Installation Script         #
#   For Non-Root Users in $HOME/Build_WRF               #
#########################################################

# Exit immediately if any command fails
set -e

WRFversion="4.6.0"
WPSversion="4.6.0"
type="ARW"

if [ -n "$1" ]; then
    if [ "$1" = "-chem" ]; then
        type="Chem"
    elif [ "$1" = "-arw" ]; then
        type="ARW"
    elif [ "$1" = "-hydro" ]; then
        type="Hydro"
    else
        echo "Unrecognized option, please run as:"
        echo "For WRF-ARW   : bash install_wrf.sh -arw"
        echo "For WRF-Chem  : bash install_wrf.sh -chem"
        echo "For WRF-Hydro : bash install_wrf.sh -hydro"
        exit 1
    fi
fi

WRF_HOME="$HOME/Build_WRF"
LIB_DIR="$WRF_HOME/LIBRARIES"
PREFIX="$WRF_HOME/local"

echo "=== Starting Local Installation of WRF ${WRFversion} (${type}) Dependencies ==="
echo "Target prefix directory: $PREFIX"

# Create necessary directories
mkdir -p "$LIB_DIR"
mkdir -p "$PREFIX/include"
mkdir -p "$PREFIX/lib"
mkdir -p "$PREFIX/bin"

# Set basic compiler flags
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran
export CFLAGS="-O3 -fPIC"
export FCFLAGS="-O3 -fPIC"
export FFLAGS="-O3 -fPIC"

export PATH="$PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export LDFLAGS="-L$PREFIX/lib"
export CPPFLAGS="-I$PREFIX/include"

cd "$LIB_DIR"

#########################################################
# 1. Zlib Installation
#########################################################
echo "--- [1/9] Installing zlib ---"
if [ ! -d "zlib-1.2.13" ]; then
    wget https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.gz -O zlib-1.2.13.tar.gz || curl -L https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.gz -o zlib-1.2.13.tar.gz
    tar -zxvf zlib-1.2.13.tar.gz
fi
cd zlib-1.2.13
./configure --prefix="$PREFIX"
make -j4
make install
cd "$LIB_DIR"

#########################################################
# 2. HDF5 Installation
#########################################################
echo "--- [2/9] Installing HDF5 ---"
if [ ! -d "hdf5-1.12.2" ]; then
    wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.2/src/hdf5-1.12.2.tar.gz -O hdf5-1.12.2.tar.gz || curl -L https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.2/src/hdf5-1.12.2.tar.gz -o hdf5-1.12.2.tar.gz
    tar -zxvf hdf5-1.12.2.tar.gz
fi
cd hdf5-1.12.2
./configure --prefix="$PREFIX" --with-zlib="$PREFIX" --enable-parallel=no --enable-hl --enable-fortran
make -j4
make install
cd "$LIB_DIR"

#########################################################
# 3. NetCDF-C Installation
#########################################################
echo "--- [3/9] Installing NetCDF-C ---"
if [ ! -d "netcdf-c-4.9.2" ]; then
    wget https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.9.2.tar.gz -O netcdf-c-4.9.2.tar.gz || curl -L https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.9.2.tar.gz -o netcdf-c-4.9.2.tar.gz
    tar -zxvf netcdf-c-4.9.2.tar.gz
fi
cd netcdf-c-4.9.2
export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"
./configure --prefix="$PREFIX" --with-hdf5="$PREFIX" --disable-dap --disable-byterange
make -j4
make install
cd "$LIB_DIR"

#########################################################
# 4. NetCDF-Fortran Installation
#########################################################
echo "--- [4/9] Installing NetCDF-Fortran ---"
if [ ! -d "netcdf-fortran-4.6.1" ]; then
    wget https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.1.tar.gz -O netcdf-fortran-4.6.1.tar.gz || curl -L https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.1.tar.gz -o netcdf-fortran-4.6.1.tar.gz
    tar -zxvf netcdf-fortran-4.6.1.tar.gz
fi
cd netcdf-fortran-4.6.1
export LIBS="-lnetcdf -lhdf5_hl -lhdf5 -lz"
./configure --prefix="$PREFIX" --with-netcdf="$PREFIX"
make -j4
make install
cd "$LIB_DIR"

#########################################################
# 5. MPICH Installation
#########################################################
echo "--- [5/9] Installing MPICH ---"
if [ ! -d "mpich-4.1.2" ]; then
    wget https://www.mpich.org/static/downloads/4.1.2/mpich-4.1.2.tar.gz -O mpich-4.1.2.tar.gz || curl -L https://www.mpich.org/static/downloads/4.1.2/mpich-4.1.2.tar.gz -o mpich-4.1.2.tar.gz
    tar -zxvf mpich-4.1.2.tar.gz
fi
cd mpich-4.1.2
./configure --prefix="$PREFIX"
make -j4
make install
cd "$LIB_DIR"

#########################################################
# 6. Libpng Installation
#########################################################
echo "--- [6/9] Installing libpng ---"
if [ ! -d "libpng-1.6.39" ]; then
    wget https://sourceforge.net/projects/libpng/files/libpng16/1.6.39/libpng-1.6.39.tar.gz -O libpng-1.6.39.tar.gz || curl -L https://sourceforge.net/projects/libpng/files/libpng16/1.6.39/libpng-1.6.39.tar.gz -o libpng-1.6.39.tar.gz
    tar -zxvf libpng-1.6.39.tar.gz
fi
cd libpng-1.6.39
./configure --prefix="$PREFIX"
make -j4
make install
cd "$LIB_DIR"

#########################################################
# 7. JasPer Installation (GRIB2 Support)
#########################################################
echo "--- [7/9] Installing JasPer ---"
if [ ! -d "jasper-1.900.1" ]; then
    wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz -O jasper-1.900.1.tar.gz || curl -L https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz -o jasper-1.900.1.tar.gz
    tar -zxvf jasper-1.900.1.tar.gz
fi
cd jasper-1.900.1
./configure --prefix="$PREFIX"
make -j4
make install
cd "$LIB_DIR"

#########################################################
# 8. Flex Installation
#########################################################
echo "--- [8/9] Installing Flex ---"
if [ ! -d "flex-2.6.4" ]; then
    wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz -O flex-2.6.4.tar.gz
    tar -zxvf flex-2.6.4.tar.gz
fi
cd flex-2.6.4
./configure --prefix="$PREFIX"
make -j4
make install
cd "$LIB_DIR"

#########################################################
# 9. Byacc Installation (Yacc)
#########################################################
echo "--- [9/9] Installing byacc ---"
if [ -z "$(ls -d byacc-* 2>/dev/null)" ]; then
    wget https://invisible-island.net/datafiles/release/byacc.tar.gz -O byacc.tar.gz
    tar -zxvf byacc.tar.gz
fi
cd byacc-*
./configure --prefix="$PREFIX"
make -j4
make install
cd "$LIB_DIR"

echo "=== All dependencies successfully built and installed to $PREFIX ==="

# Configure environment variables in ~/.bashrc consistently
echo "Configuring environment variables in ~/.bashrc..."
touch ~/.bashrc
bashrc_additions=(
    "# WRF Local Environment Variables"
    "export DIR=$WRF_HOME"
    "export PREFIX=$PREFIX"
    "export CC=gcc"
    "export CXX=g++"
    "export FC=gfortran"
    "export F77=gfortran"
    "export PATH=\$PREFIX/bin:\$PATH"
    "export LD_LIBRARY_PATH=\$PREFIX/lib:\$LD_LIBRARY_PATH"
    "export NETCDF=\$PREFIX"
    "export HDF5=\$PREFIX"
    "export JASPERLIB=\$PREFIX/lib"
    "export JASPERINC=\$PREFIX/include"
    "export FFLAGS=\"-O3 -fPIC\""
    "export FCFLAGS=\"-O3 -fPIC\""
)

if [ "$type" = "Chem" ]; then
    bashrc_additions+=("export FLEX_LIB_DIR=\$PREFIX/lib" "export YACC='yacc -d'")
fi

for line in "${bashrc_additions[@]}"; do
    grep -qxF "$line" ~/.bashrc || echo "$line" >> ~/.bashrc
done

# Load environment variables for the current session
export DIR="$WRF_HOME"
export PREFIX="$PREFIX"
export PATH="$PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export NETCDF="$PREFIX"
export HDF5="$PREFIX"
export JASPERLIB="$PREFIX/lib"
export JASPERINC="$PREFIX/include"
if [ "$type" = "Chem" ]; then
    export FLEX_LIB_DIR="$PREFIX/lib"
    export YACC="yacc -d"
fi

cd "$WRF_HOME" || exit

#########################################################
#   WRF Installation                                    #
#########################################################
echo "--- Downloading and Compiling WRF v${WRFversion} ---"
if [ -d "WRFV${WRFversion}" ]; then
    rm -rf "WRFV${WRFversion}"
fi

wget https://github.com/wrf-model/WRF/releases/download/v${WRFversion}/v${WRFversion}.tar.gz -O WRFV${WRFversion}.tar.gz
tar -zxvf WRFV${WRFversion}.tar.gz

if [ "$type" = "Hydro" ]; then
    export WRF_HYDRO=1
    wget https://github.com/NCAR/wrf_hydro_nwm_public/archive/refs/tags/v5.3.0.tar.gz -O v5.3.0.tar.gz
    tar -zxvf v5.3.0.tar.gz
    /bin/cp -rf wrf_hydro_nwm_public-5.3.0/trunk/NDHMS/* WRFV${WRFversion}/hydro/
    rm -rf v5.3.0.tar.gz wrf_hydro_nwm_public-5.3.0
fi

cd WRFV${WRFversion} || exit

if [ "$type" = "Chem" ]; then
    export WRF_CHEM=1
    export WRF_KPP=1
fi

# Configure WRF (Option 34: gfortran/gcc dmpar parallel)
( echo 34 ; echo 1 ) | ./configure

gfortversion=$(gfortran -dumpversion | cut -d '.' -f 1)
if [ "$gfortversion" -lt 8 ] && [ "$gfortversion" -ge 6 ]; then
    sed -i '/-DBUILD_RRTMG_FAST=1/d' configure.wrf
fi

echo "Compiling WRF (this can take 20-40 minutes)..."
logsave compile.log ./compile em_real
if grep -q "Problems building executables, look for errors in the build log" compile.log; then
    echo "Error: Compilation failed. Please check compile.log inside WRFV${WRFversion}."
    exit 1
fi

cd "$WRF_HOME" || exit
[ -d "WRF-${WRFversion}-${type}" ] && rm -rf "WRF-${WRFversion}-${type}"
mv WRFV${WRFversion} "WRF-${WRFversion}-${type}"

#########################################################
#   WPS Installation                                    #
#########################################################
echo "--- Downloading and Compiling WPS v${WPSversion} ---"
if [ -d "WPS-${WPSversion}" ]; then
    rm -rf "WPS-${WPSversion}"
fi

wget https://github.com/wrf-model/WPS/archive/v${WPSversion}.tar.gz -O WPSV${WPSversion}.tar.gz
tar -zxvf WPSV${WPSversion}.tar.gz
cd "WPS-${WPSversion}" || exit
./clean

# Configure WPS (Option 3: gfortran dmpar)
echo 3 | ./configure
logsave compile.log ./compile
sed -i "s# geog_data_path.*# geog_data_path = '../WPS_GEOG/'#" namelist.wps

cd "$WRF_HOME" || exit

#########################################################
#   Geography Data Files                                #
#########################################################
echo "--- Setting up WPS_GEOG ---"
if [ ! -d "WPS_GEOG" ]; then
    wget https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz -O geog_high_res_mandatory.tar.gz
    tar -zxvf geog_high_res_mandatory.tar.gz
    rm geog_high_res_mandatory.tar.gz
fi

if [ "$type" = "Chem" ]; then
    cd WPS_GEOG || exit
    Chem_Geog="modis_landuse_21class_30s soiltype_top_2m soiltype_bot_2m albedo_ncep maxsnowalb erod clayfrac_5m sandfrac_5m"
    for i in ${Chem_Geog}; do
        if [ ! -d "$i" ]; then
            echo "Downloading chemical geography dataset: $i..."
            wget https://www2.mmm.ucar.edu/wrf/src/wps_files/${i}.tar.bz2 -O ${i}.tar.bz2
            tar -xvf ${i}.tar.bz2
            rm ${i}.tar.bz2
        fi
    done
    cd "$WRF_HOME" || exit
fi

echo "=== WRF & WPS ${WRFversion} Installation Completed Successfully! ==="
echo "Please run: source ~/.bashrc"
