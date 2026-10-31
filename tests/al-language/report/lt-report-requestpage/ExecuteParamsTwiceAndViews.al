// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-execute-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 91367, report 91368, SingleInstance log 91369 (used only by test codeunit 91370)
// Probe: observe probe (writer Y7, 2026-10-30, asked by an al-runtime-rs runtime agent); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: (1) a second Execute on one report variable when the first or the second call carries request page parameters (Options XML): the second call's error
//   text and code, and the log of both runs; after Clear the variable runs again. (2) Execute with <DataItems><DataItem name="Row">VIEW</DataItem> in the
//   parameters: the filters and sort order the data item sees in OnPreDataItem and the rows it reads, together with an Options field; the next Execute without
//   a view (static and on a new variable) sees no filter; a view that names an unknown data item; a view combined with SetTableView on the same variable.
//   handlers/TestReportRuntimeContracts.al:459 pins Execute('') twice ('The object has been run. Use the function CLEAR(Report).').
// BC versions: 27, 28, 29

table 91367 "LT Y7 Exec Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp, Id) { }
    }
}

report 91368 "LT Y7 Exec Params"
{
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(Row; "LT Y7 Exec Row")
        {
            RequestFilterFields = Grp, Id;

            trigger OnPreDataItem()
            begin
                L.Add('pre note=' + NoteVal + ' filters=[' + Row.GetFilters() + '] key=[' + Row.CurrentKey() + '] asc=' + Format(Row.Ascending()));
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('get ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(NoteVal; NoteVal) { ApplicationArea = All; }
            }
        }
    }

    var
        L: Codeunit "LT Y7 Exec Log";
        NoteVal: Text[30];
}

codeunit 91369 "LT Y7 Exec Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 91370 "LT Y7 Exec Params Twice Views"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT Y7 Exec Log";

    local procedure Seed()
    var
        Row: Record "LT Y7 Exec Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 4 do begin
            Row.Id := I;
            Row.Grp := 1 + ((I - 1) div 2);
            Row.Insert();
        end;
        L.Take();
    end;

    local procedure Params(Options: Text; DataItems: Text): Text
    var
        Txt: Text;
    begin
        Txt := '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT Y7 Exec Params" id="91368"><Options>' + Options + '</Options>';
        if DataItems <> '' then
            Txt += '<DataItems>' + DataItems + '</DataItems>';
        exit(Txt + '</ReportParameters>');
    end;

    local procedure Note(Value: Text): Text
    begin
        exit('<Field name="NoteVal">' + Value + '</Field>');
    end;

    [TryFunction]
    local procedure TryExecute(var R: Report "LT Y7 Exec Params"; P: Text)
    begin
        R.Execute(P);
    end;

    local procedure Exec(var Observer: Codeunit "Probe Observer"; Name: Text; var R: Report "LT Y7 Exec Params"; P: Text)
    begin
        ClearLastError();
        if TryExecute(R, P) then
            Observer.Observe(Name, 'ok|' + L.Take())
        else begin
            Observer.Observe(Name, 'E[' + CopyStr(GetLastErrorText(), 1, 160) + '|' + GetLastErrorCode() + ']|' + L.Take());
            ClearLastError();
        end;
    end;

    [Test]
    procedure Y7_Execute_ParamsThenParams_SameVariable()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT Y7 Exec Params";
    begin
        Seed();
        Exec(Observer, 'first', R, Params(Note('one'), ''));
        Exec(Observer, 'second', R, Params(Note('two'), ''));
        Clear(R);
        Exec(Observer, 'after Clear', R, Params(Note('three'), ''));
        Observer.Expect('first', 'ok|pre note=one filters=[] key=[Id] asc=Yes;get 1;get 2;get 3;get 4;');
        Observer.Expect('second', 'E[The object has been run. Use the function CLEAR(Report).|ObjectHasAlreadyBeenRun]|');
        Observer.Expect('after Clear', 'ok|pre note=three filters=[] key=[Id] asc=Yes;get 1;get 2;get 3;get 4;');
        Observer.Verify();
    end;

    [Test]
    procedure Y7_Execute_EmptyThenParams_SameVariable()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT Y7 Exec Params";
    begin
        Seed();
        Exec(Observer, 'first', R, '');
        Exec(Observer, 'second', R, Params(Note('two'), ''));
        Observer.Expect('first', 'ok|pre note= filters=[] key=[Id] asc=Yes;get 1;get 2;get 3;get 4;');
        Observer.Expect('second', 'E[The object has been run. Use the function CLEAR(Report).|ObjectHasAlreadyBeenRun]|');
        Observer.Verify();
    end;

    [Test]
    procedure Y7_Execute_ParamsThenEmpty_SameVariable()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT Y7 Exec Params";
    begin
        Seed();
        Exec(Observer, 'first', R, Params(Note('one'), ''));
        Exec(Observer, 'second', R, '');
        Observer.Expect('first', 'ok|pre note=one filters=[] key=[Id] asc=Yes;get 1;get 2;get 3;get 4;');
        Observer.Expect('second', 'E[The object has been run. Use the function CLEAR(Report).|ObjectHasAlreadyBeenRun]|');
        Observer.Verify();
    end;

    [Test]
    procedure Y7_Execute_DataItemView_ThenNoView()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT Y7 Exec Params";
        R2: Report "LT Y7 Exec Params";
    begin
        Seed();
        Exec(Observer, 'view grp 2', R, Params(Note('v'), '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field2=1(2))</DataItem>'));
        Report.Execute(Report::"LT Y7 Exec Params", '');
        Observer.Observe('static next, no view', L.Take());
        Exec(Observer, 'new variable, no view', R2, Params(Note('n'), ''));
        Observer.Expect('view grp 2', 'ok|pre note=v filters=[Grp: 2] key=[Id] asc=Yes;get 3;get 4;');
        Observer.Expect('static next, no view', 'pre note= filters=[] key=[Id] asc=Yes;get 1;get 2;get 3;get 4;');
        Observer.Expect('new variable, no view', 'ok|pre note=n filters=[] key=[Id] asc=Yes;get 1;get 2;get 3;get 4;');
        Observer.Verify();
    end;

    [Test]
    procedure Y7_Execute_DataItemView_Forms()
    var
        Observer: Codeunit "Probe Observer";
        R1: Report "LT Y7 Exec Params";
        R2: Report "LT Y7 Exec Params";
        R3: Report "LT Y7 Exec Params";
        R4: Report "LT Y7 Exec Params";
    begin
        Seed();
        Exec(Observer, 'sorting grp descending, id range', R1, Params(Note('d'), '<DataItem name="Row">VERSION(1) SORTING(Field2,Field1) ORDER(Descending) WHERE(Field1=1(2..4))</DataItem>'));
        Exec(Observer, 'two field filters', R2, Params('', '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field1=1(&lt;&gt;3),Field2=1(1|2))</DataItem>'));
        Exec(Observer, 'unknown data item name', R3, Params(Note('u'), '<DataItem name="Nope">VERSION(1) SORTING(Field1) WHERE(Field2=1(2))</DataItem>'));
        Exec(Observer, 'empty view text', R4, Params(Note('e'), '<DataItem name="Row"></DataItem>'));
        Observer.Expect('sorting grp descending, id range', 'ok|pre note=d filters=[Id: 2..4] key=[Grp,Id] asc=No;get 4;get 3;get 2;');
        Observer.Expect('two field filters', 'ok|pre note= filters=[Id: <>3, Grp: 1|2] key=[Id] asc=Yes;get 1;get 2;get 4;');
        Observer.Expect('unknown data item name', 'ok|pre note=u filters=[] key=[Id] asc=Yes;get 1;get 2;get 3;get 4;');
        Observer.Expect('empty view text', 'ok|pre note=e filters=[] key=[Id] asc=Yes;get 1;get 2;get 3;get 4;');
        Observer.Verify();
    end;

    [Test]
    procedure Y7_Execute_DataItemView_WithSetTableView()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT Y7 Exec Params";
        Row: Record "LT Y7 Exec Row";
    begin
        Seed();
        Row.SetRange(Id, 1, 3);
        R.SetTableView(Row);
        Exec(Observer, 'view grp 2 over SetTableView id 1..3', R, Params(Note('s'), '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field2=1(2))</DataItem>'));
        Observer.Expect('view grp 2 over SetTableView id 1..3', 'ok|pre note=s filters=[Grp: 2] key=[Id] asc=Yes;get 3;get 4;');
        Observer.Verify();
    end;
}
