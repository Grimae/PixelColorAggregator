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

-- Function to convert pixel color to readable format
local function colorToString(color)
  if color == 4294967295 then
    return "white"
  elseif color == 4278190080 then
    return "black"
  else
    return string.format("#%08X", color)  -- Convert to hex format for other colors
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
