local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local ui = require('openmw.ui')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ambient = require('openmw.ambient')

-- Global variable to store banked experience for each skill
local experienceBank = {}

local skillList = {
    'block', 'armorer', 'mediumarmor', 'heavyarmor', 'bluntweapon',
    'longblade', 'axe', 'spear', 'athletics', 'enchant', 'destruction',
    'alteration', 'illusion', 'conjuration', 'mysticism', 'restoration',
    'alchemy', 'unarmored', 'security', 'sneak', 'acrobatics', 'lightarmor',
    'shortblade', 'marksman', 'mercantile', 'speechcraft', 'handtohand'
}

local function initializeExperienceBank()
    for _, skill in ipairs(skillList) do
        experienceBank[skill] = 0
    end
end

local function isShiftAltPressed()
    return input.isShiftPressed() and input.isAltPressed()
end

local lastShiftAltState = false

local function checkShiftAltState()
    local currentState = isShiftAltPressed()
    if currentState ~= lastShiftAltState then
        lastShiftAltState = currentState
        core.sendGlobalEvent('shiftAltStateChanged', {pressed = currentState})
    end
end

local function applyExperienceWithBanking(skill, experience)
    local currentBase = types.NPC.stats.skills[skill](self).base
    local currentProgress = types.NPC.stats.skills[skill](self).progress
    local totalExperience = currentProgress + experience + (experienceBank[skill] or 0)
    
    while totalExperience >= 1 do
        types.NPC.stats.skills[skill](self).base = currentBase + 1
        currentBase = currentBase + 1
        totalExperience = totalExperience - 1
        ui.showMessage(skill .. " increased to " .. currentBase)
    end
    
    -- Ensure the final progress is between 0 and 1
    local finalProgress = math.min(totalExperience, 0.99)
    
    types.NPC.stats.skills[skill](self).progress = finalProgress
    experienceBank[skill] = 0

    print(string.format("Debug: Skill %s - New Base: %d, New Progress: %.2f", skill, currentBase, finalProgress))
end

local function calculateExperience(enchantmentInfo, enchantSkill)
    print("Debug: Entering calculateExperience function")
    print("Debug: Enchantment Type: " .. tostring(enchantmentInfo.enchantmentType))
    print("Debug: Enchantment Charge: " .. tostring(enchantmentInfo.charge))
    print("Debug: Total Enchantment Cost: " .. tostring(enchantmentInfo.totalCost))
    print("Debug: Number of effects: " .. tostring(#enchantmentInfo.effects))

    local totalExperience = 0
    local isConstantEffect = enchantmentInfo.enchantmentType == core.magic.ENCHANTMENT_TYPE.ConstantEffect
    -- local itemEnchantValue = 0 
    local enchantmentCharge = enchantmentInfo.charge or 0
    local enchantmentCost = math.max(enchantmentInfo.totalCost or 1, 0.1)  -- Ensure minimum cost of 0.1
    local costToChargeRatio = math.max((enchantmentCost / math.min(enchantmentCharge, 0.1)), 1) -- Calculate ratio of cost to charge between 0.1 and 1.
    local invertedEffectiveCost = math.min(math.max(1 - (1.1 - enchantSkill / 100), 0.1), 1) -- We do this just to make number go up if good. No cheating by going past 100 enchanting.
    if isConstantEffect then
        -- For constant effects, calculate experience based on enchantment cost and skill
        totalExperience = enchantmentCost * 400 * invertedEffectiveCost
        -- Want to reward higher enchant level
        -- Want to reward more expensive casts
        -- Since there is no costToChargeRatio in constantEffect, I just used the weakest soul that allows the constant effect: 400.
    elseif enchantmentCharge > 0 then
        -- For non-constant effects with a charge, calculate base experience
        local baseExperience = enchantmentCost * invertedEffectiveCost

        totalExperience = baseExperience * costToChargeRatio  -- Adjust base experience with cost-to-charge ratio because we want to reward multiple casts.

        totalExperience = math.max(totalExperience, 1) -- Ensure a minimum of 1 XP
        -- Three major assumptions:
        -- Want to reward higher enchant level
        -- Want to reward more expensive casts
        -- Want to reward more casts per charge
        -- Particularly we need to think about 1/5 vs something like 100/500, we want to reward the 100 more right?
        -- So that's why the costToChargeRatio is calculated after.
    else
        -- This should never happen, but just in case
        totalExperience = enchantmentCost * invertedEffectiveCost
        -- Ensure a minimum of 1 XP
        totalExperience = math.max(totalExperience, 1)
    end

    -- -- Cap the total experience to a reasonable maximum, e.g., 10000 (10 levels)
    totalExperience = math.min(totalExperience, 10000)

    print(string.format("Debug: Effective Cost: %.2f", enchantmentCost))
    print(string.format("Debug: Total Experience: %.2f", totalExperience))

    -- Distribute experience among effects based on their individual costs
    for i, effect in ipairs(enchantmentInfo.effects) do
        local effectCost = math.max(effect.calculatedCost, 0.1)  -- Technically the game maintains a minimum cost of 1 for all spells.
        
        local effectExperience = (effectCost / enchantmentCost) * totalExperience
        print(string.format("Debug: Effect %d - ID: %s, School: %s, Cost: %.2f, Experience: %.2f", 
                            i, tostring(effect.id), tostring(effect.school), effectCost, effectExperience))
    end

    return totalExperience, enchantmentInfo.effects
end

local function handleEnchantmentUsed(enchantmentInfo)
    print("Debug: Entering handleEnchantmentUsed function")
    print("Debug: Enchantment Type: " .. tostring(enchantmentInfo.enchantmentType))
    print("Debug: Item Charge: " .. tostring(enchantmentInfo.charge))
    print("Debug: Enchantment Cost: " .. tostring(enchantmentInfo.cost))
    print("Debug: Number of effects: " .. tostring(#enchantmentInfo.effects))

    local enchantSkill = types.NPC.stats.skills.enchant(self).base
    print("Debug: Enchant Skill: " .. tostring(enchantSkill))

    local totalExperience, effects = calculateExperience(enchantmentInfo, enchantSkill)

    print(string.format("Debug: Total Experience calculated: %.2f", totalExperience))

    if totalExperience > 0 and totalExperience < math.huge and not (totalExperience ~= totalExperience) then
        ambient.playSound("swallow")
        ui.showMessage('You destroyed your item and absorbed its power!')        

        local totalCost = math.max(enchantmentInfo.totalCost, 0.1) -- Just in case to prevent a nuke.
        for _, effect in ipairs(effects) do
            local effectCost = math.max(effect.calculatedCost, 0.1) 
            local effectExperience = (effectCost / totalCost) * totalExperience
            print(string.format("Debug: Applying experience for %s: %.2f", effect.school, effectExperience))
            applyExperienceWithBanking(effect.school, effectExperience / 100)  -- Convert to 0-1 range
        end
        -- Apply experience to enchant skill similar to effects
        local enchantExperience = math.max(totalExperience / #effects, 0.1) -- Divide total experience based on number of effects.
        applyExperienceWithBanking('enchant', enchantExperience / 100)  -- Convert to 0-1 range
        print(string.format("Debug: Applying experience for enchant: %.2f", enchantExperience))

        -- applyExperienceWithBanking('enchant', 0.01)  -- 1% progress for enchant skill
    else
        print("Debug: Enchantment does not grant valid experience.")
    end
end

-- Initialize the experience bank when the script loads
initializeExperienceBank()

return {
    eventHandlers = {
        enchantmentUsed = handleEnchantmentUsed
    },
    engineHandlers = {
        onUpdate = checkShiftAltState
    }
}