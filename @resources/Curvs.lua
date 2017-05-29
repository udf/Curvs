function Initialize()
	dofile(SKIN:GetVariable("@") .. "Dofiles\\class.lua")
	dofile(SKIN:GetVariable("@") .. "Dofiles\\animator.lua")
	dofile(SKIN:GetVariable("@") .. "Dofiles\\utilities.lua")

	-- Set up animations
	LastMeter = ""

	AnimationFadeInStep = 42
	AnimationFadeOutStep = 21
	AnimationMaxAlpha = 255
	AnimationMinAlpha = 1

	Animators = {}
	AnimatorCenter = Animator(
		0,
		AnimationFadeOutStep,
		AnimateImage
	)
	table.insert(Animators, AnimatorCenter)
	AnimatorCenterFade = Animator(
		0,
		AnimationFadeOutStep,
		AnimateFader
	)
	table.insert(Animators, AnimatorCenterFade)

	local ringCount = RmGetUInt("RingCount", 1)
	if ringCount == 0 then ringCount = 1 end
	Buttons = {}
	for ring=1,ringCount do
		local prefix = ("Ring%s"):format(ring)
		local buttonCount = RmGetUInt(prefix .. ".Count", 1)

		for button=1,buttonCount do
			local buttonName = ("%ss%s"):format(ring, button)
			Buttons[buttonName] = {}

			Buttons[buttonName].image = SKIN:GetVariable(buttonName .. "Image", "")
			Buttons[buttonName].bang = SKIN:GetVariable(buttonName .. "Bang", "")

			Buttons[buttonName].color = StripAlpha(SKIN:GetVariable(buttonName .. "Color", ""))
			if Buttons[buttonName].color == nil then
				Buttons[buttonName].color = SKIN:GetMeter(buttonName):GetOption("StyleAttributes")
			else
				Buttons[buttonName].color = "Stroke Color " .. Buttons[buttonName].color
			end

			Buttons[buttonName].animator = Animator(
					AnimationMaxAlpha,
					AnimationFadeOutStep,
					function(alpha)
						SKIN:Bang("!SetOption", buttonName, "StyleAttributes", Buttons[buttonName].color .. "," .. math.floor(alpha))
					end
				)
			Buttons[buttonName].animator:SetTarget(1, 5)
			table.insert(Animators, Buttons[buttonName].animator)
		end
	end
end

function Update()
	for i=1,#Animators do
		Animators[i]:Update()
	end
end

function HideImage()
	AnimatorCenter:SetTarget(0, AnimationFadeInStep)
end
function ShowImage(imageName)
	SKIN:Bang("!SetOption", "Center", "ImageName", imageName)
	AnimatorCenter:SetTarget(255, AnimationFadeInStep)
end
function ShowFader(imageName)
	SKIN:Bang("!SetOption", "CenterFade", "ImageName", imageName)
	SKIN:Bang("!SetOption", "CenterFade", "ImageAlpha", 255)
	AnimatorCenterFade.nCurrent = 255
	AnimatorCenterFade:SetTarget(0, AnimationFadeInStep)
end
function AnimateImage(alpha)
	SKIN:Bang("!SetOption", "Center", "ImageAlpha", math.floor(alpha))
end
function AnimateFader(alpha)
	SKIN:Bang("!SetOption", "CenterFade", "ImageAlpha", math.floor(alpha))
end

function onHover(sectionName)
	--print("onHover", sectionName)
	Buttons[sectionName].animator:SetTarget(AnimationMaxAlpha, AnimationFadeInStep)

	if Buttons[sectionName].image == "" then
		SKIN:Bang("!SetOption", "CenterText", "Text", sectionName)
		HideImage()
	else
		SKIN:Bang("!SetOption", "CenterText", "Text", "")
		ShowImage(Buttons[sectionName].image)
	end

	LastMeter = sectionName
end
function onLeave(sectionName)
	--print("onLeave", sectionName)
	Buttons[sectionName].animator:SetTarget(AnimationMinAlpha, AnimationFadeOutStep)

	if sectionName == LastMeter then
		HideImage()
	end
	if Buttons[sectionName].image ~= "" then
		ShowFader(Buttons[sectionName].image)
	end

	SKIN:Bang("!SetOption", "CenterText", "Text", "")
end
function onClick(sectionName)
	--print("onClick", sectionName)
	if Buttons[sectionName].bang ~= "" then
		SKIN:Bang(Buttons[sectionName].bang)
	end
end
