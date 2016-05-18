function Initialize()
	-- Prevent always multiplying PI by 2 in the rest of the code (minor performance boost) by doing it now
	PI2 = math.pi * 2

	-- Configuration variables
	tC = {}
	tC.Count = RmGetUInt("RingCount", 1)
	if tC.Count == 0 then tC.Count = 1 end
	tC.StartRadius = RmGetUInt("RingCenterSize", 60)
	if tC.StartRadius == 0 then tC.StartRadius = 60 end
	tC.iBorderTk = 2

	tC.f = {} -- Formatting functions
	tC.f.Meter = function(s1, s2) return ("%ss%s"):format(s1, s2) end
	tC.f.Border = function(s1, s2) return ("b%s_%s"):format(s1, s2) end
	tC.f.CircleBorder = function(s1) return ("cb%s"):format(s1) end
	tC.f.RingMeterPre = function(s1) return ("Ring%s."):format(s1) end

	tC.m = {} -- Meters and measures
	tC.m.CenterText = SKIN:GetMeter("CenterText")

	tC.a = {} -- Animation constants
	tC.a.SectionFadeInStep = 42
	tC.a.SectionFadeOutStep = 21
	tC.a.SectionMaxAlpha = 255


	-- Class definitions
	-- iniBuilder: Assists with creating a structured ini
	iniBuilder = class(function(o)
		o.tData = {}
	end)
	function iniBuilder:NewSection(sSectionName)
		-- iniSectionBuilder: Sub class of iniBuilder, Assists with creating a structured ini section
		iniSectionBuilder = class(function(o, sSectionName, oParent)
			o.oParent = oParent
			o.tData = {}
			table.insert(o.tData, ("\[%s\]"):format(sSectionName))
		end)
		function iniSectionBuilder:AddKey(sKey, sVal)
			table.insert(self.tData, ("%s=%s"):format(sKey, sVal))
		end
		function iniSectionBuilder:Commit()
			local iParentSize = #self.oParent.tData
			for i=1,#self.tData do
				self.oParent.tData[iParentSize + i] = self.tData[i]
			end
		end

		return iniSectionBuilder(sSectionName, self)
	end
	function iniBuilder:ToString()
		return table.concat(self.tData, "\n")
	end

	-- Animator: Animates a value from nItitial to nTarget iFrames times, allows changing nTarget and iFrames mid animation
	Animator = class(function(o, nItitial, nStep, updateFunc)
		o.nCurrent = nItitial
		o.nTarget = nItitial
		o.nStep = nStep
		o.updateFunc = updateFunc
		o.running = false
	end)
	-- Sets a new target for the animator
	function Animator:SetTarget(nTarget, nStep)
		if nTarget == nil then return false end
		if nStep ~= nil then
			self.nStep = nStep
		end
		self.nTarget = nTarget

		if self.nCurrent < nTarget then
			-- Make nStep positive
			if self.nStep < 0 then self.nStep = -(self.nStep) end
		elseif self.nCurrent > nTarget then
			-- Make nStep negative
			if self.nStep > 0 then self.nStep = -(self.nStep) end
		end

		self.running = true

		return true
	end
	-- Steps the animator one frame up and returns the new value, optionally calling self.updateFunc if it is a valid function
	function Animator:Update()
		if self.running then 
			self.nCurrent = self.nCurrent + self.nStep

			if (self.nStep > 0 and self.nCurrent >= self.nTarget) or (self.nStep < 0 and self.nCurrent <= self.nTarget) then
				self.nCurrent = self.nTarget
				self.running = false
			end
		end

		if type(self.updateFunc) == "function" then self.updateFunc(self.nCurrent) end
		return self.nCurrent
	end



	-- Rebuild the skin if the ini says that we should
	if RmGetInt("Rebuild", 0) == 1 then
		rebuildSkin()
	end


	-- Create an animator for the center image
	oCenterAnim = Animator(
		0,
		tC.a.SectionFadeOutStep,
		AnimateImage
	)
	-- Create an animator for the fade center image
	oCenterFadeAnim = Animator(
		0,
		tC.a.SectionFadeOutStep,
		AnimateFader
	)


	-- Set up hit testing
	tHT = {
		animators = {},
		cache = {},
		last = nil
	}

	for iRing=1,tC.Count do
		local sPre = tC.f.RingMeterPre(iRing)

		local iCount = RmGetUInt(sPre .. "Count", 1)
		if iCount == 0 then iCount = 1 end
		
		for iSect=1,iCount do
			tHT.cache[tC.f.Meter(iRing, iSect)] = {}
			local o = tHT.cache[tC.f.Meter(iRing, iSect)]

			o.sM = tC.f.Meter(iRing, iSect)
			o.oM = SKIN:GetMeter(o.sM)

			local sPre = o.sM
			o.Col = StripAlpha(SKIN:GetVariable(sPre .. "Color", ""))
			if o.Col == nil then
				o.Col = o.oM:GetOption("HoverColor")
			end

			o.Image = SKIN:GetVariable(sPre .. "Image", "")

			o.Bang = SKIN:GetVariable(sPre .. "Bang", "")

			o.Animator = Animator(
					tC.a.SectionMaxAlpha,
					tC.a.SectionFadeOutStep,
					function(nVal)
						SKIN:Bang("!SetOption", o.sM, "LineColor", o.Col .. "," .. math.floor(nVal))
					end
				)
			o.Animator:SetTarget(1, 5)
			table.insert(tHT.animators, o.Animator)
		end
	end
end



function Update()
	oCenterAnim:Update()
	oCenterFadeAnim:Update()

	for i=1,#tHT.animators do
		tHT.animators[i]:Update()
	end
end



function HideImage()
	oCenterAnim:SetTarget(0, tC.a.SectionFadeInStep)
end
function ShowImage(sImageName)
	SKIN:Bang("!SetOption", "Center", "ImageName", sImageName)
	oCenterAnim:SetTarget(255, tC.a.SectionFadeInStep)
end
function ShowFader(sImageName)
	SKIN:Bang("!SetOption", "CenterFade", "ImageName", sImageName)
	SKIN:Bang("!SetOption", "CenterFade", "ImageAlpha", 255)
	oCenterFadeAnim.nCurrent = 255
	oCenterFadeAnim:SetTarget(0, tC.a.SectionFadeInStep)
end
function AnimateImage(nAlpha)
	SKIN:Bang("!SetOption", "Center", "ImageAlpha", math.floor(nAlpha))
end
function AnimateFader(nAlpha)
	SKIN:Bang("!SetOption", "CenterFade", "ImageAlpha", math.floor(nAlpha))
end



-- Mouse events
function onHover(sMeter)
	--print("onHover: " .. sMeter)
	tHT.cache[sMeter].Animator:SetTarget(tC.a.SectionMaxAlpha, tC.a.SectionFadeInStep)

	if tHT.cache[sMeter].Image == "" then
		SKIN:Bang("!SetOption", "CenterText", "Text", sMeter)
		HideImage()
	else
		SKIN:Bang("!SetOption", "CenterText", "Text", "")
		ShowImage(tHT.cache[sMeter].Image)
	end

	tHT.last = sMeter
end
function onLeave(sMeter)
	--print("onLeave: " .. sMeter)
	tHT.cache[sMeter].Animator:SetTarget(1, tC.a.SectionFadeOutStep)

	if tHT.cache[tHT.last].Image == tHT.cache[sMeter].Image then
		HideImage()
	end
	if tHT.cache[sMeter].Image ~= "" then
		ShowFader(tHT.cache[sMeter].Image)
	end

	SKIN:Bang("!SetOption", "CenterText", "Text", "")
end
function onClick(sMeter)
	--print("onClick: " .. sMeter)
	if tHT.cache[sMeter].Bang ~= "" then
		SKIN:Bang(tHT.cache[sMeter].Bang)
	end
end



function rebuildSkin()
	-- If rebuild was selected from the context menu then we should refresh the skin (to reload the variables) and then rebuild the meters
	if RmGetInt("Rebuild", 0) ~= 1 then
		-- Write a key to the ini so that we know next time that we should call this function to rebuild the meters
		SKIN:Bang("!WriteKeyValue", "Variables", "Rebuild", "1")
		SKIN:Bang("!Refresh")
		return
	end
	-- Revert the key to 0 to prevent an infinite loop (which is not as fun as it seems)
	SKIN:Bang("!WriteKeyValue", "Variables", "Rebuild", "0")

	local iCurRad = tC.StartRadius -- Current radius
	local oMeters = iniBuilder() -- iniBuilder for the meters
	local oBorders = iniBuilder() -- iniBuilder for the borders
	local sMeters = ""

	-- Create first circle border
	local o = oBorders:NewSection( tC.f.CircleBorder(0) )
		o:AddKey("Meter", "Roundline")
		o:AddKey("MeterStyle", "Section|CircleBorder")
		o:AddKey("LineStart", iCurRad)
		o:AddKey("LineLength", iCurRad + tC.iBorderTk)
	o:Commit()

	for iRing=1,tC.Count do
		local sPre = tC.f.RingMeterPre(iRing)
		local iCount = RmGetUInt(sPre .. "Count", 1)
		if iCount == 0 then iCount = 1 end
		local iSize = RmGetUInt(sPre .. "Size", 50)
		if iSize == 0 then iSize = 50 end
		local nOffset = SKIN:ParseFormula( SKIN:GetVariable(sPre .. "Offset", 0) )
		if nOffset == nil then nOffset = 0 end
		local iEndRadius = iCurRad + iSize

		-- Create the circle border that goes around the outside of this ring
		o = oBorders:NewSection( tC.f.CircleBorder(iRing) )
			o:AddKey("Meter", "Roundline")
			o:AddKey("MeterStyle", "Section|CircleBorder")
			o:AddKey("LineStart", iEndRadius)
			o:AddKey("LineLength", iEndRadius + tC.iBorderTk)
		o:Commit()

		for iSect=1,iCount do
			local nStartAngle = PI2 / iCount * (iSect-1) + nOffset
			local nBorderOffset = (tC.iBorderTk / (PI2 * iEndRadius)) * math.pi
			if iCount <= 1 then nBorderOffset = 0 end

			sMeters = sMeters .. tC.f.Meter(iRing, iSect) .. " "
			o = oMeters:NewSection( tC.f.Meter(iRing, iSect) )
				o:AddKey("Meter", "Roundline")
				o:AddKey("MeterStyle", "Section")
				o:AddKey("StartAngle", nStartAngle + nBorderOffset)
				o:AddKey("RotationAngle", PI2 / iCount - nBorderOffset*2)
				o:AddKey("LineStart", iCurRad)
				o:AddKey("LineLength", iEndRadius)
				o:AddKey("HoverColor", HSLtoRGB(iSect/iCount, 0.7, 0.75))

				o:AddKey("OverAction", "[!CommandMeasure \"Lua\" \"onHover('#CURRENTSECTION#')\"]")
				o:AddKey("LeaveAction", "[!CommandMeasure \"Lua\" \"onLeave('#CURRENTSECTION#')\"]")
				o:AddKey("ClickAction", "[!CommandMeasure \"Lua\" \"onClick('#CURRENTSECTION#')\"]")
			o:Commit()

			if iCount > 1 then
				o = oBorders:NewSection( tC.f.Border(iRing, iSect) )
					o:AddKey("Meter", "Roundline")
					o:AddKey("MeterStyle", "Section|LineBorder")
					o:AddKey("StartAngle", nStartAngle)
					o:AddKey("RotationAngle", PI2 / iCount)
					o:AddKey("LineStart", iCurRad)
					o:AddKey("LineLength", iEndRadius)
					o:AddKey("LineWidth", tC.iBorderTk)
				o:Commit()
			end
		end

		iCurRad = iEndRadius + tC.iBorderTk
	end

	o = oBorders:NewSection("Variables")
		o:AddKey("Size", iCurRad * 2 + tC.iBorderTk*2)
	o:Commit()

	-- Write the file
	local file = io.open(SKIN:GetVariable("@") .. "Meters.inc", "w+")
	file:write( oMeters:ToString() .. "\n" .. oBorders:ToString() )
	file:close()

	SKIN:Bang("!WriteKeyValue", "HitTester", "Meters", sMeters)	

	-- Reload the skin
	SKIN:Bang("!Refresh")
end



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

-- Rounds a number to iDp decimal places
function round(nNum, iDp)
	local nMultFactor = 10^(iDp or 0)
	return math.floor(nNum * nMultFactor + 0.5) / nMultFactor
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

-- re-maps an angle in radians to the range 0-2PI
function ReMapRadians(nRad)
	local n = nRad % PI2
	if n < 0 then n = PI2 + n end
	return n
end

-- Converts HEX colors to RGB, stripping the alpha value in the process
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



-- class.lua
-- Compatible with Lua 5.1 (not 5.0).
function class(base, init)
	local c = {}	 -- a new class instance
	if not init and type(base) == "function" then
		init = base
		base = nil
	elseif type(base) == "table" then
	 -- our new class is a shallow copy of the base class!
		for i,v in pairs(base) do
			c[i] = v
		end
		c._base = base
	end
	-- the class will be the metatable for all its objects,
	-- and they will look up their methods in it.
	c.__index = c

	-- expose a constructor which can be called by <classname>(<args>)
	local mt = {}
	mt.__call = function(class_tbl, ...)
	local obj = {}
	setmetatable(obj,c)
	if init then
		init(obj,...)
	else 
		-- make sure that any stuff from the base class is initialized!
		if base and base.init then
		base.init(obj, ...)
		end
	end
	return obj
	end
	c.init = init
	c.is_a = function(self, klass)
		local m = getmetatable(self)
		while m do 
			if m == klass then return true end
			m = m._base
		end
		return false
	end
	setmetatable(c, mt)
	return c
end