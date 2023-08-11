-- Configuration --------------------------------------
AUTOTRACKER_ENABLE_DEBUG_LOGGING = false
-------------------------------------------------------

print("")
print("Active Auto-Tracker Configuration")
print("---------------------------------------------------------------------")
print("Enable Item Tracking:        ", AUTOTRACKER_ENABLE_ITEM_TRACKING)
print("Enable Location Tracking:    ", AUTOTRACKER_ENABLE_LOCATION_TRACKING)
if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
    print("Enable Debug Logging:        ", "true")
end
print("---------------------------------------------------------------------")
print("")

U8_READ_CACHE = 0
U8_READ_CACHE_ADDRESS = 0

U16_READ_CACHE = 0
U16_READ_CACHE_ADDRESS = 0

-- ************************** Memory reading helper functions

function InvalidateReadCaches()
    U8_READ_CACHE_ADDRESS = 0
    U16_READ_CACHE_ADDRESS = 0
end

function ReadU8(segment, address)
    if U8_READ_CACHE_ADDRESS ~= address then
        U8_READ_CACHE = segment:ReadUInt8(address)
        U8_READ_CACHE_ADDRESS = address
    end

    return U8_READ_CACHE
end

function ReadU16(segment, address)
    if U16_READ_CACHE_ADDRESS ~= address then
        U16_READ_CACHE = segment:ReadUInt16(address)
        U16_READ_CACHE_ADDRESS = address
    end

    return U16_READ_CACHE
end

-- *************************** Game status

function isInGame()
    local mainModuleIdx = AutoTracker:ReadU16(0x3000c70, 0)

    local inGame = ((mainModuleIdx == 0x04) or (mainModuleIdx == 0x05) or (mainModuleIdx == 0x07) or (mainModuleIdx == 0x09))
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
        print("*** In-game Status: ", '0x3000c70', string.format('0x%x', mainModuleIdx), inGame)
    end
    return inGame
end

-- ******************** Helper functions for updating items and locations

function updateSectionChestCountFromByteAndFlag(segment, locationRef, address, flag, callback)
    local location = Tracker:FindObjectForCode(locationRef)
    if location then
        -- Do not auto-track this if the user has manually modified it
        if location.Owner.ModifiedByUser then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
                print("* Skipping user modified location: ", locationRef)
            end
            return
        end

        local value = ReadU8(segment, address)
        local check = value & flag

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print("Updating chest count:", locationRef, string.format('0x%x', address),
                    string.format('0x%x', value), string.format('0x%x', flag), check ~= 0)
        end

        if check ~= 0 then
            location.AvailableChestCount = 0
            if callback then
                callback(true)
            end
        else
            location.AvailableChestCount = location.ChestCount
            if callback then
                callback(false)
            end
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
        print("***ERROR*** Couldn't find location:", locationRef)
    end
end

function updateSectionChestCountFromValue(segment, locationRef, startAddress, endAddress, targetValues, callback)
    local location = Tracker:FindObjectForCode(locationRef)
    if location then
        -- Do not auto-track this if the user has manually modified it
        if location.Owner.ModifiedByUser then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
                print("* Skipping user modified location: ", locationRef)
            end
            return
        end

        local check = 0
        local foundAddress = 0x0000000
        local foundValue = 0x0000
        local breakLoop = false
        for address = startAddress+0x02, endAddress+0x02, 0x4 do
            for i,v in ipairs(targetValues) do
                if ReadU16(segment, address) == v then
                    check = 1
                    foundAddress = address
                    foundValue = v
                    breakLoop = true
                end
            end
            if breakLoop then
                break
            end
        end

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print("Updating chest count:", locationRef, string.format('0x%x', foundAddress),
                    string.format('0x%x', foundValue), check ~= 0)
        end

        if check ~= 0 then
            location.AvailableChestCount = 0
            if callback then
                callback(true)
            end
        else
            location.AvailableChestCount = location.ChestCount
            if callback then
                callback(false)
            end
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
        print("***ERROR*** Couldn't find location:", locationRef)
    end
end

function updateAmmoFrom2Bytes(segment, code, address)
    local item = Tracker:FindObjectForCode(code)
    local value = ReadU16(segment, address)
    local hard = Tracker:ProviderCountForCode("DifficultyHard") > 0
    
    if item then
        if code == "etank" then
            if value >= 1299 or (hard and value >= 699) then
                item.AcquiredCount = 12
            else
                item.AcquiredCount = hard and (value-50)/50 or value/100
            end
        else
            local currentValue = hard and tonumber(OBJ_MISSILE.AvailableCount2) or tonumber(OBJ_MISSILE.AvailableCount1)
            local inc = hard and 2 or 5
            if currentValue == nil then
                OBJ_MISSILE:Increment(value/inc)
            elseif currentValue < value then
                OBJ_MISSILE:Increment((value - currentValue)/inc)
            elseif currentValue > value then
                OBJ_MISSILE:Decrement((currentValue - value)/inc)
            end
        end

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            if code == "etank" then
                print("Ammo:", item.Name, string.format("0x%x", address), value, item.AcquiredCount)
            else
                print("Ammo:", item.Name, string.format("0x%x", address), value, OBJ_MISSILE.AvailableCount1, OBJ_MISSILE.AvailableCount2)
            end
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
        print("***ERROR*** Couldn't find item: ", code)
    end
end

function updateAmmoFromByte(segment, code, address)
    local item = Tracker:FindObjectForCode(code)
    local value = ReadU8(segment, address)
    local hard = Tracker:ProviderCountForCode("DifficultyHard") > 0

    if item then
        if code == "super" then
            local currentValue = hard and tonumber(OBJ_SUPER.AvailableCount2) or tonumber(OBJ_SUPER.AvailableCount1)
            local inc = hard and 1 or 2
            if currentValue == nil then
                OBJ_SUPER:Increment(value/inc)
            elseif currentValue < value then
                OBJ_SUPER:Increment((value - currentValue)/inc)
            elseif currentValue > value then
                OBJ_SUPER:Decrement((currentValue - value)/inc)
            end
        else
            local currentValue = hard and tonumber(OBJ_POWER.AvailableCount2) or tonumber(OBJ_POWER.AvailableCount1)
            local inc = hard and 1 or 2
            if currentValue == nil then
                OBJ_POWER:Increment(value/inc)
            elseif currentValue < value then
                OBJ_POWER:Increment((value - currentValue)/inc)
            elseif currentValue > value then
                OBJ_POWER:Decrement((currentValue - value)/inc)
            end
        end

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            if code == "super" then
                print("Ammo:", item.Name, string.format("0x%x", address), value, OBJ_SUPER.AvailableCount1, OBJ_SUPER.AvailableCount2)
            else
                print("Ammo:", item.Name, string.format("0x%x", address), value, OBJ_POWER.AvailableCount1, OBJ_POWER.AvailableCount2)
            end
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
        print("***ERROR*** Couldn't find item: ", code)
    end
end

function updateToggleItemFromByteAndFlag(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)

        local flagTest = value & flag

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print("Item:", item.Name, string.format("0x%x", address), string.format("0x%x", value),
                    string.format("0x%x", flag), flagTest ~= 0)
        end

        if flagTest ~= 0 then
            item.Active = true
        else
            item.Active = false
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
        print("***ERROR*** Couldn't find item: ", code)
    end
end


-- ************************* Main functions

function updateDifficulty()
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        InvalidateReadCaches()
        local address = 0x300002c

        if AutoTracker:ReadU8(address, 0) > 1 then
            OBJ_DIFFICULTY:setState(1)
        else
            OBJ_DIFFICULTY:setState(0)
        end

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            local difficulty = Tracker:ProviderCountForCode("DifficultyHard") > 0 and "Hard" or "Normal"
            print("Setting:", "Difficulty", string.format("0x%x", address), AutoTracker:ReadU8(address, 0), difficulty)
        end
    end
    return true
end

function updateIBNR()
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        InvalidateReadCaches()
        local address = 0x82b1474
        local setting = Tracker:FindObjectForCode("IBNR")

        if AutoTracker:ReadU16(address, 0) == 0x48 then
            setting.Active = true
        else
            setting.Active = false
        end

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            local tfstring = Tracker:ProviderCountForCode("IBNR") > 0 and "true" or "false"
            print("Setting:", setting.Name, string.format("0x%x", address), AutoTracker:ReadU16(address, 0), tfstring)
        end
    end
    return true
end

function updatePBNR()
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        InvalidateReadCaches()
        local address = 0x802cc16
        local setting = Tracker:FindObjectForCode("PBNR")

        if AutoTracker:ReadU16(address, 0) == 0xe00e then
            setting.Active = true
        else
            setting.Active = false
        end

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            local tfstring = Tracker:ProviderCountForCode("PBNR") > 0 and "true" or "false"
            print("Setting:", setting.Name, string.format("0x%x", address), AutoTracker:ReadU16(address, 0), tfstring)
        end
    end
    return true
end

function updateEnableItemToggle()
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        InvalidateReadCaches()
        local address = 0x8071c1a
        local setting = Tracker:FindObjectForCode("EnableItemToggle")

        if AutoTracker:ReadU16(address, 0) == 0xe00c then
            setting.Active = true
        else
            setting.Active = false
        end

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            local tfstring = Tracker:ProviderCountForCode("EnableItemToggle") > 0 and "true" or "false"
            print("Setting:", setting.Name, string.format("0x%x", address), AutoTracker:ReadU16(address, 0), tfstring)
        end
    end
    return true
end

function updateObtainUnknownItems()
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        InvalidateReadCaches()
        local address = 0x800bd7e
        local setting = Tracker:FindObjectForCode("ObtainUnknownItems")

        if AutoTracker:ReadU16(address, 0) == 0xf038 then
            setting.Active = true
        else
            setting.Active = false
        end

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            local tfstring = Tracker:ProviderCountForCode("ObtainUnknownItems") > 0 and "true" or "false"
            print("Setting:", setting.Name, string.format("0x%x", address), AutoTracker:ReadU16(address, 0), tfstring)
        end
    end
    return true
end

function updateRandomizeEnemies()
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        InvalidateReadCaches()
        local address = 0x82b21e4
        local setting = Tracker:FindObjectForCode("RandomizeEnemies")

        if AutoTracker:ReadU16(address, 0) == 0x002c and
           AutoTracker:ReadU16(address + 0x4, 0) == 0x0031 and
           AutoTracker:ReadU16(address + 0x8, 0) == 0x0030 and
           AutoTracker:ReadU16(address + 0xa, 0) == 0x0538 and
           AutoTracker:ReadU16(address + 0xe, 0) == 0x0027 and
           AutoTracker:ReadU16(address + 0x12, 0) == 0x002e and
           AutoTracker:ReadU16(address + 0x14, 0) == 0x054e and
           AutoTracker:ReadU16(address + 0x18, 0) == 0x002f and
           AutoTracker:ReadU16(address + 0x1c, 0) == 0x0032 and
           AutoTracker:ReadU16(address + 0x1e, 0) == 0x0033 and
           AutoTracker:ReadU16(address + 0x20, 0) == 0x0334 and
           AutoTracker:ReadU16(address + 0x22, 0) == 0x0436 and
           AutoTracker:ReadU16(address + 0x24, 0) == 0x0538 and
           AutoTracker:ReadU16(address + 0x28, 0) == 0x0068 and
           AutoTracker:ReadU16(address + 0x2a, 0) == 0x0169 and
           AutoTracker:ReadU16(address + 0x2c, 0) == 0x0246 and
           AutoTracker:ReadU16(address + 0x2e, 0) == 0x036b and
           AutoTracker:ReadU16(address + 0x30, 0) == 0x045b and
           AutoTracker:ReadU16(address + 0x32, 0) == 0x055c then
            setting.Active = false
        else
            setting.Active = true
        end

        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            local tfstring = Tracker:ProviderCountForCode("RandomizeEnemies") > 0 and "true" or "false"
            print("Setting:", setting.Name, string.format("0x%x", address), AutoTracker:ReadU16(address, 0), tfstring)
        end
    end
    return true
end

function updateItems(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        InvalidateReadCaches()
        local address = 0x300153c

        updateToggleItemFromByteAndFlag(segment, "long", address, 0x01)
        updateToggleItemFromByteAndFlag(segment, "ice", address, 0x02)
        updateToggleItemFromByteAndFlag(segment, "wave", address, 0x04)
        updateToggleItemFromByteAndFlag(segment, "plasma", address, 0x08)
        updateToggleItemFromByteAndFlag(segment, "charge", address, 0x10)
        updateToggleItemFromByteAndFlag(segment, "bomb", address, 0x80)

        updateToggleItemFromByteAndFlag(segment, "hijump", address + 0x2, 0x01)
        updateToggleItemFromByteAndFlag(segment, "speed", address + 0x2, 0x02)
        updateToggleItemFromByteAndFlag(segment, "space", address + 0x2, 0x04)
        updateToggleItemFromByteAndFlag(segment, "screw", address + 0x2, 0x08)
        updateToggleItemFromByteAndFlag(segment, "varia", address + 0x2, 0x10)
        updateToggleItemFromByteAndFlag(segment, "gravity", address + 0x2, 0x20)
        updateToggleItemFromByteAndFlag(segment, "morph", address + 0x2, 0x40)
        updateToggleItemFromByteAndFlag(segment, "grip", address + 0x2, 0x80)
    end
    return true
end

function updateAmmo(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        InvalidateReadCaches()
        local address = 0x3001530

        updateDifficulty()

        updateAmmoFrom2Bytes(segment, "etank", address)
        updateAmmoFrom2Bytes(segment, "missile", address + 0x2)
        updateAmmoFromByte(segment, "super", address + 0x4)
        updateAmmoFromByte(segment, "pb", address + 0x5)
    end
    return true
end

function updateBosses(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        InvalidateReadCaches()
        local address = 0x2037e00

        --updateToggleItemFromByteAndFlag(segment, "acidwormitem", address + 0x3, 0x10)
        updateToggleItemFromByteAndFlag(segment, "kraiditem", address + 0x3, 0x40)
        updateToggleItemFromByteAndFlag(segment, "ridleyitem", address + 0x4, 0x20)
        updateToggleItemFromByteAndFlag(segment, "motherbrainitem", address + 0x4, 0x80)
        updateToggleItemFromByteAndFlag(segment, "kraidpower", address + 0x5, 0x40)
        updateToggleItemFromByteAndFlag(segment, "charlieitem", address + 0x8, 0x08)
        --updateToggleItemFromByteAndFlag(segment, "mecharidleyitem", address + 0x9, 0x04)
    end
    return true
end

function updateAbilityLocations(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_ITEM_TRACKING then
        InvalidateReadCaches()
        local address = 0x2037e00

        updateSectionChestCountFromByteAndFlag(segment, "@Brinstar (0, 15)/Ability", address + 0xa, 0x08)
        updateSectionChestCountFromByteAndFlag(segment, "@Brinstar (6, 6)/Ability", address + 0x9, 0x80)
        updateSectionChestCountFromByteAndFlag(segment, "@Brinstar (14, 2)/Ability", address + 0x2, 0x08)
        updateSectionChestCountFromByteAndFlag(segment, "@Brinstar (14, 12)/Ability", address + 0x2, 0x10)
        updateSectionChestCountFromByteAndFlag(segment, "@Brinstar (24, 6)/Ability", address + 0xa, 0x04)

        updateSectionChestCountFromByteAndFlag(segment, "@Kraid (7, 14)/Ability", address + 0x2, 0x40)
        updateSectionChestCountFromByteAndFlag(segment, "@Kraid (8, 15)/Ability", address + 0xa, 0x10)

        updateSectionChestCountFromByteAndFlag(segment, "@Norfair (6, 7)/Ability", address + 0x2, 0x20)
        updateSectionChestCountFromByteAndFlag(segment, "@Norfair (10, 12)/Ability", address + 0xa, 0x02)
        updateSectionChestCountFromByteAndFlag(segment, "@Norfair (18, 3)/Ability", address + 0xa, 0x01)
        updateSectionChestCountFromByteAndFlag(segment, "@Norfair (19, 8)/Ability", address + 0x2, 0x04)

        updateSectionChestCountFromByteAndFlag(segment, "@Ridley (6, 7)/Ability", address + 0x2, 0x80)

        updateSectionChestCountFromByteAndFlag(segment, "@Crateria (14, 6)/Ability", address + 0x2, 0x01)
        updateSectionChestCountFromByteAndFlag(segment, "@Crateria (20, 5)/Ability", address + 0x3, 0x01)
    end
    return true
end

function updateBrinstar(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        InvalidateReadCaches()
        local sAddress = 0x2036c00
        local eAddress = 0x2036c4c

        --updateSectionChestCountFromValue(segment, "@Brinstar (0, 15)/Ability", sAddress, eAddress, {0x1b0a,0x1b0b,0x1b0c})
        updateSectionChestCountFromValue(segment, "@Brinstar (5, 14)/Tank", sAddress, eAddress, {0x070d})
        --updateSectionChestCountFromValue(segment, "@Brinstar (6, 6)/Ability", sAddress, eAddress, {0x0708})
        updateSectionChestCountFromValue(segment, "@Brinstar (7, 15)/Tank", sAddress, eAddress, {0x021c})
        updateSectionChestCountFromValue(segment, "@Brinstar (9, 11)/Tank", sAddress, eAddress, {0x1205})
        updateSectionChestCountFromValue(segment, "@Brinstar (9, 12)/Tank", sAddress, eAddress, {0x1905})
        updateSectionChestCountFromValue(segment, "@Brinstar (11, 3)/Tank", sAddress, eAddress, {0x0a04})
        updateSectionChestCountFromValue(segment, "@Brinstar (11, 12)/Tank", sAddress, eAddress, {0x0407})
        --updateSectionChestCountFromValue(segment, "@Brinstar (14, 2)/Ability", sAddress, eAddress, {0x0607,0x0608,0x0707,0x0708})
        --updateSectionChestCountFromValue(segment, "@Brinstar (14, 12)/Ability", sAddress, eAddress, {0x0713,0x0714,0x0813,0x0814,0x0913,0x0914})
        updateSectionChestCountFromValue(segment, "@Brinstar (16, 3)/Tank", sAddress, eAddress, {0x1012})
        updateSectionChestCountFromValue(segment, "@Brinstar (16, 12)/Tank", sAddress, eAddress, {0x0636})
        updateSectionChestCountFromValue(segment, "@Brinstar (17, 7)/Tank", sAddress, eAddress, {0x0604})
        updateSectionChestCountFromValue(segment, "@Brinstar (17, 10)/Tank", sAddress, eAddress, {0x170e})
        updateSectionChestCountFromValue(segment, "@Brinstar (22, 8)/Tank", sAddress, eAddress, {0x0a0b})
        updateSectionChestCountFromValue(segment, "@Brinstar (23, 4)/Tank", sAddress, eAddress, {0x0527})
        updateSectionChestCountFromValue(segment, "@Brinstar (23, 6)/Tank", sAddress, eAddress, {0x050b})
        --updateSectionChestCountFromValue(segment, "@Brinstar (24, 6)/Ability", sAddress, eAddress, {0x0616,0x0617,0x0716,0x0717})
        updateSectionChestCountFromValue(segment, "@Brinstar (24, 8)/Tank", sAddress, eAddress, {0x0627})
    end
    return true
end

function updateKraid(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        InvalidateReadCaches()
        local sAddress = 0x2036d00
        local eAddress = 0x2036d34

        updateSectionChestCountFromValue(segment, "@Kraid (3, 5)/Tank", sAddress, eAddress, {0x0a07})
        updateSectionChestCountFromValue(segment, "@Kraid (6, 6)/Tank", sAddress, eAddress, {0x0e26})
        updateSectionChestCountFromValue(segment, "@Kraid (7, 9)/Tank", sAddress, eAddress, {0x0909})
        updateSectionChestCountFromValue(segment, "@Kraid (7, 12)/Tank", sAddress, eAddress, {0x0314})
        --updateSectionChestCountFromValue(segment, "@Kraid (7, 14)/Ability", sAddress, eAddress, {0x060c,0x060d,0x070c,0x070d})
        updateSectionChestCountFromValue(segment, "@Kraid (8, 8)/Tank", sAddress, eAddress, {0x144a})
        --updateSectionChestCountFromValue(segment, "@Kraid (8, 15)/Ability", sAddress, eAddress, {0x0606,0x0607,0x0706,0x0707})
        updateSectionChestCountFromValue(segment, "@Kraid (11, 4)/Tank", sAddress, eAddress, {0x0405})
        updateSectionChestCountFromValue(segment, "@Kraid (11, 6)/Tank", sAddress, eAddress, {0x0418})
        updateSectionChestCountFromValue(segment, "@Kraid (12, 10)/Tank", sAddress, eAddress, {0x0402})
        updateSectionChestCountFromValue(segment, "@Kraid (13, 2)/Tank", sAddress, eAddress, {0x0616})
        updateSectionChestCountFromValue(segment, "@Kraid (13, 7)/Tank", sAddress, eAddress, {0x093c})
        updateSectionChestCountFromValue(segment, "@Kraid (15, 4)/Tank", sAddress, eAddress, {0x2109})
    end
    return true
end

function updateNorfair(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        InvalidateReadCaches()
        local sAddress = 0x2036e00
        local eAddress = 0x2036e50

        updateSectionChestCountFromValue(segment, "@Norfair (3, 11)/Tank", sAddress, eAddress, {0x0e08})
        updateSectionChestCountFromValue(segment, "@Norfair (4, 12)/Tank", sAddress, eAddress, {0x171e})
        --updateSectionChestCountFromValue(segment, "@Norfair (6, 7)/Ability", sAddress, eAddress, {0x0607,0x0608,0x0707,0x0708})
        updateSectionChestCountFromValue(segment, "@Norfair (8, 7)/Tank", sAddress, eAddress, {0x0411})
        updateSectionChestCountFromValue(segment, "@Norfair (10, 5)/Tank", sAddress, eAddress, {0x0441})
        updateSectionChestCountFromValue(segment, "@Norfair (10, 6)/Tank", sAddress, eAddress, {0x0448})
        --updateSectionChestCountFromValue(segment, "@Norfair (10, 12)/Ability", sAddress, eAddress, {0x0607,0x0608,0x0707,0x0708})
        updateSectionChestCountFromValue(segment, "@Norfair (11, 6)/Tank", sAddress, eAddress, {0x0605})
        updateSectionChestCountFromValue(segment, "@Norfair (11, 13)/Tank", sAddress, eAddress, {0x031c})
        updateSectionChestCountFromValue(segment, "@Norfair (13, 13)/Tank", sAddress, eAddress, {0x0436})
        updateSectionChestCountFromValue(segment, "@Norfair (14, 6)/Tank", sAddress, eAddress, {0x0315})
        updateSectionChestCountFromValue(segment, "@Norfair (15, 10)/Tank", sAddress, eAddress, {0x0504})
        updateSectionChestCountFromValue(segment, "@Norfair (17, 10)/Tank", sAddress, eAddress, {0x032d})
        --updateSectionChestCountFromValue(segment, "@Norfair (18, 3)/Ability", sAddress, eAddress, {0x0615,0x0616,0x0715,0x0716})
        updateSectionChestCountFromValue(segment, "@Norfair (19, 2)/Tank", sAddress, eAddress, {0x040b})
        --updateSectionChestCountFromValue(segment, "@Norfair (19, 8)/Ability", sAddress, eAddress, {0x0608,0x0609,0x0708,0x0709})
        updateSectionChestCountFromValue(segment, "@Norfair (20, 4)/Tank", sAddress, eAddress, {0x094a})
        updateSectionChestCountFromValue(segment, "@Norfair (21, 1)/Tank", sAddress, eAddress, {0x0318})
        updateSectionChestCountFromValue(segment, "@Norfair (21, 11)/Tank", sAddress, eAddress, {0x0521})
        updateSectionChestCountFromValue(segment, "@Norfair (22, 8)/Tank", sAddress, eAddress, {0x4f0e})
        updateSectionChestCountFromValue(segment, "@Norfair (22, 11)/Tank", sAddress, eAddress, {0x6f08})
    end
    return true
end

function updateRidley(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        InvalidateReadCaches()
        local sAddress = 0x2036f00
        local eAddress = 0x2036f4c

        updateSectionChestCountFromValue(segment, "@Ridley (3, 8)/Tank", sAddress, eAddress, {0x0318})
        updateSectionChestCountFromValue(segment, "@Ridley (3, 9)/Tank", sAddress, eAddress, {0x0f14})
        updateSectionChestCountFromValue(segment, "@Ridley (4, 6)/Tank", sAddress, eAddress, {0x2108})
        updateSectionChestCountFromValue(segment, "@Ridley (5, 7)/Tank", sAddress, eAddress, {0x0708})
        --updateSectionChestCountFromValue(segment, "@Ridley (6, 7)/Ability", sAddress, eAddress, {0x0815,0x0816,0x0915,0x0916})
        updateSectionChestCountFromValue(segment, "@Ridley (7, 3)/Tank", sAddress, eAddress, {0x0806})
        updateSectionChestCountFromValue(segment, "@Ridley (8, 4)/Tank", sAddress, eAddress, {0x0408})
        updateSectionChestCountFromValue(segment, "@Ridley (8, 5)/Tank", sAddress, eAddress, {0x0d0d})
        updateSectionChestCountFromValue(segment, "@Ridley (9, 1)/Tank", sAddress, eAddress, {0x1507})
        updateSectionChestCountFromValue(segment, "@Ridley (9, 4)/Tank", sAddress, eAddress, {0x060b})
        updateSectionChestCountFromValue(segment, "@Ridley (9, 5)/Tank", sAddress, eAddress, {0x1008})
        updateSectionChestCountFromValue(segment, "@Ridley (10, 8)/Tank", sAddress, eAddress, {0x0648})
        updateSectionChestCountFromValue(segment, "@Ridley (12, 5)/Tank", sAddress, eAddress, {0x0409})
        updateSectionChestCountFromValue(segment, "@Ridley (13, 5)/Tank", sAddress, eAddress, {0x0f0f})
        updateSectionChestCountFromValue(segment, "@Ridley (14, 4)/Tank", sAddress, eAddress, {0x061b})
        updateSectionChestCountFromValue(segment, "@Ridley (16, 6)/Tank", sAddress, eAddress, {0x141c})
        updateSectionChestCountFromValue(segment, "@Ridley (17, 7)/Tank", sAddress, eAddress, {0x091b})
        updateSectionChestCountFromValue(segment, "@Ridley (19, 2)/Tank", sAddress, eAddress, {0x0636})
        updateSectionChestCountFromValue(segment, "@Ridley (22, 7)/Tank", sAddress, eAddress, {0x0d04})
        updateSectionChestCountFromValue(segment, "@Ridley (24, 5)/Tank", sAddress, eAddress, {0x072a})
    end
    return true
end

function updateTourian(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        InvalidateReadCaches()
        local sAddress = 0x2037000
        local eAddress = 0x2037008

        updateSectionChestCountFromValue(segment, "@Tourian (17, 11)/Tank", sAddress, eAddress, {0x6d0b})
        updateSectionChestCountFromValue(segment, "@Tourian (19, 12)/Tank", sAddress, eAddress, {0x080e})
    end
    return true
end

function updateCrateria(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        InvalidateReadCaches()
        local sAddress = 0x2037100
        local eAddress = 0x203711c

        updateSectionChestCountFromValue(segment, "@Crateria (9, 4)/Tank", sAddress, eAddress, {0x2514})
        --updateSectionChestCountFromValue(segment, "@Crateria (14, 6)/Ability", sAddress, eAddress, {0x0706,0x0707,0x0708,0x0806,0x0807,0x0808,0x0906,0x0907,0x0908,0x0a06,0x0a07,0x0a08})
        updateSectionChestCountFromValue(segment, "@Crateria (17, 8)/Tank", sAddress, eAddress, {0x1b03})
        updateSectionChestCountFromValue(segment, "@Crateria (19, 5)/Tank", sAddress, eAddress, {0x0a08})
        --updateSectionChestCountFromValue(segment, "@Crateria (20, 5)/Ability", sAddress, eAddress, {0x081a,0x081b,0x091a,0x091b})
        updateSectionChestCountFromValue(segment, "@Crateria (21, 5)/Tank", sAddress, eAddress, {0x2240})
        updateSectionChestCountFromValue(segment, "@Crateria (22, 2)/Tank", sAddress, eAddress, {0x095a})
    end
    return true
end

function updateChozodia(segment)
    if not isInGame() then
        return false
    end
    if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        InvalidateReadCaches()
        local sAddress = 0x2037200
        local eAddress = 0x2037244

        updateSectionChestCountFromValue(segment, "@Chozodia (4, 18)/Tank", sAddress, eAddress, {0x0e22})
        updateSectionChestCountFromValue(segment, "@Chozodia (4, 21)/Tank", sAddress, eAddress, {0x0d10})
        updateSectionChestCountFromValue(segment, "@Chozodia (6, 21)/Tank", sAddress, eAddress, {0x0309})
        updateSectionChestCountFromValue(segment, "@Chozodia (7, 19)/Tank", sAddress, eAddress, {0x1b06})
        updateSectionChestCountFromValue(segment, "@Chozodia (10, 7)/Tank", sAddress, eAddress, {0x1838})
        updateSectionChestCountFromValue(segment, "@Chozodia (10, 8)/Tank", sAddress, eAddress, {0x2838})
        updateSectionChestCountFromValue(segment, "@Chozodia (10, 9)/Tank", sAddress, eAddress, {0x082c})
        updateSectionChestCountFromValue(segment, "@Chozodia (10, 18)/Tank", sAddress, eAddress, {0x0d0a})
        updateSectionChestCountFromValue(segment, "@Chozodia (11, 13)/Tank", sAddress, eAddress, {0x143b})
        updateSectionChestCountFromValue(segment, "@Chozodia (14, 5)/Tank", sAddress, eAddress, {0x1109})
        updateSectionChestCountFromValue(segment, "@Chozodia (15, 4)/Tank", sAddress, eAddress, {0x070a})
        updateSectionChestCountFromValue(segment, "@Chozodia (15, 13)/Tank", sAddress, eAddress, {0x0618})
        updateSectionChestCountFromValue(segment, "@Chozodia (17, 8)/Tank", sAddress, eAddress, {0x082c})
        updateSectionChestCountFromValue(segment, "@Chozodia (18, 7)/Tank", sAddress, eAddress, {0x0609})
        updateSectionChestCountFromValue(segment, "@Chozodia (20, 7)/Tank", sAddress, eAddress, {0x050d})
        updateSectionChestCountFromValue(segment, "@Chozodia (21, 15)/Tank", sAddress, eAddress, {0x0413})
        updateSectionChestCountFromValue(segment, "@Chozodia (22, 2)/Tank", sAddress, eAddress, {0x133b})
        updateSectionChestCountFromValue(segment, "@Chozodia (26, 14)/Tank", sAddress, eAddress, {0x1212})
    end
    return true
end

-- *************************** Setup memory watches

ScriptHost:AddMemoryWatch("MZM Setting Data", 0x300002c, 0x01, updateDifficulty)
ScriptHost:AddMemoryWatch("MZM Setting Data", 0x82b1474, 0x02, updateIBNR)
ScriptHost:AddMemoryWatch("MZM Setting Data", 0x802cc16, 0x02, updatePBNR)
ScriptHost:AddMemoryWatch("MZM Setting Data", 0x8071c1a, 0x02, updateEnableItemToggle)
ScriptHost:AddMemoryWatch("MZM Setting Data", 0x800bd7e, 0x02, updateObtainUnknownItems)
ScriptHost:AddMemoryWatch("MZM Setting Data", 0x82b21e4, 0x32, updateRandomizeEnemies)
ScriptHost:AddMemoryWatch("MZM Item Data", 0x300153c, 0x07, updateItems)
ScriptHost:AddMemoryWatch("MZM Ammo Data", 0x3001530, 0x07, updateAmmo)
ScriptHost:AddMemoryWatch("MZM Boss Data", 0x2037e00, 0x20, updateBosses)
ScriptHost:AddMemoryWatch("MZM Room Data", 0x2037e00, 0x20, updateAbilityLocations)
ScriptHost:AddMemoryWatch("MZM Room Data", 0x2036c02, 0x4e, updateBrinstar)
ScriptHost:AddMemoryWatch("MZM Room Data", 0x2036d02, 0x36, updateKraid)
ScriptHost:AddMemoryWatch("MZM Room Data", 0x2036e02, 0x52, updateNorfair)
ScriptHost:AddMemoryWatch("MZM Room Data", 0x2036f02, 0x4e, updateRidley)
ScriptHost:AddMemoryWatch("MZM Room Data", 0x2037002, 0x0a, updateTourian)
ScriptHost:AddMemoryWatch("MZM Room Data", 0x2037102, 0x1e, updateCrateria)
ScriptHost:AddMemoryWatch("MZM Room Data", 0x2037202, 0x46, updateChozodia)
