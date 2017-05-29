-- Helper functions
-- Returns a rainmeter variable rounded down to an integer
function RmGetInt(sVar, iDefault)
	return math.floor(SKIN:GetVariable(sVar, iDefault))
end

-- Returns a rainmeter variable rounded down to an integer, negative integers are converted to positive ones
function RmGetUInt(sVar, iDefault)
	return math.abs(RmGetInt(sVar, iDefault))
end

-- Returns a rainmeter variable represented as a (floating point) number
function RmGetNumber(sVar, iDefault)
	return number(SKIN:GetVariable(sVar, iDefault))
end

-- Converts a hsl color [0-1, 0-1, 0-1] to an rgb color [0-255, 0-255, 0-255]
function HSLtoRGB(h, s, l)
	function hue2rgb(p, q, t)
		if t < 0 then t = t + 1 end
		if t > 1 then t = t - 1 end
		if t < 1/6 then return p + (q - p) * 6 * t end
		if t < 1/2 then return q end
		if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
		return p
	end

	local r, g, b

	if s == 0 then
		r, g, b = l, l, l
	else
		local q
		if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
		local p = 2 * l - q

		r = hue2rgb(p, q, h + 1/3)
		g = hue2rgb(p, q, h)
		b = hue2rgb(p, q, h - 1/3)
	end

	return math.floor(r * 255) .. "," .. math.floor(g * 255) .. "," .. math.floor(b * 255)
end

-- Converts hex colors to RGB, stripping the alpha value in the process
function StripAlpha(color)
	if color:find(",") ~= nil then
		if color:match("%d+,%d+,%d+") ~= nil then
			-- RGB with/without alpha
			return color:match("%d+,%d+,%d+")
		end
	else
		if (color:len() == 8 or color:len() == 6) and color:match("%x+") == color then
			if color:len() == 8 then
				-- Hex with alpha, strip the alpha
				color = color:sub(1, 6)
			end
			-- The length of color is now 6 and it is a rgb hex color

			local rgb = ""

			for hex in color:gmatch('..') do
				rgb = rgb .. "," .. tonumber(hex, 16)
			end

			return rgb:sub(2)
		end
	end

	return nil
end