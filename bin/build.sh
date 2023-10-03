#!/usr/bin/env bash

config_dir="${PWD}/config"
timestamp=$(date -u +"%Y%m%d%H%M%S")

while IFS=$',' read -r board shield; do
    extra_cmake_args=${shield:+-DSHIELD="$shield"}
    artifact_name=${shield:+${shield// /-}-}${board}-zmk
    filename="firmware/${timestamp}-${artifact_name}"
    build_dir="build/${artifact_name}"

    echo ""
    echo "-----------------"
    echo "BUILDING FIRMWARE"
    echo "-----------------"
    echo "Zephyr: ${ZEPHYR_VERSION}"
    echo "Board: ${board}"
    echo "Shield: ${shield}"
    echo ""

    if [[ ! -d "$build_dir" ]]; then
        west build -s zmk/app -b "$board" -d ${build_dir} -- \
            -DZMK_CONFIG="$config_dir" "${extra_cmake_args}"
    else
        west build -d ${build_dir} -- -DZMK_CONFIG="$config_dir"
    fi

    if [[ ! -z $OUTPUT_ZMK_CONFIG ]]; then
        grep -v -e "^#" -e "^$" ${build_dir}/zephyr/.config \
            | sort > "${filename}.config"
    fi

    cp ${build_dir}/zephyr/zmk.uf2 "${filename}.uf2"
done < <(yq '
    [{"board": .board[], "shield": .shield[] // ""}] + .include
    | filter(.board)
    | unique_by(.board + .shield).[]
    | [.board, .shield // ""]
    | @csv
' build.yaml)
