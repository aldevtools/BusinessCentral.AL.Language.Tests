// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: PXT Row (60654), PXT Log (60655)
//
// The base page declares NO triggers at all, so everything the tests observe was
// contributed by "PXT List Ext" (60657). A base page carrying its own OnOpenPage would
// leave "did the extension's copy run" unanswerable.

page 60656 "PXT List"
{
    PageType = List;
    SourceTable = "PXT Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

pageextension 60657 "PXT List Ext" extends "PXT List"
{
    trigger OnOpenPage()
    begin
        Log('OnOpenPage', '');
    end;

    trigger OnAfterGetRecord()
    begin
        Log('OnAfterGetRecord', Rec."No.");
    end;

    local procedure Log(TriggerName: Text[50]; RowNo: Code[20])
    var
        LogRec: Record "PXT Log";
        NextEntryNo: Integer;
    begin
        if LogRec.FindLast() then
            NextEntryNo := LogRec."Entry No." + 1
        else
            NextEntryNo := 1;

        LogRec.Init();
        LogRec."Entry No." := NextEntryNo;
        LogRec."Trigger Name" := TriggerName;
        LogRec."Row No." := RowNo;
        LogRec.Insert();
    end;
}
