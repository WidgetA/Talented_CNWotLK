local L = LibStub("AceLocale-3.0"):GetLocale("Talented")
local Talented = Talented

local LAYOUT_BASE_X = 4
local LAYOUT_BASE_Y = 24

local LAYOUT_OFFSET_X, LAYOUT_OFFSET_Y, LAYOUT_DELTA_X, LAYOUT_DELTA_Y
local LAYOUT_SIZE_X

local function RecalcLayout(offset)
	if LAYOUT_OFFSET_X ~= offset then

		LAYOUT_OFFSET_X = offset
		LAYOUT_OFFSET_Y = LAYOUT_OFFSET_X

		LAYOUT_DELTA_X = LAYOUT_OFFSET_X / 2
		LAYOUT_DELTA_Y = LAYOUT_OFFSET_Y / 2

		LAYOUT_SIZE_X = --[[LAYOUT_MAX_COLUMNS]] 4 * LAYOUT_OFFSET_X + LAYOUT_DELTA_X

		return true
	end
end

local function offset(row, column)
	return (column - 1) * LAYOUT_OFFSET_X + LAYOUT_DELTA_X, - ((row - 1) * LAYOUT_OFFSET_Y + LAYOUT_DELTA_Y)
end

--[[
Views are an abstract representation of a Talent tree "view". It should allow
Talented to display the player and it's pet trees at the same time.

Views have several attributes:
	view.frame: parent frame of the view (can be the main Talented window or another) *read only*
	view.name: the name of the view. Must be unique. *read only*
	view.class: the class of the view. *auto on :SetTemplate()*
	view.pet: the view is for a pet tree. *auto on :SetTemplate()*
	view.spec: the view is for an actual spec, it can't be modified except via :LearnTalent() *auto on :SetTemplate()*
	view.mode: view display mode. Can be "view" or "edit" *changed via :SetViewMode()*
	view.template: the template associated with the view *changed via :SetTemplate()*
	view.target: the target template associated with the view *changed via :SetTemplate()*
]]

local TalentView = {}
function TalentView:init(frame, name)
	self.frame = frame
	self.name = name
	self.elements = {}
end

function TalentView:SetUIElement(element, ...)
	self.elements[strjoin("-", ...)] = element
end

function TalentView:GetUIElement(...)
	return self.elements[strjoin("-", ...)]
end

function TalentView:SetViewMode(mode, force)
	if mode ~= self.mode or force then
		self.mode = mode
		self:Update()
	end
end

local function GetMaxPoints(...)
	local total = 0
	if GetCVar('portal')=='CN' then
		for i = 1, GetNumTalentTabs(...) do
			local _, _, _, _, point, _, _, _ = GetTalentTabInfo(i, ...)
			total = total + point
		end
	else
		for i = 1, GetNumTalentTabs(...) do
			total = total + select(3, GetTalentTabInfo(i, ...))
		end
	end
	return total + GetUnspentTalentPoints(...)
end

function TalentView:SetClass(class, force)
	if self.class == class and not force then return end
	local pet = not RAID_CLASS_COLORS[class]
	self.pet = pet

	Talented.Pool:changeSet(self.name)
	wipe(self.elements)
	local talents = Talented:UncompressSpellData(class)

	if not LAYOUT_OFFSET_X then
		RecalcLayout(Talented.db.profile.offset)
	end
	local top_offset, bottom_offset = LAYOUT_BASE_X, LAYOUT_BASE_X
	if self.frame.SetTabSize then
		local n = #talents
		self.frame:SetTabSize(n)
		top_offset = top_offset + (4 - n) * LAYOUT_BASE_Y
		if Talented.db.profile.add_bottom_offset then
			bottom_offset = bottom_offset + LAYOUT_BASE_Y
		end
	end
	local first_tree = talents[1]
	local finalRow = first_tree[#first_tree].row
	local size_y = finalRow * LAYOUT_OFFSET_Y + LAYOUT_DELTA_Y
	for tab, tree in ipairs(talents) do
		local frame = Talented:MakeTalentFrame(self.frame, LAYOUT_SIZE_X, size_y)
		frame.tab = tab
		frame.view = self
		frame.pet = self.pet

		local background = Talented.tabdata[class][tab].background
		frame.topleft:SetTexture("Interface\\TalentFrame\\"..background.."-TopLeft")
		frame.topright:SetTexture("Interface\\TalentFrame\\"..background.."-TopRight")
		frame.bottomleft:SetTexture("Interface\\TalentFrame\\"..background.."-BottomLeft")
		frame.bottomright:SetTexture("Interface\\TalentFrame\\"..background.."-BottomRight")

		self:SetUIElement(frame, tab)

		for index, talent in ipairs(tree) do
			if not talent.inactive then
				local button = Talented:MakeButton(frame)
				button.id = index

				self:SetUIElement(button, tab, index)

				button:SetPoint("TOPLEFT", offset(talent.row, talent.column))
				button.texture:SetTexture(Talented:GetTalentIcon(class, tab, index))
				button:Show()
			end
		end

		for index, talent in ipairs(tree) do
			local req = talent.req
			if req then
				local elements = {}
				Talented.DrawLine(elements, frame, offset, talent.row, talent.column, tree[req].row, tree[req].column)
				self:SetUIElement(elements, tab, index, req)
			end
		end

		frame:SetPoint("TOPLEFT", (tab-1) * LAYOUT_SIZE_X + LAYOUT_BASE_X, -top_offset)
	end
	self.frame:SetSize(#talents * LAYOUT_SIZE_X + LAYOUT_BASE_X * 2, size_y + top_offset + bottom_offset)
	self.frame:SetScale(Talented.db.profile.scale)

	self.class = class
	self:Update()
end

function TalentView:SetTemplate(template, target)
	if template then Talented:UnpackTemplate(template) end
	-- if target then Talented:UnpackTemplate(target) end This will use target's code object, which we have NOT been updating

	--Pack target
	local curr = self.target
	self.target = target
	if curr and curr ~= template and curr ~= target then
		Talented:PackTemplate(curr)
	end

	--Pack template
	curr = self.template
	self.template = template
	if curr and curr.name and curr ~= template and curr ~= target then --make sure template still exists, in which case it AND its name should exist
		Talented:PackTemplate(curr)
	end

	--Set current spec and class
	self.spec = template.talentGroup
	self:SetClass(template.class)
	return self:Update()
end

function TalentView:ClearTarget()
	if self.target then
		self.target = nil
		self:Update()
	end
end

function TalentView:GetReqLevel(total)
	if not self.pet then
		return total == 0 and 1 or total + 9
	else
		if total == 0 then return 10 end
		if total > 16 then
			return 60 + (total - 15) * 4 -- this spec requires Beast Mastery
		else
			return 16 + total * 4
		end
	end
end

local GRAY_FONT_COLOR = GRAY_FONT_COLOR
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
local GREEN_FONT_COLOR = GREEN_FONT_COLOR
local RED_FONT_COLOR = RED_FONT_COLOR
local LIGHTBLUE_FONT_COLOR = { r = 0.3, g = 0.9, b = 1 }
function TalentView:Update()
	local template, target = self.template, self.target
	local total = 0
	local info = Talented:UncompressSpellData(template.class)
	local at_cap = Talented:IsTemplateAtCap(template)
	local allowEditing = (self.mode == "edit" or template.talentGroup==nil)

	for tab, tree in ipairs(info) do
		local count = 0
		for index, talent in ipairs(tree) do
			local rank = template[tab] and template[tab][index] or 0 --template[tab] ? template[tab][index] : 0
			count = count + rank
			local button = self:GetUIElement(tab, index)
			if button == nil then
				print(template.class, info, at_cap, tab, tree, index, talent, button)
				for k,v in pairs(talent) do print(k, v) end
			end
			local color = GRAY_FONT_COLOR
			local state = Talented:GetTalentState(template, tab, index)
			if state == "empty" and (at_cap or not allowEditing) then
				state = "unavailable"
			end
			if state == "unavailable" then
				button.texture:SetDesaturated(1)
				button.slot:SetVertexColor(0.65, 0.65, 0.65)
				button.rank:Hide()
				button.rank.texture:Hide()
			else
				button.rank:Show()
				button.rank.texture:Show()
				button.rank:SetText(rank)
				button.texture:SetDesaturated(nil)
				if state == "full" then
					color = NORMAL_FONT_COLOR
				else
					color = GREEN_FONT_COLOR
				end
				button.slot:SetVertexColor(color.r, color.g, color.b)
				button.rank:SetVertexColor(color.r, color.g, color.b)
			end
			local req = talent.req
			if req then
				local ecolor = color
				if ecolor == GREEN_FONT_COLOR then
					if allowEditing then
						local s = Talented:GetTalentState(template, tab, req)
						if s ~= "full" then
							ecolor = RED_FONT_COLOR
						end
					else
						ecolor = NORMAL_FONT_COLOR
					end
				end
				for _, element in ipairs(self:GetUIElement(tab, index, req)) do
					element:SetVertexColor(ecolor.r, ecolor.g, ecolor.b)
				end
			end
			local targetvalue = target and target[tab][index]
			if targetvalue and (targetvalue > 0 or rank > 0) then
				local btarget = Talented:GetButtonTarget(button)
				btarget:Show()
				btarget.texture:Show()
				btarget:SetText(targetvalue)
				local tcolor
				if rank < targetvalue then
					tcolor = LIGHTBLUE_FONT_COLOR
				elseif rank == targetvalue then
					tcolor = GRAY_FONT_COLOR
				else
					tcolor = RED_FONT_COLOR
				end
				btarget:SetVertexColor(tcolor.r, tcolor.g, tcolor.b)
			elseif button.target then
				button.target:Hide()
				button.target.texture:Hide()
			end
		end

		local frame = self:GetUIElement(tab)
		frame.name:SetFormattedText(L["%s (%d)"], Talented.tabdata[template.class][tab].name, count)
		total = total + count
		local clear = frame.clear
		if count <= 0 or not allowEditing or self.spec then
			clear:Hide()
		else
			clear:Show()
		end
	end
	local maxpoints = GetMaxPoints(nil, nil, self.spec)
	local points = self.frame.points
	if points then
		if Talented.db.profile.show_level_req then
			level =  self:GetReqLevel(total)
			if self.pet and total>16 then
				beastMasteryTalentName = select(1, GetSpellInfo(53270))
				points:SetFormattedText(L["Level %d (requires %s)"], level, beastMasteryTalentName)
			else
				points:SetFormattedText(L["Level %d"], level)
			end
		else
			points:SetFormattedText(L["%d/%d"], total, maxpoints)
		end
		local color
		if total < maxpoints then
			color = GREEN_FONT_COLOR
		elseif total > maxpoints then
			color = RED_FONT_COLOR
		else
			color = NORMAL_FONT_COLOR
		end
		points:SetTextColor(color.r, color.g, color.b)
	end

	local pointsleft = self.frame.pointsleft
	if pointsleft then
		if maxpoints ~= total and template.talentGroup then
			pointsleft:Show()
			pointsleft.text:SetFormattedText(L["You have %d talent |4point:points; left"], maxpoints - total)
		else
			pointsleft:Hide()
		end
	end

	local edit = self.frame.editname
	if edit then
		if template.talentGroup then
			edit:Hide()
		else
			edit:Show()
			edit:SetText(template.name)
		end
	end

	local checkbox, activateBtn, roleSelectBtn = self.frame.checkbox, self.frame.bactivate, self.frame.brole
	if checkbox then
		if template.talentGroup == GetActiveTalentGroup() then 
			if activateBtn then activateBtn:Hide() end
			roleSelectBtn:Show()
			checkbox:Show()
			checkbox.label:SetText(L["Edit talents"])
			checkbox.tooltip = L["Toggle editing of talents."]
		elseif template.talentGroup then
			checkbox:Hide()
			roleSelectBtn:Hide()
			if activateBtn then
				activateBtn.talentGroup = template.talentGroup
				activateBtn:Show()
			end
		else
			if activateBtn then activateBtn:Hide() end
			checkbox:Hide()
			roleSelectBtn:Hide()
			-- checkbox:Show()
			-- checkbox.label:SetText(L["Edit template"])
			-- checkbox.tooltip =L["Toggle editing of the template."]
		end
		checkbox:SetChecked(self.mode == "edit")
	end
	
	local targetname = self.frame.targetname
	if targetname then
		if template.talentGroup then
			targetname:Show()
			if template.talentGroup == GetActiveTalentGroup() and target then
				targetname:SetText(L["Target: %s"]:format(target.name))
			elseif template.talentGroup == 1 then
				targetname:SetText(TALENT_SPEC_PRIMARY)
			else
				targetname:SetText(TALENT_SPEC_SECONDARY)
			end
		else
			targetname:Hide()
		end
	end
end

function TalentView:SetTooltipInfo(owner, tab, index)
	Talented:SetTooltipInfo(owner, self.class, tab, index)
end

function TalentView:OnTalentClick(button, tab, index)
	if IsModifiedClick"CHATLINK" then
		local link = Talented:GetTalentLink(self.template, tab, index)
		if link then
			ChatEdit_InsertLink(link)
		end
	else
		self:UpdateTalent(tab, index, button == "LeftButton" and 1 or -1)
	end
end

function TalentView:UpdateTalent(tab, index, offset)
	--Don't allow editing of current talents if looking @ current template
	if self.mode ~= "edit" and self.spec then return end
	
	if self.spec then
		-- Applying talent
		if offset > 0 then
			Talented:LearnTalent(self.template, tab, index)
		end
		return
	end
	local template = self.template

	if offset > 0 and Talented:IsTemplateAtCap(template) then return end
	local s = Talented:GetTalentState(template, tab, index)

	local ranks = Talented:GetTalentRanks(template.class, tab, index)
	local original = template[tab][index]
	local value = original + offset
	if value < 0 or s == "unavailable" then
		value = 0
	elseif value > ranks then
		value = ranks
	end
	Talented:Debug("Updating %d-%d : %d -> %d (%d)", tab, index, original, value, offset)
	if value == original or not Talented:ValidateTalentBranch(template, tab, index, value) then
		return
	end
	template[tab][index] = value
	template.points = nil
	for _, view in Talented:IterateTalentViews(template) do
		view:Update()
	end
	Talented:UpdateTooltip()
	return true
end

function TalentView:ClearTalentTab(tab)
	local template = self.template
	if template and not template.talentGroup then
		local tab = template[tab]
		for index, value in ipairs(tab) do
			tab[index] = 0
		end
	end
	for _, view in Talented:IterateTalentViews(template) do
		view:Update()
	end
end

Talented.views = {}
Talented.TalentView = {
	__index = TalentView,
	new = function (self, ...)
		local view = setmetatable({}, self)
		view:init(...)
		table.insert(Talented.views, view)
		return view
	end,
}

local function next_TalentView(views, index)
	index = (index or 0) + 1
	local view = views[index]
	if not view then
		return nil
	else
		return index, view
	end
end

function Talented:IterateTalentViews(template)
	local next
	if template then
		next = function (views, index)
			while true do
				index = (index or 0) + 1
				local view = views[index]
				if not view then
					return nil
				elseif view.template == template then
					return index, view
				end
			end
		end
	else
		next = next_TalentView
	end
	return next, self.views
end

function Talented:ViewsReLayout(force)
	if RecalcLayout(self.db.profile.offset) or force then
		for _, view in self:IterateTalentViews() do
			view:SetClass(view.class, true)
		end
	end
end
