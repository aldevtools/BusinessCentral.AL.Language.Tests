// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table, log, two list pages
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GoToKey onto the first row while already standing on it (and onto the current row when it is not the first): reads and trigger runs, with OnAfterGetRecord and OnAfterGetCurrRecord, and with only OnAfterGetCurrRecord
// BC versions: 29 (27 and 28 by CI)

table 72751 "LT ListRows GoToFirst Row"
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
codeunit 72752 "LT ListRows GoToFirst Log"
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

page 72753 "LT ListRows GoToFirst Both"
{
    PageType = List;
    SourceTable = "LT ListRows GoToFirst Row";
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
        Log: Codeunit "LT ListRows GoToFirst Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('G', Rec.Id);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C', Rec.Id);
    end;
}

page 72754 "LT ListRows GoToFirst Curr"
{
    PageType = List;
    SourceTable = "LT ListRows GoToFirst Row";
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
        Log: Codeunit "LT ListRows GoToFirst Log";

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C', Rec.Id);
    end;
}

codeunit 72755 "LT ListRows GoToFirst"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Row: Record "LT ListRows GoToFirst Row";
        Log: Codeunit "LT ListRows GoToFirst Log";
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
        Log: Codeunit "LT ListRows GoToFirst Log";
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
        Log: Codeunit "LT ListRows GoToFirst Log";
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
    procedure GoToKeyFirstWhileOnIt_Both5Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows GoToFirst Log";
        List: TestPage "LT ListRows GoToFirst Both";
    begin
        Seed(5);
        List.OpenView();
        Observer.Observe('current-open', List.IdCtl.Value());
        Log.Wipe();
        Observer.Observe('hit-first', Format(List.GoToKey(1)));
        Observer.Observe('current-first', List.IdCtl.Value());
        ObserveDump(Observer, 'first-on-first');
        Log.Wipe();
        Observer.Observe('hit-first-again', Format(List.GoToKey(1)));
        ObserveDump(Observer, 'first-again');
        List.Close();
        Observer.Expect('current-open', '1');
        Observer.Expect('hit-first', 'Yes');
        Observer.Expect('current-first', '1');
        Observer.Expect('first-on-first-total', '0');
        Observer.Expect('first-on-first-G-count', '0');
        Observer.Expect('first-on-first-C-count', '0');
        Observer.Expect('first-on-first-G-runs', '');
        Observer.Expect('first-on-first-C-runs', '');
        Observer.Expect('first-on-first-first12', '');
        Observer.Expect('first-on-first-last12', '');
        Observer.Expect('hit-first-again', 'Yes');
        Observer.Expect('first-again-total', '0');
        Observer.Expect('first-again-G-count', '0');
        Observer.Expect('first-again-C-count', '0');
        Observer.Expect('first-again-G-runs', '');
        Observer.Expect('first-again-C-runs', '');
        Observer.Expect('first-again-first12', '');
        Observer.Expect('first-again-last12', '');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyFirstWhileOnIt_Both30Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows GoToFirst Log";
        List: TestPage "LT ListRows GoToFirst Both";
    begin
        Seed(30);
        List.OpenView();
        Observer.Observe('current-open', List.IdCtl.Value());
        Log.Wipe();
        Observer.Observe('hit-first', Format(List.GoToKey(1)));
        Observer.Observe('current-first', List.IdCtl.Value());
        ObserveDump(Observer, 'first-on-first');
        Log.Wipe();
        Observer.Observe('hit-first-again', Format(List.GoToKey(1)));
        ObserveDump(Observer, 'first-again');
        List.Close();
        Observer.Expect('current-open', '1');
        Observer.Expect('hit-first', 'Yes');
        Observer.Expect('current-first', '1');
        Observer.Expect('first-on-first-total', '0');
        Observer.Expect('first-on-first-G-count', '0');
        Observer.Expect('first-on-first-C-count', '0');
        Observer.Expect('first-on-first-G-runs', '');
        Observer.Expect('first-on-first-C-runs', '');
        Observer.Expect('first-on-first-first12', '');
        Observer.Expect('first-on-first-last12', '');
        Observer.Expect('hit-first-again', 'Yes');
        Observer.Expect('first-again-total', '0');
        Observer.Expect('first-again-G-count', '0');
        Observer.Expect('first-again-C-count', '0');
        Observer.Expect('first-again-G-runs', '');
        Observer.Expect('first-again-C-runs', '');
        Observer.Expect('first-again-first12', '');
        Observer.Expect('first-again-last12', '');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyCurrentRow_Both30Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows GoToFirst Log";
        List: TestPage "LT ListRows GoToFirst Both";
    begin
        Seed(30);
        List.OpenView();
        Observer.Observe('hit-3', Format(List.GoToKey(3)));
        Log.Wipe();
        Observer.Observe('hit-3-again', Format(List.GoToKey(3)));
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDump(Observer, 'same-row');
        Log.Wipe();
        Observer.Observe('hit-first-from-3', Format(List.GoToKey(1)));
        Observer.Observe('current-after-first', List.IdCtl.Value());
        ObserveDump(Observer, 'back-to-first');
        List.Close();
        Observer.Expect('hit-3', 'Yes');
        Observer.Expect('hit-3-again', 'Yes');
        Observer.Expect('current', '3');
        Observer.Expect('same-row-total', '9');
        Observer.Expect('same-row-G-count', '6');
        Observer.Expect('same-row-C-count', '3');
        Observer.Expect('same-row-G-runs', '1,1-2,2-3,3');
        Observer.Expect('same-row-C-runs', '1-3');
        Observer.Expect('same-row-first12', 'G1;G1;C1;G2;G2;C2;G3;G3;C3');
        Observer.Expect('same-row-last12', 'G1;G1;C1;G2;G2;C2;G3;G3;C3');
        Observer.Expect('hit-first-from-3', 'Yes');
        Observer.Expect('current-after-first', '1');
        Observer.Expect('back-to-first-total', '3');
        Observer.Expect('back-to-first-G-count', '2');
        Observer.Expect('back-to-first-C-count', '1');
        Observer.Expect('back-to-first-G-runs', '1,1');
        Observer.Expect('back-to-first-C-runs', '1');
        Observer.Expect('back-to-first-first12', 'G1;G1;C1');
        Observer.Expect('back-to-first-last12', 'G1;G1;C1');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyFirstWhileOnIt_OnlyCurr5Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows GoToFirst Log";
        List: TestPage "LT ListRows GoToFirst Curr";
    begin
        Seed(5);
        List.OpenView();
        Observer.Observe('current-open', List.IdCtl.Value());
        Log.Wipe();
        Observer.Observe('hit-first', Format(List.GoToKey(1)));
        Observer.Observe('current-first', List.IdCtl.Value());
        ObserveDump(Observer, 'first-on-first');
        Log.Wipe();
        Observer.Observe('hit-first-again', Format(List.GoToKey(1)));
        ObserveDump(Observer, 'first-again');
        List.Close();
        Observer.Expect('current-open', '1');
        Observer.Expect('hit-first', 'Yes');
        Observer.Expect('current-first', '1');
        Observer.Expect('first-on-first-total', '0');
        Observer.Expect('first-on-first-G-count', '0');
        Observer.Expect('first-on-first-C-count', '0');
        Observer.Expect('first-on-first-G-runs', '');
        Observer.Expect('first-on-first-C-runs', '');
        Observer.Expect('first-on-first-first12', '');
        Observer.Expect('first-on-first-last12', '');
        Observer.Expect('hit-first-again', 'Yes');
        Observer.Expect('first-again-total', '0');
        Observer.Expect('first-again-G-count', '0');
        Observer.Expect('first-again-C-count', '0');
        Observer.Expect('first-again-G-runs', '');
        Observer.Expect('first-again-C-runs', '');
        Observer.Expect('first-again-first12', '');
        Observer.Expect('first-again-last12', '');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyFirstWhileOnIt_OnlyCurr30Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows GoToFirst Log";
        List: TestPage "LT ListRows GoToFirst Curr";
    begin
        Seed(30);
        List.OpenView();
        Observer.Observe('current-open', List.IdCtl.Value());
        Log.Wipe();
        Observer.Observe('hit-first', Format(List.GoToKey(1)));
        Observer.Observe('current-first', List.IdCtl.Value());
        ObserveDump(Observer, 'first-on-first');
        Log.Wipe();
        Observer.Observe('hit-first-again', Format(List.GoToKey(1)));
        ObserveDump(Observer, 'first-again');
        List.Close();
        Observer.Expect('current-open', '1');
        Observer.Expect('hit-first', 'Yes');
        Observer.Expect('current-first', '1');
        Observer.Expect('first-on-first-total', '0');
        Observer.Expect('first-on-first-G-count', '0');
        Observer.Expect('first-on-first-C-count', '0');
        Observer.Expect('first-on-first-G-runs', '');
        Observer.Expect('first-on-first-C-runs', '');
        Observer.Expect('first-on-first-first12', '');
        Observer.Expect('first-on-first-last12', '');
        Observer.Expect('hit-first-again', 'Yes');
        Observer.Expect('first-again-total', '0');
        Observer.Expect('first-again-G-count', '0');
        Observer.Expect('first-again-C-count', '0');
        Observer.Expect('first-again-G-runs', '');
        Observer.Expect('first-again-C-runs', '');
        Observer.Expect('first-again-first12', '');
        Observer.Expect('first-again-last12', '');
        Observer.Verify();
    end;

    [Test]
    procedure GoToKeyCurrentRow_OnlyCurr30Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows GoToFirst Log";
        List: TestPage "LT ListRows GoToFirst Curr";
    begin
        Seed(30);
        List.OpenView();
        Observer.Observe('hit-3', Format(List.GoToKey(3)));
        Log.Wipe();
        Observer.Observe('hit-3-again', Format(List.GoToKey(3)));
        Observer.Observe('current', List.IdCtl.Value());
        ObserveDump(Observer, 'same-row');
        Log.Wipe();
        Observer.Observe('hit-first-from-3', Format(List.GoToKey(1)));
        Observer.Observe('current-after-first', List.IdCtl.Value());
        ObserveDump(Observer, 'back-to-first');
        List.Close();
        Observer.Expect('hit-3', 'Yes');
        Observer.Expect('hit-3-again', 'Yes');
        Observer.Expect('current', '3');
        Observer.Expect('same-row-total', '3');
        Observer.Expect('same-row-G-count', '0');
        Observer.Expect('same-row-C-count', '3');
        Observer.Expect('same-row-G-runs', '');
        Observer.Expect('same-row-C-runs', '1-3');
        Observer.Expect('same-row-first12', 'C1;C2;C3');
        Observer.Expect('same-row-last12', 'C1;C2;C3');
        Observer.Expect('hit-first-from-3', 'Yes');
        Observer.Expect('current-after-first', '1');
        Observer.Expect('back-to-first-total', '1');
        Observer.Expect('back-to-first-G-count', '0');
        Observer.Expect('back-to-first-C-count', '1');
        Observer.Expect('back-to-first-G-runs', '');
        Observer.Expect('back-to-first-C-runs', '1');
        Observer.Expect('back-to-first-first12', 'C1');
        Observer.Expect('back-to-first-last12', 'C1');
        Observer.Verify();
    end;
}
