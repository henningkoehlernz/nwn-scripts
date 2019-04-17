#include "x2_inc_itemprop"
#include "nwnx_item"
#include "nwnx_object"

// grants oPC physical damage immunity based on armor worn
void ApplyArmorImmunity(object oArmor, object oPC);
// grants oPC physical damage resistance based on shield worn
void ApplyShieldResistance(object oShield, object oPC);
// grants oPC with armor mastery damage reduction and stat boost based on armor worn
void ApplyArmorMastery(object oArmor, object oPC);
// removes from oPC all effects created by oItem
void StripItemEffects(object oItem, object oPC);

// removes all item properties granting damage reduction, resist P/B/S or immunity P/B/S
void StripPhysicalProtections(object oItem);

// applies effect to oPC as permanent supernatural effect
void ApplyPermanentEffect(effect eEffect, object oPC);
// scales damage immunity based on existing immunity before applying it to oPC; returns scaled amount
int ApplyScaledDamageImmunity(int nDamageType, int nImmunity, object oPC);
// returns maximal AC bonus from item properties
int GetArmorEnhancementBonus(object oItem);
// returns total damage reduction granted by feats
int GetDamageReductionFromFeats(object oPC);

//--------------------------- Implementation ----------------------------------

void ApplyArmorImmunity(object oArmor, object oPC)
{
    int nBaseAC = NWNX_Item_GetBaseArmorClass(oArmor);
    if ( nBaseAC > 0 )
    {
        int nCon = GetAbilityScore(oPC, ABILITY_CONSTITUTION);
        int nArmorCap = 10 + 5 * nBaseAC; // 50% max
        int nImmunity = nCon < nArmorCap ? nCon : nArmorCap;
        int nPImm = ApplyScaledDamageImmunity(DAMAGE_TYPE_PIERCING, nImmunity, oPC);
        int nBImm = ApplyScaledDamageImmunity(DAMAGE_TYPE_BLUDGEONING, nImmunity, oPC);
        int nSImm = ApplyScaledDamageImmunity(DAMAGE_TYPE_SLASHING, nImmunity, oPC);
        string msg = "Armor: " + IntToString(nImmunity) + "% P/B/S immunity";
        if ( nPImm != nBImm || nPImm != nSImm )
            msg += ", scaled to " + IntToString(nPImm) + "/" + IntToString(nBImm) + "/" + IntToString(nSImm);
        SendMessageToPC(oPC, msg);
    }
}

void ApplyShieldResistance(object oShield, object oPC)
{
    int nResist = 0;
    switch ( GetBaseItemType(oShield) )
    {
        case BASE_ITEM_TOWERSHIELD: nResist = GetAbilityModifier(ABILITY_CONSTITUTION, oPC) / 2; break;
        case BASE_ITEM_LARGESHIELD: nResist = GetAbilityModifier(ABILITY_STRENGTH,     oPC) / 2; break;
        case BASE_ITEM_SMALLSHIELD: nResist = GetAbilityModifier(ABILITY_DEXTERITY,    oPC) / 2; break;
    }
    if ( nResist > 0 )
    {
        ApplyPermanentEffect(EffectDamageResistance(DAMAGE_TYPE_PIERCING, nResist), oPC);
        ApplyPermanentEffect(EffectDamageResistance(DAMAGE_TYPE_BLUDGEONING, nResist), oPC);
        ApplyPermanentEffect(EffectDamageResistance(DAMAGE_TYPE_SLASHING, nResist), oPC);
        SendMessageToPC(oPC, "Shield: resist " + IntToString(nResist) + " P/B/S");
    }
}

void ApplyArmorMastery(object oArmor, object oPC)
{
    if ( GetLevelByClass(CLASS_TYPE_FIGHTER, oPC) >= 20 )
    {
        int nBaseAC = NWNX_Item_GetBaseArmorClass(oArmor);
        if ( nBaseAC > 0 )
        {
            int nPower = 1 + GetArmorEnhancementBonus(oArmor);
            int nBonus = 5 + GetDamageReductionFromFeats(oPC);
            ApplyPermanentEffect(EffectDamageReduction(nBonus, IPGetDamagePowerConstantFromNumber(nPower)), oPC);
            SendMessageToPC(oPC, "Armor Mastery: DR " + IntToString(nBonus) + "/+" + IntToString(nPower));
            int nAbility = nBaseAC > 5 ? ABILITY_CONSTITUTION : nBaseAC > 3 ? ABILITY_STRENGTH : ABILITY_DEXTERITY;
            ApplyPermanentEffect(EffectAbilityIncrease(nAbility, 2), oPC);
        }
    }
}

void StripItemEffects(object oItem, object oPC)
{
    effect e = GetFirstEffect(oPC);
    while ( GetIsEffectValid(e) )
    {
        if ( GetEffectCreator(e) == oItem )
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

void StripPhysicalProtections(object oItem)
{
    itemproperty ip = GetFirstItemProperty(oItem);
    while ( GetIsItemPropertyValid(ip) )
    {
        if ( GetItemPropertyDurationType(ip) == DURATION_TYPE_PERMANENT )
        {
            switch ( GetItemPropertyType(ip) )
            {
                case ITEM_PROPERTY_DAMAGE_REDUCTION:
                    RemoveItemProperty(oItem, ip);
                    break;
                case ITEM_PROPERTY_DAMAGE_RESISTANCE:
                case ITEM_PROPERTY_IMMUNITY_DAMAGE_TYPE:
                    switch ( GetItemPropertySubType(ip) )
                    {
                        case IP_CONST_DAMAGETYPE_PIERCING:
                        case IP_CONST_DAMAGETYPE_BLUDGEONING:
                        case IP_CONST_DAMAGETYPE_SLASHING:
                            RemoveItemProperty(oItem, ip);
                    }
            }
        }
        ip = GetNextItemProperty(oItem);
    }
}

void ApplyPermanentEffect(effect eEffect, object oPC)
{
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, SupernaturalEffect(eEffect), oPC);
}

int ApplyScaledDamageImmunity(int nDamageType, int nImmunity, object oPC)
{
    int nCurrentImmunity = NWNX_Object_GetDamageImmunity(oPC, nDamageType);
    int nScaledImmunity = nImmunity * (100 - nCurrentImmunity) / 100;
    ApplyPermanentEffect(EffectDamageImmunityIncrease(nDamageType, nScaledImmunity), oPC);
    return nScaledImmunity;
}

int GetArmorEnhancementBonus(object oItem)
{
    int nMaxBonus = 0;
    itemproperty ip = GetFirstItemProperty(oItem);
    while ( GetIsItemPropertyValid(ip) )
    {
        if ( GetItemPropertyType(ip) == ITEM_PROPERTY_AC_BONUS )
        {
            int nBonus = GetItemPropertyCostTableValue(ip);
            if ( nBonus > nMaxBonus )
                nMaxBonus = nBonus;
        }
        ip = GetNextItemProperty(oItem);
   }
   return nMaxBonus;
}

int GetDamageReductionFromFeats(object oPC)
{
    int totalDR = 0;

    if ( GetHasFeat(FEAT_EPIC_DAMAGE_REDUCTION_9, oPC) )
        totalDR = 9;
    else if ( GetHasFeat(FEAT_EPIC_DAMAGE_REDUCTION_6, oPC) )
        totalDR = 6;
    else if ( GetHasFeat(FEAT_EPIC_DAMAGE_REDUCTION_3, oPC) )
        totalDR = 3;

    int nBarbLevel = GetLevelByClass(CLASS_TYPE_BARBARIAN, oPC);
    if ( nBarbLevel >= 11 )
        totalDR += (nBarbLevel - 8) / 3;

    int nDDLevel = GetLevelByClass(CLASS_TYPE_DWARVENDEFENDER, oPC);
    if ( nDDLevel >= 6 )
        totalDR += (nDDLevel - 2) / 4 * 3;

    return totalDR;
}
