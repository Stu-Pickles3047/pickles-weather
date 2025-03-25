#!/bin/bash

clear
echo "Setting up " && echo "Pickles Weather"
# Lua script path (relative to the script's directory)
lua_script="$(pwd)/weather.lua"

# Conky configuration file path (relative to the script's directory)
conky_config="$(pwd)/pickles-weather.examples.conky.conf"

# Function to check if a command is available and install if missing
check_command() {
  if command -v "$1" &> /dev/null; then
    echo "Found $1"
    return 0
  else
    echo "" && echo ""
    echo "Installing $1..."
    if [[ "$(id -u)" -eq 0 ]]; then # Check if root
      if command -v paru &> /dev/null; then
        paru -S --noconfirm "$1"
      elif command -v apt &> /dev/null; then
        apt-get update && apt-get install -y "$1"
      else
        echo "Error: paru or apt not found. Please install $1 manually."
        return 1
      fi
    else
      if command -v paru &> /dev/null; then
        sudo paru -S --noconfirm "$1"
      elif command -v apt &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y "$1"
      else
        echo "Error: paru or apt not found. Please run this script as root or install $1 manually."
        return 1
      fi
    fi
    if command -v "$1" &> /dev/null; then
      echo "$1 installed successfully."
      return 0
    else
      echo "Error: Failed to install $1."
      return 1
    fi
  fi
}

# Function to check if a Lua module is available and install if missing
check_lua_module() {
  lua -e "require('$1')" &> /dev/null
  if [ $? -eq 0 ]; then
    echo "Found Lua module: $1"
    return 0
  else
    echo "Installing Lua module: $1..."
    if [[ "$(id -u)" -eq 0 ]]; then # Check if root
      luarocks install "$1"
    else
      sudo luarocks install "$1"
    fi
    lua -e "require('$1')" &> /dev/null
    if [ $? -eq 0 ]; then
      echo "Lua module $1 installed successfully."
      return 0
    else
      echo "Error: Failed to install Lua module $1."
      return 1
    fi
  fi
}

# Check for required commands and install if needed
echo "Checking and installing required commands..."
check_command lua
check_command wget
check_command curl
check_command luarocks

# Check for required Lua modules and install if needed
echo "" && echo "Checking and installing required Lua modules..."
check_lua_module socket.http
check_lua_module dkjson
echo ""
# Check if the settings.lua file exists and update if necessary
settings_file="$(dirname "$lua_script")/settings.lua"
if [ -f "$settings_file" ]; then
  echo "Found settings.lua"

  # Update save_loc
  sed -i "s|save_loc = \".*\"|save_loc = \"$(pwd)/weather.json\"|" "$settings_file"
  echo "Updated save_loc in settings.lua"

  # Update icon_path
  sed -i "s|icon_path = \".*\"|icon_path = \"$(pwd)/icons/\"|" "$settings_file"
  echo "Updated icon_path in settings.lua"

  # Update conky config lua_load
  sed -i "s|lua_load = '.*'|lua_load = '$(pwd)/weather.lua'|" "$conky_config"
  echo "Updated lua_load in conky config"

  # Check if the icon path exists.
  if [[ -n $(grep -oP 'icon_path\s*=\s*"\K[^"]+' "$settings_file") ]]
  then
    ICON_PATH=$(grep -oP 'icon_path\s*=\s*"\K[^"]+' "$settings_file")
    if [[ -d "$ICON_PATH" ]]
    then
      echo "Icon directory found: $ICON_PATH"
    else
      echo "Error: Icon directory not found: $ICON_PATH"
      exit 1
    fi
  else
    echo "Error: icon_path not defined in settings.lua"
    exit 1
  fi

  # check if save_loc is defined and if the directory it points to is writeable.
  if [[ -n $(grep -oP 'save_loc\s*=\s*"\K[^"]+' "$settings_file") ]]
  then
    SAVE_LOC=$(grep -oP 'save_loc\s*=\s*"\K[^"]+' "$settings_file")
    SAVE_LOC_DIR=$(dirname "$SAVE_LOC")
    if [[ -d "$SAVE_LOC_DIR" ]]
    then
      if [[ -w "$SAVE_LOC_DIR" ]]
      then
        echo "Save location directory is writeable: $SAVE_LOC_DIR"
      else
        echo "Error: Save location directory is not writeable: $SAVE_LOC_DIR"
        exit 1
      fi
    else
      echo "Error: Save location directory does not exist: $SAVE_LOC_DIR"
      exit 1
    fi
  else
    echo "Error: save_loc not defined in settings.lua"
    exit 1
  fi

else
  echo "Error: settings.lua not found in $(dirname \"$lua_script\")."
  exit 1
fi

echo "" && echo "Dependency check complete."

# Ask to start Conky
read -p "Would you like to start conky with pickles weather example conky script? (y/n): " choice
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
  if command -v conky &> /dev/null; then
    killall conky
    conky -d -c "$(pwd)/pickles-weather.examples.conky.conf"
    echo "Conky started with Pickles Weather."
  else
    echo "Error: conky not found. Please install conky to use this feature."
  fi
fi

exit 0
