local POINTS = {
	{ teleX = 31.30, teleY = 10.78, teleName = "Moon Guard Stronghold" },
	{ teleX = 22.68, teleY = 36.42, teleName = "Falanaar" },
	{ teleX = 42.07, teleY = 34.91, teleName = "Tel'Anor" },
	{ teleX = 36.61, teleY = 46.54, teleName = "Ruins of Elune'eth" },
	{ teleX = 45.80, teleY = 64.42, teleName = "Sanctum of Order" },
	{ teleX = 43.07, teleY = 76.91, teleName = "Lunastre Estate" },
	{ teleX = 38.19, teleY = 77.13, teleName = "Felsoul Hold" },
	{ teleX = 46.66, teleY = 81.00, teleName = "Waning Crescent" }
};

Telemancy = {
	hasSetup = false,
	icons = {}, -- Used to store the icons we cook!
	mapID = 1033, -- Suramar
	iconOffset = 16, -- Icon is 32x32
};

local t = Telemancy;

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
			if GetCurrentMapAreaID() == t.mapID and GetCurrentMapDungeonLevel() == 0 then
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
	for key, icon in pairs(t.icons) do
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
		self:SetPoint("TOPLEFT", (frameWidth * self.teleX) - t.iconOffset, (frameHeight * self.teleY) + t.iconOffset);
	else
		self.updateTimer = self.updateTimer + elapsed;
	end
end

t.OnIconEnter = function(self)
	WorldMapFrameAreaLabel:SetText("Telemancy: " .. self.teleName);
	WorldMapFrameAreaLabel:Show();
end

t.OnIconLeave = function(self)
	WorldMapFrameAreaLabel:SetText("");
end

t.Setup = function()
	-- Create a re-usable template for frame creation.
	local template = {
		size = 32,
		parent = WorldMapPOIFrame,
		strata = "TOOLTIP",
		textures = {
			texture = [[Interface/MINIMAP/Dungeon]],
			color = {0.0117647059, 0.4745098039, 0.8666666667}
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

		template.data = point; -- Provide point data to the frame.
		template.data.updateTimer = 0; -- Used in OnIconUpdate

		table.insert(t.icons, Krutilities:Frame(template));
	end

	POINTS = nil; -- Dereference this, no longer need it.
	t.hasSetup = true; -- Flag set-up as done.
end