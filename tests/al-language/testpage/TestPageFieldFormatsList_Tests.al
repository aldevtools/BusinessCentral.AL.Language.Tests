// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: TPF Row (69932), TPF List (69935), TPF Enum (69932), Assert (60021)
// BC versions: 27.0+
//
// CLAIM UNDER TEST: a field of a list page reads the same text on a row as on a card (codeunit 69932),
// and on the list's draft line (the new row an editable list shows over an empty table) it reads
// the blank row's text: blank for a Date, Time, DateTime and Duration, but '0.00' for a Decimal,
// 'No' for a Boolean, the first caption for an Option or Enum, and the braced null Guid, which is
// not blank. Measured on a probe revision of this file on every cloud leg, 27.0 to 29.0.

codeunit 69935 "TPF List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Value_ListRow_EveryFieldType()
    var
        Row: Record "TPF Row";
        List: TestPage "TPF List";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 1234567;
        Row.Dec2 := 1234567.89;
        Row.Flag := true;
        Row.Opt := Row.Opt::Beta;
        Row.Enm := "TPF Enum"::Two;
        Row.Dt := 20240302D;
        Row.Tm := 123456T;
        Row.DtTm := CreateDateTime(20240302D, 123456T);
        Evaluate(Row.Gd, '{11111111-2222-3333-4444-555555555555}');
        Row.Dur := 5000;
        Row.Insert();
        List.OpenEdit();
        List.GoToKey('R1');
        Assert.AreEqual('1234567', List.Num.Value(), 'Integer');
        Assert.AreEqual('1,234,567.89', List.Dec2.Value(), 'Decimal');
        Assert.AreEqual('Yes', List.Flag.Value(), 'Boolean');
        Assert.AreEqual('Zwei', List.Opt.Value(), 'Option');
        Assert.AreEqual('Zwei', List.Enm.Value(), 'Enum');
        Assert.AreEqual('3/2/2024', List.Dt.Value(), 'Date');
        Assert.AreEqual('12:34:56 PM', Plain(List.Tm.Value()), 'Time');
        Assert.AreEqual('3/2/2024 12:34 PM', Plain(List.DtTm.Value()), 'DateTime');
        Assert.AreEqual('{11111111-2222-3333-4444-555555555555}', List.Gd.Value(), 'Guid');
        Assert.AreEqual('5 seconds', List.Dur.Value(), 'Duration');
        List.Close();
    end;

    [Test]
    procedure Value_ListDraftLine_EveryFieldType()
    var
        Row: Record "TPF Row";
        List: TestPage "TPF List";
    begin
        Row.DeleteAll();
        List.OpenEdit();
        Assert.AreEqual('0', List.Num.Value(), 'Integer');
        Assert.AreEqual('0.00', List.Dec2.Value(), 'Decimal');
        Assert.AreEqual('No', List.Flag.Value(), 'Boolean');
        Assert.AreEqual('Eins', List.Opt.Value(), 'Option');
        Assert.AreEqual('Eins', List.Enm.Value(), 'Enum');
        Assert.AreEqual('', List.Dt.Value(), 'Date');
        Assert.AreEqual('', List.Tm.Value(), 'Time');
        Assert.AreEqual('', List.DtTm.Value(), 'DateTime');
        Assert.AreEqual('{00000000-0000-0000-0000-000000000000}', List.Gd.Value(), 'Guid');
        Assert.AreEqual('', List.Dur.Value(), 'Duration');
        List.Close();
    end;

    // The space before AM/PM is U+202F where the runtime's culture data is CLDR 42 or newer, and
    // U+0020 where it is older; the expectations above are written with U+0020.
    local procedure Plain(T: Text): Text
    var
        Nnbsp: Text[1];
        Nbsp: Text[1];
    begin
        Nnbsp[1] := 8239;
        Nbsp[1] := 160;
        exit(T.Replace(Nnbsp, ' ').Replace(Nbsp, ' '));
    end;
}
