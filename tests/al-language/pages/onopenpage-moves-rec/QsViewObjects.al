// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: own pages 87365 - 87374 and log codeunit 87375 (writer QS) on table 87260 (QrMovedObjects.al); tests QS_* in QrMovedTests.al
//   (codeunit 87266)
// Probe: observed on the corpus CI matrix; every literal asserted in the QS_* tests is what the BC service tier produced.
// Objects: a Card and a List page for each of five SourceTableViews on the QR table (rows A 'delta', B 'charlie', C 'bravo', D 'alpha'):
//   KeyAsc = sorting(Name) (D, C, B, A), KeyDesc = sorting(Name) order(descending) (A, B, C, D), PkDesc = sorting("No.") order(descending)
//   (D, C, B, A), Where = where("No." = filter('B..D')) (B, C, D), KeyWhere = sorting(Name) where("No." = filter('A..C')) (C, B, A).
//   OnOpenPage moves Rec as the log codeunit's mode says (see Move). Log: V:<view> = Rec.GetView() when OnOpenPage starts, O:<no> = Rec
//   when OnOpenPage ends, R:<no> = OnAfterGetRecord, C:<no> = OnAfterGetCurrRecord.
// BC versions: 27, 28, 29

page 87365 "LT QS KeyAsc Card"
{
    PageType = Card;
    SourceTable = "LT QR Page Row";
    SourceTableView = sorting(Name);
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
        Log.Add('V:' + Rec.GetView(false));
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
        Log: Codeunit "LT QS View Log";
}

page 87366 "LT QS KeyAsc List"
{
    PageType = List;
    SourceTable = "LT QR Page Row";
    SourceTableView = sorting(Name);
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
        Log.Add('V:' + Rec.GetView(false));
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
        Log: Codeunit "LT QS View Log";
}

page 87367 "LT QS KeyDesc Card"
{
    PageType = Card;
    SourceTable = "LT QR Page Row";
    SourceTableView = sorting(Name) order(descending);
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
        Log.Add('V:' + Rec.GetView(false));
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
        Log: Codeunit "LT QS View Log";
}

page 87368 "LT QS KeyDesc List"
{
    PageType = List;
    SourceTable = "LT QR Page Row";
    SourceTableView = sorting(Name) order(descending);
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
        Log.Add('V:' + Rec.GetView(false));
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
        Log: Codeunit "LT QS View Log";
}

page 87369 "LT QS PkDesc Card"
{
    PageType = Card;
    SourceTable = "LT QR Page Row";
    SourceTableView = sorting("No.") order(descending);
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
        Log.Add('V:' + Rec.GetView(false));
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
        Log: Codeunit "LT QS View Log";
}

page 87370 "LT QS PkDesc List"
{
    PageType = List;
    SourceTable = "LT QR Page Row";
    SourceTableView = sorting("No.") order(descending);
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
        Log.Add('V:' + Rec.GetView(false));
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
        Log: Codeunit "LT QS View Log";
}

page 87371 "LT QS Where Card"
{
    PageType = Card;
    SourceTable = "LT QR Page Row";
    SourceTableView = where("No." = filter('B..D'));
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
        Log.Add('V:' + Rec.GetView(false));
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
        Log: Codeunit "LT QS View Log";
}

page 87372 "LT QS Where List"
{
    PageType = List;
    SourceTable = "LT QR Page Row";
    SourceTableView = where("No." = filter('B..D'));
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
        Log.Add('V:' + Rec.GetView(false));
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
        Log: Codeunit "LT QS View Log";
}

page 87373 "LT QS KeyWhere Card"
{
    PageType = Card;
    SourceTable = "LT QR Page Row";
    SourceTableView = sorting(Name) where("No." = filter('A..C'));
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
        Log.Add('V:' + Rec.GetView(false));
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
        Log: Codeunit "LT QS View Log";
}

page 87374 "LT QS KeyWhere List"
{
    PageType = List;
    SourceTable = "LT QR Page Row";
    SourceTableView = sorting(Name) where("No." = filter('A..C'));
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
        Log.Add('V:' + Rec.GetView(false));
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
        Log: Codeunit "LT QS View Log";
}

codeunit 87375 "LT QS View Log"
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

    // 0: nothing; 1: Get('C'); 2: FindLast; 3: FindFirst then Next; 4: FindFirst; 5: "No." := 'C' without a read; 6: Get('D');
    // 7: Get('A'); 8: SetCurrentKey("No.") then Get('B'); 9: Ascending(not Ascending()) then FindFirst.
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
                Rec.FindFirst();
            5:
                Rec."No." := 'C';
            6:
                Rec.Get('D');
            7:
                Rec.Get('A');
            8:
                begin
                    Rec.SetCurrentKey("No.");
                    Rec.Get('B');
                end;
            9:
                begin
                    Rec.Ascending(not Rec.Ascending());
                    Rec.FindFirst();
                end;
        end;
    end;
}
