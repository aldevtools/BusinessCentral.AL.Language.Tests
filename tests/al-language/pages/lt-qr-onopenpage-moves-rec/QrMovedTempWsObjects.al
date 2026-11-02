// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: table 87260 and log codeunit 87265 (QrMovedObjects.al); pages 93102, 93103 (writer Y57); tests QR_TempWs* in QrMovedTests.al (87266)
// Objects: a Worksheet page (not a tree) on a temporary source whose OnOpenPage inserts A..D itself (Rec is left on D) and then moves Rec
//   as the log codeunit's mode says, like "LT QR Moved Temp List" (87264); a second one that also has an OnNextRecord trigger which only
//   logs (N:<no>|<steps>) and moves with Rec.Next(Steps). Log: O:<no> = Rec when OnOpenPage ends, R:<no> = OnAfterGetRecord,
//   C:<no> = OnAfterGetCurrRecord.
// BC versions: 27, 28, 29

page 93102 "LT QR Moved Temp Ws"
{
    PageType = Worksheet;
    SourceTable = "LT QR Page Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
        Log.Move(Rec);
        Log.Add('O:' + Rec."No.");
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."No.");
    end;

    var
        Log: Codeunit "LT QR Page Log";
}

page 93103 "LT QR Moved Temp Ws Next"
{
    PageType = Worksheet;
    SourceTable = "LT QR Page Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
        Log.Move(Rec);
        Log.Add('O:' + Rec."No.");
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N:' + Rec."No." + '|' + Format(Steps) + '>' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."No.");
    end;

    var
        Log: Codeunit "LT QR Page Log";
}
