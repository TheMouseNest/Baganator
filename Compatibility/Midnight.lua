---@class addonTableBaganator
local addonTable = select(2, ...)

if addonTable.Constants.IsMidnight then
  TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.SellPrice, function(tooltip, lineData)
    tooltip:AddLine(WHITE_FONT_COLOR:WrapTextInColorCode(SELL_PRICE .. ": " .. GetMoneyString(lineData.price)))
    return true
  end)
end
