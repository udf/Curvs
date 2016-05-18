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
	tC.f.Meter = function(s1, s2) return ("Section%s_%s"):format(s1, s2) end
	tC.f.Border = function(s1, s2) return ("Border%s_%s"):format(s1, s2) end
	tC.f.CircleBorder = function(s1) return ("CircleBorder%s"):format(s1) end
	tC.f.RingMeterPre = function(s1) return ("Ring%s."):format(s1) end
	tC.f.ConfigPre = function(s1, s2) return ("%ss%s"):format(s1, s2) end

	tC.m = {} -- Meters and measures
	tC.m.CenterText = SKIN:GetMeter("CenterText")

	tC.a = {} -- Animation constants
	tC.a.SectionFadeInStep = 42
	tC.a.SectionFadeOutStep = 21
	tC.a.SectionMaxAlpha = 225


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
		HalfSize = RmGetInt("Size", 1) / 2,

		last = {
			ring = nil,
			sect = nil,
			isValid = function()
				return tHT.last.ring ~= nil and tHT.last.sect ~= nil
			end
		},

		Mouse = {
			isOver = false, -- True if the mouse if over our skin
			oX = SKIN:GetMeasure("MouseX"),
			oY = SKIN:GetMeasure("MouseY"),
			oldX = nil,
			oldY = nil,
		},

		animators = {}, -- Each section gets an animator object, store them here for easy access later on
		cache = {}
	}

	-- Build the hit testing cache
	--[[
		cache = {
			[n] = { // Each ring is in an array index
				Min, // Min radius of this ring
				Max, // Max radius of this ring
				Count, // Number of sections in the ring
				[n] = { // Each section is in an array index
					sM, // String name of this section's meter
					oM, // meter object of this section's meter
					Min, // Min angle
					Max, // Max angle
					Special, // True if Min is greater than Max (ie the section covers an area that overlaps angle = 0)
					Col, // The color of this section
					Image, // The image to show when this section is selected
					Bang, // The bang to execute when this section is clicked
					Animator, // Animator object that controls the fade in/out of this section
				},
			},
		}
	]]--
	local iCurRad = tC.StartRadius
	for iRing=1,tC.Count do
		local sPre = tC.f.RingMeterPre(iRing)
		tHT.cache[iRing] = {}
		tHT.cache[iRing].Min = iCurRad
		iCurRad = iCurRad + RmGetUInt(sPre .. "Size", 50)
		tHT.cache[iRing].Max = iCurRad

		local iCount = RmGetUInt(sPre .. "Count", 1)
		if iCount == 0 then iCount = 1 end

		tHT.cache[iRing].Count = iCount
		
		for iSect=1,iCount do
			tHT.cache[iRing][iSect] = {}
			local o = tHT.cache[iRing][iSect]

			o.sM = tC.f.Meter(iRing, iSect)
			o.oM = SKIN:GetMeter(o.sM)

			o.Min = ReMapRadians( tonumber(o.oM:GetOption("StartAngle")) )
			o.Max = ReMapRadians( o.Min + tonumber(o.oM:GetOption("RotationAngle")) )

			o.Special = (o.Min > o.Max)

			local sPre = tC.f.ConfigPre(iRing, iSect)
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
			o.Animator:SetTarget(1, 3)
			table.insert(tHT.animators, o.Animator)
		end
	end

	function tHT:Update()
		-- Only hit test if the mouse is over our skin
		if not self.Mouse.isOver then return end

		-- Get the current cursor position
		local iX = self.Mouse.oX:GetValue()
		local iY = self.Mouse.oY:GetValue()

		-- Skip hit testing if the previous update cycle already processed these coordinates
		if self.oldX == iX and self.oldY == iY then return end
		self.oldX = iX
		self.oldY = iY		

		-- Cursor position relative to a Cartesian plane whose origin is at the center of client area of our skin's window
		local iCX = iX - self.HalfSize
		local iCY = -(iY - self.HalfSize)
		-- Cursor position in polar coordinates relative to the above values
		local nRadius = math.sqrt(iCX^2 + iCY^2)
		local nTheta = ReMapRadians( -(math.atan2(iCY, iCX)) )

		local iRing = nil
		local iSect = nil

		-- Attempt to find out which ring the cursor is over
		for i=1,tC.Count do
			if nRadius >= self.cache[i].Min and nRadius <= self.cache[i].Max then
				iRing = i
				break
			end
		end

		-- Attempt to find out which section the cursor is over
		if iRing ~= nil then
			--Single sectioned ring, we are definitely over the only section
			if self.cache[iRing].Count == 1 then
				iSect = 1
			else
				for i=1,self.cache[iRing].Count do
					local o = self.cache[iRing][i]

					if (nTheta >= o.Min and nTheta <= o.Max) or (o.Special and (nTheta >= o.Min or nTheta <= o.Max)) then
						iSect = i
						break
					end			
				end
			end
		end

		if iRing ~= nil and iSect ~= nil then
			if iRing ~= self.last.ring or iSect ~= self.last.sect then
				if self.last.isValid() then
					self.cache[self.last.ring][self.last.sect].Animator:SetTarget(1, tC.a.SectionFadeOutStep)

					if self.cache[self.last.ring][self.last.sect].Image ~= "" then
						ShowFader(self.cache[self.last.ring][self.last.sect].Image)
					end
				end

				self.cache[iRing][iSect].Animator:SetTarget(tC.a.SectionMaxAlpha, tC.a.SectionFadeInStep)
				if self.cache[iRing][iSect].Image == "" then
					SKIN:Bang("!SetOption", "CenterText", "Text", ("%ss%s"):format(iRing, iSect))
					HideImage()
				else
					SKIN:Bang("!SetOption", "CenterText", "Text", "")
					ShowImage(self.cache[iRing][iSect].Image)
				end
			end
			
			self.last.ring = iRing
			self.last.sect = iSect
		else
			SKIN:Bang("!SetOption", "CenterText", "Text", "")
		end
	end
end



function Update()
	tHT:Update()

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
function onHover()
	tHT.Mouse.isOver = true
	tC.m.CenterText:Show()
end
function onLeave()
	tHT.Mouse.isOver = false
	tC.m.CenterText:Hide()
	HideImage()

	if tHT.last.isValid() then
		tHT.cache[tHT.last.ring][tHT.last.sect].Animator:SetTarget(1, tC.a.SectionFadeOutStep)

		tHT.last.ring = nil
		tHT.last.sect = nil
	end
end
function onClick()
	if tHT.last.isValid() then
		if tHT.cache[tHT.last.ring][tHT.last.sect].Bang ~= "" then
			SKIN:Bang(tHT.cache[tHT.last.ring][tHT.last.sect].Bang)
		end
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

			o = oMeters:NewSection( tC.f.Meter(iRing, iSect) )
				o:AddKey("Meter", "Roundline")
				o:AddKey("MeterStyle", "Section")
            o:AddKey("StartAngle", nStartAngle + nBorderOffset)
            o:AddKey("RotationAngle", PI2 / iCount - nBorderOffset*2)
				o:AddKey("LineStart", iCurRad)
				o:AddKey("LineLength", iEndRadius)
				o:AddKey("HoverColor", HSLtoRGB(iSect/iCount, 0.7, 0.75))
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