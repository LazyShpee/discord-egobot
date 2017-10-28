local pngEncode = require('libs.image_ops.png_encode')
local pngDecode = require('libs.image_ops.png')

local min = math.min
local max = math.max
local floor = math.floor

local png = {}

local function clamp(a)
  return max(0, min(a, 255))
end

function png:getPixel(x, y) -- explicit
  local i = (x + self.width * y) * 4 + 1
  if i <= 0 or i > self.size then return 0, 0, 0, 0 end
  return  self.pixels[i], self.pixels[i + 1], self.pixels[i + 2], self.pixels[i + 3]
end

function png:setPixel(x, y, r, g, b, a) -- explicit
  local i = (x + self.width * y) * 4 + 1
  if i <= 0 or i > self.size then return end
  self.pixels[i], self.pixels[i + 1], self.pixels[i + 2], self.pixels[i + 3] = clamp(r), clamp(g), clamp(b), clamp(a or self.pixels[i + 3])
end

function png:iter() -- returns an iterator that goes on every pixels returning x, y, r, g, b, a
  local i = -4
  return function ()
    i = i + 4
    if i < self.size then
      return (i / 4) % self.width, floor(i / 4 / self.width), self.pixels[i + 1], self.pixels[i + 2], self.pixels[i + 3], self.pixels[i + 4]
    end
  end
end

function png:save(name, opt) -- saves the encoded png to name
  return pngEncode.Save_Interleaved(name, self.pixels, self.width, opt)
end
png.write = png.save -- just an alias

function png:data(opt) -- Get the encoded png as a string
  return pngEncode.ToString_Interleaved(self.pixels, self.width, opt)
end
png.encode = png.data -- another alias

function png:inside(x, y)
  return x >= 0 and x < self.width and y >= 0 and y < self.height
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

function png.open(name)
  local im = setmetatable({}, {__index = png})
  local PNG = pngDecode.Load(name)
  im.pixels = PNG:GetPixels()
  im.width, im.height = PNG:GetDims()
  im.size = im.width * im.height * 4

  return im
end

return png