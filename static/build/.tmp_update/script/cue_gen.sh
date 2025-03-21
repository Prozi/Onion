#!/bin/sh
if [ -z "$rootdir" ]; then
    rootdir="/mnt/SDCARD/Roms"
fi

if [ $# -gt 0 ]; then
    targets="$1"
else
    targets="PS SEGACD NEOCD PCE PCFX AMIGA"
fi

cd "$rootdir"

find $targets -maxdepth 3 -name "*.bin" -type f 2>/dev/null | sort | (
    count=0

    while read target; do
        dir_path=$(dirname "$target")
        target_name=$(basename "$target")
        target_base="${target_name%.*}"

        # strip filename of () and trim
        game_name=$(echo "$target_name" | sed -E 's/\(.*\)//g' | sed 's/\..*$//' | sed 's/[[:space:]]*$//')

        # Extract track number if present
        track_number=$(echo "$target_base" | sed -E 's/.*(Track|Disc|Disk) ([0-9]+).*/\2/;t;d')

        # If no track number found, use "01"
        if [ -z "$track_number" ]; then
            track_number="01"
        fi

        # Add leading zero to track number if it is a single digit
        if echo "$track_number" | grep -q '^[0-9]$'; then
            track_number="0$track_number"
        fi

        # write cue if next game
        if ! echo "$game_name" | grep -q "^$previous_game_name$"; then
            # empty cue
            if echo "$cue" | grep -q '^$'; then
                # rewrite cue - track 01
                cue="FILE \"$previous_target\" BINARY
    TRACK $track_number MODE1/2352
        INDEX 01 00:00:00"
            fi

            cue_path="$dir_path/$previous_game_name.cue"

            echo "GAME \"$dir_path/$previous_game_name\""
            echo "$cue"
            echo "$cue" >"$cue_path"

            cue=""
            count=$((count + 1))
        fi

        previous_track_number="$track_number"
        previous_target="$target"

        # for first tracks
        if echo "$track_number" | grep -q '01'; then
            # rewrite cue - track 01
            cue="FILE \"$target\" BINARY
    TRACK $track_number MODE1/2352
        INDEX 01 00:00:00"
        # for non first tracks
        else
            # append cue - audio
            cue="$cue
FILE \"$target\" BINARY
    TRACK $track_number AUDIO
        INDEX 00 00:00:00
        INDEX 01 00:02:00"
        fi

        previous_game_name="$game_name"

    done

    cue_path="$dir_path/$previous_game_name.cue"

    echo "GAME y \"$dir_path/$game_name\""
    echo "$cue"
    echo "$cue" >"$cue_path"

    count=$((count + 1))

    # print totals
    echo "$count cue $([ $count -eq 1 ] && echo "file" || echo "files") created"
)

find $targets -maxdepth 1 -type f -name "*_cache6.db" -exec rm -f {} \;

echo "Success"
