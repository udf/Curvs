function Initialize()
	dofile(SKIN:GetVariable('@') .. "Dofiles\\class.lua")
	dofile(SKIN:GetVariable('@') .. "Dofiles\\inibuilder.lua")
	dofile(SKIN:GetVariable('@') .. "Dofiles\\utilities.lua")

	-- Rebuild the skin if the ini says that we should
	if RmGetInt("Rebuild", 0) == 1 then
		rebuild()
	end
end

function rebuild()
	-- If rebuild was selected from the context menu then we should refresh the skin (to reload the variables) and then rebuild the meters
	if RmGetInt("Rebuild", 0) ~= 1 then
		-- Write a key to the ini so that we know next time that we should call this function to rebuild the meters
		SKIN:Bang("!WriteKeyValue", "Variables", "Rebuild", "1")
		SKIN:Bang("!Refresh")
		return
	end
	-- Revert the key to 0 to prevent an infinite loop (which is not as fun as it seems)
	SKIN:Bang("!WriteKeyValue", "Variables", "Rebuild", "0")

	local Arc = function(radiusStart, radiusEnd, angleStart, angleEnd)
		angleEnd = math.rad(angleEnd)
		angleStart = math.rad(angleStart)
		local radiusMid = (radiusStart + radiusEnd)/2
		return ("Arc %.2f,%.2f,%.2f,%.2f,%.2f,%.2f | StrokeWidth %.2f"):format(
			radiusMid*math.cos(angleStart), radiusMid*math.sin(angleStart), 
			radiusMid*math.cos(angleEnd), radiusMid*math.sin(angleEnd), 
			radiusMid, radiusMid, radiusEnd - radiusStart)
	end

	local Ellipse = function(radius)
		return ("Ellipse 0,0,%.2f | Extend OffsetTransform,StyleAttributes"):format(radius)
	end
	local Line = function(radiusStart, radiusEnd, angle)
		angle = math.rad(angle)
		return ("Line %.2f,%.2f,%.2f,%.2f | Extend OffsetTransform,StyleAttributes"):format(
			radiusStart*math.cos(angle), radiusStart*math.sin(angle), 
			radiusEnd*math.cos(angle), radiusEnd*math.sin(angle)
			)
	end

	local ringCount = RmGetUInt("RingCount", 1)
	if ringCount == 0 then ringCount = 1 end
	local currentRadius = RmGetUInt("RingCenterSize", 60)
	if currentRadius == 0 then currentRadius = 60 end

	local oMeters = iniBuilder()
	local oBorders = oMeters:NewSection("borders")
	oBorders:AddKey("Meter", "Shape")
	oBorders:AddKey("MeterStyle", "StyleBorder")
	oBorders:AddKey("Shape", Ellipse(currentRadius))
	local borderShapeIndex = 2

	for ring=1,ringCount do
		local prefix = ("Ring%s"):format(ring)
		local buttonCount = RmGetUInt(prefix .. ".Count", 1)
		if buttonCount == 0 then buttonCount = 1 end
		local ringSize = RmGetUInt(prefix .. ".Size", 50)
		if ringSize == 0 then ringSize = 50 end
		local buttonOffset = SKIN:ParseFormula( SKIN:GetVariable(prefix .. ".Offset", 0) )
		if buttonOffset == nil then buttonOffset = 0 end
		local endRadius = currentRadius + ringSize

		for button=1,buttonCount do
			local angleIncrement = 360 / buttonCount
			local o = oMeters:NewSection(("%ss%s"):format(ring, button))
				o:AddKey("Meter", "Shape")
				o:AddKey("MeterStyle", "StyleButton")
				o:AddKey("Shape", Arc(currentRadius, endRadius, (button-1) * angleIncrement + buttonOffset, button * angleIncrement + buttonOffset) .. " | Extend OffsetTransform,StyleAttributes")
				o:AddKey("StyleAttributes", ("Stroke Color %s"):format(HSLtoRGB(button/buttonCount, 0.7, 0.75)))
			o:Commit()

			oBorders:AddKey("Shape" .. borderShapeIndex, Line(currentRadius, endRadius, button * angleIncrement + buttonOffset))
			borderShapeIndex = borderShapeIndex + 1
		end

		currentRadius = endRadius
		oBorders:AddKey("Shape" .. borderShapeIndex, Ellipse(currentRadius))
		borderShapeIndex = borderShapeIndex + 1
	end

	oBorders:Commit()

	o = oMeters:NewSection("Variables")
		o:AddKey("ButtonShift", currentRadius)
	o:Commit()

	-- Write the file
	local file = io.open(SKIN:GetVariable("@") .. "buttons.inc", "w")
	file:write(oMeters:ToString())
	file:close()

	-- Reload the skin
	SKIN:Bang("!Refresh")
end