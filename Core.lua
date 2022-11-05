STP = LibStub("AceAddon-3.0"):NewAddon("Simple Threat Plates", "AceConsole-3.0")
STP:RegisterChatCommand("stp", "loadOptions")
STP:RegisterChatCommand("simplethreatplates", "loadOptions")

options = {
	name = "Simple Threat Plates",
	handler = STP,
	type = 'group',
	args = {
		defaultcolour = {
			type = 'color',
			name = 'Default Plate Colour',
			set = 'SetDefaultColor',
			get = 'GetDefaultColor',
		},
		aggrocolour = {
			type = 'color',
			name = 'Aggro Plate Colour',
			set = 'SetAggroColor',
			get = 'GetAggroColor',
		},
		closecolour = {
			type = 'color',
			name = 'Insecure Threat Plate Colour',
			set = 'SetCloseColor',
			get = 'GetCloseColor',
		},
		offtankcolour = {
			type = 'color',
			name = 'Other Tank Has Aggro Plate Colour',
			set = 'SetOfftankColor',
			get = 'GetOfftankColor',
		},
		nontankcolour = {
			type = 'color',
			name = 'Non tank Has Aggro Plate Colour',
			set = 'SetNontankColor',
			get = 'GetNontankColor',
		},
	},
}

-- declare defaults to be used in the DB
local defaults = {
	profile = {
		colours = {
			default = {
				r = 1,
				g = 0,
				b = 0
			},
			aggro = {
				r = 0,
				g = 1,
				b = 0
			},
			close = {
				r = 1,
				g = 1,
				b = 0
			},
			offtank = {
				r = 0,
				g = 0.5,
				b = 1
			},
			nontank = {
				r = 1,
				g = 0,
				b = 0
			}
		}
	}
}

local tanks = {}
local nontanks = {}

function STP:OnInitialize()
	STP:Print("Simple Threat Plates loaded!")

	self.db = LibStub("AceDB-3.0"):New("SimpleThreatPlatesDB", defaults, true)
	--	self.db:ResetDB()
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	LibStub("AceConfig-3.0"):RegisterOptionsTable("Simple Threat Plates", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Simple Threat Plates", "Simple Threat Plates")

	hooksecurefunc("CompactUnitFrame_OnEvent", UpdateThreat)
	hooksecurefunc("CompactUnitFrame_RegisterEvents", UpdateThreat)

	local frame = CreateFrame("FRAME", "STPAddonFrame");
	frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	frame:RegisterEvent("GROUP_ROSTER_UPDATE");
	frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");

	local function checkSpecs(self, event, ...)
		tanks = {}
		if IsInRaid() then
			for i = 1, GetNumGroupMembers(), 1 do
				name = "raid" .. i;
				if UnitGroupRolesAssigned(name) == "TANK" then
					if UnitName(name) ~= UnitName("player") then
						table.insert(tanks, name)
					end
				else
					if UnitName(name) ~= UnitName("player") then
						table.insert(nontanks, name)
					end
				end
			end
		else
			for i = 1, GetNumGroupMembers() - 1, 1 do
				name = "party" .. i;
				if UnitGroupRolesAssigned(name) == "TANK" then
					table.insert(tanks, name)
				else
					table.insert(nontanks, name)
				end
			end
		end
	end

	frame:SetScript("OnEvent", checkSpecs);
end

function STP:GetDefaultColor(info)
	return self.db.profile.colours.default.r, self.db.profile.colours.default.g, self.db.profile.colours.default.b
end

function STP:SetDefaultColor(t, r, g, b, a)
	self.db.profile.colours.default.r = r
	self.db.profile.colours.default.g = g
	self.db.profile.colours.default.b = b
	rerunPlates();

end

function STP:GetAggroColor(info)
	return self.db.profile.colours.aggro.r, self.db.profile.colours.aggro.g, self.db.profile.colours.aggro.b
end

function STP:SetAggroColor(t, r, g, b, a)
	self.db.profile.colours.aggro.r = r
	self.db.profile.colours.aggro.g = g
	self.db.profile.colours.aggro.b = b
	rerunPlates();
end

function STP:GetCloseColor(info)
	return self.db.profile.colours.close.r, self.db.profile.colours.close.g, self.db.profile.colours.close.b
end

function STP:SetCloseColor(t, r, g, b, a)
	self.db.profile.colours.close.r = r
	self.db.profile.colours.close.g = g
	self.db.profile.colours.close.b = b
	rerunPlates();
end

function STP:GetOfftankColor(info)
	return self.db.profile.colours.offtank.r, self.db.profile.colours.offtank.g, self.db.profile.colours.offtank.b
end

function STP:SetOfftankColor(t, r, g, b, a)
	self.db.profile.colours.offtank.r = r
	self.db.profile.colours.offtank.g = g
	self.db.profile.colours.offtank.b = b
	rerunPlates();
end

function STP:GetNontankColor(info)
	return self.db.profile.colours.nontank.r, self.db.profile.colours.nontank.g, self.db.profile.colours.nontank.b
end

function STP:SetNontankColor(t, r, g, b, a)
	self.db.profile.colours.nontank.r = r
	self.db.profile.colours.nontank.g = g
	self.db.profile.colours.nontank.b = b
	rerunPlates();
end

function rerunPlates()
	--Rerun all nameplates through UpdateThreat
	if not InCombatLockdown() then
		table.foreach(C_NamePlate:GetNamePlates(),
			function(k, v)
				UpdateThreat(C_NamePlate.GetNamePlateForUnit(v["namePlateUnitToken"])["UnitFrame"])
			end)
	end
end

function STP:loadOptions(input)
	STP:Print("Opening options pane.")
	InterfaceOptionsFrame_OpenToCategory("Simple Threat Plates")
	InterfaceOptionsFrame_OpenToCategory("Simple Threat Plates")
	InterfaceOptionsFrame_OpenToCategory("Simple Threat Plates")

end

function UpdateThreat(self)
	print(GetTime())
	local unit = self.unit

	--If unit is valid, not an enemy
	if (not unit) or (not UnitIsEnemy(unit, "player") or UnitIsPlayer(unit)) then
		return
	end
	if not unit:match('nameplate%d*') then return end

	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if not nameplate then return end

	updateNameplateColor("player", self, {
		default = { STP:GetDefaultColor() },
		close = { STP:GetCloseColor() },
		temporary = { STP:GetAggroColor() },
		aggro = { STP:GetAggroColor() }
	}) --the player

	--Check other tanks.
	for _, tank in pairs(tanks) do
		updateNameplateColor(tank, self, {
			default = nil,
			close = nil,
			temporary = { STP:GetOfftankColor() },
			aggro = { STP:GetOfftankColor() }
		}) --the offtank
	end

	for _, nontank in pairs(nontanks) do
		updateNameplateColor(nontank, self, {
			default = nil,
			close = nil,
			temporary = { STP:GetNontankColor() },
			aggro = { STP:GetNontankColor() }
		}) --the nontank
	end
end

local statuses = {
	"default",
	"close",
	"temporary",
	"aggro"
}
function updateNameplateColor(unit, nameplate, statusColorMap)
	local isTanking, status = UnitDetailedThreatSituation(unit, nameplate.unit)
	if status == nil then
		--status could be nil if target not engaged, we can't do anything with that info!
		--ignore or set the default, but only if we are looking for the player
		if unit == "player" then
			--if the player themselves is not engaged, then reset the status color
			nameplate.healthBar:SetStatusBarColor(STP:GetDefaultColor())
		end
		return
	end

	status = status + 1 --lua arrays are weird and start from 1! >:(
	local selectedColor = statusColorMap[statuses[status]]

	if selectedColor ~= nil then --nil means don't change for it
		return nameplate.healthBar:SetStatusBarColor(unpack(selectedColor))
	end
end
