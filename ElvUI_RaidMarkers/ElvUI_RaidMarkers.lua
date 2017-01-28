local E, L, V, P, G = unpack(ElvUI);
local RM = E:NewModule("RaidMarkersBar")
local EP = LibStub("LibElvUIPlugin-1.0")

local _G = _G
local ipairs = ipairs;
local format = string.format;

local UnregisterStateDriver = UnregisterStateDriver;
local RegisterStateDriver = RegisterStateDriver;

-- Profile
P["actionbar"]["raidmarkersbar"] = {
	["visible"] = "auto",
	["orient"] = "horizontal"
}

-- Config
local function InjectOptions()
	E.Options.args.actionbar.args.raidmarkersbar = {
		type = "group",
		name = L["Raid Markers"],
		args = {
			header = {
				order = 1,
				type = "header",
				name = L["Raid Markers"]
			},
			visible = {
				order = 2,
				type = "select",
				name = L["Visibility"],
				desc = L["Select how the raid markers bar will be displayed."],
				values = {
					["hide"] = L["Hide"],
					["show"] = L["Show"],
					["auto"] = L["Automatic"]
				},
				get = function() return RM.db.visible end,
				set = function(_, value) RM.db.visible = value; RM:UpdateBar(); end
			},
			orient = {
				order = 3,
				type = "select",
				name = L["Orientation"],
				desc = L["Choose the orientation of the raid markers bar."],
				values = {
					["horizontal"] = L["Horizontal"],
					["vertical"] = L["Vertical"]
				},
				get = function() return RM.db.orient end,
				set = function(_, value) RM.db.orient = value; RM:UpdateBar(); end
			}
		}
	}
end

local BUTTON_HEIGHT = 18
local BUTTON_WIDTH = 18
local BUTTON_DISTANCE = 5
local FRAME_HEIGHT = 22
local FRAME_WIDTH = 150

local buttonMap = {
	[1] = {RT = 1},	-- yellow/star
	[2] = {RT = 2},	-- orange/circle
	[3] = {RT = 3},	-- purple/diamond
	[4] = {RT = 4},	-- green/triangle
	[5] = {RT = 5},	-- white/moon
	[6] = {RT = 6},	-- blue/square
	[7] = {RT = 7},	-- red/cross
	[8] = {RT = 8},	-- white/skull
	[9] = {RT = 0}	-- clear target
}

function RM:ToggleBar()
	if(self.db.show) then
		self.frame:Show()
	else
		self.frame:Hide()
	end
end

function RM:UpdateMover()
	self.frame.mover:Size(self.frame:GetWidth(), self.frame:GetHeight())
end

function RM:UpdateBar(first)
	local height, width = FRAME_HEIGHT, FRAME_WIDTH

	if(self.db.orient == "vertical") then
		width = BUTTON_WIDTH + 3
		height = (BUTTON_HEIGHT * 9) + (BUTTON_DISTANCE * 9)
	else
		width = (BUTTON_WIDTH * 9) + (BUTTON_DISTANCE * 9)
		height = BUTTON_HEIGHT + 3
	end

	if(first) then
		self.frame:ClearAllPoints()
		self.frame:SetPoint("CENTER")
	end

	self.frame:SetWidth(width)
	self.frame:SetHeight(height)

	for i = 9, 1, -1 do
		local button = self.frame.buttons[i]
		local prev = self.frame.buttons[i + 1]
		button:ClearAllPoints()

		if(self.db.orient == "vertical") then
			if(i == 9) then
				button:SetPoint("TOP", 0, -3)
			else
				button:SetPoint("TOP", prev, "BOTTOM", 0, -BUTTON_DISTANCE)
			end
		else
			if(i == 9) then
				button:SetPoint("LEFT", 3, 0)
			else
				button:SetPoint("LEFT", prev, "RIGHT", BUTTON_DISTANCE, 0)
			end
		end
	end

	if(self.db.visible == "hide") then
		UnregisterStateDriver(self.frame, "visibility")
		if(self.frame:IsShown()) then
			self.frame:Hide()
		end
	elseif(self.db.visible == "show") then
		UnregisterStateDriver(self.frame, "visibility")
		if(not self.frame:IsShown()) then
			self.frame:Show()
		end
	else
		RegisterStateDriver(self.frame, "visibility", "[noexists,nogroup] hide; show")
	end
end

function RM:ButtonFactory()
	for i, buttonData in ipairs(buttonMap) do
		local button = CreateFrame("Button", ("ElvUI_RaidMarkersBarButton%d"):format(i), _G["ElvUI_RaidMarkersBar"], "SecureActionButtonTemplate")
		button:SetHeight(BUTTON_HEIGHT)
		button:SetWidth(BUTTON_WIDTH)
		button:SetTemplate("Default", true)

		local image = button:CreateTexture(nil, "OVERLAY")
		image:SetInside()
		image:SetTexture(i == 9 and "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up" or ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"):format(i))

		local highlight = button:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetInside()
		highlight:SetTexture(1, 1, 1, 0.30)

		local target = buttonData.RT

		if(target) then
			button:SetAttribute("type1", "macro")
			button:SetAttribute("macrotext1", ("/run SetRaidTargetIcon(\"target\", %d)"):format(i < 9 and i or 0))

			button:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
				GameTooltip:AddLine(i == 9 and L["Click to clear the mark."] or L["Click to mark the target."], 1, 1, 1)
				GameTooltip:Show()
			end)
			button:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end

		button:RegisterForClicks("AnyDown")
		self.frame.buttons[i] = button
	end
end

function RM:Initialize()
	self.db = E.db.actionbar.raidmarkersbar

	self.frame = CreateFrame("Frame", "ElvUI_RaidMarkersBar", E.UIParent, "SecureHandlerStateTemplate")
	self.frame:SetResizable(false)
	self.frame:SetClampedToScreen(true)
	self.frame:SetTemplate("Transparent")

	self.frame.buttons = {}
	self:ButtonFactory()
	self:UpdateBar(true)

	E:CreateMover(self.frame, "ElvUI_RMBarMover", L["Raid Markers Bar"])

	self:UpdateMover()
end

E:RegisterModule(RM:GetName())

EP:RegisterPlugin(..., InjectOptions)