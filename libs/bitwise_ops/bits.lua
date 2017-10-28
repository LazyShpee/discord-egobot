--- Various operations on bit sequences.

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

-- Modules --
local operators = require("bitwise_ops.operators")

-- Imports --
local band = operators.band
local bor = operators.bor
local lshift = operators.lshift
local rshift = operators.rshift

-- Exports --
local M = {}

--- DOCME
-- @uint n
-- @treturn uint N
function M.Reverse (n)
	n = bor(rshift(band(n, 0xAAAAAAAA), 1), lshift(band(n, 0x55555555), 1))
	n = bor(rshift(band(n, 0xCCCCCCCC), 2), lshift(band(n, 0x33333333), 2))
	n = bor(rshift(band(n, 0xF0F0F0F0), 4), lshift(band(n, 0x0F0F0F0F), 4))
	n = bor(rshift(band(n, 0xFF00FF00), 8), lshift(band(n, 0x00FF00FF), 8))

    return bor(rshift(n, 16), lshift(n, 16))
end

-- Export the module.
return M