// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-visible-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 91750 - 91760 (writer Y17a)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: gap cycle 1, gap G2. An expression control over a field of a page-global record (TotalLine.Amount, the Sales Invoice
//   Subform shape) in a linked ListPart, and a function control in a Worksheet over a temporary table (the Item Tracking Lines
//   shape). The part's OnFindRecord clears TotalLine, its OnAfterGetCurrRecord recomputes it from the database. The tests record
//   which page triggers run, and what the controls show, after TestField.Visible, TestAction.Visible, TestPart.Next / First,
//   TestAction.Invoke of a card action that calls a part procedure, an action that inserts into the temporary Rec, and DrillDown.
// BC versions: 27, 28, 29

table 91750 "LT Y17 RF Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 91751 "LT Y17 RF Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; Disc; Decimal) { }
    }
    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }
}

page 91752 "LT Y17 RF Lines"
{
    PageType = ListPart;
    SourceTable = "LT Y17 RF Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
            }
            group(Totals)
            {
                field(TotalAmt; TotalLine.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Total';
                    Editable = false;
                }
                field(TotalCount; LineCount)
                {
                    ApplicationArea = All;
                    Caption = 'Count';
                    Editable = false;
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Log.Add('find');
        Clear(TotalLine);
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('agr ' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    var
        SumLine: Record "LT Y17 RF Line";
    begin
        Log.Add('agcr ' + Format(Rec."Line No."));
        SumLine.SetRange("Doc No.", Rec."Doc No.");
        SumLine.CalcSums(Amount);
        TotalLine.Amount := SumLine.Amount;
        LineCount := SumLine.Count();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Last: Record "LT Y17 RF Line";
    begin
        Last.SetRange("Doc No.", Rec."Doc No.");
        if Last.FindLast() then
            Rec."Line No." := Last."Line No." + 10000
        else
            Rec."Line No." := 10000;
        Log.Add('new ' + Format(Rec."Line No."));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('ins ' + Format(Rec."Line No."));
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('mod ' + Format(Rec."Line No."));
        exit(true);
    end;

    procedure AddDiscount()
    var
        Upd: Record "LT Y17 RF Line";
    begin
        Log.Add('proc');
        Upd.SetRange("Doc No.", Rec."Doc No.");
        if Upd.FindSet() then
            repeat
                Upd.Amount := Upd.Amount - 1;
                Upd.Modify();
            until Upd.Next() = 0;
    end;

    var
        TotalLine: Record "LT Y17 RF Line";
        Log: Codeunit "LT Y17 RF Log";
        LineCount: Integer;
}

page 91753 "LT Y17 RF Card"
{
    PageType = Document;
    SourceTable = "LT Y17 RF Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
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
            part(Lines; "LT Y17 RF Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CalcDisc)
            {
                ApplicationArea = All;
                Caption = 'Calc Disc';
                trigger OnAction()
                begin
                    CurrPage.Lines.Page.AddDiscount();
                end;
            }
            action(CalcDiscUpd)
            {
                ApplicationArea = All;
                Caption = 'Calc Disc Upd';
                trigger OnAction()
                begin
                    CurrPage.Lines.Page.AddDiscount();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('card agcr');
    end;

    var
        Log: Codeunit "LT Y17 RF Log";
}

table 91754 "LT Y17 RF Track"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Lot; Code[20]) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

page 91755 "LT Y17 RF Tracking"
{
    PageType = Worksheet;
    SourceTable = "LT Y17 RF Track";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Lot; Rec.Lot)
                {
                    ApplicationArea = All;
                }
                field(Avail; IsAvail(Rec))
                {
                    ApplicationArea = All;
                    Caption = 'Avail';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AssignLot)
            {
                ApplicationArea = All;
                Caption = 'Assign Lot';
                trigger OnAction()
                begin
                    Log.Add('action');
                    Rec.Init();
                    Rec."Entry No." := 2;
                    Rec.Lot := 'L1';
                    Rec.Insert();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec."Entry No." := 1;
        Rec.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('agr ' + Format(Rec."Entry No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr ' + Format(Rec."Entry No."));
    end;

    local procedure IsAvail(Track: Record "LT Y17 RF Track"): Boolean
    begin
        Log.Add('avail ' + Format(Track."Entry No."));
        exit(Track.Lot <> '');
    end;

    var
        Log: Codeunit "LT Y17 RF Log";
}

codeunit 91756 "LT Y17 RF Log"
{
    SingleInstance = true;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure Bump()
    begin
        Counter += 1;
    end;

    procedure ReadCounter(): Integer
    begin
        Add('counter');
        exit(Counter);
    end;

    procedure ResetCounter()
    begin
        Counter := 0;
    end;

    var
        Entries: Text;
        Counter: Integer;
}

page 91758 "LT Y17 RF Fact"
{
    PageType = CardPart;
    SourceTable = "LT Y17 RF Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Counter; CounterValue())
            {
                ApplicationArea = All;
                Caption = 'Counter';
                trigger OnDrillDown()
                begin
                    Log.Add('drill');
                    Page.Run(Page::"LT Y17 RF Line List");
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('fact agr');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('fact agcr');
    end;

    local procedure CounterValue(): Integer
    begin
        exit(Log.ReadCounter());
    end;

    var
        Log: Codeunit "LT Y17 RF Log";
}

page 91759 "LT Y17 RF Line List"
{
    PageType = List;
    SourceTable = "LT Y17 RF Line";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

page 91760 "LT Y17 RF Card Fact"
{
    PageType = Card;
    SourceTable = "LT Y17 RF Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
            }
        }
        area(FactBoxes)
        {
            part(Fact; "LT Y17 RF Fact")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('card agcr');
    end;

    var
        Log: Codeunit "LT Y17 RF Log";
}

codeunit 91757 "LT Y17 RF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y17 RF Log";

    local procedure Seed()
    var
        Doc: Record "LT Y17 RF Doc";
        Line: Record "LT Y17 RF Line";
    begin
        Line.DeleteAll();
        Doc.DeleteAll();
        Doc."No." := 'D1';
        Doc.Name := 'Doc one';
        Doc.Insert();
        AddLine(10000, 10);
        AddLine(20000, 5);
        Log.Take();
        Log.ResetCounter();
    end;

    local procedure AddLine(LineNo: Integer; Amount: Decimal)
    var
        Line: Record "LT Y17 RF Line";
    begin
        Line."Doc No." := 'D1';
        Line."Line No." := LineNo;
        Line.Amount := Amount;
        Line.Insert();
    end;

    local procedure SetAmount(LineNo: Integer; Amount: Decimal)
    var
        Line: Record "LT Y17 RF Line";
    begin
        Line.Get('D1', LineNo);
        Line.Amount := Amount;
        Line.Modify();
    end;

    local procedure StoredLines(): Text
    var
        Line: Record "LT Y17 RF Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Doc No." + '/' + Format(Line."Line No.") + '/' + Format(Line.Amount, 0, 9) + ';';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure Totals(var Card: TestPage "LT Y17 RF Card"): Text
    begin
        exit(Card.Lines.TotalAmt.Value() + '/' + Card.Lines.TotalCount.Value());
    end;

    // V1: TestField.Visible of a part control, after the database changed under the part.
    [Test]
    procedure RF_Visible_PartControl()
    var
        Card: TestPage "LT Y17 RF Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Card.GoToKey('D1');
        Observer.Observe('gotokey log', Log.Take());
        Observer.Observe('totals before', Totals(Card));
        Observer.Observe('read log', Log.Take());
        SetAmount(10000, 100);
        Observer.Observe('visible', Format(Card.Lines.Amount.Visible(), 0, 9));
        Observer.Observe('visible log', Log.Take());
        Observer.Observe('totals after', Totals(Card));
        Observer.Observe('row after', Card.Lines."Line No.".Value() + '/' + Card.Lines.Amount.Value());
        Observer.Observe('after log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    // V2: TestField.Visible of a card control, and TestAction.Visible.
    [Test]
    procedure RF_Visible_CardControl()
    var
        Card: TestPage "LT Y17 RF Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Observer.Observe('totals before', Totals(Card));
        Log.Take();
        SetAmount(10000, 100);
        Observer.Observe('name visible', Format(Card.Name.Visible(), 0, 9));
        Observer.Observe('name visible log', Log.Take());
        Observer.Observe('totals after name', Totals(Card));
        Observer.Observe('read log', Log.Take());
        SetAmount(20000, 50);
        Observer.Observe('action visible', Format(Card.CalcDisc.Visible(), 0, 9));
        Observer.Observe('action visible log', Log.Take());
        Observer.Observe('totals after action', Totals(Card));
        Observer.Observe('read log 2', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    // N1: the subform shape: Last, Next to a new row, SetValue, Next saves it.
    [Test]
    procedure RF_PartNext_NewLineSaved()
    var
        Card: TestPage "LT Y17 RF Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Observer.Observe('totals open', Totals(Card));
        Log.Take();
        Observer.Observe('last', Format(Card.Lines.Last(), 0, 9) + '/' + Card.Lines."Line No.".Value());
        Observer.Observe('last log', Log.Take());
        Observer.Observe('next new', Format(Card.Lines.Next(), 0, 9) + '/' + Card.Lines."Line No.".Value());
        Observer.Observe('next new log', Log.Take());
        Card.Lines.Amount.SetValue(7);
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('setvalue row', Card.Lines."Line No.".Value() + '/' + Card.Lines.Amount.Value());
        Observer.Observe('next save', Format(Card.Lines.Next(), 0, 9) + '/' + Card.Lines."Line No.".Value());
        Observer.Observe('next save log', Log.Take());
        Observer.Observe('totals after', Totals(Card));
        Observer.Observe('totals log', Log.Take());
        Observer.Observe('stored', StoredLines());
        Card.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored after close', StoredLines());
        Observer.Finish();
    end;

    // N2: Next over existing rows after the database changed.
    [Test]
    procedure RF_PartNext_ExistingRows()
    var
        Card: TestPage "LT Y17 RF Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Observer.Observe('first', Format(Card.Lines.First(), 0, 9) + '/' + Card.Lines."Line No.".Value());
        Observer.Observe('totals first', Totals(Card));
        Log.Take();
        SetAmount(20000, 50);
        Observer.Observe('next', Format(Card.Lines.Next(), 0, 9) + '/' + Card.Lines."Line No.".Value() + '/' + Card.Lines.Amount.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('totals next', Totals(Card));
        Observer.Observe('totals log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    // I1: the CalculateInvoiceDiscount shape: a card action calls a part procedure that writes the lines; no CurrPage.Update.
    [Test]
    procedure RF_CardAction_CallsPartProcedure()
    var
        Card: TestPage "LT Y17 RF Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Observer.Observe('totals before', Totals(Card));
        Observer.Observe('row before', Card.Lines."Line No.".Value() + '/' + Card.Lines.Amount.Value());
        Log.Take();
        Card.CalcDisc.Invoke();
        Observer.Observe('invoke log', Log.Take());
        Observer.Observe('totals after', Totals(Card));
        Observer.Observe('row after', Card.Lines."Line No.".Value() + '/' + Card.Lines.Amount.Value());
        Observer.Observe('read log', Log.Take());
        Observer.Observe('stored', StoredLines());
        Card.Close();
        Observer.Finish();
    end;

    // I3: as I1, the action then calls CurrPage.Update(false).
    [Test]
    procedure RF_CardAction_CallsPartProcedure_Update()
    var
        Card: TestPage "LT Y17 RF Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Observer.Observe('totals before', Totals(Card));
        Observer.Observe('row before', Card.Lines."Line No.".Value() + '/' + Card.Lines.Amount.Value());
        Log.Take();
        Card.CalcDiscUpd.Invoke();
        Observer.Observe('invoke log', Log.Take());
        Observer.Observe('totals after', Totals(Card));
        Observer.Observe('row after', Card.Lines."Line No.".Value() + '/' + Card.Lines.Amount.Value());
        Observer.Observe('read log', Log.Take());
        Observer.Observe('stored', StoredLines());
        Card.Close();
        Observer.Finish();
    end;

    // F1: First on the linked part after the database changed.
    [Test]
    procedure RF_PartFirst_Linked()
    var
        Card: TestPage "LT Y17 RF Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Observer.Observe('totals before', Totals(Card));
        Log.Take();
        SetAmount(10000, 100);
        Observer.Observe('first', Format(Card.Lines.First(), 0, 9) + '/' + Card.Lines."Line No.".Value() + '/' + Card.Lines.Amount.Value());
        Observer.Observe('first log', Log.Take());
        Observer.Observe('totals after', Totals(Card));
        Observer.Observe('read log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    // I2: the Item Tracking Lines shape: the page's own action inserts into the temporary Rec, no CurrPage.Update.
    [Test]
    procedure RF_WorksheetAction_InsertsRow()
    var
        Tracking: TestPage "LT Y17 RF Tracking";
    begin
        Seed();
        Tracking.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('open', Tracking."Entry No.".Value() + '/' + Tracking.Avail.Value());
        Observer.Observe('open read log', Log.Take());
        Tracking.AssignLot.Invoke();
        Observer.Observe('invoke log', Log.Take());
        Observer.Observe('after invoke', Tracking."Entry No.".Value() + '/' + Tracking.Lot.Value() + '/' + Tracking.Avail.Value());
        Observer.Observe('after invoke read log', Log.Take());
        Observer.Observe('first', Format(Tracking.First(), 0, 9) + '/' + Tracking."Entry No.".Value() + '/' + Tracking.Avail.Value());
        Observer.Observe('first log', Log.Take());
        Observer.Observe('next', Format(Tracking.Next(), 0, 9) + '/' + Tracking."Entry No.".Value() + '/' + Tracking.Avail.Value());
        Observer.Observe('next log', Log.Take());
        Tracking.Close();
        Observer.Finish();
    end;

    // D1: DrillDown of a FactBox function control whose value reads a counter the test changed.
    [Test]
    [HandlerFunctions('LineListHandler')]
    procedure RF_DrillDown_CardPartFunction()
    var
        Card: TestPage "LT Y17 RF Card Fact";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Observer.Observe('open log', Log.Take());
        Observer.Observe('counter before', Card.Fact.Counter.Value());
        Observer.Observe('read log', Log.Take());
        Log.Bump();
        Card.Fact.Counter.DrillDown();
        Observer.Observe('drilldown log', Log.Take());
        Observer.Observe('counter after', Card.Fact.Counter.Value());
        Observer.Observe('read log 2', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    [PageHandler]
    procedure LineListHandler(var List: TestPage "LT Y17 RF Line List")
    begin
        Log.Add('handler');
        List.Close();
    end;
}
