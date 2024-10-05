# Absorb & Ascend
Destroy a magic item and absorb its power!

![An altmer enchanter destroys an enchanted sword and absorbs its power.](images/absorb.png "An altmer enchanter destroys an enchanted sword and absorbs its power.")

## Features

This mod enables you to "consume" a magic weapon, armor, or clothing item. You'll then gain experience based on the magic school(s) of the enchantment, plus a small experience gain for the enchant skill. The item is destroyed in the process.

Enchanted thrown weapons and ammo cannot be consumed this way.

_This mod requires OpenMW 0.49!_

## How to use

While in the inventory menu, hold Shift+Alt, then "equip" the magic item. The keys are configurable.

## Kart's fork of ChitinWarAxe's Absorb and Ascend using a custom formula.

This fork (Kart) is for a character that isn't allowed to use enchanted items so I made it more rewarding, basically. For a regular character I'd go with Chitins especially because you can customize it.

## Comparison

As opposed to ChitinWarAxe's use of "enchantment chance", this fork instead uses the
"effective cost"

Chitin:

`_Item charge/20 + Enchantment cost/2, multiplied with 1 + (((intelligence+enchant)/5 + luck/10)/100)_`

Kart:

`(1 - (1.1 - enchantSkill / 100)) bound between 0.1 and 1.0.`

## Notes on the math

Math:

- Features some max and min functions to prevent overflow.
- Inverted Effect Cost to reward players with higher enchant level.

`local costToChargeRatio = math.max((enchantmentCost / math.min(enchantmentCharge, 0.1)), 1)`

`local invertedEffectiveCost = math.min(math.max(1 - (1.1 - enchantSkill / 100), 0.1), 1)`


If constant effect:

`totalExperience = enchantmentCost * 400 * invertedEffectiveCost`

Non constant effect:

`local baseExperience = enchantmentCost * invertedEffectiveCost`

`totalExperience = baseExperience * costToChargeRatio`

Fallback:

`totalExperience = enchantmentCost * invertedEffectiveCost`


### Final calculation:

Each effect's experience is calculated relative to its cost compared to the total cost of the enchantment:

`local effectExperience = (effectCost / enchantmentCost) * totalExperience`

Then finally the enchant experience which is the total experience divided by the number of effects, with a minimum of 1 XP:

`local enchantExperience = math.max(totalExperience / #effects, 0.1)`


