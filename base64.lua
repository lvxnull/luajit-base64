local lshift = require('bit').lshift
local rshift = require('bit').rshift
local band = require('bit').band
local bor = require('bit').bor
local byte = string.byte

local M = {}

local b64enc = {
  [0] = 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/',
}

local b64dec = {
  [0x3d] = 0,  [0x41] = 0,  [0x42] = 1,  [0x43] = 2,  [0x44] = 3,  [0x45] = 4,
  [0x46] = 5,  [0x47] = 6,  [0x48] = 7,  [0x49] = 8,  [0x4a] = 9,  [0x4b] = 10,
  [0x4c] = 11, [0x4d] = 12, [0x4e] = 13, [0x4f] = 14, [0x50] = 15, [0x51] = 16,
  [0x52] = 17, [0x53] = 18, [0x54] = 19, [0x55] = 20, [0x56] = 21, [0x57] = 22,
  [0x58] = 23, [0x59] = 24, [0x5a] = 25, [0x61] = 26, [0x62] = 27, [0x63] = 28,
  [0x64] = 29, [0x65] = 30, [0x66] = 31, [0x67] = 32, [0x68] = 33, [0x69] = 34,
  [0x6a] = 35, [0x6b] = 36, [0x6c] = 37, [0x6d] = 38, [0x6e] = 39, [0x6f] = 40,
  [0x70] = 41, [0x71] = 42, [0x72] = 43, [0x73] = 44, [0x74] = 45, [0x75] = 46,
  [0x76] = 47, [0x77] = 48, [0x78] = 49, [0x79] = 50, [0x7a] = 51, [0x30] = 52,
  [0x31] = 53, [0x32] = 54, [0x33] = 55, [0x34] = 56, [0x35] = 57, [0x36] = 58,
  [0x37] = 59, [0x38] = 60, [0x39] = 61, [0x2b] = 62, [0x2f] = 63,
}

local function batch_stringify(t)
  local output = {}
  local len = #t
  for i = 1, len, 1000 do
    table.insert(output, string.char(unpack(t, i, math.min(len, i + 999))))
  end
  return table.concat(output)
end

function M.enc(s)
  local len = #s
  local output = {}

  local mask = 0x3f -- 0b00111111
  local j = 1
  for i = 1, len, 3 do
    local b1, b2, b3 = byte(s, i, i + 2)
    local bits = bor(lshift(b1, 16), lshift(b2 or 0, 8), b3 or 0)
    output[j] = b64enc[rshift(bits, 18)]
    output[j + 1] = b64enc[band(rshift(bits, 12), mask)]
    output[j + 2] = b64enc[band(rshift(bits, 6), mask)]
    output[j + 3] = b64enc[band(bits, mask)]
    j = j + 4
  end

  for i = 0, 1 - ((len - 1) % 3) do
    output[#output - i] = '='
  end

  return table.concat(output)
end

function M.dec(s)
  local len = #s
  local output = {}

  local mask = 0xff
  local b1, b2, b3, b4

  local j = 1
  for i = 1, len, 4 do
    b1, b2, b3, b4 = byte(s, i, i + 3)
    local bits = bor(lshift(b64dec[b1], 18), lshift(b64dec[b2], 12), lshift(b64dec[b3], 6), b64dec[b4])
    output[j] = rshift(bits, 16)
    output[j + 1] = band(rshift(bits, 8), mask)
    output[j + 2] = band(bits, mask)
    j = j + 3
  end

  if b4 == 0x3d then
    table.remove(output)
    if b3 == 0x3d then
      table.remove(output)
    end
  end

  return batch_stringify(output)
end

return M
