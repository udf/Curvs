function Initialize()
	PI2 = math.pi * 2

	local sMeters = SELF:GetOption("Meters")
	local tMeters = Split(sMeters, " ")

	tM = {}

	for i, sMeter in ipairs(tMeters) do
		local oMeter = SKIN:GetMeter(sMeter)
		if oMeter ~= nil then
			if oMeter:GetOption("Meter"):lower() == "roundline" then
				tM[sMeter] = {}
				tM[sMeter].o = oMeter
				tM[sMeter].s = sMeter

				tM[sMeter].fOver = false
			else
				print("Roundline.lua: Invalid meter, " .. sMeter .. " is not a Roundline meter")
			end
		else
			print("Roundline.lua: Invalid meter, " .. sMeter .. " is not a valid meter")
		end
	end

	oMouse = {}
	oMouse.Info = SKIN:GetMeasure("MouseInfo")
	oMouse.X = SKIN:GetMeasure("MouseX")
	oMouse.Y = SKIN:GetMeasure("MouseY")

	oldPosX = nil
	oldPosY = nil

	bHovered = false
	bHoveredLast = false
	bLastInfo = false
end

function Update()
	local bOverWindow = (oMouse.Info:GetValue() == 1)
	-- If we are not over the window and we were previously over the window, then call the leave action for every hovered meter
	if not bOverWindow and bOverWindowLast then
		for k,v in pairs(tM) do
			if v.fOver == true then
				SKIN:Bang( v.o:GetOption("LeaveAction") )
				v.fOver = false
			end
		end
	end
	bOverWindowLast = bOverWindow

	-- Do nothing if we are not over the skin
	if not bHovered and not bHoveredLast then return end

	local iMX = oMouse.X:GetValue()
	local iMY = oMouse.Y:GetValue()

	oldPosX = iMX
	oldPosY = iMY

	for k,v in pairs(tM) do
		-- Make the cursor position relative to a Cartesian plane whose origin is at the center of the current Roundline meter
		local iCX = iMX - (v.o:GetX(true) + v.o:GetW()/2)
		local iCY = -( iMY - (v.o:GetY(true) + v.o:GetH()/2) )
		-- Position in polar coordinates relative to the above values
		local nRadius = math.sqrt(iCX^2 + iCY^2)
		local nTheta = ReMapRadians( -(math.atan2(iCY, iCX)) )

		local nRstart = UInt( v.o:GetOption("LineStart", 0) )
		local nRend = UInt( v.o:GetOption("LineLength", 1) )
		local nAstart = SKIN:ParseFormula(v.o:GetOption("StartAngle", 1))
		local nAend = nAstart + SKIN:ParseFormula(v.o:GetOption("RotationAngle", 1))
		if math.abs(nAend - nAstart) >= PI2 then -- If the angle covered by the meter is greater or equal to a full revolution
			-- The meter covers a full revolution
			nAstart = 0
			nAend = 0
		end
		nAstart = ReMapRadians(nAstart)
		nAend = ReMapRadians(nAend)
		
		if (nRadius >= nRstart and nRadius <= nRend) and IsAngleInRange(nTheta, nAstart, nAend) then
			if v.fOver == false then
				-- On hover
				--print("Hover", k)
				SKIN:Bang( v.o:GetOption("OverAction") )
				v.fOver = true
			end
		else
			if v.fOver == true then
				-- On leave
				--print("Leave", k)
				SKIN:Bang( v.o:GetOption("LeaveAction") )
				v.fOver = false
			end
		end
	end

	bHoveredLast = bHovered
end

function onHover()
	bHovered = true
end
function onLeave()
	bHovered = false
end

function onSkinEvent(sEvent)
	for k,v in pairs(tM) do
		if v.fOver == true then
			--print(sEvent, k)
			SKIN:Bang(v.o:GetOption(sEvent .. "Action"))
		end
	end
end

-- re-maps an angle in radians to the range 0-2PI
function ReMapRadians(nRad)
   local n = nRad % PI2
   if n < 0 then n = PI2 + n end
   return n
end

function UInt(n)
	return math.abs(math.floor( SKIN:ParseFormula(n) ))
end

function IsAngleInRange(nAngle, nMin, nMax)
	if nMin == nMax then
		return true
	end

	if nMin > nMax then
		-- Range passes through 0
		return nAngle > nMin or nAngle < nMax
	end

	return nAngle > nMin and nAngle < nMax
end

function Split(str, delim, maxNb)
	-- Eliminate bad cases...
	if string.find(str, delim) == nil then
		return { str }
	end
	if maxNb == nil or maxNb < 1 then
		maxNb = 0    -- No limit
	end

	local result = {}
	local pat = "(.-)" .. delim .. "()"
	local nb = 0
	local lastPos
	for part, pos in string.gmatch(str, pat) do
		nb = nb + 1
		result[nb] = part
		lastPos = pos
		if nb == maxNb then break end
	end

	-- Handle the last field
	if nb ~= maxNb then
		result[nb + 1] = string.sub(str, lastPos)
	end
	return result
end