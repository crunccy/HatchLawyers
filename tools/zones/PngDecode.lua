--!strict
-- tools/zones/PngDecode.lua (installed as ServerStorage.EggV5Upload.PngDecode) - turns a PNG stored as base64 text into
-- RGBA pixels for an EditableImage, so tools/zones/BuildEggsV5.lua can upload the egg textures from data kept in the
-- place (2026-10-12: the place owner uploads them; no files needed on his machine).
-- Handles what Blender writes: 8-bit RGB / RGBA, not interlaced. Inflate after puff.c (zlib's reference decoder).
--   PngDecode.fromBase64(text) -> (width, height, rgba buffer)

local PngDecode = {}

local B64 = {}
do
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	for i = 1, 64 do
		B64[string.byte(chars, i)] = i - 1
	end
end

local function b64decode(s: string): buffer
	s = string.gsub(s, "[^%w%+/=]", "")
	local n = #s
	local pad = if string.sub(s, -2) == "==" then 2 elseif string.sub(s, -1) == "=" then 1 else 0
	local outLen = (n // 4) * 3 - pad
	local out = buffer.create(outLen)
	local o = 0
	for i = 1, n, 4 do
		local a, b, c, d = string.byte(s, i, i + 3)
		local v = B64[a] * 262144 + B64[b] * 4096 + (B64[c] or 0) * 64 + (B64[d] or 0)
		if o < outLen then
			buffer.writeu8(out, o, v // 65536)
		end
		if o + 1 < outLen then
			buffer.writeu8(out, o + 1, (v // 256) % 256)
		end
		if o + 2 < outLen then
			buffer.writeu8(out, o + 2, v % 256)
		end
		o += 3
	end
	return out
end

local POW = {}
for i = 0, 24 do
	POW[i] = 2 ^ i
end
local LBASE = { 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258 }
local LEXT = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0 }
local DBASE = { 1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577 }
local DEXT = { 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13 }
local CLORDER = { 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 }

-- canonical Huffman tables (counts per length, symbols in code order)
local function build(lengths: { [number]: number }, n: number): ({ [number]: number }, { [number]: number })
	local count = {}
	for len = 0, 15 do
		count[len] = 0
	end
	for sym = 0, n - 1 do
		local l = lengths[sym] or 0
		count[l] += 1
	end
	local offs = { [1] = 0 }
	for len = 1, 14 do
		offs[len + 1] = offs[len] + count[len]
	end
	local symbol = {}
	for sym = 0, n - 1 do
		local l = lengths[sym] or 0
		if l ~= 0 then
			symbol[offs[l]] = sym
			offs[l] += 1
		end
	end
	return count, symbol
end

local fixedL, fixedLS, fixedD, fixedDS
do
	local l = {}
	for i = 0, 143 do
		l[i] = 8
	end
	for i = 144, 255 do
		l[i] = 9
	end
	for i = 256, 279 do
		l[i] = 7
	end
	for i = 280, 287 do
		l[i] = 8
	end
	fixedL, fixedLS = build(l, 288)
	local d = {}
	for i = 0, 29 do
		d[i] = 5
	end
	fixedD, fixedDS = build(d, 30)
end

-- a zlib stream (src[start .. start+len-1]) -> exactly `outSize` bytes
local function inflate(src: buffer, start: number, outSize: number): buffer
	local out = buffer.create(outSize)
	local op = 0
	local pos = start + 2 -- (skip the zlib header)
	local bitbuf, bitcnt = 0, 0
	local nextYield = 2000000

	local function bits(n: number): number
		while bitcnt < n do
			bitbuf += buffer.readu8(src, pos) * POW[bitcnt]
			pos += 1
			bitcnt += 8
		end
		local p = POW[n]
		local v = bitbuf % p
		bitbuf = bitbuf // p
		bitcnt -= n
		return v
	end

	local function decode(count: { [number]: number }, symbol: { [number]: number }): number
		local code, first, index = 0, 0, 0
		for len = 1, 15 do
			if bitcnt == 0 then
				bitbuf = buffer.readu8(src, pos)
				pos += 1
				bitcnt = 8
			end
			code += bitbuf % 2
			bitbuf = bitbuf // 2
			bitcnt -= 1
			local c = count[len]
			if code - c < first then
				return symbol[index + (code - first)]
			end
			index += c
			first = (first + c) * 2
			code *= 2
		end
		error("PngDecode: bad Huffman code")
	end

	repeat
		local last = bits(1)
		local btype = bits(2)
		if btype == 0 then
			bitbuf, bitcnt = 0, 0 -- (to the next byte)
			local len = buffer.readu16(src, pos)
			pos += 4
			buffer.copy(out, op, src, pos, len)
			op += len
			pos += len
		elseif btype == 1 or btype == 2 then
			local lc, ls, dc, ds
			if btype == 1 then
				lc, ls, dc, ds = fixedL, fixedLS, fixedD, fixedDS
			else
				local nlen = bits(5) + 257
				local ndist = bits(5) + 1
				local ncode = bits(4) + 4
				local cl = {}
				for i = 0, 18 do
					cl[i] = 0
				end
				for i = 1, ncode do
					cl[CLORDER[i]] = bits(3)
				end
				local cc, cs = build(cl, 19)
				local lens = {}
				local i = 0
				while i < nlen + ndist do
					local sym = decode(cc, cs)
					if sym < 16 then
						lens[i] = sym
						i += 1
					else
						local rep, val = 0, 0
						if sym == 16 then
							val = lens[i - 1]
							rep = 3 + bits(2)
						elseif sym == 17 then
							rep = 3 + bits(3)
						else
							rep = 11 + bits(7)
						end
						for _ = 1, rep do
							lens[i] = val
							i += 1
						end
					end
				end
				local ll, dl = {}, {}
				for k = 0, nlen - 1 do
					ll[k] = lens[k]
				end
				for k = 0, ndist - 1 do
					dl[k] = lens[nlen + k]
				end
				lc, ls = build(ll, nlen)
				dc, ds = build(dl, ndist)
			end
			while true do
				local sym = decode(lc, ls)
				if sym < 256 then
					buffer.writeu8(out, op, sym)
					op += 1
				elseif sym == 256 then
					break
				else
					sym -= 257
					local len = LBASE[sym + 1] + bits(LEXT[sym + 1])
					local d = decode(dc, ds)
					local dist = DBASE[d + 1] + bits(DEXT[d + 1])
					local from = op - dist
					if dist >= len then
						buffer.copy(out, op, out, from, len)
					else
						for k = 0, len - 1 do
							buffer.writeu8(out, op + k, buffer.readu8(out, from + k))
						end
					end
					op += len
				end
				if op > nextYield then
					nextYield += 2000000
					task.wait()
				end
			end
		else
			error("PngDecode: bad block type")
		end
	until last == 1
	return out
end

function PngDecode.fromBase64(text: string): (number, number, buffer)
	local png = b64decode(text)
	local function u32(o: number): number
		return buffer.readu8(png, o) * 16777216 + buffer.readu8(png, o + 1) * 65536 + buffer.readu8(png, o + 2) * 256 + buffer.readu8(png, o + 3)
	end
	local pos = 8
	local w, h, depth, ctype, interlace = 0, 0, 0, 0, 0
	local idat, total = {}, 0
	while pos < buffer.len(png) do
		local len = u32(pos)
		local typ = buffer.readstring(png, pos + 4, 4)
		if typ == "IHDR" then
			w, h = u32(pos + 8), u32(pos + 12)
			depth, ctype, interlace = buffer.readu8(png, pos + 16), buffer.readu8(png, pos + 17), buffer.readu8(png, pos + 20)
		elseif typ == "IDAT" then
			table.insert(idat, { pos + 8, len })
			total += len
		elseif typ == "IEND" then
			break
		end
		pos += 12 + len
	end
	assert(depth == 8 and (ctype == 2 or ctype == 6) and interlace == 0, "PngDecode: needs an 8-bit RGB/RGBA PNG, not interlaced")
	local z = buffer.create(total)
	local zp = 0
	for _, c in idat do
		buffer.copy(z, zp, png, c[1], c[2])
		zp += c[2]
	end
	local bpp = if ctype == 6 then 4 else 3
	local stride = w * bpp
	local raw = inflate(z, 0, h * (stride + 1))
	local out = buffer.create(w * h * 4)
	local prev = buffer.create(stride)
	local cur = buffer.create(stride)
	for y = 0, h - 1 do
		local rp = y * (stride + 1)
		local ft = buffer.readu8(raw, rp)
		rp += 1
		for x = 0, stride - 1 do
			local v = buffer.readu8(raw, rp + x)
			if ft == 1 then
				if x >= bpp then
					v += buffer.readu8(cur, x - bpp)
				end
			elseif ft == 2 then
				v += buffer.readu8(prev, x)
			elseif ft == 3 then
				local a = if x >= bpp then buffer.readu8(cur, x - bpp) else 0
				v += (a + buffer.readu8(prev, x)) // 2
			elseif ft == 4 then
				local a = if x >= bpp then buffer.readu8(cur, x - bpp) else 0
				local b = buffer.readu8(prev, x)
				local c = if x >= bpp then buffer.readu8(prev, x - bpp) else 0
				local p = a + b - c
				local pa, pb, pc = math.abs(p - a), math.abs(p - b), math.abs(p - c)
				v += if pa <= pb and pa <= pc then a elseif pb <= pc then b else c
			end
			buffer.writeu8(cur, x, v % 256)
		end
		local o = y * w * 4
		for x = 0, w - 1 do
			local s = x * bpp
			buffer.writeu8(out, o, buffer.readu8(cur, s))
			buffer.writeu8(out, o + 1, buffer.readu8(cur, s + 1))
			buffer.writeu8(out, o + 2, buffer.readu8(cur, s + 2))
			buffer.writeu8(out, o + 3, if bpp == 4 then buffer.readu8(cur, s + 3) else 255)
			o += 4
		end
		prev, cur = cur, prev
		if y % 48 == 47 then
			task.wait()
		end
	end
	return w, h, out
end

return PngDecode
