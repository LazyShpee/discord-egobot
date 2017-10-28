--- A JPEG loader and associated functionality.

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
local assert = assert
local byte = string.byte
local char = string.char
local floor = math.floor
local ipairs = ipairs
local max = math.max
local min = math.min
local sub = string.sub

-- Modules --
local huffman = require("libs.image_ops.huffman")
local image_utils = require("libs.image_ops.utils")
local operators = require("libs.bitwise_ops.operators")

-- Imports --
local bnot = operators.bnot
local ReadU16 = image_utils.ReadU16

-- Exports --
local M = {}

-- --
local Component = { "Y", "Cb", "Cr", "I", "Q" }

--
local function Nybbles (n)
	local low = n % 16

	return (n - low) * 2^-4, low
end

--
local function GetStartOfFrame (str, pos, get_data)
	local nbits, data = byte(str, pos)
	local h = ReadU16(str, pos + 1)
	local w = ReadU16(str, pos + 3)

	if get_data then
		data, pos = { nbits = nbits }, pos + 5

		for i = 1, byte(str, pos) * 3, 3 do
			local horz, vert = Nybbles(byte(str, pos + i + 1))

			data[#data + 1] = {
				id = Component[byte(str, pos + i)],
				horz_samp_factor = horz, vert_samp_factor = vert,
				quantization_table = byte(str, pos + i + 2)
			}
		end
	end

	return w, h, data
end

--
local function ReadHeader (str, pos, get_data)
	while true do
		if byte(str, pos) ~= 0xFF then
			return false
		else
			local code = byte(str, pos + 1)

			-- Start Of Frame --
			if code == 0xC0 or code == 0xC1 then
				return true, GetStartOfFrame(str, pos + 4, get_data)

			-- End Of Image --
			elseif code == 0xD9 then
				return false
			end
		end

		pos = pos + ReadU16(str, pos + 2) + 2
	end
end

--
local function AuxInfo (str, get_data)
	if sub(str, 1, 2) == char(0xFF, 0xD8) then
		return ReadHeader(str, 3, get_data)
	end

	return false
end

--- DOCME
function M.GetInfo (name, get_data)
	return image_utils.ReadHeader(name, "*a", AuxInfo, get_data)
end

--- DOCME
M.GetInfoString = AuxInfo

--
local function OnByte (cur_byte, jpeg, pos)
	if cur_byte == 0xFF then
		local next_byte = byte(jpeg, pos + 1)

		if next_byte == 0x00 then
			return pos + 1
		elseif next_byte == 0xFF then -- Needs testing!
			pos = pos + 1

			repeat
				pos = pos + 1
			until byte(jpeg, pos + 1) ~= 0xFF

			return pos
		else
			-- Segment or repeat marker :(
			-- Throw error? (If for recovery, OnByte needs to be pcall'd)
		end
	end
end
local oc=os.clock
--
local function Decode (get_bits, ht)
	local code = 0

	for nbits = 1, #ht do
		local symbols = ht[nbits]

		code = get_bits(code, symbols.nbits)

		if code < symbols.beyond then
			return symbols[code - symbols.offset]
		end
	end
end

--
local function Extend (v, t)
	if v < 2^(t - 1) then
		v = v - bnot(0xFFFFFFFF * 2^t)
	end

	return v
end

--
local function DQT (jpeg, from, qbyte)
	local is_16bit = qbyte > 16
	local qt = { is_16bit = is_16bit }

	if is_16bit then
		for pos = from + 1, from + 128, 2 do
			local a, b = byte(jpeg, pos, pos + 1)

			qt[#qt + 1] = a * 2^8 + b
		end
	else
		for i = 1, 64 do
			qt[i] = byte(jpeg, from + i)
		end
	end

	return qt, from + (is_16bit and 128 or 64) + 1
end

-- --
local Cos, Sqrt2_2 = {}, .25 * math.sqrt(2)

do
	for x = 0, 7 do
		local k = 2 * x + 1

		Cos[#Cos + 1] = Sqrt2_2

		for u = 1, 7 do
			Cos[#Cos + 1] = .5 * math.cos(k * u * math.pi / 16)
		end
	end
end

-- --
local Zagzig = {
    0,  1,  8, 16,  9,  2,  3, 10,
   17, 24, 32, 25, 18, 11,  4,  5,
   12, 19, 26, 33, 40, 48, 41, 34,
   27, 20, 13,  6,  7, 14, 21, 28,
   35, 42, 49, 56, 57, 50, 43, 36,
   29, 22, 15, 23, 30, 37, 44, 51,
   58, 59, 52, 45, 38, 31, 39, 46,
   53, 60, 61, 54, 47, 55, 62, 63
}

-- Make the array more amenable to 1-based indexing.
for i, n in ipairs(Zagzig) do
	Zagzig[i] = n + 1
end

-- --
local ZZ = {}

--
local function FillZeroes (k, n)
	for i = k, k + n - 1 do
		ZZ[i] = 0
	end

	return k + n
end

-- --
local Dequant = {}
local pmcu_t,pmcu_n=0,0
local entropy_t,entropy_n=0,0
local idct_t,idct_n=0,0

-- --
local QU = {}

-- --
local Offset = { 1, 3, 5, 7, 1 + 64, 3 + 64, 5 + 64, 7 + 64 }

--
local function ScaleX2 (work, dcol) -- N.B. For now, assume width, height = 1...
	local wpos = 2 * dcol

	for rpos = dcol, 1, -8 do
		for i = 0, 7 do
			local sample, j = work[rpos - i], wpos - Offset[i + 1]

			work[j], work[j + 1] = sample, sample
		end

		wpos = wpos - 8
	end
end

-- --
local Quarters = { 2, 1, 1.5, .5 }

--
local function ScaleY2 (work, dline, hcells) -- ditto
	local rpos, quarter = dline, .25 * dline

	for q = 1, 4 do
		local wpos, rnext = Quarters[q] * dline, rpos - quarter

		while rpos > rnext do
			for i = 0, 7 do
				local sample, j = work[rpos - i], wpos - i

				work[j], work[j - 8] = sample, sample
			end

			rpos, wpos = rpos - 8, wpos - 16
		end
	end
end

--
local function ProcessMCU (get_bits, scan_info, shift, reader_op, yfunc)
local t0=oc()
	--
	local mcus_left, preds, hcells = scan_info.left, scan_info.preds, scan_info.hcells

	if mcus_left == 0 then
		reader_op("round_up")
		reader_op("get_bytes", 2)

		for i = 1, #scan_info do
			preds[i] = 0
		end

		scan_info.left = scan_info.mcus - 1
	elseif mcus_left then
		scan_info.left = mcus_left - 1
	end

	--
	for i, scan in ipairs(scan_info) do
		local dht, aht, qt, work, wpos = scan.dht, scan.aht, scan.qt, scan.work, 1
		local scalex, scaley, dcol, dline = scan.scalex, scan.scaley, scan.du_column, scan.du_line

		for _ = 1, scan.nunits do
local tt=oc()
			--
			local s = Decode(get_bits, dht)
			local extra, r = s % 16, 0

			if extra > 0 then
				r = get_bits(0, extra)
			end

			preds[i] = preds[i] + Extend(r, s)

			--
			local k = 1

			while k < 64 do
				local zb = Decode(get_bits, aht)

				if zb > 0 then
					if zb < 16 then
						ZZ[k], k = Extend(get_bits(0, zb), zb), k + 1
					elseif zb ~= 0xF0 then
						local nzeroes, nbits = Nybbles(zb)

						k = FillZeroes(k, nzeroes)
						ZZ[k], k = Extend(get_bits(0, nbits), nbits), k + 1
					else
						k = FillZeroes(k, 16)
					end
				else
					break
				end
			end
entropy_t,entropy_n=entropy_t+oc()-tt,entropy_n+1
			--
			Dequant[1] = preds[i] * qt[1]

			-- for j = 1, 64 * 64, 64 ?
			--		pqt * Sqrt2_2
			-- Row1.limit = 1 (or 8?)

			for j = 2, k do
				local at, dq = Zagzig[j], qt[j] * ZZ[j - 1]

				Dequant[at] = dq
			end

			for j = k + 1, 64 do
				Dequant[Zagzig[j]] = 0
			end

			-- ^^^ Possible way to precalculate in the cos coefficients:
			-- Zigzag[j] refers to first of 8 values in Dequant (with spacing of... 64? would then require no changes...)
			-- Do `% 8`, etc. on result to figure out row, column (alternatively, step the zagzig algorithmically)
			-- If in first column (including DC) multiply by Sqrt2_2 each
			-- Else multiply by Cos[u + col - 1], Cos[u + col + 8 - 1], ...
			-- Lookups in below step would be far fewer
			-- If matrices typically sparse, ought to incur FAR fewer multiplications and lookups overall
			-- Problem: naive approach might waste a lot of effort zeroing Dequant
			-- Idea: Keep "largest column" per row, zero until previous limit
			-- Since only used in next step, can assume further elements are 0 (even across components and MCU's)
			-- ^^ Observed non-zeroes (out of 64): simple image = avg of 21.93; complex image = 39.79
local tb=oc()
			--
			local qi = 1

			for u = 1, 64, 8 do
				local a, b, c, d, e, f, g = Cos[u + 1], Cos[u + 2], Cos[u + 3], Cos[u + 4], Cos[u + 5], Cos[u + 6], Cos[u + 7]

				for j = 1, 64, 8 do
					QU[qi], qi = Dequant[j] * Sqrt2_2 +
						a * Dequant[j + 1] +
						b * Dequant[j + 2] +
						c * Dequant[j + 3] +
						d * Dequant[j + 4] +
						e * Dequant[j + 5] +
						f * Dequant[j + 6] +
						g * Dequant[j + 7], qi + 1
				end

				QU[u] = QU[u] * Sqrt2_2 + shift
			end

			--
			local up_to = wpos + 64

			for v = 1, 64, 8 do
				local a, b, c, d, e, f, g = Cos[v + 1], Cos[v + 2], Cos[v + 3], Cos[v + 4], Cos[v + 5], Cos[v + 6], Cos[v + 7]

				for u = 1, 64, 8 do
					local sum = QU[u] +
						a * QU[u + 1] +
						b * QU[u + 2] +
						c * QU[u + 3] +
						d * QU[u + 4] +
						e * QU[u + 5] +
						f * QU[u + 6] +
						g * QU[u + 7]

					work[wpos], wpos = sum, wpos + 1
				end

				-- wpos = wpos + stride? (put into a more natural order...)
				-- Then ScaleX2 and ScaleY2 wouldn't be so crazy
			end

idct_t,idct_n=idct_t+oc()-tb,idct_n+1
		end

		yfunc()

		--
		if scalex then
			if scalex == 2 then
				ScaleX2(work, dcol, hcells)
			else
				--
			end

			yfunc()
		end

		if scaley then
			if scaley == 2 then
				ScaleY2(work, dline, hcells)
			else
				--
			end

			yfunc()
		end
	end
pmcu_t,pmcu_n=pmcu_t+oc()-t0,pmcu_n+1
end

--
local function Int255 (comp)
	if comp < 0 then
		return 0
	elseif comp > 255 then
		return 255
	else
		return floor(comp + .5)
	end
end

-- --
local Synth = {}

--
function Synth.YCbCr255 (data, pos, scan_info, base, run, from)
	local y_work, cb_work, cr_work = scan_info[1].work, scan_info[2].work, scan_info[3].work

	for i = 1, run, 8 do
		for j = from, from + min(7, run - i) do
			local at = base + j
			local y = y_work[at]
			local cr = cr_work[at] - 128 -- :/ Just undoes the previous shift...
			local cb = cb_work[at] - 128

			data[pos + 1] = Int255(y + 1.402 * cr)
			data[pos + 2] = Int255(y - .34414 * cb - .71414 * cr)
			data[pos + 3] = Int255(y + 1.772 * cb)
			data[pos + 4] = 255

			pos = pos + 4
		end

		base = base + 64
	end
end

--
local function SetupScan (jpeg, from, state, dhtables, ahtables, qtables, n, restart)
	local scan_info, preds, synth = { left = restart, mcus = restart }, {}, ""

	for i = 1, n do
		local comp = Component[byte(jpeg, from + 1)]

		for _, scomp in ipairs(state) do
			if comp == scomp.id then
				local di, ai = Nybbles(byte(jpeg, from + 2))
				local hsf, vsf = scomp.horz_samp_factor, scomp.vert_samp_factor
				local scalex, scaley = state.hmax / hsf, state.vmax / vsf

				scan_info[i], preds[i] = {
					nunits = hsf * vsf,
					scalex = scalex > 1 and scalex, du_column = hsf * 64,
					scaley = scaley > 1 and scaley, du_line = vsf * 64 * state.hmax,
					dht = dhtables[di + 1], aht = ahtables[ai + 1],
					qt = qtables[scomp.quantization_table + 1],
					work = {}
				}, 0

				break
			end
		end

		from, synth = from + 2, synth .. comp
	end

	--
	scan_info.preds, scan_info.hcells, scan_info.vcells = preds, state.hmax * 8, state.vmax * 8

	return scan_info, assert(Synth[synth .. (2^state.nbits - 1)], "No synthesize method available")
end

-- Default yield function: no-op
local function DefYieldFunc () end

--
local function AuxLoad (jpeg, yfunc)
	local state, w, h

	assert(sub(jpeg, 1, 2) == char(0xFF, 0xD8), "Image is not a JPEG")

	yfunc = yfunc or DefYieldFunc

	local pos, total, ahtables, dhtables, qtables, pixels, restart = 3, #jpeg, {}, {}, {}

local tt=oc()
	while true do
		assert(byte(jpeg, pos) == 0xFF, "Not a segment")

		local code = byte(jpeg, pos + 1)

		if code == 0xD9 then
			break
		end

		local from, len = pos + 4, ReadU16(jpeg, pos + 2)
		local next_pos = pos + len + 2

		--
		yfunc()

		-- Start Of Frame --
		if code == 0xC0 or code == 0xC1 then
			w, h, state = GetStartOfFrame(jpeg, from, true)

			for _, comp in ipairs(state) do
				state.hmax = max(state.hmax or 0, comp.horz_samp_factor)
				state.vmax = max(state.vmax or 0, comp.vert_samp_factor)
			end

		-- Define Huffman Table --
		elseif code == 0xC4 then
			repeat
				local hbyte, ht, spos = byte(jpeg, from), huffman.DecodeCompactByteStream(jpeg, from, 16)

				if hbyte >= 16 then
					ahtables[hbyte - 15] = ht
				else
					dhtables[hbyte + 1] = ht
				end

				from = spos
			until from == next_pos

		-- Start Of Scan --
		elseif code == 0xDA then
			pixels = pixels or {}

			--
			local n, shift = byte(jpeg, from), 2^(state.nbits - 1)
			local scan_info, synth = SetupScan(jpeg, from, state, dhtables, ahtables, qtables, n, restart)

			--
			local get_bits, reader_op = image_utils.BitReader(jpeg, from + 2 * n + 4, OnByte, true)
			local hcells, vcells = scan_info.hcells, scan_info.vcells

			-- 
			local ybase, xstep, ystep, rowstep = 0, 4 * hcells, 4 * w * vcells, 4 * w
			local cstep = 2 * xstep

			for y1 = 1, h, vcells do
				local xbase, y2 = ybase, min(y1 + vcells - 1, h)

				for x1 = 1, w, hcells do
					ProcessMCU(get_bits, scan_info, shift, reader_op, yfunc)

					local cbase, x2 = 0, min(x1 + hcells - 1, w)
					local pos, run, from = xbase, x2 - x1 + 1, 1

					for _ = y1, y2 do
						synth(pixels, pos, scan_info, cbase, run, from)

						pos, from = pos + rowstep, from + 8

						if from > 64 then
							cbase, from = cbase + cstep, 1
						end
					end

					yfunc()

					xbase = xbase + xstep
				end

				ybase = ybase + ystep
			end

			next_pos = reader_op("get_pos_rounded_up")

		-- Define Quantization table --
		elseif code == 0xDB then
			repeat
				local qbyte = byte(jpeg, from)

				qtables[qbyte % 16 + 1], from = DQT(jpeg, from, qbyte)
			until from == next_pos

		-- Define Restart Interval --
		elseif code == 0xDD then
			restart = ReadU16(jpeg, from)
		end

		pos = next_pos

		assert(pos <= total, "Incomplete or corrupt JPEG file")
	end
print("TOTAL", oc()-tt)

print("MCU", pmcu_t, pmcu_t / pmcu_n)
print("   ENTROPY", entropy_t, entropy_t / entropy_n)
print("   IDCT", idct_t, idct_t / idct_n)
	--
	local JPEG = {}

	--- DOCME
	function JPEG:ForEach (func, arg)
		image_utils.ForEach(pixels, w, h, func, nil, arg)
	end

	--- DOCME
	function JPEG:ForEach_OnRow (func, on_row, arg)
		image_utils.ForEach(pixels, w, h, func, on_row, arg)
	end

	--- DOCME
	function JPEG:ForEachInColumn (func, col, arg)
		image_utils.ForEachInColumn(pixels, w, h, func, col, arg)
	end

	--- DOCME
	function JPEG:ForEachInRow (func, row, arg)
		image_utils.ForEachInRow(pixels, w, func, row, arg)
	end

	--- DOCME
	function JPEG:GetDims ()
		return w, h
	end

	--- DOCME
	function JPEG:GetPixels ()
		return pixels
	end

	--- DOCME
	function JPEG:SetYieldFunc (func)
		yfunc = func or DefYieldFunc
	end

	return JPEG
end

--- DOCME
function M.Load (name, yfunc)
	return image_utils.Load(name, AuxLoad, yfunc)
end

--- DOCME
M.LoadString = AuxLoad

-- Export the module.
return M