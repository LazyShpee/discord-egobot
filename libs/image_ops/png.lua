--- A PNG loader and associated functionality.
--
-- Much of this is a (stripped-down) mechanical translation from [png.js's file of the same name](https://github.com/devongovett/png.js/blob/master/png.js).

--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
--

-- Standard library imports --
local abs = math.abs
local assert = assert
local byte = string.byte
local concat = table.concat
local floor = math.floor
local min = math.min
local sub = string.sub
local unpack = unpack

-- Modules --
local image_utils = require("libs.image_ops.utils")
local zlib = require("libs.image_ops.zlib")

-- Imports --
local ReadU32 = image_utils.ReadU32
local Sub = image_utils.Sub

-- Exports --
local M = {}

-- --
local Signature = "\137\080\078\071\013\010\026\010"

--
local function ReadHeader (str, pos, get_data)
	local w = ReadU32(str, pos)
	local h = ReadU32(str, pos + 4)

	return w, h, get_data and {
		nbits = byte(str, pos + 8),
		ctype = byte(str, pos + 9)
	}
end

--
local function AuxInfo (str, get_data)
	if sub(str, 1, 8) == Signature and sub(str, 13, 16) == "IHDR" then
		return true, ReadHeader(str, 17, get_data)
	end

	return false
end

--- DOCME
function M.GetInfo (name, get_data)
	return image_utils.ReadHeader(name, 24, AuxInfo, get_data)
end

--- DOCME
M.GetInfoString = AuxInfo

--
local function DecodePalette (palette, yfunc)
	local pos, decoded = 1, {}

	for i = 1, #palette, 3 do
		local r, g, b = unpack(palette, i, i + 2)

		decoded[pos], decoded[pos + 1], decoded[pos + 2], decoded[pos + 3] = r, g, b, 255

		pos = pos + 4

		yfunc()
	end

	return decoded
end

--
local function GetCol (i, pixel_bytes)
	local imod = i % pixel_bytes

	return (i - imod) / pixel_bytes, imod
end

--
local function GetLeft (pixels, i, pos, pixel_bytes)
	return i < pixel_bytes and 0 or pixels[pos - pixel_bytes]
end

--
local function GetUpper (pixels, imod, pixel_bytes, roff, col)
	return pixels[roff + col * pixel_bytes + imod + 1]
end

-- --
local DecodeAlgorithm = {
	-- Sub --
	function(pixels, i, pos, pixel_bytes)
		return GetLeft(pixels, i, pos, pixel_bytes)
	end,

	-- Up --
	function(pixels, i, _, pixel_bytes, roff)
		local col, imod = GetCol(i, pixel_bytes)

		return roff >= 0 and GetUpper(pixels, imod, pixel_bytes, roff, col) or 0
	end,

	-- Average --
	function(pixels, i, pos, pixel_bytes, roff)
		local left = GetLeft(pixels, i, pos, pixel_bytes)

		if roff >= 0 then
			local col, imod = GetCol(i, pixel_bytes)

			return floor(.5 * (left + GetUpper(pixels, imod, pixel_bytes, roff, col)))
		else
			return left
		end
	end,

	-- Paeth --
	function(pixels, i, pos, pixel_bytes, roff)
		local left, upper, ul = GetLeft(pixels, i, pos, pixel_bytes), 0, 0

		if roff >= 0 then
			local col, imod = GetCol(i, pixel_bytes)

			upper = GetUpper(pixels, imod, pixel_bytes, roff, col)

			if col > 0 then
				ul = GetUpper(pixels, imod, pixel_bytes, roff, col - 1)
			end
		end

		local p = left + upper - ul
		local pa, pb, pc = abs(p - left), abs(p - upper), abs(p - ul)

		if pa <= pb and pa <= pc then
			return left
		elseif pb <= pc then
			return upper
		else
			return ul
		end
	end
}

--
local function DecodePixels (data, state, w, yfunc)
	if #data == 0 then
		return {}
	end

	data = zlib.NewFlateStream(data):GetBytes(yfunc and { yfunc = yfunc })

	local pixels, nbytes = {}, state.bit_len / 8
	local nscan, wpos, n = nbytes * w, 1, #data
	local roff, rw = -nscan

	for rpos = 1, n, nscan + 1 do
		rw = min(nscan, n - rpos)

		--
		local algo = data[rpos]

		if algo > 0 then
			algo = assert(DecodeAlgorithm[algo], "Invalid filter algorithm")

			for i = 1, rw do
				pixels[wpos] = (data[rpos + i] + algo(pixels, i - 1, wpos, nbytes, roff)) % 256

				wpos = wpos + 1
			end

		--
		else
			for i = rpos + 1, rpos + rw do
				pixels[wpos], wpos = data[i], wpos + 1
			end
		end

		--
		roff = roff + nscan

		yfunc()
	end

	for _ = 1, nscan - rw do
		pixels[wpos], wpos = 0, wpos + 1
	end

	return pixels
end

--
local function GetIndex (pixels, palette, i, j)
	if palette then
		return pixels[.25 * (i - 1) + 1] * 4 + 1
	else
		return j
	end
end

--
local function GetColor1 (input, i, j)
	local v, alpha = unpack(input, i, j)

	return v, v, v, alpha
end

--
local function CopyToImageData (pixels, state, n, yfunc)
	local data, input = {}

	if state.palette then
		state.palette, state.colors, state.has_alpha = DecodePalette(state.palette), 4, true

		input = state.palette
	else
		input = pixels
	end

	local j, extra, count, get_color = 1, state.has_alpha and 1 or 0

	if state.colors == 1 then
		count, get_color = 1 + extra, GetColor1
	else
		count, get_color = 3 + extra, unpack
	end

	for i = 1, n, 4 do
		local k = GetIndex(pixels, state.palette, i, j)
		local r, g, b, alpha = get_color(input, k, k + count - 1)

		data[i], data[i + 1], data[i + 2], data[i + 3], j = r, g, b, alpha or 255, k + count

		yfunc()
	end

	return data
end

-- Default yield function: no-op
local function DefYieldFunc () end

--
local function AuxLoad (png, yfunc)
	local state, w, h

	assert(sub(png, 1, 8) == Signature, "Image is not a PNG")

	yfunc = yfunc or DefYieldFunc

	local pos, total, pixels, data = 9, #png

	while true do
		local size = ReadU32(png, pos)
		local code = Sub(png, pos + 4, 4)

		pos = pos + 8

		-- Image Header --
		if code == "IHDR" then
			w, h, state = ReadHeader(png, pos, true)

			-- compression, filter, interlace methods

		-- Palette --
		elseif code == "PLTE" then
			state.palette = Sub(png, pos, size)

		-- Image Data --
		elseif code == "IDAT" then
			data = data or {}

			data[#data + 1] = Sub(png, pos, size)

		-- Image End --
		elseif code == "IEND" then
			data = concat(data, "")

			local color_type = state.ctype

			if color_type == 0 or color_type == 3 or color_type == 4 then
				state.colors = 1
			elseif color_type == 2 or color_type == 6 then
				state.colors = 3
			end

			state.has_alpha = color_type == 4 or color_type == 6
			state.colors = state.colors + (state.has_alpha and 1 or 0)
			state.bit_len = state.nbits * state.colors
			
			-- color space = (colors == 1): "gray" / (colors == 3) : "rgb"

			break
		end

		pos = pos + size + 4 -- Chunk + CRC

		assert(pos <= total, "Incomplete or corrupt PNG file")
	end

	--
	local function Decode ()
		local decoded = DecodePixels(data, state, w, yfunc)

		decoded, data = CopyToImageData(decoded, state, w * h * 4, yfunc)

		return decoded
	end

	--
	local PNG = {}

	--- DOCME
	function PNG:ForEach (func, arg)
		pixels = pixels or Decode()

		image_utils.ForEach(pixels, w, h, func, nil, arg)
	end

	--- DOCME
	function PNG:ForEach_OnRow (func, on_row, arg)
		pixels = pixels or Decode()

		image_utils.ForEach(pixels, w, h, func, on_row, arg)
	end

	--- DOCME
	function PNG:ForEachInColumn (func, col, arg)
		pixels = pixels or Decode()

		image_utils.ForEachInColumn(pixels, w, h, func, col, arg)
	end

	--- DOCME
	function PNG:ForEachInRow (func, row, arg)
		pixels = pixels or Decode()

		image_utils.ForEachInRow(pixels, w, func, row, arg)
	end

	--- DOCME
	function PNG:GetDims ()
		return w, h
	end

	--- DOCME
	function PNG:GetPixels ()
		pixels = pixels or Decode()

		return pixels
	end

	--- DOCME
	function PNG:SetYieldFunc (func)
		yfunc = func or DefYieldFunc
	end

	-- NYI --
	-- get frame, set frame, has alpha, etc.

	return PNG
end

--- DOCME
function M.Load (name, yfunc)
	return image_utils.Load(name, AuxLoad, yfunc)
end

--- DOCME
M.LoadString = AuxLoad

-- Export the module.
return M