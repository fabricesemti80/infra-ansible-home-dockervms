#!/bin/bash

# Script to move folders from sources to destinations on QNAP NAS
# Removes "[...]" patterns from folder names
# Defaults to dry-run mode

# Configuration
SSH_CMD="ssh -i ~/.ssh/fs_home_rsa admin-fabrice@10.0.40.2"

# Default source and destination pairs
DEFAULT_MOVIES_SRC="/share/Public/media/movies"
DEFAULT_MOVIES_DST="/share/Public/docker-compose-data/media/movies"

DEFAULT_TV_SRC="/share/Public/media/tv"
DEFAULT_TV_DST="/share/Public/docker-compose-data/media/tv"

# Override with command line if provided
MOVIES_SRC="$DEFAULT_MOVIES_SRC"
MOVIES_DST="$DEFAULT_MOVIES_DST"
TV_SRC="$DEFAULT_TV_SRC"
TV_DST="$DEFAULT_TV_DST"

# Number of folders to process per source
NUM_FOLDERS=5

# Dry run mode (set to false to actually move)
DRY_RUN=true

# Overwrite existing destinations
OVERWRITE=false

# Which pairs to process
PROCESS_MOVIES=false
PROCESS_TV=false

# Check for command line parameters
while [ $# -gt 0 ]; do
    case "$1" in
        --execute)
            DRY_RUN=false
            shift
            ;;
        --overwrite)
            OVERWRITE=true
            shift
            ;;
        --num)
            if [ -n "$2" ] && [ "$2" -gt 0 ]; then
                NUM_FOLDERS="$2"
                shift 2
            else
                echo "Error: --num requires a positive integer"
                exit 1
            fi
            ;;
        --movies)
            PROCESS_MOVIES=true
            shift
            ;;
        --tv)
            PROCESS_TV=true
            shift
            ;;
        --movies-src)
            if [ -n "$2" ]; then
                MOVIES_SRC="$2"
                shift 2
            else
                echo "Error: --movies-src requires a path"
                exit 1
            fi
            ;;
        --movies-dst)
            if [ -n "$2" ]; then
                MOVIES_DST="$2"
                shift 2
            else
                echo "Error: --movies-dst requires a path"
                exit 1
            fi
            ;;
        --tv-src)
            if [ -n "$2" ]; then
                TV_SRC="$2"
                shift 2
            else
                echo "Error: --tv-src requires a path"
                exit 1
            fi
            ;;
        --tv-dst)
            if [ -n "$2" ]; then
                TV_DST="$2"
                shift 2
            else
                echo "Error: --tv-dst requires a path"
                exit 1
            fi
            ;;
        --help)
            echo "Usage: $0 [--execute] [--overwrite] [--num <number>] [--movies] [--tv] [--movies-src <path>] [--movies-dst <path>] [--tv-src <path>] [--tv-dst <path>] [--help]"
            echo "Options:"
            echo "  --execute        Actually move the folders (default is dry-run)"
            echo "  --overwrite      Overwrite existing destination folders"
            echo "  --num <n>        Number of folders to process per source (default 5)"
            echo "  --movies         Process movies folders"
            echo "  --tv             Process TV folders"
            echo "  --movies-src <p> Set source path for movies"
            echo "  --movies-dst <p> Set destination path for movies"
            echo "  --tv-src <p>     Set source path for TV"
            echo "  --tv-dst <p>     Set destination path for TV"
            echo "  --help           Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--execute] [--overwrite] [--num <number>] [--movies] [--tv] [--movies-src <path>] [--movies-dst <path>] [--tv-src <path>] [--tv-dst <path>] [--help]"
            exit 1
            ;;
    esac
done

# If no pairs specified, process both
if [ "$PROCESS_MOVIES" = false ] && [ "$PROCESS_TV" = false ]; then
    PROCESS_MOVIES=true
    PROCESS_TV=true
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to clean folder name
clean_name() {
    echo "$1" | sed 's/\[.*$//' | sed 's/ *$//'
}

# Function to process a source-destination pair
process_pair() {
    local src="$1"
    local dst="$2"
    local pair_name="$3"

    echo -e "${BLUE}Processing $pair_name: $src -> $dst${NC}"

    # Get the first NUM_FOLDERS subdirectories and store in array
    local folders_array=()
    while IFS= read -r folder; do
        folders_array+=("$folder")
    done < <($SSH_CMD "ls -d \"$src\"/*/ 2>/dev/null" | head -n $NUM_FOLDERS)

    if [ ${#folders_array[@]} -eq 0 ]; then
        echo -e "${RED}No folders found in $src${NC}"
        return
    fi

    # Process each folder from the stored array
    for folder in "${folders_array[@]}"; do
        if [ -z "$folder" ]; then continue; fi

        # Get basename
        local basename
        basename=$(basename "$folder")

        # Clean the name
        local clean_basename
        clean_basename=$(clean_name "$basename")

        # Construct destination path
        local dest_path="$dst/$clean_basename"

        local changed="false"
        local status="ok"
        if [ "$DRY_RUN" = true ]; then
            changed="false (dry-run)"
        else
            # Check permissions
            local src_readable
            src_readable=$($SSH_CMD "test -r \"$folder\" && echo yes || echo no")
            local src_is_symlink
            src_is_symlink=$($SSH_CMD "test -L \"$folder\" && echo yes || echo no")
            local src_parent
            src_parent=$(dirname "$folder")
            local src_parent_writable
            src_parent_writable=$($SSH_CMD "test -w \"$src_parent\" && echo yes || echo no")
            local dst_writable
            dst_writable=$($SSH_CMD "test -w \"$dst\" && echo yes || echo no")
            local dest_exists
            dest_exists=$($SSH_CMD "test -e \"$dest_path\" && echo yes || echo no")

            if [ "$src_readable" != "yes" ]; then
                status="failed"
                changed="false (source $folder not readable)"
            elif [ "$src_is_symlink" = "yes" ]; then
                status="failed"
                changed="false (source $folder is a symlink)"
            elif [ "$src_parent_writable" != "yes" ]; then
                status="failed"
                changed="false (source parent $src_parent not writable)"
            elif [ "$dst_writable" != "yes" ]; then
                status="failed"
                changed="false (destination $dst not writable)"
            elif [ "$dest_exists" = "yes" ] && [ "$OVERWRITE" = false ]; then
                status="failed"
                changed="false (destination $dest_path already exists)"
            else
                $SSH_CMD "mv \"$folder\" \"$dest_path\""
                if [ $? -eq 0 ]; then
                    changed="true"
                else
                    changed="false"
                    status="failed"
                fi
            fi
        fi

        if [ "$status" = "failed" ]; then
            echo -e "  ${RED}${status}${NC}: [${basename}] => {"
        else
            echo -e "  ${GREEN}${status}${NC}: [${basename}] => {"
        fi
        echo -e "    \"src\": \"$folder\","
        echo -e "    \"dest\": \"$dest_path\","
        echo -e "    \"changed\": $changed"
        echo -e "  }"
    done
}

# Process selected pairs
if [ "$PROCESS_MOVIES" = true ]; then
    process_pair "$MOVIES_SRC" "$MOVIES_DST" "Movies"
fi
if [ "$PROCESS_TV" = true ]; then
    process_pair "$TV_SRC" "$TV_DST" "TV"
fi
