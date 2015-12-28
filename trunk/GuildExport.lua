function RaidGuild:GuildExport()
	self.guildExportNeeded = true
	if self.guildExportReady == false then
		SetGuildRosterShowOffline(true)
		GuildRoster()
		return
	end
	self.guildExportNeeded = nil

	local player = UnitName("player")
	local version = 1

	ex = '<?xml version="1.0"?>'
	ex = ex .. '<guildrooster author="'..player..'" version="'..version..'">'
	
	for index = 1,GetNumGuildMembers(true) do
			local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(index)
			ex = ex .. '<player name="'..name..'" rank="'..rank..'" rankindex="'..rankIndex..'" level="'..level..'" class="'..class..'" note="'..note..'" officernote="'..officernote..'" />'
	end		

	ex = ex .. '</guildrooster>'
	
	RaidGuildStringFrameEditBox:SetText(ex)
	RaidGuildStringFrameDone:SetText("Close")
	RaidGuildStringFrameEditBox:HighlightText()
	RaidGuildStringFrame:Show()
end