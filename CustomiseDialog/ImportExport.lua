---@class addonTableBaganator
local addonTable = select(2, ...)

function addonTable.CustomiseDialog.ImportData(import, name, overwrite)
  if import.addon ~= "Baganator" then
    return false, 1
  end

  if import.version <= 2 then
    import.kind = "categories"
  end


  if import.kind == "categories" then
    addonTable.CustomiseDialog.CategoriesImport(import)
  elseif import.kind == "profile" then
    import.addon = nil
    import.version = nil
    import.kind = nil
    for key in pairs(addonTable.Config.MapKeysForExport) do
      if import[key] then
        local new = {}
        for k, v in pairs(import[key]) do
          local num = tonumber(k)
          new[num or k] = v
        end
        import[key] = new
      end
    end
    if overwrite and BAGANATOR_CONFIG.Profiles[name] then
      local old = addonTable.Config.CurrentProfile
      BAGANATOR_CONFIG.Profiles[name] = import
      addonTable.Config.ChangeProfile(name, old)
    else
      if BAGANATOR_CONFIG.Profiles[name] then
        return false, 4
      end
      addonTable.Config.MakeProfile(name, false)
      local old = addonTable.Config.CurrentProfile
      BAGANATOR_CONFIG.Profiles[BAGANATOR_CURRENT_PROFILE] = import
      addonTable.Config.ChangeProfile(BAGANATOR_CURRENT_PROFILE, old)
    end
  end

  return true
end
