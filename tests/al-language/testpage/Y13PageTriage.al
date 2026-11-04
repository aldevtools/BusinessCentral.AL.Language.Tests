// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained enums 91630, tables 91631-91633 and 91640-91641, pages 91634-91636 and 91642-91643,
//   test codeunits 91637 and 91644
// Probe: observe probe (writer Y13, 2026-10-31, runtime asks from partner-app triage); every literal asserted below is what the BC service tier produced.
// Facts: (1) FindFirstField on a list page, then the value of a control whose source is an expression (a function call, an arithmetic expression
//   over a field, a string expression), after FindFirstField, FindNextField and GoToRecord. (2) OptionCount and GetOption of two page controls
//   bound to one enum field, one with ValuesAllowed on the control, and of a page control over a table field that has ValuesAllowed.
//   (3) Error('') raised from a TABLE field's OnValidate when the field is edited on a ListPart inside a Card (the control trigger case is
//   pinned in Np4EmptyError.al and the table trigger on a List or Card page in QzTableValidateEmptyError.al).
// BC versions: 27, 28, 29

enum 91630 "LT Y13 Kind"
{
    Extensible = false;
    value(0; Open) { }
    value(1; Released) { }
    value(2; Closed) { }
    value(3; Archived) { }
}

table 91631 "LT Y13 PG Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Kind; Enum "LT Y13 Kind") { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 91632 "LT Y13 PG VA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT Y13 Kind") { ValuesAllowed = Open, Closed; }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 91634 "LT Y13 PG Expr List"
{
    PageType = List;
    SourceTable = "LT Y13 PG Row";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
                field(FromFunction; Describe()) { ApplicationArea = All; }
                field(Doubled; Rec.Qty * 2) { ApplicationArea = All; }
                field(Joined; Rec.Name + '/' + Format(Rec.Id)) { ApplicationArea = All; }
                field(FromVariable; Stored) { ApplicationArea = All; }
            }
        }
    }

    var
        Stored: Text;

    local procedure Describe(): Text
    begin
        exit('d:' + Rec.Name);
    end;

    trigger OnAfterGetRecord()
    begin
        Stored := 'v:' + Rec.Name;
    end;
}

page 91635 "LT Y13 PG Kinds"
{
    PageType = Card;
    SourceTable = "LT Y13 PG Row";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Plain; Rec.Kind) { ApplicationArea = All; }
            field(Limited; Rec.Kind) { ApplicationArea = All; ValuesAllowed = Open, Released; }
        }
    }
}

page 91636 "LT Y13 PG TableVA"
{
    PageType = Card;
    SourceTable = "LT Y13 PG VA Row";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Kind; Rec.Kind) { ApplicationArea = All; }
        }
    }
}

codeunit 91637 "LT Y13 PG Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Rows()
    var
        Row: Record "LT Y13 PG Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Alpha';
        Row.Qty := 5;
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Beta';
        Row.Qty := 7;
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'Gamma';
        Row.Qty := 9;
        Row.Insert();
    end;

    local procedure Shown(var P: TestPage "LT Y13 PG Expr List"): Text
    begin
        exit(P.Name.Value() + ' fn=' + P.FromFunction.Value() + ' dbl=' + P.Doubled.Value() + ' join=' + P.Joined.Value() + ' var=' + P.FromVariable.Value());
    end;

    [Test]
    procedure Y13_PG_FindFirstField_ExpressionControls()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y13 PG Expr List";
    begin
        Rows();
        P.OpenView();
        Observer.Observe('opened', Shown(P));
        Observer.Observe('find Beta', Format(P.FindFirstField(P.Name, 'Beta')));
        Observer.Observe('after find', Shown(P));
        Observer.Observe('find next', Format(P.FindNextField(P.Name, 'Gamma')));
        Observer.Observe('after next', Shown(P));
        Observer.Observe('find by function', Format(P.FindFirstField(P.FromFunction, 'd:Alpha')));
        Observer.Observe('after find by function', Shown(P));
        Observer.Observe('find by double', Format(P.FindFirstField(P.Doubled, '14')));
        Observer.Observe('after find by double', Shown(P));
        Observer.Observe('find by join', Format(P.FindFirstField(P.Joined, 'Gamma/3')));
        Observer.Observe('after find by join', Shown(P));
        Observer.Observe('find by variable', Format(P.FindFirstField(P.FromVariable, 'v:Beta')));
        Observer.Observe('after find by variable', Shown(P));
        Observer.Expect('opened', 'Alpha fn=d:Alpha dbl=10 join=Alpha/1 var=v:Alpha');
        Observer.Expect('find Beta', 'Yes');
        Observer.Expect('after find', 'Beta fn=d:Beta dbl=14 join=Beta/2 var=v:Beta');
        Observer.Expect('find next', 'Yes');
        Observer.Expect('after next', 'Gamma fn=d:Gamma dbl=18 join=Gamma/3 var=v:Gamma');
        Observer.Expect('find by function', 'Yes');
        Observer.Expect('after find by function', 'Alpha fn=d:Alpha dbl=10 join=Alpha/1 var=v:Alpha');
        Observer.Expect('find by double', 'No');
        Observer.Expect('after find by double', 'Alpha fn=d:Alpha dbl=10 join=Alpha/1 var=v:Alpha');
        Observer.Expect('find by join', 'Yes');
        Observer.Expect('after find by join', 'Gamma fn=d:Gamma dbl=18 join=Gamma/3 var=v:Gamma');
        Observer.Expect('find by variable', 'Yes');
        Observer.Expect('after find by variable', 'Beta fn=d:Beta dbl=14 join=Beta/2 var=v:Beta');
        Observer.Verify();
    end;

    local procedure Options(var P: TestPage "LT Y13 PG Kinds"; Limited: Boolean): Text
    var
        Index: Integer;
        Result: Text;
    begin
        if Limited then begin
            Result := 'count=' + Format(P.Limited.OptionCount()) + ' [';
            for Index := 1 to P.Limited.OptionCount() do
                Result += P.Limited.GetOption(Index) + ',';
        end else begin
            Result := 'count=' + Format(P.Plain.OptionCount()) + ' [';
            for Index := 1 to P.Plain.OptionCount() do
                Result += P.Plain.GetOption(Index) + ',';
        end;
        exit(Result + ']');
    end;

    local procedure TableOptions(var V: TestPage "LT Y13 PG TableVA"): Text
    var
        Index: Integer;
        Result: Text;
    begin
        Result := 'count=' + Format(V.Kind.OptionCount()) + ' [';
        for Index := 1 to V.Kind.OptionCount() do
            Result += V.Kind.GetOption(Index) + ',';
        exit(Result + ']');
    end;

    [Test]
    procedure Y13_PG_OptionCount_ValuesAllowed()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y13 PG Row";
        VaRow: Record "LT Y13 PG VA Row";
        P: TestPage "LT Y13 PG Kinds";
        V: TestPage "LT Y13 PG TableVA";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        VaRow.DeleteAll();
        VaRow.Id := 1;
        VaRow.Insert();
        P.OpenEdit();
        Observer.Observe('plain control', Options(P, false));
        Observer.Observe('limited control', Options(P, true));
        V.OpenEdit();
        Observer.Observe('table field with ValuesAllowed', TableOptions(V));
        Observer.Expect('plain control', 'count=4 [Open,Released,Closed,Archived,]');
        Observer.Expect('limited control', 'count=2 [Open,Released,]');
        Observer.Expect('table field with ValuesAllowed', 'count=2 [Open,Closed,]');
        Observer.Verify();
    end;
}

table 91640 "LT Y13 PV Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Desc; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 91641 "LT Y13 PV Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; HeadId; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; Name; Text[30])
        {
            trigger OnValidate()
            begin
                if Name = 'empty' then
                    Error('');
            end;
        }
    }
    keys { key(PK; HeadId, LineNo) { Clustered = true; } }
}

page 91642 "LT Y13 PV Lines"
{
    PageType = ListPart;
    SourceTable = "LT Y13 PV Line";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec.LineNo) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 91643 "LT Y13 PV Card"
{
    PageType = Card;
    SourceTable = "LT Y13 PV Head";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            part(Lines; "LT Y13 PV Lines")
            {
                ApplicationArea = All;
                SubPageLink = HeadId = field(Id);
            }
        }
    }
}

codeunit 91644 "LT Y13 PV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT Y13 PV Head";
        Line: Record "LT Y13 PV Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head.Id := 1;
        Head.Desc := 'seed';
        Head.Insert();
        Line.HeadId := 1;
        Line.LineNo := 10000;
        Line.Name := 'seed';
        Line.Insert();
        Commit();
    end;

    local procedure Stored(): Text
    var
        Line: Record "LT Y13 PV Line";
    begin
        exit('line=' + Format(Line.Get(1, 10000)) + '|' + Line.Name);
    end;

    [Test]
    procedure Y13_PV_TableValidateEmptyError_ListPartInCard()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT Y13 PV Card";
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey(1);
        Host.Lines.First();
        Host.Lines.Name.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', Host.Lines.Name.Value());
        Host.Lines.Name.SetValue('fine');
        Observer.Observe('value-after-fine', Host.Lines.Name.Value());
        Host.Close();
        Observer.Observe('stored-after-close', Stored());
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('value-after-fine', 'fine');
        Observer.Expect('stored-after-close', 'line=Yes|fine');
        Observer.Verify();
    end;
}

