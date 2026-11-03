// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table, log, three list pages
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: reads at open of a 5-row and a 30-row list by trigger: only OnAfterGetRecord, only OnAfterGetCurrRecord, both (counts, run-length forms, first and last 12 entries, current row after open)
// BC versions: 29 (27 and 28 by CI)

table 72732 "LT ListRows OpenAG Row"
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
codeunit 72733 "LT ListRows OpenAG Log"
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

page 72734 "LT ListRows OpenAG Rec"
{
    PageType = List;
    SourceTable = "LT ListRows OpenAG Row";
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
        Log: Codeunit "LT ListRows OpenAG Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('G', Rec.Id);
    end;
}

page 72735 "LT ListRows OpenAG Curr"
{
    PageType = List;
    SourceTable = "LT ListRows OpenAG Row";
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
        Log: Codeunit "LT ListRows OpenAG Log";

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C', Rec.Id);
    end;
}

page 72736 "LT ListRows OpenAG Both"
{
    PageType = List;
    SourceTable = "LT ListRows OpenAG Row";
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
        Log: Codeunit "LT ListRows OpenAG Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('G', Rec.Id);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C', Rec.Id);
    end;
}

codeunit 72737 "LT ListRows OpenAG"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Row: Record "LT ListRows OpenAG Row";
        Log: Codeunit "LT ListRows OpenAG Log";
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
        Log: Codeunit "LT ListRows OpenAG Log";
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
        Log: Codeunit "LT ListRows OpenAG Log";
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
    procedure OpenView_OnlyRec5Rows_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows OpenAG Log";
        List: TestPage "LT ListRows OpenAG Rec";
    begin
        Seed(5);
        List.OpenView();
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('current-after-next', List.IdCtl.Value());
        ObserveDump(Observer, 'after-next');
        List.Close();
        Observer.Expect('current', '1');
        Observer.Expect('open-total', '6');
        Observer.Expect('open-G-count', '6');
        Observer.Expect('open-C-count', '0');
        Observer.Expect('open-G-runs', '1-5,1');
        Observer.Expect('open-C-runs', '');
        Observer.Expect('open-first12', 'G1;G2;G3;G4;G5;G1');
        Observer.Expect('open-last12', 'G1;G2;G3;G4;G5;G1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('current-after-next', '2');
        Observer.Expect('after-next-total', '0');
        Observer.Expect('after-next-G-count', '0');
        Observer.Expect('after-next-C-count', '0');
        Observer.Expect('after-next-G-runs', '');
        Observer.Expect('after-next-C-runs', '');
        Observer.Expect('after-next-first12', '');
        Observer.Expect('after-next-last12', '');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_OnlyRec30Rows_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows OpenAG Log";
        List: TestPage "LT ListRows OpenAG Rec";
    begin
        Seed(30);
        List.OpenView();
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('current-after-next', List.IdCtl.Value());
        ObserveDump(Observer, 'after-next');
        List.Close();
        Observer.Expect('current', '1');
        Observer.Expect('open-total', '21');
        Observer.Expect('open-G-count', '21');
        Observer.Expect('open-C-count', '0');
        Observer.Expect('open-G-runs', '1-20,1');
        Observer.Expect('open-C-runs', '');
        Observer.Expect('open-first12', 'G1;G2;G3;G4;G5;G6;G7;G8;G9;G10;G11;G12');
        Observer.Expect('open-last12', 'G10;G11;G12;G13;G14;G15;G16;G17;G18;G19;G20;G1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('current-after-next', '2');
        Observer.Expect('after-next-total', '0');
        Observer.Expect('after-next-G-count', '0');
        Observer.Expect('after-next-C-count', '0');
        Observer.Expect('after-next-G-runs', '');
        Observer.Expect('after-next-C-runs', '');
        Observer.Expect('after-next-first12', '');
        Observer.Expect('after-next-last12', '');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_OnlyCurr5Rows_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows OpenAG Log";
        List: TestPage "LT ListRows OpenAG Curr";
    begin
        Seed(5);
        List.OpenView();
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('current-after-next', List.IdCtl.Value());
        ObserveDump(Observer, 'after-next');
        List.Close();
        Observer.Expect('current', '1');
        Observer.Expect('open-total', '1');
        Observer.Expect('open-G-count', '0');
        Observer.Expect('open-C-count', '1');
        Observer.Expect('open-G-runs', '');
        Observer.Expect('open-C-runs', '1');
        Observer.Expect('open-first12', 'C1');
        Observer.Expect('open-last12', 'C1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('current-after-next', '2');
        Observer.Expect('after-next-total', '1');
        Observer.Expect('after-next-G-count', '0');
        Observer.Expect('after-next-C-count', '1');
        Observer.Expect('after-next-G-runs', '');
        Observer.Expect('after-next-C-runs', '2');
        Observer.Expect('after-next-first12', 'C2');
        Observer.Expect('after-next-last12', 'C2');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_OnlyCurr30Rows_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows OpenAG Log";
        List: TestPage "LT ListRows OpenAG Curr";
    begin
        Seed(30);
        List.OpenView();
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('current-after-next', List.IdCtl.Value());
        ObserveDump(Observer, 'after-next');
        List.Close();
        Observer.Expect('current', '1');
        Observer.Expect('open-total', '1');
        Observer.Expect('open-G-count', '0');
        Observer.Expect('open-C-count', '1');
        Observer.Expect('open-G-runs', '');
        Observer.Expect('open-C-runs', '1');
        Observer.Expect('open-first12', 'C1');
        Observer.Expect('open-last12', 'C1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('current-after-next', '2');
        Observer.Expect('after-next-total', '1');
        Observer.Expect('after-next-G-count', '0');
        Observer.Expect('after-next-C-count', '1');
        Observer.Expect('after-next-G-runs', '');
        Observer.Expect('after-next-C-runs', '2');
        Observer.Expect('after-next-first12', 'C2');
        Observer.Expect('after-next-last12', 'C2');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_Both5Rows_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows OpenAG Log";
        List: TestPage "LT ListRows OpenAG Both";
    begin
        Seed(5);
        List.OpenView();
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('current-after-next', List.IdCtl.Value());
        ObserveDump(Observer, 'after-next');
        List.Close();
        Observer.Expect('current', '1');
        Observer.Expect('open-total', '8');
        Observer.Expect('open-G-count', '7');
        Observer.Expect('open-C-count', '1');
        Observer.Expect('open-G-runs', '1-5,1,1');
        Observer.Expect('open-C-runs', '1');
        Observer.Expect('open-first12', 'G1;G2;G3;G4;G5;G1;G1;C1');
        Observer.Expect('open-last12', 'G1;G2;G3;G4;G5;G1;G1;C1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('current-after-next', '2');
        Observer.Expect('after-next-total', '3');
        Observer.Expect('after-next-G-count', '2');
        Observer.Expect('after-next-C-count', '1');
        Observer.Expect('after-next-G-runs', '2,2');
        Observer.Expect('after-next-C-runs', '2');
        Observer.Expect('after-next-first12', 'G2;G2;C2');
        Observer.Expect('after-next-last12', 'G2;G2;C2');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_Both30Rows_ReadsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows OpenAG Log";
        List: TestPage "LT ListRows OpenAG Both";
    begin
        Seed(30);
        List.OpenView();
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDump(Observer, 'open');
        Log.Wipe();
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('current-after-next', List.IdCtl.Value());
        ObserveDump(Observer, 'after-next');
        List.Close();
        Observer.Expect('current', '1');
        Observer.Expect('open-total', '23');
        Observer.Expect('open-G-count', '22');
        Observer.Expect('open-C-count', '1');
        Observer.Expect('open-G-runs', '1-20,1,1');
        Observer.Expect('open-C-runs', '1');
        Observer.Expect('open-first12', 'G1;G2;G3;G4;G5;G6;G7;G8;G9;G10;G11;G12');
        Observer.Expect('open-last12', 'G12;G13;G14;G15;G16;G17;G18;G19;G20;G1;G1;C1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('current-after-next', '2');
        Observer.Expect('after-next-total', '3');
        Observer.Expect('after-next-G-count', '2');
        Observer.Expect('after-next-C-count', '1');
        Observer.Expect('after-next-G-runs', '2,2');
        Observer.Expect('after-next-C-runs', '2');
        Observer.Expect('after-next-first12', 'G2;G2;C2');
        Observer.Expect('after-next-last12', 'G2;G2;C2');
        Observer.Verify();
    end;
}
