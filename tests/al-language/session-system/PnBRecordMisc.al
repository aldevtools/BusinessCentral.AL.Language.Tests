// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), PnBObjects.al (tables 70527/70529, log 70531, enum 70532), self-contained codeunits 70541-70548
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//   70541: "Enum | Names() and Ordinals() list the declared values in declaration order..." (146); "Format | Format(Rec.Field) of an Option field answers the field's OptionCaption..." (193)
//   70542: "Write transaction | Database.IsInWriteTransaction is true while..." (149); "Sequential Guid | CreateSequentialGuid is a fresh deterministic Guid..." (164);
//          "Guid | a Text assigns to a Guid in 8-4-4-4-12 form..." (161); "Database state | LastUsedRowVersion is the highest SystemRowVersion..." (199)
//   70543/70544: "Codeunit.Run with TableNo | A run with no record, or a temporary record..." (165)
//   70545: "Record.Find | =>, =< and =>< find the row itself, else its neighbour..." (183); "SetAscending | SetAscending(Field, false) is supported for a key of that single field only..." (148)
//   70546: "IsolatedStorage | the module is the app that owns the calling code..." (159); "Clock | Today, Time and CurrentDateTime read the host clock... Sleep(n)..." (175);
//          "WorkDate | WorkDate() is today until WorkDate(d) sets it..." (176); "Call depth | the ceiling is 992 nested AL calls..." (200)
//   (CurrFieldNo row (202) is settled in PnBPages.al, codeunit 70555)
//   70548: "Clear | Clear of a codeunit variable gives a fresh instance" (140); "Dialog | Open, Update, Close of a progress dialog do nothing" (160); "ApplicationArea" (174)
// BC versions: 29 (27 and 28 by CI)

codeunit 70541 "LT PnB Enum Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Enum_NamesAndOrdinals_Order()
    var
        Obs: Codeunit "Probe Observer";
        E: Enum "LT PnB Enum";
        Names: List of [Text];
        Ordinals: List of [Integer];
        i: Integer;
    begin
        Names := E.Names();
        Ordinals := E.Ordinals();
        Obs.Observe('namesCount', Format(Names.Count()));
        Obs.Observe('ordinalsCount', Format(Ordinals.Count()));
        for i := 1 to Names.Count() do begin
            Obs.Observe('name' + Format(i), Names.Get(i));
            Obs.Observe('ordinal' + Format(i), Format(Ordinals.Get(i)));
        end;
        Obs.Expect('namesCount', '5');
        Obs.Expect('ordinalsCount', '5');
        Obs.Expect('name1', 'First');
        Obs.Expect('ordinal1', '0');
        Obs.Expect('name2', 'Fifth');
        Obs.Expect('ordinal2', '5');
        Obs.Expect('name3', 'Second');
        Obs.Expect('ordinal3', '2');
        Obs.Expect('name4', 'Seventh');
        Obs.Expect('ordinal4', '7');
        Obs.Expect('name5', 'Third');
        Obs.Expect('ordinal5', '3');
        Obs.Verify();
    end;

    [Test]
    procedure Enum_Conversions()
    var
        Obs: Codeunit "Probe Observer";
        E: Enum "LT PnB Enum";
    begin
        E := Enum::"LT PnB Enum"::Fifth;
        Obs.Observe('format', Format(E));
        Obs.Observe('ordinal', Format(E.AsInteger()));
        E := Enum::"LT PnB Enum".FromInteger(7);
        Obs.Observe('fromInt7', Format(E));
        E := Enum::"LT PnB Enum".FromInteger(3);
        Obs.Observe('fromInt3', Format(E));
        Obs.Observe('formatFirst', Format(Enum::"LT PnB Enum"::First));
        Obs.Observe('formatFirstNo', Format(Enum::"LT PnB Enum"::First, 0, 1));
        Obs.Observe('formatFifthNo', Format(Enum::"LT PnB Enum"::Fifth, 0, 1));
        Obs.Observe('formatFifth9', Format(Enum::"LT PnB Enum"::Fifth, 0, 9));
        Obs.Expect('format', 'Cinq');
        Obs.Expect('ordinal', '5');
        Obs.Expect('fromInt7', 'Seventh');
        Obs.Expect('fromInt3', 'Third');
        Obs.Expect('formatFirst', 'First');
        Obs.Expect('formatFirstNo', 'First');
        Obs.Expect('formatFifthNo', 'Cinq');
        Obs.Expect('formatFifth9', '5');
        Obs.Verify();
    end;

    [Test]
    procedure OptionField_FormatUsesOptionCaption()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
        Ok: Boolean;
    begin
        Row.Opt := Row.Opt::One;
        Obs.Observe('format', Format(Row.Opt));
        Obs.Observe('format0', Format(Row.Opt, 0, 0));
        Obs.Observe('format1', Format(Row.Opt, 0, 1));
        Obs.Observe('format2', Format(Row.Opt, 0, 2));
        Obs.Observe('format9', Format(Row.Opt, 0, 9));
        Obs.Observe('formatLen2', Format(Row.Opt, 2));
        Obs.Observe('formatLen2n9', Format(Row.Opt, 2, 9));
        Obs.Observe('member', Format(Row.Opt::Two));
        Ok := Evaluate(Row.Opt, 'Uno');
        Obs.Observe('evalCaption', Format(Ok) + '/' + Format(Row.Opt));
        Ok := Evaluate(Row.Opt, 'Two');
        Obs.Observe('evalMember', Format(Ok) + '/' + Format(Row.Opt));
        Ok := Evaluate(Row.Opt, 'Dos');
        Obs.Observe('evalCaption2', Format(Ok) + '/' + Format(Row.Opt));
        Ok := Evaluate(Row.Opt, '1');
        Obs.Observe('evalOrdinal', Format(Ok) + '/' + Format(Row.Opt));
        Obs.Observe('fieldCaptionList', Row.FieldCaption(Opt));
        Obs.Expect('format', 'Uno');
        Obs.Expect('format0', 'Uno');
        Obs.Expect('format1', 'Uno');
        Obs.Expect('format2', '1');
        Obs.Expect('format9', '1');
        Obs.Expect('formatLen2', 'Un');
        Obs.Expect('formatLen2n9', '1 ');
        Obs.Expect('member', 'Dos');
        Obs.Expect('evalCaption', 'Yes/Uno');
        Obs.Expect('evalMember', 'Yes/Dos');
        Obs.Expect('evalCaption2', 'Yes/Dos');
        Obs.Expect('evalOrdinal', 'Yes/Uno');
        Obs.Expect('fieldCaptionList', 'Opt');
        Obs.Verify();
    end;

    [Test]
    procedure OptionField_ThroughFieldRef()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
        FR: FieldRef;
        RR: RecordRef;
    begin
        Row.Opt := Row.Opt::Two;
        RR.GetTable(Row);
        FR := RR.Field(Row.FieldNo(Opt));
        Obs.Observe('fr.value', Format(FR.Value()));
        Obs.Observe('fr.format', Format(FR));
        Obs.Observe('fr.optionCaption', FR.OptionCaption());
        Obs.Observe('fr.optionMembers', FR.OptionMembers());
        Obs.Observe('fr.optionString', FR.OptionString());
        Obs.Expect('fr.value', 'Dos');
        Obs.Expect('fr.format', 'Dos');
        Obs.Expect('fr.optionCaption', 'Nil,Uno,Dos');
        Obs.Expect('fr.optionMembers', 'Zero,One,Two');
        Obs.Expect('fr.optionString', 'Zero,One,Two');
        Obs.Verify();
    end;
}

codeunit 70542 "LT PnB WriteTx Guid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure IsInWriteTransaction_States()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
        Tmp: Record "LT PnB Row" temporary;
    begin
        Row.DeleteAll();
        Commit();
        Obs.Observe('afterCommit', Format(Database.IsInWriteTransaction()));
        Row.DeleteAll();
        Obs.Observe('deleteAllEmpty', Format(Database.IsInWriteTransaction()));
        Tmp.Id := 1;
        Tmp.Insert();
        Obs.Observe('tempInsert', Format(Database.IsInWriteTransaction()));
        Tmp.DeleteAll();
        Obs.Observe('tempDeleteAll', Format(Database.IsInWriteTransaction()));
        Row.Id := 1;
        Row.Insert();
        Obs.Observe('insert', Format(Database.IsInWriteTransaction()));
        Commit();
        Obs.Observe('afterCommit2', Format(Database.IsInWriteTransaction()));
        Row.Find('=');
        Obs.Observe('afterRead', Format(Database.IsInWriteTransaction()));
        Row.Name := 'x';
        Row.Modify();
        Obs.Observe('afterModify', Format(Database.IsInWriteTransaction()));
        Commit();
        Row.ModifyAll(Name, 'x');
        Obs.Observe('modifyAllNoChange', Format(Database.IsInWriteTransaction()));
        Commit();
        Row.SetRange(Id, 99);
        Row.DeleteAll();
        Obs.Observe('deleteAllNoMatch', Format(Database.IsInWriteTransaction()));
        Row.Reset();
        Row.DeleteAll();
        Obs.Observe('deleteAllMatch', Format(Database.IsInWriteTransaction()));
        Commit();
        Obs.Expect('afterCommit', 'No');
        Obs.Expect('deleteAllEmpty', 'Yes');
        Obs.Expect('tempInsert', 'Yes');
        Obs.Expect('tempDeleteAll', 'Yes');
        Obs.Expect('insert', 'Yes');
        Obs.Expect('afterCommit2', 'No');
        Obs.Expect('afterRead', 'No');
        Obs.Expect('afterModify', 'Yes');
        Obs.Expect('modifyAllNoChange', 'Yes');
        Obs.Expect('deleteAllNoMatch', 'Yes');
        Obs.Expect('deleteAllMatch', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure LastUsedRowVersion_AndLockTimeout()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
        V1: BigInteger;
        V2: BigInteger;
        Orig: Boolean;
    begin
        Row.DeleteAll();
        V1 := Database.LastUsedRowVersion();
        Obs.Observe('positive', Format(V1 > 0));
        Row.Id := 1;
        Row.Insert();
        V2 := Database.LastUsedRowVersion();
        Obs.Observe('afterInsertGreater', Format(V2 > V1));
        Obs.Observe('readTwice', Format(Database.LastUsedRowVersion() = V2));
        Orig := LockTimeout();
        Obs.Observe('lockTimeoutDefault', Format(Orig));
        LockTimeout(false);
        Obs.Observe('lockTimeoutFalse', Format(LockTimeout()));
        Commit();
        Obs.Observe('lockTimeoutAfterCommit', Format(LockTimeout()));
        LockTimeout(Orig);
        Obs.Observe('lockTimeoutRestored', Format(LockTimeout() = Orig));
        Obs.Expect('positive', 'Yes');
        Obs.Expect('afterInsertGreater', 'No');
        Obs.Expect('readTwice', 'Yes');
        Obs.Expect('lockTimeoutDefault', 'Yes');
        Obs.Expect('lockTimeoutFalse', 'No');
        Obs.Expect('lockTimeoutAfterCommit', 'Yes');
        Obs.Expect('lockTimeoutRestored', 'Yes');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryEval(T: Text; var G: Guid)
    begin
        if not Evaluate(G, T) then
            Error('evaluate returned false');
    end;

    local procedure GuidOf(T: Text): Text
    var
        G: Guid;
    begin
        if TryEval(T, G) then
            exit(Format(G));
        exit('error:' + GetLastErrorText());
    end;

    [Test]
    procedure Guid_TextForms()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('braced', GuidOf('{12345678-1234-1234-1234-123456789ABC}'));
        Obs.Observe('plain', GuidOf('12345678-1234-1234-1234-123456789abc'));
        Obs.Observe('lowerBraced', GuidOf('{12345678-abcd-abcd-abcd-123456789abc}'));
        Obs.Observe('noDashes', GuidOf('12345678123412341234123456789abc'));
        Obs.Observe('tooShort', GuidOf('12345678-1234-1234-1234-123456789ab'));
        Obs.Observe('nonHex', GuidOf('1234567g-1234-1234-1234-123456789abc'));
        Obs.Observe('empty', GuidOf(''));
        Obs.Observe('leftBraceOnly', GuidOf('{12345678-1234-1234-1234-123456789abc'));
        Obs.Observe('spaces', GuidOf(' 12345678-1234-1234-1234-123456789abc '));
        Obs.Observe('nullText', GuidOf('00000000-0000-0000-0000-000000000000'));
        Obs.Observe('parens', GuidOf('(12345678-1234-1234-1234-123456789abc)'));
        Obs.Expect('braced', '{12345678-1234-1234-1234-123456789ABC}');
        Obs.Expect('plain', '{12345678-1234-1234-1234-123456789ABC}');
        Obs.Expect('lowerBraced', '{12345678-ABCD-ABCD-ABCD-123456789ABC}');
        Obs.Expect('noDashes', '{12345678-1234-1234-1234-123456789ABC}');
        Obs.Expect('tooShort', 'error:evaluate returned false');
        Obs.Expect('nonHex', 'error:evaluate returned false');
        Obs.Expect('empty', 'error:evaluate returned false');
        Obs.Expect('leftBraceOnly', 'error:evaluate returned false');
        Obs.Expect('spaces', '{12345678-1234-1234-1234-123456789ABC}');
        Obs.Expect('nullText', '{00000000-0000-0000-0000-000000000000}');
        Obs.Expect('parens', '{12345678-1234-1234-1234-123456789ABC}');
        Obs.Verify();
    end;

    [Test]
    procedure Guid_FieldRefAndFilterText()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
        RR: RecordRef;
        FR: FieldRef;
        G: Guid;
    begin
        Row.DeleteAll();
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Row.Id := 1;
        Row.Gd := G;
        Row.Insert();
        Row.SetFilter(Gd, '12345678-1234-1234-1234-123456789abc');
        Obs.Observe('filterPlain', Format(Row.Count()));
        Row.SetFilter(Gd, '{12345678-1234-1234-1234-123456789ABC}');
        Obs.Observe('filterBraced', Format(Row.Count()));
        Row.Reset();
        RR.GetTable(Row);
        FR := RR.Field(Row.FieldNo(Gd));
        Obs.Observe('fieldRefValueFormat', Format(FR.Value()));
        Obs.Expect('filterPlain', '1');
        Obs.Expect('filterBraced', '1');
        Obs.Expect('fieldRefValueFormat', '{12345678-1234-1234-1234-123456789ABC}');
        Obs.Verify();
    end;
}

codeunit 70544 "LT PnB TableNo Run"
{
    TableNo = "LT PnB Row";

    trigger OnRun()
    var
        LogCu: Codeunit "LT PnB Log 3";
    begin
        LogCu.Add('Id=' + Format(Rec.Id) + ',Name=' + Rec.Name + ',IsTemp=' + Format(Rec.IsTemporary()) + ',Count=' + Format(Rec.Count()));
        Rec.Name := 'changed';
    end;
}

codeunit 70543 "LT PnB TableNo Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Run_NoRecord()
    var
        Obs: Codeunit "Probe Observer";
        LogCu: Codeunit "LT PnB Log 3";
        Row: Record "LT PnB Row";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Id := 5;
        Row.Name := 'five';
        Row.Insert();
        LogCu.Reset();
        asserterror Ok := Codeunit.Run(Codeunit::"LT PnB TableNo Run");
        Obs.ObserveError('af275');
        Obs.Observe('ok', Format(Ok));
        Obs.Observe('lastError', GetLastErrorText());
        Obs.Observe('log', LogCu.Joined());
        Obs.Expect('af275|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Obs.Expect('af275|code', 'DB:Ok');
        Obs.Expect('ok', 'No');
        Obs.Expect('lastError', '');
        Obs.Expect('log', '');
        Obs.Verify();
    end;

    [Test]
    procedure Run_TemporaryRecord()
    var
        Obs: Codeunit "Probe Observer";
        LogCu: Codeunit "LT PnB Log 3";
        Tmp: Record "LT PnB Row" temporary;
        Ok: Boolean;
    begin
        Tmp.Id := 9;
        Tmp.Name := 'nine';
        Tmp.Insert();
        LogCu.Reset();
        Ok := Codeunit.Run(Codeunit::"LT PnB TableNo Run", Tmp);
        Obs.Observe('ok', Format(Ok));
        Obs.Observe('lastError', GetLastErrorText());
        Obs.Observe('log', LogCu.Joined());
        Obs.Observe('nameAfter', Tmp.Name);
        Obs.Expect('ok', 'Yes');
        Obs.Expect('lastError', '');
        Obs.Expect('log', 'Id=9,Name=nine,IsTemp=Yes,Count=1');
        Obs.Expect('nameAfter', 'changed');
        Obs.Verify();
    end;

    [Test]
    procedure Run_RealRecord_ChangeReachesCaller()
    var
        Obs: Codeunit "Probe Observer";
        LogCu: Codeunit "LT PnB Log 3";
        Row: Record "LT PnB Row";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Id := 5;
        Row.Name := 'five';
        Row.Insert();
        LogCu.Reset();
        asserterror Ok := Codeunit.Run(Codeunit::"LT PnB TableNo Run", Row);
        Obs.ObserveError('af316');
        Obs.Observe('ok', Format(Ok));
        Obs.Observe('log', LogCu.Joined());
        Obs.Observe('nameAfter', Row.Name);
        asserterror Row.Get(5);
        Obs.ObserveError('af321');
        Obs.Observe('storedName', Row.Name);
        Obs.Expect('af316|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Obs.Expect('af316|code', 'DB:Ok');
        Obs.Expect('ok', 'No');
        Obs.Expect('log', '');
        Obs.Expect('nameAfter', 'five');
        Obs.Expect('af321|text', 'The LT PnB Row does not exist. Identification fields and values: Id=''5''');
        Obs.Expect('af321|code', 'DB:RecordNotFound');
        Obs.Expect('storedName', 'five');
        Obs.Verify();
    end;
}

codeunit 70545 "LT PnB Find Sort"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT PnB Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 5 do begin
            Row.Init();
            Row.Id := i * 10;
            Row.Name := CopyStr('N' + Format(6 - i), 1, 30);
            Row.Amount := 1 + (i mod 2);
            Row.Insert();
        end;
    end;

    local procedure FindAt(Mode: Text; Id: Integer; var Row: Record "LT PnB Row"): Text
    var
        Ok: Boolean;
    begin
        Row.Id := Id;
        Ok := Row.Find(Mode);
        exit(Format(Ok) + '/' + Format(Row.Id));
    end;

    [Test]
    procedure Find_NeighbourModes_PrimaryKey()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
    begin
        Seed();
        Obs.Observe('=>@20', FindAt('=>', 20, Row));
        Obs.Observe('=>@25', FindAt('=>', 25, Row));
        Obs.Observe('=>@5', FindAt('=>', 5, Row));
        Obs.Observe('=>@55', FindAt('=>', 55, Row));
        Obs.Observe('=<@20', FindAt('=<', 20, Row));
        Obs.Observe('=<@25', FindAt('=<', 25, Row));
        Obs.Observe('=<@5', FindAt('=<', 5, Row));
        Obs.Observe('=<@55', FindAt('=<', 55, Row));
        Obs.Observe('=><@20', FindAt('=><', 20, Row));
        Obs.Observe('=><@25', FindAt('=><', 25, Row));
        Obs.Observe('=><@5', FindAt('=><', 5, Row));
        Obs.Observe('=><@55', FindAt('=><', 55, Row));
        Obs.Observe('=><@22', FindAt('=><', 22, Row));
        Obs.Observe('=><@28', FindAt('=><', 28, Row));
        Obs.Expect('=>@20', 'Yes/20');
        Obs.Expect('=>@25', 'Yes/30');
        Obs.Expect('=>@5', 'Yes/10');
        Obs.Expect('=>@55', 'No/55');
        Obs.Expect('=<@20', 'Yes/20');
        Obs.Expect('=<@25', 'Yes/20');
        Obs.Expect('=<@5', 'No/5');
        Obs.Expect('=<@55', 'Yes/50');
        Obs.Expect('=><@20', 'Yes/20');
        Obs.Expect('=><@25', 'Yes/30');
        Obs.Expect('=><@5', 'Yes/10');
        Obs.Expect('=><@55', 'Yes/50');
        Obs.Expect('=><@22', 'Yes/30');
        Obs.Expect('=><@28', 'Yes/30');
        Obs.Verify();
    end;

    [Test]
    procedure Find_NeighbourModes_WithFilterAndKey()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
    begin
        Seed();
        Row.SetRange(Id, 20, 40);
        Obs.Observe('filter=>@10', FindAt('=>', 10, Row));
        Obs.Observe('filter=<@50', FindAt('=<', 50, Row));
        Obs.Observe('filter=><@25', FindAt('=><', 25, Row));
        Obs.Observe('filter=><@10', FindAt('=><', 10, Row));
        Obs.Observe('filter=>@20', FindAt('=>', 20, Row));
        Row.Reset();
        Row.SetCurrentKey(Name);
        Obs.Observe('keyName=>@20', FindAt('=>', 20, Row));
        Obs.Observe('keyName=<@20', FindAt('=<', 20, Row));
        Obs.Observe('keyName=><@25', FindAt('=><', 25, Row));
        Obs.Expect('filter=>@10', 'Yes/20');
        Obs.Expect('filter=<@50', 'Yes/40');
        Obs.Expect('filter=><@25', 'Yes/30');
        Obs.Expect('filter=><@10', 'Yes/20');
        Obs.Expect('filter=>@20', 'Yes/20');
        Obs.Expect('keyName=>@20', 'Yes/20');
        Obs.Expect('keyName=<@20', 'Yes/20');
        Obs.Expect('keyName=><@25', 'Yes/10');
        Obs.Verify();
    end;

    local procedure Walk(var Row: Record "LT PnB Row"): Text
    var
        R: Text;
    begin
        if Row.FindSet() then
            repeat
                R += Format(Row.Id) + ' ';
            until Row.Next() = 0;
        exit(R);
    end;

    [Test]
    procedure SetAscending_SingleFieldKey()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
    begin
        Seed();
        Row.SetCurrentKey(Id);
        Row.SetAscending(Id, false);
        Obs.Observe('ascendingFlag', Format(Row.Ascending()));
        Obs.Observe('descIds', Walk(Row));
        Row.SetAscending(Id, true);
        Obs.Observe('backToAsc', Walk(Row));
        Row.Reset();
        Row.SetCurrentKey(Name);
        Row.SetAscending(Name, false);
        Obs.Observe('nameDesc', Walk(Row));
        Obs.Observe('getView', Row.GetView());
        Row.SetRange(Id, 20, 40);
        Obs.Observe('descFiltered', Walk(Row));
        Obs.Expect('ascendingFlag', 'No');
        Obs.Expect('descIds', '50 40 30 20 10 ');
        Obs.Expect('backToAsc', '10 20 30 40 50 ');
        Obs.Expect('nameDesc', '10 20 30 40 50 ');
        Obs.Expect('getView', 'VERSION(1) SORTING(Name) ORDER(Descending)');
        Obs.Expect('descFiltered', '20 30 40 ');
        Obs.Verify();
    end;

    [Test]
    procedure SetAscending_MultiFieldKey_AndCopy()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
        Other: Record "LT PnB Row";
    begin
        Seed();
        Row.SetCurrentKey(Amount, Name);
        Obs.Observe('asc', Walk(Row));
        Row.SetAscending(Amount, false);
        Obs.Observe('amountDesc', Walk(Row));
        Obs.Observe('ascendingAfter', Format(Row.Ascending()));
        Obs.Observe('viewAfter', Row.GetView());
        Other.Copy(Row);
        Obs.Observe('copyWalk', Walk(Other));
        Obs.Observe('copyAscending', Format(Other.Ascending()));
        Row.Reset();
        Row.SetCurrentKey(Amount);
        Obs.Observe('tiesAmountKey', Walk(Row));
        Obs.Expect('asc', '40 20 50 30 10 ');
        Obs.Expect('amountDesc', '50 30 10 40 20 ');
        Obs.Expect('ascendingAfter', 'No');
        Obs.Expect('viewAfter', 'VERSION(1) SORTING(Amount,Name) ORDER(Descending,Ascending)');
        Obs.Expect('copyWalk', '50 30 10 40 20 ');
        Obs.Expect('copyAscending', 'No');
        Obs.Expect('tiesAmountKey', '40 20 50 30 10 ');
        Obs.Verify();
    end;
}


codeunit 70548 "LT PnB Clear Dialog"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Clear_CodeunitVariable_GivesFreshInstance()
    var
        Obs: Codeunit "Probe Observer";
        Counter: Codeunit "LT PnB Counter";
    begin
        Counter.Bump();
        Counter.Bump();
        Obs.Observe('before', Format(Counter.Value()));
        Clear(Counter);
        Obs.Observe('afterClear', Format(Counter.Value()));
        Counter.Bump();
        Obs.Observe('afterBump', Format(Counter.Value()));
        Obs.Expect('before', '2');
        Obs.Expect('afterClear', '0');
        Obs.Expect('afterBump', '1');
        Obs.Verify();
    end;

    [Test]
    procedure Dialog_OpenUpdateClose_AreHarmless()
    var
        Obs: Codeunit "Probe Observer";
        Dlg: Dialog;
    begin
        Dlg.Open('Working #1######');
        Dlg.Update(1, 'x');
        Dlg.Update(1, 5);
        Dlg.Close();
        Obs.Observe('done', 'ok');
        Dlg.Open('Again #1###### #2######');
        Dlg.Update(2, 'y');
        Dlg.Close();
        Obs.Observe('doneAgain', 'ok');
        Obs.Expect('done', 'ok');
        Obs.Expect('doneAgain', 'ok');
        Obs.Verify();
    end;

#if BC29PLUS
#endif
}

codeunit 70549 "LT PnB Counter"
{
    var
        Count: Integer;

    procedure Bump()
    begin
        Count += 1;
    end;

    procedure Value(): Integer
    begin
        exit(Count);
    end;
}
