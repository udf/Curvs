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