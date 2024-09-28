#!/bin/bash

install_argobots() {
    local prefix=$1
    local argobots_version=$2
    git clone https://github.com/pmodels/argobots.git argobots
    # shellcheck disable=SC2164
    cd argobots
    git checkout "tags/v$argobots_version"
    ./autogen.sh
    ./configure --prefix="$prefix"
    make -j
    make install
    # shellcheck disable=SC2103
    cd ..
}

install_darshan() {
    local prefix=$1
    local darshan_version=$2
    local darshan_log_path=${3:-/var/log/darshan}
    mkdir -p "$darshan_log_path"
    git clone https://github.com/darshan-hpc/darshan.git darshan
    # shellcheck disable=SC2164
    cd darshan
    git checkout "tags/darshan-$darshan_version"
    ./prepare.sh
    # shellcheck disable=SC2164
    cd darshan-runtime
    CC=mpicc ./configure \
        --prefix="$prefix" \
        --enable-hdf5-mod \
        --with-jobid-env=NONE \
        --with-hdf5="$prefix" \
        --with-log-path="$darshan_log_path"
    make -j
    make install
    # shellcheck disable=SC2103
    cd ..
    # shellcheck disable=SC2164
    cd darshan-util
    ./configure --prefix="$prefix"
    make -j
    make install
    # shellcheck disable=SC2103
    cd ../..
}

install_hdf5() {
    local prefix=$1
    local hdf5_version=$2
    git clone https://github.com/HDFGroup/hdf5.git hdf5
    # shellcheck disable=SC2164
    cd hdf5
    git checkout "tags/hdf5_$hdf5_version"
    CC=mpicc ./configure \
        --prefix="$prefix" \
        --enable-parallel \
        --enable-threadsafe \
        --enable-unsupported
    make -j
    make install
    make check-install
    # shellcheck disable=SC2103
    cd ..
}

install_hdf5_async_vol() {
    local prefix=$1
    local async_vol_version=$2
    git clone https://github.com/HDFGroup/vol-async.git hdf5-vol-async
    # shellcheck disable=SC2164
    cd hdf5-vol-async
    git checkout "tags/v$async_vol_version"
    mkdir build
    # shellcheck disable=SC2164
    cd build
    cmake .. \
        -DCMAKE_C_COMPILER=mpicc \
        -DCMAKE_INSTALL_PREFIX="$prefix"
    make -j
    make install
    # shellcheck disable=SC2103
    cd ../..
}

install_h5bench() {
    local prefix=$1
    local h5bench_version=$2
    git clone https://github.com/hpc-io/h5bench.git h5bench
    # shellcheck disable=SC2164
    cd h5bench
    git checkout "tags/$h5bench_version"
    mkdir build
    # shellcheck disable=SC2164
    cd build
    cmake .. \
        -DCMAKE_C_FLAGS="-I/$prefix/include -L/$prefix/lib" \
        -DCMAKE_INSTALL_PREFIX="$prefix" \
        -DH5BENCH_METADATA=ON \
        -DWITH_ASYNC_VOL=ON
    make -j
    make install
    # shellcheck disable=SC2103
    cd ../..
}

install_ior() {
    local prefix=$1
    local ior_version=$2
    git clone https://github.com/hpc/ior.git ior
    # shellcheck disable=SC2164
    cd ior
    git checkout "tags/$ior_version"
    ./bootstrap
    ./configure --prefix="$prefix" --with-hdf5
    make -j
    make install
    # shellcheck disable=SC2103
    cd ..
}

install_recorder() {
    local prefix=$1
    local recorder_version=$2
    if [ -n "$RECORDER_TRACES_DIR" ]; then
        mkdir -p "$RECORDER_TRACES_DIR"
    fi
    git clone https://github.com/uiuc-hpc/Recorder.git recorder
    # shellcheck disable=SC2164
    cd recorder
    git checkout "tags/v$recorder_version"
    git submodule update --init --recursive
    mkdir build
    # shellcheck disable=SC2164
    cd build
    cmake .. -DCMAKE_INSTALL_PREFIX="$prefix"
    make -j
    make install
    # shellcheck disable=SC2103
    cd ../..
}

# Example usage:
# install_argobots <prefix> <argobots_version>
# install_darshan <prefix> <darshan_version> <darshan_log_path>
# install_hdf5 <prefix> <hdf5_version>
# install_hdf5_async_vol <prefix> <async_vol_version>
# install_ior <prefix> <ior_version>
# install_recorder <prefix> <recorder_version>
