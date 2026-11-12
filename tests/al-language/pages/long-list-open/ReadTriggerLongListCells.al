// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-last-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-next-method
// Scope: in-scope (Cloud). TestPage; ModalPageHandler with a TestPage.
// Fixtures used: Probe Observer (codeunit 69160); own table 64850, log codeunit 64851, pages 64852 and 64853, test codeunit 64859
// Probe (values from the CI runs on BC 27.5, 28.5 and 29.0, the same on all three). Area: TestPage moves on lists whose page has OnAfterGetRecord and OnAfterGetCurrRecord (al-runner issues
//   7475, 7757 and 7799). Cells: Last() on a list of 61 rows opened with OpenView and run modally in lookup mode from a Page variable
//   (the Item List shape of 7475); GoToKey with a lowercase Code key and with an Integer for a Code key on a list of 5 rows, from its
//   first and its third row; on a Worksheet with only OnAfterGetRecord, OpenEdit then Next() with no First() before it, then a
//   SetValue on a repeater control bound to a page variable with an OnValidate.
//   Pinned nearby: pages/long-list-open/LastOnLongList.al (Last() on long lists of a page with only OnAfterGetRecord),
//   pages/run-modal/P82TestPage.al:77 Navigation_GoToKey (lowercase and wrong-type keys on a list without row triggers),
//   testpage/Y61GoToKeyEdges.al (a missing key on a list with OnAfterGetCurrRecord). Not pinned: the cells above.
// Observed: the result of each move, the row shown after it and the log (R:<id> OnAfterGetRecord, C:<id> OnAfterGetCurrRecord,
//   V:<id>/<value> the control's OnValidate), written as one text per step.
// Result: Last() reads from row 20 to the end and stands on the last row, as on a page with only OnAfterGetRecord; GoToKey with a
//   lowercase Code key or an Integer for a Code key answers No (no error), reads the other rows of the list (each with both triggers)
//   and goes back to the row it stood on; Next() without First() on the Worksheet runs no trigger, and the SetValue
//   reads the row it stands on (R:) before the control's OnValidate runs.
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
        Observer.Expect('opened on', 'R1001');
        Observer.Expect('log of the open', 'R:R1001 R:R1002 R:R1003 R:R1004 R:R1005 R:R1006 R:R1007 R:R1008 R:R1009 R:R1010 R:R1011 R:R1012 R:R1013 R:R1014 R:R1015 R:R1016 R:R1017 R:R1018 R:R1019 R:R1020 R:R1001 R:R1001 C:R1001 ');
        Observer.Expect('Last', 'Yes');
        Observer.Expect('shown after Last', 'R1061');
        Observer.Expect('log of Last', 'R:R1020 R:R1021 R:R1022 R:R1023 R:R1024 R:R1025 R:R1026 R:R1027 R:R1028 R:R1029 R:R1030 R:R1031 R:R1032 R:R1033 R:R1034 R:R1035 R:R1036 R:R1037 R:R1038 R:R1039 R:R1040 R:R1041 R:R1042 R:R1043 R:R1044 R:R1045 R:R1046 R:R1047 R:R1048 R:R1049 R:R1050 R:R1051 R:R1052 R:R1053 R:R1054 R:R1055 R:R1056 R:R1057 R:R1058 R:R1059 R:R1060 R:R1061 R:R1061 C:R1061 ');
        Observer.Expect('Previous', 'Yes');
        Observer.Expect('shown after Previous', 'R1060');
        Observer.Expect('log of Previous', 'R:R1060 R:R1060 C:R1060 ');
        Observer.Verify();
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
        Observer.Expect('opened on', 'R1001');
        Observer.Expect('log of the open', 'R:R1001 R:R1002 R:R1003 R:R1004 R:R1005 R:R1006 R:R1007 R:R1008 R:R1009 R:R1010 R:R1011 R:R1012 R:R1013 R:R1014 R:R1015 R:R1016 R:R1017 R:R1018 R:R1019 R:R1020 R:R1001 R:R1001 C:R1001 ');
        Observer.Expect('Last', 'Yes');
        Observer.Expect('shown after Last', 'R1061');
        Observer.Expect('log of Last', 'R:R1020 R:R1021 R:R1022 R:R1023 R:R1024 R:R1025 R:R1026 R:R1027 R:R1028 R:R1029 R:R1030 R:R1031 R:R1032 R:R1033 R:R1034 R:R1035 R:R1036 R:R1037 R:R1038 R:R1039 R:R1040 R:R1041 R:R1042 R:R1043 R:R1044 R:R1045 R:R1046 R:R1047 R:R1048 R:R1049 R:R1050 R:R1051 R:R1052 R:R1053 R:R1054 R:R1055 R:R1056 R:R1057 R:R1058 R:R1059 R:R1060 R:R1061 R:R1061 C:R1061 ');
        Observer.Expect('Previous', 'Yes');
        Observer.Expect('shown after Previous', 'R1060');
        Observer.Expect('log of Previous', 'R:R1060 R:R1060 C:R1060 ');
        Observer.Expect('log of the second Last', 'R:R1061 R:R1061 C:R1061 ');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('GetRecord', 'R1061');
        Observer.Expect('log after the handler', '');
        Observer.Verify();
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
    end;

    [Test]
    procedure WithCurrRecord_GoToKey_Lowercase_FromFirstRow()
    begin
        GoToKeyForm(false, 'r1002');
        Observer.Expect('GoToKey', 'No');
        Observer.Expect('shown after GoToKey', 'R1001');
        Observer.Expect('log of GoToKey', 'R:R1002 R:R1002 C:R1002 R:R1003 R:R1003 C:R1003 R:R1004 R:R1004 C:R1004 R:R1005 R:R1005 C:R1005 R:R1001 R:R1001 C:R1001 ');
        Observer.Verify();
    end;

    [Test]
    procedure WithCurrRecord_GoToKey_Lowercase_FromThirdRow()
    begin
        GoToKeyForm(true, 'r1002');
        Observer.Expect('GoToKey', 'No');
        Observer.Expect('shown after GoToKey', 'R1003');
        Observer.Expect('log of GoToKey', 'R:R1001 R:R1001 C:R1001 R:R1002 R:R1002 C:R1002 R:R1003 R:R1003 C:R1003 R:R1004 R:R1004 C:R1004 R:R1005 R:R1005 C:R1005 R:R1003 R:R1003 C:R1003 ');
        Observer.Verify();
    end;

    [Test]
    procedure WithCurrRecord_GoToKey_IntegerForCode_FromFirstRow()
    begin
        GoToKeyForm(false, 1002);
        Observer.Expect('GoToKey', 'No');
        Observer.Expect('shown after GoToKey', 'R1001');
        Observer.Expect('log of GoToKey', 'R:R1002 R:R1002 C:R1002 R:R1003 R:R1003 C:R1003 R:R1004 R:R1004 C:R1004 R:R1005 R:R1005 C:R1005 R:R1001 R:R1001 C:R1001 ');
        Observer.Verify();
    end;

    [Test]
    procedure WithCurrRecord_GoToKey_IntegerForCode_FromThirdRow()
    begin
        GoToKeyForm(true, 1002);
        Observer.Expect('GoToKey', 'No');
        Observer.Expect('shown after GoToKey', 'R1003');
        Observer.Expect('log of GoToKey', 'R:R1001 R:R1001 C:R1001 R:R1002 R:R1002 C:R1002 R:R1003 R:R1003 C:R1003 R:R1004 R:R1004 C:R1004 R:R1005 R:R1005 C:R1005 R:R1003 R:R1003 C:R1003 ');
        Observer.Verify();
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
        Observer.Expect('log of the open', 'R:R1001 R:R1002 R:R1003 R:R1001 ');
        Observer.Expect('Next', 'Yes');
        Observer.Expect('shown after Next', 'R1002');
        Observer.Expect('log of Next', '');
        Observer.Expect('log of SetValue', 'R:R1002 V:R1002/5 R:R1002 R:R1003 R:R1002 R:R1001 ');
        Observer.Expect('term shown', '0');
        Observer.Verify();
    end;
}
