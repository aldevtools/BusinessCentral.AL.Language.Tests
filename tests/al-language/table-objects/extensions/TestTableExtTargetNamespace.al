// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: TXN Log (69420), TXN Logger (69421)
//
// Shared fixtures for TestTableExtTargetNamespace_Tests.al: what a tableextension extends when
// its `extends` clause is written bare or with its namespace, and a table of the same name
// exists in two namespaces. Each extension logs one row when its OnInsert or an OnValidate of
// a field it adds runs, so the log says which extensions ran for the table that was written.

namespace ALLanguage.Coverage.TxnShared;

table 69420 "TXN Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Trigger Name"; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 69421 "TXN Logger"
{
    procedure Log(TriggerName: Text[50])
    var
        LogRec: Record "TXN Log";
        NextEntryNo: Integer;
    begin
        if LogRec.FindLast() then
            NextEntryNo := LogRec."Entry No." + 1
        else
            NextEntryNo := 1;

        LogRec.Init();
        LogRec."Entry No." := NextEntryNo;
        LogRec."Trigger Name" := TriggerName;
        LogRec.Insert();
    end;
}
