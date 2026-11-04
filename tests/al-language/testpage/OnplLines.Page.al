// Fixture for codeunit 60868 "ONPL Tests": "TPDL Lines" (60997) plus one control bound to a
// page VARIABLE, whose OnValidate writes Rec -- the shape of the Purchase Invoice subform's
// FilteredTypeField, which is the first control Microsoft's document tests type into.
page 60869 "ONPL Lines"
{
    PageType = ListPart;
    SourceTable = "TPDL Line";
    ApplicationArea = All;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(HeaderNo; Rec."Header No.") { ApplicationArea = All; }
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
                field(ViaGlobal; ViaGlobal)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Validate(Descr, ViaGlobal);
                    end;
                }
                field(HeaderSeen; Rec."Header Seen By Validate") { ApplicationArea = All; }
                field(SetByOnNewRecord; Rec."Set By OnNewRecord") { ApplicationArea = All; }
            }
        }
    }

    var
        ViaGlobal: Text[50];

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Set By OnNewRecord" := 'NEWREC';
    end;
}
