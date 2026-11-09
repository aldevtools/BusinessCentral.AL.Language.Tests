// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setview-method
// Scope: in-scope (Cloud)
// local object: the view / filter property of the object is what is under test, so each case needs its own page or report; the capture codeunit is SingleInstance and outlives a test
// Fixtures used: Probe Observer (codeunit 69160); own objects in 96600..96699
// BC versions: 27, 28, 29
// Area matrix (al-runner issues 7371, 7411, 7423): Record.SetView with the view text forms of the page / report cases (table "VW Row" of
//   pages/view-properties/VwPageViews.al): CONST and FILTER with blank, number, enum name, enum number, quoted member, type-qualified and
//   field-qualified enum values, Database:: constants, dates, booleans, options, SORTING / ORDER, several conditions, and texts that are not
//   a view. Each case observes whether SetView accepts the text, Rec.GetFilters(), Rec.GetView(), the rows it reads, or the error.

codeunit 96605 "VW Set View Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Capture: Codeunit "VW Capture";

    local procedure Initialize()
    begin
        Capture.Seed();
        Capture.Reset();
    end;

    [TryFunction]
    local procedure TrySetView(var Row: Record "VW Row"; ViewText: Text)
    begin
        Row.SetView(ViewText);
    end;

    local procedure Observe(ViewText: Text)
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "VW Row";
        Rows: Text;
    begin
        if not TrySetView(Row, ViewText) then begin
            Observer.ObserveError('setView');
            Observer.Finish();
        end;
        Observer.Observe('filters', Row.GetFilters());
        Observer.Observe('view', Row.GetView(true));
        Observer.Observe('viewCaptions', Row.GetView(false));
        if Row.FindSet() then
            repeat
                Rows += Row."No." + ',';
            until Row.Next() = 0;
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;

    // CLAIM: Record.SetView('WHERE(CodeF=CONST())') behaves as recorded below.
    [Test]
    procedure SetView_ConstBlankCode()
    begin
        Initialize();
        Observe('WHERE(CodeF=CONST())');
    end;

    // CLAIM: Record.SetView('WHERE(CodeF=FILTER())') behaves as recorded below.
    [Test]
    procedure SetView_FilterBlankCode()
    begin
        Initialize();
        Observe('WHERE(CodeF=FILTER())');
    end;

    // CLAIM: Record.SetView('WHERE(CodeF=FILTER(<>''''))') behaves as recorded below.
    [Test]
    procedure SetView_FilterNotBlankCode()
    begin
        Initialize();
        Observe('WHERE(CodeF=FILTER(<>''''))');
    end;

    // CLAIM: Record.SetView('WHERE(CodeF=FILTER(=''''))') behaves as recorded below.
    [Test]
    procedure SetView_FilterEqualsQuotedBlankCode()
    begin
        Initialize();
        Observe('WHERE(CodeF=FILTER(=''''))');
    end;

    // CLAIM: Record.SetView('WHERE(TextF=CONST())') behaves as recorded below.
    [Test]
    procedure SetView_ConstTextBlank()
    begin
        Initialize();
        Observe('WHERE(TextF=CONST())');
    end;

    // CLAIM: Record.SetView('WHERE(IntF=CONST(96600))') behaves as recorded below.
    [Test]
    procedure SetView_ConstIntNumber()
    begin
        Initialize();
        Observe('WHERE(IntF=CONST(96600))');
    end;

    // CLAIM: Record.SetView('WHERE(IntF=FILTER(Database::VW Row))') behaves as recorded below.
    [Test]
    procedure SetView_FilterIntDatabase()
    begin
        Initialize();
        Observe('WHERE(IntF=FILTER(Database::VW Row))');
    end;

    // CLAIM: Record.SetView('WHERE(IntF=FILTER(Database::''VW Row''))') behaves as recorded below.
    [Test]
    procedure SetView_FilterIntDatabaseQuoted()
    begin
        Initialize();
        Observe('WHERE(IntF=FILTER(Database::''VW Row''))');
    end;

    // CLAIM: Record.SetView('WHERE(KindF=CONST(Item))') behaves as recorded below.
    [Test]
    procedure SetView_ConstEnumName()
    begin
        Initialize();
        Observe('WHERE(KindF=CONST(Item))');
    end;

    // CLAIM: Record.SetView('WHERE(KindF=CONST(1))') behaves as recorded below.
    [Test]
    procedure SetView_ConstEnumNumber()
    begin
        Initialize();
        Observe('WHERE(KindF=CONST(1))');
    end;

    // CLAIM: Record.SetView('WHERE(KindF=CONST(Fixed Asset))') behaves as recorded below.
    [Test]
    procedure SetView_ConstEnumQuotedMember()
    begin
        Initialize();
        Observe('WHERE(KindF=CONST(Fixed Asset))');
    end;

    // CLAIM: Record.SetView('WHERE(KindF=CONST(Nope))') behaves as recorded below.
    [Test]
    procedure SetView_ConstEnumUnknownMember()
    begin
        Initialize();
        Observe('WHERE(KindF=CONST(Nope))');
    end;

    // CLAIM: Record.SetView('WHERE(KindF=FILTER(Item))') behaves as recorded below.
    [Test]
    procedure SetView_FilterEnumName()
    begin
        Initialize();
        Observe('WHERE(KindF=FILTER(Item))');
    end;

    // CLAIM: Record.SetView('WHERE(KindF=FILTER(<>Item))') behaves as recorded below.
    [Test]
    procedure SetView_FilterEnumNot()
    begin
        Initialize();
        Observe('WHERE(KindF=FILTER(<>Item))');
    end;

    // CLAIM: Record.SetView('WHERE(KindF=FILTER(VW Kind::Item))') behaves as recorded below.
    [Test]
    procedure SetView_FilterEnumTypeQualified()
    begin
        Initialize();
        Observe('WHERE(KindF=FILTER(VW Kind::Item))');
    end;

    // CLAIM: Record.SetView('WHERE(KindF=FILTER(KindF::Item))') behaves as recorded below.
    [Test]
    procedure SetView_FilterEnumFieldQualified()
    begin
        Initialize();
        Observe('WHERE(KindF=FILTER(KindF::Item))');
    end;

    // CLAIM: Record.SetView('WHERE(KindF=FILTER(Item|Resource))') behaves as recorded below.
    [Test]
    procedure SetView_FilterEnumOr()
    begin
        Initialize();
        Observe('WHERE(KindF=FILTER(Item|Resource))');
    end;

    // CLAIM: Record.SetView('WHERE(DateF=FILTER())') behaves as recorded below.
    [Test]
    procedure SetView_FilterDateBlank()
    begin
        Initialize();
        Observe('WHERE(DateF=FILTER())');
    end;

    // CLAIM: Record.SetView('WHERE(DateF=FILTER(=''''))') behaves as recorded below.
    [Test]
    procedure SetView_FilterDateEqualsBlank()
    begin
        Initialize();
        Observe('WHERE(DateF=FILTER(=''''))');
    end;

    // CLAIM: Record.SetView('WHERE(BoolF=CONST(Yes))') behaves as recorded below.
    [Test]
    procedure SetView_ConstBoolTrue()
    begin
        Initialize();
        Observe('WHERE(BoolF=CONST(Yes))');
    end;

    // CLAIM: Record.SetView('WHERE(BoolF=CONST(true))') behaves as recorded below.
    [Test]
    procedure SetView_ConstBoolTrueWord()
    begin
        Initialize();
        Observe('WHERE(BoolF=CONST(true))');
    end;

    // CLAIM: Record.SetView('WHERE(OptF=CONST(B))') behaves as recorded below.
    [Test]
    procedure SetView_ConstOptionName()
    begin
        Initialize();
        Observe('WHERE(OptF=CONST(B))');
    end;

    // CLAIM: Record.SetView('SORTING(CodeF)') behaves as recorded below.
    [Test]
    procedure SetView_SortingOnlyCode()
    begin
        Initialize();
        Observe('SORTING(CodeF)');
    end;

    // CLAIM: Record.SetView('SORTING(No.) ORDER(Descending) WHERE(KindF=CONST(Item))') behaves as recorded below.
    [Test]
    procedure SetView_SortingDescendingWhere()
    begin
        Initialize();
        Observe('SORTING(No.) ORDER(Descending) WHERE(KindF=CONST(Item))');
    end;

    // CLAIM: Record.SetView('WHERE(KindF=FILTER(Item),CodeF=CONST())') behaves as recorded below.
    [Test]
    procedure SetView_TwoConditions()
    begin
        Initialize();
        Observe('WHERE(KindF=FILTER(Item),CodeF=CONST())');
    end;

    // CLAIM: Record.SetView('WHERE(Nope=CONST(1))') behaves as recorded below.
    [Test]
    procedure SetView_UnknownField()
    begin
        Initialize();
        Observe('WHERE(Nope=CONST(1))');
    end;

    // CLAIM: Record.SetView('KindF=Item') behaves as recorded below.
    [Test]
    procedure SetView_NotAView()
    begin
        Initialize();
        Observe('KindF=Item');
    end;
}
