local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')

local shiftAltPressed = false

local function getEnchantment(item)
    local record = item.type.record(item)
    if record and record.enchant then
        return core.magic.enchantments.records[record.enchant]
    end
    return nil
end

local function calculateSpellCost(effect, magicEffect)
    local magnitudeCost = (effect.magnitudeMin + effect.magnitudeMax) / 2
    local durationAreaCost = effect.duration + effect.area + 1
    local baseCost = magicEffect.baseCost or 0
    local spellCost = magnitudeCost * durationAreaCost * (baseCost / 40)
    
    return math.floor(spellCost)
end

local function handleItemUsage(item, actor)
    if not shiftAltPressed then
        return
    end

    local itemType = item.type
    local itemRecord = itemType.record(item)
    local itemName = itemRecord.name

    local enchantment = getEnchantment(item)
    if enchantment then
        if (enchantment.type == 4) then
            print('Scroll or similar item, skipping')
            return
        end

        local enchantmentInfo = {
            itemName = itemName,
            enchantmentId = enchantment.id,
            enchantmentType = enchantment.type,
            charge = enchantment.charge,
            cost = enchantment.cost,
            autocalcFlag = enchantment.autocalcFlag,
            effects = {}
        }

        local totalCost = 0
        for i, effect in ipairs(enchantment.effects) do
            local magicEffect = core.magic.effects.records[effect.id]
            local calculatedCost = calculateSpellCost(effect, magicEffect)
            totalCost = totalCost + calculatedCost
            table.insert(enchantmentInfo.effects, {
                id = effect.id,
                school = magicEffect.school,
                magnitudeMin = effect.magnitudeMin,
                magnitudeMax = effect.magnitudeMax,
                duration = effect.duration,
                area = effect.area,
                affectedAttribute = effect.affectedAttribute,
                affectedSkill = effect.affectedSkill,
                calculatedCost = calculatedCost
            })
        end
        enchantmentInfo.totalCost = totalCost

        actor:sendEvent('enchantmentUsed', enchantmentInfo)
        item:remove()
        return false
    end
end

I.ItemUsage.addHandlerForType(types.Weapon, handleItemUsage)
I.ItemUsage.addHandlerForType(types.Armor, handleItemUsage)
I.ItemUsage.addHandlerForType(types.Clothing, handleItemUsage)

local function onShiftAltStateChanged(data)
    shiftAltPressed = data.pressed
    print("Shift+Alt state changed: " .. tostring(shiftAltPressed))
end

return {
    eventHandlers = {
        shiftAltStateChanged = onShiftAltStateChanged
    }
}