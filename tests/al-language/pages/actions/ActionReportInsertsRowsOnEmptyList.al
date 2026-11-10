// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-delayedinsert-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// local object: the DelayedInsert property of the pages, their actions and the report the actions run are under test (table 62385,
//   report 62386, pages 62387 and 62388, codeunit 62389).
// Area: a List page is filtered to a parent that has no rows, so it stands on its new-row line. An action stores rows for that
//   parent behind the page's back, then the test closes the page (al-runner issue 7478: DelayedInsert = true, the action runs a
//   processing report with a request page, then OK).
//   Pages: DelayedInsert = true and DelayedInsert = false.
//   Actions: a report with a request page (handled by the test), the same report without request page, a direct Insert through
//   another record variable, a direct Insert followed by CurrPage.Update(false).
//   Close: OK and Close.
//   Observed after each step: the rows of the table, whether the page shows a row (First) and which, and after the close whether
//   the blank new-row line was inserted.
// Already pinned elsewhere: GoToRecord on a row an action inserted on a page that already shows rows
//   (pages/actions/Y65GoToRecordActionInsert.al).
// No test writes to the database before the action runs the report with its request page.
// BC versions: 27-29
table 62385 "PAG AddRows Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Parent No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Description; Text[30]) { }
    }

    keys
    {
        key(PK; "Parent No.", "Line No.") { Clustered = true; }
    }
}

report 62386 "PAG AddRows Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                Line: Record "PAG AddRows Line";
                I: Integer;
            begin
                for I := 1 to HowMany do begin
                    Line.Init();
                    Line."Parent No." := ParentNo;
                    Line."Line No." := I * 10000;
                    Line.Description := 'by report ' + Format(I);
                    Line.Insert();
                end;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(HowManyCtl; HowMany)
                {
                    ApplicationArea = All;
                    Caption = 'How many';
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        HowMany := 2;
    end;

    var
        ParentNo: Code[20];
        HowMany: Integer;

    procedure SetParent(NewParentNo: Code[20])
    begin
        ParentNo := NewParentNo;
    end;
}

codeunit 62389 "PAG AddRows Mgt"
{
    // Mode 1: the report with its request page. 2: the report without request page. 3 and 4: a direct Insert.
    procedure AddLines(var PageLine: Record "PAG AddRows Line"; Mode: Integer)
    var
        Line: Record "PAG AddRows Line";
        AddRows: Report "PAG AddRows Report";
        ParentNo: Code[20];
    begin
        ParentNo := CopyStr(PageLine.GetFilter("Parent No."), 1, MaxStrLen(ParentNo));
        case Mode of
            1:
                begin
                    AddRows.SetParent(ParentNo);
                    AddRows.Run();
                end;
            2:
                begin
                    AddRows.SetParent(ParentNo);
                    AddRows.UseRequestPage(false);
                    AddRows.RunModal();
                end;
            3, 4:
                begin
                    Line.Init();
                    Line."Parent No." := ParentNo;
                    Line."Line No." := 10000;
                    Line.Description := 'direct 1';
                    Line.Insert();
                    Line."Line No." := 20000;
                    Line.Description := 'direct 2';
                    Line.Insert();
                end;
        end;
    end;
}

page 62387 "PAG AddRows Delayed"
{
    PageType = List;
    SourceTable = "PAG AddRows Line";
    DelayedInsert = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Parent No."; Rec."Parent No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddByReport)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Mgt.AddLines(Rec, 1);
                end;
            }
            action(AddByReportNoRequestPage)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Mgt.AddLines(Rec, 2);
                end;
            }
            action(AddDirect)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Mgt.AddLines(Rec, 3);
                end;
            }
            action(AddDirectAndUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Mgt.AddLines(Rec, 4);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "PAG AddRows Mgt";
}

page 62388 "PAG AddRows Plain"
{
    PageType = List;
    SourceTable = "PAG AddRows Line";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Parent No."; Rec."Parent No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddByReport)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Mgt.AddLines(Rec, 1);
                end;
            }
            action(AddByReportNoRequestPage)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Mgt.AddLines(Rec, 2);
                end;
            }
            action(AddDirect)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Mgt.AddLines(Rec, 3);
                end;
            }
            action(AddDirectAndUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Mgt.AddLines(Rec, 4);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "PAG AddRows Mgt";
}

codeunit 62390 "PAG AddRows Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Stored(): Text
    var
        Line: Record "PAG AddRows Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += '[' + Line."Parent No." + ' ' + Format(Line."Line No.") + ' ' + Line.Description + ']';
            until Line.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryOkDelayed(var Pg: TestPage "PAG AddRows Delayed")
    begin
        Pg.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryCloseDelayed(var Pg: TestPage "PAG AddRows Delayed")
    begin
        Pg.Close();
    end;

    [TryFunction]
    local procedure TryOkPlain(var Pg: TestPage "PAG AddRows Plain")
    begin
        Pg.OK().Invoke();
    end;

    local procedure ShownDelayed(var Pg: TestPage "PAG AddRows Delayed"): Text
    begin
        exit('[' + Pg."Parent No.".Value + ' ' + Pg."Line No.".Value + ' ' + Pg.Description.Value + ']');
    end;

    local procedure ShownPlain(var Pg: TestPage "PAG AddRows Plain"): Text
    begin
        exit('[' + Pg."Parent No.".Value + ' ' + Pg."Line No.".Value + ' ' + Pg.Description.Value + ']');
    end;

    // Action 1 report with request page, 2 report without, 3 direct, 4 direct and update. Closing 1 OK, 2 Close.
    local procedure RunDelayed(ActionNo: Integer; Closing: Integer)
    var
        Line: Record "PAG AddRows Line";
        Pg: TestPage "PAG AddRows Delayed";
    begin
        Pg.OpenEdit();
        Pg.Filter.SetFilter("Parent No.", 'P1');
        Observer.Observe('row before', ShownDelayed(Pg));
        case ActionNo of
            1:
                Pg.AddByReport.Invoke();
            2:
                Pg.AddByReportNoRequestPage.Invoke();
            3:
                Pg.AddDirect.Invoke();
            4:
                Pg.AddDirectAndUpdate.Invoke();
        end;
        Observer.Observe('stored after action', Stored());
        Observer.Observe('row after action', ShownDelayed(Pg));
        if Closing = 1 then
            Observer.Observe('ok', Format(TryOkDelayed(Pg)))
        else
            Observer.Observe('close', Format(TryCloseDelayed(Pg)));
        Observer.ObserveError('closing');
        Observer.Observe('stored after closing', Stored());
        Line.DeleteAll();
    end;

    local procedure RunPlain(ActionNo: Integer)
    var
        Line: Record "PAG AddRows Line";
        Pg: TestPage "PAG AddRows Plain";
    begin
        Pg.OpenEdit();
        Pg.Filter.SetFilter("Parent No.", 'P1');
        Observer.Observe('row before', ShownPlain(Pg));
        case ActionNo of
            1:
                Pg.AddByReport.Invoke();
            2:
                Pg.AddByReportNoRequestPage.Invoke();
            3:
                Pg.AddDirect.Invoke();
            4:
                Pg.AddDirectAndUpdate.Invoke();
        end;
        Observer.Observe('stored after action', Stored());
        Observer.Observe('row after action', ShownPlain(Pg));
        Observer.Observe('ok', Format(TryOkPlain(Pg)));
        Observer.ObserveError('closing');
        Observer.Observe('stored after closing', Stored());
        Line.DeleteAll();
    end;

    // The reporter's shape.
    [Test]
    [HandlerFunctions('AddRowsHandler')]
    procedure EmptyDelayedInsertList_ActionRunsReportWithRequestPage_Ok()
    begin
        RunDelayed(1, 1);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AddRowsHandler')]
    procedure EmptyDelayedInsertList_ActionRunsReportWithRequestPage_Close()
    begin
        RunDelayed(1, 2);
        Observer.Finish();
    end;

    [Test]
    procedure EmptyDelayedInsertList_ActionRunsReportWithoutRequestPage_Ok()
    begin
        RunDelayed(2, 1);
        Observer.Finish();
    end;

    [Test]
    procedure EmptyDelayedInsertList_ActionInsertsDirectly_Ok()
    begin
        RunDelayed(3, 1);
        Observer.Finish();
    end;

    [Test]
    procedure EmptyDelayedInsertList_ActionInsertsDirectly_Close()
    begin
        RunDelayed(3, 2);
        Observer.Finish();
    end;

    [Test]
    procedure EmptyDelayedInsertList_ActionInsertsDirectlyAndUpdates_Ok()
    begin
        RunDelayed(4, 1);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AddRowsHandler')]
    procedure EmptyPlainList_ActionRunsReportWithRequestPage_Ok()
    begin
        RunPlain(1);
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPlainList_ActionRunsReportWithoutRequestPage_Ok()
    begin
        RunPlain(2);
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPlainList_ActionInsertsDirectly_Ok()
    begin
        RunPlain(3);
        Observer.Finish();
    end;

    [Test]
    procedure EmptyPlainList_ActionInsertsDirectlyAndUpdates_Ok()
    begin
        RunPlain(4);
        Observer.Finish();
    end;

    // After the action the test reads the rows the page shows (First, Next) before it presses OK.
    [Test]
    [HandlerFunctions('AddRowsHandler')]
    procedure EmptyDelayedInsertList_ActionRunsReport_RowsShownThenOk()
    var
        Line: Record "PAG AddRows Line";
        Pg: TestPage "PAG AddRows Delayed";
        Rows: Text;
    begin
        Pg.OpenEdit();
        Pg.Filter.SetFilter("Parent No.", 'P1');
        Pg.AddByReport.Invoke();
        if Pg.First() then
            repeat
                Rows += ShownDelayed(Pg);
            until not Pg.Next();
        Observer.Observe('rows shown', Rows);
        Observer.Observe('ok', Format(TryOkDelayed(Pg)));
        Observer.ObserveError('closing');
        Observer.Observe('stored after closing', Stored());
        Line.DeleteAll();
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure AddRowsHandler(var RP: TestRequestPage "PAG AddRows Report")
    begin
        RP.HowManyCtl.SetValue(3);
        RP.OK().Invoke();
    end;
}
