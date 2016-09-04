
-- Static.
local ICON_OFFSET = 14; -- Icon is 28x28
local ACTIVE_ICON = [[Interface/MINIMAP/Vehicle-AllianceMagePortal]];
local INACTIVE_ICON = [[Interface/MINIMAP/Vehicle-HordeMagePortal]];
local MAP_ID = 1033;
local POINTS = {
	{ teleX = 31.30, teleY = 10.78, teleName = "TELE_MOON_GUARD", questID = 43808 },
	{ teleX = 22.68, teleY = 36.42, teleName = "TELE_FALANAAR", questID = 42230 },
	{ teleX = 42.07, teleY = 34.91, teleName = "TELE_TELANOR", questID = 43809 },
	{ teleX = 36.61, teleY = 46.54, teleName = "TELE_RUINS_ELUNE", questID = 40956 },
	{ teleX = 45.80, teleY = 64.42, teleName = "TELE_SANCTUM_ORDER", questID = 43813 },
	{ teleX = 43.07, teleY = 76.91, teleName = "TELE_LUNASTRE", questID = 43811 },
	{ teleX = 38.19, teleY = 77.13, teleName = "TELE_FELSOUL_HOLD", questID = 41575 },
	{ teleX = 46.66, teleY = 81.00, teleName = "TELE_WANING_CRESENT", questID = 42487 },
	{ teleX = 64.00, teleY = 60.40, teleName = "TELE_TWILIGHT_VINEYARDS", questID = 44084 }
};

Telemancy = {
	hasSetup = false,
	icons = {}, -- Used to store the icons we cook!
	strings = {} -- Localization table.
};

local t = Telemancy;
local L = Telemancy.strings;

-- Event frame! How.. eventful.
local eventFrame = CreateFrame("FRAME");
eventFrame:RegisterEvent("WORLD_MAP_UPDATE");
eventFrame:SetScript("OnEvent", function(...) t.OnEvent(...); end);

t.OnEvent = function(self, event, ...)
	-- The world map has updated, check our stuff!
	if event == "WORLD_MAP_UPDATE" then
		-- Check the world map is actually shown.
		if WorldMapFrame:IsShown() then
			-- Confirm that we're in the correct zone (and multi-map level).
			if GetCurrentMapAreaID() == MAP_ID and GetCurrentMapDungeonLevel() == 0 then
				t.UpdateIcons();
				return;
			end
		end

		-- Negative, commander! Hide the icons.
		t.HideIcons();
	end
end

t.UpdateIcons = function()
	-- Set-up icons for the first time.
	if not t.hasSetup then
		t.Setup();
	end

	-- Iterate every spawned icon and update it.
	local frameWidth, frameHeight = WorldMapPOIFrame:GetSize();
	for key, icon in pairs(t.icons) do
		-- set the icons when WorldMap is updating (eg. Zoom)
		icon:SetPoint("TOPLEFT", (frameWidth * icon.teleX) - ICON_OFFSET, (frameHeight * icon.teleY) + ICON_OFFSET);
		icon:Show();
	end
end

t.HideIcons = function()
	-- Iterate every icon and hide it.
	for key, icon in pairs(t.icons) do
		icon:Hide();
	end
end

t.OnIconUpdate = function(self, elapsed)
	-- Every second, check our icons are in the right place.
	-- Lots of things can displace them, but we don't need to go over-board on checking.
	if self.updateTimer >= 1 then
		-- Get the current width/height of the POI frame.
		local frameWidth, frameHeight = WorldMapPOIFrame:GetSize();
		self:SetFrameStrata("HIGH"); -- Map frame resets strata, so we enforce it here every time.
		self:SetPoint("TOPLEFT", (frameWidth * self.teleX) - ICON_OFFSET, (frameHeight * self.teleY) + ICON_OFFSET);

		-- check if Quest is completed and change texture if needed
		if IsQuestFlaggedCompleted(self.questID) then
			if not self.isActive then
				self.texture:SetTexture(ACTIVE_ICON);
				self.isActive = true;
			end
		else
			if self.isActive then
				self.texture:SetTexture(INACTIVE_ICON);
				self.isActive = false;
			end
		end
	else
		self.updateTimer = self.updateTimer + elapsed;
	end
end

t.OnIconEnter = function(self)
	WorldMapFrameAreaLabel:SetText("Telemancy: " .. L[self.teleName]);	
	if IsQuestFlaggedCompleted(self.questID) then
		WorldMapFrameAreaDescription:SetText(L["TELE_ACTIVE"]);
	else
		WorldMapFrameAreaDescription:SetText(L["TELE_INACTIVE"]);
	end	
	WorldMapFrameAreaLabel:Show();
	WorldMapFrameAreaDescription:Show();
end

t.OnIconLeave = function(self)
	WorldMapFrameAreaLabel:SetText("");
end

t.Setup = function()
	-- Create a re-usable template for frame creation.
	local template = {
		size = 28,
		parent = WorldMapPOIFrame,
		strata = "TOOLTIP",
		textures = {
			injectSelf = "texture",
			texture = nil,
		},
		scripts = {
			OnUpdate = t.OnIconUpdate,
			OnEnter = t.OnIconEnter,
			OnLeave = t.OnIconLeave
		}
	};

	-- Create a new frame for every point.
	for key, point in pairs(POINTS) do
		-- Convert the generic point to an actual offset for anchoring.
		point.teleX = point.teleX / 100;
		point.teleY = -(point.teleY / 100);

		-- Set the icon to represent the quest completion state.
		if IsQuestFlaggedCompleted(point.questID) then
			template.textures.texture = ACTIVE_ICON;
		else
			template.textures.texture = INACTIVE_ICON;
		end
		
		template.data = point; -- Provide point data to the frame.
		template.data.updateTimer = 0; -- Used in OnIconUpdate

		table.insert(t.icons, Krutilities:Frame(template));
	end

	POINTS = nil; -- Dereference this, no longer need it.
	t.hasSetup = true; -- Flag set-up as done.
end
