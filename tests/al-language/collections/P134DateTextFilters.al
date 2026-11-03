// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74132, page 74133, test codeunit 74134 (P134)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a text filter on a Date column through TestFilter.SetFilter (page filter) and through FieldRef.SetFilter: the empty text, blank filter '', 0D, formulas such as 1M and CM, the region's date spellings (01/01/26, 1/1/2026, 2026-01-01) and invalid text: the filter text kept (GetFilter), the rows left and the error text and code. Record.SetFilter is pinned by record/lt-loadfields-pagesource-validate/P81DateFilters.al
// BC versions: 29 (27 and 28 by CI)

table 74132 "LT P134 DateRow"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 74133 "LT P134 DateList"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P134 DateRow";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(D; Rec.D) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 74134 "LT P134 Date Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P134 DateRow";
    begin
        Row.DeleteAll();
        Add(1, 0D);
        Add(2, 20260101D);
        Add(3, 20260115D);
        Add(4, 20260201D);
        Add(5, 20251231D);
    end;

    local procedure Add(NewId: Integer; NewDate: Date)
    var
        Row: Record "LT P134 DateRow";
    begin
        Row.Id := NewId;
        Row.D := NewDate;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryTestFilter(var L: TestPage "LT P134 DateList"; Txt: Text)
    begin
        L.Filter.SetFilter(D, Txt);
    end;

    [TryFunction]
    local procedure TryFieldRef(var F: FieldRef; Txt: Text)
    begin
        F.SetFilter(Txt);
    end;

    local procedure Rows(var L: TestPage "LT P134 DateList"): Text
    var
        Ids: Text;
    begin
        if L.First() then
            repeat
                Ids += Format(L.Id.Value) + ',';
            until not L.Next();
        exit(Ids);
    end;

    local procedure ApplyTestFilter(Txt: Text): Text
    var
        L: TestPage "LT P134 DateList";
        Result: Text;
    begin
        L.OpenView();
        if not TryTestFilter(L, Txt) then begin
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
            ClearLastError();
            L.Close();
            exit(Result);
        end;
        Result := 'ok|filter=' + L.Filter.GetFilter(D) + '|rows=' + Rows(L);
        L.Close();
        exit(Result);
    end;

    local procedure ApplyFieldRef(Txt: Text): Text
    var
        RecRef: RecordRef;
        F: FieldRef;
        Ids: Text;
        Result: Text;
    begin
        RecRef.Open(Database::"LT P134 DateRow");
        F := RecRef.Field(2);
        if not TryFieldRef(F, Txt) then begin
            Result := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
            ClearLastError();
            RecRef.Close();
            exit(Result);
        end;
        if RecRef.FindSet() then
            repeat
                Ids += Format(RecRef.Field(1).Value) + ',';
            until RecRef.Next() = 0;
        Result := 'ok|filter=' + F.GetFilter() + '|rows=' + Ids;
        RecRef.Close();
        exit(Result);
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer"; Texts: List of [Text]; Prefix: Text; Mode: Integer)
    var
        Txt: Text;
        i: Integer;
    begin
        foreach Txt in Texts do begin
            i += 1;
            if Mode = 0 then
                Observer.Observe(Prefix + Format(i) + '[' + Txt + ']', ApplyTestFilter(Txt))
            else
                Observer.Observe(Prefix + Format(i) + '[' + Txt + ']', ApplyFieldRef(Txt));
        end;
    end;

    [Test]
    procedure P134_TestFilter_Date_RegionAndIsoSpellings()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('010126');
        Texts.Add('01012026');
        Texts.Add('01/01/26');
        Texts.Add('01/01/2026');
        Texts.Add('1/1/26');
        Texts.Add('1/1/2026');
        Texts.Add('2026-01-01');
        Texts.Add('01.01.2026');
        Texts.Add('01-01-2026');
        Texts.Add('01/15/26');
        Texts.Add('15/01/26');
        Texts.Add('Jan 1, 2026');
        asserterror ObserveAll(Observer, Texts, 's', 0);
        Observer.ObserveError('af209');
        Observer.Expect('s1[010126]', 'ok|filter=01/01/26|rows=2,');
        Observer.Expect('s2[01012026]', 'ok|filter=01/01/26|rows=2,');
        Observer.Expect('s3[01/01/26]', 'ok|filter=01/01/26|rows=2,');
        Observer.Expect('s4[01/01/2026]', 'ok|filter=01/01/26|rows=2,');
        Observer.Expect('s5[1/1/26]', 'ok|filter=01/01/26|rows=2,');
        Observer.Expect('s6[1/1/2026]', 'ok|filter=01/01/26|rows=2,');
        Observer.Expect('s7[2026-01-01]', 'ok|filter=01/01/26|rows=2,');
        Observer.Expect('s8[01.01.2026]', 'ok|filter=01/01/26|rows=2,');
        Observer.Expect('s9[01-01-2026]', 'ok|filter=01/01/26|rows=2,');
        Observer.Expect('s10[01/15/26]', 'ok|filter=01/15/26|rows=3,');
        Observer.Expect('af209|text', 'The filter "15/01/26" is not valid for the D field on the LT P134 DateRow table. The format of the Date ''15/01/26'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('af209|code', 'DataBinding:Filter');
        Observer.Verify();
    end;

    [Test]
    procedure P134_TestFilter_Date_Ranges()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('010126..150126');
        Texts.Add('01/01/26..01/15/26');
        Texts.Add('..01/15/26');
        Texts.Add('01/15/26..');
        Texts.Add('2026-01-01..2026-01-15');
        Texts.Add('<01/15/26');
        Texts.Add('>=01/15/26');
        Texts.Add('<>01/15/26');
        Texts.Add('01/01/26|02/01/26');
        Texts.Add('150126..010126');
        asserterror ObserveAll(Observer, Texts, 'r', 0);
        Observer.ObserveError('af231');
        Observer.Expect('af231|text', 'The filter "010126..150126" is not valid for the D field on the LT P134 DateRow table. The format of the Date ''150126'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('af231|code', 'DataBinding:Filter');
        Observer.Verify();
    end;

    [Test]
    procedure P134_TestFilter_Date_InvalidTexts()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('abc');
        Texts.Add('13132026');
        Texts.Add('01/32/26');
        Texts.Add('01012026..abc');
        Texts.Add('|');
        Texts.Add('*');
        Texts.Add('99999999');
        Texts.Add('01/01/26 ');
        Texts.Add(' 01/01/26');
        asserterror ObserveAll(Observer, Texts, 'i', 0);
        Observer.ObserveError('af252');
        Observer.Expect('af252|text', 'The filter "abc" is not valid for the D field on the LT P134 DateRow table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('af252|code', 'DataBinding:Filter');
        Observer.Verify();
    end;

    [Test]
    procedure P134_FieldRef_Date_EmptyAndBlankForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
    begin
        Seed();
        Texts.Add('');
        Texts.Add(' ');
        Texts.Add('''''');
        Texts.Add('<>''''');
        Texts.Add('0D');
        Texts.Add('<>0D');
        Texts.Add('0');
        ObserveAll(Observer, Texts, 'e', 1);
        Observer.Expect('e1[]', 'ok|filter=|rows=1,2,3,4,5,');
        Observer.Expect('e2[ ]', 'ok|filter=|rows=1,2,3,4,5,');
        Observer.Expect('e3['''']', 'ok|filter=''''|rows=1,');
        Observer.Expect('e4[<>'''']', 'ok|filter=<>''''|rows=2,3,4,5,');
        Observer.Expect('e5[0D]', 'ok|filter=' + Format(Today(), 0, '<Month,2>/<Day,2>/<Year,2>') + '|rows=');
        Observer.Expect('e6[<>0D]', 'ok|filter=<>' + Format(Today(), 0, '<Month,2>/<Day,2>/<Year,2>') + '|rows=1,2,3,4,5,');
        Observer.Expect('e7[0]', 'error:The filter "0" is not valid for the D field on the LT P134 DateRow table. The format of the Date ''0'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Verify();
    end;
}
