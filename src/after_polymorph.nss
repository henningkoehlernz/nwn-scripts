// Run after polymorph events using
// NWNX_Events_SubscribeEvent("NWNX_ON_POLYMORPH_AFTER", "after_polymorph");
#include "nwnx_creature"
#include "nwnx_events"
#include "_util"

const int FEAT_POWERFUL_SHAPE = 1117;
const int FEAT_AGILE_SHAPE = 1118;
const int FEAT_STURDY_SHAPE = 1119;

// compute ability bonus for str/dex/con
int GetFormAbilityBonus(object oPC, int nAbility, int nFormScore, int nFormMax, int nFeat)
{
    if ( GetHasFeat(nFeat, oPC) )
    {
        if ( nFormScore )
        {
            // grant bonus equal to original ability modifier
            int nBaseModifier = NWNX_Creature_GetPrePolymorphAbilityScore(oPC, nAbility) / 2 - 5;
            return nBaseModifier;
        }
        else
        {
            // ensure minimum value equal to nFormMax + original ability modifier
            int nBaseScore = GetAbilityScore(oPC, nAbility, TRUE);
            int nBaseModifier = nBaseScore / 2 - 5;
            int nModifiedScore = nFormMax + nBaseModifier;
            if ( nModifiedScore > nBaseScore )
                return nModifiedScore - nBaseScore;
        }
    }
    else if ( !nFormScore )
    {
        // ensure minimum value of nFormMax for primary (scaling) score
        int nBaseScore = GetAbilityScore(oPC, nAbility, TRUE);
        if ( nBaseScore < nFormMax )
            return nFormMax - nBaseScore;
    }
    return 0;
}

// applies bonus, if any, and returns log message
string ApplyPolymorphBonus(object oPC, int nAbility, int nBonus, string sAbility)
{
    if ( nBonus )
    {
        NWNX_Creature_ModifyRawAbilityScore(oPC, nAbility, nBonus);
        return " +" + IntToString(nBonus) + " " + sAbility;
    }
    return "";
}

void main()
{
    object oPC = OBJECT_SELF;
    // get form stats
    int nPoly = StringToInt(NWNX_Events_GetEventData("POLYMORPH_TYPE"));
    int nFormStr = StringToInt(Get2DAString("polymorph", "STR", nPoly));
    int nFormDex = StringToInt(Get2DAString("polymorph", "DEX", nPoly));
    int nFormCon = StringToInt(Get2DAString("polymorph", "CON", nPoly));
    int nFormMax = max(nFormStr, max(nFormDex, nFormCon));
    // ensure variable (primary) stats get minimum value, and add feat bonuses
    int nBonusStr = GetFormAbilityBonus(oPC, ABILITY_STRENGTH, nFormStr, nFormMax, FEAT_POWERFUL_SHAPE);
    int nBonusDex = GetFormAbilityBonus(oPC, ABILITY_DEXTERITY, nFormDex, nFormMax, FEAT_AGILE_SHAPE);
    int nBonusCon = GetFormAbilityBonus(oPC, ABILITY_CONSTITUTION, nFormCon, nFormMax, FEAT_STURDY_SHAPE);
    // adjust Str/Dex/Con based on bonuses computed
    string msg = ApplyPolymorphBonus(oPC, ABILITY_STRENGTH, nBonusStr, "Str")
        + ApplyPolymorphBonus(oPC, ABILITY_DEXTERITY, nBonusDex, "Dex")
        + ApplyPolymorphBonus(oPC, ABILITY_CONSTITUTION, nBonusCon, "Con");
    if ( msg != "" )
        SendMessageToPC(oPC, "Polymorph Ability Adjustments:" + msg);
}
