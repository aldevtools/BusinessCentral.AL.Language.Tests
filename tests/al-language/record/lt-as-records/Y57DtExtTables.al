// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope
// Fixtures used: tables 93100, 93101 and their table extensions 93101, 93100 (writer Y57); filled and copied by the install codeunit 92912
//   (Y47DtInstall.al, scenarios S4-S6), read by test codeunit 92913 (Y47DtInstallRead.al, Y57_DtExt_*).
// Probe: DataTransfer into and from tables that have a table extension (in the same app), with fields of the extension as source,
//   destination and filter, and an unmapped extension field with an InitValue. The base table triggers and the table extension triggers
//   write into the log table 92912 with codes X0001.. (not L*, so Y47_DtInstall_NoTriggers is not touched).
// BC versions: 27.5+

table 93100 "LT Y57 DT Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer) { }
        field(3; Label; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnModify()
    begin
        AddLog('src modify ' + "Code");
    end;

    procedure AddLog(Line: Text)
    var
        Log: Record "LT Y47 DT Log";
        Next: Integer;
    begin
        Log.SetFilter("Code", 'X*');
        Next := Log.Count() + 1;
        Log.Init();
        Log."Code" := CopyStr('X' + Format(Next, 4, '<Integer,4><Filler Character,0>'), 1, 20);
        Log.Outcome := CopyStr(Line, 1, 250);
        if Log.Insert() then;
    end;
}

tableextension 93101 "LT Y57 DT Src Ext" extends "LT Y57 DT Src"
{
    fields
    {
        field(93101; "Ext Qty"; Integer) { DataClassification = SystemMetadata; }
    }

    trigger OnAfterModify()
    begin
        AddLog('src ext after modify ' + "Code");
    end;
}

table 93101 "LT Y57 DT Dest"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer)
        {
            trigger OnValidate()
            var
                Src: Record "LT Y57 DT Src";
            begin
                Src.AddLog('dest validate amount ' + "Code");
            end;
        }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Src: Record "LT Y57 DT Src";
    begin
        Src.AddLog('dest insert ' + "Code");
    end;

    trigger OnModify()
    var
        Src: Record "LT Y57 DT Src";
    begin
        Src.AddLog('dest modify ' + "Code");
    end;
}

tableextension 93100 "LT Y57 DT Dest Ext" extends "LT Y57 DT Dest"
{
    fields
    {
        field(93100; "Ext Amount"; Integer)
        {
            DataClassification = SystemMetadata;
            InitValue = 7;

            trigger OnValidate()
            var
                Src: Record "LT Y57 DT Src";
            begin
                Src.AddLog('dest ext validate ' + "Code");
            end;
        }
        field(93102; "Ext Note"; Text[30])
        {
            DataClassification = SystemMetadata;
            InitValue = 'ext init';
        }
    }

    trigger OnAfterInsert()
    var
        Src: Record "LT Y57 DT Src";
    begin
        Src.AddLog('dest ext after insert ' + "Code");
    end;

    trigger OnBeforeModify()
    var
        Src: Record "LT Y57 DT Src";
    begin
        Src.AddLog('dest ext before modify ' + "Code");
    end;
}
