#!/bin/bash

# auto_pull_migrate_apps.sh - Frappe Bench Repository Update Tool
# ---------------------------------------------------------
# Place this file in the root of your bench directory
# Run with: ./auto_pull_migrate_apps.sh

# Get the current directory (should be bench root)
BENCH_DIR="$(pwd)"
PARENT_DIR="apps"

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

# Flag to track if any repositories were updated
CHANGES_DETECTED=0

# Terminal colors and formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Separator line
separator() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to check if an app is in the excluded list
is_excluded() {
  local app_name="$1"
  for excluded in "${EXCLUDED_APPS[@]}"; do
    if [ "$app_name" == "$excluded" ]; then
      return 0  # True, app is excluded
    fi
  done
  return 1  # False, app is not excluded
}

echo -e "${BOLD}${GREEN}Starting repository update check...${NC}"
separator
echo -e "Bench directory: ${BOLD}$BENCH_DIR${NC}"
echo -e "Scanning subdirectories in: ${BOLD}$PARENT_DIR${NC}"

# Print excluded apps if any
if [ ${#EXCLUDED_APPS[@]} -gt 0 ]; then
  echo -e "Excluding apps: ${YELLOW}${EXCLUDED_APPS[*]}${NC}"
fi

separator

# Check if parent directory exists
if [ ! -d "$PARENT_DIR" ]; then
  echo -e "${RED}Error: Parent directory $PARENT_DIR does not exist.${NC}"
  echo -e "Make sure you're running this script from the bench root directory."
  exit 1
fi

# Iterate through each subdirectory in the parent directory
for dir in "$PARENT_DIR"/*; do
  # Check if it's a directory and contains a .git folder
  if [ -d "$dir" ] && [ -d "$dir/.git" ]; then
    REPO_NAME=$(basename "$dir")
    
    # Skip excluded apps
    if is_excluded "$REPO_NAME"; then
      echo -e "\n${BOLD}Repository:${NC} $REPO_NAME"
      echo -e "${YELLOW}⚡ Skipping${NC} (excluded in configuration)"
      continue
    fi
    
    echo -e "\n${BOLD}Repository:${NC} $REPO_NAME"
    separator
    
    # Save current directory
    CURRENT_DIR="$(pwd)"
    
    # Navigate to the directory
    cd "$dir" || continue
    
    # Check if the repo has a remote from our configured list
    REMOTE=""
    for remote_name in "${REMOTE_NAMES[@]}"; do
      if git remote | grep -q "$remote_name"; then
        REMOTE="$remote_name"
        break
      fi
    done
    
    if [ -z "$REMOTE" ]; then
      echo -e "${YELLOW}⚠️  Warning:${NC} No suitable remote found in $REPO_NAME. Skipping."
      cd "$CURRENT_DIR"
      continue
    fi
    
    echo -e "• Remote: ${BLUE}$REMOTE${NC}"
    
    # Get current branch
    CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
    echo -e "• Current branch: ${BLUE}$CURRENT_BRANCH${NC}"
    
    # Check if we're already on default branch and switch if needed and allowed
    if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
      if [ $FORCE_BRANCH_SWITCH -eq 1 ]; then
        echo -e "• Switching from ${YELLOW}$CURRENT_BRANCH${NC} to ${GREEN}$DEFAULT_BRANCH${NC} branch"
        git checkout $DEFAULT_BRANCH
        if [ $? -ne 0 ]; then
          echo -e "${RED}❌ Error:${NC} Failed to switch to $DEFAULT_BRANCH branch in $REPO_NAME"
          cd "$CURRENT_DIR"
          continue
        fi
      else
        echo -e "${YELLOW}⚠️  Warning:${NC} Repository on $CURRENT_BRANCH branch (not $DEFAULT_BRANCH). Skipping."
        cd "$CURRENT_DIR"
        continue
      fi
    fi
    
    # Fetch from remote to check for changes
    echo -e "• Fetching from remote..."
    if [ $SHOW_VERBOSE_GIT_OUTPUT -eq 1 ]; then
      git fetch $REMOTE
    else
      git fetch $REMOTE > /dev/null 2>&1
    fi
    
    # Get the current commit hash before pulling
    BEFORE_PULL=$(git rev-parse HEAD)
    REMOTE_HASH=$(git rev-parse $REMOTE/$DEFAULT_BRANCH 2>/dev/null)
    
    # Check if remote exists and has changes
    if [ -z "$REMOTE_HASH" ]; then
      echo -e "${YELLOW}⚠️  Warning:${NC} Remote branch '$REMOTE/$DEFAULT_BRANCH' not found in $REPO_NAME. Skipping."
      cd "$CURRENT_DIR"
      continue
    fi
    
    if [ "$BEFORE_PULL" = "$REMOTE_HASH" ]; then
      echo -e "• Status: ${GREEN}✓ Up to date${NC} (no changes to pull)"
      cd "$CURRENT_DIR"
      continue
    fi
    
    # Pull the latest changes
    echo -e "• Pulling latest changes from $DEFAULT_BRANCH..."
    if [ $SHOW_VERBOSE_GIT_OUTPUT -eq 1 ]; then
      git pull $REMOTE $DEFAULT_BRANCH
      PULL_STATUS=$?
    else
      PULL_OUTPUT=$(git pull $REMOTE $DEFAULT_BRANCH 2>&1)
      PULL_STATUS=$?
    fi
    
    # Check if pull was successful
    if [ $PULL_STATUS -ne 0 ]; then
      echo -e "${RED}❌ Error:${NC} Git pull failed in $REPO_NAME"
      if [ $SHOW_VERBOSE_GIT_OUTPUT -ne 1 ]; then
        echo -e "$PULL_OUTPUT" | sed 's/^/  /'
      fi
      cd "$CURRENT_DIR"
      continue
    fi
    
    # Get the commit hash after pulling
    AFTER_PULL=$(git rev-parse HEAD)
    
    # Check if there were any changes
    if [ "$BEFORE_PULL" != "$AFTER_PULL" ]; then
      echo -e "• Status: ${YELLOW}⟳ Updated${NC} (changes pulled)"
      CHANGES_DETECTED=1
      
      # Get summary of changes
      COMMIT_COUNT=$(git log --oneline $BEFORE_PULL..$AFTER_PULL | wc -l)
      echo -e "• Pull summary: ${BOLD}$COMMIT_COUNT${NC} new commit(s)"
    else
      echo -e "• Status: ${GREEN}✓ No changes${NC}"
    fi
    
    # Return to the parent directory
    cd "$CURRENT_DIR"
  fi
done

separator
# Execute the command if changes were detected
if [ $CHANGES_DETECTED -eq 1 ] && [ -n "$COMMAND_TO_RUN" ]; then
  echo -e "\n${YELLOW}⟳ Changes detected${NC} in at least one repository"
  echo -e "Running command: ${BOLD}$COMMAND_TO_RUN${NC}"
  cd "$BENCH_DIR"
  eval "$COMMAND_TO_RUN"
else
  if [ $CHANGES_DETECTED -eq 1 ]; then
    echo -e "\n${YELLOW}⟳ Changes detected${NC} in at least one repository (no command configured)"
  else
    echo -e "\n${GREEN}✓ No changes detected${NC} in any repository"
  fi
fi

separator
echo -e "${BOLD}${GREEN}Update check completed!${NC}"
