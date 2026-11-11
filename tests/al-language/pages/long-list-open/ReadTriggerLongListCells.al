// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-last-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-next-method
// Scope: in-scope (Cloud). TestPage; ModalPageHandler with a TestPage.
// Fixtures used: Probe Observer (codeunit 69160); own table 64850, log codeunit 64851, pages 64852 and 64853, test codeunit 64859
// Probe: observe-only. Area: TestPage moves on lists whose page has OnAfterGetRecord and OnAfterGetCurrRecord (al-runner issues
//   7475, 7757 and 7799). Cells: Last() on a list of 61 rows opened with OpenView and run modally in lookup mode from a Page variable
//   (the Item List shape of 7475); GoToKey with a lowercase Code key and with an Integer for a Code key on a list of 5 rows, from its
//   first and its third row; on a Worksheet with only OnAfterGetRecord, OpenEdit then Next() with no First() before it, then a
//   SetValue on a repeater control bound to a page variable with an OnValidate.
//   Pinned nearby: pages/long-list-open/LastOnLongList.al (Last() on long lists of a page with only OnAfterGetRecord),
//   pages/run-modal/P82TestPage.al:77 Navigation_GoToKey (lowercase and wrong-type keys on a list without row triggers),
//   testpage/Y61GoToKeyEdges.al (a missing key on a list with OnAfterGetCurrRecord). Not pinned: the cells above.
// Observed: the result of each move, the row shown after it and the log (R:<id> OnAfterGetRecord, C:<id> OnAfterGetCurrRecord,
//   V:<id>/<value> the control's OnValidate), written as one text per step.
// local object: the row triggers of the pages and the row counts are what the test checks
// BC versions: 27, 28, 29

table 64850 "PGP4 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 64851 "PGP4 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ' ';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 64852 "PGP4 List"
{
    PageType = List;
    SourceTable = "PGP4 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Code");
    end;

    var
        Log: Codeunit "PGP4 Log";
}

page 64853 "PGP4 Worksheet"
{
    PageType = Worksheet;
    SourceTable = "PGP4 Row";
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(TermCtrl; Term)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('V:' + Rec."Code" + '/' + Format(Term));
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Code");
        Term := 0;
    end;

    var
        Log: Codeunit "PGP4 Log";
        Term: Integer;
}

codeunit 64859 "PGP4 Read Trigger Cells"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PGP4 Log";

    local procedure Initialize(Count: Integer)
    var
        Row: Record "PGP4 Row";
        i: Integer;
    begin
        Row.DeleteAll();
        Observer.Discard();
        for i := 1 to Count do begin
            Row.Init();
            Row."Code" := 'R' + Format(1000 + i);
            Row.Name := 'N' + Format(i);
            Row.Insert();
        end;
        Log.Take();
    end;

    [TryFunction]
    local procedure TryLast(var P: TestPage "PGP4 List"; var Moved: Boolean)
    begin
        Moved := P.Last();
    end;

    local procedure LastAndPrevious(var P: TestPage "PGP4 List")
    var
        Moved: Boolean;
    begin
        Observer.Observe('opened on', P."Code".Value());
        Observer.Observe('log of the open', Log.Take());
        if TryLast(P, Moved) then
            Observer.Observe('Last', Format(Moved))
        else
            Observer.ObserveError('Last error');
        Observer.Observe('shown after Last', P."Code".Value());
        Observer.Observe('log of Last', Log.Take());
        Observer.Observe('Previous', Format(P.Previous()));
        Observer.Observe('shown after Previous', P."Code".Value());
        Observer.Observe('log of Previous', Log.Take());
    end;

    [Test]
    procedure WithCurrRecord_61Rows_OpenView_Last()
    var
        P: TestPage "PGP4 List";
    begin
        Initialize(61);
        P.OpenView();
        LastAndPrevious(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LastThenOkHandler')]
    procedure WithCurrRecord_61Rows_LookupVariable_Last_GetRecord()
    var
        Row: Record "PGP4 Row";
        List: Page "PGP4 List";
    begin
        Initialize(61);
        List.Editable(false);
        List.LookupMode(true);
        Observer.Observe('action', Format(List.RunModal()));
        List.GetRecord(Row);
        Observer.Observe('GetRecord', Row."Code");
        Observer.Observe('log after the handler', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure LastThenOkHandler(var P: TestPage "PGP4 List")
    begin
        LastAndPrevious(P);
        P.Last();
        Observer.Observe('log of the second Last', Log.Take());
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryGoToKey(var P: TestPage "PGP4 List"; KeyValue: Variant; var Found: Boolean)
    begin
        Found := P.GoToKey(KeyValue);
    end;

    local procedure GoToKeyForm(StartOnThird: Boolean; KeyValue: Variant)
    var
        P: TestPage "PGP4 List";
        Found: Boolean;
    begin
        Initialize(5);
        P.OpenView();
        if StartOnThird then
            P.GoToKey('R1003');
        Log.Take();
        if TryGoToKey(P, KeyValue, Found) then
            Observer.Observe('GoToKey', Format(Found))
        else
            Observer.ObserveError('GoToKey error');
        Observer.Observe('shown after GoToKey', P."Code".Value());
        Observer.Observe('log of GoToKey', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure WithCurrRecord_GoToKey_Lowercase_FromFirstRow()
    begin
        GoToKeyForm(false, 'r1002');
    end;

    [Test]
    procedure WithCurrRecord_GoToKey_Lowercase_FromThirdRow()
    begin
        GoToKeyForm(true, 'r1002');
    end;

    [Test]
    procedure WithCurrRecord_GoToKey_IntegerForCode_FromFirstRow()
    begin
        GoToKeyForm(false, 1002);
    end;

    [Test]
    procedure WithCurrRecord_GoToKey_IntegerForCode_FromThirdRow()
    begin
        GoToKeyForm(true, 1002);
    end;

    [Test]
    procedure Worksheet_OpenEdit_NextWithoutFirst_SetValueOnVariableControl()
    var
        Ws: TestPage "PGP4 Worksheet";
    begin
        Initialize(3);
        Ws.OpenEdit();
        Observer.Observe('log of the open', Log.Take());
        Observer.Observe('Next', Format(Ws.Next()));
        Observer.Observe('shown after Next', Ws."Code".Value());
        Observer.Observe('log of Next', Log.Take());
        Ws.TermCtrl.SetValue(5);
        Observer.Observe('log of SetValue', Log.Take());
        Observer.Observe('term shown', Ws.TermCtrl.Value());
        Ws.Close();
        Observer.Finish();
    end;
}
