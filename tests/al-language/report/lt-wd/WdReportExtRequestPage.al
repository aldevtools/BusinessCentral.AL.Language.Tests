// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 90790-90794
// Probe: written against al-runner issue 6302. A reportextension that both modifies a dataitem trigger (OnAfterAfterGetRecord) and adds a field to the request page,
//        run through a RequestPageHandler: the extension field set in the handler is read by the extension's trigger, the base report's own trigger also runs,
//        and the field keeps its value or is reset on a second run of the same report variable. Every value asserted below is what the BC service tier produced.
// BC versions: 27, 28, 29

table 90790 "LT WD Account"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Note; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

report 90791 "LT WD Statement"
{
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem(Account; "LT WD Account")
        {
            trigger OnAfterGetRecord()
            begin
                Seen += 1;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(ShowAll; ShowAll) { ApplicationArea = All; }
                }
            }
        }
    }

    procedure GetSeen(): Integer
    begin
        exit(Seen);
    end;

    procedure GetShowAll(): Boolean
    begin
        exit(ShowAll);
    end;

    var
        ShowAll: Boolean;
        Seen: Integer;
}

reportextension 90792 "LT WD Statement Ext" extends "LT WD Statement"
{
    dataset
    {
        modify(Account)
        {
            trigger OnAfterAfterGetRecord()
            begin
                Account.Note := NoteText;
                Account.Modify();
            end;
        }
    }

    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(NoteText; NoteText) { ApplicationArea = All; }
            }
        }
    }

    var
        NoteText: Text[50];
}

codeunit 90794 "LT WD Report Ext Request Page"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('StatementRequestPageHandler')]
    procedure WD_ReportExt_RequestPageFieldReachesTheRun()
    var
        Observer: Codeunit "Probe Observer";
        Account: Record "LT WD Account";
        Statement: Report "LT WD Statement";
    begin
        Account.DeleteAll();
        Account."No." := 'A';
        Account.Insert();
        Account."No." := 'B';
        Account.Insert();
        Commit();

        Statement.UseRequestPage(true);
        Statement.Run();

        Observer.Observe('seen by the base trigger', Format(Statement.GetSeen()));
        Observer.Observe('base field', Format(Statement.GetShowAll()));
        Account.Get('A');
        Observer.Observe('A note', Account.Note);
        Account.Get('B');
        Observer.Observe('B note', Account.Note);
        Observer.Finish();
    end;

    [RequestPageHandler]
    procedure StatementRequestPageHandler(var Statement: TestRequestPage "LT WD Statement")
    begin
        Statement.ShowAll.SetValue(true);
        Statement.NoteText.SetValue('hello');
        Statement.OK().Invoke();
    end;
}
