// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-createguid-function
// Scope: in-scope
// Fixtures used: shared Assert (60021); shared table 50000 "ALT Shape 00", codeunit 68871
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the form of the Guids the platform makes, over 50 values each (Format(G) is "{" + 8 hex + "-" + 4 + "-" + 4 + "-" + 4 + "-"
// + 12 + "}", so the version digit is character 16 and the variant digit character 21):
//  - CreateGuid is an RFC 4122 version 4 Guid: character 16 is always 4, character 21 one of 8, 9, A, B,
//    and the 50 values have 50 different first 20 characters;
//  - the SystemId the platform gives a new row is NOT version 4: over 50 rows the version position takes more
//    than one value (and the variant position more than the four 8, 9, A, B), and the first 20 characters of all 50 differ.
// There is no CreateSequentialGuid in AL (AL0118).
// BC versions: 27.5

codeunit 68871 "Probe Guid Form"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Describe(Guids: List of [Guid]; var VersionDigits: Text; var VariantDigits: Text; var DistinctPrefixes: Integer)
    var
        Value: Guid;
        Text: Text;
        Prefixes: Dictionary of [Text, Boolean];
    begin
        foreach Value in Guids do begin
            Text := Format(Value);
            if StrPos(VersionDigits, Text.Substring(16, 1)) = 0 then
                VersionDigits += Text.Substring(16, 1);
            if StrPos(VariantDigits, Text.Substring(21, 1)) = 0 then
                VariantDigits += Text.Substring(21, 1);
            if not Prefixes.ContainsKey(CopyStr(Text, 1, 20)) then
                Prefixes.Add(CopyStr(Text, 1, 20), true);
        end;
        DistinctPrefixes := Prefixes.Count();
    end;

    [Test]
    procedure CreateGuid_IsVersion4()
    var
        Guids: List of [Guid];
        Index: Integer;
        VersionDigits: Text;
        VariantDigits: Text;
        DistinctPrefixes: Integer;
    begin
        for Index := 1 to 50 do
            Guids.Add(CreateGuid());

        Describe(Guids, VersionDigits, VariantDigits, DistinctPrefixes);

        Assert.AreEqual('4', VersionDigits, 'version digit');
        Assert.AreEqual(50, DistinctPrefixes, 'distinct first 20 characters');
        Assert.IsTrue(StrLen(DelChr(VariantDigits, '=', '89AB')) = 0, 'variant digit in 8, 9, A, B');
    end;

    [Test]
    procedure SystemId_OfNewRows_IsNotVersion4()
    var
        GuidRec: Record "ALT Shape 00";
        Guids: List of [Guid];
        Index: Integer;
        VersionDigits: Text;
        VariantDigits: Text;
        DistinctPrefixes: Integer;
    begin
        GuidRec.DeleteAll();
        for Index := 1 to 50 do begin
            GuidRec.Id := Index;
            GuidRec.Insert();
        end;
        GuidRec.FindSet();
        repeat
            Guids.Add(GuidRec.SystemId);
        until GuidRec.Next() = 0;

        Describe(Guids, VersionDigits, VariantDigits, DistinctPrefixes);

        Assert.AreEqual(50, DistinctPrefixes, 'distinct first 20 characters');
        Assert.IsTrue(StrLen(VersionDigits) > 1, 'the version position takes several values');
        Assert.IsTrue(StrLen(DelChr(VariantDigits, '=', '89AB')) > 0, 'the variant position is not limited to 8, 9, A, B');
    end;
}
