-- Animator: Animates a value from nItitial to nTarget iFrames times, allows changing nTarget and iFrames mid animation
Animator = class(
	function(o, nItitial, nStep, updateFunc)
		o.nCurrent = nItitial
		o.nTarget = nItitial
		o.nStep = math.abs(nStep)
		o.updateFunc = updateFunc
		o.running = false
	end
)
-- Sets a new target for the animator
function Animator:SetTarget(nTarget, nStep)
	if nTarget == nil then return false end
	if nStep ~= nil then
		self.nStep = math.abs(nStep)
	end
	self.nTarget = nTarget
	self.running = true
	return true
end
-- Steps the animator one frame up and returns the new value, optionally calling self.updateFunc if it is a valid function
function Animator:Update()
	if self.running then
		local direction = 1
		if self.nTarget - self.nCurrent < 0 then
			direction = -1
		end

		self.nCurrent = self.nCurrent + self.nStep * direction
		if (self.nTarget - self.nCurrent) * direction <= 0 then 
			self.running = false
			self.nCurrent = self.nTarget
		end

		if type(self.updateFunc) == "function" then self.updateFunc(self.nCurrent) end
	end

	return self.nCurrent
end