// appends a sub-tag to a multi-tag string
string AddSubTag(string sTag, string sSubTag, string sSeparator = ":");
// extract sub-tag from a multi-tag string
string GetSubTag(string sTag, int nIndex, string sSeparator = ":");
// check if tag has given subtag at any position
int GetHasSubTag(string sTag, string sSubTag, string sSeparator = ":");
// returns true if oCreature has an effect with given sub-tag
int GetHasSubTagEffect(object oCreature, string sSubTag, int nIndex = -1, string sSeparator = ":");
// remove effects from oCreature if they have matching sub-tag
void RemoveEffectsBySubTag(object oCreature, string sSubTag, int nIndex = -1, string sSeparator = ":");

//--------------------------- Implementation ----------------------------------

string AddSubTag(string sTag, string sSubTag, string sSeparator = ":")
{
    return sTag + sSeparator + sSubTag;
}

string GetSubTag(string sTag, int nIndex, string sSeparator = ":")
{
    int nTagPos = 0;
    while ( nIndex > 0 )
    {
        int nSepPos = FindSubString(sTag, sSeparator, nTagPos);
        if ( nSepPos == -1 )
            return "";
        nTagPos = nSepPos + GetStringLength(sSeparator);
        nIndex -= 1;
    }
    int nSepPos = FindSubString(sTag, sSeparator, nTagPos);
    if ( nSepPos == -1 )
        nSepPos = GetStringLength(sTag);
    return GetSubString(sTag, nTagPos, nSepPos - nTagPos);
}

int GetHasSubTag(string sTag, string sSubTag, string sSeparator = ":")
{
    string sTagTerminated = sSeparator + sTag + sSeparator;
    string sSubTagTerminated = sSeparator + sSubTag + sSeparator;
    return FindSubString(sTagTerminated, sSubTagTerminated) != -1;
}

int GetHasSubTagEffect(object oCreature, string sSubTag, int nIndex = -1, string sSeparator = ":")
{
    effect e = GetFirstEffect(oCreature);
    while ( GetIsEffectValid(e) )
    {
        string sTag = GetEffectTag(e);
        if ( nIndex == -1 ? GetHasSubTag(sTag, sSubTag, sSeparator) : GetSubTag(sTag, nIndex, sSeparator) == sSubTag )
            return TRUE;
        e = GetNextEffect(oCreature);
    }
    return FALSE;
}

void RemoveEffectsBySubTag(object oCreature, string sSubTag, int nIndex = -1, string sSeparator = ":")
{
    effect e = GetFirstEffect(oCreature);
    while ( GetIsEffectValid(e) )
    {
        string sTag = GetEffectTag(e);
        if ( nIndex == -1 ? GetHasSubTag(sTag, sSubTag, sSeparator) : GetSubTag(sTag, nIndex, sSeparator) == sSubTag )
            RemoveEffect(oCreature, e);
        e = GetNextEffect(oCreature);
    }
}

