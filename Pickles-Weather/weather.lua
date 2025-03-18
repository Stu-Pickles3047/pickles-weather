#!/usr/bin/lua
--Pickles Weather
--Thankyou for tryting out Pickles Weather for conky.
--Please See readme or Pickles-weather.examples.conky.conf
-- DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU ARE DOING.
--No editing instructions inside
--===============================================================
-- 
-- Determine the script's directory
local script_path = debug.getinfo(1, "S").source:match("@(.*[/\\])")

-- Add the script's directory to package.path
if script_path then
    package.path = package.path .. ";" .. script_path .. "?.lua"
    --print(package.path) -- Debug print
end

-- Load settings from settings.lua
local settings = require("settings")

-- Use settings from the loaded table
local latitude = settings.latitude
local longitude = settings.longitude
local save_loc = settings.save_loc
local icon_path = settings.icon_path
local icon_size = settings.icon_size

local last_download_time = 0
local json = require("dkjson")

--Download Json if needed
function download_file(url, filepath)
    http = require("socket.http")
    file, err = io.open(filepath, "wb")
    if not file then
        return false, "Error opening file for writing: " .. filepath .. (err and " (" .. err .. ")" or "")
    end
    body, code, headers, status = http.request(url)
    file:close()
    if code == 200 then
        file_write, write_err = io.open(filepath, "wb")
        if file_write then
            file_write:write(body)
            file_write:close()
            return true
        else
            return false, "Error writing body to file: " .. filepath .. (write_err and " (" .. write_err .. ")" or "")
        end
    else
        os.remove(filepath)
        return false, "HTTP request failed: " .. code .. " " 
    end
end
function get_json()
    current_time = os.time()
    if current_time - last_download_time < 1800 then
        return true
    end
    json_url = string.format("http://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m,is_day,rain,showers,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Australia%%2FSydney&forecast_days=1&models=best_match", latitude, longitude)
    success, err = download_file(json_url, save_loc)
    if success then
        last_download_time = current_time
    end
    return success, err
end
--Read Json
function read_json(filepath)
    get_json()
    local file, err = io.open(filepath, "r")
    if not file then
        return nil, "Error opening JSON file: " .. filepath .. (err and " (" .. err .. ")" or "")
    end
    local content = file:read("*a")
    file:close()
    local data, err = json.decode(content)
    if not data then
        return nil, "Error decoding JSON: " .. (err and " (" .. err .. ")" or "")
    end
    return data, nil
end

--Conky Temperatur
function conky_temperature()
    local weather_data, err = read_json(save_loc)
    if not weather_data then
        return "Error: " .. err
    end
    if weather_data and weather_data.current and weather_data.current.temperature_2m then
        return weather_data.current.temperature_2m
    else
        return "Data unavailable"
    end
end

--Conky Min Temp
function conky_min()
    local weather_data, err = read_json(save_loc)
    if not weather_data then
        return "Error: " .. err
    end
    if weather_data and weather_data.daily and weather_data.daily.temperature_2m_min and weather_data.daily.temperature_2m_min[1] then
        return weather_data.daily.temperature_2m_min[1]
    else
        return "Data unavailable"
    end
end

--Conky Max Temp
function conky_max()
    local weather_data, err = read_json(save_loc)
    if not weather_data then
        return "Error: " .. err
    end
    if weather_data and weather_data.daily and weather_data.daily.temperature_2m_max and weather_data.daily.temperature_2m_max[1] then
        return weather_data.daily.temperature_2m_max[1]
    else
        return "Data unavailable"
    end
end

--Get weather descriptions from Json and convert to text
function code_descriptor(weather_code)
    local descriptions = {
        [0] = "Clear sky",
        [1] = "Mainly clear",
        [2] = "partly cloudy",
        [3] = "overcast",
        [45] = "fog",
        [48] = "depositing rime fog",
        [51] = "Light drizzle",
        [53] = "moderate drizzle",
        [55] = "dense drizzle",
        [56] = "light freezing drizzle",
        [57] = "dense freezing drizzle",
        [61] = "slight rain",
        [63] = "moderate rain",
        [65] = "heavy rain",
        [66] = "light freezing rain",
        [67] = "heavy freezing rain",
        [71] = "slight snow fall",
        [73] = "moderate snow fall",
        [75] = "heavy snow fall",
        [77] = "snow grains",
        [80] = "slight rain showers",
        [81] = "moderate rain showers",
        [82] = "violent rain showers",
        [85] = "slight snow showers",
        [86] = "heavy snow showers",
        [95] = "thunderstorms"
    }
    return descriptions[weather_code] or "code not found"
end

--Get weather icon code
function code_image(weather_code)
    local image_code = {
        [0] = "01",
        [1] = "02",
        [2] = "03",
        [3] = "04",
        [45] = "50",
        [48] = "50",
        [51] = "09",
        [53] = "09",
        [55] = "09",
        [56] = "09",
        [57] = "09",
        [61] = "10",
        [63] = "10",
        [65] = "10",
        [66] = "13",
        [67] = "13",
        [71] = "13",
        [73] = "13",
        [75] = "13",
        [77] = "13",
        [80] = "09",
        [81] = "09",
        [82] = "13",
        [85] = "13",
        [86] = "13",
        [95] = "11"
    }
    return image_code[weather_code] or "code not found"
end

--conky weather Description
function conky_description()
    local weather_data, err = read_json(save_loc)
    if not weather_data then
        return "Error: " .. err
    end
    if weather_data and weather_data.current and weather_data.current.weather_code then
        wc = weather_data.current.weather_code
        descript = code_descriptor(wc)
        return descript
    else
        return "Data unavailable"
    end
end

--Conky get and return icon details
function get_image_code()
    -- Retrieve weather_code from JSON
    local weather_data, err = read_json(save_loc)
    if weather_data and weather_data.current and weather_data.current.weather_code then
        local wc = weather_data.current.weather_code
        local img_code = code_image(wc) -- Capture return value
        return(img_code) -- Print the image code
    else
        print("Image code: Data unavailable") --handle the error
    end
end

--Is it day or night
function get_isday()
    local weather_data, err = read_json(save_loc)
    if weather_data and weather_data.current and weather_data.current.is_day then
        local id = weather_data.current.is_day
        if id == 0 then
            dn = 'n'
        elseif id == 1 then
            dn = 'd'
        else
            dn = "unknown"
        end
        return dn
    else
        print("Image code: Data unavailable")
        return nil
    end
end

--Conky Image
function conky_image(args)
    local numbers = {}
    for num in args:gmatch("%d+") do
        table.insert(numbers, num)
    end

    if #numbers >= 2 then
        local x, y = numbers[1], numbers[2]
        local img_code = get_image_code()
        local is_day = get_isday()
        local ico_loc = icon_path .. img_code .. is_day .. "@2x.png"

        local image_command = "${image " .. ico_loc .. " -s " .. icon_size .. " -p " .. x .. "," .. y .. "}"
        return image_command
    else
        print("gmatch failed")
        return nil
    end
end


-- Main Script
get_json()

--FOR DEBUG PURPOSES
--temp = conky_temperature()
--min = conky_min()
--max = conky_max()
--desc = conky_description()
--print(temp)
--print(min)
--print(max)
--print(desc)
--test case for function conky_image
--print(conky_image("p=10, 20"))

