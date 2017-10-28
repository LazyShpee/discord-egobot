--- Utilities for Huffman codes.

--[[
From the original (in zlib):

/*
 * Extracted from pdf.js
 * https://github.com/andreasgal/pdf.js
 *
 * Copyright (c) 2011 Mozilla Foundation
 *
 * Contributors: Andreas Gal <gal@mozilla.com>
 *               Chris G Jones <cjones@mozilla.com>
 *               Shaon Barman <shaon.barman@gmail.com>
 *               Vivien Nicolas <21@vingtetun.org>
 *               Justin D'Arcangelo <justindarc@gmail.com>
 *               Yury Delendik
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
]]

-- Standard library imports --
local byte = string.byte
local max = math.max

-- Exports --
local M = {}

--- DOCME
function M.DecodeCompactByteStream (stream, from, max_bits)
	local ht, spos, code, prev = {}, from + max_bits + 1, 0, 0

	for i = 1, max_bits do
		local n = byte(stream, from + i)

		if n > 0 then
			local symbols = { nbits = i - prev, offset = code - 1, beyond = code + n }

			for j = 1, n do
				symbols[j], spos = byte(stream, spos), spos + 1
			end

			ht[#ht + 1], code, prev = symbols, code + n, i
		end

		code = 2 * code
	end

	return ht, spos
end

-- --
local Lengths = {}

--- DOCME
function M.GenCodes (codes, from, n, yfunc)
	-- Find max code length, culling 0 lengths as an optimization.
	local max_len, nlens = 0, 0

	for i = 1, n or #from do
		local len = from[i]

		if len > 0 then
			Lengths[nlens + 1] = i - 1
			Lengths[nlens + 2] = len

			max_len, nlens = max(len, max_len), nlens + 2
		end
	end

	-- Build the table.
	local code, skip, cword, size = 0, 2, 2^16, 2^max_len

	codes.max_len, codes.size = max_len, size

	for i = 1, max_len do
		for j = 1, nlens, 2 do
			if i == Lengths[j + 1] then
				-- Bit-reverse the code.
				local code2, t = 0, code

				for _ = 1, i do
					local bit = t % 2

					code2, t = 2 * code2 + bit, .5 * (t - bit)
				end

				-- Fill the table entries.
				local entry = cword + Lengths[j]

				for k = code2 + 1, size, skip do
					codes[k] = entry
				end

				code = code + 1

				yfunc()
			end
		end

		code, skip, cword = 2 * code, 2 * skip, cword + 2^16
	end
end

-- Export the module.
return M