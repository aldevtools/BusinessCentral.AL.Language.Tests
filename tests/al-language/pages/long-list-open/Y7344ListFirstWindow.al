// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// local object: the page shape (OnAfterGetRecord and OnAfterGetCurrRecord on a Worksheet, with and without) and the row count are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own objects 99700-99703, test codeunit 99703
// Probe (al-runner issue 7344): the table holds N rows R1001..R(1000+N); the page is opened with OpenEdit; an action inserts one row
//   (A before every row, Z after every row, R1010A in the middle) and calls CurrPage.Update() (or not); then TestPage.GoToKey or
//   TestPage.GoToRecord of the new row, in separate runs. N is 1, 19, 20, 21 and 60. The reading is Found true or false and the row the
//   page shows afterwards. "Both" has the two triggers (empty), "None" has neither.
// Results (BC 27.5, 28.5, 29.0 on the Linux CI, identical): GoToKey and GoToRecord find the inserted row (found=Yes, the page shows it) for every
//   row count 1, 19, 20, 21 and 60, for an insert before every row, after every row and in the middle, with and without CurrPage.Update(),
//   and on the page with neither trigger. There is no threshold at 20 rows.
// BC versions: 27, 28, 29

table 99700 "LT FW Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    procedure AddRow(NewNo: Code[20])
    var
        Line: Record "LT FW Line";
    begin
        Line."No." := NewNo;
        Line.Description := 'Inserted ' + NewNo;
        Line.Insert();
    end;
}

page 99701 "LT FW Both"
{
    PageType = Worksheet;
    SourceTable = "LT FW Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsA)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update();
                end;
            }
            action(InsANoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                end;
            }
            action(InsZ)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('Z');
                    CurrPage.Update();
                end;
            }
            action(InsM)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('R1010A');
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;
}

page 99702 "LT FW None"
{
    PageType = Worksheet;
    SourceTable = "LT FW Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsA)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                    CurrPage.Update();
                end;
            }
            action(InsANoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('A');
                end;
            }
            action(InsZ)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('Z');
                    CurrPage.Update();
                end;
            }
            action(InsM)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.AddRow('R1010A');
                    CurrPage.Update();
                end;
            }
        }
    }
}

codeunit 99703 "LT FW Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed(Count: Integer)
    var
        Line: Record "LT FW Line";
        i: Integer;
    begin
        Line.DeleteAll();
        for i := 1 to Count do begin
            Line."No." := 'R' + Format(1000 + i);
            Line.Description := 'Existing';
            Line.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryBothKey(var P: TestPage "LT FW Both"; RowKey: Code[20]; var Found: Boolean)
    begin
        Found := P.GoToKey(RowKey);
    end;

    [TryFunction]
    local procedure TryBothRecord(var P: TestPage "LT FW Both"; RowKey: Code[20]; var Found: Boolean)
    var
        Line: Record "LT FW Line";
    begin
        Line.Get(RowKey);
        Found := P.GoToRecord(Line);
    end;

    local procedure RunBoth(Count: Integer; Action: Integer; ByRecord: Boolean): Text
    var
        P: TestPage "LT FW Both";
        RowKey: Code[20];
        Found: Boolean;
        Ok: Boolean;
        Shown: Text;
    begin
        Seed(Count);
        P.OpenEdit();
        case Action of
            1:
                begin
                    P.InsA.Invoke();
                    RowKey := 'A';
                end;
            2:
                begin
                    P.InsANoUpdate.Invoke();
                    RowKey := 'A';
                end;
            3:
                begin
                    P.InsZ.Invoke();
                    RowKey := 'Z';
                end;
            4:
                begin
                    P.InsM.Invoke();
                    RowKey := 'R1010A';
                end;
        end;
        ClearLastError();
        if ByRecord then
            Ok := TryBothRecord(P, RowKey, Found)
        else
            Ok := TryBothKey(P, RowKey, Found);
        if Ok then
            Shown := 'found=' + Format(Found)
        else
            Shown := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        exit(Shown + ' now=' + P."No.".Value());
    end;

    [TryFunction]
    local procedure TryNoneKey(var P: TestPage "LT FW None"; RowKey: Code[20]; var Found: Boolean)
    begin
        Found := P.GoToKey(RowKey);
    end;

    [TryFunction]
    local procedure TryNoneRecord(var P: TestPage "LT FW None"; RowKey: Code[20]; var Found: Boolean)
    var
        Line: Record "LT FW Line";
    begin
        Line.Get(RowKey);
        Found := P.GoToRecord(Line);
    end;

    local procedure RunNone(Count: Integer; Action: Integer; ByRecord: Boolean): Text
    var
        P: TestPage "LT FW None";
        RowKey: Code[20];
        Found: Boolean;
        Ok: Boolean;
        Shown: Text;
    begin
        Seed(Count);
        P.OpenEdit();
        case Action of
            1:
                begin
                    P.InsA.Invoke();
                    RowKey := 'A';
                end;
            2:
                begin
                    P.InsANoUpdate.Invoke();
                    RowKey := 'A';
                end;
            3:
                begin
                    P.InsZ.Invoke();
                    RowKey := 'Z';
                end;
            4:
                begin
                    P.InsM.Invoke();
                    RowKey := 'R1010A';
                end;
        end;
        ClearLastError();
        if ByRecord then
            Ok := TryNoneRecord(P, RowKey, Found)
        else
            Ok := TryNoneKey(P, RowKey, Found);
        if Ok then
            Shown := 'found=' + Format(Found)
        else
            Shown := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        exit(Shown + ' now=' + P."No.".Value());
    end;

    [Test]
    procedure Y7344_Both_InsertBeforeAll_Update()
    begin
        Observer.Observe('GoToKey 1 rows', RunBoth(1, 1, false));
        Observer.Observe('GoToRecord 1 rows', RunBoth(1, 1, true));
        Observer.Observe('GoToKey 19 rows', RunBoth(19, 1, false));
        Observer.Observe('GoToRecord 19 rows', RunBoth(19, 1, true));
        Observer.Observe('GoToKey 20 rows', RunBoth(20, 1, false));
        Observer.Observe('GoToRecord 20 rows', RunBoth(20, 1, true));
        Observer.Observe('GoToKey 21 rows', RunBoth(21, 1, false));
        Observer.Observe('GoToRecord 21 rows', RunBoth(21, 1, true));
        Observer.Observe('GoToKey 60 rows', RunBoth(60, 1, false));
        Observer.Observe('GoToRecord 60 rows', RunBoth(60, 1, true));
        Observer.Expect('GoToKey 1 rows', 'found=Yes now=A');
        Observer.Expect('GoToRecord 1 rows', 'found=Yes now=A');
        Observer.Expect('GoToKey 19 rows', 'found=Yes now=A');
        Observer.Expect('GoToRecord 19 rows', 'found=Yes now=A');
        Observer.Expect('GoToKey 20 rows', 'found=Yes now=A');
        Observer.Expect('GoToRecord 20 rows', 'found=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y7344_Both_InsertBeforeAll_NoUpdate()
    begin
        Observer.Observe('GoToKey 1 rows', RunBoth(1, 2, false));
        Observer.Observe('GoToRecord 1 rows', RunBoth(1, 2, true));
        Observer.Observe('GoToKey 19 rows', RunBoth(19, 2, false));
        Observer.Observe('GoToRecord 19 rows', RunBoth(19, 2, true));
        Observer.Observe('GoToKey 20 rows', RunBoth(20, 2, false));
        Observer.Observe('GoToRecord 20 rows', RunBoth(20, 2, true));
        Observer.Observe('GoToKey 21 rows', RunBoth(21, 2, false));
        Observer.Observe('GoToRecord 21 rows', RunBoth(21, 2, true));
        Observer.Observe('GoToKey 60 rows', RunBoth(60, 2, false));
        Observer.Observe('GoToRecord 60 rows', RunBoth(60, 2, true));
        Observer.Expect('GoToKey 1 rows', 'found=Yes now=A');
        Observer.Expect('GoToRecord 1 rows', 'found=Yes now=A');
        Observer.Expect('GoToKey 19 rows', 'found=Yes now=A');
        Observer.Expect('GoToRecord 19 rows', 'found=Yes now=A');
        Observer.Expect('GoToKey 20 rows', 'found=Yes now=A');
        Observer.Expect('GoToRecord 20 rows', 'found=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y7344_Both_InsertAfterAll_Update()
    begin
        Observer.Observe('GoToKey 19 rows', RunBoth(19, 3, false));
        Observer.Observe('GoToRecord 19 rows', RunBoth(19, 3, true));
        Observer.Observe('GoToKey 20 rows', RunBoth(20, 3, false));
        Observer.Observe('GoToRecord 20 rows', RunBoth(20, 3, true));
        Observer.Observe('GoToKey 60 rows', RunBoth(60, 3, false));
        Observer.Observe('GoToRecord 60 rows', RunBoth(60, 3, true));
        Observer.Expect('GoToKey 19 rows', 'found=Yes now=Z');
        Observer.Expect('GoToRecord 19 rows', 'found=Yes now=Z');
        Observer.Expect('GoToKey 20 rows', 'found=Yes now=Z');
        Observer.Expect('GoToRecord 20 rows', 'found=Yes now=Z');
        Observer.Expect('GoToKey 60 rows', 'found=Yes now=Z');
        Observer.Expect('GoToRecord 60 rows', 'found=Y');
        Observer.Verify();
    end;

    [Test]
    procedure Y7344_Both_InsertMiddle_Update()
    begin
        Observer.Observe('GoToKey 19 rows', RunBoth(19, 4, false));
        Observer.Observe('GoToRecord 19 rows', RunBoth(19, 4, true));
        Observer.Observe('GoToKey 20 rows', RunBoth(20, 4, false));
        Observer.Observe('GoToRecord 20 rows', RunBoth(20, 4, true));
        Observer.Observe('GoToKey 60 rows', RunBoth(60, 4, false));
        Observer.Observe('GoToRecord 60 rows', RunBoth(60, 4, true));
        Observer.Expect('GoToKey 19 rows', 'found=Yes now=R1010A');
        Observer.Expect('GoToRecord 19 rows', 'found=Yes now=R1010A');
        Observer.Expect('GoToKey 20 rows', 'found=Yes now=R1010A');
        Observer.Expect('GoToRecord 20 rows', 'found=Yes now=R1010A');
        Observer.Expect('GoToKey 60 rows', 'found=Yes now=R1010A');
        Observer.Expect('G', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y7344_None_InsertBeforeAll_Update()
    begin
        Observer.Observe('GoToKey 19 rows', RunNone(19, 1, false));
        Observer.Observe('GoToRecord 19 rows', RunNone(19, 1, true));
        Observer.Observe('GoToKey 20 rows', RunNone(20, 1, false));
        Observer.Observe('GoToRecord 20 rows', RunNone(20, 1, true));
        Observer.Observe('GoToKey 60 rows', RunNone(60, 1, false));
        Observer.Observe('GoToRecord 60 rows', RunNone(60, 1, true));
        Observer.Expect('GoToKey 19 rows', 'found=Yes now=A');
        Observer.Expect('GoToRecord 19 rows', 'found=Yes now=A');
        Observer.Expect('GoToKey 20 rows', 'found=Yes now=A');
        Observer.Expect('GoToRecord 20 rows', 'found=Yes now=A');
        Observer.Expect('GoToKey 60 rows', 'found=Yes now=A');
        Observer.Expect('GoToRecord 60 rows', 'found=Y');
        Observer.Verify();
    end;
}
