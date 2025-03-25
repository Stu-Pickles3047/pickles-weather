-- settings.lua
--Edit this file NOT weather.lua
return {
    -- Location
    -- goto http://maps.google.com search for location, right click on location and the first option shown is the gps co-ords

    latitude = "-37.816228709426966", -- Latitude of location without S or E etc Current location set to Melbourne, Vic, Australia
    longitude = "144.96422468453642", -- Latitude of location without S or E etc  
       --Size you want the weather image to display in conky
    icon_size = "20x20",
     --Location to save weather.json Should be in /path/to/conky-config/Pickles-Weather/weather.json
     save_loc = "/pathto.conky/pickles-weather/weather.json",
     --Location where weather icons are located - Should be in /path/to/conky-config/Pickles-Weather/icons/
     icon_path = "/pathto.conky/pickles-weather/icons/",
}
