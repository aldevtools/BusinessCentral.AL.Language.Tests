// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: PXQ Log (69400), PXQ Logger (69401), PXQ Row (69402)
//
// Shared fixtures for TestPageExtQualifiedExtends_Tests.al: what a pageextension's `extends`
// clause names when the name is written with its namespace, or left to the file's own namespace
// and `using`s. The base page the tests extend under two spellings shares its name with a
// Base Application page, so an extension that targets one must not run for the other.

namespace ALLanguage.Coverage.PxqShared;

table 69400 "PXQ Log"
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

table 69402 "PXQ Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 69401 "PXQ Logger"
{
    procedure Log(TriggerName: Text[50])
    var
        LogRec: Record "PXQ Log";
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
