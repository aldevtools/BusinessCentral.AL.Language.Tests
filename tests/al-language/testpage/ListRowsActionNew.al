// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table, log, list page
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a list with a new row (TestPage OpenEdit + New, key and name set, row not left) then an action (with and without CurrPage.Update(false)): reads logged, row stored or not
// BC versions: 29 (27 and 28 by CI)

table 72747 "LT ListRows ActionNew Row"
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
codeunit 72748 "LT ListRows ActionNew Log"
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

page 72749 "LT ListRows ActionNew List"
{
    PageType = List;
    SourceTable = "LT ListRows ActionNew Row";
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

    actions
    {
        area(Processing)
        {
            action(Ping)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('A', Rec.Id);
                end;
            }
            action(PingUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('A', Rec.Id);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT ListRows ActionNew Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('G', Rec.Id);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C', Rec.Id);
    end;
}

codeunit 72750 "LT ListRows ActionNew"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Rows: Integer)
    var
        Row: Record "LT ListRows ActionNew Row";
        Log: Codeunit "LT ListRows ActionNew Log";
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
        Log: Codeunit "LT ListRows ActionNew Log";
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
        Log: Codeunit "LT ListRows ActionNew Log";
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
    procedure NewRowThenAction_Ping5Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows ActionNew Log";
        Row: Record "LT ListRows ActionNew Row";
        List: TestPage "LT ListRows ActionNew List";
    begin
        Seed(5);
        List.OpenEdit();
        Log.Wipe();
        List.New();
        Observer.Observe('after-new-total', Format(Log.Total()));
        Log.Wipe();
        List.IdCtl.SetValue(100);
        List.NameCtl.SetValue('New row');
        Observer.Observe('id-after-setvalue', List.IdCtl.Value());
        ObserveDump(Observer, 'after-edit');
        Observer.Observe('stored-before-action', Format(Row.Get(100)));
        Log.Wipe();
        List.Ping.Invoke();
        Observer.Observe('current-after-action', List.IdCtl.Value());
        Observer.Observe('A-count', Format(Log.CountOf('A')));
        ObserveDump(Observer, 'after-action');
        Observer.Observe('stored-after-action', Format(Row.Get(100)));
        Observer.Observe('row-count-after-action', Format(Row.Count()));
        List.Close();
        Observer.Observe('stored-after-close', Format(Row.Get(100)));
        Observer.Expect('after-new-total', '1');
        Observer.Expect('id-after-setvalue', '100');
        Observer.Expect('after-edit-total', '0');
        Observer.Expect('after-edit-G-count', '0');
        Observer.Expect('after-edit-C-count', '0');
        Observer.Expect('after-edit-G-runs', '');
        Observer.Expect('after-edit-C-runs', '');
        Observer.Expect('after-edit-first12', '');
        Observer.Expect('after-edit-last12', '');
        Observer.Expect('stored-before-action', 'Yes');
        Observer.Expect('current-after-action', '100');
        Observer.Expect('A-count', '1');
        Observer.Expect('after-action-total', '12');
        Observer.Expect('after-action-G-count', '10');
        Observer.Expect('after-action-C-count', '1');
        Observer.Expect('after-action-G-runs', '100,100,100,5,4,3,2,1,100,100');
        Observer.Expect('after-action-C-runs', '100');
        Observer.Expect('after-action-first12', 'G100;A100;G100;G100;G5;G4;G3;G2;G1;G100;G100;C100');
        Observer.Expect('after-action-last12', 'G100;A100;G100;G100;G5;G4;G3;G2;G1;G100;G100;C100');
        Observer.Expect('stored-after-action', 'Yes');
        Observer.Expect('row-count-after-action', '6');
        Observer.Expect('stored-after-close', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NewRowThenAction_PingUpdate5Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows ActionNew Log";
        Row: Record "LT ListRows ActionNew Row";
        List: TestPage "LT ListRows ActionNew List";
    begin
        Seed(5);
        List.OpenEdit();
        Log.Wipe();
        List.New();
        Observer.Observe('after-new-total', Format(Log.Total()));
        Log.Wipe();
        List.IdCtl.SetValue(100);
        List.NameCtl.SetValue('New row');
        Observer.Observe('id-after-setvalue', List.IdCtl.Value());
        ObserveDump(Observer, 'after-edit');
        Observer.Observe('stored-before-action', Format(Row.Get(100)));
        Log.Wipe();
        List.PingUpdate.Invoke();
        Observer.Observe('current-after-action', List.IdCtl.Value());
        Observer.Observe('A-count', Format(Log.CountOf('A')));
        ObserveDump(Observer, 'after-action');
        Observer.Observe('stored-after-action', Format(Row.Get(100)));
        Observer.Observe('row-count-after-action', Format(Row.Count()));
        List.Close();
        Observer.Observe('stored-after-close', Format(Row.Get(100)));
        Observer.Expect('after-new-total', '1');
        Observer.Expect('id-after-setvalue', '100');
        Observer.Expect('after-edit-total', '0');
        Observer.Expect('after-edit-G-count', '0');
        Observer.Expect('after-edit-C-count', '0');
        Observer.Expect('after-edit-G-runs', '');
        Observer.Expect('after-edit-C-runs', '');
        Observer.Expect('after-edit-first12', '');
        Observer.Expect('after-edit-last12', '');
        Observer.Expect('stored-before-action', 'Yes');
        Observer.Expect('current-after-action', '100');
        Observer.Expect('A-count', '1');
        Observer.Expect('after-action-total', '12');
        Observer.Expect('after-action-G-count', '10');
        Observer.Expect('after-action-C-count', '1');
        Observer.Expect('after-action-G-runs', '100,100,100,5,4,3,2,1,100,100');
        Observer.Expect('after-action-C-runs', '100');
        Observer.Expect('after-action-first12', 'G100;A100;G100;G100;G5;G4;G3;G2;G1;G100;G100;C100');
        Observer.Expect('after-action-last12', 'G100;A100;G100;G100;G5;G4;G3;G2;G1;G100;G100;C100');
        Observer.Expect('stored-after-action', 'Yes');
        Observer.Expect('row-count-after-action', '6');
        Observer.Expect('stored-after-close', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NewRowThenAction_Ping30Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows ActionNew Log";
        Row: Record "LT ListRows ActionNew Row";
        List: TestPage "LT ListRows ActionNew List";
    begin
        Seed(30);
        List.OpenEdit();
        Log.Wipe();
        List.New();
        Observer.Observe('after-new-total', Format(Log.Total()));
        Log.Wipe();
        List.IdCtl.SetValue(100);
        List.NameCtl.SetValue('New row');
        Observer.Observe('id-after-setvalue', List.IdCtl.Value());
        ObserveDump(Observer, 'after-edit');
        Observer.Observe('stored-before-action', Format(Row.Get(100)));
        Log.Wipe();
        List.Ping.Invoke();
        Observer.Observe('current-after-action', List.IdCtl.Value());
        Observer.Observe('A-count', Format(Log.CountOf('A')));
        ObserveDump(Observer, 'after-action');
        Observer.Observe('stored-after-action', Format(Row.Get(100)));
        Observer.Observe('row-count-after-action', Format(Row.Count()));
        List.Close();
        Observer.Observe('stored-after-close', Format(Row.Get(100)));
        Observer.Expect('after-new-total', '12');
        Observer.Expect('id-after-setvalue', '100');
        Observer.Expect('after-edit-total', '0');
        Observer.Expect('after-edit-G-count', '0');
        Observer.Expect('after-edit-C-count', '0');
        Observer.Expect('after-edit-G-runs', '');
        Observer.Expect('after-edit-C-runs', '');
        Observer.Expect('after-edit-first12', '');
        Observer.Expect('after-edit-last12', '');
        Observer.Expect('stored-before-action', 'Yes');
        Observer.Expect('current-after-action', '100');
        Observer.Expect('A-count', '1');
        Observer.Expect('after-action-total', '39');
        Observer.Expect('after-action-G-count', '37');
        Observer.Expect('after-action-C-count', '1');
        Observer.Expect('after-action-G-runs', '100,100,100,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,100,11,10,9,8,7,6,5,4,3,2,1,100,100');
        Observer.Expect('after-action-C-runs', '100');
        Observer.Expect('after-action-first12', 'G100;A100;G100;G100;G30;G29;G28;G27;G26;G25;G24;G23');
        Observer.Expect('after-action-last12', 'G9;G8;G7;G6;G5;G4;G3;G2;G1;G100;G100;C100');
        Observer.Expect('stored-after-action', 'Yes');
        Observer.Expect('row-count-after-action', '31');
        Observer.Expect('stored-after-close', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NewRowThenAction_PingUpdate30Rows_ReadsLogged()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT ListRows ActionNew Log";
        Row: Record "LT ListRows ActionNew Row";
        List: TestPage "LT ListRows ActionNew List";
    begin
        Seed(30);
        List.OpenEdit();
        Log.Wipe();
        List.New();
        Observer.Observe('after-new-total', Format(Log.Total()));
        Log.Wipe();
        List.IdCtl.SetValue(100);
        List.NameCtl.SetValue('New row');
        Observer.Observe('id-after-setvalue', List.IdCtl.Value());
        ObserveDump(Observer, 'after-edit');
        Observer.Observe('stored-before-action', Format(Row.Get(100)));
        Log.Wipe();
        List.PingUpdate.Invoke();
        Observer.Observe('current-after-action', List.IdCtl.Value());
        Observer.Observe('A-count', Format(Log.CountOf('A')));
        ObserveDump(Observer, 'after-action');
        Observer.Observe('stored-after-action', Format(Row.Get(100)));
        Observer.Observe('row-count-after-action', Format(Row.Count()));
        List.Close();
        Observer.Observe('stored-after-close', Format(Row.Get(100)));
        Observer.Expect('after-new-total', '12');
        Observer.Expect('id-after-setvalue', '100');
        Observer.Expect('after-edit-total', '0');
        Observer.Expect('after-edit-G-count', '0');
        Observer.Expect('after-edit-C-count', '0');
        Observer.Expect('after-edit-G-runs', '');
        Observer.Expect('after-edit-C-runs', '');
        Observer.Expect('after-edit-first12', '');
        Observer.Expect('after-edit-last12', '');
        Observer.Expect('stored-before-action', 'Yes');
        Observer.Expect('current-after-action', '100');
        Observer.Expect('A-count', '1');
        Observer.Expect('after-action-total', '39');
        Observer.Expect('after-action-G-count', '37');
        Observer.Expect('after-action-C-count', '1');
        Observer.Expect('after-action-G-runs', '100,100,100,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,100,11,10,9,8,7,6,5,4,3,2,1,100,100');
        Observer.Expect('after-action-C-runs', '100');
        Observer.Expect('after-action-first12', 'G100;A100;G100;G100;G30;G29;G28;G27;G26;G25;G24;G23');
        Observer.Expect('after-action-last12', 'G9;G8;G7;G6;G5;G4;G3;G2;G1;G100;G100;C100');
        Observer.Expect('stored-after-action', 'Yes');
        Observer.Expect('row-count-after-action', '31');
        Observer.Expect('stored-after-close', 'Yes');
        Observer.Verify();
    end;
}
