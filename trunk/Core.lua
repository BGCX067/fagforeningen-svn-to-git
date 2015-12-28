RaidGuild = LibStub("AceAddon-3.0"):NewAddon("RaidGuild","AceConsole-3.0", "AceEvent-3.0","AceHook-3.0","AceComm-3.0","AceTimer-3.0")

local options = { 
    name = "RaidGuild",
    handler = RaidGuild,
    type='group',
    args = {
        debug = {
            type = "toggle",
            name = "debug",
            desc = "Toggle debug messages",
			set = function(info,val) RaidGuild.db.profile.Debug = val; RaidGuild:Print("Debug is " .. tostring(val)) end,
			get = function(info) return RaidGuild.db.profile.Debug end,
        },
		announce = {
            type = "group",
			desc = "Announcement functions",
			name = "announce",
			args = {
				boss = {
					type = "toggle",
					name = "boss",
					desc = "Toggle boss down messages",
					set = function(info,val) RaidGuild.db.profile.ShowBossDownings = val; RaidGuild:Print("ShowBossDownings is " .. tostring(val)) end,
					get = function(info) return RaidGuild.db.profile.ShowBossDownings end,
				},
				lootsummary = {
					type = "toggle",
					name = "lootsummary",
					desc = "Toggle loot summary messages",
					set = function(info,val) RaidGuild.db.profile.ShowRaidLootOverview = val; RaidGuild:Print("ShowRaidLootOverview is " .. tostring(val)) end,
					get = function(info) return RaidGuild.db.profile.ShowRaidLootOverview end,
				},
				loot = {
					type = "toggle",
					name = "loot",
					desc = "Toggle loot handed out messages",
					set = function(info,val) RaidGuild.db.profile.ShowRaidLootHandedOut = val; RaidGuild:Print("ShowRaidLootHandedOut is " .. tostring(val)) end,
					get = function(info) return RaidGuild.db.profile.ShowRaidLootHandedOut end,
				},
			},
		},
		raid = {
            type = "group",
			desc = "Raid functions",
			name = "raid",
			args = {
				setup = {
					type = "execute",
					name = "setup",
					desc = "Sets up a new raid",
					func = function() RaidGuild:SetupRaid() end,
				},
				clear = {
					type = "execute",
					name = "clear",
					desc = "Clear all information from the raidtracker",
					func = function() RaidGuild:ClearRaid() end,
				},
				stop = {
					type = "execute",
					name = "stop",
					desc = "Stops the current raid",
					func = function() RaidGuild:StopRaid() end,
				},
				start = {
					type = "execute",
					name = "start",
					desc = "Start the current raid",
					func = function() RaidGuild:StartRaid() end,
				},
				autostart = {
					type = "toggle",
					name = "autostart",
					desc = "Autostart the tracker",
					set = function(info,val) RaidGuild.db.profile.RaidAutoStart = val; RaidGuild:Print("RaidAutoStart is " .. tostring(val)) end,
					get = function(info) return RaidGuild.db.profile.RaidAutoStart end,
				},
				export = {
					type = "execute",
					name = "export",
					desc = "Export to Website",
					func = function() RaidGuild:ExportRaid() end,
				},
				invitetime = {
					type = "input",
					name = "invitetime",
					desc = "Set Invite Timer End for this raid (eg. 19:50)",
					set = function(info,val)  RaidGuild.currentRaid["inviteend_time"] = val; RaidGuild:Print("InviteEnd is " .. tostring(val)); RaidGuild:UpdateInviteEnd() end,
					get = function(info) return  RaidGuild.currentRaid["inviteend_time"] end,
				},
				defaultinvitetime = {
					type = "input",
					name = "defaultinvitetime",
					desc = "Set Default Invite Time End (eg. 19:50)",
					set = function(info,val)  RaidGuild.db.profile.DefaultInviteEnd = val; RaidGuild:Print("DefaultInviteEnd is " .. tostring(val)) end,
					get = function(info) return  RaidGuild.db.profile.DefaultInviteEnd end,
				},
			},		
        },
		raidset = {
            type = "group",
			desc = "Raid Edit functions",
			name = "raidset",
			args = {
				diff = {
					type = "input",
					name = "diff",
					desc = "Set Difficulty (1=Normal, 2=Heroic)",
					set = function(info,val)  RaidGuild.currentRaid["difficulty"] = val; RaidGuild:Print("Difficulty is " .. tostring(val)) end,
					get = function(info) return  RaidGuild.currentRaid["difficulty"] end,
				},
				zone = {
					type = "input",
					name = "zone",
					desc = "Set Zone",
					set = function(info,val)  RaidGuild.currentRaid["zone"] = val; RaidGuild:Print("Zone is " .. tostring(val)) end,
					get = function(info) return  RaidGuild.currentRaid["zone"] end,
				},
			}
		},
		guild = {
            type = "group",
			desc = "Guild functions",
			name = "guild",
			args = {
				export = {
					type = "execute",
					name = "export",
					desc = "Export the guild rooster",
					func = function() RaidGuild:GuildExport() end,
				},
			}
		},
    },
}

local defaults = {
	profile = {
		Debug = false,
		ShowBossDownings = true,
		ShowRaidLootOverview = true,
		ShowRaidLootHandedOut = true,
		RaidAutoStart = true,
		DefaultInviteEnd = "19:50",
	},
	global = {
		currentRaid = 0,
		RaidLog = {},
	},
}

local deformat = LibStub("LibDeformat-3.0")

RaidGuild.templateRaid = {
	
	difficulty = 0,
	zone = "Unknown",
	raidstart = 0,
	raidstop = 0,
	inviteend = 0,
	invites = {},
	join = {},
	leave = {},
	dkptime = {},
	rooster = {},
	bossdown = {},
	wipes = {},
	loot = {},
}

RaidGuild.lastBoss = nil
RaidGuild.currentRaid = nil
RaidGuild.currentRaidID = 0

RaidGuild.isDisenchanter = false
RaidGuild.disenchantMinimum = 375

RaidGuild.checkInvitesDelay = 30 -- sec
RaidGuild.checkInvitesTimer = nil
RaidGuild.onlineMembers = {}
RaidGuild.memberRank = {}
RaidGuild.memberNotes = {}
RaidGuild.memberMain = {}

LibStub("AceConfig-3.0"):RegisterOptionsTable("RaidGuild", options, {"rg", "raidguild"})
RaidGuild.commPrefix = "RGC"
RaidGuild.raidQualityLog = 2 -- Quality: 0 = grey, 1 = white, 2 = green, 3 = blue, 4 = purple, 5 = legendary
RaidGuild.myTradeskills = {}

function RaidGuild:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("RaidGuildDB",defaults)
  self:Debug("Hellu thar... RaidGuild haz loadeded");
  if self.db.global.currentRaid ~= 0 then
	self:Debug("Loading RaidID",self.db.global.currentRaid )
	self.currentRaid = self.db.global.RaidLog[self.db.global.currentRaid]
	self.currentRaidID = self.db.global.currentRaid
  end
  
  -- Get an initial member list
  SetGuildRosterShowOffline(true)
  GuildRoster()
end

function RaidGuild:OnEnable()
	self:RegisterEvent("UPDATE_INSTANCE_INFO")
	self:RegisterEvent("CHAT_MSG_LOOT")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterComm(self.commPrefix .. "+AN", "R_ANNOUNCE")
	self:RegisterComm(self.commPrefix .. "+RI", "R_RAIDINFO")
	self:RegisterComm(self.commPrefix .. "+RC", "R_RAIDCOMM")
	self:RegisterComm(self.commPrefix .. "+OC", "R_OTHERCMD")
	self:RegisterComm(self.commPrefix .. "+TS", "R_TRADESEARCH")
	self:RawHook("ChatFrame_MessageEventHandler",true)
	self:HookScript(GameTooltip,"OnUpdate", "GameTooltip_OnUpdate")
end

function RaidGuild:Debug(args,...)
	if self.db.profile.Debug then
		self:Print("<Debug>",args,...) 
	end
end

function RaidGuild:GameTooltip_OnUpdate()
	local mytext=getglobal("GameTooltipTextLeft1"); 
	local text=mytext:GetText();
	local zone = GetRealZoneText()
	if self.raidZones[zone] and self.currentRaidID ~= 0 then
		if RaidGuild.itemBoss[text] ~= nil then
			self:BossDown(RaidGuild.itemBoss[text])
		end
	end
end

function RaidGuild:R_ANNOUNCE(prefix, message, distribution, sender)
	-- Raid Announce
    --self:Debug("Com AN:",sender, "sent", message)
	local cmd, arg1, arg2 = strsplit(";",message)
	if cmd == "BOSSDOWN" and self.db.profile.ShowBossDownings then
		self:Print("Boss Down: ", arg1)
	elseif cmd == "LOOTRCV" and self.db.profile.ShowRaidLootHandedOut then
		self:Print("Loot: " .. arg1 .. " receives " .. arg2)
	elseif cmd == "LOOTSUM" and self.db.profile.ShowRaidLootOverview then
		self:Print("Loot: " .. arg1);
	end
end

function RaidGuild:R_RAIDINFO(prefix, message, distribution, sender)
	-- Raid ID query
    --self:Debug("COM RI:",sender, "sent", message)
end

function RaidGuild:R_RAIDCOMM(prefix, message, distribution, sender)
	-- Communicate within the raid
    self:Debug("COM RC:",sender, "sent", message)
	local cmd, arg1, arg2, arg3  = strsplit(":",message)
	local player = UnitName("player")
	if sender ~= player then
		if cmd == "START" then
			self:Print("Raid Start inititated by ".. sender)
			
			id = tonumber(arg1)
			zone = arg2
			difficulty = tonumber(arg3)
				
			self.db.global.RaidLog[id]= self:CopyTable(self.templateRaid)
			self.currentRaid = self.db.global.RaidLog[id]
			self.currentRaidID = id
			self.db.global.currentRaid = id
				
			self.currentRaid["zone"] = zone
			self.currentRaid["difficulty"] = difficulty
				
			self:Debug("Setting up and starting RaidID",id)
			self.currentRaid["raidstart"] = time()
			self:ClearLeftPlayersBeforeStart()
		elseif cmd == "STOP" then
			self:Print("Raid Stop inititated by ".. sender)
			self:RaidStop()
		elseif cmd == "UPDATEDEST" then
			zone = arg1
			difficulty = tonumber(arg1)
			self.currentRaid["zone"] = zone
			self.currentRaid["difficulty"] = difficulty
		end
	end
end

function RaidGuild:R_OTHERCMD(prefix,message,distribution,sender)
	self:Debug("COM OC:",sender,"initiated",message);
	if message == "raidinfoupdate" then
		RequestRaidInfo()
	elseif message == "ping" then
		-- response to ping (optimally with version info)
		self:SendCommMessage(self.commPrefix .. "+OC", "pong", "WHISPER",sender)
	elseif message == "pong" then
		self:Debug("COM OC:","Got pong from",sender);
	end
end

function RaidGuild:R_TRADESEARCH(prefix, message, distribution, sender)
	-- Tradeskill Search
    self:Debug("COM TS:",sender, "sent", message)
end

function RaidGuild:UPDATE_INSTANCE_INFO()
	now = time();
	
	for i=1, GetNumSavedInstances() do
		local name, id, remain, difficulty = GetSavedInstanceInfo(i)
		if self.raidZones[name] then
			self:SendCommMessage(self.commPrefix .. "+RI", id .. ":" .. name .. ":" .. (remain + now) .. ":" .. difficulty, "GUILD")
		end
	end
end


function RaidGuild:CHAT_MSG_LOOT(eventname,msg)

	local zone = GetRealZoneText()
		
	if self.raidZones[zone] and self.currentRaidID ~= 0 then
		local player, item = deformat(msg, LOOT_ITEM)
	
		if not player then
			item = deformat(msg, LOOT_ITEM_SELF)
			if item then
				player = UnitName("player")
			end
		end
		
				
		if type(item) == "string" and type(player) == "string" then
			
			local itemName, itemLink, itemRarity,  itemLevel, itemMinLevel, itemType, itemSubtype, itemStackCount, itemEquipLocation  = GetItemInfo(item)
			local itemId = select(3, itemLink:find("item:(%d+):"))
			
			if not itemId then return end
			
			itemId = tonumber(itemId:trim())
			
			local tmp, itemEquip = strsplit("_",itemEquipLocation);
			
			if tmp == "INVTYPE" then
				itemEquipLocation = itemEquip
			else
				itemEquipLocation = "UNEQUIPPABLE"
			end
			
			if type(itemId) ~= "number" then return end
			
			if player == UnitName("player") then
					amount = select(2, deformat(msg, LOOT_ITEM_SELF_MULTIPLE))
			else
					amount = select(3, deformat(msg, LOOT_ITEM_MULTIPLE))
			end
			
			amount = tonumber(amount)
			if type(amount) ~= "number" then amount = 1 end

			if itemRarity >= self.raidQualityLog then 
				
				if self.ignoredItems[itemId] then 
					self:Debug("Ignored Loot: ",itemId)
					return 
				end
				
				if type(self.armorTokens[itemId]) == "string" then
					itemEquipLocation = self.armorTokens[itemId]
				end
				
				self:Debug("Loot:",player,"=> itemID:",itemId,"=> slot:",itemEquipLocation)
				-- Add to DKP List
				tinsert(self.currentRaid.loot,{player = player, name = itemName, itemid = itemId, quality = itemRarity, itemtype = itemEquipLocation, amount = amount, time = time(), category = "loot"})
					
				if itemRarity >= 4 and IsPartyLeader() then -- purple og derover
					-- Guild Announce: Drop
					self:SendCommMessage(self.commPrefix .. "+AN", "LOOTRCV;" .. player .. ";" .. item, "GUILD")
				end
			end
		end
	end
end


function RaidGuild:COMBAT_LOG_EVENT_UNFILTERED(eventname,timestamp,event,sourceGUID,sourceName,sourceFlags,destGUID,destName,destFlags)
	
	-- Kill check Boss/Trash
	if event == "UNIT_DIED" then
		local zone = GetRealZoneText();
		
		if self.raidZones[zone] and self.currentRaidID ~= 0 then
			
			local mob = destName;
			--self:Debug("Mob down:", mob, destGUID)
			
			if self.bossList[zone][mob] then
				self:Debug("Boss down:",mob)
				self:BossDown(mob)
			else
				if self.currentRaid["raidstart"] == 0 and self.db.profile.RaidAutoStart then
					if self.trashList[zone][mob] then
						self:Debug("Raid Started by slaying of",mob)
						self:StartRaid()
					end
				end
			end
		end
	end
end

function RaidGuild:BossDown(mob)
	if self.lastBoss ~= mob then
		self.lastBoss = mob -- ROFL
		-- Register Bossdowning
		self.currentRaid.bossdown[time()] = mob

		if IsPartyLeader() then
			self:SendCommMessage(self.commPrefix .. "+AN", "BOSSDOWN;" .. mob, "GUILD")
		end
	end
end

function RaidGuild:SKILL_LINES_CHANGED()
	local numSkills = GetNumSkillLines()
	wipe(self.myTradeskills);
	for i=1, numSkills do
		local skillName,_,_,skillRank,_,_,_, tradeSkill,_,_,_,_,_ = GetSkillLineInfo(i);
		if tradeSkill then
			self:Debug("Skills:",skillName,skillRank)
			tinsert(self.myTradeskills,skillName)
			if skillName == "Enchanting" and skillRank >= RaidGuild.disenchantMinimum then
				self.isDisenchanter = true
			end
		end
	end
	self:UnregisterEvent("SKILL_LINES_CHANGED")
end

function RaidGuild:SetupRaid()
	if self.currentRaidID ~= 0 then
		self:StopRaid()
	end

	local id = time() -- moar entropy
	self.db.global.RaidLog[id]= self:CopyTable(self.templateRaid)
	self.currentRaid = self.db.global.RaidLog[id]
	self.currentRaidID = id
	self.db.global.currentRaid = id
	self:UpdateInviteEnd()
	self:Debug("Setting up RaidID",id)
	if GetNumRaidMembers() == 0 then
		RaidGuild:RaidImport()
	end
	self:Print("Raid Setup Complete")
end

function RaidGuild:StopRaid()
	self:Debug("Stopping RaidID",self.currentRaidID)
	
	for name in pairs(self.currentRaid["rooster"]) do
		if self.currentRaid["rooster"][name] then
			self:Debug("Removed",name,"from raid");
		    self.currentRaid["leave"][name] = time()
			if self.currentRaid["dkptime"][name] then
				self.currentRaid["dkptime"][name] =  self.currentRaid["leave"][name] - max(self.currentRaid["join"][name],self.currentRaid["raidstart"]) + self.currentRaid["dkptime"][name]
			else
				self.currentRaid["dkptime"][name] =  self.currentRaid["leave"][name] - max(self.currentRaid["join"][name],self.currentRaid["raidstart"])
			end
		end
	end	
	
	if IsPartyLeader() then
		self:SendCommMessage(self.commPrefix .. "+RC", "STOP:"..self.currentRaidID, "RAID")
	end
	self.currentRaid["raidstop"] = time()
	self.currentRaid = nil
	self.currentRaidID = 0
	self.db.global.currentRaid = 0
	self:Print("Raid Stopped")
end

function RaidGuild:StartRaid()
	if self.currentRaid ~= nil then
		if self.currentRaid["raidstart"] ~= 0 then
			self:Print("Raid is already started")
		else
			if self.currentRaidID == 0 then
				self:Print("You must setup a raid before starting it")
			else
				self:Debug("Starting RaidID",self.currentRaidID)
				self.currentRaid["raidstart"] = time()
				self.currentRaid["difficulty"] = GetInstanceDifficulty() 
				self.currentRaid["zone"] = GetRealZoneText();
				if IsPartyLeader() then
					self:SendCommMessage(self.commPrefix .. "+RC", "START:"..self.currentRaidID..":"..self.currentRaid["zone"]..":"..self.currentRaid["difficulty"], "RAID")
					local player = UnitName("player")
					local lootmethod = GetLootMethod() 
					if lootmethod ~= "master" then
						SetLootMethod("master",player)
					end
				end
				self:ClearLeftPlayersBeforeStart()
				self:Print("Raid Started")
			end
		end
	else
		self:Print("You must setup a raid before starting it")
	end
end

function RaidGuild:RAID_ROSTER_UPDATE()

	if self.currentRaidID ~= 0 then
	
		local previousRooster = self:CopyTable(self.currentRaid["rooster"])
		
		for i = 1,GetNumRaidMembers() do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
			self.currentRaid["rooster"][name] = true
			if previousRooster[name] then 
			   previousRooster[name] = false
			else
				self:Debug("Added",name,"to raid")
				self.currentRaid["join"][name] = time()
				self.currentRaid["invites"][name] = false
			end
		end
		
		for name in pairs(previousRooster) do
			if previousRooster[name] then
				self:Debug("Removed",name,"from raid");
				self.currentRaid["leave"][name] = time()
				if self.currentRaid["dkptime"][name] then
					self.currentRaid["dkptime"][name] =  self.currentRaid["leave"][name] - max(self.currentRaid["join"][name],self.currentRaid["raidstart"]) + self.currentRaid["dkptime"][name]
				else
					self.currentRaid["dkptime"][name] =  self.currentRaid["leave"][name] - max(self.currentRaid["join"][name],self.currentRaid["raidstart"])
				end
				self.currentRaid["rooster"][name] = false
			end
		end
		local diff = GetDungeonDifficulty() -- change to heroic when more than 11 players in raid and not started yet
		if IsPartyLeader() and GetNumRaidMembers() > 11 and diff == 1 and self.currentRaid["raidstart"] == 0 then
			SetDungeonDifficulty(2)
		end
			
	end
			    

end

function RaidGuild:ClearRaid()
	self.db.global.RaidLog = {}
	self.db.global.currentRaid = 0
	self.currentRaid = nil
	self.currentRaidID = 0
	self:Print("Clearing raids")
end

function RaidGuild:ClearLeftPlayersBeforeStart()
	local roost = self.currentRaid["rooster"]
	for k,v in pairs(roost) do
		if v ~= true then
			self:Debug("Removing",k,"from raid dkp list")
			self.currentRaid["leave"][k] = nil
			self.currentRaid["join"][k] = nil
			self.currentRaid["dkptime"][k] = nil
		end
	end
end

-- simple shallow copy
function RaidGuild:CopyTable(src, dest)
	if type(dest) ~= "table" then dest = {} end
	if type(src) == "table" then
		for k,v in pairs(src) do
			if type(v) == "table" then
				-- try to index the key first so that the metatable creates the defaults, if set, and use that table
				v = self:CopyTable(v, dest[k])
			end
			dest[k] = v
		end
	end
	return dest
end

function RaidGuild:RaidImport()
	RaidGuildStringFrameEditBox:SetText("");
	RaidGuildStringFrameDone:SetText("Import");
	RaidGuildStringFrameEditBox:SetFocus();
	RaidGuildStringFrame:Show();
end

function RaidGuild:DoRaidImport(msg)
	local invites = { strsplit(":", msg) }
	local player = UnitName("player")
	if msg ~= "" then
		for i,invite in ipairs(invites) do
			if invite ~= player then
				self:Debug("<Invite> Adding:",invite)
				self.currentRaid["invites"][invite] = true
			end
		end
	
		self.checkInvitesTimer = self:ScheduleRepeatingTimer("CheckInvites",self.checkInvitesDelay)
		self:CheckInvites()
	end
end

function RaidGuild:CheckInvites()
	if self.currentRaidID == 0 then
		self:CancelTimer(self.checkInvitesTimer)
		return
	end 
	
	local invitesToGo = 0
	GuildRoster()
	self:Debug("<Invite>","Checking")
	
	local inv = self.currentRaid["invites"]
	
	for invite,state in pairs(inv) do
		if state then
			invitesToGo = invitesToGo + 1
			if self.onlineMembers[invite] then
				InviteUnit(invite)
				self:Debug("<Invite>","Inviting",invite);
			else
				self:Debug("<Invite>","Offline:",invite);
			end
		end
	end
	
	if invitesToGo == 0 then
		self:Debug("<Invite>","No more to invite")
		self:Print("Automatic invites ended, everybody is in the raid")
		self:CancelTimer(self.checkInvitesTimer)
	end
	
	local t = time()
	if t > self.currentRaid["inviteend"] then
		self:CancelTimer(self.checkInvitesTimer)
		self:Print("Automatic invites ended")
		local inv = self.currentRaid["invites"]
		for invite,state in pairs(inv) do
			if state then
				self:Print("No invite: "..invite)
			end
		end
	end
end


function RaidGuild:UpdateInviteEnd()
	if self.currentRaid["inviteend_time"] == nil then
		self.currentRaid["inviteend_time"] = self.db.profile.DefaultInviteEnd
	end
	
	local hour,minute = strsplit(":",self.currentRaid["inviteend_time"])
	local seconds = (hour * 60 + minute) * 60
	
	local nhour,nminute = strsplit(":",date("%H:%M"))
	local nseconds = (nhour * 60 + nminute) * 60
	
	local midnight = time() - nseconds
	self.currentRaid["inviteend"] = midnight + seconds
	
end

function RaidGuild:GUILD_ROSTER_UPDATE()
	--self:Debug("Guild update fired")

	local num = GetNumGuildMembers()
	self.onlineMembers = {}
	self.memberRank = {}
	self.memberNotes = {}
	for index=1,num do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(index);
		if online == 1 then
			self.onlineMembers[name] = true
		else
			self.onlineMembers[name] = false
		end
		self.memberRank[name] = rankIndex
		self.memberNotes[name] = note
    end
	
	if GetGuildRosterShowOffline() then
		self.guildExportReady = true
		local notes = self.memberNotes;
		for name,note in pairs(notes) do
			local pattern = ".-%((%S*)%).-";
			local pos1, pos2;
			pos1, pos2, main = string.find(note, pattern);

			if (main == nil or main == "") then
				main = nil;
			else
				main = string.upper(strsub(main, 1, 1)) .. string.lower(strsub(main, 2));
			end
			self.memberMain[name] = main
		end
	else
		self.guildExportReady = false
	end
	
	if self.guildExportNeeded then
		self:GuildExport()
	end
end

function RaidGuild:PARTY_MEMBERS_CHANGED()
	if self.currentRaidID ~= 0 and GetNumPartyMembers() > 0 then
		if GetNumRaidMembers()  == 0 then
			ConvertToRaid()
			SetDungeonDifficulty(1)
		end
	end
				
end

function RaidGuild:ChatFrame_MessageEventHandler(arg1,arg2,arg3,arg4,...)

	event = arg2
	msg = arg3
	name = arg4
	
	if (event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_OFFICER" or event == "CHAT_MSG_WHISPER") then
		if(type(self.memberMain[name]) == "string") then
			msg = "("..self.memberMain[name]..") "..msg
		end
	end
	return self.hooks.ChatFrame_MessageEventHandler(arg1,event,msg,name,...)
end


