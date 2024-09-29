#!/bin/bash

prerun() {
    local tool="$1"
    local data_dir="$2"
    local log_dir="$3"
    local log_file="$4"

    case "$tool" in
    darshan)
        export DARSHAN_DUMP_CONFIG=1
        export DARSHAN_LOGPATH="$log_dir"
        export DARSHAN_LOGFILE="$log_file.darshan"
        export DXT_ENABLE_IO_TRACE=1
        export LD_PRELOAD="/usr/local/lib/libdarshan.so"
        ;;
    recorder)
        export RECORDER_TRACES_DIR="$log_dir"
        export LD_PRELOAD="/usr/local/lib/librecorder.so"
        ;;
    dftracer)
        export DFTRACER_DATA_DIR="$data_dir"
        export DFTRACER_INIT=PRELOAD
        export DFTRACER_LOG_FILE="$log_file"
        export LD_PRELOAD="/usr/local/lib/python3.10/dist-packages/dftracer/lib/libdftracer_preload.so"
        ;;
    *)
        echo "Unknown tool: $tool"
        exit 1
        ;;
    esac

    mkdir -p "$data_dir"
    mkdir -p "$log_dir"
}

postrun() {
    local tool="$1"
    local data_dir="$2"
    local log_dir="$3"
    local log_file="$4"

    # stop tracing
    unset LD_PRELOAD

    case "$tool" in
    darshan)
        darshan-parser --all "$log_file.darshan" >"$log_file-darshan-parser-all.txt"
        darshan-parser --total "$log_file.darshan" >"$log_file-darshan-parser-total.txt"
        darshan-dxt-parser "$log_file.darshan" >"$log_file-darshan-dxt-parser.txt"
        darshan-job-summary.pl "$log_file.darshan" --output "$log_file-darshan-job-summary.pdf"
        drishti "$log_file.darshan" >"$log_file-drishti.txt"
        wisio analysis="$tool" analysis.trace_path="$log_file.darshan" >"$log_file-wisio.txt"
        ;;
    recorder)
        wisio-recorder2parquet "$log_dir"
        recorder2text "$log_dir"
        recorder2timeline "$log_dir"
        wisio analysis="$tool" analysis.trace_path="$log_dir/_parquet" >"$log_file-wisio.txt"
        ;;
    dftracer)
        wisio analysis="$tool" analysis.trace_path="$log_file*.pfw" >"$log_file-wisio.txt"
        ;;
    *)
        echo "Unknown tool: $tool"
        exit 1
        ;;
    esac
}

run_h5bench() {
    local tool="$1"

    local h5bench_name="h5bench"
    local h5bench_dir="/opt/$h5bench_name"

    local data_dir="$h5bench_dir/storage"

    local log_dir="$2/$(date +%s)"
    local log_file="$log_dir/$h5bench_name"

    prerun "$tool" "$data_dir" "$log_dir" "$log_file"

    h5bench --debug --validate-mode "$h5bench_dir/samples/sync-write-1d-contig-contig.json"

    postrun "$tool" "$data_dir" "$log_dir" "$log_file"
}

run_ior() {
    local tool="$1"

    local ior_api="${3:-POSIX}"
    local ior_name="ior"
    local ior_dir="/opt/$ior_name"

    local data_dir="$ior_dir/storage"

    local log_dir="$2/$(date +%s)"
    local log_file="$log_dir/$ior_name"

    if [ "$ior_api" = "HDF5" ]; then
        # ior does not support async vol
        unset HDF5_VOL_CONNECTOR
        unset HDF5_PLUGIN_PATH
    fi

    prerun "$tool" "$data_dir" "$log_dir" "$log_file"

    # ior -a POSIX -b 1G -t 1m -w -F -o "$data_dir/ior"
    # ior -a MPIIO -b 1G -t 1m -w -F -o "$data_dir/ior"

    ior -a "$ior_api" -b 4G -t 1m -w -F -o "$data_dir/ior" -O useO_DIRECT=1

    postrun "$tool" "$data_dir" "$log_dir" "$log_file"
}
