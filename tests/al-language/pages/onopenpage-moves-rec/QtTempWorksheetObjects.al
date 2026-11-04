// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetabletemporary-property
// Scope: in-scope
// Fixtures used: own pages 87380 - 87383 (writer QT); table "LT QR Page Row" (87260) and log "LT QR Page Log" (87265) from QrMovedObjects.al;
//   tests in QrMovedTests.al (codeunit 87266, QT_* tests)
// Probe: al-runtime-rs assumption worksheet-temp-source-open-row (PR 5655, Page 498 Reservation): a page over a TEMPORARY source that a
//   procedure fills BEFORE Run / RunModal (not OnOpenPage) and leaves Rec on some row. SetRows(Pos) inserts A..D (Log.Fill, which leaves Rec
//   on D) and then: '' no move (D); 'A', 'B' Get; 'BB' and 'E' Get('B') then the key set to a value no row has (between B and C / past D);
//   'NAME:B' SetCurrentKey(Name) then Get('B'). Worksheet (no OnFindRecord / OnNextRecord), Worksheet with OnNextRecord, Worksheet with
//   OnFindRecord and OnNextRecord, and a List as the control. Log: O:<no> Rec when OnOpenPage ends, R: OnAfterGetRecord, C: OnAfterGetCurrRecord,
//   F:<which>><no> OnFindRecord, N:<steps>><no> OnNextRecord (the row after the move).
// BC versions: 27, 28, 29

page 87380 "LT QT Temp Ws"
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

    procedure SetRows(Pos: Text)
    begin
        Log.Fill(Rec);
        if Pos = '' then
            exit;
        if Pos.StartsWith('NAME:') then begin
            Rec.SetCurrentKey(Name);
            Rec.Get(CopyStr(Pos, 6));
            exit;
        end;
        if not Rec.Get(Pos) then begin
            Rec.Get('B');
            Rec."No." := CopyStr(Pos, 1, MaxStrLen(Rec."No."));
        end;
    end;

    trigger OnOpenPage()
    begin
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

page 87381 "LT QT Temp Ws Next"
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

    procedure SetRows(Pos: Text)
    begin
        Log.Fill(Rec);
        if Pos = '' then
            exit;
        if Pos.StartsWith('NAME:') then begin
            Rec.SetCurrentKey(Name);
            Rec.Get(CopyStr(Pos, 6));
            exit;
        end;
        if not Rec.Get(Pos) then begin
            Rec.Get('B');
            Rec."No." := CopyStr(Pos, 1, MaxStrLen(Rec."No."));
        end;
    end;

    trigger OnOpenPage()
    begin
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

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N:' + Format(Steps) + '>' + Rec."No.");
        exit(Moved);
    end;

    var
        Log: Codeunit "LT QR Page Log";
}

page 87382 "LT QT Temp Ws Find Next"
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

    procedure SetRows(Pos: Text)
    begin
        Log.Fill(Rec);
        if Pos = '' then
            exit;
        if Pos.StartsWith('NAME:') then begin
            Rec.SetCurrentKey(Name);
            Rec.Get(CopyStr(Pos, 6));
            exit;
        end;
        if not Rec.Get(Pos) then begin
            Rec.Get('B');
            Rec."No." := CopyStr(Pos, 1, MaxStrLen(Rec."No."));
        end;
    end;

    trigger OnOpenPage()
    begin
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

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F:' + Which + '>' + Rec."No.");
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N:' + Format(Steps) + '>' + Rec."No.");
        exit(Moved);
    end;

    var
        Log: Codeunit "LT QR Page Log";
}

page 87383 "LT QT Temp List"
{
    PageType = List;
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

    procedure SetRows(Pos: Text)
    begin
        Log.Fill(Rec);
        if Pos = '' then
            exit;
        if Pos.StartsWith('NAME:') then begin
            Rec.SetCurrentKey(Name);
            Rec.Get(CopyStr(Pos, 6));
            exit;
        end;
        if not Rec.Get(Pos) then begin
            Rec.Get('B');
            Rec."No." := CopyStr(Pos, 1, MaxStrLen(Rec."No."));
        end;
    end;

    trigger OnOpenPage()
    begin
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
