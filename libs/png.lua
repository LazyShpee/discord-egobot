local pngEncode = require('./libs/png_encode')

local min = math.min
local max = math.max
local floor = math.floor

local png = {}

local function clamp(a)
  return max(0, min(a, 255))
end

function png:getPixel(x, y)
  local i = (x + self.width * y) * 4 + 1
  if i <= 0 or i > self.size then return 0, 0, 0, 0 end
  return  self.pixels[i], self.pixels[i + 1], self.pixels[i + 2], self.pixels[i + 3]
end

function png:setPixel(x, y, r, g, b, a)
  local i = (x + self.width * y) * 4 + 1
  if i <= 0 or i > self.size then return end
  self.pixels[i], self.pixels[i + 1], self.pixels[i + 2], self.pixels[i + 3] = clamp(r), clamp(g), clamp(b), clamp(a or self.pixels[i + 3])
end

function png:iter()
  local i = -4
  return function ()
    i = i + 4
    if i < self.size then
      return (i / 4) % self.width, floor(i / 4 / self.width), self.pixels[i + 1], self.pixels[i + 2], self.pixels[i + 3], self.pixels[i + 4]
    end
  end
end

function png:save(name, opt)
  return pngEncode.Save_Interleaved(name, self.pixels, self.width, opt)
end

function png.new(width, height)
  local im = setmetatable({
    pixels = {},
    width = width, height = height,
    size = width * height * 4 
  }, {__index = png})
  
  for i = 1, width * height * 4 do
    im.pixels[i] = 0
  end
  
  return im
end

return png