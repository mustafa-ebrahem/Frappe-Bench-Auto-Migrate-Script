# Frappe Bench Repository Update Tool

A utility script that automatically checks and updates all custom apps in your Frappe Bench installation.

## Overview

`auto_migrate.sh` is designed to simplify the process of keeping your custom Frappe/ERPNext apps up to date. The script:

- Checks all apps in your bench's `apps` directory
- Pulls the latest changes from their respective git repositories
- Optionally runs migration commands when updates are detected
- Provides clear visual feedback about the update process

## Features

- ✅ Automatic detection of git repositories
- ✅ Configurable remote selection (tries origin, dev, upstream by default)
- ✅ Configurable app exclusions
- ✅ Branch management with optional force switching
- ✅ Detailed update reporting
- ✅ Automatic migrations (optional)
- ✅ Color-coded terminal output for better readability
- ✅ Configurable verbosity

## Requirements

- Bash shell
- Git
- Frappe Bench environment

## Installation

1. Download the script to your bench directory:
   ```bash
   cd /path/to/your/bench
   curl -o auto_migrate.sh https://raw.githubusercontent.com/mustafa-ebrahem/Frappe-Bench-Auto-Migrate-Script/master/auto_pull_migrate_apps.sh
   ```

   Or you can download it directly from the GitHub repository:
   ```bash
   cd /path/to/your/bench
   wget -O auto_migrate.sh https://raw.githubusercontent.com/mustafa-ebrahem/Frappe-Bench-Auto-Migrate-Script/master/auto_pull_migrate_apps.sh
   ```

2. Make the script executable:
   ```bash
   chmod +x auto_migrate.sh
   ```

## Usage

Simply run the script from your bench directory:

```bash
./auto_migrate.sh
```

## Configuration

You can customize the script by editing these variables at the top:

```bash
# Command to execute if changes are pulled
# comment out to pull changes only
COMMAND_TO_RUN="bench migrate"

# Default branch to use
DEFAULT_BRANCH="master"

# List of remote names to try (in order of preference)
REMOTE_NAMES=(
  "origin"
  "dev"
  "upstream"
)

# List of apps to exclude (case-sensitive)
EXCLUDED_APPS=(
  "erpnext"
  "frappe"
)

# Whether to force checkout to DEFAULT_BRANCH (1 = yes, 0 = no)
FORCE_BRANCH_SWITCH=1

# Whether to show detailed git output (1 = yes, 0 = no)
SHOW_VERBOSE_GIT_OUTPUT=0
```

### Options:

- `COMMAND_TO_RUN`: The command to execute after pulling changes (set to empty to disable)
- `DEFAULT_BRANCH`: The git branch to pull from (usually 'master' or 'main')
- `REMOTE_NAMES`: List of remote repository names to check, in order of preference
- `EXCLUDED_APPS`: Array of app names to skip during the update process
- `FORCE_BRANCH_SWITCH`: Whether to force switching to the default branch (1=yes, 0=no)
- `SHOW_VERBOSE_GIT_OUTPUT`: Show detailed git output while running commands (1=yes, 0=no)

## Recommendations

1. **Core Apps**: By default, 'frappe' and 'erpnext' are excluded as they typically require more careful updating.
2. **Scheduling**: Consider adding this script to your crontab for automatic updates.
3. **Custom Commands**: You can modify the `COMMAND_TO_RUN` to perform additional tasks like rebuilding assets:
   ```
   COMMAND_TO_RUN="bench migrate && bench build"
   ```
4. **Remote Configuration**: Customize the `REMOTE_NAMES` array if your repositories use different remote names.
5. **Branch Management**: Set `FORCE_BRANCH_SWITCH=0` if you want to skip repos that aren't on the default branch.

## Notes

- The script will only update apps in the specified default branch.
- If an app is on a different branch, the script will attempt to switch to the default branch (if `FORCE_BRANCH_SWITCH=1`).
- Apps without a valid remote repository are skipped.
- Verbose git output can be enabled for troubleshooting purposes.
