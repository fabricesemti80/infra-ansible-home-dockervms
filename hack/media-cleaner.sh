#!/bin/bash

# Unified Script for QNAP NAS folder operations
# MODE: move - moves folders between directories and cleans names
# MODE: rename - renames folders in-place using custom patterns
# Compatible with macOS
# Defaults to dry-run mode

# TESTING COMMANDS (run these first to verify setup):
#
# 1. Test SSH connection:
#    ssh -i ~/.ssh/fs_home_rsa admin-fabrice@10.0.40.2 "echo 'Connection successful'"
#
# 2. Test folder listing:
#    ssh -i ~/.ssh/fs_home_rsa admin-fabrice@10.0.40.2 "ls -1 /share/Public/media/movies/ | head -5"
#
# 3. Check SSH key permissions:
#    chmod 600 ~/.ssh/fs_home_rsa
#
# 4. Run script in dry-run mode first:
#    ./script.sh --mode rename --movies --num 5

# Configuration
SSH_CMD="ssh -i ~/.ssh/fs_home_rsa admin-fabrice@10.0.40.2"

# Default paths for MOVE mode
DEFAULT_MOVIES_SRC="/share/Public/media/movies"
DEFAULT_MOVIES_DST="/share/Public/docker-compose-data/media/movies"
DEFAULT_TV_SRC="/share/Public/media/tv"
DEFAULT_TV_DST="/share/Public/docker-compose-data/media/tv"

# Default paths for RENAME mode
DEFAULT_MOVIES_PATH="/share/Public/media/movies"
DEFAULT_TV_PATH="/share/Public/media/tv"

# Default settings
MODE=""  # move or rename (required parameter)
NUM_FOLDERS=5
DRY_RUN=true
OVERWRITE=false  # Only used in move mode

# Move mode variables
MOVIES_SRC="$DEFAULT_MOVIES_SRC"
MOVIES_DST="$DEFAULT_MOVIES_DST"
TV_SRC="$DEFAULT_TV_SRC"
TV_DST="$DEFAULT_TV_DST"

# Rename mode variables
MOVIES_PATH="$DEFAULT_MOVIES_PATH"
TV_PATH="$DEFAULT_TV_PATH"
DEFAULT_PATTERN='\[[^]]*\]'  # Matches [anything]
PATTERN="$DEFAULT_PATTERN"

# Which paths/pairs to process
PROCESS_MOVIES=false
PROCESS_TV=false

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --mode)
            if [ -n "$2" ] && { [ "$2" = "move" ] || [ "$2" = "rename" ]; }; then
                MODE="$2"
                shift 2
            else
                echo "Error: --mode requires either 'move' or 'rename'"
                exit 1
            fi
            ;;
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
        --pattern)
            if [ -n "$2" ]; then
                PATTERN="$2"
                shift 2
            else
                echo "Error: --pattern requires a regex pattern"
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
        # Move mode parameters
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
        # Rename mode parameters
        --movies-path)
            if [ -n "$2" ]; then
                MOVIES_PATH="$2"
                shift 2
            else
                echo "Error: --movies-path requires a path"
                exit 1
            fi
            ;;
        --tv-path)
            if [ -n "$2" ]; then
                TV_PATH="$2"
                shift 2
            else
                echo "Error: --tv-path requires a path"
                exit 1
            fi
            ;;
        --help)
            echo "Usage: $0 --mode <move|rename> [OPTIONS]"
            echo ""
            echo "Required:"
            echo "  --mode <mode>        Operation mode: 'move' or 'rename'"
            echo ""
            echo "Common Options:"
            echo "  --execute            Actually perform operations (default is dry-run)"
            echo "  --num <n>            Number of folders to process (default 5)"
            echo "  --movies             Process movies folders/pairs"
            echo "  --tv                 Process TV folders/pairs"
            echo "  --help               Show this help"
            echo ""
            echo "MOVE Mode Options:"
            echo "  --overwrite          Overwrite existing destination folders"
            echo "  --movies-src <path>  Source path for movies (default: $DEFAULT_MOVIES_SRC)"
            echo "  --movies-dst <path>  Destination path for movies (default: $DEFAULT_MOVIES_DST)"
            echo "  --tv-src <path>      Source path for TV (default: $DEFAULT_TV_SRC)"
            echo "  --tv-dst <path>      Destination path for TV (default: $DEFAULT_TV_DST)"
            echo ""
            echo "RENAME Mode Options:"
            echo "  --pattern <regex>    Regex pattern to remove (default: remove [text] brackets)"
            echo "  --movies-path <path> Path for movies (default: $DEFAULT_MOVIES_PATH)"
            echo "  --tv-path <path>     Path for TV (default: $DEFAULT_TV_PATH)"
            echo ""
            echo "Pattern Examples (RENAME mode):"
            echo "  --pattern '\[[^]]*\]'           # Remove [text] (default)"
            echo "  --pattern '(19|20)[0-9][0-9]'   # Remove years like 1999, 2023"
            echo "  --pattern 'DVDRip\|BluRay'      # Remove DVDRip or BluRay"
            echo "  --pattern '\..*\$'              # Remove file extensions"
            echo "  --pattern '^The '               # Remove 'The ' at start"
            echo ""
            echo "Usage Examples:"
            echo "  # MOVE mode - dry run"
            echo "  $0 --mode move --movies --num 3"
            echo ""
            echo "  # MOVE mode - execute"
            echo "  $0 --mode move --execute --movies --tv --overwrite"
            echo ""
            echo "  # RENAME mode - remove brackets"
            echo "  $0 --mode rename --execute --movies --pattern '\[[^]]*\]'"
            echo ""
            echo "  # RENAME mode - remove years"
            echo "  $0 --mode rename --execute --tv --pattern '(19|20)[0-9][0-9]' --num 10"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$MODE" ]; then
    echo "Error: --mode is required. Use 'move' or 'rename'"
    echo "Use --help for usage information"
    exit 1
fi

# If no paths/pairs specified, process both
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

# Function to clean folder name for MOVE mode (removes [text] patterns and cleans up)
clean_name_move() {
    # Remove [text] patterns, then clean up whitespace and punctuation
    echo "$1" | \
    sed 's/\[[^]]*\]//g' | \
    sed 's/[[:space:]]\+/ /g' | \
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
    sed 's/^[.[:space:]]*//; s/[.[:space:]]*$//'
}

# Function to clean folder name for RENAME mode (removes custom pattern and cleans up)
clean_name_rename() {
    local original="$1"
    local cleaned

    # Remove custom pattern, then clean up whitespace and punctuation
    cleaned=$(echo "$original" | \
    sed "s/$PATTERN//g" | \
    sed 's/[[:space:]]\+/ /g' | \
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
    sed 's/^[.[:space:]]*//; s/[.[:space:]]*$//')

    # If result is empty or only whitespace, keep original name
    if [ -z "$cleaned" ] || [ "$(echo "$cleaned" | sed 's/[[:space:]]//g')" = "" ]; then
        echo "$original"
    else
        echo "$cleaned"
    fi
}

# Function for MOVE mode - process a source-destination pair
move_folders() {
    local src="$1"
    local dst="$2"
    local pair_name="$3"

    echo -e "${BLUE}MOVE Mode - Processing $pair_name: $src -> $dst${NC}"

    # Get the first NUM_FOLDERS subdirectories
    local folders_array=()
    while IFS= read -r folder; do
        folders_array+=("$folder")
    done < <($SSH_CMD "find \"$src\" -mindepth 1 -maxdepth 1 -type d | head -n $NUM_FOLDERS")

    if [ ${#folders_array[@]} -eq 0 ]; then
        echo -e "${RED}No folders found in $src${NC}"
        return
    fi

    echo -e "${GREEN}Found ${#folders_array[@]} folders to process${NC}"
    echo ""

    # Process each folder
    for folder in "${folders_array[@]}"; do
        if [ -z "$folder" ]; then continue; fi

        local basename
        basename=$(basename "$folder")
        local clean_basename
        clean_basename=$(clean_name_move "$basename")
        local dest_path="$dst/$clean_basename"

        local changed="false"
        local status="ok"

        if [ "$DRY_RUN" = true ]; then
            local folder_size
            folder_size=$($SSH_CMD "du -h -s \"$folder\" 2>/dev/null | awk '{print \$1}'" 2>/dev/null || echo "unknown")
            echo -e "${YELLOW}  Folder size: $folder_size${NC}"
            changed="false (dry-run)"
        else
            local folder_size
            folder_size=$($SSH_CMD "du -h -s \"$folder\" 2>/dev/null | awk '{print \$1}'" 2>/dev/null || echo "unknown")
            echo -e "${YELLOW}  Moving folder of size: $folder_size${NC}"

            # Check conditions
            local dest_exists
            dest_exists=$($SSH_CMD "test -e \"$dest_path\" && echo yes || echo no")

            if [ "$dest_exists" = "yes" ] && [ "$OVERWRITE" = false ]; then
                status="failed"
                changed="false (destination exists, use --overwrite)"
            else
                $SSH_CMD "mkdir -p \"$dst\""
                echo -e "${YELLOW}  Executing: mv \"$folder\" \"$dest_path\"${NC}"
                $SSH_CMD "mv \"$folder\" \"$dest_path\""

                if [ $? -eq 0 ]; then
                    changed="true"
                    local dest_size
                    dest_size=$($SSH_CMD "du -h -s \"$dest_path\" 2>/dev/null | awk '{print \$1}'" 2>/dev/null || echo "unknown")
                    echo -e "${GREEN}  Destination size: $dest_size${NC}"
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
        echo ""
    done
}

# Function for RENAME mode - process folders in a path
rename_folders() {
    local path="$1"
    local path_name="$2"

    echo -e "${BLUE}RENAME Mode - Processing $path_name: $path${NC}"
    echo -e "${BLUE}Looking for folders matching pattern: $PATTERN${NC}"

    # Get folders that match the pattern
    local folders_array=()
    while IFS= read -r folder; do
        if [[ -n "$folder" ]]; then
            local basename
            basename=$(basename "$folder")
            if echo "$basename" | grep -q "$PATTERN"; then
                folders_array+=("$folder")
            fi
        fi
    done < <($SSH_CMD "find \"$path\" -mindepth 1 -maxdepth 1 -type d | head -n $((NUM_FOLDERS * 3))")

    # Take only the first NUM_FOLDERS matches
    if [ ${#folders_array[@]} -gt $NUM_FOLDERS ]; then
        folders_array=("${folders_array[@]:0:$NUM_FOLDERS}")
    fi

    if [ ${#folders_array[@]} -eq 0 ]; then
        echo -e "${YELLOW}No folders matching pattern '$PATTERN' found in $path${NC}"
        return
    fi

    echo -e "${GREEN}Found ${#folders_array[@]} folders matching pattern to process${NC}"
    echo ""

    # Process each folder
    for folder in "${folders_array[@]}"; do
        if [ -z "$folder" ]; then continue; fi

        local basename
        basename=$(basename "$folder")
        local clean_basename
        clean_basename=$(clean_name_rename "$basename")

        # Skip if name wouldn't change or would result in empty/invalid name
        if [ "$basename" = "$clean_basename" ]; then
            echo -e "${YELLOW}Skipping: [$basename] (no change needed or would result in empty name)${NC}"
            continue
        fi

        # Additional safety check for empty names after cleaning
        if [ -z "$clean_basename" ] || [ "$(echo "$clean_basename" | sed 's/[[:space:]]//g')" = "" ]; then
            echo -e "${YELLOW}Skipping: [$basename] (would result in empty name)${NC}"
            continue
        fi

        local parent_path
        parent_path=$(dirname "$folder")
        local new_path="$parent_path/$clean_basename"

        local changed="false"
        local status="ok"

        if [ "$DRY_RUN" = true ]; then
            changed="false (dry-run)"
            status="would rename"
        else
            local dest_exists
            dest_exists=$($SSH_CMD "test -e \"$new_path\" && echo yes || echo no")

            if [ "$dest_exists" = "yes" ]; then
                if [ "$OVERWRITE" = true ]; then
                    echo -e "${YELLOW}  Removing existing destination: $new_path${NC}"
                    $SSH_CMD "rm -rf \"$new_path\""
                    dest_exists="no"
                else
                    status="failed"
                    changed="false (destination already exists)"
                fi
            fi

            if [ "$dest_exists" = "no" ]; then
                echo -e "${YELLOW}  Executing: mv \"$folder\" \"$new_path\"${NC}"
                $SSH_CMD "mv \"$folder\" \"$new_path\""

                if [ $? -eq 0 ]; then
                    changed="true"
                    status="renamed"
                else
                    changed="false"
                    status="failed"
                fi
            fi
        fi

        if [[ "$status" == "failed" ]]; then
            echo -e "  ${RED}${status}${NC}: "
        elif [[ "$status" == "renamed" ]]; then
            echo -e "  ${GREEN}${status}${NC}: "
        else
            echo -e "  ${YELLOW}${status}${NC}: "
        fi

        echo -e "    Old: \"$basename\""
        echo -e "    New: \"$clean_basename\""
        echo -e "    Changed: $changed"
        echo ""
    done
}

# Show operation summary
echo -e "${BLUE}=== NAS Folder Operations Script ===${NC}"
echo -e "${BLUE}Mode: $MODE${NC}"
if [ "$MODE" = "rename" ]; then
    echo -e "${BLUE}Pattern: $PATTERN${NC}"
fi
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}=== DRY RUN MODE - No changes will be made ===${NC}"
else
    echo -e "${RED}=== EXECUTE MODE - Operations will be performed ===${NC}"
fi
echo -e "${BLUE}Processing up to $NUM_FOLDERS folders per path/pair${NC}"
echo ""

# Execute based on mode
if [ "$MODE" = "move" ]; then
    if [ "$PROCESS_MOVIES" = true ]; then
        move_folders "$MOVIES_SRC" "$MOVIES_DST" "Movies"
    fi
    if [ "$PROCESS_TV" = true ]; then
        move_folders "$TV_SRC" "$TV_DST" "TV Shows"
    fi
elif [ "$MODE" = "rename" ]; then
    if [ "$PROCESS_MOVIES" = true ]; then
        rename_folders "$MOVIES_PATH" "Movies"
    fi
    if [ "$PROCESS_TV" = true ]; then
        rename_folders "$TV_PATH" "TV Shows"
    fi
fi

echo -e "${BLUE}=== Processing Complete ===${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}Run with --execute to actually perform the operations${NC}"
fi