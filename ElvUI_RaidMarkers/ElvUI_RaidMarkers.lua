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
	["visible"] = "AUTOMATIC",
	["orient"] = "HORIZONTAL",
	["buttonSize"] = 18,
	["buttonSpacing"] = 5
}

-- Config
local function InjectOptions()
	E.Options.args.actionbar.args.raidmarkersbar = {
		type = "group",
		name = L["Raid Markers"],
		get = function(info) return E.db.actionbar.raidmarkersbar[ info[#info] ]; end,
		set = function(info, value) E.db.actionbar.raidmarkersbar[ info[#info] ] = value; RM:UpdateBar(); end,
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
					["HIDE"] = L["Hide"],
					["SHOW"] = L["Show"],
					["AUTOMATIC"] = L["Automatic"]
				}
			},
			orient = {
				order = 3,
				type = "select",
				name = L["Orientation"],
				desc = L["Choose the orientation of the raid markers bar."],
				values = {
					["HORIZONTAL"] = L["Horizontal"],
					["VERTICAL"] = L["Vertical"]
				}
			},
			buttonSize = {
				order = 4,
				type = "range",
				name = L["Button Size"],
				desc = L["The size of the action buttons."],
				min = 15, max = 60, step = 1
			},
			buttonSpacing = {
				order = 5,
				type = "range",
				name = L["Button Spacing"],
				desc = L["The spacing between buttons."],
				min = -1, max = 10, step = 1
			}
		}
	}
end

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

function RM:UpdateBar(first)
	if(first) then
		self.frame:ClearAllPoints()
		self.frame:Point("CENTER")
	end
	
	if(self.db.orient == "VERTICAL") then
		self.frame:Height((self.db.buttonSize + self.db.buttonSpacing) * #buttonMap + self.db.buttonSpacing);
		self.frame:Width(self.db.buttonSize + (self.db.buttonSpacing*2));
	else
		self.frame:Width((self.db.buttonSize + self.db.buttonSpacing) * #buttonMap + self.db.buttonSpacing);
		self.frame:Height(self.db.buttonSize + (self.db.buttonSpacing*2));
	end

	for i = 9, 1, -1 do
		local button = self.frame.buttons[i]
		local prev = self.frame.buttons[i + 1]
		button:Size(self.db.buttonSize);
		button:ClearAllPoints()

		if(self.db.orient == "VERTICAL") then
			if(i == 9) then
				button:Point("TOP", 0, -self.db.buttonSpacing)
			else
				button:Point("TOP", prev, "BOTTOM", 0, -self.db.buttonSpacing)
			end
		else
			if(i == 9) then
				button:Point("LEFT", self.db.buttonSpacing, 0)
			else
				button:Point("LEFT", prev, "RIGHT", self.db.buttonSpacing, 0)
			end
		end
	end

	if(self.db.visible == "HIDE") then
		UnregisterStateDriver(self.frame, "visibility")
		if(self.frame:IsShown()) then
			self.frame:Hide()
		end
	elseif(self.db.visible == "SHOW") then
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
		button:SetTemplate("Default", true)

		local image = button:CreateTexture(nil, "OVERLAY")
		image:SetInside()
		image:SetTexture(i == 9 and "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up" or ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"):format(i))

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

		button:StyleButton()
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
end

E:RegisterModule(RM:GetName())

EP:RegisterPlugin(..., InjectOptions)