--For use within logic.lua only. Will not work for access_rules in .json files
function has(item, amount)
  local count = Tracker:ProviderCountForCode(item)
  amount = tonumber(amount)
  if not amount then
    return count > 0
  else
    return count == amount
  end
end


--For use within access_rules in .json files. Acts as a logical operator "not"
function notItem(item)
  local count = Tracker:ProviderCountForCode(item)
  if count == 0 then
    return 1
  end
  return 0
end


--Count Functions

function EnergyCount(amount)
  local count = Tracker:ProviderCountForCode("etank")
  local energy = has("Normal") and count*100+100 or count*50+100
  amount = tonumber(amount)
  if energy >= amount then
    return 1
  end
  return 0
end

function AnyMissileCount(amount)
  local missileCount = Tracker:ProviderCountForCode("missile")
  local superCount = Tracker:ProviderCountForCode("super")
  amount = tonumber(amount)
  if missileCount + superCount >= amount then
    return 1
  end
  return 0
end


--"Can Do" Functions

function CanOpenRedDoors()
  if has("missile") or has("super") then
    return 1
  end
  return 0
end

function CanPowerBomb()
  if has("morph") and has("powerbomb") then
    return 1
  end
  return 0
end


--Functions mostly taken verbatim from Conditions.cs of the randomizer

function CanIBJ()
  if (~has("DisableIBJ")) and has("IBJ") and has("morph") and has("bomb") then
    return 1, AccessibilityLevel.SequenceBreak
  end
  return 0
end

function CanIWJ()
  if (~has("DisableIWJ")) and has("IWJ") then
    return 1
  end
  return 0
end

function CanHellRun()
  if has("HellRun") then
    return 1, AccessibilityLevel.SequenceBreak
  end
  return 0
end

function CanLavaDive()
  if has("LavaDive") then
    return 1, AccessibilityLevel.SequenceBreak
  end
  return 0
end

function BombChain()
  if has("morph") and (has("bomb") or has("powerbomb")) then
    return 1
  end
  return 0
end

function BombBlock()
  if BombChain() == 1 or has("screw") then
    return 1
  end
  return 0
end

function Launcher()
  if has("morph") and has("bomb") then
    return 1
  end
  return 0
end

function BallSpark()
  if has("morph") and has("speed") and has("hijump") then
    return 1
  end
  return 0
end

function HeatImmune()
  if has("varia") or ActiveGravity() == 1 then
    return 1
  end
  return 0
end

function CanFreeze()
  if (not has("RandEnemies")) and has("ItemToggle") and has("ice") then
    return 1
  end
  return 0
end

function AccessNorfair()
  if BombChain() == 1 then
    if (has("screw") and (CanIWJ() == 1 or ActiveSpace() == 1)) or (CanPowerBomb() == 1 and ActiveGravity() == 1 and has("speed")) then
      return 1
    elseif CeilingTunnel_5() == 1 then
      return CeilingTunnel_5()
    elseif has("AllowSoftLocks") then
      return 1, AccessibilityLevel.Inspect
    end
  end
  return 0
end

function AccessCrateria()
  if AccessNorfair() == 1 then
    return AccessNorfair()
  --elseif has("AllowSoftLocks") and Launcher() == 1 and CanPowerBomb() == 1 and ActiveSpace() == 1 and has("grip") then
  --  return 1
  end
  return 0
end

--Must be accompanied by AccessCrateria in the .json
function AccessChozodiaTopEntrance()
  if CeilingTunnel_1_2() == 1 and CanPowerBomb() == 1 and CanOpenRedDoors() == 1 then
    if has("speed") then
      return 1
    elseif LedgeNW_8p() == 1 then
      return LedgeNW_8p()
    end
  elseif has("screw") and CanPowerBomb() == 1 and CanOpenRedDoors() == 1 then
    return LedgeNW_8p()
  end
  return 0
end

function LeaveChozodiaTemple()
  if has("charlieitem") then
    if CanPowerBomb() == 1 and has("screw") and ((CanIWJ() == 1 and has("hijump")) or has("space")) then
      return 1
    elseif ((CanIWJ() == 1 and has("hijump")) or (has("space") and (has("gravity") or CanIWJ() == 1))) and (has("screw") or BombChain() == 1) then
      return ChoLavaRun()
    end
  elseif LedgeNW_8p() == 1 and CanPowerBomb() == 1 then
    if has("screw") then
      return LedgeNW_8p()
    else
      return ChoLavaRun()
    end
  end
  return 0
end

function NorShaft()
  if BombChain() == 1 and has("speed") then
    return 1
  elseif BombChain() == 1 then
    return LedgeNW_5()
  end
  return 0
end

function NorHeatRun()
  if HeatImmune() == 1 and has("speed") then
    return 1
  elseif HeatImmune() == 1 and LedgeNW_8p() == 1 then
    return LedgeNW_8p()
  elseif EnergyCount(200) == 1 and (has("speed") or LedgeNW_8p() == 1) then
    return CanHellRun()
  end
  return 0
end

function ChoLavaRun()
  if has("gravity") and Ledge_8p() == 1 then
    return Ledge_8p()
  elseif ((has("varia") and EnergyCount(200) == 1) or EnergyCount(300) == 1) and Ledge_8p() == 1 then
    return CanLavaDive()
  end
  return 0
end

function Item25()
  if BombChain() == 1 and CeilingTunnel_3_4() == 1 and CanOpenRedDoors() == 1 then
    if ActiveGravity() == 1 and LedgeNW_8p() == 1 then
      return LedgeNW_8p()
    elseif Launcher() == 1 and CeilingTunnel_5() == 1 and (has("grip") or Ledge_8p() == 1) then
      return CeilingTunnel_5()
    end
  end
  return 0
end

--[[ function Item57()
  if NorShaft() == 1 and CeilingTunnel_8p() == 1 and
   (has("grip") or CanIWJ() == 1 or ActiveSpace() == 1 or CanIBJ() == 1) and
   (Launcher() == 1 or has("speed")) then
    return CeilingTunnel_8p()
  elseif NorHeatRun() == 1 and CeilingTunnel_3_4() == 1 and has("speed") and
   (has("bomb") or has("powerbomb") or ActivePlasma() == 1) then
    return CeilingTunnel_3_4()
  end
  return 0
end ]]

function FullyPowered()
--[[   if Item25() == 1 and Item57() == 1 and ChoLavaRun() == 1 and (has("ice") or has("IBNR")) then
    return ChoLavaRun()
  end ]]
  if has("charlieitem") or has("ObtainUnknownItems") then
    return 1
  end
  return 0
end

function ActiveSpace()
  if has("space") and (has("ObtainUnknownItems") or FullyPowered() == 1) then
    return 1
  end
  return 0
end

function ActiveGravity()
  if has("gravity") and (has("ObtainUnknownItems") or FullyPowered() == 1) then
    return 1
  end
  return 0
end

function ActivePlasma()
  if has("plasma") and (has("ObtainUnknownItems") or FullyPowered() == 1) then
    return 1
  end
  return 0
end


--Locations taken verbatim from Conditions.cs of the randomizer (NW = No Wall)

function Ledge_4_5()
  if has("hijump") or has("grip") or CanIWJ() == 1 or ActiveSpace() == 1 then
    return 1
  end
  return CanIBJ()
end

function LedgeNW_5()
  if has("hijump") or has("grip") or ActiveSpace() == 1 then
    return 1
  end
  return CanIBJ()
end

function Ledge_6_7()
  if (has("hijump") and has("grip")) or CanIWJ() == 1 or ActiveSpace() == 1 then
    return 1
  end
  return CanIBJ()
end

function LedgeNW_6_7()
  if (has("hijump") and has("grip")) or ActiveSpace() == 1 then
    return 1
  end
  return CanIBJ()
end

function Ledge_8p()
  if CanIWJ() == 1 or ActiveSpace() == 1 then
    return 1
  end
  return CanIBJ()
end

function LedgeNW_8p()
  if ActiveSpace() == 1 then
    return 1
  end
  return CanIBJ()
end

function CeilingTunnel_1_2()
  if has("morph") and (has("bomb") or has("hijump")) then
    return 1
  end
  return 0
end

function CeilingTunnel_3_4()
  if has("morph") and (has("grip") or has("hijump")) then
    return 1
  end
  return CanIBJ()
end

function CeilingTunnel_5()
  if has("morph") and has("grip") then
    return 1
  end
  return CanIBJ()
end

function CeilingTunnel_6_7()
  if has("morph") and has("grip") and (has("hijump") or ActiveSpace() == 1 or CanIWJ() == 1) then
    return 1
  end
  return CanIBJ()
end

function CeilingTunnelNW_6_7()
  if has("morph") and has("grip") and (has("hijump") or ActiveSpace() == 1) then
    return 1
  end
  return CanIBJ()
end

function CeilingTunnel_8p()
  if has("morph") and has("grip") and (ActiveSpace() == 1 or CanIWJ() == 1) then
    return 1
  end
  return CanIBJ()
end

function CeilingTunnelNW_8p()
  if has("morph") and has("grip") and ActiveSpace() == 1 then
    return 1
  end
  return CanIBJ()
end

function Tunnel_1_3()
  if has("morph") then
    return 1
  end
  return 0
end

function Tunnel_4_5()
  if has("morph") and (has("grip") or has("hijump") or ActiveSpace() == 1 or CanIWJ() == 1) then
    return 1
  end
  return CanIBJ()
end

function TunnelNW_4_5()
  if has("morph") and (has("grip") or has("hijump") or ActiveSpace() == 1) then
    return 1
  end
  return CanIBJ()
end

function Tunnel_6_7()
  if has("morph") and ((has("grip") and has("hijump")) or ActiveSpace() == 1 or CanIWJ() == 1) then
    return 1
  end
  return CanIBJ()
end

function TunnelNW_6_7()
  if has("morph") and ((has("grip") and has("hijump")) or ActiveSpace() == 1) then
    return 1
  end
  return CanIBJ()
end

function Tunnel_8p()
  if has("morph") and (ActiveSpace() == 1 or CanIWJ() == 1) then
    return 1
  end
  return CanIBJ()
end

function TunnelNW_8p()
  if has("morph") and ActiveSpace() == 1 then
    return 1
  end
  return CanIBJ()
end