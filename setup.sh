

#!/bin/bash

# ANSI color codes
LIGHT_BLUE='\e[1;34m'
RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\e[0m' # No Color

# Detect distro and set package manager
if command -v pacman &> /dev/null; then
  PKG_MANAGER="pacman -Syu --noconfirm"
  DISTRO="Arch-based (pacman)"
elif command -v dnf &> /dev/null; then
  PKG_MANAGER="dnf install -y"
  DISTRO="Fedora/CentOS (dnf)"
elif command -v zypper &> /dev/null; then
  PKG_MANAGER="zypper install -y"
  DISTRO="openSUSE (zypper)"
elif command -v apt-get &> /dev/null; then
  PKG_MANAGER="apt-get install -y"
  DISTRO="Debian/Ubuntu (apt-get)"
elif command -v yum &> /dev/null; then
  PKG_MANAGER="yum install -y"
  DISTRO="Older Fedora/CentOS (yum)"
elif command -v apk &> /dev/null; then
  PKG_MANAGER="apk add --no-cache"
  DISTRO="Alpine (apk)"
else
  PKG_MANAGER="" # No default detected
  DISTRO="Unknown"
fi

# Prompt for package manager if auto-detection fails.
if [[ -z "$PKG_MANAGER" ]]; then
  log_and_print "$RED" "No default package manager detected."
  read -p "Enter package manager (pacman, dnf, zypper, apt-get, yum, apk): " CUSTOM_PKG_MANAGER

  case "$CUSTOM_PKG_MANAGER" in
    pacman) PKG_MANAGER="pacman -Syu --noconfirm";;
    dnf) PKG_MANAGER="dnf install -y";;
    zypper) PKG_MANAGER="zypper install -y";;
    apt-get) PKG_MANAGER="apt-get install -y";;
    yum) PKG_MANAGER="yum install -y";;
    apk) PKG_MANAGER="apk add --no-cache";;
    *) log_and_print "$RED" "Invalid package manager. Defaulting to apt-get"; PKG_MANAGER="apt-get install -y";;
  esac
  log_and_print "$NC" "Using package manager: $PKG_MANAGER"
fi
# Log file
LOG_FILE="setup.log"

# Function to log and print with color
log_and_print() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${NC}"
  echo "$message" >> "$LOG_FILE"
}

# Function to display a progress indicator (flashing dots)
show_progress() {
  local count=0
  while [[ $installing -eq 1 ]]; do
    printf "."
    sleep 0.5
    count=$((count + 1))
    if [[ $count -gt 3 ]]; then
      printf "\r   \r" # Clear dots
      count=0
    fi
  done
  printf "\n" # Newline after progress
}

# Clear log file
> "$LOG_FILE"

log_and_print "$LIGHT_BLUE" "Starting Pickles Weather setup..."
log_and_print "$NC" "----------------------------------------"

# 1. Check required files
log_and_print "$LIGHT_BLUE" "Checking required files..."
REQUIRED_FILES=("conky.png" "LICENSE.txt" "pickles-weather.examples.conky.conf" "README.md" "settings.lua" "weather.lua")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    MISSING_FILES+=("$file")
  fi
done

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
  log_and_print "$RED" "Error: Missing required files: ${MISSING_FILES[*]}"
  exit 1
else
  log_and_print "$GREEN" "All required files found."
fi

log_and_print "$NC" "----------------------------------------"

# 2. Check Conky installation and features
log_and_print "$LIGHT_BLUE" "Checking Conky installation..."

if ! command -v conky &> /dev/null; then
  log_and_print "$RED" "Conky is not installed. Installing..."
  installing=1 # Initialize installing variable
  show_progress &
  PROGRESS_PID=$! # Capture PID of background process
  sudo $PKG_MANAGER conky &> /dev/null
  installing=0 # Reset installing variable
  kill $PROGRESS_PID # Kill background process
  if [[ $? -ne 0 ]]; then
    log_and_print "$RED" "Error: Failed to install Conky."
    exit 1
  else
    log_and_print "$GREEN" "Conky installed successfully."
  fi
else
  log_and_print "$GREEN" "Conky is already installed."
fi

CONKY_VERSION=$(conky -v 2>&1)

if ! echo "$CONKY_VERSION" | grep -qi "curl"; then
  log_and_print "$RED" "Error: Conky does not have curl support."
  exit 1
elif ! echo "$CONKY_VERSION" | grep -qi "lua"; then
  log_and_print "$RED" "Error: Conky does not have lua support."
  exit 1
elif ! echo "$CONKY_VERSION" | grep -qi "cairo"; then
  log_and_print "$RED" "Error: Conky does not have cairo support."
  exit 1
else
  log_and_print "$GREEN" "Conky has curl, lua, and cairo support."
fi

log_and_print "$NC" "----------------------------------------"

# 3. Check Lua libraries
log_and_print "$LIGHT_BLUE" "Checking Lua libraries..."

if ! command -v luarocks &> /dev/null; then
  log_and_print "$RED" "LuaRocks is not installed. Installing..."
  installing=1 # Initialize installing variable
  show_progress &
  PROGRESS_PID=$! # Capture PID of background process
  sudo $PKG_MANAGER luarocks &> /dev/null
  installing=0 # Reset installing variable
  kill $PROGRESS_PID # Kill background process
  if [[ $? -ne 0 ]]; then
    log_and_print "$RED" "Error: Failed to install LuaRocks."
    exit 1
  else
    log_and_print "$GREEN" "LuaRocks installed successfully."
  fi
else
  log_and_print "$GREEN" "LuaRocks is already installed."
fi

#Check for lua socket
if ! luarocks list | grep -q "socket"; then
    log_and_print "$RED" "lua socket is not installed. Installing..."
    installing=1 # Initialize installing variable
    show_progress &
    PROGRESS_PID=$! # Capture PID of background process
    sudo luarocks install socket &> /dev/null
    installing=0 # Reset installing variable
    kill $PROGRESS_PID # Kill background process
    if [[ $? -ne 0 ]]; then
      log_and_print "$RED" "Error: Failed to install lua socket."
      exit 1
    else
        log_and_print "$GREEN" "lua socket installed via luarocks."
    fi
else
    log_and_print "$GREEN" "lua socket is already installed via luarocks."
fi

#check for dkjson
if ! luarocks list | grep -q "dkjson"; then
  log_and_print "$RED" "dkjson is not installed. Installing..."
  installing=1 # Initialize installing variable
  show_progress &
  PROGRESS_PID=$! # Capture PID of background process
  sudo luarocks install dkjson &> /dev/null
  installing=0 # Reset installing variable
  kill $PROGRESS_PID # Kill background process
  if [[ $? -ne 0 ]]; then
    log_and_print "$RED" "Error: Failed to install dkjson."
    exit 1
  else
    log_and_print "$GREEN" "dkjson installed via LuaRocks."
  fi
else
  log_and_print "$GREEN" "dkjson is already installed."
fi

log_and_print "$NC" "----------------------------------------"

# 4. Modify settings.lua
log_and_print "$LIGHT_BLUE" "Modifying settings.lua..."

SCRIPT_DIR=$(pwd)
JSON_PATH="$SCRIPT_DIR/weather.json"
ICON_PATH="$SCRIPT_DIR/icons/"

sed -i "s|save_loc = \".*\"|save_loc = \"$JSON_PATH\"|" settings.lua
sed -i "s|icon_path = \".*\"|icon_path = \"$ICON_PATH\"|" settings.lua

log_and_print "$GREEN" "settings.lua modified."

log_and_print "$NC" "----------------------------------------"

# 5. Modify pickles-weather.examples.conky.conf
log_and_print "$LIGHT_BLUE" "Modifying pickles-weather.examples.conky.conf..."

WEATHER_LUA_PATH="$SCRIPT_DIR/weather.lua"

sed -i "s|lua_load = '.*'|lua_load = '$WEATHER_LUA_PATH'|" pickles-weather.examples.conky.conf

log_and_print "$GREEN" "pickles-weather.examples.conky.conf modified."

log_and_print "$NC" "----------------------------------------"
# Section to remove .git folder in pickles-weather
read -p "Do you want to remove the .git folder, and just keep needed files? (y/n): " REMOVE_GIT

if [[ "$REMOVE_GIT" == "y" || "$REMOVE_GIT" == "Y" ]]; then
  if [[ -d ".git" ]]; then # Corrected path
    log_and_print "$LIGHT_BLUE" "Removing .git folder..."
    rm -rf ".git" # Corrected path
    if [[ $? -eq 0 ]]; then
      log_and_print "$GREEN" ".git folder removed successfully."
    else
      log_and_print "$RED" "Failed to remove .git folder."
    fi
  else
    log_and_print "$NC" ".git folder not found."
  fi
else
  log_and_print "$NC" ".git folder removal skipped."
fi

log_and_print "$NC" "----------------------------------------"
# 6. Run Conky
read -p "Do you want to run Conky with pickles-weather.examples.conky.conf? (y/n): " RUN_CONKY

if [[ "$RUN_CONKY" == "y" || "$RUN_CONKY" == "Y" ]]; then
  log_and_print "$LIGHT_BLUE" "Running Conky in background..."

  # Kill any existing Conky processes
  killall conky &> /dev/null

  # Start Conky in background
  conky -d -c "$SCRIPT_DIR/pickles-weather.examples.conky.conf" &> /dev/null &

  # Wait for Conky to start (5 seconds)
  sleep 5
fi
clear
log_and_print "$NC" "----------------------------------------"
log_and_print "$GREEN" "Setup complete. Output saved to $(pwd)/$LOG_FILE"
echo ""
echo ""
##Instructions to add to your own conky
LOG_FILE="add.to.conky"
# Clear log file
> "$LOG_FILE"
log_and_print "$LIGHT_BLUE" "----------------------------------------"
log_and_print "$GREEN" "------------Pickles Weather-------------"
log_and_print "$LIGHT_BLUE" "----------------------------------------"
log_and_print "$NC" "To add to your own conky.conf"
log_and_print "$NC" "in the conky.config area add the line"
log_and_print "$NC" "lua_load = '$WEATHER_LUA_PATH',"
log_and_print "$NC" "----------------------------------------"
log_and_print "$NC" "in your text section you can add"
log_and_print "$NC" "\${lua conky_temperature} -- Adds the current temperature ie 23.1" # Escaped $
log_and_print "$NC" "\${lua conky_min} -- Adds today's min temperature" # Escaped $
log_and_print "$NC" "\${lua conky_max} -- Adds today's max temperature" # Escaped $
log_and_print "$NC" "\${lua conky_description} -- Adds a description of the current weather, ie cloudy, sunny" # Escaped $
log_and_print "$NC" "\${lua_parse conky_image p=X,Y} -- Adds an icon image from " # Escaped $
log_and_print "$NC" "/pickles-weather/icons/ to suit the current conditions eg:"
log_and_print "$NC" "\${lua_parse conky_image p=215,215} sends \${image} tag back to conky with the icon at position 215,215" # Escaped $
log_and_print "$NC" "----------------------------------------"
log_and_print "$LIGHT_BLUE" "Thanks For Using Pickles Weather"
log_and_print "$GREEN" "Conky add to conky complete. Output saved to $(pwd)/$LOG_FILE"