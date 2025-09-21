# NAS Media Folder Operations Scripts

This directory contains scripts for managing media folders on a QNAP NAS.

## Scripts

### `media-cleaner.sh`

A script to move folders from source directories to destination directories on the QNAP NAS, with automatic name cleaning.

**Features:**
- Moves folders between configured source/destination pairs
- Removes bracketed patterns (e.g., `[2009]DvDrip-aXXo`) from folder names
- Supports dry-run mode for safe testing
- Checks permissions and prevents overwriting by default
- Can process movies and/or TV folders selectively
- Customizable source/destination paths via command-line options

**Usage:**
```bash
./media-cleaner.sh [options]
```

**Options:**
- `--execute`: Actually perform moves (default is dry-run)
- `--overwrite`: Allow overwriting existing destination folders
- `--num <n>`: Number of folders to process per source (default 5)
- `--movies`: Process movies folders
- `--tv`: Process TV folders
- `--movies-src <path>`: Override default movies source path
- `--movies-dst <path>`: Override default movies destination path
- `--tv-src <path>`: Override default TV source path
- `--tv-dst <path>`: Override default TV destination path
- `--help`: Show detailed help

**Examples:**
```bash
# Dry run movies (default)
./media-cleaner.sh --movies

# Execute move for both movies and TV
./media-cleaner.sh --execute --movies --tv --overwrite --num 10

# Custom paths
./media-cleaner.sh --execute --movies --movies-src /custom/src --movies-dst /custom/dst
```

### `media-cleaner.sh`

A unified script for QNAP NAS folder operations with two modes: **move** and **rename**.

**Features:**
- **Move Mode**: Moves folders between directories with name cleaning
- **Rename Mode**: Renames folders in-place using custom regex patterns
- Compatible with macOS
- Dry-run mode for safe testing
- Size reporting for moved folders
- Pattern-based renaming with examples
- Selective processing of movies/TV folders

**Usage:**
```bash
./media-cleaner.sh --mode <move|rename> [options]
```

**Common Options:**
- `--mode <move|rename>`: Required operation mode
- `--execute`: Actually perform operations (default dry-run)
- `--num <n>`: Number of folders to process (default 5)
- `--movies`: Process movies folders
- `--tv`: Process TV folders
- `--help`: Show detailed help

**Move Mode Options:**
- `--overwrite`: Overwrite existing destination folders
- `--movies-src <path>`: Source path for movies
- `--movies-dst <path>`: Destination path for movies
- `--tv-src <path>`: Source path for TV
- `--tv-dst <path>`: Destination path for TV

**Rename Mode Options:**
- `--pattern <regex>`: Regex pattern to remove from names
- `--movies-path <path>`: Path for movies
- `--tv-path <path>`: Path for TV

**Pattern Examples (Rename Mode):**
- `\[[^]]*\]`: Remove `[text]` brackets (default)
- `(19|20)[0-9][0-9]`: Remove years like 1999, 2023
- `DVDRip\|BluRay`: Remove DVDRip or BluRay
- `\..*$`: Remove file extensions
- `^The `: Remove 'The ' at start

**Examples:**
```bash
# Move mode dry run
./media-cleaner.sh --mode move --movies --num 3

# Move mode execute
./media-cleaner.sh --mode move --execute --movies --tv --overwrite

# Rename mode - remove brackets
./media-cleaner.sh --mode rename --execute --movies --pattern '\[[^]]*\]'

# Rename mode - remove years
./media-cleaner.sh --mode rename --execute --tv --pattern '(19|20)[0-9][0-9]' --num 10
```

## Setup Requirements

1. SSH key configured for passwordless access to QNAP NAS
2. SSH key file: `~/.ssh/fs_home_rsa`
3. SSH user: `admin-fabrice@10.0.40.2`

## Testing Commands

Before running scripts, test the setup:

```bash
# Test SSH connection
ssh -i ~/.ssh/fs_home_rsa admin-fabrice@10.0.40.2 "echo 'Connection successful'"

# Test folder listing
ssh -i ~/.ssh/fs_home_rsa admin-fabrice@10.0.40.2 "ls -1 /share/Public/media/movies/ | head -5"

# Check SSH key permissions
chmod 600 ~/.ssh/fs_home_rsa
```

## Safety Notes

- Always run in dry-run mode first (`--execute` not specified)
- Scripts check permissions and skip operations that would fail
- Symlinks are skipped to prevent broken references
- Use `--overwrite` carefully to avoid data loss
- Scripts provide detailed output showing what would be done

## Troubleshooting

- **Empty folders after move**: Check if source folders are symlinks (scripts skip symlinks)
- **Permission errors**: Ensure SSH user has read/write access to source/destination paths
- **SSH connection issues**: Verify SSH key and NAS accessibility
- **No folders found**: Check source paths exist and contain subdirectories
