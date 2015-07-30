-- $Id: bitwise.lua,v 1.24 2014/12/26 17:20:53 roberto Exp $

print("testing bitwise operations")

local numbits = string.packsize('j') * 8

assert(~0 == -1)

--XXX Kernel Lua: no math lib
if not _KERNEL then
assert((1 << (numbits - 1)) == math.mininteger)
end

-- basic tests for bitwise operators;
-- use variables to avoid constant folding
local a, b, c, d
a = 0xFFFFFFFFFFFFFFFF
assert(a == -1 and a & -1 == a and a & 35 == 35)
a = 0xF0F0F0F0F0F0F0F0
-- XXX Kernel Lua: precedence bug
if not _KERNEL then
assert(a | -1 == -1)
assert(a ~ a == 0 and a ~ 0 == a and a ~ ~a == -1)
assert(a >> 4 == ~a)
else
assert((a | -1) == -1)
assert((a ~ a) == 0 and (a ~ 0) == a and (a ~ ~a) == -1)
assert((a >> 4) == ~a)
end
a = 0xF0; b = 0xCC; c = 0xAA; d = 0xFD
-- XXX Kernel Lua: precedence bug
if not _KERNEL then
assert(a | b ~ c & d == 0xF4)
else
assert((a | (b ~ c & d)) == 0xF4)
end

-- XXX Kernel Lua: no floating-point numbers
if not _KERNEL then
eval[['a = 0xF0.0; b = 0xCC.0; c = "0xAA.0"; d = "0xFD.0"'
assert(a | b ~ c & d == 0xF4)]]
end

a = 0xF0000000; b = 0xCC000000;
c = 0xAA000000; d = 0xFD000000
-- XXX Kernel Lua: precedence bug
if not _KERNEL then
assert(a | b ~ c & d == 0xF4000000)
assert(~~a == a and ~a == -1 ~ a and -d == ~d + 1)
else
assert((a | (b ~ c & d)) == 0xF4000000)
assert(~~a == a and ~a == (-1 ~ a) and -d == (~d + 1))
end

a = a << 32
b = b << 32
c = c << 32
d = d << 32
-- XXX Kernel Lua: precedence bug
if not _KERNEL then
assert(a | b ~ c & d == 0xF4000000 << 32)
assert(~~a == a and ~a == -1 ~ a and -d == ~d + 1)
else
assert((a | (b ~ c & d)) == (0xF4000000 << 32))
assert(~~a == a and ~a == (-1 ~ a) and -d == (~d + 1))
end

-- XXX Kernel Lua: no expo operator
if not _KERNEL then
eval'assert(-1 >> 1 == 2^(numbits - 1) - 1 and 1 << 31 == 0x80000000)'
end

-- XXX Kernel Lua: precedence bug
if not _KERNEL then
assert(-1 >> (numbits - 1) == 1)
assert(-1 >> numbits == 0 and
       -1 >> -numbits == 0 and
       -1 << numbits == 0 and
       -1 << -numbits == 0)
else
assert((-1 >> (numbits - 1)) == 1)
assert((-1 >> numbits) == 0 and
       (-1 >> -numbits) == 0 and
       (-1 << numbits) == 0 and
       (-1 << -numbits) == 0)
end

-- XXX Kernel Lua: no expo operator
if not _KERNEL then
eval[[assert((2^30 - 1) << 2^30 == 0)'
assert((2^30 - 1) >> 2^30 == 0)]]
end

-- XXX Kernel Lua: precedence bug
if not _KERNEL then
assert(1 >> -3 == 1 << 3 and 1000 >> 5 == 1000 << -5)
else
assert((1 >> -3) == (1 << 3) and (1000 >> 5) == (1000 << -5))
end


-- coercion from strings to integers
-- XXX Kernel Lua: precedence bug
if not _KERNEL then
assert("0xffffffffffffffff" | 0 == -1)
assert("0xfffffffffffffffe" & "-1" == -2)
assert(" \t-0xfffffffffffffffe\n\t" & "-1" == 2)
assert("   \n  -45  \t " >> "  -2  " == -45 * 4)
else
assert(("0xffffffffffffffff" | 0) == -1)
assert(("0xfffffffffffffffe" & "-1") == -2)
assert((" \t-0xfffffffffffffffe\n\t" & "-1") == 2)
assert(("   \n  -45  \t " >> "  -2  ") == -45 * 4)
end

-- out of range number
assert(not pcall(function () return "0xffffffffffffffff.0" | 0 end))

-- embedded zeros
assert(not pcall(function () return "0xffffffffffffffff\0" | 0 end))

print'+'

-- XXX Kernel Lua: creating package table
if _KERNEL then
setfield('package.preload', {})
end

package.preload.bit32 = function ()     --{

-- no built-in 'bit32' library: implement it using bitwise operators

local bit = {}

function bit.bnot (a)
  return ~a & 0xFFFFFFFF
end


--
-- in all vararg functions, avoid creating 'arg' table when there are
-- only 2 (or less) parameters, as 2 parameters is the common case
--

function bit.band (x, y, z, ...)
  if not z then
    return ((x or -1) & (y or -1)) & 0xFFFFFFFF
  else
    local arg = {...}
    local res = x & y & z
    for i = 1, #arg do res = res & arg[i] end
    return res & 0xFFFFFFFF
  end
end

function bit.bor (x, y, z, ...)
  if not z then
    return ((x or 0) | (y or 0)) & 0xFFFFFFFF
  else
    local arg = {...}
    local res = x | y | z
    for i = 1, #arg do res = res | arg[i] end
    return res & 0xFFFFFFFF
  end
end

function bit.bxor (x, y, z, ...)
  if not z then
    return ((x or 0) ~ (y or 0)) & 0xFFFFFFFF
  else
    local arg = {...}
    local res = x ~ y ~ z
    for i = 1, #arg do res = res ~ arg[i] end
    return res & 0xFFFFFFFF
  end
end

function bit.btest (...)
  return bit.band(...) ~= 0
end

function bit.lshift (a, b)
  return ((a & 0xFFFFFFFF) << b) & 0xFFFFFFFF
end

function bit.rshift (a, b)
  return ((a & 0xFFFFFFFF) >> b) & 0xFFFFFFFF
end

function bit.arshift (a, b)
  a = a & 0xFFFFFFFF
  if b <= 0 or (a & 0x80000000) == 0 then
    return (a >> b) & 0xFFFFFFFF
  else
    return ((a >> b) | ~(0xFFFFFFFF >> b)) & 0xFFFFFFFF
  end
end

function bit.lrotate (a ,b)
  b = b & 31
  a = a & 0xFFFFFFFF
  a = (a << b) | (a >> (32 - b))
  return a & 0xFFFFFFFF
end

function bit.rrotate (a, b)
  return bit.lrotate(a, -b)
end

local function checkfield (f, w)
  w = w or 1
  assert(f >= 0, "field cannot be negative")
  assert(w > 0, "width must be positive")
  assert(f + w <= 32, "trying to access non-existent bits")
  return f, ~(-1 << w)
end

function bit.extract (a, f, w)
  local f, mask = checkfield(f, w)
  return (a >> f) & mask
end

function bit.replace (a, v, f, w)
  local f, mask = checkfield(f, w)
  v = v & mask
  a = (a & ~(mask << f)) | (v << f)
  return a & 0xFFFFFFFF
end

return bit

end  --}


print("testing bitwise library")

-- XXX Kernel Lua: if not in kernel Lua, require will load bit32 from preload
-- Otherwise, take it directly
local bit32
if not _KERNEL then
bit32 = require'bit32'
else
bit32 = package.preload.bit32()
end

assert(bit32.band() == bit32.bnot(0))
assert(bit32.btest() == true)
assert(bit32.bor() == 0)
assert(bit32.bxor() == 0)

assert(bit32.band() == bit32.band(0xffffffff))
assert(bit32.band(1,2) == 0)


-- out-of-range numbers
assert(bit32.band(-1) == 0xffffffff)
assert(bit32.band((1 << 33) - 1) == 0xffffffff)
assert(bit32.band(-(1 << 33) - 1) == 0xffffffff)
assert(bit32.band((1 << 33) + 1) == 1)
assert(bit32.band(-(1 << 33) + 1) == 1)
assert(bit32.band(-(1 << 40)) == 0)
assert(bit32.band(1 << 40) == 0)
assert(bit32.band(-(1 << 40) - 2) == 0xfffffffe)
assert(bit32.band((1 << 40) - 4) == 0xfffffffc)

assert(bit32.lrotate(0, -1) == 0)
assert(bit32.lrotate(0, 7) == 0)
assert(bit32.lrotate(0x12345678, 0) == 0x12345678)
assert(bit32.lrotate(0x12345678, 32) == 0x12345678)
assert(bit32.lrotate(0x12345678, 4) == 0x23456781)
assert(bit32.rrotate(0x12345678, -4) == 0x23456781)
assert(bit32.lrotate(0x12345678, -8) == 0x78123456)
assert(bit32.rrotate(0x12345678, 8) == 0x78123456)
assert(bit32.lrotate(0xaaaaaaaa, 2) == 0xaaaaaaaa)
assert(bit32.lrotate(0xaaaaaaaa, -2) == 0xaaaaaaaa)
for i = -50, 50 do
  assert(bit32.lrotate(0x89abcdef, i) == bit32.lrotate(0x89abcdef, i%32))
end

assert(bit32.lshift(0x12345678, 4) == 0x23456780)
assert(bit32.lshift(0x12345678, 8) == 0x34567800)
assert(bit32.lshift(0x12345678, -4) == 0x01234567)
assert(bit32.lshift(0x12345678, -8) == 0x00123456)
assert(bit32.lshift(0x12345678, 32) == 0)
assert(bit32.lshift(0x12345678, -32) == 0)
assert(bit32.rshift(0x12345678, 4) == 0x01234567)
assert(bit32.rshift(0x12345678, 8) == 0x00123456)
assert(bit32.rshift(0x12345678, 32) == 0)
assert(bit32.rshift(0x12345678, -32) == 0)
assert(bit32.arshift(0x12345678, 0) == 0x12345678)
assert(bit32.arshift(0x12345678, 1) == 0x12345678 / 2)
assert(bit32.arshift(0x12345678, -1) == 0x12345678 * 2)
assert(bit32.arshift(-1, 1) == 0xffffffff)
assert(bit32.arshift(-1, 24) == 0xffffffff)
assert(bit32.arshift(-1, 32) == 0xffffffff)
assert(bit32.arshift(-1, -1) == bit32.band(-1 * 2, 0xffffffff))

-- XXX Kernel Lua: precedence bug
if not _KERNEL then
assert(0x12345678 << 4 == 0x123456780)
assert(0x12345678 << 8 == 0x1234567800)
assert(0x12345678 << -4 == 0x01234567)
assert(0x12345678 << -8 == 0x00123456)
assert(0x12345678 << 32 == 0x1234567800000000)
assert(0x12345678 << -32 == 0)
assert(0x12345678 >> 4 == 0x01234567)
assert(0x12345678 >> 8 == 0x00123456)
assert(0x12345678 >> 32 == 0)
assert(0x12345678 >> -32 == 0x1234567800000000)
else
assert((0x12345678 << 4) == 0x123456780)
assert((0x12345678 << 8) == 0x1234567800)
assert((0x12345678 << -4) == 0x01234567)
assert((0x12345678 << -8) == 0x00123456)
assert((0x12345678 << 32) == 0x1234567800000000)
assert((0x12345678 << -32) == 0)
assert((0x12345678 >> 4) == 0x01234567)
assert((0x12345678 >> 8) == 0x00123456)
assert((0x12345678 >> 32) == 0)
assert((0x12345678 >> -32) == 0x1234567800000000)
end

print("+")
-- some special cases
local c = {0, 1, 2, 3, 10, 0x80000000, 0xaaaaaaaa, 0x55555555,
           0xffffffff, 0x7fffffff}

for _, b in pairs(c) do
  assert(bit32.band(b) == b)
  assert(bit32.band(b, b) == b)
  assert(bit32.band(b, b, b, b) == b)
  assert(bit32.btest(b, b) == (b ~= 0))
  assert(bit32.band(b, b, b) == b)
  assert(bit32.band(b, b, b, ~b) == 0)
  assert(bit32.btest(b, b, b) == (b ~= 0))
  assert(bit32.band(b, bit32.bnot(b)) == 0)
  assert(bit32.bor(b, bit32.bnot(b)) == bit32.bnot(0))
  assert(bit32.bor(b) == b)
  assert(bit32.bor(b, b) == b)
  assert(bit32.bor(b, b, b) == b)
  assert(bit32.bor(b, b, 0, ~b) == 0xffffffff)
  assert(bit32.bxor(b) == b)
  assert(bit32.bxor(b, b) == 0)
  assert(bit32.bxor(b, b, b) == b)
  assert(bit32.bxor(b, b, b, b) == 0)
  assert(bit32.bxor(b, 0) == b)
  assert(bit32.bnot(b) ~= b)
  assert(bit32.bnot(bit32.bnot(b)) == b)
  assert(bit32.bnot(b) == (1 << 32) - 1 - b)
  assert(bit32.lrotate(b, 32) == b)
  assert(bit32.rrotate(b, 32) == b)
  assert(bit32.lshift(bit32.lshift(b, -4), 4) == bit32.band(b, bit32.bnot(0xf)))
  assert(bit32.rshift(bit32.rshift(b, 4), -4) == bit32.band(b, bit32.bnot(0xf)))
end

-- for this test, use at most 24 bits (mantissa of a single float)
-- XXX Kernel Lua: no floating-point tests
if not _KERNEL then
eval[[c = {0, 1, 2, 3, 10, 0x800000, 0xaaaaaa, 0x555555, 0xffffff, 0x7fffff}
for _, b in pairs(c) do
  for i = -40, 40 do
    local x = bit32.lshift(b, i)
    local y = math.floor(math.fmod(b * 2.0^i, 2.0^32))
    assert(math.fmod(x - y, 2.0^32) == 0)
  end
end]]
end

assert(not pcall(bit32.band, {}))
assert(not pcall(bit32.bnot, "a"))
assert(not pcall(bit32.lshift, 45))
assert(not pcall(bit32.lshift, 45, print))
assert(not pcall(bit32.rshift, 45, print))

print("+")


-- testing extract/replace

assert(bit32.extract(0x12345678, 0, 4) == 8)
assert(bit32.extract(0x12345678, 4, 4) == 7)
assert(bit32.extract(0xa0001111, 28, 4) == 0xa)
assert(bit32.extract(0xa0001111, 31, 1) == 1)
assert(bit32.extract(0x50000111, 31, 1) == 0)
assert(bit32.extract(0xf2345679, 0, 32) == 0xf2345679)

assert(not pcall(bit32.extract, 0, -1))
assert(not pcall(bit32.extract, 0, 32))
assert(not pcall(bit32.extract, 0, 0, 33))
assert(not pcall(bit32.extract, 0, 31, 2))

assert(bit32.replace(0x12345678, 5, 28, 4) == 0x52345678)
assert(bit32.replace(0x12345678, 0x87654321, 0, 32) == 0x87654321)
-- XXX Kernel Lua: no expo operator
if not _KERNEL then
eval[[assert(bit32.replace(0, 1, 2) == 2^2)')
assert(bit32.replace(0, -1, 4) == 2^4)]]
end
assert(bit32.replace(-1, 0, 31) == (1 << 31) - 1)
assert(bit32.replace(-1, 0, 1, 2) == (1 << 32) - 7)


-- testing conversion of floats
-- XXX Kernel Lua: no floating point tests
if not _KERNEL then
eval[[assert(bit32.bor(3.0) == 3)
assert(bit32.bor(-4.0) == 0xfffffffc)

-- large floats and large-enough integers?
if eval('return 2.0^50 < 2.0^50 + 1.0 and 2.0^50 < (-1 >> 1)') then
  eval('assert(bit32.bor(2.0^32 - 5.0) == 0xfffffffb)')
  eval('assert(bit32.bor(-2.0^32 - 6.0) == 0xfffffffa)')
  eval('assert(bit32.bor(2.0^48 - 5.0) == 0xfffffffb)')
  eval('assert(bit32.bor(-2.0^48 - 6.0) == 0xfffffffa)')
end
]]
end

print'OK'

