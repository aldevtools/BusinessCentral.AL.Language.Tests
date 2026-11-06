// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 96240-96259 (LT WF3 *)
// Probe: from al-runner issue 7194 (host side of 6877, see R6877PartBothLaterRow.al): a ListPart (SubPageLink, UpdatePropagation = Both) over
//   three lines on a Document, a Card and a ListPlus host, and on a ListPlus host without UpdatePropagation. The host's own CurrPage.Update runs
//   from a host field's OnValidate with Update(true), from one with Update(false) and from a host action with Update(); in each case the code
//   first stores new quantities on all lines through a codeunit (line n gets n * factor). The part stands on line 2 (First, Next) or line 3
//   (Last) first. Observed: the part's Line No. and Qty after the host step, the trigger log of host and part, the stored Qty of every line, and
//   which line a following part SetValue of Qty lands on.
// Facts: see the assertions below.
// BC versions: 27+ (tested by the corpus CI matrix)

table 96240 "LT WF3 Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Factor; Decimal) { }
        field(3; FactorB; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 96241 "LT WF3 Doc Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Qty; Decimal) { }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }
}

codeunit 96242 "LT WF3 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}

codeunit 96243 "LT WF3 Spread"
{
    // Line n gets n * Factor.
    procedure Spread(DocNo: Code[20]; Factor: Decimal)
    var
        Line: Record "LT WF3 Doc Line";
    begin
        Line.SetRange("Doc No.", DocNo);
        if Line.FindSet() then
            repeat
                Line.Qty := Line."Line No." / 10000 * Factor;
                Line.Modify();
            until Line.Next() = 0;
    end;
}

page 96244 "LT WF3 Part"
{
    PageType = ListPart;
    SourceTable = "LT WF3 Doc Line";
    InsertAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('Part.OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('Part.AGR(' + Format(Rec."Line No." / 10000) + ')');
    end;
}

page 96245 "LT WF3 Doc Host"
{
    PageType = Document;
    SourceTable = "LT WF3 Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Factor; Rec.Factor)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('Factor.V');
                    Spread.Spread(Rec."No.", Rec.Factor);
                    CurrPage.Update(true);
                    Log.Add('Factor.V.end');
                end;
            }
            field(FactorB; Rec.FactorB)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('FactorB.V');
                    Spread.Spread(Rec."No.", Rec.FactorB);
                    CurrPage.Update(false);
                    Log.Add('FactorB.V.end');
                end;
            }
            part(Lines; "LT WF3 Part")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Double)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('Double.A');
                    Spread.Spread(Rec."No.", 2);
                    CurrPage.Update();
                    Log.Add('Double.A.end');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('Host.OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('Host.AGR');
    end;
}

page 96246 "LT WF3 Card Host"
{
    PageType = Card;
    SourceTable = "LT WF3 Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Factor; Rec.Factor)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('Factor.V');
                    Spread.Spread(Rec."No.", Rec.Factor);
                    CurrPage.Update(true);
                    Log.Add('Factor.V.end');
                end;
            }
            field(FactorB; Rec.FactorB)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('FactorB.V');
                    Spread.Spread(Rec."No.", Rec.FactorB);
                    CurrPage.Update(false);
                    Log.Add('FactorB.V.end');
                end;
            }
            part(Lines; "LT WF3 Part")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Double)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('Double.A');
                    Spread.Spread(Rec."No.", 2);
                    CurrPage.Update();
                    Log.Add('Double.A.end');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('Host.OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('Host.AGR');
    end;
}

page 96247 "LT WF3 Plus Host"
{
    PageType = ListPlus;
    SourceTable = "LT WF3 Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Factor; Rec.Factor)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('Factor.V');
                    Spread.Spread(Rec."No.", Rec.Factor);
                    CurrPage.Update(true);
                    Log.Add('Factor.V.end');
                end;
            }
            field(FactorB; Rec.FactorB)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('FactorB.V');
                    Spread.Spread(Rec."No.", Rec.FactorB);
                    CurrPage.Update(false);
                    Log.Add('FactorB.V.end');
                end;
            }
            part(Lines; "LT WF3 Part")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Double)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('Double.A');
                    Spread.Spread(Rec."No.", 2);
                    CurrPage.Update();
                    Log.Add('Double.A.end');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('Host.OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('Host.AGR');
    end;
}

page 96248 "LT WF3 Plus No Both"
{
    PageType = ListPlus;
    SourceTable = "LT WF3 Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Factor; Rec.Factor)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('Factor.V');
                    Spread.Spread(Rec."No.", Rec.Factor);
                    CurrPage.Update(true);
                    Log.Add('Factor.V.end');
                end;
            }
            field(FactorB; Rec.FactorB)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('FactorB.V');
                    Spread.Spread(Rec."No.", Rec.FactorB);
                    CurrPage.Update(false);
                    Log.Add('FactorB.V.end');
                end;
            }
            part(Lines; "LT WF3 Part")
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
            action(Double)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Spread: Codeunit "LT WF3 Spread";
                    Log: Codeunit "LT WF3 Log";
                begin
                    Log.Add('Double.A');
                    Spread.Spread(Rec."No.", 2);
                    CurrPage.Update();
                    Log.Add('Double.A.end');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('Host.OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Log.Add('Host.AGR');
    end;
}

codeunit 96249 "LT WF3 Host Update"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Doc: Record "LT WF3 Doc";
        Line: Record "LT WF3 Doc Line";
        i: Integer;
    begin
        Doc.DeleteAll();
        Line.DeleteAll();
        Doc."No." := 'D1';
        Doc.Insert();
        for i := 1 to 3 do begin
            Line."Doc No." := 'D1';
            Line."Line No." := i * 10000;
            Line.Insert();
        end;
    end;

    local procedure Stored(): Text
    var
        Line: Record "LT WF3 Doc Line";
        Result: Text;
    begin
        Line.SetRange("Doc No.", 'D1');
        Line.FindSet();
        repeat
            Result += Format(Line.Qty) + ',';
        until Line.Next() = 0;
        exit(Result);
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; PartLine: Text; PartQty: Text)
    var
        Log: Codeunit "LT WF3 Log";
    begin
        Observer.Observe('part line', PartLine);
        Observer.Observe('part qty', PartQty);
        Observer.Observe('log', Log.Get());
        Observer.Observe('stored', Stored());
    end;

    local procedure RunDoc(var Observer: Codeunit "Probe Observer"; PartLine: Integer; Step: Integer)
    var
        P: TestPage "LT WF3 Doc Host";
        Log: Codeunit "LT WF3 Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        if PartLine = 3 then
            P.Lines.Last()
        else begin
            P.Lines.First();
            P.Lines.Next();
        end;
        Log.Reset();
        case Step of
            1:
                P.Factor.SetValue(5);
            2:
                P.FactorB.SetValue(5);
            3:
                P.Double.Invoke();
        end;
        Show(Observer, P.Lines."Line No.".Value(), P.Lines.Qty.Value());
        Log.Reset();
        P.Lines.Qty.SetValue(99);
        Observer.Observe('stored after part SetValue', Stored());
        Observer.Observe('log of part SetValue', Log.Get());
        P.Close();
    end;

    local procedure RunCard(var Observer: Codeunit "Probe Observer"; PartLine: Integer; Step: Integer)
    var
        P: TestPage "LT WF3 Card Host";
        Log: Codeunit "LT WF3 Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        if PartLine = 3 then
            P.Lines.Last()
        else begin
            P.Lines.First();
            P.Lines.Next();
        end;
        Log.Reset();
        case Step of
            1:
                P.Factor.SetValue(5);
            2:
                P.FactorB.SetValue(5);
            3:
                P.Double.Invoke();
        end;
        Show(Observer, P.Lines."Line No.".Value(), P.Lines.Qty.Value());
        Log.Reset();
        P.Lines.Qty.SetValue(99);
        Observer.Observe('stored after part SetValue', Stored());
        Observer.Observe('log of part SetValue', Log.Get());
        P.Close();
    end;

    local procedure RunPlus(var Observer: Codeunit "Probe Observer"; PartLine: Integer; Step: Integer)
    var
        P: TestPage "LT WF3 Plus Host";
        Log: Codeunit "LT WF3 Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        if PartLine = 3 then
            P.Lines.Last()
        else begin
            P.Lines.First();
            P.Lines.Next();
        end;
        Log.Reset();
        case Step of
            1:
                P.Factor.SetValue(5);
            2:
                P.FactorB.SetValue(5);
            3:
                P.Double.Invoke();
        end;
        Show(Observer, P.Lines."Line No.".Value(), P.Lines.Qty.Value());
        Log.Reset();
        P.Lines.Qty.SetValue(99);
        Observer.Observe('stored after part SetValue', Stored());
        Observer.Observe('log of part SetValue', Log.Get());
        P.Close();
    end;

    local procedure RunPlusNoBoth(var Observer: Codeunit "Probe Observer"; PartLine: Integer; Step: Integer)
    var
        P: TestPage "LT WF3 Plus No Both";
        Log: Codeunit "LT WF3 Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        if PartLine = 3 then
            P.Lines.Last()
        else begin
            P.Lines.First();
            P.Lines.Next();
        end;
        Log.Reset();
        case Step of
            1:
                P.Factor.SetValue(5);
            2:
                P.FactorB.SetValue(5);
            3:
                P.Double.Invoke();
        end;
        Show(Observer, P.Lines."Line No.".Value(), P.Lines.Qty.Value());
        Log.Reset();
        P.Lines.Qty.SetValue(99);
        Observer.Observe('stored after part SetValue', Stored());
        Observer.Observe('log of part SetValue', Log.Get());
        P.Close();
    end;

    [Test]
    procedure WF3_Doc_Line2_FieldUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDoc(Observer, 2, 1);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Doc_Line2_FieldUpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDoc(Observer, 2, 2);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Doc_Line2_Action()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDoc(Observer, 2, 3);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Doc_Line3_FieldUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDoc(Observer, 3, 1);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Doc_Line3_FieldUpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDoc(Observer, 3, 2);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Doc_Line3_Action()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDoc(Observer, 3, 3);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Card_Line2_FieldUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 2, 1);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Card_Line2_FieldUpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 2, 2);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Card_Line2_Action()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 2, 3);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Card_Line3_FieldUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 3, 1);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Card_Line3_FieldUpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 3, 2);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Card_Line3_Action()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 3, 3);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Plus_Line2_FieldUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlus(Observer, 2, 1);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Plus_Line2_FieldUpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlus(Observer, 2, 2);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Plus_Line2_Action()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlus(Observer, 2, 3);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Plus_Line3_FieldUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlus(Observer, 3, 1);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Plus_Line3_FieldUpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlus(Observer, 3, 2);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_Plus_Line3_Action()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlus(Observer, 3, 3);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_PlusNoBoth_Line2_FieldUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlusNoBoth(Observer, 2, 1);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_PlusNoBoth_Line2_FieldUpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlusNoBoth(Observer, 2, 2);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_PlusNoBoth_Line2_Action()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlusNoBoth(Observer, 2, 3);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_PlusNoBoth_Line3_FieldUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlusNoBoth(Observer, 3, 1);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_PlusNoBoth_Line3_FieldUpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlusNoBoth(Observer, 3, 2);
        Observer.Finish();
    end;

    [Test]
    procedure WF3_PlusNoBoth_Line3_Action()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlusNoBoth(Observer, 3, 3);
        Observer.Finish();
    end;
}
