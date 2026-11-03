// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 81151-81152, pages 81151-81153, test codeunit 81161
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: a host card shows the same ListPart in five part controls: Editable = <page variable>, Enabled = <page variable>, both (as page 41
//   "Sales Quote" part SalesLines: Editable = IsSalesLinesEditable; Enabled = IsSalesLinesEditable), the literal Editable = false, and no property.
//   The variable comes from the header row in OnAfterGetRecord (Flag false on header H1, true on H2). Per part: the subpage field's Editable()
//   and Enabled(), and whether SetValue on it raises (error text and code) and what is stored. Also a ListPart whose repeater and field have
//   Editable = <expression> of the subpage (from the line row), shown in a part control with no Editable property.
//   Microsoft's ERM Sales Quotes test BlankSalesQuoteLinesUneditable (codeunit 134379) expects SalesQuote.SalesLines.Description.Editable() = false.
// Measured (BC 27.5, 28.5, 29.0): the part control's Editable expression reaches the subpage field's Editable() (false while the variable is
//   false, true while true, and it follows the host when it moves); its Enabled expression reaches Enabled() the same way; Editable and Enabled are
//   independent. SetValue through the part does not raise in any of these cases, not even with the literal Editable = false or a subpage field whose
//   own Editable() is false: the value is written and stored. A page's own Editable property takes no expression (must-not-compile 1290, AL0220).
// Corpus issue: StefanMaron/BusinessCentral.AL.Language.Tests#660 item 2.
// BC versions: all (CI)

table 81151 "LT BE Part Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Flag; Boolean) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 81152 "LT BE Part Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Head; Code[10]) { }
        field(2; LineNo; Integer) { }
        field(3; Description; Text[50]) { }
        field(4; Locked; Boolean) { }
    }

    keys { key(PK; Head, LineNo) { Clustered = true; } }
}

page 81151 "LT BE Part Sub"
{
    PageType = ListPart;
    SourceTable = "LT BE Part Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 81153 "LT BE Part Sub Expr"
{
    PageType = ListPart;
    SourceTable = "LT BE Part Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                Editable = RowEditable;

                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Locked; Rec.Locked)
                {
                    ApplicationArea = All;
                    Editable = RowEditable;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RowEditable := not Rec.Locked;
    end;

    var
        RowEditable: Boolean;
}

page 81152 "LT BE Part Host"
{
    PageType = Card;
    SourceTable = "LT BE Part Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(EdLines; "LT BE Part Sub")
            {
                ApplicationArea = All;
                SubPageLink = Head = field("No.");
                Editable = LinesFlag;
            }
            part(EnLines; "LT BE Part Sub")
            {
                ApplicationArea = All;
                SubPageLink = Head = field("No.");
                Enabled = LinesFlag;
            }
            part(BothLines; "LT BE Part Sub")
            {
                ApplicationArea = All;
                SubPageLink = Head = field("No.");
                Editable = LinesFlag;
                Enabled = LinesFlag;
            }
            part(LitLines; "LT BE Part Sub")
            {
                ApplicationArea = All;
                SubPageLink = Head = field("No.");
                Editable = false;
            }
            part(PlainLines; "LT BE Part Sub")
            {
                ApplicationArea = All;
                SubPageLink = Head = field("No.");
            }
            part(ExprLines; "LT BE Part Sub Expr")
            {
                ApplicationArea = All;
                SubPageLink = Head = field("No.");
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LinesFlag := Rec.Flag;
    end;

    var
        LinesFlag: Boolean;
}

codeunit 81161 "LT BE Part Editable Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT BE Part Head";
        Line: Record "LT BE Part Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        AddHead('H1', false);
        AddHead('H2', true);
        AddLine('H1', false);
        AddLine('H2', false);
    end;

    local procedure AddHead(No: Code[10]; Flag: Boolean)
    var
        Head: Record "LT BE Part Head";
    begin
        Head.Init();
        Head."No." := No;
        Head.Flag := Flag;
        Head.Insert();
    end;

    local procedure AddLine(HeadNo: Code[10]; Locked: Boolean)
    var
        Line: Record "LT BE Part Line";
    begin
        Line.Init();
        Line.Head := HeadNo;
        Line.LineNo := 10000;
        Line.Description := 'Start';
        Line.Locked := Locked;
        Line.Insert();
    end;

    local procedure Stored(HeadNo: Code[10]): Text
    var
        Line: Record "LT BE Part Line";
    begin
        Line.Get(HeadNo, 10000);
        exit(Line.Description);
    end;

    local procedure Open(var TP: TestPage "LT BE Part Host"; HeadNo: Code[10])
    var
        Head: Record "LT BE Part Head";
    begin
        TP.OpenEdit();
        Head.Get(HeadNo);
        TP.GoToRecord(Head);
    end;

    local procedure ObserveStates(var Observer: Codeunit "Probe Observer"; var TP: TestPage "LT BE Part Host"; Tag: Text)
    begin
        Observer.Observe(Tag + '-ed-editable', Format(TP.EdLines.Description.Editable()));
        Observer.Observe(Tag + '-ed-enabled', Format(TP.EdLines.Description.Enabled()));
        Observer.Observe(Tag + '-en-editable', Format(TP.EnLines.Description.Editable()));
        Observer.Observe(Tag + '-en-enabled', Format(TP.EnLines.Description.Enabled()));
        Observer.Observe(Tag + '-both-editable', Format(TP.BothLines.Description.Editable()));
        Observer.Observe(Tag + '-both-enabled', Format(TP.BothLines.Description.Enabled()));
        Observer.Observe(Tag + '-lit-editable', Format(TP.LitLines.Description.Editable()));
        Observer.Observe(Tag + '-lit-enabled', Format(TP.LitLines.Description.Enabled()));
        Observer.Observe(Tag + '-plain-editable', Format(TP.PlainLines.Description.Editable()));
        Observer.Observe(Tag + '-plain-enabled', Format(TP.PlainLines.Description.Enabled()));
    end;

    [TryFunction]
    local procedure TrySet(var TP: TestPage "LT BE Part Host"; PartName: Text; NewValue: Text)
    begin
        case PartName of
            'ed':
                TP.EdLines.Description.SetValue(NewValue);
            'en':
                TP.EnLines.Description.SetValue(NewValue);
            'both':
                TP.BothLines.Description.SetValue(NewValue);
            'lit':
                TP.LitLines.Description.SetValue(NewValue);
            'plain':
                TP.PlainLines.Description.SetValue(NewValue);
        end;
    end;

    local procedure ValueOf(var TP: TestPage "LT BE Part Host"; PartName: Text): Text
    begin
        case PartName of
            'ed':
                exit(TP.EdLines.Description.Value());
            'en':
                exit(TP.EnLines.Description.Value());
            'both':
                exit(TP.BothLines.Description.Value());
            'lit':
                exit(TP.LitLines.Description.Value());
            'plain':
                exit(TP.PlainLines.Description.Value());
        end;
    end;

    [TryFunction]
    local procedure TryClose(var TP: TestPage "LT BE Part Host")
    begin
        TP.Close();
    end;

    local procedure SetCase(var Observer: Codeunit "Probe Observer"; HeadNo: Code[10]; PartName: Text)
    var
        TP: TestPage "LT BE Part Host";
        Tag: Text;
        Ok: Boolean;
    begin
        Seed();
        Open(TP, HeadNo);
        Tag := HeadNo + '-' + PartName;
        Ok := TrySet(TP, PartName, 'Changed');
        Observer.Observe(Tag + '-set', Format(Ok));
        if not Ok then
            Observer.ObserveError(Tag + '-set-err');
        Observer.Observe(Tag + '-value', ValueOf(TP, PartName));
        if not TryClose(TP) then
            Observer.ObserveError(Tag + '-close');
        Observer.Observe(Tag + '-stored', Stored(HeadNo));
    end;

    [Test]
    procedure PartEditableExpr_FlagFalse_ControlStates()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT BE Part Host";
    begin
        Seed();
        Open(TP, 'H1');
        Observer.Observe('pageEditable', Format(TP.Editable()));
        ObserveStates(Observer, TP, 'H1');
        TP.Close();
        Observer.Expect('pageEditable', 'Yes');
        Observer.Expect('H1-ed-editable', 'No');
        Observer.Expect('H1-ed-enabled', 'Yes');
        Observer.Expect('H1-en-editable', 'Yes');
        Observer.Expect('H1-en-enabled', 'No');
        Observer.Expect('H1-both-editable', 'No');
        Observer.Expect('H1-both-enabled', 'No');
        Observer.Expect('H1-lit-editable', 'No');
        Observer.Expect('H1-lit-enabled', 'Yes');
        Observer.Expect('H1-plain-editable', 'Yes');
        Observer.Expect('H1-plain-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PartEditableExpr_FlagTrue_ControlStates()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT BE Part Host";
    begin
        Seed();
        Open(TP, 'H2');
        ObserveStates(Observer, TP, 'H2');
        TP.Close();
        Observer.Expect('H2-ed-editable', 'Yes');
        Observer.Expect('H2-ed-enabled', 'Yes');
        Observer.Expect('H2-en-editable', 'Yes');
        Observer.Expect('H2-en-enabled', 'Yes');
        Observer.Expect('H2-both-editable', 'Yes');
        Observer.Expect('H2-both-enabled', 'Yes');
        Observer.Expect('H2-lit-editable', 'No');
        Observer.Expect('H2-lit-enabled', 'Yes');
        Observer.Expect('H2-plain-editable', 'Yes');
        Observer.Expect('H2-plain-enabled', 'Yes');
        Observer.Verify();
    end;

    // The flag changes when the host moves from H1 (false) to H2 (true) and back.
    [Test]
    procedure PartEditableExpr_HostMoves_ControlStatesFollow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT BE Part Host";
    begin
        Seed();
        Open(TP, 'H1');
        Observer.Observe('at', TP."No.".Value());
        TP.Next();
        Observer.Observe('next', TP."No.".Value());
        Observer.Observe('next-ed-editable', Format(TP.EdLines.Description.Editable()));
        Observer.Observe('next-both-editable', Format(TP.BothLines.Description.Editable()));
        Observer.Observe('next-both-enabled', Format(TP.BothLines.Description.Enabled()));
        TP.Previous();
        Observer.Observe('prev', TP."No.".Value());
        Observer.Observe('prev-ed-editable', Format(TP.EdLines.Description.Editable()));
        Observer.Observe('prev-both-editable', Format(TP.BothLines.Description.Editable()));
        Observer.Observe('prev-both-enabled', Format(TP.BothLines.Description.Enabled()));
        TP.Close();
        Observer.Expect('at', 'H1');
        Observer.Expect('next', 'H2');
        Observer.Expect('next-ed-editable', 'Yes');
        Observer.Expect('next-both-editable', 'Yes');
        Observer.Expect('next-both-enabled', 'Yes');
        Observer.Expect('prev', 'H1');
        Observer.Expect('prev-ed-editable', 'No');
        Observer.Expect('prev-both-editable', 'No');
        Observer.Expect('prev-both-enabled', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure PartEditableExpr_FlagFalse_SetValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetCase(Observer, 'H1', 'ed');
        SetCase(Observer, 'H1', 'en');
        SetCase(Observer, 'H1', 'both');
        SetCase(Observer, 'H1', 'lit');
        SetCase(Observer, 'H1', 'plain');
        Observer.Expect('H1-ed-set', 'Yes');
        Observer.Expect('H1-ed-value', 'Changed');
        Observer.Expect('H1-ed-stored', 'Changed');
        Observer.Expect('H1-en-set', 'Yes');
        Observer.Expect('H1-en-value', 'Changed');
        Observer.Expect('H1-en-stored', 'Changed');
        Observer.Expect('H1-both-set', 'Yes');
        Observer.Expect('H1-both-value', 'Changed');
        Observer.Expect('H1-both-stored', 'Changed');
        Observer.Expect('H1-lit-set', 'Yes');
        Observer.Expect('H1-lit-value', 'Changed');
        Observer.Expect('H1-lit-stored', 'Changed');
        Observer.Expect('H1-plain-set', 'Yes');
        Observer.Expect('H1-plain-value', 'Changed');
        Observer.Expect('H1-plain-stored', 'Changed');
        Observer.Verify();
    end;

    [Test]
    procedure PartEditableExpr_FlagTrue_SetValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetCase(Observer, 'H2', 'ed');
        SetCase(Observer, 'H2', 'en');
        SetCase(Observer, 'H2', 'both');
        SetCase(Observer, 'H2', 'lit');
        SetCase(Observer, 'H2', 'plain');
        Observer.Expect('H2-ed-set', 'Yes');
        Observer.Expect('H2-ed-value', 'Changed');
        Observer.Expect('H2-ed-stored', 'Changed');
        Observer.Expect('H2-en-set', 'Yes');
        Observer.Expect('H2-en-value', 'Changed');
        Observer.Expect('H2-en-stored', 'Changed');
        Observer.Expect('H2-both-set', 'Yes');
        Observer.Expect('H2-both-value', 'Changed');
        Observer.Expect('H2-both-stored', 'Changed');
        Observer.Expect('H2-lit-set', 'Yes');
        Observer.Expect('H2-lit-value', 'Changed');
        Observer.Expect('H2-lit-stored', 'Changed');
        Observer.Expect('H2-plain-set', 'Yes');
        Observer.Expect('H2-plain-value', 'Changed');
        Observer.Expect('H2-plain-stored', 'Changed');
        Observer.Verify();
    end;

    // The subpage's own repeater and field say Editable = RowEditable (not Locked, set in its OnAfterGetRecord); the line of H1 is
    // unlocked, the line of H2 is locked.
    local procedure ExprCase(var Observer: Codeunit "Probe Observer"; HeadNo: Code[10])
    var
        Line: Record "LT BE Part Line";
        TP: TestPage "LT BE Part Host";
        Ok: Boolean;
    begin
        Seed();
        Line.Get('H2', 10000);
        Line.Locked := true;
        Line.Modify();
        Open(TP, HeadNo);
        Observer.Observe('desc-editable', Format(TP.ExprLines.Description.Editable()));
        Observer.Observe('desc-enabled', Format(TP.ExprLines.Description.Enabled()));
        Observer.Observe('locked-editable', Format(TP.ExprLines.Locked.Editable()));
        Ok := TrySetExpr(TP, 'Changed');
        Observer.Observe('set', Format(Ok));
        if not Ok then
            Observer.ObserveError('set-err');
        if not TryClose(TP) then
            Observer.ObserveError('close');
        Observer.Observe('stored', Stored(HeadNo));
    end;

    [Test]
    procedure SubpageEditableExpr_UnlockedLine()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExprCase(Observer, 'H1');
        Observer.Expect('desc-editable', 'Yes');
        Observer.Expect('desc-enabled', 'Yes');
        Observer.Expect('locked-editable', 'Yes');
        Observer.Expect('set', 'Yes');
        Observer.Expect('stored', 'Changed');
        Observer.Verify();
    end;

    [Test]
    procedure SubpageEditableExpr_LockedLine()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExprCase(Observer, 'H2');
        Observer.Expect('desc-editable', 'No');
        Observer.Expect('desc-enabled', 'Yes');
        Observer.Expect('locked-editable', 'No');
        Observer.Expect('set', 'Yes');
        Observer.Expect('stored', 'Changed');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetExpr(var TP: TestPage "LT BE Part Host"; NewValue: Text)
    begin
        TP.ExprLines.Description.SetValue(NewValue);
    end;
}
