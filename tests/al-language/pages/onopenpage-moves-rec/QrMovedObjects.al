// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: own objects 87260 - 87265 (writer QR); tests in QrMovedTests.al (codeunit 87266)
// Probe: observed on the corpus CI matrix; every literal asserted is what the BC service tier produced.
// Objects: a table with rows A, B, C, D (Name sorts them the other way round), a Card and a List page on it and a Card and a List page on a
//   temporary source (SourceTableTemporary; OnOpenPage inserts A..D itself, which leaves Rec on D). No page declares OnFindRecord or
//   OnNextRecord. OnOpenPage moves Rec as the log codeunit's mode says (see Move). Log: O:<no> = Rec when OnOpenPage ends,
//   R:<no> = OnAfterGetRecord, C:<no> = OnAfterGetCurrRecord.
// BC versions: 27, 28, 29

table 87260 "LT QR Page Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByName; Name) { }
    }
}

page 87261 "LT QR Moved Card"
{
    PageType = Card;
    SourceTable = "LT QR Page Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
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

page 87262 "LT QR Moved List"
{
    PageType = List;
    SourceTable = "LT QR Page Row";
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

page 87263 "LT QR Moved Temp Card"
{
    PageType = Card;
    SourceTable = "LT QR Page Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
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

page 87264 "LT QR Moved Temp List"
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

codeunit 87265 "LT QR Page Log"
{
    SingleInstance = true;

    var
        Mode: Integer;
        Entries: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    // Rows A 'delta', B 'charlie', C 'bravo', D 'alpha': key "No." orders them A..D, key ByName D..A.
    procedure Fill(var Rec: Record "LT QR Page Row")
    begin
        Insert(Rec, 'A', 'delta');
        Insert(Rec, 'B', 'charlie');
        Insert(Rec, 'C', 'bravo');
        Insert(Rec, 'D', 'alpha');
    end;

    local procedure Insert(var Rec: Record "LT QR Page Row"; No: Code[10]; NewName: Text[30])
    begin
        Rec.Init();
        Rec."No." := No;
        Rec.Name := NewName;
        Rec.Insert();
    end;

    // 0: nothing; 1: Get('C'); 2: FindLast; 3: FindFirst then Next (B); 4: SetRange("No.", 'B', 'D') then FindLast (D);
    // 5: SetCurrentKey(Name) then Get('B'); 6: "No." := 'C' without a read; 7: Get('C') then SetRange("No.", 'A', 'B') (Rec outside the view);
    // 8: SetRange("No.", 'B', 'D') then FindFirst (B, the first row of the view).
    procedure Move(var Rec: Record "LT QR Page Row")
    begin
        case Mode of
            1:
                Rec.Get('C');
            2:
                Rec.FindLast();
            3:
                begin
                    Rec.FindFirst();
                    Rec.Next();
                end;
            4:
                begin
                    Rec.SetRange("No.", 'B', 'D');
                    Rec.FindLast();
                end;
            5:
                begin
                    Rec.SetCurrentKey(Name);
                    Rec.Get('B');
                end;
            6:
                Rec."No." := 'C';
            7:
                begin
                    Rec.Get('C');
                    Rec.SetRange("No.", 'A', 'B');
                end;
            8:
                begin
                    Rec.SetRange("No.", 'B', 'D');
                    Rec.FindFirst();
                end;
        end;
    end;
}
