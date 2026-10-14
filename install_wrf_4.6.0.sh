#!/bin/bash
#=============================================================================================
#  install_wrf_4.6.0.sh
#
#  Installs WRF/WPS 4.6.0 (ARW, Chem and/or Hydro) plus all required libraries in a
#  user-writable directory (no root needed).
#
#  Source download links and build steps : install_wrf_and_libraries.sh
#  Environment-variable setup method     : uems_install.pl (UEMS), namely:
#     - LC_ALL=C and proxy variables handled up front   (UEMS_Initialize / --proxy)
#     - template files with placeholders (WRFDIR, NPROCS, ...) filled in by the installer
#       (SystemConfig)
#     - an environment *modulefile* instead of editing ~/.bashrc  (UEMSwrkstn)
#     - a "Do List" file with Bash and Tcsh instructions written to $HOME (PrintGuidance)
#     - --homedir / --continue / --force / --proxy style flags
#
#  Usage:
#     bash install_wrf_4.6.0.sh -arw
#     bash install_wrf_4.6.0.sh -chem
#     bash install_wrf_4.6.0.sh -hydro
#     bash install_wrf_4.6.0.sh -arw -chem -hydro     (or: -all)
#
#  Options:
#     --homedir DIR   Top-level install dir               (default: $HOME/Build_WRF)
#     --proxy HOST:PORT   Set http_proxy/https_proxy      (default: proxies are cleared)
#     --continue      Skip libraries already installed (keeps tarballs)
#     --force         Rebuild everything, even if already installed
#     --nogeog        Do not download WPS_GEOG
#     --help
#=============================================================================================

set -eo pipefail

WRFversion="4.6.0"
WPSversion="4.6.0"

#---------------------------------------------------------------------------------------------
#  UEMS-style initialization: language and proxy handling
#---------------------------------------------------------------------------------------------
export LC_ALL=C
unset http_proxy https_proxy       # proxies OFF by default - see --proxy

#---------------------------------------------------------------------------------------------
#  Flag parsing
#---------------------------------------------------------------------------------------------
TYPES=()
WRF_HOME="$HOME/Build_WRF"
CONTINUE=0
FORCE=0
NOGEOG=0

usage() { sed -n '2,/^#=====*$/p' "$0" | sed -n '/Usage:/,$p' | sed 's/^#//'; exit "${1:-1}"; }

while [ $# -gt 0 ]; do
    case "$1" in
        -arw)      TYPES+=("ARW") ;;
        -chem)     TYPES+=("Chem") ;;
        -hydro)    TYPES+=("Hydro") ;;
        -all)      TYPES=("ARW" "Chem" "Hydro") ;;
        --homedir) shift; WRF_HOME="${1:?--homedir requires a path}" ;;
        --proxy)   shift; PROXY="${1:?--proxy requires HOST:PORT}"
                   export http_proxy="http://${PROXY%/}/"; export https_proxy="https://${PROXY%/}/" ;;
        --continue) CONTINUE=1 ;;
        --force)    FORCE=1 ;;
        --nogeog)   NOGEOG=1 ;;
        -h|--help)  usage 0 ;;
        *) echo "Unrecognized option: $1"; usage 1 ;;
    esac
    shift
done

if [ ${#TYPES[@]} -eq 0 ]; then
    echo "You must choose at least one build type:"
    echo "  For WRF-ARW   : bash $0 -arw"
    echo "  For WRF-Chem  : bash $0 -chem"
    echo "  For WRF-Hydro : bash $0 -hydro"
    exit 1
fi
# remove duplicates
mapfile -t TYPES < <(printf '%s\n' "${TYPES[@]}" | awk '!s[$0]++')

#---------------------------------------------------------------------------------------------
#  Paths
#---------------------------------------------------------------------------------------------
WRF_HOME="$(mkdir -p "$WRF_HOME" && cd "$WRF_HOME" && pwd)"
LIB_DIR="$WRF_HOME/LIBRARIES"
PREFIX="$WRF_HOME/local"
PKG_DIR="$WRF_HOME/packages"                    # saved tarballs (like uems/packages)
MODDIR="$WRF_HOME/etc/modulefiles"              # like uems/etc/modulefiles
LOGDIR="$WRF_HOME/logs"

mkdir -p "$LIB_DIR" "$PREFIX"/{include,lib,bin} "$PKG_DIR" "$MODDIR" "$LOGDIR"

NPROCS=$(nproc 2>/dev/null || echo 4)           # UEMS places NPROCS in its config files
MAKEJ=$(( NPROCS > 8 ? 8 : NPROCS ))

echo "=== WRF ${WRFversion} installer ==="
echo "Build types      : ${TYPES[*]}"
echo "Install location: $WRF_HOME"
echo "Processors      : $NPROCS (using make -j$MAKEJ)"

#---------------------------------------------------------------------------------------------
#  Helpers
#---------------------------------------------------------------------------------------------
fetch() {   # fetch URL OUTFILE   -> saved under packages/, wget first, curl as fallback
    local url="$1" out="$PKG_DIR/$2"
    if [ -s "$out" ] && [ $FORCE -eq 0 ]; then return 0; fi
    rm -f "$out"
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress "$url" -O "$out" || { rm -f "$out"; command -v curl >/dev/null && curl -fL "$url" -o "$out"; }
    else
        curl -fL "$url" -o "$out"
    fi
    [ -s "$out" ] || { echo "ERROR: failed to download $url"; exit 1; }
}

unpack() {  # unpack TARFILE DIRNAME   (into $LIB_DIR)
    [ -d "$LIB_DIR/$2" ] && [ $FORCE -eq 0 ] || { rm -rf "$LIB_DIR/${2:?}"; tar -xf "$PKG_DIR/$1" -C "$LIB_DIR"; }
}

done_marker() { echo "$PREFIX/.installed_$1"; }
is_done() { [ $CONTINUE -eq 1 ] && [ $FORCE -eq 0 ] && [ -f "$(done_marker "$1")" ]; }
mark_done() { touch "$(done_marker "$1")"; }

#---------------------------------------------------------------------------------------------
#  Compiler / build environment for the libraries
#---------------------------------------------------------------------------------------------
export CC=gcc CXX=g++ FC=gfortran F77=gfortran
export CFLAGS="-O3 -fPIC" FCFLAGS="-O3 -fPIC" FFLAGS="-O3 -fPIC"
export PATH="$PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"
export LDFLAGS="-L$PREFIX/lib"
export CPPFLAGS="-I$PREFIX/include"

cd "$LIB_DIR"

#=============================================================================================
#  LIBRARIES   (links taken from install_wrf_and_libraries.sh)
#=============================================================================================
build_zlib() {
    echo "--- [1/9] zlib ---"
    fetch https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.gz zlib-1.2.13.tar.gz
    unpack zlib-1.2.13.tar.gz zlib-1.2.13
    ( cd zlib-1.2.13 && ./configure --prefix="$PREFIX" && make -j$MAKEJ && make install )
}

build_hdf5() {
    echo "--- [2/9] HDF5 ---"
    fetch https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.2/src/hdf5-1.12.2.tar.gz hdf5-1.12.2.tar.gz
    unpack hdf5-1.12.2.tar.gz hdf5-1.12.2
    ( cd hdf5-1.12.2 && ./configure --prefix="$PREFIX" --with-zlib="$PREFIX" --enable-parallel=no --enable-hl --enable-fortran \
        && make -j$MAKEJ && make install )
}

build_netcdf_c() {
    echo "--- [3/9] NetCDF-C ---"
    fetch https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.9.2.tar.gz netcdf-c-4.9.2.tar.gz
    unpack netcdf-c-4.9.2.tar.gz netcdf-c-4.9.2
    ( cd netcdf-c-4.9.2 && ./configure --prefix="$PREFIX" --with-hdf5="$PREFIX" --disable-dap --disable-byterange \
        && make -j$MAKEJ && make install )
}

build_netcdf_fortran() {
    echo "--- [4/9] NetCDF-Fortran ---"
    fetch https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.1.tar.gz netcdf-fortran-4.6.1.tar.gz
    unpack netcdf-fortran-4.6.1.tar.gz netcdf-fortran-4.6.1
    ( export LIBS="-lnetcdf -lhdf5_hl -lhdf5 -lz"
      cd netcdf-fortran-4.6.1 && ./configure --prefix="$PREFIX" --with-netcdf="$PREFIX" \
        && make -j$MAKEJ && make install )
}

build_mpich() {
    echo "--- [5/9] MPICH ---"
    fetch https://www.mpich.org/static/downloads/4.1.2/mpich-4.1.2.tar.gz mpich-4.1.2.tar.gz
    unpack mpich-4.1.2.tar.gz mpich-4.1.2
    ( cd mpich-4.1.2 && ./configure --prefix="$PREFIX" && make -j$MAKEJ && make install )
}

build_libpng() {
    echo "--- [6/9] libpng ---"
    fetch https://sourceforge.net/projects/libpng/files/libpng16/1.6.39/libpng-1.6.39.tar.gz libpng-1.6.39.tar.gz
    unpack libpng-1.6.39.tar.gz libpng-1.6.39
    ( cd libpng-1.6.39 && ./configure --prefix="$PREFIX" && make -j$MAKEJ && make install )
}

build_jasper() {
    echo "--- [7/9] JasPer ---"
    fetch https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz jasper-1.900.1.tar.gz
    unpack jasper-1.900.1.tar.gz jasper-1.900.1
    ( cd jasper-1.900.1 && ./configure --prefix="$PREFIX" && make -j$MAKEJ && make install )
}

build_flex() {
    echo "--- [8/9] Flex ---"
    fetch https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz flex-2.6.4.tar.gz
    unpack flex-2.6.4.tar.gz flex-2.6.4
    ( cd flex-2.6.4 && ./configure --prefix="$PREFIX" && make -j$MAKEJ && make install )
}

build_byacc() {
    echo "--- [9/9] byacc ---"
    fetch https://invisible-island.net/datafiles/release/byacc.tar.gz byacc.tar.gz
    if [ -z "$(ls -d byacc-* 2>/dev/null)" ] || [ $FORCE -eq 1 ]; then
        rm -rf byacc-*; tar -xf "$PKG_DIR/byacc.tar.gz" -C "$LIB_DIR"
    fi
    ( cd byacc-* && ./configure --prefix="$PREFIX" && make -j$MAKEJ && make install )
}

# Flex and byacc are only required by WRF-Chem (KPP), but they are cheap, so always built.
for lib in zlib hdf5 netcdf_c netcdf_fortran mpich libpng jasper flex byacc; do
    if is_done "$lib"; then echo "--- $lib already installed (skipping) ---"; continue; fi
    "build_$lib" > "$LOGDIR/lib_${lib}.log" 2>&1 || { echo "ERROR building $lib - see $LOGDIR/lib_${lib}.log"; tail -n 20 "$LOGDIR/lib_${lib}.log"; exit 1; }
    mark_done "$lib"
    echo "    $lib done"
done

echo "=== All libraries installed to $PREFIX ==="

#=============================================================================================
#  ENVIRONMENT SETUP  (UEMS method: templated modulefile + sourceable files + Do-List)
#
#  UEMS writes template files containing placeholders (EMSDIR, NPROCS, ...) and then
#  replaces them with the real values (SystemConfig). The same is done here.
#=============================================================================================
write_environment_files() {
    local type="$1"
    local lt; lt=$(echo "$type" | tr 'A-Z' 'a-z')
    local wrfdir="$WRF_HOME/WRF-${WRFversion}-${type}"
    local wpsdir="$WRF_HOME/WPS-${WPSversion}-${type}"
    local modfile="$MODDIR/WRF${type}"
    local shfile="$MODDIR/WRF${type}.sh"
    local cshfile="$MODDIR/WRF${type}.csh"

    #---- Tcl modulefile template ------------------------------------------------------------
    cat > "$modfile" <<'EOF'
#%Module1.0
##  WRF @TYPE@ @WRFVER@ environment - generated by install_wrf_4.6.0.sh
module-whatis "WRF @WRFVER@ (@TYPE@) with local libraries"

set wrfhome  @WRFHOME@
set prefix   @PREFIX@

setenv WRF_HOME      $wrfhome
setenv WRF_DIR       @WRFDIR@
setenv WPS_DIR       @WPSDIR@
setenv WPS_GEOG      $wrfhome/WPS_GEOG
setenv NPROCS        @NPROCS@
setenv DIR           $wrfhome
setenv PREFIX        $prefix
setenv CC            gcc
setenv CXX           g++
setenv FC            gfortran
setenv F77           gfortran
setenv NETCDF        $prefix
setenv HDF5          $prefix
setenv JASPERLIB     $prefix/lib
setenv JASPERINC     $prefix/include
setenv FFLAGS        "-O3 -fPIC"
setenv FCFLAGS       "-O3 -fPIC"
@EXTRA_TCL@
prepend-path PATH            $prefix/bin
prepend-path LD_LIBRARY_PATH $prefix/lib
EOF

    #---- Bash and Tcsh template -------------------------------------------------------------
    cat > "$shfile" <<'EOF'
# WRF @TYPE@ @WRFVER@ environment (bash) - source this file
export WRF_HOME=@WRFHOME@
export WRF_DIR=@WRFDIR@
export WPS_DIR=@WPSDIR@
export WPS_GEOG=@WRFHOME@/WPS_GEOG
export NPROCS=@NPROCS@
export DIR=@WRFHOME@
export PREFIX=@PREFIX@
export CC=gcc CXX=g++ FC=gfortran F77=gfortran
export NETCDF=@PREFIX@
export HDF5=@PREFIX@
export JASPERLIB=@PREFIX@/lib
export JASPERINC=@PREFIX@/include
export FFLAGS="-O3 -fPIC"
export FCFLAGS="-O3 -fPIC"
@EXTRA_SH@
export PATH=@PREFIX@/bin:$PATH
export LD_LIBRARY_PATH=@PREFIX@/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
EOF

    cat > "$cshfile" <<'EOF'
# WRF @TYPE@ @WRFVER@ environment (tcsh) - source this file
setenv WRF_HOME @WRFHOME@
setenv WRF_DIR @WRFDIR@
setenv WPS_DIR @WPSDIR@
setenv WPS_GEOG @WRFHOME@/WPS_GEOG
setenv NPROCS @NPROCS@
setenv DIR @WRFHOME@
setenv PREFIX @PREFIX@
setenv CC gcc
setenv CXX g++
setenv FC gfortran
setenv F77 gfortran
setenv NETCDF @PREFIX@
setenv HDF5 @PREFIX@
setenv JASPERLIB @PREFIX@/lib
setenv JASPERINC @PREFIX@/include
setenv FFLAGS "-O3 -fPIC"
setenv FCFLAGS "-O3 -fPIC"
@EXTRA_CSH@
setenv PATH @PREFIX@/bin:${PATH}
if ($?LD_LIBRARY_PATH) then
    setenv LD_LIBRARY_PATH @PREFIX@/lib:${LD_LIBRARY_PATH}
else
    setenv LD_LIBRARY_PATH @PREFIX@/lib
endif
EOF

    #---- Build-type specific variables ------------------------------------------------------
    local x_tcl="" x_sh="" x_csh=""
    case "$type" in
        Chem)
            x_tcl=$'setenv WRF_CHEM 1\nsetenv WRF_KPP 1\nsetenv FLEX_LIB_DIR $prefix/lib\nsetenv YACC "yacc -d"'
            x_sh=$'export WRF_CHEM=1\nexport WRF_KPP=1\nexport FLEX_LIB_DIR=@PREFIX@/lib\nexport YACC="yacc -d"'
            x_csh=$'setenv WRF_CHEM 1\nsetenv WRF_KPP 1\nsetenv FLEX_LIB_DIR @PREFIX@/lib\nsetenv YACC "yacc -d"' ;;
        Hydro)
            x_tcl='setenv WRF_HYDRO 1'
            x_sh='export WRF_HYDRO=1'
            x_csh='setenv WRF_HYDRO 1' ;;
    esac

    #---- Replace placeholders (like UEMS SystemConfig) -------------------------------------
    local f
    for f in "$modfile" "$shfile" "$cshfile"; do
        sed -i \
            -e "s|@WRFHOME@|$WRF_HOME|g" \
            -e "s|@PREFIX@|$PREFIX|g" \
            -e "s|@WRFDIR@|$wrfdir|g" \
            -e "s|@WPSDIR@|$wpsdir|g" \
            -e "s|@NPROCS@|$NPROCS|g" \
            -e "s|@WRFVER@|$WRFversion|g" \
            -e "s|@TYPE@|$type|g" "$f"
    done
    # multi-line substitutions (done via awk to stay safe with newlines)
    awk -v r="$x_tcl" '{ if ($0=="@EXTRA_TCL@") { if (r!="") print r } else print }' "$modfile" > "$modfile.tmp" && mv "$modfile.tmp" "$modfile"
    awk -v r="$x_sh"  '{ if ($0=="@EXTRA_SH@")  { if (r!="") print r } else print }' "$shfile"  > "$shfile.tmp"  && mv "$shfile.tmp"  "$shfile"
    awk -v r="$x_csh" '{ if ($0=="@EXTRA_CSH@") { if (r!="") print r } else print }' "$cshfile" > "$cshfile.tmp" && mv "$cshfile.tmp" "$cshfile"
    sed -i -e "s|@PREFIX@|$PREFIX|g" "$shfile" "$cshfile"
}

# Load the environment into THIS script's session for a given build type (needed for compiling)
load_build_env() {
    local type="$1"
    export DIR="$WRF_HOME" PREFIX="$PREFIX"
    export NETCDF="$PREFIX" HDF5="$PREFIX"
    export JASPERLIB="$PREFIX/lib" JASPERINC="$PREFIX/include"
    export PATH="$PREFIX/bin:$PATH"
    export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"
    unset WRF_CHEM WRF_KPP WRF_HYDRO FLEX_LIB_DIR YACC
    case "$type" in
        Chem)  export WRF_CHEM=1 WRF_KPP=1 FLEX_LIB_DIR="$PREFIX/lib" YACC="yacc -d" ;;
        Hydro) export WRF_HYDRO=1 ;;
    esac
}

#=============================================================================================
#  WRF / WPS BUILD (per type)
#=============================================================================================
build_wrf() {
    local type="$1"
    local wrfdir="$WRF_HOME/WRF-${WRFversion}-${type}"
    local log="$LOGDIR/wrf_${type}.log"

    if [ -d "$wrfdir" ] && [ -x "$wrfdir/main/wrf.exe" ] && [ $FORCE -eq 0 ]; then
        echo "--- WRF ${type} already built (use --force to rebuild) ---"
        return 0
    fi

    echo "--- Downloading and compiling WRF v${WRFversion} (${type}) ---"
    cd "$WRF_HOME"
    load_build_env "$type"

    fetch "https://github.com/wrf-model/WRF/releases/download/v${WRFversion}/v${WRFversion}.tar.gz" "WRFV${WRFversion}.tar.gz"

    rm -rf "WRFV${WRFversion}" "$wrfdir"
    tar -xf "$PKG_DIR/WRFV${WRFversion}.tar.gz" -C "$WRF_HOME"
    # The GitHub tarball extracts to WRFV4.6.0 or WRF-4.6.0 depending on the release
    [ -d "WRFV${WRFversion}" ] || mv "WRF-${WRFversion}" "WRFV${WRFversion}"

    if [ "$type" = "Hydro" ]; then
        fetch https://github.com/NCAR/wrf_hydro_nwm_public/archive/refs/tags/v5.3.0.tar.gz v5.3.0.tar.gz
        rm -rf wrf_hydro_nwm_public-5.3.0
        tar -xf "$PKG_DIR/v5.3.0.tar.gz" -C "$WRF_HOME"
        /bin/cp -rf wrf_hydro_nwm_public-5.3.0/trunk/NDHMS/* "WRFV${WRFversion}/hydro/"
        rm -rf wrf_hydro_nwm_public-5.3.0
    fi

    cd "WRFV${WRFversion}"

    # Option 34: gfortran/gcc dmpar ; nesting option 1 = basic
    ( echo 34 ; echo 1 ) | ./configure > "$log" 2>&1

    local gfortversion; gfortversion=$(gfortran -dumpversion | cut -d '.' -f 1)
    if [ "$gfortversion" -lt 8 ] && [ "$gfortversion" -ge 6 ]; then
        sed -i '/-DBUILD_RRTMG_FAST=1/d' configure.wrf
    fi

    echo "Compiling WRF ${type} (this can take 20-40+ minutes) - log: $log"
    ./compile em_real >> "$log" 2>&1 || true
    if grep -q "Problems building executables, look for errors in the build log" "$log" || [ ! -x main/wrf.exe ]; then
        echo "ERROR: WRF ${type} compilation failed. See $log"
        exit 1
    fi

    cd "$WRF_HOME"
    mv "WRFV${WRFversion}" "$wrfdir"
}

build_wps() {
    local type="$1"
    local wrfdir="$WRF_HOME/WRF-${WRFversion}-${type}"
    local wpsdir="$WRF_HOME/WPS-${WPSversion}-${type}"
    local log="$LOGDIR/wps_${type}.log"

    if [ -d "$wpsdir" ] && [ -x "$wpsdir/geogrid.exe" ] && [ $FORCE -eq 0 ]; then
        echo "--- WPS ${type} already built (use --force to rebuild) ---"
        return 0
    fi

    echo "--- Downloading and compiling WPS v${WPSversion} (${type}) ---"
    cd "$WRF_HOME"
    load_build_env "$type"

    fetch "https://github.com/wrf-model/WPS/archive/v${WPSversion}.tar.gz" "WPSV${WPSversion}.tar.gz"
    rm -rf "WPS-${WPSversion}" "$wpsdir"
    tar -xf "$PKG_DIR/WPSV${WPSversion}.tar.gz" -C "$WRF_HOME"
    mv "WPS-${WPSversion}" "$wpsdir"

    cd "$wpsdir"
    ./clean > /dev/null 2>&1 || true
    export WRF_DIR="$wrfdir"

    # Option 3: gfortran dmpar
    echo 3 | ./configure > "$log" 2>&1
    ./compile >> "$log" 2>&1 || true
    if [ ! -x geogrid.exe ] || [ ! -x ungrib.exe ] || [ ! -x metgrid.exe ]; then
        echo "ERROR: WPS ${type} compilation failed. See $log"
        exit 1
    fi
    sed -i "s# geog_data_path.*# geog_data_path = '$WRF_HOME/WPS_GEOG/'#" namelist.wps
    cd "$WRF_HOME"
}

#=============================================================================================
#  GEOGRAPHY DATA (shared by all build types)
#=============================================================================================
setup_geog() {
    cd "$WRF_HOME"
    if [ $NOGEOG -eq 1 ]; then echo "--- Skipping WPS_GEOG (--nogeog) ---"; return; fi
    echo "--- Setting up WPS_GEOG ---"
    if [ ! -d "WPS_GEOG" ]; then
        fetch https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz geog_high_res_mandatory.tar.gz
        tar -xf "$PKG_DIR/geog_high_res_mandatory.tar.gz" -C "$WRF_HOME"
    fi

    local t
    for t in "${TYPES[@]}"; do
        if [ "$t" = "Chem" ]; then
            ( cd WPS_GEOG
              for i in modis_landuse_21class_30s soiltype_top_2m soiltype_bot_2m albedo_ncep maxsnowalb erod clayfrac_5m sandfrac_5m; do
                  if [ ! -d "$i" ]; then
                      echo "Downloading chemical geography dataset: $i ..."
                      fetch "https://www2.mmm.ucar.edu/wrf/src/wps_files/${i}.tar.bz2" "${i}.tar.bz2"
                      tar -xf "$PKG_DIR/${i}.tar.bz2" -C .
                  fi
              done )
            break
        fi
    done
}

#=============================================================================================
#  MAIN
#=============================================================================================
for type in "${TYPES[@]}"; do
    build_wrf "$type"
    build_wps "$type"
    write_environment_files "$type"
done
setup_geog

# download WRF-domain-Wizard 
mkdir -p "$WRF_HOME/domwizard"
git clone https://github.com/goikelem/WRF-domain-Wizard "$WRF_HOME/domwizard"

#=============================================================================================
#  UEMS-style "Do List" - tells the user how to load the environment
#=============================================================================================
DOLIST="$HOME/WRF-DoList.txt"
HAVE_MODULES=0
{ command -v modulecmd >/dev/null 2>&1 || [ -x /usr/bin/modulecmd ] || type module >/dev/null 2>&1; } && HAVE_MODULES=1

{
echo "Greetings, wonderful WRF owner."
echo
echo "WRF ${WRFversion} was installed under: $WRF_HOME"
echo "Build type(s): ${TYPES[*]}"
echo
echo "For you to use the system the environment must be set. Pick ONE build type"
echo "at a time (WRFARW, WRFChem or WRFHydro) - don't load more than one together."
echo
if [ $HAVE_MODULES -eq 1 ]; then
    echo "### Option 1: Environment Modules (recommended) ###"
    echo
    echo " If using Bash shell (add to ~/.bashrc):"
    echo
    echo "   # Add the path to the WRF module files to MODULEPATH"
    echo "   export MODULEPATH=\"\${MODULEPATH}:$MODDIR\""
    echo "   module load WRF${TYPES[0]}"
    echo
    echo " If using Tcsh shell (add to ~/.cshrc):"
    echo
    echo "   setenv MODULEPATH \${MODULEPATH}:$MODDIR"
    echo "   module load WRF${TYPES[0]}"
    echo
    echo "### Option 2: Source the environment file ###"
else
    echo "The environment modules package (modulecmd) does not appear to be installed,"
    echo "so just source the environment files instead:"
fi
echo
for t in "${TYPES[@]}"; do
    echo " WRF-${t}:"
    echo "   Bash : source $MODDIR/WRF${t}.sh"
    echo "   Tcsh : source $MODDIR/WRF${t}.csh"
done
echo
echo "And while you are editing your login file, comment out or delete references to"
echo "previous WRF environments, because they will come looking for you."
} > "$DOLIST"

echo
echo "================================================================"
echo " WRF ${WRFversion} installation complete for: ${TYPES[*]}"
echo "================================================================"
echo " Executables:"
for t in "${TYPES[@]}"; do
    echo "   WRF-${t}: $WRF_HOME/WRF-${WRFversion}-${t}/main/{wrf,real,ndown,tc}.exe"
    echo "   WPS-${t}: $WRF_HOME/WPS-${WPSversion}-${t}/{geogrid,ungrib,metgrid}.exe"
done
echo
echo " Environment files : $MODDIR"
echo " Instructions     : $DOLIST"
echo " Logs             : $LOGDIR"
echo
cat "$DOLIST"
