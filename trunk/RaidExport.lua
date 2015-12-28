function RaidGuild:ExportRaid()

	local player = UnitName("player")
	local version = 1

	ex = '<?xml version="1.0"?>'
	ex = ex .. '<raidtracker author="'..player..'" version="'..version..'">'
	for id,raid in pairs(self.db.global.RaidLog) do
		if type(self.raidMeta[raid["zone"].."-"..tostring(raid["difficulty"])]) == "table" then
			nicename = self.raidMeta[raid["zone"].."-"..tostring(raid["difficulty"])]["nicename"]
		else
			nicename = raid["zone"]
		end
		ex = ex .. '<raid id="'..id..'" difficulty="'..raid["difficulty"]..'" zone="'..raid["zone"]..'" nicename="'..nicename..'" raidstart="'..raid["raidstart"]..'" raidstop="'..raid["raidstop"]..'">'
		ex = ex .. '<leave>'
		for player,t in pairs(raid["leave"]) do
			ex = ex .. '<time player="' .. player .. '" value="' .. t .. '" />'
		end
		ex = ex .. '</leave>'
		ex = ex .. '<join>'
		for player,t in pairs(raid["join"]) do
			ex = ex .. '<time player="' .. player .. '" value="' .. t .. '" />'
		end
		ex = ex .. '</join>'
		ex = ex .. '<dkptime>'
		for player,t in pairs(raid["dkptime"]) do
			ex = ex .. '<time player="' .. player .. '" value="' .. t .. '" />'
		end
		ex = ex .. '</dkptime>'
		ex = ex .. '<bossdown>'
		for t,boss in pairs(raid["bossdown"]) do
			ex = ex .. '<boss name="' .. boss .. '" time="' .. t .. '" />'
		end
		ex = ex .. '</bossdown>'
		ex = ex .. '<loot>'
		for id,t in pairs(raid["loot"]) do
			ex = ex .. '<item id="'..t["itemid"]..'" time="'..t["time"]..'" name="'..t["name"]..'" category="'..t["category"]..'" type="'..t["itemtype"]..'" quality="'..t["quality"]..'" player="'..t["player"]..'" amount="'..t["amount"]..'" />'
		end
		ex = ex .. '</loot>'
		ex = ex .. '</raid>'
		
	end
	ex = ex .. '</raidtracker>'
	
	RaidGuildStringFrameEditBox:SetText(ex);
	RaidGuildStringFrameDone:SetText("Close");
	RaidGuildStringFrameEditBox:HighlightText();
	RaidGuildStringFrame:Show();
end