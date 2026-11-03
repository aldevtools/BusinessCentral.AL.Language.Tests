// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table, log, two list pages
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GoToKey to the last row and back to row 2 on a list of exactly 41, 60 and 61 rows: reads per trigger (counts, run-length forms of the rows read, first and last 12 entries); page A has only OnAfterGetCurrRecord, page B has OnAfterGetRecord and OnAfterGetCurrRecord
// BC versions: 29 (27 and 28 by CI)

table 72727 "LT ListRows Window Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// SingleInstance log of this file; entries are a kind (G = OnAfterGetRecord, C = OnAfterGetCurrRecord, F = OnFindRecord, N = OnNextRecord, A = action) and the row id.
codeunit 72728 "LT ListRows Window Log"
{
    SingleInstance = true;

    var
        Kinds: List of [Text];
        RowIds: List of [Integer];

    procedure Wipe()
    begin
        Clear(Kinds);
        Clear(RowIds);
    end;

    procedure Add(Kind: Text; RowId: Integer)
    begin
        Kinds.Add(Kind);
        RowIds.Add(RowId);
    end;

    procedure Total(): Integer
    begin
        exit(Kinds.Count());
    end;

    procedure CountOf(Kind: Text): Integer
    var
        i: Integer;
        n: Integer;
    begin
        for i := 1 to Kinds.Count() do
            if Kinds.Get(i) = Kind then
                n += 1;
        exit(n);
    end;

    local procedure Piece(a: Integer; b: Integer): Text
    begin
        if a = b then
            exit(Format(a));
        exit(Format(a) + '-' + Format(b));
    end;

    // Run-length form of the row ids read by one kind: ascending runs of +1 as a-b, joined by comma.
    procedure Runs(Kind: Text): Text
    var
        i: Integer;
        v: Integer;
        Start: Integer;
        Prev: Integer;
        Started: Boolean;
        Result: Text;
    begin
        for i := 1 to Kinds.Count() do
            if Kinds.Get(i) = Kind then begin
                v := RowIds.Get(i);
                if not Started then begin
                    Start := v;
                    Prev := v;
                    Started := true;
                end else
                    if v = Prev + 1 then
                        Prev := v
                    else begin
                        if Result <> '' then
                            Result += ',';
                        Result += Piece(Start, Prev);
                        Start := v;
                        Prev := v;
                    end;
            end;
        if Started then begin
            if Result <> '' then
                Result += ',';
            Result += Piece(Start, Prev);
        end;
        exit(Result);
    end;

    procedure Head(N: Integer): Text
    var
        i: Integer;
        Result: Text;
    begin
        for i := 1 to N do
            if i <= Kinds.Count() then begin
                if Result <> '' then
                    Result += ';';
                Result += Kinds.Get(i) + Format(RowIds.Get(i));
            end;
        exit(Result);
    end;

    procedure Tail(N: Integer): Text
    var
        i: Integer;
        From: Integer;
        Result: Text;
    begin
        From := Kinds.Count() - N + 1;
        if From < 1 then
            From := 1;
        for i := From to Kinds.Count() do begin
            if Result <> '' then
                Result += ';';
            Result += Kinds.Get(i) + Format(RowIds.Get(i));
        end;
        exit(Result);
    end;
}

page 72729 "LT ListRows Window A"
{
    PageType = List;
    SourceTable = "LT ListRows Window Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "LT ListRows Window Log";

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C', Rec.Id);
    end;
}

page 72730 "LT ListRows Window B"
{
    PageType = List;
    SourceTable = "LT ListRows Window Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "LT ListRows Window Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('G', Rec.Id);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C', Rec.Id);
    end;
}

codeunit 72731 "LT ListRows Window"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Row: Record "LT ListRows Window Row";
        Log: Codeunit "LT ListRows Window Log";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Rows do begin
            Row.Init();
            Row.Id := i;
            Row.Name := 'Row ' + Format(i);
            Row.Insert();
        end;
        Log.Wipe();
    end;

    local procedure ObserveDump(var Observer: Codeunit "Probe Observer"; Tag: Text)
    var
        Log: Codeunit "LT ListRows Window Log";
    begin
        Observer.Observe(Tag + '-total', Format(Log.Total()));
        Observer.Observe(Tag + '-G-count', Format(Log.CountOf('G')));
        Observer.Observe(Tag + '-C-count', Format(Log.CountOf('C')));
        Observer.Observe(Tag + '-G-runs', CopyStr(Log.Runs('G'), 1, 800));
        Observer.Observe(Tag + '-C-runs', CopyStr(Log.Runs('C'), 1, 800));
        Observer.Observe(Tag + '-first12', Log.Head(12));
        Observer.Observe(Tag + '-last12', Log.Tail(12));
    end;

    local procedure ObserveDumpFN(var Observer: Codeunit "Probe Observer"; Tag: Text)
    var
        Log: Codeunit "LT ListRows Window Log";
    begin
        Observer.Observe(Tag + '-total', Format(Log.Total()));
        Observer.Observe(Tag + '-F-count', Format(Log.CountOf('F')));
        Observer.Observe(Tag + '-N-count', Format(Log.CountOf('N')));
        Observer.Observe(Tag + '-F-runs', CopyStr(Log.Runs('F'), 1, 800));
        Observer.Observe(Tag + '-N-runs', CopyStr(Log.Runs('N'), 1, 800));
        Observer.Observe(Tag + '-first12', Log.Head(12));
        Observer.Observe(Tag + '-last12', Log.Tail(12));
    end;

    [Test]
    procedure GoToKeyLastThenRow2_OnlyCurr41Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows Window Log";
        List: TestPage "LT ListRows Window A";
    begin
        Seed(41);
        List.OpenView();
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('hit-last', Format(List.GoToKey(41)));
        Observer.Observe('current-last', List.IdCtl.Value());
        ObserveDump(Observer, 'to-last');
        Log.Wipe();
        Observer.Observe('hit-row2', Format(List.GoToKey(2)));
        Observer.Observe('current-row2', List.IdCtl.Value());
        ObserveDump(Observer, 'back-to-2');
        List.Close();
        Observer.Expect('open-total', '1');
        Observer.Expect('open-G-count', '0');
        Observer.Expect('open-C-count', '1');
        Observer.Expect('open-G-runs', '');
        Observer.Expect('open-C-runs', '1');
        Observer.Expect('open-first12', 'C1');
        Observer.Expect('open-last12', 'C1');
        Observer.Expect('hit-last', 'Yes');
        Observer.Expect('current-last', '41');
        Observer.Expect('to-last-total', '40');
        Observer.Expect('to-last-G-count', '0');
        Observer.Expect('to-last-C-count', '40');
        Observer.Expect('to-last-G-runs', '');
        Observer.Expect('to-last-C-runs', '2-41');
        Observer.Expect('to-last-first12', 'C2;C3;C4;C5;C6;C7;C8;C9;C10;C11;C12;C13');
        Observer.Expect('to-last-last12', 'C30;C31;C32;C33;C34;C35;C36;C37;C38;C39;C40;C41');
        Observer.Expect('hit-row2', 'Yes');
        Observer.Expect('current-row2', '2');
        Observer.Expect('back-to-2-total', '2');
        Observer.Expect('back-to-2-G-count', '0');
        Observer.Expect('back-to-2-C-count', '2');
        Observer.Expect('back-to-2-G-runs', '');
        Observer.Expect('back-to-2-C-runs', '1-2');
        Observer.Expect('back-to-2-first12', 'C1;C2');
        Observer.Expect('back-to-2-last12', 'C1;C2');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyLastThenRow2_OnlyCurr60Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows Window Log";
        List: TestPage "LT ListRows Window A";
    begin
        Seed(60);
        List.OpenView();
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('hit-last', Format(List.GoToKey(60)));
        Observer.Observe('current-last', List.IdCtl.Value());
        ObserveDump(Observer, 'to-last');
        Log.Wipe();
        Observer.Observe('hit-row2', Format(List.GoToKey(2)));
        Observer.Observe('current-row2', List.IdCtl.Value());
        ObserveDump(Observer, 'back-to-2');
        List.Close();
        Observer.Expect('open-total', '1');
        Observer.Expect('open-G-count', '0');
        Observer.Expect('open-C-count', '1');
        Observer.Expect('open-G-runs', '');
        Observer.Expect('open-C-runs', '1');
        Observer.Expect('open-first12', 'C1');
        Observer.Expect('open-last12', 'C1');
        Observer.Expect('hit-last', 'Yes');
        Observer.Expect('current-last', '60');
        Observer.Expect('to-last-total', '59');
        Observer.Expect('to-last-G-count', '0');
        Observer.Expect('to-last-C-count', '59');
        Observer.Expect('to-last-G-runs', '');
        Observer.Expect('to-last-C-runs', '2-60');
        Observer.Expect('to-last-first12', 'C2;C3;C4;C5;C6;C7;C8;C9;C10;C11;C12;C13');
        Observer.Expect('to-last-last12', 'C49;C50;C51;C52;C53;C54;C55;C56;C57;C58;C59;C60');
        Observer.Expect('hit-row2', 'Yes');
        Observer.Expect('current-row2', '2');
        Observer.Expect('back-to-2-total', '2');
        Observer.Expect('back-to-2-G-count', '0');
        Observer.Expect('back-to-2-C-count', '2');
        Observer.Expect('back-to-2-G-runs', '');
        Observer.Expect('back-to-2-C-runs', '1-2');
        Observer.Expect('back-to-2-first12', 'C1;C2');
        Observer.Expect('back-to-2-last12', 'C1;C2');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyLastThenRow2_OnlyCurr61Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows Window Log";
        List: TestPage "LT ListRows Window A";
    begin
        Seed(61);
        List.OpenView();
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('hit-last', Format(List.GoToKey(61)));
        Observer.Observe('current-last', List.IdCtl.Value());
        ObserveDump(Observer, 'to-last');
        Log.Wipe();
        Observer.Observe('hit-row2', Format(List.GoToKey(2)));
        Observer.Observe('current-row2', List.IdCtl.Value());
        ObserveDump(Observer, 'back-to-2');
        List.Close();
        Observer.Expect('open-total', '1');
        Observer.Expect('open-G-count', '0');
        Observer.Expect('open-C-count', '1');
        Observer.Expect('open-G-runs', '');
        Observer.Expect('open-C-runs', '1');
        Observer.Expect('open-first12', 'C1');
        Observer.Expect('open-last12', 'C1');
        Observer.Expect('hit-last', 'Yes');
        Observer.Expect('current-last', '61');
        Observer.Expect('to-last-total', '60');
        Observer.Expect('to-last-G-count', '0');
        Observer.Expect('to-last-C-count', '60');
        Observer.Expect('to-last-G-runs', '');
        Observer.Expect('to-last-C-runs', '2-61');
        Observer.Expect('to-last-first12', 'C2;C3;C4;C5;C6;C7;C8;C9;C10;C11;C12;C13');
        Observer.Expect('to-last-last12', 'C50;C51;C52;C53;C54;C55;C56;C57;C58;C59;C60;C61');
        Observer.Expect('hit-row2', 'Yes');
        Observer.Expect('current-row2', '2');
        Observer.Expect('back-to-2-total', '2');
        Observer.Expect('back-to-2-G-count', '0');
        Observer.Expect('back-to-2-C-count', '2');
        Observer.Expect('back-to-2-G-runs', '');
        Observer.Expect('back-to-2-C-runs', '1-2');
        Observer.Expect('back-to-2-first12', 'C1;C2');
        Observer.Expect('back-to-2-last12', 'C1;C2');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyLastThenRow2_Both41Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows Window Log";
        List: TestPage "LT ListRows Window B";
    begin
        Seed(41);
        List.OpenView();
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('hit-last', Format(List.GoToKey(41)));
        Observer.Observe('current-last', List.IdCtl.Value());
        ObserveDump(Observer, 'to-last');
        Log.Wipe();
        Observer.Observe('hit-row2', Format(List.GoToKey(2)));
        Observer.Observe('current-row2', List.IdCtl.Value());
        ObserveDump(Observer, 'back-to-2');
        List.Close();
        Observer.Expect('open-total', '23');
        Observer.Expect('open-G-count', '22');
        Observer.Expect('open-C-count', '1');
        Observer.Expect('open-G-runs', '1-20,1,1');
        Observer.Expect('open-C-runs', '1');
        Observer.Expect('open-first12', 'G1;G2;G3;G4;G5;G6;G7;G8;G9;G10;G11;G12');
        Observer.Expect('open-last12', 'G12;G13;G14;G15;G16;G17;G18;G19;G20;G1;G1;C1');
        Observer.Expect('hit-last', 'Yes');
        Observer.Expect('current-last', '41');
        Observer.Expect('to-last-total', '143');
        Observer.Expect('to-last-G-count', '103');
        Observer.Expect('to-last-C-count', '40');
        Observer.Expect('to-last-G-runs', '2,2-3,3-4,4-5,5-6,6-7,7-8,8-9,9-10,10-11,11-12,12-13,13-14,14-15,15-16,16-17,17-18,18-19,19-40,20,20-21,21-22,22-23,23-24,24-25,25-26,26-27,27-28,28-29,29-30,30-31,31-32,32-33,33-34,34-35,35-36,36-37,37-38,38-39,39-41,40,40-41,41');
        Observer.Expect('to-last-C-runs', '2-41');
        Observer.Expect('to-last-first12', 'G2;G2;C2;G3;G3;C3;G4;G4;C4;G5;G5;C5');
        Observer.Expect('to-last-last12', 'C38;G39;G39;C39;G40;G41;G40;G40;C40;G41;G41;C41');
        Observer.Expect('hit-row2', 'Yes');
        Observer.Expect('current-row2', '2');
        Observer.Expect('back-to-2-total', '6');
        Observer.Expect('back-to-2-G-count', '4');
        Observer.Expect('back-to-2-C-count', '2');
        Observer.Expect('back-to-2-G-runs', '1,1-2,2');
        Observer.Expect('back-to-2-C-runs', '1-2');
        Observer.Expect('back-to-2-first12', 'G1;G1;C1;G2;G2;C2');
        Observer.Expect('back-to-2-last12', 'G1;G1;C1;G2;G2;C2');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyLastThenRow2_Both60Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows Window Log";
        List: TestPage "LT ListRows Window B";
    begin
        Seed(60);
        List.OpenView();
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('hit-last', Format(List.GoToKey(60)));
        Observer.Observe('current-last', List.IdCtl.Value());
        ObserveDump(Observer, 'to-last');
        Log.Wipe();
        Observer.Observe('hit-row2', Format(List.GoToKey(2)));
        Observer.Observe('current-row2', List.IdCtl.Value());
        ObserveDump(Observer, 'back-to-2');
        List.Close();
        Observer.Expect('open-total', '23');
        Observer.Expect('open-G-count', '22');
        Observer.Expect('open-C-count', '1');
        Observer.Expect('open-G-runs', '1-20,1,1');
        Observer.Expect('open-C-runs', '1');
        Observer.Expect('open-first12', 'G1;G2;G3;G4;G5;G6;G7;G8;G9;G10;G11;G12');
        Observer.Expect('open-last12', 'G12;G13;G14;G15;G16;G17;G18;G19;G20;G1;G1;C1');
        Observer.Expect('hit-last', 'Yes');
        Observer.Expect('current-last', '60');
        Observer.Expect('to-last-total', '220');
        Observer.Expect('to-last-G-count', '161');
        Observer.Expect('to-last-C-count', '59');
        Observer.Expect('to-last-G-runs', '2,2-3,3-4,4-5,5-6,6-7,7-8,8-9,9-10,10-11,11-12,12-13,13-14,14-15,15-16,16-17,17-18,18-19,19-40,20,20-21,21-22,22-23,23-24,24-25,25-26,26-27,27-28,28-29,29-30,30-31,31-32,32-33,33-34,34-35,35-36,36-37,37-38,38-39,39-60,40,40-41,41-42,42-43,43-44,44-45,45-46,46-47,47-48,48-49,49-50,50-51,51-52,52-53,53-54,54-55,55-56,56-57,57-58,58-59,59-60,60,60');
        Observer.Expect('to-last-C-runs', '2-60');
        Observer.Expect('to-last-first12', 'G2;G2;C2;G3;G3;C3;G4;G4;C4;G5;G5;C5');
        Observer.Expect('to-last-last12', 'G57;C57;G58;G58;C58;G59;G59;C59;G60;G60;G60;C60');
        Observer.Expect('hit-row2', 'Yes');
        Observer.Expect('current-row2', '2');
        Observer.Expect('back-to-2-total', '6');
        Observer.Expect('back-to-2-G-count', '4');
        Observer.Expect('back-to-2-C-count', '2');
        Observer.Expect('back-to-2-G-runs', '1,1-2,2');
        Observer.Expect('back-to-2-C-runs', '1-2');
        Observer.Expect('back-to-2-first12', 'G1;G1;C1;G2;G2;C2');
        Observer.Expect('back-to-2-last12', 'G1;G1;C1;G2;G2;C2');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyLastThenRow2_Both61Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows Window Log";
        List: TestPage "LT ListRows Window B";
    begin
        Seed(61);
        List.OpenView();
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('hit-last', Format(List.GoToKey(61)));
        Observer.Observe('current-last', List.IdCtl.Value());
        ObserveDump(Observer, 'to-last');
        Log.Wipe();
        Observer.Observe('hit-row2', Format(List.GoToKey(2)));
        Observer.Observe('current-row2', List.IdCtl.Value());
        ObserveDump(Observer, 'back-to-2');
        List.Close();
        Observer.Expect('open-total', '23');
        Observer.Expect('open-G-count', '22');
        Observer.Expect('open-C-count', '1');
        Observer.Expect('open-G-runs', '1-20,1,1');
        Observer.Expect('open-C-runs', '1');
        Observer.Expect('open-first12', 'G1;G2;G3;G4;G5;G6;G7;G8;G9;G10;G11;G12');
        Observer.Expect('open-last12', 'G12;G13;G14;G15;G16;G17;G18;G19;G20;G1;G1;C1');
        Observer.Expect('hit-last', 'Yes');
        Observer.Expect('current-last', '61');
        Observer.Expect('to-last-total', '224');
        Observer.Expect('to-last-G-count', '164');
        Observer.Expect('to-last-C-count', '60');
        Observer.Expect('to-last-G-runs', '2,2-3,3-4,4-5,5-6,6-7,7-8,8-9,9-10,10-11,11-12,12-13,13-14,14-15,15-16,16-17,17-18,18-19,19-40,20,20-21,21-22,22-23,23-24,24-25,25-26,26-27,27-28,28-29,29-30,30-31,31-32,32-33,33-34,34-35,35-36,36-37,37-38,38-39,39-60,40,40-41,41-42,42-43,43-44,44-45,45-46,46-47,47-48,48-49,49-50,50-51,51-52,52-53,53-54,54-55,55-56,56-57,57-58,58-59,59-61,60,60-61,61');
        Observer.Expect('to-last-C-runs', '2-61');
        Observer.Expect('to-last-first12', 'G2;G2;C2;G3;G3;C3;G4;G4;C4;G5;G5;C5');
        Observer.Expect('to-last-last12', 'C58;G59;G59;C59;G60;G61;G60;G60;C60;G61;G61;C61');
        Observer.Expect('hit-row2', 'Yes');
        Observer.Expect('current-row2', '2');
        Observer.Expect('back-to-2-total', '6');
        Observer.Expect('back-to-2-G-count', '4');
        Observer.Expect('back-to-2-C-count', '2');
        Observer.Expect('back-to-2-G-runs', '1,1-2,2');
        Observer.Expect('back-to-2-C-runs', '1-2');
        Observer.Expect('back-to-2-first12', 'G1;G1;C1;G2;G2;C2');
        Observer.Expect('back-to-2-last12', 'G1;G1;C1;G2;G2;C2');
        Observer.Verify();
    end;
}
