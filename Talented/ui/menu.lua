local Talented = Talented
local L = LibStub("AceLocale-3.0"):GetLocale("Talented")

local classNames = {}
FillLocalizedClassList(classNames, false)
classNames["Ferocity"] = Talented.tabdata["Ferocity"][1].name
classNames["Tenacity"] = Talented.tabdata["Tenacity"][1].name
classNames["Cunning"] = Talented.tabdata["Cunning"][1].name

local menuColorCodes = {}
local function fill_menuColorCodes()
	for name, default in pairs(RAID_CLASS_COLORS) do
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[name] or default
		menuColorCodes[name] =  string.format("|cff%2x%2x%2x", color.r * 255, color.g * 255, color.b * 255)
	end
	menuColorCodes["Ferocity"] = "|cffe0a040"
	menuColorCodes["Tenacity"] = "|cffe0a040"
	menuColorCodes["Cunning"] = "|cffe0a040"
end
fill_menuColorCodes()

if CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS.RegisterCallback then
	CUSTOM_CLASS_COLORS:RegisterCallback(fill_menuColorCodes)
end

function Talented:OpenOptionsFrame()
	LibStub("AceConfigDialog-3.0"):Open("Talented")
end

function Talented:GetNamedMenu(name)
	local menus = self.menus
	if not menus then
		menus = {}
		self.menus = menus
	end
	local menu = menus[name]
	if not menu then
		menu = {}
		menus[name] = menu
	end
	return menu
end

local function Menu_SetTemplate(entry, template)
	if IsShiftKeyDown() then
		local frame = Talented:MakeAlternateView()
		frame.view:SetTemplate(template)
		frame.view:SetViewMode"view"
		frame:Show()
	else
		Talented:OpenTemplate(template)
	end
	Talented:CloseMenu()
end

local function Menu_IsTemplatePlayerClass()
	return Talented.template.class == select(2, UnitClass("player"))
end

local function Menu_NewTemplate(entry, class)
	Talented:OpenTemplate(Talented:CreateEmptyTemplate(class))
	Talented:CloseMenu()
end

function Talented:CreateTemplateMenu()
	--N.B. called by MakeTemplateMenu()
	local menu = self:GetNamedMenu("Template")

	local entry = self:GetNamedMenu("primary")
	entry.text = TALENT_SPEC_PRIMARY
	entry.func = Menu_SetTemplate
	menu[#menu + 1] = entry

	entry = self:GetNamedMenu("secondary")
	entry.text = TALENT_SPEC_SECONDARY
	entry.disabled = true
	entry.func = Menu_SetTemplate
	menu[#menu + 1] = entry

	if select(2, UnitClass"player") == "HUNTER" then
		entry = self:GetNamedMenu("petcurrent")
		entry.text = L["View Pet Spec"]
		entry.disabled = true
		entry.func = function ()
			Talented:PET_TALENT_UPDATE()
			Talented:OpenTemplate(Talented.pet_current)
			Talented:CloseMenu()
		end
		menu[#menu + 1] = entry
	end

	entry = self:GetNamedMenu("separator")
	if not entry.text then
		entry.text = ""
		entry.disabled = true
		entry.separator = true
	end
	menu[#menu + 1] = entry

	local list = {}
	for index, name in ipairs(CLASS_SORT_ORDER) do
		list[index] = name
	end
	list[#list + 1] = "Ferocity"
	list[#list + 1] = "Tenacity"
	list[#list + 1] = "Cunning"

	for _, name in ipairs(list) do
		entry = self:GetNamedMenu(name)
		entry.text = classNames[name]
		entry.colorCode = menuColorCodes[name]
		entry.hasArrow = true
		entry.menuList = self:GetNamedMenu(name.."List")
		menu[#menu + 1] = entry
	end

	-- menu[#menu + 1] = self:GetNamedMenu("separator")

	-- entry = self:GetNamedMenu("Inspected")
	-- entry.text = L["Inspected Characters"]
	-- entry.hasArrow = true
	-- entry.menuList = self:GetNamedMenu("InspectedList")
	-- menu[#menu + 1] = entry

	self.CreateTemplateMenu = function (self) return self:GetNamedMenu("Template") end
	return menu
end

local function Sort_Template_Menu_Entry(a, b)
	a, b = a.text, b.text
	if not a then return false end
	if not b then return true end
	return a < b
end

local function update_template_entry(entry, name, template)
	local points = template.points
	if not points then
		points = Talented:GetTemplateInfo(template)
		template.points = points
	end
	entry.text = name..points
end

function Talented:MakeTemplateMenu()
	local menu = self:CreateTemplateMenu()

	for class, color in pairs(menuColorCodes) do
		local menuList = self:GetNamedMenu(class.."List")
		local index = 1
		classdb = self.db.global.templates[class]
		if classdb ~= nil then
			for name, template in pairs(classdb) do
				if template.class == class then
					local entry = menuList[index]
					if not entry then
						entry = {}
						menuList[index] = entry
					end
					index = index + 1
					update_template_entry(entry, name, template)
					entry.func = Menu_SetTemplate
					entry.checked = (self.template == template)
					entry.arg1 = template
					entry.colorCode = color
				end
			end
		end
		for i = index, #menuList do
			menuList[i].text = nil
		end
		table.sort(menuList, Sort_Template_Menu_Entry)
		local menu = self:GetNamedMenu(class)
		menu.text = classNames[class]
		if index == 1 then
			menu.disabled = true
		else
			menu.disabled = nil
			menu.colorCode = color
		end
	end

	-- if not self.inspections then
	-- 	 self:GetNamedMenu("Inspected").disabled = true
	-- else
	-- 	 self:GetNamedMenu("Inspected").disabled = nil
	-- 	local menuList = self:GetNamedMenu("InspectedList")
	-- 	local index = 1
	-- 	for name, template in pairs(self.inspections) do
	-- 		local entry = menuList[index]
	-- 		if not entry then
	-- 			entry = {}
	-- 			menuList[index] = entry
	-- 		end
	-- 		index = index + 1
	-- 		update_template_entry(entry, name, template)
	-- 		entry.func = Menu_SetTemplate
	-- 		entry.checked = (self.template == template)
	-- 		entry.arg1 = template
	-- 		entry.colorCode = menuColorCodes[template.class]
	-- 	end
	-- 	table.sort(menuList, Sort_Template_Menu_Entry)
	-- end
	local talentGroup = GetActiveTalentGroup()
	local entry = self:GetNamedMenu("primary")
	local current = self.alternates[1]
	update_template_entry(entry, TALENT_SPEC_PRIMARY, current)
	entry.arg1 = current
	entry.checked = (self.template == current)
	if #self.alternates > 1 then
		local alt = self.alternates[2]
		local entry = self:GetNamedMenu("secondary")
		entry.disabled = false
		update_template_entry(entry, TALENT_SPEC_SECONDARY, alt)
		entry.arg1 = alt
		entry.checked = (self.template == alt)
	end

	--Pet talents
	entry = self.menus.petcurrent
	if entry then
		entry.disabled = not self.pet_current
		entry.checked = (self.template == self.pet_current)
	end

	return menu
end

StaticPopupDialogs["TALENTED_IMPORT_URL"] = {
	text = L["Enter the complete URL of a template from Blizzard talent calculator or wowhead."],
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	hasWideEditBox = 1,
	maxLetters = 256,
	whileDead = 1,
	OnShow = function (self)
		self.editBox:SetText""
	end,
	OnAccept = function(self)
		local url = self.editBox:GetText()
		self:Hide()
		local template = Talented:ImportTemplate(url)
		if template then Talented:OpenTemplate(template) end
	end,
	timeout = 0,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		StaticPopupDialogs[parent.which].OnAccept(parent)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	hideOnEscape = 1
	
}

StaticPopupDialogs["TALENTED_EXPORT_TO"] = {
	text = L["Enter the name of the character you want to send the template to."],
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 256,
	whileDead = 1,
	autoCompleteParams = AUTOCOMPLETE_LIST.WHISPER,
	OnAccept = function(self)
		local name = self.editBox:GetText()
		self:Hide()
		Talented:ExportTemplateToUser(name)
	end,
	timeout = 0,
	EditBoxOnEnterPressed =
		StaticPopupDialogs.TALENTED_IMPORT_URL.EditBoxOnEnterPressed,
	EditBoxOnEscapePressed =
		StaticPopupDialogs.TALENTED_IMPORT_URL.EditBoxOnEscapePressed,
	hideOnEscape = 1
}

function Talented:CreateActionMenu()
	local menu = self:GetNamedMenu("Action")

	local menuList = self:GetNamedMenu("NewTemplates")

	local list = {}
	for index, name in ipairs(CLASS_SORT_ORDER) do
		list[index] = name
	end
	list[#list + 1] = "Ferocity"
	list[#list + 1] = "Tenacity"
	list[#list + 1] = "Cunning"

	for _, name in ipairs(list) do
		local s = {
			text = classNames[name],
			colorCode = menuColorCodes[name],
			func = Menu_NewTemplate,
			arg1 = name
		}
		menuList[#menuList + 1] = s
	end

	menu[#menu + 1] = {
		text = L["New Template"],
		hasArrow = true,
		menuList = menuList,
	}
	local entry = self:GetNamedMenu("separator")
	if not entry.text then
		entry.text = ""
		entry.disabled = true
		entry.separator = true
	end
	menu[#menu + 1] = entry

	entry = self:GetNamedMenu("Apply")
	entry.text = L["Apply template"]
	entry.func = function () Talented:SetMode("apply") end
	menu[#menu + 1] = entry

	entry = self:GetNamedMenu("SwitchTalentGroup")
	entry.text = L["Switch to this Spec"]
	entry.func = function (entry, talentGroup) SetActiveTalentGroup(talentGroup) end
	menu[#menu + 1] = entry

	entry = self:GetNamedMenu("Delete")
	entry.text = L["Delete template"]
	entry.func = function () Talented:DeleteCurrentTemplate() end
	menu[#menu + 1] = entry

	entry = self:GetNamedMenu("Copy")
	entry.text = L["Copy template"]
	entry.func = function () Talented:OpenTemplate(Talented:CopyTemplate(Talented.template)) end
	menu[#menu + 1] = entry

	entry = self:GetNamedMenu("Target")
	entry.text = L["Set as target"]
	entry.func = function (entry, targetName, template)
		if entry.checked then
			Talented.db.char.targets[targetName] = nil
			Talented.base.view:ClearTarget()
		else
			if not template then
				Talented.base.view:ClearTarget()
			else
				Talented.db.char.targets[targetName] = {name = template.name, class = template.class}
			end
		end
	end
	entry.arg2 = self.template
	menu[#menu + 1] = entry

	menu[#menu + 1] = self:GetNamedMenu("separator")
	menu[#menu + 1] = {
		text = L["Import template ..."],
		func = function ()
			StaticPopup_Show"TALENTED_IMPORT_URL"
		end,
	}

	menu[#menu + 1] = {
		text = L["Export template"],
		hasArrow = true,
		menuList = self:GetNamedMenu("exporters"),
	}

	menu[#menu + 1] = {
		text = L["Send to ..."],
		func = function ()
			StaticPopup_Show"TALENTED_EXPORT_TO"
		end,
	}

	menu[#menu + 1] = {
		text = L["Options ..."],
		func = function ()
			Talented:OpenOptionsFrame()
		end,
	}

	self.CreateActionMenu = function (self) return self:GetNamedMenu("Action") end
	return menu
end

local function Export_Template(entry, handler)
	local url = handler(Talented, Talented.template)
	if url then
		if Talented.db.profile.show_url_in_chat then
			Talented:WriteToChat(url)
		else
			Talented:ShowInDialog(url)
		end
	end
end

function Talented:MakeActionMenu()
	local menu = self:CreateActionMenu()
	local templateTalentGroup, activeTalentGroup = self.template.talentGroup, GetActiveTalentGroup()
	local restricted = (self.template.class ~= select(2, UnitClass("player")))
	local pet_restricted = not self.GetPetClass or self:GetPetClass() ~= self.template.class
	local targetName
	if not restricted then
		targetName = templateTalentGroup or activeTalentGroup
	elseif not pet_restricted then
		targetName = UnitName"PET"
	end

	self:GetNamedMenu("Apply").disabled = templateTalentGroup or restricted and pet_restricted
	self:GetNamedMenu("Delete").disabled = templateTalentGroup or not self.db.global.templates[self.template.class][self.template.name]
	local switch = self:GetNamedMenu("SwitchTalentGroup")
	switch.disabled = (restricted or not templateTalentGroup or templateTalentGroup == activeTalentGroup)
	switch.arg1 = templateTalentGroup

	local target = self:GetNamedMenu("Target")
	if templateTalentGroup then
		target.text = L["Clear target"]
		target.arg1 = targetName
		target.arg2 = nil
		target.disabled = not self.db.char.targets[targetName]
		target.checked = nil
	else
		target.text = L["Set as target"]
		target.arg1 = targetName
		target.arg2 = self.template
		target.disabled = not targetName

		target.checked = (self.db.char.targets[targetName] and self.db.char.targets[targetName].name == self.template.name)
	end

	for _, entry in ipairs(self:GetNamedMenu("NewTemplates")) do
		local class = entry.arg1
		entry.colorCode = menuColorCodes[class]
	end

	local exporters = self:GetNamedMenu("exporters")
	local index = 1
	for name, handler in pairs(self.exporters) do
		exporters[index] = exporters[index] or {}
		exporters[index].text = name
		exporters[index].func = Export_Template
		exporters[index].arg1 = handler
		index = index + 1
	end
	for i = index, #exporters do
		exporters[i].text = nil
	end

	return menu
end

local function PlayerTalentFrameRoleDropDown_OnSelect(self)
	SetTalentGroupRole(GetActiveTalentGroup(), self.value)
	icon = Talented:GetRoleIcon(self.value)
	b = TalentedFrame.brole
	b:SetText(icon)
	b:SetSize(max(12, b:GetTextWidth()+12), 22)
end

function Talented:CreateRoleMenu()
	local menu = self:GetNamedMenu("Role")

	--Check if we're editing the current role, and exit out otherwise
	local templateTalentGroup, activeTalentGroup = self.template.talentGroup, GetActiveTalentGroup()
	if templateTalentGroup ~= activeTalentGroup then return end

	--Get current role
	local currentRole = "NONE";
	currentRole = GetTalentGroupRole(activeTalentGroup)

	--Make choices for each role
	entry = self:GetNamedMenu("Tank")
	entry.text = INLINE_TANK_ICON.." "..TANK;
	entry.func = PlayerTalentFrameRoleDropDown_OnSelect
	entry.classicChecks = true;
	entry.value = "TANK";
	entry.checked = entry.value == currentRole;
	menu[#menu + 1] = entry

	entry = self:GetNamedMenu("Healer")
	entry.text = INLINE_HEALER_ICON.." "..HEALER;
	entry.func = PlayerTalentFrameRoleDropDown_OnSelect
	entry.classicChecks = true;
	entry.value = "HEALER";
	entry.checked = entry.value == currentRole;
	menu[#menu + 1] = entry

	entry = self:GetNamedMenu("Damager")
	entry.text = INLINE_DAMAGER_ICON.." "..DAMAGER;
	entry.func = PlayerTalentFrameRoleDropDown_OnSelect
	entry.classicChecks = true;
	entry.value = "DAMAGER";
	entry.checked = entry.value == currentRole or currentRole == "NONE";
	menu[#menu + 1] = entry

	--Prevent this function running twice
	self.CreateRoleMenu = function (self) return self:GetNamedMenu("Role") end
	return menu
end

function Talented:MakeRoleMenu()
	--Create or retrieve menu
	local menu = self:CreateRoleMenu()

	--Initiate current role, then check if we're looking at a template or our own spec
	local currentRole = "NONE";
	local templateTalentGroup, activeTalentGroup = self.template.talentGroup, GetActiveTalentGroup()

	--Get current role if we are looking at our spec
	if templateTalentGroup == activeTalentGroup then
		currentRole = GetTalentGroupRole(activeTalentGroup)

		--Check/uncheck roles according to whether they are selected
		for _, entry in ipairs(self:GetNamedMenu("Role")) do
			entry.checked = entry.value == currentRole
			entry.disabled = false
		end

	--Otherwise, disable this menu
	else
		for _, entry in ipairs(self:GetNamedMenu("Role")) do
			entry.disabled = true
		end
	end
	return menu
end

function Talented:CloseMenu()
	HideDropDownMenu(1)
end

function Talented:GetDropdownFrame(frame)
	local dropdown = CreateFrame("Frame", "TalentedDropDown", nil, "UIDropDownMenuTemplate")
	dropdown.point = "TOPLEFT"
	dropdown.relativePoint = "BOTTOMLEFT"
	dropdown.displayMode = "MENU"
	dropdown.xOffset = 2
	dropdown.yOffset = 2
	dropdown.relativeTo = frame
	self.dropdown = dropdown
	self.GetDropdownFrame = function (self, frame)
		local dropdown = self.dropdown
		dropdown.relativeTo = frame
		return dropdown
	end
	return dropdown
end

local function InitializeMenu(self, menu, frame)
    UIDropDownMenu_Initialize(self, function()
        if UIDROPDOWNMENU_MENU_LEVEL == 1 then
            for _, item in ipairs(menu) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = item.colorCode and item.colorCode..item.text.."|r" or item.text
                info.checked = item.checked
                info.disabled = item.disabled
                info.hasArrow = item.hasArrow
                info.value = item
                info.isTitle = item.isTitle or item.separator
                info.notCheckable = (item.isTitle or item.separator) and true or not item.classicChecks
                
                if item.func then
                    info.func = function()
                        item.func(item, item.arg1, item.arg2)
                        if not item.keepShownOnClick then
                            CloseDropDownMenus()
                        end
                    end
                end
                
                UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
            end
        else
            local parentItem = UIDROPDOWNMENU_MENU_VALUE
            
            if parentItem and parentItem.hasArrow and parentItem.menuList then
                local subMenu
                if type(parentItem.menuList) == "string" then
                    subMenu = Talented.menus[parentItem.menuList]
                else
                    subMenu = parentItem.menuList
                end
                
                if subMenu then
                    for _, subItem in ipairs(subMenu) do
                        if subItem.text then
                            local info = UIDropDownMenu_CreateInfo()
                            info.text = subItem.colorCode and subItem.colorCode..subItem.text.."|r" or subItem.text
                            info.checked = subItem.checked
                            info.disabled = subItem.disabled
                            info.hasArrow = subItem.hasArrow
                            info.value = subItem
                            info.notCheckable = not subItem.classicChecks
                            
                            if subItem.func then
                                info.func = function()
                                    subItem.func(subItem, subItem.arg1, subItem.arg2)
                                    if not subItem.keepShownOnClick then
                                        CloseDropDownMenus()
                                    end
                                end
                            end       
                            UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
                        end
                    end
                end
            end
        end
    end, "MENU")
    
    local xOffset = frame and frame.xOffset or 0
    local yOffset = frame and frame.yOffset or 0
    ToggleDropDownMenu(1, nil, self, frame, xOffset, yOffset)
end

function Talented:OpenTemplateMenu(frame)
	if GetCVar('portal')=='CN' then
		if not self.dropdown then
			self.dropdown = CreateFrame("Frame", "TalentedDropDown", nil, "UIDropDownMenuTemplate")
		end
		InitializeMenu(self.dropdown, self:MakeTemplateMenu(), frame)
	else
		EasyMenu(self:MakeTemplateMenu(), self:GetDropdownFrame(frame))
	end
end

function Talented:OpenActionMenu(frame)
	if GetCVar('portal')=='CN' then
		if not self.dropdown then
			self.dropdown = CreateFrame("Frame", "TalentedDropDown", nil, "UIDropDownMenuTemplate")
		end
		InitializeMenu(self.dropdown, self:MakeActionMenu(), frame)
	else
		EasyMenu(self:MakeActionMenu(), self:GetDropdownFrame(frame))
	end
end

function Talented:OpenRoleMenu(frame)
	if GetCVar('portal')=='CN' then
		if not self.dropdown then
			self.dropdown = CreateFrame("Frame", "TalentedDropDown", nil, "UIDropDownMenuTemplate")
		end
		InitializeMenu(self.dropdown, self:MakeRoleMenu(), frame)
	else
		EasyMenu(self:MakeRoleMenu(), self:GetDropdownFrame(frame))
	end
end

function Talented:OpenLockMenu(frame, parent)
	if not self.dropdown then
        self.dropdown = CreateFrame("Frame", "TalentedDropDown", nil, "UIDropDownMenuTemplate")
    end
    local menu = self:GetNamedMenu("LockFrame")
    local entry = menu[1]
    if not entry then
        entry = {
            text = L["Lock frame"],
            func = function (entry, frame)
                Talented:SetFrameLock(frame, not entry.checked)
            end,
        }
        menu[1] = entry
    end
    entry.arg1 = parent
    entry.checked = self:GetFrameLock(parent)
	if GetCVar('portal')=='CN' then
		InitializeMenu(self.dropdown, menu, frame)
	else
		EasyMenu(menu, self:GetDropdownFrame(frame))
	end
end
