// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: self-contained table 69181, page 69181, page extension 69181
// Probe: a compile check written against BC 27 (AL 16 to 30): every trigger below is allowed in a page extension. The others are not:
// OnInit (AL0162, must-not-compile case 0004), OnFindRecord (0017), OnNextRecord (0018). The object runs no test; it only has to compile.
// BC versions: 27 and newer
table 69181 "PO Trigger Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 69181 "PO Trigger Base Page"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "PO Trigger Row";
}

pageextension 69181 "PO Trigger Ext" extends "PO Trigger Base Page"
{
    trigger OnOpenPage()
    begin
    end;

    trigger OnClosePage()
    begin
    end;

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(true);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    begin
    end;
}
