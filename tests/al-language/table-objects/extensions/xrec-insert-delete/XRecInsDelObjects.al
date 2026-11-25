// Objects of the probe XRecInsDelTests.al (al-runner issue 8986): what xRec holds in the insert and delete triggers of a table
// extension, and in the table's own OnInsert and OnDelete next to them.
// local object: the triggers that read xRec are the thing under test, so the tables, extensions and the page are own objects.
// - "LT XRE Row" (76380): table with OnInsert and OnDelete that log Rec, xRec and what the table procedure ReadXRec sees.
// - "LT XRE Row Ext" (76381): extension of it in the same app; every insert and delete trigger logs Rec, xRec, the same read in a
//   local procedure of the extension, and Rec.ReadXRec(). A mode of the log adds one more reading (SystemId, filters, Count,
//   Get, xRec := Rec) in each insert trigger; a switch makes OnBeforeDelete write Rec.Name.
// - "LT XRE Plain" (76382): a table without extension, OnInsert logs Rec and xRec.
// - "LT XRE Row Card" (76383): card page on "LT XRE Row" for the insert through a page.
// - "LT XRE Base Line Ext" (76384): extension of "XA XRE Base Line" (XApp A, 76390): the two-app shape of issue 8986.
// - "LT XRE Log" (76387): the log. Used only by test codeunit 76388.

table 76380 "LT XRE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Serial; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT XRE Log";
    begin
        Log.Add('T.OnInsert r=' + Log.Fmt("Entry No.", Serial, Name) + ' x=' + Log.Fmt(xRec."Entry No.", xRec.Serial, xRec.Name) +
            ' eq=' + Format(Format(Rec) = Format(xRec)) + ' rp=' + ReadXRec());
    end;

    trigger OnDelete()
    var
        Log: Codeunit "LT XRE Log";
    begin
        Log.Add('T.OnDelete r=' + Log.Fmt("Entry No.", Serial, Name) + ' x=' + Log.Fmt(xRec."Entry No.", xRec.Serial, xRec.Name) +
            ' eq=' + Format(Format(Rec) = Format(xRec)) + ' rp=' + ReadXRec());
    end;

    procedure ReadXRec(): Text
    var
        Log: Codeunit "LT XRE Log";
    begin
        exit(Log.Fmt(xRec."Entry No.", xRec.Serial, xRec.Name));
    end;
}

tableextension 76381 "LT XRE Row Ext" extends "LT XRE Row"
{
    trigger OnBeforeInsert()
    begin
        LogTrigger('E.OnBeforeInsert');
    end;

    trigger OnInsert()
    begin
        LogTrigger('E.OnInsert');
    end;

    trigger OnAfterInsert()
    begin
        LogTrigger('E.OnAfterInsert');
    end;

    trigger OnBeforeDelete()
    var
        Log: Codeunit "LT XRE Log";
    begin
        if Log.GetMode() = 'extwrite' then
            Name := 'EXTW';
        LogTrigger('E.OnBeforeDelete');
    end;

    trigger OnDelete()
    begin
        LogTrigger('E.OnDelete');
    end;

    trigger OnAfterDelete()
    begin
        LogTrigger('E.OnAfterDelete');
    end;

    local procedure LocalXRec(): Text
    var
        Log: Codeunit "LT XRE Log";
    begin
        exit(Log.Fmt(xRec."Entry No.", xRec.Serial, xRec.Name));
    end;

    local procedure LogTrigger(TriggerName: Text)
    var
        Log: Codeunit "LT XRE Log";
        Line: Text;
        Found: Boolean;
    begin
        Line := TriggerName + ' r=' + Log.Fmt("Entry No.", Serial, Name) + ' x=' + Log.Fmt(xRec."Entry No.", xRec.Serial, xRec.Name) +
            ' eq=' + Format(Format(Rec) = Format(xRec)) + ' lp=' + LocalXRec() + ' rp=' + ReadXRec();
        if TriggerName.Contains('Insert') then
            case Log.GetMode() of
                'sid':
                    Line += ' xsidnull=' + Format(IsNullGuid(xRec.SystemId)) + ' rsidnull=' + Format(IsNullGuid(SystemId)) + ' sideq=' + Format(xRec.SystemId = SystemId);
                'filters':
                    Line += ' xfilters=[' + xRec.GetFilters() + '] rfilters=[' + GetFilters() + ']';
                'count':
                    Line += ' xcount=' + Format(xRec.Count()) + ' rcount=' + Format(Count());
                'get':
                    begin
                        Found := xRec.Get("Entry No.");
                        Line += ' xget=' + Format(Found) + ' xafter=' + Log.Fmt(xRec."Entry No.", xRec.Serial, xRec.Name);
                    end;
                'assign':
                    begin
                        xRec := Rec;
                        Line += ' xassigned=' + Log.Fmt(xRec."Entry No.", xRec.Serial, xRec.Name);
                    end;
            end;
        Log.Add(Line);
    end;
}

table 76382 "LT XRE Plain"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Serial; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT XRE Log";
    begin
        Log.Add('P.OnInsert r=' + Log.Fmt("Entry No.", Serial, Name) + ' x=' + Log.Fmt(xRec."Entry No.", xRec.Serial, xRec.Name) +
            ' eq=' + Format(Format(Rec) = Format(xRec)));
    end;
}

page 76383 "LT XRE Row Card"
{
    PageType = Card;
    SourceTable = "LT XRE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
            field(Serial; Rec.Serial) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

tableextension 76384 "LT XRE Base Line Ext" extends "XA XRE Base Line"
{
    fields
    {
        field(76384; "xRec Serial In Ext OnAfterIns"; Integer) { DataClassification = SystemMetadata; }
    }

    trigger OnBeforeInsert()
    begin
        LogTrigger('B.OnBeforeInsert');
    end;

    trigger OnInsert()
    begin
        LogTrigger('B.OnInsert');
    end;

    trigger OnAfterInsert()
    begin
        "xRec Serial In Ext OnAfterIns" := xRec."Serial No.";
        LogTrigger('B.OnAfterInsert');
    end;

    trigger OnBeforeDelete()
    begin
        LogTrigger('B.OnBeforeDelete');
    end;

    trigger OnDelete()
    begin
        LogTrigger('B.OnDelete');
    end;

    trigger OnAfterDelete()
    begin
        LogTrigger('B.OnAfterDelete');
    end;

    local procedure LocalXSerial(): Integer
    begin
        exit(xRec."Serial No.");
    end;

    local procedure LogTrigger(TriggerName: Text)
    var
        Log: Codeunit "LT XRE Log";
    begin
        Log.Add(TriggerName + ' r=' + Log.Fmt("Entry No.", "Serial No.", '') + ' x=' + Log.Fmt(xRec."Entry No.", xRec."Serial No.", '') +
            ' lp=' + Format(LocalXSerial()));
    end;
}

codeunit 76387 "LT XRE Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        Mode: Text;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Line(Index: Integer): Text
    begin
        if Index > Lines.Count() then
            exit('<none>');
        exit(Lines.Get(Index));
    end;

    procedure Reset()
    begin
        Clear(Lines);
        Mode := '';
    end;

    procedure SetMode(NewMode: Text)
    begin
        Mode := NewMode;
    end;

    procedure GetMode(): Text
    begin
        exit(Mode);
    end;

    procedure Fmt(EntryNo: Integer; Serial: Integer; Name: Text): Text
    begin
        exit(Format(EntryNo) + '/' + Format(Serial) + '/' + Name);
    end;
}
