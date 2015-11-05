-----------------------------------------------------------------------------------------------
-- Client Lua Script for StratPad
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "ICCommLib"
require "ICComm"
 
-----------------------------------------------------------------------------------------------
-- StratPad Module Definition
-----------------------------------------------------------------------------------------------
local StratPad = {} 

local icons = {
	-- Marks
	["bomb"] 			= "Icon_Windows_UI_CRB_Marker_Bomb",
	["chicken"] 		= "Icon_Windows_UI_CRB_Marker_Chicken",
	["crosshair"] 		= "Icon_Windows_UI_CRB_Marker_Crosshair",
	["ghost"] 			= "Icon_Windows_UI_CRB_Marker_Ghost",
	["Mask"] 			= "Icon_Windows_UI_CRB_Marker_Mask",
	["octopus"] 		= "Icon_Windows_UI_CRB_Marker_Octopus",
	["pig"] 			= "Icon_Windows_UI_CRB_Marker_Pig",
	["toaster"] 		= "Icon_Windows_UI_CRB_Marker_Toaster",
	["ufo"] 			= "Icon_Windows_UI_CRB_Marker_Ufo",
	["bomb"] 			= "Icon_Windows_UI_CRB_Marker_Bomb",
	-- Classes
	["engineer"]		= "UI_Icon_CharacterCreate_Class_Engineer",
	["esper"]			= "UI_Icon_CharacterCreate_Class_Esper",
	["medic"]			= "UI_Icon_CharacterCreate_Class_Medic",
	["spellslinger"]	= "UI_Icon_CharacterCreate_Class_Spellslinger",
	["stalker"]			= "UI_Icon_CharacterCreate_Class_Stalker",
	["warrior"]			= "UI_Icon_CharacterCreate_Class_Warrior",
	-- Roles
	["tank"]			= "sprCharC_iconArchType_Tank",
	["healer"]			= "sprCharC_iconArchType_Healer",
	["dps"]				= "sprCharC_iconArchType_Melee",
	-- Paths
	["explorer"]		= "UI_Icon_CharacterCreate_Path_Explorer",
	["scientist"]		= "UI_Icon_CharacterCreate_Path_Scientist",
	["settler"]			= "UI_Icon_CharacterCreate_Path_Settler",
	["soldier"]			= "UI_Icon_CharacterCreate_Path_Soldier",
	-- Skills
	["kick"]			= "Icon_SkillPhysical_UI_wr_punt",
	-- misc
	["danger"]			= "sprNP_HighLevel"
}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function StratPad:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.config = {}
    return o
end

function StratPad:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- StratPad OnLoad
-----------------------------------------------------------------------------------------------
function StratPad:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("StratPad.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	Apollo.RegisterTimerHandler("StratPad_Connect", "Connect", self)
end

-----------------------------------------------------------------------------------------------
-- StratPad OnDocLoaded
-----------------------------------------------------------------------------------------------
function StratPad:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "StratPadMain", nil, self)
		self.wndDisplay = Apollo.LoadForm(self.xmlDoc, "StratPadDisplay", nil, self)
		self.wndPreview = Apollo.LoadForm(self.xmlDoc, "StratPadPreview", nil, self)
		
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		if self.wndDisplay == nil then
			Apollo.AddAddonErrorText(self, "Could not load the display window for some reason.")
			return
		end
		if self.wndPreview == nil then
			Apollo.AddAddonErrorText(self, "Could not load the preview window for some reason.")
			return
		end
		
		if self.config ~= nil then
			if self.config.mainWindowOffset and self.config.mainWindowOffset ~= nil then
				self.wndMain:SetAnchorOffsets(unpack(self.config.mainWindowOffset))
			end
			if self.config.displayWindowOffset and self.config.displayWindowOffset ~= nil then
				self.wndDisplay:SetAnchorOffsets(unpack(self.config.displayWindowOffset))
			end
			if self.config.previewWindowOffset and self.config.previewWindowOffset ~= nil then
				self.wndPreview:SetAnchorOffsets(unpack(self.config.previewWindowOffset))
			end
		end
				
	    self.wndMain:Show(false, true)
		self.wndDisplay:Show(false, true)
		self.wndPreview:Show(false, true)
	
		-- Connect to ICComm Channel
		self:Connect()
	
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("stratpad", "OnStratPadOn", self)
		-- Apollo.RegisterSlashCommand("st", "OnStratPadOn", self)


		-- Do additional Addon initialization here
	end
end

function StratPad:Connect()
	self.share = ICCommLib.JoinChannel("StratPad", ICCommLib.CodeEnumICCommChannelType.Group)
	
	if self.share:IsReady() then
		self.share:SetReceivedMessageFunction("OnMessageReceived", self)
	else
		Apollo.CreateTimer("StratPad_Connect", 3, false)
	end
end

-----------------------------------------------------------------------------------------------
-- StratPad Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/sp"
function StratPad:OnStratPadOn()
	self.wndMain:Invoke() -- show the window
end



function StratPad:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
		
	local tData = {}
	
	self.config.mainWindowOffset = { self.wndMain:GetAnchorOffsets() }
	self.config.displayWindowOffset = { self.wndDisplay:GetAnchorOffsets() }
	self.config.previewWindowOffset = { self.wndPreview:GetAnchorOffsets() }

	tData.config = self:DeepCopy(self.config)
	--tData.data = self:DeepCopy(self.data)
	
	return tData
end

function StratPad:OnRestore(eLevel, tData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	
	if tData.config then
		self.config = self:DeepCopy(tData.config)
	end

	if tData.data then
		self.data = self:DeepCopy(tData.data)
	end
end

-----------------------------------------------------------------------------------------------
-- StratPadForm Events
-----------------------------------------------------------------------------------------------

function StratPad:OnMessageReceived(channel, strMessage, idMessage)
	self:DisplayMessage(self.wndDisplay, strMessage)
end

-- when the OK button is clicked
function StratPad:OnSend()
	local msg = self.wndMain:FindChild("EditBox"):GetText()
	if self.share:IsReady() then
		self.share:SendMessage(msg)
		self:DisplayMessage(self.wndDisplay, msg)
	end
end

function StratPad:OnPreview()
	local msg = self.wndMain:FindChild("EditBox"):GetText()
	
	self:DisplayMessage(self.wndPreview, msg)
end

function StratPad:DisplayMessage(wndControl, strMessage)
	if wndControl ~= self.wndDisplay and wndControl ~= self.wndPreview then return end
	
	local xml = self:BuildXMLFromMessage(strMessage)
	
	wndControl:SetDoc(xml)
	wndControl:SetHeightToContentHeight()
	
	wndControl:Show(true, true)
end

function StratPad:BuildXMLFromMessage(message)
	local rows = self:BuildTableFromMessage(message)
	local xml = XmlDoc.new()
	
	for ri, row in ipairs(rows) do
		xml:AddLine("", ApolloColor.new("white"), "CRB_InterfaceMedium", "Left")
		for pi, part in ipairs(row) do
			if part.text then
				xml:AppendText(part.text, part.color or "white", "CRB_InterfaceMedium", "Left")
			elseif part.icon then
				local icon = icons[part.icon] or part.icon
				xml:AppendImage(icon, 20, 20)
			else
				xml:AppendText(" ")
			end
		end
	end
	--[[	
	xml:AddLine("", ApolloColor.new("white"), "CRB_InterfaceMedium", "Left")
	xml:AppendImage(icons["chicken"], 16, 16)
	xml:AppendText(message, ApolloColor.new("ff33ff33"), "CRB_InterfaceMedium", "Left")
	]]--
	return xml
end

function StratPad:BuildTableFromMessage(message)
	local result = {}
	
	local msgRows = self:Split(message, "\n")
	
	-- Just text for now
	-- Just having a single {medic} on this fight
	-- Stack on {bomb} then goto {chicken} and dance
	-- Testing with |cFFFF0000this should be colored|r and this should also |cFF00FF00some more color|r
	-- Testing with both {bomb} and |cFF0000FFcolor|r
	-- And other order |cFFFFFF00color first|r and then the icon {warrior}
	for i,str in ipairs(msgRows) do
		local row = {}
		self:FormatString(row, str)
		table.insert(result, row)
	end
	
	return result
end

function StratPad:FormatString(list, str)
	local bIcon = string.find(str, "{%a+}")
	
	if bIcon then
		local icon = string.match(str, "{%a+}")
		if bIcon > 1 then
			local t = { text = string.sub(str, 1, bIcon - 2) }
			table.insert(list, t)
			str = string.sub(str, bIcon)
		else
			icon = string.sub(icon, 2, string.len(icon) - 1)
			table.insert(list, { icon = icon })
			str = string.sub(str, string.len(icon) + 4)
		end
		self:FormatString(list, str)
	else
		if str == "" then
			str = " "
		end
		table.insert(list, { text = str })
	end
end

--[[
local result = {
	rows = {
		[1] = {
			[1] = { text = "Stack on " },
			[2] = { icon = "bomb" },
			[3] = { text = " during P1", color = ApolloColor.new("ffff0000") }
		},
		[2] = {
			[1] = { text = " " }
		},
		[3] = {
			[1] = { icon = "kick" },
			[2] = { text = " then stack on " },
			[3] = { icon = "chicken" },
			[4] = { text = " during P2", color = ApolloColor.new("ff0000ff") }
		}
	}
}
]]--

function StratPad:OnToggleDisplay()
	self.wndDisplay:Show(not self.wndDisplay:IsShown(), true)
	self.wndPreview:Show(not self.wndPreview:IsShown(), true)
end

function StratPad:OnClose()
	self.wndMain:Close()
end

function StratPad:OnDisplayClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= self.wndDisplay then return end
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		self.wndDisplay:Show(false, false)
	end
end

function StratPad:OnPreviewClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= self.wndPreview then return end
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		self.wndPreview:Show(false, false)
	end
end

function StratPad:OnAddButtonClick()
	Print("Add button pressed")
end

function StratPad:OnDeleteButtonClick()
	Print("Delete button pressed")
end

-----------------------------------------------------------------------------------------------
-- StratPadForm Util
-----------------------------------------------------------------------------------------------

function StratPad:DeepCopy(t)
	if type(t) == "table" then
		local copy = {}
		for k, v in next, t do
			copy[self:DeepCopy(k)] = self:DeepCopy(v)
		end
		return copy
	else
		return t
	end
end

function StratPad:TableLength(tTable)
	if tTable == nil then return 0 end
  	local count = 0
  	for _ in pairs(tTable) do count = count + 1 end
  	return count
end

function StratPad:Split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

-----------------------------------------------------------------------------------------------
-- StratPad Instance
-----------------------------------------------------------------------------------------------
local StratPadInst = StratPad:new()
StratPadInst:Init()
