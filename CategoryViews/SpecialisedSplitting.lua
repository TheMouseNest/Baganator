---@class addonTableBaganator
local addonTable = select(2, ...)

local QueueReason = {
  Lockbox = 1,
  ConsumableCharges = 2,
}

local itemsToSkip = {}
local itemsWithCharges = {}

local events = {
  "UNIT_SPELLCAST_START",
  "UNIT_SPELLCAST_FAILED",
  "UNIT_SPELLCAST_FAILED_QUIET",
  "UNIT_SPELLCAST_INTERRUPTED",
  "UNIT_SPELLCAST_STOP",
}

local monitor = CreateFrame("Frame")

local timer
local counter = 0

monitor:SetScript("OnEvent", function(self, eventName, unit, castID, spellID)
  if eventName == "UNIT_SPELLCAST_START" then
    counter = counter + 1
  elseif eventName == "UNIT_SPELLCAST_INTERRUPTED" or eventName == "UNIT_SPELLCAST_FAILED_QUIET" then
    counter = counter - 1
  elseif eventName == "UNIT_SPELLCAST_STOP" then
    counter = counter - 1
    C_Timer.After(0.5, function()
      Baganator.API.RequestItemButtonsRefresh()
    end)
  end
  if counter == 0 then
    monitor:UnregisterAllEvents()
    timer:Cancel()
    timer = nil
  end
end)

addonTable.CallbackRegistry:RegisterCallback("ItemSpellUsed", function(_, itemID)
  if not itemsWithCharges[itemID] then
    return
  end

  for _, e in ipairs(events) do
    monitor:RegisterUnitEvent(e, "player")
  end
  if timer then
    timer:Cancel()
  end
  timer = C_Timer.NewTimer(15, function()
    monitor:UnregisterAllEvents()
  end)
end)

BaganatorCategoryViewsSpecialisedSplittingMixin = {}

function BaganatorCategoryViewsSpecialisedSplittingMixin:OnLoad()
  self:ResetCaches()
end

function BaganatorCategoryViewsSpecialisedSplittingMixin:ResetCaches()
  self.oldGUIDCache = self.guidCache or {}
  self.guidCache = {}
end

function BaganatorCategoryViewsSpecialisedSplittingMixin:Cancel()
  self:SetScript("OnUpdate", nil)
end

function BaganatorCategoryViewsSpecialisedSplittingMixin:OnHide()
  self.oldGUIDCache = {}
  self:Cancel()
end

function BaganatorCategoryViewsSpecialisedSplittingMixin:ApplySplitting(everything, callback)
  self.start = debugprofilestop()
  self.everything = everything
  self.callback = callback

  if not Syndicator.Search.GetTooltipInfoSpell then
    self.callback()
  end

  self.queued = {}

  for index, info in ipairs(everything) do
    if not itemsToSkip[info.itemID] and info.itemID ~= nil and info.itemLocation and C_Item.DoesItemExist(info.itemLocation) then
      Syndicator.Search.GetClassSubClass(info)
      if self.guidCache[info.guid] then
        info.specialSplitting = self.guidCache[info.guid]
        info.key = info.key .. "_" .. info.specialSplitting
        info.keyNoGUID = info.keyNoGUID .. "_" .. info.specialSplitting
        info.keyGUID = info.keyGUID .. "_" .. info.specialSplitting
      elseif info.hasLoot and not info.isBound and info.classID == Enum.ItemClass.Miscellaneous and info.subClassID == 0 then
        self.queued[index] = QueueReason.Lockbox
      elseif info.classID == Enum.ItemClass.Consumable or (addonTable.Constants.IsEra and info.classID == Enum.ItemClass.Weapon) then
        self.queued[index] = QueueReason.ConsumableCharges
      else
        itemsToSkip[info.itemID] = true
      end
    end
  end

  self:Process()
end

function BaganatorCategoryViewsSpecialisedSplittingMixin:Process()
  local keys = GetKeysArray(self.queued)
  for _, index in ipairs(keys) do
    local splitType = self.queued[index]
    if addonTable.CheckTimeout() then
      self:SetScript("OnUpdate", function()
        addonTable.ReportEntry()
        self:Process()
      end)
      return
    end

    local info = self.everything[index]

    if itemsToSkip[info.itemID] then
      self.queued[index] = nil
    else
      Syndicator.Search.GetTooltipInfoSpell(info)

      if info.tooltipInfoSpell then
        if splitType == QueueReason.Lockbox then
          for _, line in ipairs(info.tooltipInfoSpell.lines) do
            if line.leftText == LOCKED then
              info.specialSplitting = 0
              break
            end
          end
          if not info.specialSplitting then
            info.specialSplitting = 1
          end
        elseif splitType == QueueReason.ConsumableCharges then
          local chargeText = addonTable.Utilities.GetChargesLine(info.tooltipInfoSpell)
          if chargeText == nil then
            itemsToSkip[info.itemID] = true
          else
            info.specialSplitting = tonumber((chargeText:match("%d+") or 0))
            itemsWithCharges[info.itemID] = true
          end
        end
        if info.specialSplitting then
          if self.oldGUIDCache[info.guid] and self.oldGUIDCache[info.guid] ~= info.specialSplitting then
            addonTable.NewItems:MarkNewItemTimeout(info.itemLocation.bagID, info.itemLocation.slotIndex, info.guid)
          end
          self.guidCache[info.guid] = info.specialSplitting
          info.key = info.key .. "_" .. info.specialSplitting
          info.keyNoGUID = info.keyNoGUID .. "_" .. info.specialSplitting
          info.keyGUID = info.keyGUID .. "_" .. info.specialSplitting
        end
        info.tooltipInfoSpell = nil
        self.queued[index] = nil
      end
    end
  end

  if next(self.queued) then
    self:SetScript("OnUpdate", function()
      addonTable.ReportEntry()
      self:Process()
    end)
  else
    self.oldGUIDCache = {}
    self:SetScript("OnUpdate", nil)
    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("splitting took", debugprofilestop() - self.start)
    end
    self.callback()
  end
end
