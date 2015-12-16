function Initialize()
	-- Prevent always multiplying PI by 2 in the rest of the code (minor performance boost) by doing it now
	PI2 = math.pi * 2

	-- Process configuration variables
	tC = {}
	tC.Count = RmGetInt("RingCount", 1)
	if tC.Count <= 0 then tC.Count = 1 end
	tC.StartRadius = RmGetInt("RingStart", 60)

   tC.f = {} -- Formatting functions
   tC.f.Meter = function(s1, s2) return ("Section%s_%s"):format(s1, s2) end
   tC.f.Border = function(s1, s2) return ("Border%s_%s"):format(s1, s2) end
   tC.f.CircleBorder = function(s1) return ("CircleBorder%s"):format(s1) end
   tC.f.RingMeterPre = function(s1) return ("Ring%s."):format(s1) end

   tC.m = {} -- Meters and measures
   tC.m.CenterText = SKIN:GetMeter("MeterCenterText")
   tC.m.Center = SKIN:GetMeter("MeterCenter")



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
         table.insert(o.tData, ('\[%s\]'):format(sSectionName))
      end)
      function iniSectionBuilder:AddKey(sKey, sVal)
         table.insert(self.tData, ('%s=%s'):format(sKey, sVal))
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
      return table.concat(self.tData, '\n')
   end

   -- TODO: Add an animator class that controls the section fade (in/out) animations



	-- Rebuild the skin if the ini says that we should
	if RmGetInt("Rebuild", 0) == 1 then
		rebuildSkin()
	end

	-- Set up hit testing
	tHitTest = {
      HalfSize = RmGetInt("Size", 1) / 2,

      Mouse = {
         isOver = false, -- True if the mouse if over our skin
         oX = SKIN:GetMeasure("MouseX"),
         oY = SKIN:GetMeasure("MouseY"),
         oldX = nil,
         oldY = nil,
      },

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
            },
         },
      }
   ]]--
   local iCurRad = tC.StartRadius
   for iRing=1,tC.Count do
      local sPre = tC.f.RingMeterPre(iRing)
      tHitTest.cache[iRing] = {}
      tHitTest.cache[iRing].Min = iCurRad
      iCurRad = iCurRad + RmGetInt(sPre .. "Size", 50)
      tHitTest.cache[iRing].Max = iCurRad

      local iCount = RmGetInt(sPre .. "Count", 1)

      tHitTest.cache[iRing].Count = iCount
      
      for iSect=1,iCount do
         tHitTest.cache[iRing][iSect] = {}
         local o = tHitTest.cache[iRing][iSect]

         o.sM = tC.f.Meter(iRing, iSect)
         o.oM = SKIN:GetMeter(o.sM)

         o.Min = ReMapRadians( tonumber(o.oM:GetOption("StartAngle")) )
         o.Max = ReMapRadians( o.Min + tonumber(o.oM:GetOption("RotationAngle")) )

         o.Special = (o.Min > o.Max)

         -- TODO: Cache configuration information here, create an animator object for each section cache that shit too
      end
   end

   function tHitTest:Update()
      -- Only hit test if the mouse is over our skin
      if not self.Mouse.isOver then return end

      -- Get the current cursor position
      local iX = self.Mouse.oX:GetValue()
      local iY = self.Mouse.oY:GetValue()

      -- Skip hit testing if the previous update cycle already processed it
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
         for i=1,self.cache[iRing].Count do
            local o = self.cache[iRing][i]

            if (nTheta >= o.Min and nTheta <= o.Max) or (o.Special and (nTheta >= o.Min or nTheta <= o.Max)) then
               iSect = i
               break
            end         
         end
      end


      if iRing ~= nil and iSect ~= nil then
         -- TODO: Process animations and config info to actually make the launcher functional
         SKIN:Bang("!SetOption", "MeterCenterText", "Text", ("%ss%s"):format(iRing, iSect))
      else
         SKIN:Bang("!SetOption", "MeterCenterText", "Text", "")
      end
   end
end

function Update()
   tHitTest:Update()
end

function rebuildSkin()
	-- If rebuild was selected from the context menu then we should refresh the skin (to reload the variables) and then rebuild the meters
	if RmGetInt("Rebuild", 0) ~= 1 then
		-- Write a key to the ini so that we know next time that we should call this function to rebuild the meters
		SKIN:Bang('!WriteKeyValue', 'Variables', 'Rebuild', "1")
		SKIN:Bang('!Refresh')
		return
	end
	-- Revert the key to 0 to prevent an infinite loop (which is not as fun as it seems)
	SKIN:Bang('!WriteKeyValue', 'Variables', 'Rebuild', "0")

   local iCurRad = tC.StartRadius -- Current radius
   local oMeters = iniBuilder() -- iniBuilder for the meters
   local oBorders = iniBuilder() -- iniBuilder for the borders

   -- Create first circle border
   local o = oBorders:NewSection( tC.f.CircleBorder(0) )
      o:AddKey("Meter", "Roundline")
      o:AddKey("MeterStyle", "Section|CircleBorder")
      o:AddKey("LineStart", iCurRad)
      o:AddKey("LineLength", iCurRad + 2)
   o:Commit()

   for iRing=1,tC.Count do
      local sPre = tC.f.RingMeterPre(iRing)
      local iCount = RmGetInt(sPre .. "Count", 1)
      local iSize = RmGetInt(sPre .. "Size", 50)
      local nOffset = SKIN:ParseFormula( SKIN:GetVariable(sPre .. "Offset", 0) )
      if nOffset == nil then nOffset = 0 end
      local iEndRadius = iCurRad + iSize

      -- Create the circle border that goes around the outside of this ring
      o = oBorders:NewSection( tC.f.CircleBorder(iRing) )
         o:AddKey("Meter", "Roundline")
         o:AddKey("MeterStyle", "Section|CircleBorder")
         o:AddKey("LineStart", iEndRadius)
         o:AddKey("LineLength", iEndRadius + 2)
      o:Commit()

      for iSect=1,iCount do
         local nStartAngle = PI2 / iCount * (iSect-1) + nOffset

         o = oMeters:NewSection( tC.f.Meter(iRing, iSect) )
            o:AddKey("Meter", "Roundline")
            o:AddKey("MeterStyle", "Section")
            o:AddKey("StartAngle", nStartAngle)
            o:AddKey("RotationAngle", PI2 / iCount)
            o:AddKey("LineStart", iCurRad)
            o:AddKey("LineLength", iEndRadius)
            o:AddKey("HoverColor", HSLtoRGB(iSect/iCount, 0.7, 0.75) .. ",200")
         o:Commit()

         if iCount > 1 then
            o = oBorders:NewSection( tC.f.Border(iRing, iSect) )
               o:AddKey("Meter", "Roundline")
               o:AddKey("MeterStyle", "Section|LineBorder")
               o:AddKey("StartAngle", nStartAngle)
               o:AddKey("RotationAngle", PI2 / iCount)
               o:AddKey("LineStart", iCurRad)
               o:AddKey("LineLength", iEndRadius)
            o:Commit()
         end
      end

      iCurRad = iEndRadius
   end

   o = oBorders:NewSection("Variables")
      o:AddKey("Size", iCurRad * 2 + 4)
   o:Commit()

   -- Write the file
   local file = io.open(SKIN:GetVariable("@") .. "Meters.inc", 'w+')
   file:write( oMeters:ToString() .. "\n" .. oBorders:ToString() )
   file:close()
   -- Reload the skin
   SKIN:Bang('!Refresh')
end

-- Mouse events
function onHover()
   tHitTest.Mouse.isOver = true
   tC.m.CenterText:Show()
   tC.m.Center:Show()
end
function onLeave()
   tHitTest.Mouse.isOver = false
   tC.m.CenterText:Hide()
   tC.m.Center:Hide()
end
function onClick()
end

-- Helper functions
-- Returns a rainmeter variable rounded down to an integer
function RmGetInt(sVar, iDefault)
	return math.floor(SKIN:GetVariable(sVar, iDefault))
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
      if t < 0  then t = t + 1 end
      if t > 1  then t = t - 1 end
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


-- class.lua
-- Compatible with Lua 5.1 (not 5.0).
function class(base, init)
   local c = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
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