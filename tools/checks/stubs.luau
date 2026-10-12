-- The few Roblox globals Shared.Config / Shared.Formulas touch, so they load under the plain Luau CLI
-- (tools/checks/run_checks.py). Config only builds Color3s; Formulas only takes a Random and requires Config.

Color3 = {}
local C3 = { __index = Color3 }
local function c3(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3) end
function Color3.new(r, g, b) return c3(r, g, b) end
function Color3.fromRGB(r, g, b) return c3((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end
function Color3.fromHex(h)
	h = string.gsub(h, "#", "")
	assert(#h == 6, "Color3.fromHex wants 6 hex digits, got " .. h)
	local r, g, b = tonumber(string.sub(h, 1, 2), 16), tonumber(string.sub(h, 3, 4), 16), tonumber(string.sub(h, 5, 6), 16)
	assert(r and g and b, "Color3.fromHex: not hex: " .. h)
	return Color3.fromRGB(r, g, b)
end
function Color3.fromHSV(h, s, v) return c3(v, v, v) end
function Color3.Lerp(a, b, t) return c3(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end

-- Roblox's Random: a seeded generator with NextNumber / NextInteger (a small LCG; reproducible per seed)
Random = {}
local RNG = { __index = Random }
function Random.new(seed)
	return setmetatable({ s = (seed or 1) % 2147483647 }, RNG)
end
function Random.NextNumber(self, lo, hi)
	self.s = (self.s * 48271) % 2147483647
	local u = self.s / 2147483647
	if lo == nil then return u end
	return lo + (hi - lo) * u
end
function Random.NextInteger(self, lo, hi)
	return lo + math.floor(Random.NextNumber(self) * (hi - lo + 1))
end
