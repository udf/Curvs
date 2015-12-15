function Initialize()
	PI2 = math.pi * 2

	iRingCount = getIntVar("RingCount", 1)
	if iRingCount <= 0 then iRingCount = 1 end
	iRingStart = getIntVar("RingStart", 60)

	-- Rebuild the skin if the ini says that we should
	if SKIN:GetVariable("Rebuild", "0") == "1" then
		rebuild()
	end

	tHoverHandler = {
		Ring = nil,
		Sect = nil,
		IsValid = function(self)
			return self.Ring ~= nil and self.Sect ~= nil
		end,
		
	}

	-- Set up variables for hit testing
	iSize = getIntVar("Size", 1)
	nHalfSize = iSize/2

	oMsMouseInfo = SKIN:GetMeasure("MeasureMouseInfo")
	oMsMouseX = SKIN:GetMeasure("MeasureMouseX")
	oMsMouseY = SKIN:GetMeasure("MeasureMouseY")

	oMtCenterText = SKIN:GetMeter("MeterCenterText")
	oMtCenter = SKIN:GetMeter("MeterCenter")
	fMouseIsOver = false

	tRings = {}
	--[[
		tRings = {
			[n] = // Each ring object is in an array index
			{
				Min, // Min radius of this ring
				Max, // Nax radius of this ring
				Count, // Number of sections in the ring
				[n] = // Each section object is in an array index
				{
					s, // String name of this section's meter
					o, // meter object of this section's meter
					Min, // Min angle
					Max, // Max angle
					Special, // True if Min is greater than Max (ie the section covers an area that overlaps angle = 0)
				},
			},
		}
	]]--
	local iCurrentRad = iRingStart
	for iRing=1,iRingCount do
		tRings[iRing] = {}
		tRings[iRing].Min = iCurrentRad
		iCurrentRad = iCurrentRad + getIntVar(("Ring%s.Size"):format(iRing), 50)
		tRings[iRing].Max = iCurrentRad

		local iCount = getIntVar(("Ring%s.Count"):format(iRing), 1)

		tRings[iRing].Count = iCount
		
		for iSect=1,iCount do
			tRings[iRing][iSect] = {}
			local o = tRings[iRing][iSect]

			o.s = ("Meter%s_%s"):format(iRing, iSect)
			local oMeter = SKIN:GetMeter(o.s)
			o.o = oMeter

			o.Min = correctRadians( tonumber(oMeter:GetOption("StartAngle")) )
			o.Max = correctRadians( o.Min + tonumber(oMeter:GetOption("RotationAngle")) )

			o.Special = (o.Min > o.Max)
		end
	end
end

function Update()
	-- Only hit test if the mouse is in the client area of our skin and the mouse is over our skin
	if oMsMouseInfo:GetValue() ~= 1 or not fMouseIsOver then
		return
	end

	-- Cursor position relative to the client area of our skin's window
	local iMouseX = oMsMouseX:GetValue()
	local iMouseY = oMsMouseY:GetValue()

	local iRing, iSect = hitTest(iMouseX, iMouseY)

	if iRing ~= nil and iSect ~= nil then 
		SKIN:Bang("!SetOption", "MeterCenterText", "Text", ("%ss%s"):format(iRing, iSect))
	else
		SKIN:Bang("!SetOption", "MeterCenterText", "Text", "")
	end
end

function onHover()
	oMtCenter:Show()
	oMtCenterText:Show()
	fMouseIsOver = true
end

function onLeave()
	oMtCenter:Hide()
	oMtCenterText:Hide()
	fMouseIsOver = false
end

function hitTest(iX, iY)
	-- Cursor position relative to a Cartesian plane whose origin is at the center of client area of our skin's window
	local iCX = iX - nHalfSize
	local iCY = -(iY - nHalfSize)
	-- Cursor position in polar coordinates relative to the above values
	local nRadius = math.sqrt(iCX^2 + iCY^2)
	local nTheta = correctRadians( -(math.atan2(iCY, iCX)) )

	local iRing = nil
	local iSect = nil

	-- Attempt to find out which ring the cursor is over
	for i=1,iRingCount do
		if nRadius >= tRings[i].Min and nRadius <= tRings[i].Max then
			iRing = i
			break
		end
	end

	-- Attempt to find out which section the cursor is over
	if iRing ~= nil then
		for i=1,tRings[iRing].Count do
			local o = tRings[iRing][i]

			if (nTheta >= o.Min and nTheta <= o.Max) or (o.Special and (nTheta >= o.Min or nTheta <= o.Max)) then
				iSect = i
				break
			end			
		end
	end

	return iRing, iSect
end

function correctRadians(nRad)
	local n = nRad % PI2
	if n < 0 then n = PI2 + n end
	return n
end

function rebuild()
	-- TODO: Clean this function up

	-- If rebuild was selected from the context menu then we should refresh the skin (to reload the variables) and then rebuild the meters
	if SKIN:GetVariable("Rebuild", "0") ~= "1" then
		-- Write a key to the ini so that we know next time that we should rebuild the meters
		SKIN:Bang('!WriteKeyValue', 'Variables', 'Rebuild', "1")
		SKIN:Bang('!Refresh')
		return
	end

	-- Revert the key to 0 to prevent an infinite loop (which is not as fun as it seems)
	SKIN:Bang('!WriteKeyValue', 'Variables', 'Rebuild', "0")
	print("Rebuild called")

	local iStartPos = iRingStart
	local tIniData = {}
	local tIniData2 = {}

	-- Create the first circular border
	tIniData2[ ("MeterCircle0"):format(iRing, iSect) ] = {
		["Meter"] = "Roundline",
		["MeterStyle"] = "StyleSection",
		["StartAngle"] = "0",
		["RotationAngle"] = tostring(PI2),
		["LineStart"] = tostring(iStartPos),
		["LineLength"] = tostring(iStartPos + 2),
		["LineColor"] = "#BorderColor#",
		["UpdateDivider"] = "-1",
	}

	for iRing=1,iRingCount do
		local iCount = getIntVar(("Ring%s.Count"):format(iRing), 1)
		local iSize = getIntVar(("Ring%s.Size"):format(iRing), 50)
		local nOffset = SKIN:ParseFormula(SKIN:GetVariable(("Ring%s.Offset"):format(iRing), 0))
		if nOffset == nil then nOffset = 0 end
		local iEndPos = iStartPos + iSize

		-- Create the circular border that is around this ring
		tIniData2[ ("MeterCircle" .. iRing):format(iRing, iSect) ] = {
			["Meter"] = "Roundline",
			["MeterStyle"] = "StyleSection",
			["StartAngle"] = "0",
			["RotationAngle"] = tostring(PI2),
			["LineStart"] = tostring(iEndPos),
			["LineLength"] = tostring(iEndPos + 2),
			["LineColor"] = "#BorderColor#",
			["UpdateDivider"] = "-1",
		}

		for iSect=1,iCount do
			local iStartAngle = PI2 / iCount * (iSect-1) + nOffset

			-- Create the clickable section
			tIniData[ ("Meter%s_%s"):format(iRing, iSect) ] = {
				["Meter"] = "Roundline",
				["MeterStyle"] = "StyleSection",
				["StartAngle"] = tostring(iStartAngle),
				["RotationAngle"] = tostring(PI2 / iCount),
				["LineStart"] = tostring(iStartPos),
				["LineLength"] = tostring(iEndPos),
				["LineColor"] = "0,0,0,1",
				["HoverColor"] = hslToRgb(iSect/iCount, 0.7, 0.75) .. ",150",
			}

			-- Create the border for this section
			if iCount > 1 then
				tIniData2[ ("Meter%s_%s_border"):format(iRing, iSect) ] = {
					["Meter"] = "Roundline",
					["MeterStyle"] = "StyleSection",
					["StartAngle"] = tostring(iStartAngle),
					["RotationAngle"] = tostring(PI2 / iCount),
					["LineStart"] = tostring(iStartPos),
					["LineLength"] = tostring(iEndPos),
					["LineColor"] = "#BorderColor#",
					["Solid"] = "0",
					["LineWidth"] = "2",
					["UpdateDivider"] = "-1",
				}
			end
		end

		iStartPos = iEndPos
	end

	tIniData["Variables"] = {
		["Size"] = tostring(iStartPos * 2 + 4)
	}

	WriteIni(tIniData, SKIN:GetVariable("@") .. "Meters.inc")
	WriteIni(tIniData2, SKIN:GetVariable("@") .. "Meters2.inc")
	SKIN:Bang('!Refresh')
end

-- From https://docs.rainmeter.net/snippets/write-ini/
function WriteIni(inputtable, filename)
	assert(type(inputtable) == 'table', ('WriteIni must receive a table. Received %s instead.'):format(type(inputtable)))

	local file = assert(io.open(filename, 'w+'), 'Unable to open ' .. filename)
	local lines = {}

	for section, contents in pairs(inputtable) do
		table.insert(lines, ('\[%s\]'):format(section))
		for key, value in pairs(contents) do
			table.insert(lines, ('%s=%s'):format(key, value))
		end
		table.insert(lines, '')
	end

	file:write(table.concat(lines, '\n'))
	file:close()
end

-- Gets a variable with SKIN:GetVariable and rounds it down to an integer
function getIntVar(sVar, iDefault)
	return math.floor(SKIN:GetVariable(sVar, iDefault))
end

function hslToRgb(h, s, l)
	function hue2rgb(p, q, t)
		if t < 0	 then t = t + 1 end
		if t > 1	 then t = t - 1 end
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