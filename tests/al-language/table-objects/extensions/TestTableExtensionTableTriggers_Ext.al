// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: TXT Row (60428), TXT Log (60429), TXT Owned (60431)
//
// "TXT Row" declares no table triggers at all, so every entry TXT Log holds for it was
// contributed by "TXT Row Ext" (60430). A base table carrying its own OnInsert would leave
// "did the extension's copy run" unanswerable — that case is covered separately by
// "TXT Owned" (60431) and "TXT Owned Ext" (60432), which pin the ORDER of the two.

tableextension 60430 "TXT Row Ext" extends "TXT Row"
{
    fields
    {
        field(60430; "Ext Marker"; Integer) { DataClassification = CustomerContent; }
    }

    trigger OnBeforeInsert()
    begin
        TxtLog('OnBeforeInsert');
    end;

    trigger OnAfterInsert()
    begin
        TxtLog('OnAfterInsert');
    end;

    trigger OnBeforeModify()
    begin
        TxtLog('OnBeforeModify');
    end;

    trigger OnAfterModify()
    begin
        TxtLog('OnAfterModify');
    end;

    trigger OnBeforeDelete()
    begin
        TxtLog('OnBeforeDelete');
    end;

    trigger OnAfterDelete()
    begin
        TxtLog('OnAfterDelete');
    end;

    trigger OnBeforeRename()
    begin
        TxtLog('OnBeforeRename');
    end;

    trigger OnAfterRename()
    begin
        TxtLog('OnAfterRename');
    end;

    local procedure TxtLog(TriggerName: Text[50])
    var
        LogRec: Record "TXT Log";
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

table 60431 "TXT Owned"
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

    trigger OnInsert()
    var
        LogRec: Record "TXT Log";
        NextEntryNo: Integer;
    begin
        if LogRec.FindLast() then
            NextEntryNo := LogRec."Entry No." + 1
        else
            NextEntryNo := 1;

        LogRec.Init();
        LogRec."Entry No." := NextEntryNo;
        LogRec."Trigger Name" := 'BaseOnInsert';
        LogRec.Insert();
    end;
}

tableextension 60432 "TXT Owned Ext" extends "TXT Owned"
{
    trigger OnBeforeInsert()
    begin
        TxtLog('ExtOnBeforeInsert');
    end;

    trigger OnAfterInsert()
    begin
        TxtLog('ExtOnAfterInsert');
    end;

    local procedure TxtLog(TriggerName: Text[50])
    var
        LogRec: Record "TXT Log";
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
