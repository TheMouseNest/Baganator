---@class addonTableBaganator
local addonTable = select(2, ...)

function addonTable.CustomiseDialog.Components.GetCheckbox(parent, label, spacing, callback)
  spacing = spacing or 0
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetHeight(40)
  holder:SetPoint("LEFT", parent, "LEFT", 30, 0)
  holder:SetPoint("RIGHT", parent, "RIGHT", -15, 0)
  local checkBox = CreateFrame("CheckButton", nil, holder, "SettingsCheckboxTemplate")

  holder.checkBox = checkBox
  checkBox:SetPoint("LEFT", holder, "CENTER", -15 - spacing, 0)
  checkBox:SetText(label)
  checkBox:SetNormalFontObject(GameFontHighlight)
  checkBox:GetFontString():SetPoint("RIGHT", holder, "CENTER", -30 - spacing, 0)
  checkBox:GetFontString():SetPoint("LEFT", holder)
  checkBox:GetFontString():SetJustifyH("RIGHT")

  addonTable.Skins.AddFrame("CheckBox", checkBox)

  function holder:SetValue(value)
    checkBox:SetChecked(value)
  end

  holder:SetScript("OnEnter", function()
    checkBox:OnEnter()
  end)

  holder:SetScript("OnLeave", function()
    checkBox:OnLeave()
  end)

  holder:SetScript("OnMouseUp", function()
    checkBox:Click()
  end)

  checkBox:SetScript("OnClick", function()
    callback(checkBox:GetChecked())
  end)

  return holder
end

function addonTable.CustomiseDialog.Components.GetHeader(parent, text)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetPoint("LEFT", 30, 0)
  holder:SetPoint("RIGHT", -30, 0)
  holder.text = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  holder.text:SetText(text)
  holder.text:SetPoint("LEFT", 20, -1)
  holder.text:SetPoint("RIGHT", 20, -1)
  holder:SetHeight(40)
  return holder
end

function addonTable.CustomiseDialog.Components.GetTab(parent, text)
  local tab
  if addonTable.Constants.IsRetail then
    tab = CreateFrame("Button", nil, parent, "PanelTopTabButtonTemplate")
    tab:SetScript("OnShow", function(self)
      PanelTemplates_TabResize(self, 15, nil, 70)
      PanelTemplates_DeselectTab(self)
    end)
  else
    tab = CreateFrame("Button", nil, parent, "TabButtonTemplate")
    tab:SetScript("OnShow", function(self)
      PanelTemplates_TabResize(self, 0, nil, 0)
      PanelTemplates_DeselectTab(self)
    end)
  end
  tab:SetText(text)
  tab:GetScript("OnShow")(tab)
  addonTable.Skins.AddFrame("TopTabButton", tab)
  return tab
end

function addonTable.CustomiseDialog.Components.GetSlider(parent, label, min, max, scale, formatter, callback)
  scale = scale or 1
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetHeight(40)
  holder:SetPoint("LEFT", parent, "LEFT", 30, 0)
  holder:SetPoint("RIGHT", parent, "RIGHT", -30, 0)

  holder.Label = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  holder.Label:SetJustifyH("RIGHT")
  holder.Label:SetPoint("LEFT", 20, 0)
  holder.Label:SetPoint("RIGHT", holder, "CENTER", -50, 0)
  holder.Label:SetText(label)

  holder.Slider = CreateFrame("Slider", nil, holder, "MinimalSliderWithSteppersTemplate")
  holder.Slider:SetPoint("LEFT", holder, "CENTER", -32, 0)
  holder.Slider:SetPoint("RIGHT", -45, 0)
  holder.Slider:SetHeight(20)
  holder.Slider:Init(max, min, max, max - min, {
    [MinimalSliderWithSteppersMixin.Label.Right]  = CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
      return WHITE_FONT_COLOR:WrapTextInColorCode(formatter(value / scale))
    end)
  })

  holder.Slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
    callback(value / scale)
  end)

  function holder:GetValue()
    return holder.Slider.Slider:GetValue() / scale
  end

  function holder:SetValue(value)
    return holder.Slider:SetValue(value * scale)
  end

  --addonTable.Skins.AddFrame("Slider", holder.Slider)

  holder:SetScript("OnMouseWheel", function(_, delta)
    if holder.Slider.Slider:IsEnabled() then
      holder.Slider:SetValue(holder.Slider.Slider:GetValue() + delta)
    end
  end)

  return holder
end

function addonTable.CustomiseDialog.GetDraggable(callback, movedCallback)
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetSize(80, 20)
  frame.background = frame:CreateTexture(nil, "OVERLAY", nil)
  --frame.background:SetColorTexture(0.5, 0, 0.5, 0.5)
  frame.background:SetAtlas("auctionhouse-nav-button-highlight")
  frame.background:SetAllPoints()
  frame.text = frame:CreateFontString(nil, nil, "GameFontNormal")
  frame.text:SetAllPoints()
  frame:EnableMouse(true)
  frame:SetFrameStrata("DIALOG")
  frame:SetScript("OnMouseDown", function()
    callback()
    frame:Hide()
  end)
  frame:Hide()
  frame.KeepMoving = function()
    local uiScale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / uiScale, y / uiScale)
    if movedCallback then
      movedCallback()
    end
  end
  frame:SetScript("OnUpdate", frame.KeepMoving)

  return frame
end

function addonTable.CustomiseDialog.GetContainerForDragAndDrop(parent, callback)
  local container = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
  addonTable.Skins.AddFrame("InsetFrame", container)
  container.ScrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
  container.ScrollBox:SetPoint("TOPLEFT", 1, -3)
  container.ScrollBox:SetPoint("BOTTOMRIGHT", -1, 3)
  local scrollView = CreateScrollBoxListLinearView()
  scrollView:SetElementExtent(22)
  scrollView:SetElementInitializer("Button", function(frame, elementData)
    if not frame.initialized then
      frame.initialized = true
      frame:SetNormalFontObject(GameFontHighlight)
      frame:SetHighlightAtlas("auctionhouse-ui-row-highlight")
      frame:SetScript("OnClick", function(self)
        callback(self.value, self:GetText(), self.indexValue)
      end)
      frame.number = frame:CreateFontString(nil, "ARTWORK", "NumberFontNormal")
      frame.number:SetPoint("LEFT", 5, 0)
    end
    frame.indexValue = container.ScrollBox:GetDataProvider():FindIndex(elementData)
    frame.number:SetText(frame.indexValue)
    frame.value = elementData.value
    frame:SetText(elementData.label)
  end)
  container.ScrollBar = CreateFrame("EventFrame", nil, container, "WowTrimScrollBar")
  container.ScrollBar:SetPoint("TOPRIGHT")
  container.ScrollBar:SetPoint("BOTTOMRIGHT")
  ScrollUtil.InitScrollBoxListWithScrollBar(container.ScrollBox, container.ScrollBar, scrollView)
  ScrollUtil.AddManagedScrollBarVisibilityBehavior(container.ScrollBox, container.ScrollBar)
  addonTable.Skins.AddFrame("TrimScrollBar", container.ScrollBar)

  return container
end

function addonTable.CustomiseDialog.GetMouseOverInContainer(c)
  for _, f in c.ScrollBox:EnumerateFrames() do
    if f:IsMouseOver() then
      return f, f:IsMouseOver(0, f:GetHeight()/2), f.indexValue
    end
  end
end

function addonTable.CustomiseDialog.GetDropdown(parent)
  local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
  dropdown.SetupOptions = function(_, entries, values)
    dropdown:SetupMenu(function(_, rootDescription)
      for index = 1, #entries do
        local entry, value = entries[index], values[index]
        rootDescription:CreateButton(entry, function() dropdown:OnEntryClicked({value = value, label = entry}) end)
      end
    end)
  end
  dropdown.disableSelectionText = true
  dropdown.OnEntryClicked = function(_, _) end
  addonTable.Skins.AddFrame("Dropdown", dropdown)
  return dropdown
end

-- Dropdown for selecting and storing an option
function addonTable.CustomiseDialog.GetBasicDropdown(parent)
  local frame = CreateFrame("Frame", nil, parent)
  local dropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
  dropdown:SetWidth(250)
  dropdown:SetPoint("LEFT", frame, "CENTER", -32, 0)
  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("LEFT", 20, 0)
  label:SetPoint("RIGHT", frame, "CENTER", -50, 0)
  label:SetJustifyH("RIGHT")
  frame:SetPoint("LEFT", 30, 0)
  frame:SetPoint("RIGHT", -30, 0)
  frame.Init = function(_, option)
    frame.option = option.option
    label:SetText(option.text)
    local entries = {}
    for index = 1, #option.entries do
      table.insert(entries, {option.entries[index], option.values[index]})
    end
    MenuUtil.CreateRadioMenu(dropdown, function(value)
      return addonTable.Config.Get(option.option) == value
    end, function(value)
      addonTable.Config.Set(option.option, value)
    end, unpack(entries))
  end
  frame.SetValue = function(_, _)
    dropdown:GenerateMenu()
    -- don't need to do anything as dropdown's onshow handles this
  end
  frame.Label = label
  frame.DropDown = dropdown
  frame:SetHeight(40)
  addonTable.Skins.AddFrame("Dropdown", frame.DropDown)

  return frame
end
