// Objects of the cross-app probes of this app (writer BW). Tests: BwCrossAppTests.al. The base table is in cross-app fixture A, the
// extension that adds "BW XB Kind" and "BW XB Note" in cross-app fixture B; this app is the third app (corpus #668 item 102, #664 item 14).

// A page of this app filters on a field that another app's table extension adds (#668 item 102).
page 83950 "LT BW XApp Second Kind List"
{
    PageType = List;
    SourceTable = "LT BW XA Base";
    SourceTableView = where("BW XB Kind" = const(Second));
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { }
                field("BW XB Kind"; Rec."BW XB Kind") { }
            }
        }
    }
}

// A FlowField of this app counts on a field that another app's table extension adds (#668 item 102).
table 83951 "LT BW XApp Counts"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Second Kind Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BW XA Base" where("BW XB Kind" = const(Second)));
        }
        field(3; "Note Filter Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BW XA Base" where("BW XB Note" = field("Note Filter")));
        }
        field(4; "Note Filter"; Text[30])
        {
            FieldClass = FlowFilter;
        }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

// A table extension of this app reads and writes a field that another app's table extension of the same table adds (#664 item 14).
tableextension 83950 "LT BW XApp Base Ext M" extends "LT BW XA Base"
{
    fields
    {
        field(83950; "BW M Copy"; Text[30])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                "BW XB Note" := CopyStr('from M: ' + "BW M Copy", 1, MaxStrLen("BW XB Note"));
            end;
        }
    }

    procedure BwCopyNote(): Text
    begin
        "BW M Copy" := "BW XB Note";
        exit("BW M Copy");
    end;
}
