// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects tables 92962 - 92963, pages 92965 - 92971, codeunit 92965 (writer Y50)
// Probe: written against the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: gap cycle 5, gap G5-18: TestPage.Caption of a List or Worksheet that has DataCaptionExpression (the pinned neighbours,
//   P113DataCaption.al and WbDataCaptionExpression.al, are Cards; Y37ListCaptionTests.al has lists with DataCaptionFields only).
//   Table T has DataCaptionFields = "No.", Name. Pages: LG (expression = a page global set by a procedure before the run), LF
//   (expression = a procedure that returns Rec.GetFilter(Grp)), LR (expression reads the current row), WG (Worksheet, procedure
//   that formats a global), LD (LG plus page DataCaptionFields = Grp), LP (a ListPart with an expression, inside the card CH).
//   Rows: A1/G1/Alpha, A2/G1/Beta, B1/G2/Gamma.
// BC versions: 27, 28, 29

table 92962 "LT Y50 DC Item"
{
    DataClassification = SystemMetadata;
    DataCaptionFields = "No.", Name;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Grp; Code[10]) { }
        field(3; Name; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92963 "LT Y50 DC Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

page 92965 "LT Y50 DC List Global"
{
    PageType = List;
    SourceTable = "LT Y50 DC Item";
    DataCaptionExpression = CaptionTxt;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetCaption(NewCaption: Text)
    begin
        CaptionTxt := NewCaption;
    end;

    var
        CaptionTxt: Text;
}

page 92966 "LT Y50 DC List Filter"
{
    PageType = List;
    SourceTable = "LT Y50 DC Item";
    DataCaptionExpression = GetFormCaption();
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    local procedure GetFormCaption(): Text[250]
    begin
        if Rec.GetFilter(Grp) <> '' then
            exit(Rec.GetFilter(Grp));
        exit('');
    end;
}

page 92967 "LT Y50 DC List Row"
{
    PageType = List;
    SourceTable = "LT Y50 DC Item";
    DataCaptionExpression = 'Row ' + Rec.Name;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

page 92968 "LT Y50 DC Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y50 DC Item";
    DataCaptionExpression = GetCaption();
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetSubject(NewSubject: Text)
    begin
        Subject := NewSubject;
    end;

    local procedure GetCaption(): Text
    begin
        exit(StrSubstNo('%1 %2', 'Doc', Subject));
    end;

    var
        Subject: Text;
}

page 92969 "LT Y50 DC List Both"
{
    PageType = List;
    SourceTable = "LT Y50 DC Item";
    DataCaptionExpression = CaptionTxt;
    DataCaptionFields = Grp;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetCaption(NewCaption: Text)
    begin
        CaptionTxt := NewCaption;
    end;

    var
        CaptionTxt: Text;
}

page 92970 "LT Y50 DC Part"
{
    PageType = ListPart;
    SourceTable = "LT Y50 DC Item";
    DataCaptionExpression = 'Part ' + Rec.Name;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

page 92971 "LT Y50 DC Host Card"
{
    PageType = Card;
    SourceTable = "LT Y50 DC Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code)
            {
                ApplicationArea = All;
            }
            part(Lines; "LT Y50 DC Part")
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 92965 "LT Y50 DC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Item: Record "LT Y50 DC Item";
        Host: Record "LT Y50 DC Host";
    begin
        Item.DeleteAll();
        Host.DeleteAll();
        AddItem('A1', 'G1', 'Alpha');
        AddItem('A2', 'G1', 'Beta');
        AddItem('B1', 'G2', 'Gamma');
        Host.Code := 'H1';
        Host.Insert();
    end;

    local procedure AddItem(No: Code[20]; Grp: Code[10]; Name: Text[30])
    var
        Item: Record "LT Y50 DC Item";
    begin
        Item."No." := No;
        Item.Grp := Grp;
        Item.Name := Name;
        Item.Insert();
    end;

    // T1, the Translation shape: the global set by a procedure before Run.
    [Test]
    procedure G518_List_GlobalExpr_Set()
    var
        Pg: Page "LT Y50 DC List Global";
        TP: TestPage "LT Y50 DC List Global";
    begin
        Seed();
        Pg.SetCaption('X1');
        TP.Trap();
        Pg.Run();
        Observer.Observe('open', TP.Caption() + '|' + TP."No.".Value());
        TP.Next();
        Observer.Observe('next', TP.Caption() + '|' + TP."No.".Value());
        TP.GoToKey('B1');
        Observer.Observe('gotokey', TP.Caption() + '|' + TP."No.".Value());
        TP.Close();
        Observer.Finish();
    end;

    // T2: the same page run without SetCaption (empty expression).
    [Test]
    procedure G518_List_GlobalExpr_Empty()
    var
        Pg: Page "LT Y50 DC List Global";
        TP: TestPage "LT Y50 DC List Global";
    begin
        Seed();
        TP.Trap();
        Pg.Run();
        Observer.Observe('open', TP.Caption() + '|' + TP."No.".Value());
        TP.Close();
        Observer.Finish();
    end;

    // T3, the Dimension Value List shape: the expression returns the Grp filter of Rec.
    [Test]
    procedure G518_List_FilterExpr()
    var
        Item: Record "LT Y50 DC Item";
        Pg: Page "LT Y50 DC List Filter";
        Pg2: Page "LT Y50 DC List Filter";
        TP: TestPage "LT Y50 DC List Filter";
    begin
        Seed();
        Item.SetRange(Grp, 'G1');
        Pg.SetTableView(Item);
        TP.Trap();
        Pg.Run();
        Observer.Observe('filtered', TP.Caption() + '|' + TP."No.".Value());
        TP.Close();
        TP.Trap();
        Pg2.Run();
        Observer.Observe('no filter', TP.Caption() + '|' + TP."No.".Value());
        TP.Filter.SetFilter(Grp, 'G2');
        Observer.Observe('testpage filter', TP.Caption() + '|' + TP."No.".Value());
        TP.Close();
        Observer.Finish();
    end;

    // T4, the Production Journal shape: a Worksheet whose expression formats a global set before RunModal.
    [Test]
    [HandlerFunctions('WorksheetHandler')]
    procedure G518_Worksheet_ProcExpr()
    var
        Pg: Page "LT Y50 DC Worksheet";
    begin
        Seed();
        Pg.SetSubject('S1');
        Pg.RunModal();
        Observer.Finish();
    end;

    // T5: the expression reads the current row; first row, after Next, after Last, and on an empty table.
    [Test]
    procedure G518_List_RowExpr()
    var
        Item: Record "LT Y50 DC Item";
        TP: TestPage "LT Y50 DC List Row";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('open', TP.Caption() + '|' + TP."No.".Value());
        TP.Next();
        Observer.Observe('next', TP.Caption() + '|' + TP."No.".Value());
        TP.Last();
        Observer.Observe('last', TP.Caption() + '|' + TP."No.".Value());
        TP.Close();
        Item.DeleteAll();
        TP.OpenView();
        Observer.Observe('empty', TP.Caption() + '|' + TP."No.".Value());
        TP.Close();
        Observer.Finish();
    end;

    // T6: an expression and page DataCaptionFields together, Rec filtered on Grp.
    [Test]
    procedure G518_List_ExprAndDataCaptionFields()
    var
        Item: Record "LT Y50 DC Item";
        Pg: Page "LT Y50 DC List Both";
        Pg2: Page "LT Y50 DC List Both";
        TP: TestPage "LT Y50 DC List Both";
    begin
        Seed();
        Item.SetRange(Grp, 'G1');
        Pg.SetTableView(Item);
        Pg.SetCaption('X1');
        TP.Trap();
        Pg.Run();
        Observer.Observe('filtered', TP.Caption() + '|' + TP."No.".Value());
        TP.Close();
        Pg2.SetCaption('X1');
        TP.Trap();
        Pg2.Run();
        Observer.Observe('no filter', TP.Caption() + '|' + TP."No.".Value());
        TP.Close();
        Observer.Finish();
    end;

    // T7: a list part with an expression inside a card.
    [Test]
    procedure G518_ListPart_Expr()
    var
        TP: TestPage "LT Y50 DC Host Card";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('card', TP.Caption());
        Observer.Observe('part', TP.Lines.Caption() + '|' + TP.Lines."No.".Value());
        TP.Close();
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure WorksheetHandler(var P: TestPage "LT Y50 DC Worksheet")
    begin
        Observer.Observe('first read', P.Caption() + '|' + P."No.".Value());
        Observer.Observe('second read', P.Caption());
        P.Next();
        Observer.Observe('after next', P.Caption() + '|' + P."No.".Value());
    end;
}
