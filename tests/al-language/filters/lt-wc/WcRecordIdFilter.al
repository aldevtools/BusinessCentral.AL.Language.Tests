// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90643, tables 90642-90644
// Probe: written against al-runner issue 6309 (SetFilter on a RecordId field with the text Format(RecordId)); every value asserted below is what the BC service tier produced.
// Facts: a RecordId field filtered with the text Format(RecordId): the rows kept and GetFilter afterwards, for a table whose caption differs from its name,
//        a two-field key with a space and a comma in a Code value, the empty RecordId, a placeholder, and text that is not a RecordId.
// BC versions: 27, 28, 29

table 90642 "LT WC RF Doc"
{
    Caption = 'LT WC Document';
    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 90643 "LT WC RF Line"
{
    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
    }
    keys { key(PK; "Doc No.", "Line No.") { Clustered = true; } }
}

table 90644 "LT WC RF Log"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Record ID"; RecordId) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByRecord; "Record ID") { }
    }
}

codeunit 90643 "LT WC Record Id Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Doc: Record "LT WC RF Doc";
        Line: Record "LT WC RF Line";
        Log: Record "LT WC RF Log";
    begin
        Log.DeleteAll();
        Doc.DeleteAll();
        Line.DeleteAll();
        Doc."No." := 'A';
        Doc.Insert();
        Doc."No." := 'B';
        Doc.Insert();
        Line."Doc No." := 'X Y,Z';
        Line."Line No." := 10000;
        Line.Insert();
        Line."Doc No." := 'X Y,Z';
        Line."Line No." := 20000;
        Line.Insert();
        Doc.Get('A');
        AddLog(1, Doc.RecordId);
        Doc.Get('B');
        AddLog(2, Doc.RecordId);
        AddLog(3, Line.RecordId);
        Line."Line No." := 10000;
        Line.Find();
        AddLog(4, Line.RecordId);
    end;

    local procedure AddLog(No: Integer; Id: RecordId)
    var
        Log: Record "LT WC RF Log";
    begin
        Log."Entry No." := No;
        Log."Record ID" := Id;
        Log.Insert();
    end;

    local procedure Ids(var Log: Record "LT WC RF Log"): Text
    var
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                Result += Format(Log."Entry No.") + ',';
            until Log.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryFilter(Txt: Text; var Result: Text)
    var
        Log: Record "LT WC RF Log";
    begin
        Log.SetFilter("Record ID", Txt);
        Result := 'filter=[' + Log.GetFilter("Record ID") + '] ids=' + Ids(Log);
    end;

    local procedure Probe(Txt: Text): Text
    var
        Result: Text;
    begin
        if TryFilter(Txt, Result) then
            exit(Result);
        Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure WC_RecordIdFilter_FormatText()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "LT WC RF Doc";
        Line: Record "LT WC RF Line";
    begin
        Seed();
        Doc.Get('A');
        Observer.Observe('doc text', Format(Doc.RecordId));
        Observer.Observe('doc A', Probe(Format(Doc.RecordId)));
        Doc.Get('B');
        Observer.Observe('doc B', Probe(Format(Doc.RecordId)));
        Line.Get('X Y,Z', 10000);
        Observer.Observe('line text', Format(Line.RecordId));
        Observer.Observe('line key with space and comma', Probe(Format(Line.RecordId)));
        Observer.Finish();
    end;

    [Test]
    procedure WC_RecordIdFilter_EmptyAndWrongText()
    var
        Observer: Codeunit "Probe Observer";
        Empty: RecordId;
    begin
        Seed();
        Observer.Observe('empty format', Format(Empty));
        Observer.Observe('empty RecordId text', Probe(Format(Empty)));
        Observer.Observe('empty text', Probe(''));
        Observer.Observe('not a RecordId', Probe('garbage'));
        Observer.Observe('unknown table', Probe('No Such Table: A'));
        Observer.Observe('table caption not name', Probe('LT WC Document: A'));
        Observer.Observe('table name', Probe('LT WC RF Doc: A'));
        Observer.Observe('missing key part', Probe('LT WC RF Line: X'));
        Observer.Finish();
    end;

    [Test]
    procedure WC_RecordIdFilter_PlaceholderAndRange()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "LT WC RF Doc";
        Log: Record "LT WC RF Log";
    begin
        Seed();
        Doc.Get('A');
        Log.SetFilter("Record ID", '%1', Doc.RecordId);
        Observer.Observe('placeholder', 'filter=[' + Log.GetFilter("Record ID") + '] ids=' + Ids(Log));
        Log.Reset();
        Log.SetRange("Record ID", Doc.RecordId);
        Observer.Observe('SetRange', 'filter=[' + Log.GetFilter("Record ID") + '] ids=' + Ids(Log));
        Log.Reset();
        Log.SetFilter("Record ID", '<>' + Format(Doc.RecordId));
        Observer.Observe('not equal', 'filter=[' + Log.GetFilter("Record ID") + '] ids=' + Ids(Log));
        Observer.Finish();
    end;
}
