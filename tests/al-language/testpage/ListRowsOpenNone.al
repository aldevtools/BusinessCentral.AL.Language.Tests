// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table, log, two list pages
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: reads at open of a 5-row and a 30-row list with neither OnAfterGetRecord nor OnAfterGetCurrRecord; the second page logs OnFindRecord and OnNextRecord to make the reads visible
// BC versions: 29 (27 and 28 by CI)

table 72738 "LT ListRows OpenNone Row"
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
codeunit 72739 "LT ListRows OpenNone Log"
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

page 72740 "LT ListRows OpenNone Bare"
{
    PageType = List;
    SourceTable = "LT ListRows OpenNone Row";
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
        Log: Codeunit "LT ListRows OpenNone Log";
}

page 72741 "LT ListRows OpenNone Find"
{
    PageType = List;
    SourceTable = "LT ListRows OpenNone Row";
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
        Log: Codeunit "LT ListRows OpenNone Log";

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Log.Add('F', Rec.Id);
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N', Rec.Id);
        exit(Moved);
    end;
}

codeunit 72742 "LT ListRows OpenNone"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Row: Record "LT ListRows OpenNone Row";
        Log: Codeunit "LT ListRows OpenNone Log";
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
        Log: Codeunit "LT ListRows OpenNone Log";
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
        Log: Codeunit "LT ListRows OpenNone Log";
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
    procedure OpenView_Bare5Rows_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows OpenNone Log";
        List: TestPage "LT ListRows OpenNone Bare";
    begin
        Seed(5);
        List.OpenView();
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('hit-last', Format(List.GoToKey(5)));
        ObserveDump(Observer, 'to-last');
        List.Close();
        Observer.Expect('current', '1');
        Observer.Expect('open-total', '0');
        Observer.Expect('open-G-count', '0');
        Observer.Expect('open-C-count', '0');
        Observer.Expect('open-G-runs', '');
        Observer.Expect('open-C-runs', '');
        Observer.Expect('open-first12', '');
        Observer.Expect('open-last12', '');
        Observer.Expect('hit-last', 'Yes');
        Observer.Expect('to-last-total', '0');
        Observer.Expect('to-last-G-count', '0');
        Observer.Expect('to-last-C-count', '0');
        Observer.Expect('to-last-G-runs', '');
        Observer.Expect('to-last-C-runs', '');
        Observer.Expect('to-last-first12', '');
        Observer.Expect('to-last-last12', '');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_Bare30Rows_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows OpenNone Log";
        List: TestPage "LT ListRows OpenNone Bare";
    begin
        Seed(30);
        List.OpenView();
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('hit-last', Format(List.GoToKey(30)));
        ObserveDump(Observer, 'to-last');
        List.Close();
        Observer.Expect('current', '1');
        Observer.Expect('open-total', '0');
        Observer.Expect('open-G-count', '0');
        Observer.Expect('open-C-count', '0');
        Observer.Expect('open-G-runs', '');
        Observer.Expect('open-C-runs', '');
        Observer.Expect('open-first12', '');
        Observer.Expect('open-last12', '');
        Observer.Expect('hit-last', 'Yes');
        Observer.Expect('to-last-total', '0');
        Observer.Expect('to-last-G-count', '0');
        Observer.Expect('to-last-C-count', '0');
        Observer.Expect('to-last-G-runs', '');
        Observer.Expect('to-last-C-runs', '');
        Observer.Expect('to-last-first12', '');
        Observer.Expect('to-last-last12', '');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_FindNext5Rows_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows OpenNone Log";
        List: TestPage "LT ListRows OpenNone Find";
    begin
        Seed(5);
        List.OpenView();
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDumpFN(Observer, 'open');
        Log.Wipe();
        Observer.Observe('hit-last', Format(List.GoToKey(5)));
        ObserveDumpFN(Observer, 'to-last');
        List.Close();
        Observer.Expect('current', '1');
        Observer.Expect('open-total', '7');
        Observer.Expect('open-F-count', '1');
        Observer.Expect('open-N-count', '6');
        Observer.Expect('open-F-runs', '0');
        Observer.Expect('open-N-runs', '2-5,5,1');
        Observer.Expect('open-first12', 'F0;N2;N3;N4;N5;N5;N1');
        Observer.Expect('open-last12', 'F0;N2;N3;N4;N5;N5;N1');
        Observer.Expect('hit-last', 'Yes');
        Observer.Expect('to-last-total', '0');
        Observer.Expect('to-last-F-count', '0');
        Observer.Expect('to-last-N-count', '0');
        Observer.Expect('to-last-F-runs', '');
        Observer.Expect('to-last-N-runs', '');
        Observer.Expect('to-last-first12', '');
        Observer.Expect('to-last-last12', '');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_FindNext30Rows_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows OpenNone Log";
        List: TestPage "LT ListRows OpenNone Find";
    begin
        Seed(30);
        List.OpenView();
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDumpFN(Observer, 'open');
        Log.Wipe();
        Observer.Observe('hit-last', Format(List.GoToKey(30)));
        ObserveDumpFN(Observer, 'to-last');
        List.Close();
        Observer.Expect('current', '1');
        Observer.Expect('open-total', '21');
        Observer.Expect('open-F-count', '1');
        Observer.Expect('open-N-count', '20');
        Observer.Expect('open-F-runs', '0');
        Observer.Expect('open-N-runs', '2-20,1');
        Observer.Expect('open-first12', 'F0;N2;N3;N4;N5;N6;N7;N8;N9;N10;N11;N12');
        Observer.Expect('open-last12', 'N10;N11;N12;N13;N14;N15;N16;N17;N18;N19;N20;N1');
        Observer.Expect('hit-last', 'Yes');
        Observer.Expect('to-last-total', '11');
        Observer.Expect('to-last-F-count', '0');
        Observer.Expect('to-last-N-count', '11');
        Observer.Expect('to-last-F-runs', '');
        Observer.Expect('to-last-N-runs', '21-30,30');
        Observer.Expect('to-last-first12', 'N21;N22;N23;N24;N25;N26;N27;N28;N29;N30;N30');
        Observer.Expect('to-last-last12', 'N21;N22;N23;N24;N25;N26;N27;N28;N29;N30;N30');
        Observer.Verify();
    end;
}
