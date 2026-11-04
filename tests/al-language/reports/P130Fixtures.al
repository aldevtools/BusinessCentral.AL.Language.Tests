// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-pagehandler-attribute
// Scope: in-scope
// Fixtures used: own tables 73536 and 73537, log codeunit 73538, pages 73539-73543; Probe Observer 69160 is used by the tests, not here
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Shared fixtures of the P130 probes (page handlers, SetSelectionFilter, report columns): not a test codeunit.
// BC versions: 29 (27 and 28 by CI)

table 73536 "LT P130 Item"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { Caption = 'Name caption'; }
        field(3; Qty; Integer) { }
        field(4; Opt; Option)
        {
            OptionMembers = Alpha,Beta,Gamma;
            OptionCaption = 'Alpha cap,Beta cap,Gamma cap';
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByQty; Qty) { }
    }
}

table 73537 "LT P130 Line"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { Caption = 'Line name caption'; }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73538 "LT P130 Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        ModeValue: Integer;

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

    procedure SetMode(NewMode: Integer)
    begin
        ModeValue := NewMode;
    end;

    procedure Mode(): Integer
    begin
        exit(ModeValue);
    end;

    procedure Seed()
    var
        Item: Record "LT P130 Item";
    begin
        Item.DeleteAll();
        Item."No." := 'A';
        Item.Name := 'Alpha';
        Item.Qty := 1;
        Item.Insert();
        Item."No." := 'B';
        Item.Name := 'Beta';
        Item.Qty := 2;
        Item.Insert();
        Item."No." := 'C';
        Item.Name := 'Gamma';
        Item.Qty := 3;
        Item.Insert();
        Entries := '';
        ModeValue := 0;
    end;
}

page 73539 "LT P130 List A"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P130 Item";
    Caption = 'LT P130 List A Caption';
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { }
                field(Name; Rec.Name) { }
            }
        }
    }
}

page 73540 "LT P130 List B"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P130 Item";
    Caption = 'LT P130 List B Caption';
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { }
                field(Qty; Rec.Qty) { }
            }
        }
    }
}

page 73541 "LT P130 Trig List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P130 Item";
    Caption = 'LT P130 Trig List Caption';
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { }
                field(Name; Rec.Name) { }
                field(Qty; Rec.Qty) { }
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('L.OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('L.OnOpenPage filter=' + Rec.GetFilter("No."));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('L.OnAfterGetRecord(' + Rec."No." + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('L.OnAfterGetCurrRecord(' + Rec."No." + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('L.OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('L.OnClosePage');
    end;
}

page 73542 "LT P130 Trig Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P130 Item";
    Caption = 'LT P130 Trig Card Caption';
    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { }
                field(Name; Rec.Name) { }
                field(Qty; Rec.Qty) { }
            }
        }
    }

    trigger OnInit()
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('C.OnInit');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('C.OnOpenPage rec=' + Rec."No.");
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('C.OnAfterGetRecord(' + Rec."No." + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('C.OnAfterGetCurrRecord(' + Rec."No." + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('C.OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT P130 Log";
    begin
        Log.Add('C.OnClosePage');
    end;
}

// A list with one action whose behaviour is chosen by Log.Mode(): SetSelectionFilter into a record that already has a view.
page 73543 "LT P130 Sel List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P130 Item";
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { }
                field(Name; Rec.Name) { }
                field(Qty; Rec.Qty) { }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ActSel)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Sel: Record "LT P130 Item";
                    Log: Codeunit "LT P130 Log";
                begin
                    case Log.Mode() of
                        1:
                            Sel.SetRange("No.", 'B');
                        2:
                            Sel.SetFilter(Qty, '>=2');
                        3:
                            Sel.SetRange("No.", 'A', 'B');
                        4:
                            begin
                                Sel.Get('C');
                                Sel.Mark(true);
                                Sel.MarkedOnly(true);
                            end;
                        5:
                            Sel.SetView('SORTING(Qty) ORDER(Descending) WHERE(Qty=FILTER(>=2))');
                        6:
                            Sel.SetFilter(Name, 'Z*');
                    end;
                    CurrPage.SetSelectionFilter(Sel);
                    Log.Add('mode=' + Format(Log.Mode()) + ' count=' + Format(Sel.Count()) + ' view=' + Sel.GetView(false) + ' marked=' + Format(Sel.MarkedOnly()));
                end;
            }
            action(ActSelRec)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P130 Log";
                begin
                    Log.Add('before rec=' + Rec."No." + ' view=' + Rec.GetView(false));
                    CurrPage.SetSelectionFilter(Rec);
                    Log.Add('after rec=' + Rec."No." + ' count=' + Format(Rec.Count()) + ' view=' + Rec.GetView(false));
                end;
            }
            action(ActSelGlobal)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P130 Log";
                begin
                    CurrPage.SetSelectionFilter(GlobalSel);
                    Log.Add('global count=' + Format(GlobalSel.Count()) + ' view=' + GlobalSel.GetView(false));
                end;
            }
        }
    }

    var
        GlobalSel: Record "LT P130 Item";
}
