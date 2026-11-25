// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 75700 and 75711, pages 75701, 75702, 75703, 75705 to 75710 and 75712, test codeunit 75704
// Probe (al-runner issue 8660): the Visible state a TestPage reads for a field control whose Visible expression names a field
//   of the source record, by what the control's source is.
// Facts:
//   - BC 29: a control whose source is an expression (Rec.Amount + 1), a page variable or a constant, and whose Visible
//     expression names a field of the source record (Rec.Amount > 0, Rec.Amount < 0, Rec.Flag, Amount > 0, ShowIt and
//     (Rec.Amount >= 0), the primary key Rec.Id > 0): the TestPage reads Yes, whatever the row holds, also when another
//     control binds that field, after OpenEdit, OpenView and OpenNew, a Trap of Page.Run and in a ModalPageHandler (of a
//     Page.RunModal statement, with a field argument, through the table's lookup page, and with its return value used).
//   - BC 27 and 28: opening a TestPage of a page with such a control (OpenEdit, OpenView, OpenNew) raises "The identifier
//     '<field>' could not be found." (code Expression:Argument), naming the first field that the Visible of the first such
//     control names, after OnOpenPage and before OnAfterGetRecord; a control bound to a field before it does not count, and
//     another control binding the field changes nothing. Page.Run of a trapped page raises it too, and each modal route
//     raises it before its handler runs. With no handler, every version gives Unhandled UI first.
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

page 75705 "PGC Visible On Open Error"
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

    trigger OnOpenPage()
    begin
        Error('OnOpenPage ran');
    end;
}
page 75706 "PGC Visible On Get Error"
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

    trigger OnAfterGetRecord()
    begin
        Error('OnAfterGetRecord ran');
    end;
}
page 75707 "PGC Visible Bound Elsewhere"
{
    PageType = Card;
    SourceTable = "PGC Visible Source Row";

    layout
    {
        area(Content)
        {
            field(AmountCtl; Rec.Amount)
            {
                ApplicationArea = All;
            }
            field(Total; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = Rec.Amount > 0;
            }
        }
    }
}
page 75708 "PGC Visible Bound First"
{
    PageType = Card;
    SourceTable = "PGC Visible Source Row";

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id)
            {
                ApplicationArea = All;
                Visible = Rec.Flag;
            }
            field(Total; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = Rec.Amount > 0;
            }
        }
    }
}
page 75709 "PGC Visible Names Key"
{
    PageType = Card;
    SourceTable = "PGC Visible Source Row";

    layout
    {
        area(Content)
        {
            field(Total; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = Rec.Id > 0;
            }
        }
    }
}
page 75710 "PGC Visible One Bound"
{
    PageType = Card;
    SourceTable = "PGC Visible Source Row";

    layout
    {
        area(Content)
        {
            field(AmountCtl; Rec.Amount)
            {
                ApplicationArea = All;
            }
            field(Total; Rec.Amount + 1)
            {
                ApplicationArea = All;
                Visible = (Rec.Amount > 0) and Rec.Flag;
            }
        }
    }
}
table 75711 "PGC Visible Lookup Row"
{
    DataClassification = SystemMetadata;
    LookupPageId = "PGC Visible Lookup Card";

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 75712 "PGC Visible Lookup Card"
{
    PageType = Card;
    SourceTable = "PGC Visible Lookup Row";

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

codeunit 75704 "PGC Visible Source Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ModalVisible: Text;

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
    [Test]
    procedure VisibleSource_FieldBoundByAnotherControl_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Bound Elsewhere";
    begin
        Initialize();
        InsertRow(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('Total visible', Format(Card.Total.Visible()));
        Observer.Observe('AmountCtl visible', Format(Card.AmountCtl.Visible()));
        Card.Close();
        Observer.Expect('Total visible', 'Yes');
        Observer.Expect('AmountCtl visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure VisibleSource_FieldBoundControlFirst_KeepsOpenValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Bound First";
    begin
        Initialize();
        InsertRow(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('IdCtl visible', Format(Card.IdCtl.Visible()));
        Observer.Observe('Total visible', Format(Card.Total.Visible()));
        Card.Close();
        Observer.Expect('IdCtl visible', 'No');
        Observer.Expect('Total visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure VisibleSource_NamesPrimaryKey_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Names Key";
    begin
        Initialize();
        InsertRow(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('Total visible', Format(Card.Total.Visible()));
        Card.Close();
        Observer.Expect('Total visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure VisibleSource_AndWithOneFieldBound_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible One Bound";
    begin
        Initialize();
        InsertRow(Row);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('Total visible', Format(Card.Total.Visible()));
        Card.Close();
        Observer.Expect('Total visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure VisibleSource_OpenView_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Expr Source";
    begin
        Initialize();
        InsertRow(Row);
        Card.OpenView();
        Card.GoToRecord(Row);
        Observer.Observe('AmountPlusOne visible', Format(Card.AmountPlusOne.Visible()));
        Card.Close();
        Observer.Expect('AmountPlusOne visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure VisibleSource_OpenNew_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Expr Source";
    begin
        Initialize();
        InsertRow(Row);
        Card.OpenNew();
        Observer.Observe('AmountPlusOne visible', Format(Card.AmountPlusOne.Visible()));
        Card.Close();
        Observer.Expect('AmountPlusOne visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure VisibleSource_TrapPageRun_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Card: TestPage "PGC Visible Expr Source";
    begin
        Initialize();
        InsertRow(Row);
        Card.Trap();
        Page.Run(Page::"PGC Visible Expr Source", Row);
        Observer.Observe('AmountPlusOne visible', Format(Card.AmountPlusOne.Visible()));
        Card.Close();
        Observer.Expect('AmountPlusOne visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadVisibleModalHandler')]
    procedure VisibleSource_ModalPageHandler_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
    begin
        Initialize();
        InsertRow(Row);
        ModalVisible := 'not run';
        Page.RunModal(Page::"PGC Visible Expr Source", Row);
        Observer.Observe('AmountPlusOne visible in handler', ModalVisible);
        Observer.Expect('AmountPlusOne visible in handler', 'Yes');
        Observer.Verify();
    end;
    [Test]
    [HandlerFunctions('ReadVisibleModalHandler')]
    procedure VisibleSource_ModalFieldArgument_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
    begin
        Initialize();
        InsertRow(Row);
        ModalVisible := 'not run';
        Page.RunModal(Page::"PGC Visible Expr Source", Row, Row.FieldNo(Amount));
        Observer.Observe('field argument visible in handler', ModalVisible);
        Observer.Expect('field argument visible in handler', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadLookupVisibleHandler')]
    procedure VisibleSource_ModalTableLookupPage_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Lookup Row";
    begin
        InitializeLookup(Row);
        ModalVisible := 'not run';
        Page.RunModal(0, Row);
        Observer.Observe('table lookup page visible in handler', ModalVisible);
        Observer.Expect('table lookup page visible in handler', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadVisibleModalHandler')]
    procedure VisibleSource_ModalReturnUsed_ReadsYes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
    begin
        Initialize();
        InsertRow(Row);
        ModalVisible := 'not run';
        Observer.Observe('return used action', Format(Page.RunModal(Page::"PGC Visible Expr Source", Row)));
        Observer.Observe('return used visible in handler', ModalVisible);
        Observer.Expect('return used action', 'LookupCancel');
        Observer.Expect('return used visible in handler', 'Yes');
        Observer.Verify();
    end;
#else
    // BC 27 and 28: opening a TestPage of a page with such a control raises "The identifier '<field>' could not be found."
    // (code Expression:Argument) in OpenEdit, OpenView and OpenNew, naming the first field the Visible of the first such
    // control names (page 75702 has its Rec.Flag control first). OnOpenPage runs before it (page 75705), OnAfterGetRecord
    // does not (page 75706).
    [Test]
    procedure VisibleSource_ExpressionSourceNamingRecField_Before29_OpenErrors()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        EditCard: TestPage "PGC Visible Expr Source";
        ViewCard: TestPage "PGC Visible Expr Source";
        NewCard: TestPage "PGC Visible Expr Source";
        Others: TestPage "PGC Visible Other Sources";
        OnOpen: TestPage "PGC Visible On Open Error";
    begin
        Initialize();
        InsertRow(Row);
        asserterror EditCard.OpenEdit();
        Observer.ObserveError('open edit');
        asserterror ViewCard.OpenView();
        Observer.ObserveError('open view');
        asserterror NewCard.OpenNew();
        Observer.ObserveError('open new');
        asserterror Others.OpenEdit();
        Observer.ObserveError('other sources open edit');
        asserterror OnOpen.OpenEdit();
        Observer.ObserveError('on open page error');
        Observer.Expect('open edit|text', 'The identifier ''Amount'' could not be found.');
        Observer.Expect('open edit|code', 'Expression:Argument');
        Observer.Expect('open view|text', 'The identifier ''Amount'' could not be found.');
        Observer.Expect('open view|code', 'Expression:Argument');
        Observer.Expect('open new|text', 'The identifier ''Amount'' could not be found.');
        Observer.Expect('open new|code', 'Expression:Argument');
        Observer.Expect('other sources open edit|text', 'The identifier ''Flag'' could not be found.');
        Observer.Expect('other sources open edit|code', 'Expression:Argument');
        Observer.Expect('on open page error|text', 'OnOpenPage ran');
        Observer.Expect('on open page error|code', 'Dialog');
        Observer.Verify();
    end;

    // BC 27 and 28 (al-runner PR 8667 review): the same error for the shapes next to the rule, naming the first field the
    // Visible of the first expression control names. Another control that binds that field, the primary key, and a field-bound
    // control before it change nothing; Page.Run of a trapped page raises it too. A Page.RunModal answered by a ModalPageHandler
    // raised it before the handler ran (CI run 45019519945), but a test cannot hold it: the handler never runs.
    [Test]
    procedure VisibleSource_ShapesNextToRule_Before29_OpenErrors()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        Elsewhere: TestPage "PGC Visible Bound Elsewhere";
        BoundFirst: TestPage "PGC Visible Bound First";
        NamesKey: TestPage "PGC Visible Names Key";
        OneBound: TestPage "PGC Visible One Bound";
        Trapped: TestPage "PGC Visible Expr Source";
    begin
        Initialize();
        InsertRow(Row);
        asserterror Elsewhere.OpenEdit();
        Observer.ObserveError('bound elsewhere');
        asserterror BoundFirst.OpenEdit();
        Observer.ObserveError('bound first');
        asserterror NamesKey.OpenEdit();
        Observer.ObserveError('names key');
        asserterror OneBound.OpenEdit();
        Observer.ObserveError('one bound');
        Trapped.Trap();
        asserterror Page.Run(Page::"PGC Visible Expr Source", Row);
        Observer.ObserveError('trap page run');
        Observer.Expect('bound elsewhere|text', 'The identifier ''Amount'' could not be found.');
        Observer.Expect('bound elsewhere|code', 'Expression:Argument');
        Observer.Expect('bound first|text', 'The identifier ''Amount'' could not be found.');
        Observer.Expect('bound first|code', 'Expression:Argument');
        Observer.Expect('names key|text', 'The identifier ''Id'' could not be found.');
        Observer.Expect('names key|code', 'Expression:Argument');
        Observer.Expect('one bound|text', 'The identifier ''Amount'' could not be found.');
        Observer.Expect('one bound|code', 'Expression:Argument');
        Observer.Expect('trap page run|text', 'The identifier ''Amount'' could not be found.');
        Observer.Expect('trap page run|code', 'Expression:Argument');
        Observer.Verify();
    end;

    // BC 27 and 28 (round 2, observe run 45063694119): a ModalPageHandler with a field argument, through the table's lookup
    // page (Page.RunModal(0, Rec)) and with the return value used raise "The identifier 'Amount' could not be found." at the
    // modal open too, before the handler runs; a test cannot hold that, since the handler never runs.
    [Test]
    procedure VisibleSource_ExpressionSourceNamingRecField_Before29_ErrorBeforeOnAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        OnAfterGet: TestPage "PGC Visible On Get Error";
    begin
        Initialize();
        InsertRow(Row);
        asserterror OnAfterGet.OpenEdit();
        Observer.ObserveError('on after get record error');
        Observer.Expect('on after get record error|text', 'The identifier ''Amount'' could not be found.');
        Observer.Expect('on after get record error|code', 'Expression:Argument');
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

    // Every version: with no handler, each modal shape fails with the test framework's Unhandled UI error first.
    [Test]
    procedure VisibleSource_ModalNoHandler_UnhandledUi()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PGC Visible Source Row";
        LookupRow: Record "PGC Visible Lookup Row";
    begin
        Initialize();
        InsertRow(Row);
        asserterror Page.RunModal(Page::"PGC Visible Expr Source", Row);
        Observer.ObserveError('modal no handler');
        asserterror Page.RunModal(Page::"PGC Visible Expr Source", Row, Row.FieldNo(Amount));
        Observer.ObserveError('modal field argument no handler');
        InitializeLookup(LookupRow);
        asserterror Page.RunModal(0, LookupRow);
        Observer.ObserveError('modal table lookup page no handler');
        Observer.Expect('modal no handler|text', 'Unhandled UI: ModalPage 75701');
        Observer.Expect('modal no handler|code', 'MissingUIHandler');
        Observer.Expect('modal field argument no handler|text', 'Unhandled UI: ModalPage 75701');
        Observer.Expect('modal field argument no handler|code', 'MissingUIHandler');
        Observer.Expect('modal table lookup page no handler|text', 'Unhandled UI: ModalPage 75712');
        Observer.Expect('modal table lookup page no handler|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure ReadLookupVisibleHandler(var Card: TestPage "PGC Visible Lookup Card")
    begin
        ModalVisible := Format(Card.AmountPlusOne.Visible());
    end;

    [ModalPageHandler]
    procedure ReadVisibleModalHandler(var Card: TestPage "PGC Visible Expr Source")
    begin
        ModalVisible := Format(Card.AmountPlusOne.Visible());
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
        LookupRow: Record "PGC Visible Lookup Row";
    begin
        Row.DeleteAll();
        LookupRow.DeleteAll();
    end;

    local procedure InitializeLookup(var Row: Record "PGC Visible Lookup Row")
    begin
        Initialize();
        Row.Id := 1;
        Row.Amount := 1;
        Row.Insert();
    end;

}
