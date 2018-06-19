/**
 * hk_inc_qcast.nss - script for quick-casting list of spells
 * by Henning Koehler
 *
 * (1) player records spells they want to quick-cast
 *     => stored in local variable
 * (2) player quick-casts recorded spells instantly
 *
 * Setup:
 * - Run qcMain on player chat
 * - Run qcSpellHook for each spell cast
 */

#include "x3_inc_string"

const string QC_SPELLS = "qcSpells";
const string QC_RECORD = "qcRecord";
const int QC_SPELL_SIZE = 3;    // 3 digits for spell id
const int QC_META_SIZE = 2;     // 2 digits for meta-magic
const int QC_DOMAIN_SIZE = 1;   // 1 digit for domain-spell level
const int QC_TOTAL_SIZE = 6;    // QC_SPELL_SIZE + QC_META_SIZE + QC_DOMAIN_SIZE

string GetSpellName(int nSpell)
{
    return Get2DAString("spells", "Label", nSpell);
}

int GetIsHostile(int nSpell)
{
    return StringToInt(Get2DAString("spells", "HostileSetting", nSpell));
}

string GetMetaName(int nMeta)
{
    switch (nMeta)
    {
        case METAMAGIC_EMPOWER:  return "Empowered";
        case METAMAGIC_EXTEND:   return "Extended";
        case METAMAGIC_MAXIMIZE: return "Maximized";
        case METAMAGIC_QUICKEN:  return "Quickened";
        case METAMAGIC_SILENT:   return "Silent";
        case METAMAGIC_STILL:    return "Still";
    }
    return "";
}

string GetSpellMetaName(int nSpell, int nMeta, int nDomain=0)
{
    return GetSpellName(nSpell)
        + (nMeta ? " (" + GetMetaName(nMeta) + ")" : "")
        + (nDomain ? " (Domain Level " + IntToString(nDomain) + ")" : "");
}

string IntToFixed(int n, int minSize)
{
    string s = IntToString(n);
    while (GetStringLength(s) < minSize)
        s = "0" + s;
    return s;
}

// returns level of last spell cast, or 0 for non-domain spells
// Note: oCaster should be OBJECT_SELF when called during spell execution,
// or GetLastSpellCaster() when called after spell execution
int GetDomainLevel(object oCaster)
{
    if (GetLastSpellCastClass() != CLASS_TYPE_CLERIC)
        return 0;

    int nFeat1, nFeat2, nFeat3 = 0; // feats increasing spell DC
    int nInnate = 0; // non-domain level of spell
    switch (GetSpellId())
    {
        case SPELL_MAGE_ARMOR:
            return 1;
        case SPELL_BARKSKIN:
        case SPELL_CATS_GRACE:
        case SPELL_INVISIBILITY:
            return 2;
        case SPELL_CLAIRAUDIENCE_AND_CLAIRVOYANCE:
        case SPELL_FREEDOM_OF_MOVEMENT:
        case SPELL_INVISIBILITY_SPHERE:
            return 3;
        case SPELL_MINOR_GLOBE_OF_INVULNERABILITY:
            return 4;
        case SPELL_ENERGY_BUFFER:
        case SPELL_IMPROVED_INVISIBILITY:
            return 5;
        case SPELL_LEGEND_LORE:
            return 6;
        case SPELL_AURA_OF_VITALITY:
            return 7;
        case SPELL_DIVINE_POWER:
            nFeat1 = FEAT_SPELL_FOCUS_EVOCATION;
            nFeat2 = FEAT_GREATER_SPELL_FOCUS_EVOCATION;
            nFeat3 = FEAT_EPIC_SPELL_FOCUS_EVOCATION;
            nInnate = 4;
            break;
        case SPELL_STONESKIN:
            nFeat1 = FEAT_SPELL_FOCUS_ABJURATION;
            nFeat2 = FEAT_GREATER_SPELL_FOCUS_ABJURATION;
            nFeat3 = FEAT_EPIC_SPELL_FOCUS_ABJURATION;
            break;
        case SPELL_TRUE_SEEING:
            nFeat1 = FEAT_SPELL_FOCUS_DIVINATION;
            nFeat2 = FEAT_GREATER_SPELL_FOCUS_DIVINATION;
            nFeat3 = FEAT_EPIC_SPELL_FOCUS_DIVINATION;
            nInnate = 5;
            break;
        default:
            return 0;
    }
    // Calculate spell/domain level via DC
    int nDC = GetSpellSaveDC();
    int nFeatDC = GetHasFeat(nFeat3, oCaster) ? 6 :
        GetHasFeat(nFeat2, oCaster) ? 4 :
        GetHasFeat(nFeat1, oCaster) ? 2 : 0;
    int nWis = GetAbilityModifier(ABILITY_WISDOM, oCaster);
    int nSpellLevel = nDC - 10 - nWis - nFeatDC;
    if ( nSpellLevel < 0 || nSpellLevel > 9 )
    {
        SendMessageToPC(oCaster, "BUG: Spell level = " + IntToString(nSpellLevel));
        return 0;
    }
    return (nSpellLevel == nInnate) ? 0 : nSpellLevel;
}

// append nSpell to spell list on oPC
void qcRecordSpell(object oPC, int nSpell, int nMeta, int nDomainLevel)
{
    string sSpell = IntToFixed(nSpell, QC_SPELL_SIZE);
    string sMeta = IntToFixed(nMeta, QC_META_SIZE);
    string sDomain = IntToString(nDomainLevel);
    string sSpellList = GetLocalString(oPC, QC_SPELLS) + sSpell + sMeta + sDomain;
    SetLocalString(oPC, QC_SPELLS, sSpellList);
}

// handles recording of last spell cast
void qcSpellHook()
{
    object oPC = OBJECT_SELF;
    if (GetIsPC(oPC) && GetLocalInt(oPC, QC_RECORD))
    {
        int nSpell = GetSpellId();
        if (GetIsHostile(nSpell)) // GetLastSpellHarmful does not seem to work
        {
            SendMessageToPC(oPC, GetSpellName(nSpell) + " is a hostile spell, not recorded.");
            return;
        }
        int nMeta = GetMetaMagicFeat();
        int nDomain = GetDomainLevel(oPC);
        qcRecordSpell(oPC, nSpell, nMeta, nDomain);
        SendMessageToPC(oPC, "Recorded spell " + GetSpellMetaName(nSpell, nMeta, nDomain) + ".");
    }
}

void qcShowSpells(object oPC)
{
    string sSpellList = GetLocalString(oPC, QC_SPELLS);
    int nSpellIndex;

    SendMessageToPC(oPC, "Recorded Spells:");
    for (nSpellIndex = 0; nSpellIndex < GetStringLength(sSpellList); nSpellIndex += QC_TOTAL_SIZE)
    {
        int nSpell = StringToInt(GetSubString(sSpellList, nSpellIndex, QC_SPELL_SIZE));
        int nMeta = StringToInt(GetSubString(sSpellList, nSpellIndex + QC_SPELL_SIZE, QC_META_SIZE));
        int nDomain = StringToInt(GetSubString(sSpellList, nSpellIndex + QC_SPELL_SIZE + QC_META_SIZE, QC_DOMAIN_SIZE));
        SendMessageToPC(oPC, IntToString(nSpellIndex/QC_TOTAL_SIZE) + ": " + GetSpellMetaName(nSpell, nMeta, nDomain));
    }
}

// cast all spells recorded
int qcCastAll(object oPC)
{
    string sSpellList = GetLocalString(oPC, QC_SPELLS);

    int nSpellIndex;
    for (nSpellIndex = 0; nSpellIndex < GetStringLength(sSpellList); nSpellIndex += QC_TOTAL_SIZE)
    {
        int nSpell = StringToInt(GetSubString(sSpellList, nSpellIndex, QC_SPELL_SIZE));
        int nMeta = StringToInt(GetSubString(sSpellList, nSpellIndex + QC_SPELL_SIZE, QC_META_SIZE));
        int nDomain = StringToInt(GetSubString(sSpellList, nSpellIndex + QC_SPELL_SIZE + QC_META_SIZE, QC_DOMAIN_SIZE));
        // add delay between spells to ensure spell parameters haven't been overwritten by the time spell scripts execute
        AssignCommand(oPC, DelayCommand(nSpellIndex * 0.01, ActionCastSpellAtObject(nSpell, oPC, nMeta, FALSE, nDomain, PROJECTILE_PATH_TYPE_DEFAULT, TRUE)));
    }
    return GetStringLength(sSpellList) / QC_TOTAL_SIZE;
}

void qcMain()
{
    object oPC = GetPCChatSpeaker();
    string sCommand = GetPCChatMessage();

    if (GetSubString(sCommand, 0, 3) != "!qc")
        return;

    if (sCommand == "!qc-record")
    {
        if (GetLocalInt(oPC, QC_RECORD))
            SendMessageToPC(oPC, "Already recording.");
        else
        {
            SetLocalInt(oPC, QC_RECORD, 1);
            SendMessageToPC(oPC, "Recording spells ...");
        }
    }
    else if (sCommand == "!qc-stop")
    {
        if (!GetLocalInt(oPC, QC_RECORD))
            SendMessageToPC(oPC, "No recording in progress.");

        DeleteLocalInt(oPC, QC_RECORD);
        SendMessageToPC(oPC, "Recording stopped.");
    }
    else if (sCommand == "!qc-clear")
    {
        DeleteLocalString(oPC, QC_SPELLS);
        SendMessageToPC(oPC, "Spell list cleared.");
    }
    else if (sCommand == "!qc-list")
    {
        qcShowSpells(oPC);
    }
    else if (sCommand == "!qc-debug")
    {
        SendMessageToPC(oPC, QC_SPELLS + "=" + GetLocalString(oPC, QC_SPELLS));
        SendMessageToPC(oPC, QC_RECORD + "=" + IntToString(GetLocalInt(oPC, QC_RECORD)));
    }
    else if (sCommand == "!qc-cast")
    {
        if (GetLocalInt(oPC, QC_RECORD))
            SendMessageToPC(oPC, "Cannot quick-cast while recording.");
        else if (GetIsInCombat(oPC))
            SendMessageToPC(oPC, "Cannot quick-cast during combat.");
        else
        {
            int nCast = qcCastAll(oPC);
            SendMessageToPC(oPC, "Quick-casting " + IntToString(nCast) + " spell" + (nCast == 1 ? "" : "s") + ".");
        }
    }
    else
    {
        SendMessageToPC(oPC, "Quick-cast commands:");
        SendMessageToPC(oPC, StringToRGBString("!qc-cast", STRING_COLOR_WHITE) + " - quick-cast recorded spells");
        SendMessageToPC(oPC, StringToRGBString("!qc-clear", STRING_COLOR_WHITE) + " - delete all recorded spells");
        SendMessageToPC(oPC, StringToRGBString("!qc-list", STRING_COLOR_WHITE) + " - show recorded spells");
        SendMessageToPC(oPC, StringToRGBString("!qc-record", STRING_COLOR_WHITE) + " - start recording spells");
        SendMessageToPC(oPC, StringToRGBString("!qc-stop", STRING_COLOR_WHITE) + " - stop recording spells");
    }
}

//void main() {}