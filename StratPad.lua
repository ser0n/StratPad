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
		
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		if self.wndDisplay == nil then
			Apollo.AddAddonErrorText(self, "Could not load the display window for some reason.")
			return
		end
		
		if self.config ~= nil then
			if self.config.mainWindowOffset and self.config.mainWindowOffset ~= nil then
				self.wndMain:SetAnchorOffsets(unpack(self.config.mainWindowOffset))
			end
		end
				
	    self.wndMain:Show(false, true)
		self.wndDisplay:Show(false, true)

	
		-- Connect to ICComm Channel
		self:Connect()
	
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("stratpad", "OnStratPadOn", self)
		Apollo.RegisterSlashCommand("sp", "OnStratPadOn", self)


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

function StratPad:OnMessageReceived(channel, strMessage, idMessage)
	self.wndDisplay:Show(true, true)
	self.wndDisplay:FindChild("txtDisplay"):SetText(strMessage)
end

function StratPad:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
		
	local tData = {}
	
	self.config.mainWindowOffset = { self.wndMain:GetAnchorOffsets() }

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
-- StratPadForm UI Events
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function StratPad:OnSend()
	--[[
	local msg = self.wndMain:FindChild("EditBox"):GetText()
	if self.share:IsReady() then
		self.share:SendMessage(msg)
		self.wndDisplay:Show(true, true)
		self.wndDisplay:FindChild("txtDisplay"):SetText(msg)
	end
	]]--
end

function StratPad:OnPreview()
	local msg = self.wndMain:FindChild("EditBox"):GetText()
	
	local xml = self:BuildXMLFromMessage(msg)
	
	self.wndDisplay:SetDoc(xml)
	self.wndDisplay:SetHeightToContentHeight()
	
	self.wndDisplay:Show(true, true)
	-- self.wndDisplay:SetAML("<T>" .. msg .. "</T>")
	-- self.wndDisplay:SetHeightToContentHeight()
end

function StratPad:BuildXMLFromMessage(message)
	local xml = XmlDoc.new()
		
	xml:AddLine("", ApolloColor.new("white"), "CRB_InterfaceMedium", "Left")
	xml:AppendImage(icons["chicken"], 16, 16)
	xml:AppendText(message, ApolloColor.new("ffff3333"), "CRB_InterfaceMedium")
	xml:AppendText(message, ApolloColor.new("ff33ff33"), "CRB_InterfaceMedium")
	xml:AppendText(message, ApolloColor.new("ff3333ff"), "CRB_InterfaceMedium")

	xml:AddLine("", ApolloColor.new("white"), "CRB_InterfaceMedium", "Left")
	xml:AppendText(" ", ApolloColor.new("ffff3333"), "CRB_InterfaceMedium")
	
	xml:AddLine("", ApolloColor.new("white"), "CRB_InterfaceMedium", "Left")
	xml:AppendImage(icons["chicken"], 16, 16)
	xml:AppendText(message, ApolloColor.new("ffff3333"), "CRB_InterfaceMedium")
	xml:AppendText(message, ApolloColor.new("ff33ff33"), "CRB_InterfaceMedium")
	xml:AppendText(message, ApolloColor.new("ff3333ff"), "CRB_InterfaceMedium")

	return xml
end

function StratPad:OnToggleDisplay()
	if not self.wndDisplay:IsShown() then
		self.wndDisplay:Show(true, true)
	else
		self.wndDisplay:Show(false, true)
	end
end

function StratPad:OnClose()
	self.wndMain:Close()
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

-----------------------------------------------------------------------------------------------
-- StratPad Instance
-----------------------------------------------------------------------------------------------
local StratPadInst = StratPad:new()
StratPadInst:Init()
