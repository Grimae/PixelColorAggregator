-- Aseprite script to aggregate pixel data in a zigzag pattern
-- and output the results to a text file.

local sprite = app.activeSprite

if not sprite then
  app.alert("No active sprite found.")
  return
end

local currentFrame = sprite.cels[1].image -- Accessing the image of the first cel
local width = currentFrame.width
local height = currentFrame.height
local output = {}

-- Predefined set of hex color codes and their corresponding color names
local colorNames = {
  ["#FFFFFF"] = "white",
  ["#000000"] = "black",
  ["#FF0000"] = "red",
  ["#00FF00"] = "green",
  ["#0000FF"] = "blue",
  ["#FFFF00"] = "yellow",
  ["#FF00FF"] = "magenta",
  ["#00FFFF"] = "cyan",
  ["#800000"] = "maroon",
  ["#808000"] = "olive",
  ["#008000"] = "dark green",
  ["#800080"] = "purple",
  ["#008080"] = "teal",
  ["#000080"] = "navy",
  ["#FFA500"] = "orange",
  ["#A52A2A"] = "brown",
  ["#808080"] = "gray",
  ["#C0C0C0"] = "silver",
  -- Add more color names and hex codes as needed
}

-- Fallback function to approximate colors
local function approximateColor(hexColor)
  local closestName = "unknown"
  local minDiff = math.huge
  
  for colorHex, colorName in pairs(colorNames) do
    -- Convert hex to RGB
    local r1, g1, b1 = tonumber(hexColor:sub(2, 3), 16), tonumber(hexColor:sub(4, 5), 16), tonumber(hexColor:sub(6, 7), 16)
    local r2, g2, b2 = tonumber(colorHex:sub(2, 3), 16), tonumber(colorHex:sub(4, 5), 16), tonumber(colorHex:sub(6, 7), 16)
    
    -- Calculate the color difference
    local diff = math.sqrt((r1 - r2)^2 + (g1 - g2)^2 + (b1 - b2)^2)
    
    if diff < minDiff then
      minDiff = diff
      closestName = colorName
    end
  end
  
  return closestName
end

-- Function to convert pixel color to readable format
local function colorToString(color)
  local hexColor = string.format("#%06X", color & 0xFFFFFF)
  
  -- Check if the color exists in the predefined names
  if colorNames[hexColor] then
    return colorNames[hexColor]  -- Return the name if it exists
  else
    return approximateColor(hexColor)  -- Return the closest color name if not found
  end
end

-- Function to aggregate pixel data in a zigzag pattern
local function aggregatePixels()
  for y = 0, height - 1 do
    local rowOutput = {}
    
    -- Determine the direction of scanning based on the row number
    local startX, endX, step
    if y % 2 == 0 then
      startX, endX, step = width - 1, 0, -1  -- Right to left
    else
      startX, endX, step = 0, width - 1, 1   -- Left to right
    end

    local currentColor = nil
    local count = 0

    for x = startX, endX, step do
      local pixelColor = currentFrame:getPixel(x, y)  -- Use the image object to get pixel color

      if pixelColor == currentColor then
        count = count + 1
      else
        if currentColor then
          table.insert(rowOutput, string.format("%s, %d", 
            colorToString(currentColor), count))
        end
        currentColor = pixelColor
        count = 1
      end
    end

    -- Handle the last color in the line
    if currentColor then
      table.insert(rowOutput, string.format("%s, %d", 
        colorToString(currentColor), count))
    end
    
    -- Combine row output and add it to overall output with a blank line after each row
    table.insert(output, table.concat(rowOutput, ", "))
    table.insert(output, "")  -- Add an empty line
  end
end

-- Aggregate the pixel data
aggregatePixels()

-- Extract the base filename without path
local baseFileName = sprite.filename:match("([^/\\]+)%.") .. "_output.txt"

-- Set the output path to the desktop
local homeDir = os.getenv("HOME") or os.getenv("USERPROFILE")  -- Get the home directory cross-platform
local outputPath = homeDir .. "/Desktop/" .. baseFileName

-- Debugging output for the output path
print("Output Path:", outputPath)

-- Write the output to a text file
local file, err = io.open(outputPath, "w")
if file then
  file:write(table.concat(output, "\n"))
  file:close()
  app.alert("Output saved to: " .. outputPath)
else
  app.alert("Failed to save output: " .. tostring(err))  -- Include the error message
end
