// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75700, pages 75701, 75702 and 75703, test codeunit 75704
// Probe (al-runner issue 8660): the Visible state a TestPage reads for a field control whose Visible expression names a field
//   of the source record, by what the control's source is.
// Facts:
//   - BC 29: a control whose source is an expression (Rec.Amount + 1), a page variable or a constant, and whose Visible
//     expression names a field of the source record (Rec.Amount > 0, Rec.Amount < 0, Rec.Flag, Amount > 0, ShowIt and
//     (Rec.Amount >= 0)): the TestPage reads Yes, whatever the row holds.
//   - BC 27 and 28: opening a TestPage of a page with such a control (OpenEdit, OpenView, OpenNew) raises "The identifier
//     '<field>' could not be found.", naming the first field that the Visible of the first such control names.
//   - A control bound to a field of the source record, or whose Visible expression names no field (a page variable, 1 = 0):
//     the TestPage reads the value the expression had when the page opened, before its first row (No for Rec.Amount > 0 and
//     for a variable that OnAfterGetRecord sets).
// local object: the controls' sources and Visible expressions are under test.
// BC versions: 27, 28, 29 (by the corpus CI matrix)

table 75700 "PGC Visible Source Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Integer) { }
        field(3; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 75701 "PGC Visible Expr Source"
{
    PageType = Card;
    SourceTable = "PGC Visible Source Row";

    layout
    {
        area(Content)
        {
            field(AmountPlusOne; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = Rec.Amount > 0;
            }
        }
    }
}

page 75702 "PGC Visible Other Sources"
{
    PageType = Card;
    SourceTable = "PGC Visible Source Row";

    layout
    {
        area(Content)
        {
            field(ExprFlag; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = Rec.Flag;
            }
            field(ExprNegative; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = Rec.Amount < 0;
            }
            field(ExprMixed; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = ShowIt and (Rec.Amount >= 0);
            }
            field(ExprBareField; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = Amount > 0;
            }
            field(VarSource; Doubled)
            {
                ApplicationArea = All;
                Visible = Rec.Amount > 0;
            }
            field(ConstSource; 'Fixed')
            {
                ApplicationArea = All;
                Visible = Rec.Amount > 0;
            }
        }
    }

    var
        ShowIt: Boolean;
        Doubled: Integer;

    trigger OnAfterGetRecord()
    begin
        ShowIt := Rec.Amount > 0;
        Doubled := Rec.Amount * 2;
    end;
}

page 75703 "PGC Visible Open Time"
{
    PageType = Card;
    SourceTable = "PGC Visible Source Row";

    layout
    {
        area(Content)
        {
            field(FieldOwn; Rec.Amount)
            {
                ApplicationArea = All;
                Visible = Rec.Amount > 0;
            }
            field(FieldOther; Rec.Id)
            {
                ApplicationArea = All;
                Visible = Rec.Amount > 0;
            }
            field(ExprVariable; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = ShowIt;
            }
            field(ExprConstant; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = 1 = 0;
            }
        }
    }

    var
        ShowIt: Boolean;

    trigger OnAfterGetRecord()
    begin
        ShowIt := Rec.Amount > 0;
    end;
}

codeunit 75704 "PGC Visible Source Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

#if BC29PLUS
    [Test]
    procedure VisibleSource_ExpressionSourceNamingRecField_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Expr Source";
    begin
        Initialize();
        InsertRow(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('AmountPlusOne visible', Format(Card.AmountPlusOne.Visible()));
        Card.Close();
        Observer.Expect('AmountPlusOne visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure VisibleSource_OtherNonFieldSourcesNamingRecField_ReadYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Other Sources";
    begin
        Initialize();
        InsertRow(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('ExprNegative visible', Format(Card.ExprNegative.Visible()));
        Observer.Observe('ExprFlag visible', Format(Card.ExprFlag.Visible()));
        Observer.Observe('ExprMixed visible', Format(Card.ExprMixed.Visible()));
        Observer.Observe('ExprBareField visible', Format(Card.ExprBareField.Visible()));
        Observer.Observe('VarSource visible', Format(Card.VarSource.Visible()));
        Observer.Observe('ConstSource visible', Format(Card.ConstSource.Visible()));
        Card.Close();
        Observer.Expect('ExprNegative visible', 'Yes');
        Observer.Expect('ExprFlag visible', 'Yes');
        Observer.Expect('ExprMixed visible', 'Yes');
        Observer.Expect('ExprBareField visible', 'Yes');
        Observer.Expect('VarSource visible', 'Yes');
        Observer.Expect('ConstSource visible', 'Yes');
        Observer.Verify();
    end;
#else
    // BC 27 and 28: opening a TestPage of a page with such a control raises "The identifier '<field>' could not be found.",
    // naming the first field the Visible of the first such control names (page 75702 has its Rec.Flag control first).
    [Test]
    procedure VisibleSource_ExpressionSourceNamingRecField_Before29_OpenEditRaises()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Expr Source";
    begin
        Initialize();
        InsertRow(Row);
        asserterror Card.OpenEdit();
        Observer.Observe('open edit error', GetLastErrorText());
        Observer.Expect('open edit error', 'The identifier ''Amount'' could not be found.');
        Observer.Verify();
    end;

    [Test]
    procedure VisibleSource_ExpressionSourceNamingRecField_Before29_OpenViewRaises()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Expr Source";
    begin
        Initialize();
        InsertRow(Row);
        asserterror Card.OpenView();
        Observer.Observe('open view error', GetLastErrorText());
        Observer.Expect('open view error', 'The identifier ''Amount'' could not be found.');
        Observer.Verify();
    end;

    [Test]
    procedure VisibleSource_ExpressionSourceNamingRecField_Before29_OpenNewRaises()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "PGC Visible Expr Source";
    begin
        Initialize();
        asserterror Card.OpenNew();
        Observer.Observe('open new error', GetLastErrorText());
        Observer.Expect('open new error', 'The identifier ''Amount'' could not be found.');
        Observer.Verify();
    end;

    [Test]
    procedure VisibleSource_OtherNonFieldSources_Before29_OpenEditNamesFirstControlsField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Other Sources";
    begin
        Initialize();
        InsertRow(Row);
        asserterror Card.OpenEdit();
        Observer.Observe('open edit error', GetLastErrorText());
        Observer.Expect('open edit error', 'The identifier ''Flag'' could not be found.');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure VisibleSource_FieldSourceOrNoRecField_ReadsOpenTimeValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Open Time";
    begin
        Initialize();
        InsertRow(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('FieldOwn visible', Format(Card.FieldOwn.Visible()));
        Observer.Observe('FieldOther visible', Format(Card.FieldOther.Visible()));
        Observer.Observe('ExprVariable visible', Format(Card.ExprVariable.Visible()));
        Observer.Observe('ExprConstant visible', Format(Card.ExprConstant.Visible()));
        Card.Close();
        Observer.Expect('FieldOwn visible', 'No');
        Observer.Expect('FieldOther visible', 'No');
        Observer.Expect('ExprVariable visible', 'No');
        Observer.Expect('ExprConstant visible', 'No');
        Observer.Verify();
    end;

    local procedure InsertRow(var Row: Record "PGC Visible Source Row")
    begin
        Row.Id := 1;
        Row.Amount := 1;
        Row.Flag := false;
        Row.Insert();
    end;

    local procedure Initialize()
    var
        Row: Record "PGC Visible Source Row";
    begin
        Row.DeleteAll();
    end;

}
