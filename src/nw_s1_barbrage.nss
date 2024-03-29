//::///////////////////////////////////////////////
//:: Barbarian Rage
//:: NW_S1_BarbRage
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    The Str and Con of the Barbarian increases,
    Will Save are +2, AC -2.
    Greater Rage starts at level 15.
*/
//:://////////////////////////////////////////////
//:: Created By: Preston Watamaniuk
//:: Created On: Aug 13, 2001
//:://////////////////////////////////////////////

#include "x2_i0_spells"

const string IMM_TAG = "BarbarianImmunity";

void ApplyDamageImmunity(int nDamageType, int nImmunity, object oPC)
{
    effect e = SupernaturalEffect(EffectDamageImmunityIncrease(nDamageType, nImmunity));
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, TagEffect(e, IMM_TAG), oPC);
}

void RemoveEffectsByTag(object oCreature, string sTag)
{
    effect e = GetFirstEffect(oCreature);
    while (GetIsEffectValid(e))
    {
        if (GetEffectTag(e) == sTag)
            RemoveEffect(oCreature, e);
        e = GetNextEffect(oCreature);
    }
}

void ApplyBarbarianImmunity(object oPC=OBJECT_SELF)
{
    int nCon = GetAbilityScore(oPC, ABILITY_CONSTITUTION);
    int nLvl = GetLevelByClass(CLASS_TYPE_BARBARIAN, oPC);
    int nImmunity = nCon > nLvl ? 2 * nLvl : nCon + nLvl;
    RemoveEffectsByTag(oPC, IMM_TAG);
    ApplyDamageImmunity(DAMAGE_TYPE_PIERCING, nImmunity, oPC);
    ApplyDamageImmunity(DAMAGE_TYPE_BLUDGEONING, nImmunity, oPC);
    ApplyDamageImmunity(DAMAGE_TYPE_SLASHING, nImmunity, oPC);
    string msg = "Class/Con bonus: " + IntToString(nImmunity) + "% P/B/S immunity";
    SendMessageToPC(oPC, msg);
}

void main()
{
    if(!GetHasEffect(EFFECT_TYPE_AC_DECREASE))
    {
        //Declare major variables
        int nLevel = GetLevelByClass(CLASS_TYPE_BARBARIAN);
        int nIncrease;
        int nSave;
        if (nLevel < 15)
        {
            nIncrease = 4;
            nSave = 2;
        }
        else
        {
            nIncrease = 6;
            nSave = 3;
        }
        if (GetHasFeat(FEAT_MIGHTY_RAGE))
        {
            nIncrease += 2;
            nSave += 1;
        }
        PlayVoiceChat(VOICE_CHAT_BATTLECRY1);
        //Determine the duration by getting the con modifier after being modified
        int nCon = 3 + GetAbilityModifier(ABILITY_CONSTITUTION) + nIncrease + nLevel;
        effect eStr = EffectAbilityIncrease(ABILITY_CONSTITUTION, nIncrease);
        effect eCon = EffectAbilityIncrease(ABILITY_STRENGTH, nIncrease);
        effect eSave = EffectSavingThrowIncrease(SAVING_THROW_WILL, nSave);
        effect eAC = EffectACDecrease(2, AC_DODGE_BONUS);
        effect eHeal = EffectRegenerate(nLevel >= 40 ? nLevel / 2 : 1 + nLevel / 3, 6.0);
        effect eDur = EffectVisualEffect(VFX_DUR_CESSATE_POSITIVE);

        effect eLink = EffectLinkEffects(eCon, eStr);
        eLink = EffectLinkEffects(eLink, eSave);
        eLink = EffectLinkEffects(eLink, eAC);
        eLink = EffectLinkEffects(eLink, eHeal);
        eLink = EffectLinkEffects(eLink, eDur);
        SignalEvent(OBJECT_SELF, EventSpellCastAt(OBJECT_SELF, SPELLABILITY_BARBARIAN_RAGE, FALSE));
        //Make effect extraordinary
        eLink = ExtraordinaryEffect(eLink);
        effect eVis = EffectVisualEffect(VFX_IMP_IMPROVE_ABILITY_SCORE); //Change to the Rage VFX

        if (nCon > 0)
        {
            //Apply the VFX impact and effects
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, OBJECT_SELF, RoundsToSeconds(nCon));
            ApplyEffectToObject(DURATION_TYPE_INSTANT, eVis, OBJECT_SELF) ;

        // 2003-07-08, Georg: Rage Epic Feat Handling
        CheckAndApplyEpicRageFeats(nCon);
        }
    }
    ApplyBarbarianImmunity();
}
