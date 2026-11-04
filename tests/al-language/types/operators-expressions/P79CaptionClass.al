// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table 73970, pages 73971-73972, test codeunit 73973
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CaptionClass of page controls and table fields ('1,1,x', '3,x', '3,', unknown type, variable expression) and what TestPage field Caption shows
// BC versions: 29 (27 and 28 by CI)

table 73970 "LT P79 Cap Rec"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { Caption = 'Identifier'; }
        field(2; Plain; Text[30]) { Caption = 'Plain Field'; }
        field(3; Lit; Text[30]) { Caption = 'Ignored Table Caption'; CaptionClass = '3,Table Literal'; }
        field(4; Dim; Text[30]) { Caption = 'Dim Table Caption'; CaptionClass = '1,1,x'; }
        field(5; Empty; Text[30]) { Caption = 'Empty Class'; CaptionClass = ''; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 73971 "LT P79 Cap Literal"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT P79 Cap Rec";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(PlainF; Rec.Plain) { ApplicationArea = All; }
                field(LitF; Rec.Lit) { ApplicationArea = All; }
                field(DimF; Rec.Dim) { ApplicationArea = All; }
                field(EmptyF; Rec.Empty) { ApplicationArea = All; }
                field(Lit3; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Control Caption';
                    CaptionClass = '3,Control Literal';
                }
                field(Lit3Comma; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Comma Caption';
                    CaptionClass = '3,a,b,c';
                }
                field(Lit3Empty; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Empty Literal Caption';
                    CaptionClass = '3,';
                }
                field(Dim1x; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Dim Control Caption';
                    CaptionClass = '1,1,x';
                }
                field(Dim2x; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Dim2 Control Caption';
                    CaptionClass = '1,2,x';
                }
                field(Dim1Plain; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Dim1 Short';
                    CaptionClass = '1,1';
                }
                field(Unknown9; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Unknown Class Caption';
                    CaptionClass = '9,x';
                }
                field(NoComma; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'No Comma Caption';
                    CaptionClass = 'abc';
                }
                field(EmptyCls; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Empty Control Class';
                    CaptionClass = '';
                }
                field(PlainCtl; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'No Class Control';
                }
            }
        }
    }
}

page 73972 "LT P79 Cap Variable"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT P79 Cap Rec";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(ByVar; Rec.Plain)
                {
                    ApplicationArea = All;
                    Caption = 'Variable Control';
                    CaptionClass = CapVar;
                }
                field(ByVar2; Rec.Id)
                {
                    ApplicationArea = All;
                    Caption = 'Variable Control Two';
                    CaptionClass = CapVar2;
                }
            }
        }
    }

    var
        CapVar: Text;
        CapVar2: Text;

    trigger OnOpenPage()
    begin
        CapVar := '3,From Variable';
        CapVar2 := '3,' + 'Concat ' + Format(Rec.Id);
    end;
}

codeunit 73973 "LT P79 CaptionClass Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TableField_Captions()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P79 Cap Rec";
    begin
        Observer.Observe('id', Rec.FieldCaption(Id));
        Observer.Observe('plain', Rec.FieldCaption(Plain));
        Observer.Observe('lit', Rec.FieldCaption(Lit));
        Observer.Observe('empty', Rec.FieldCaption(Empty));
        Observer.Expect('id', 'Identifier');
        Observer.Expect('plain', 'Plain Field');
        Observer.Expect('lit', 'Table Literal');
        Observer.Expect('empty', 'Empty Class');
        Observer.Verify();
    end;

    [Test]
    procedure TableField_DimCaptionClass()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P79 Cap Rec";
    begin
        // depends on the dimension setup of the database: only compared, not asserted by value
        Observer.Observe('dim-not-empty', Format(Rec.FieldCaption(Dim) <> ''));
        Observer.Observe('dim-not-class', Format(Rec.FieldCaption(Dim) <> '1,1,x'));
        Observer.Observe('dim-eq-tablecaption', Format(Rec.FieldCaption(Dim) = 'Dim Table Caption'));
        Observer.Expect('dim-not-empty', 'Yes');
        Observer.Expect('dim-not-class', 'No');
        Observer.Expect('dim-eq-tablecaption', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Page_LiteralClasses()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "LT P79 Cap Literal";
    begin
        Page.OpenNew();
        Observer.Observe('id', Page.IdF.Caption());
        Observer.Observe('plain', Page.PlainF.Caption());
        Observer.Observe('table-lit', Page.LitF.Caption());
        Observer.Observe('table-empty', Page.EmptyF.Caption());
        Observer.Observe('ctl-lit3', Page.Lit3.Caption());
        Observer.Observe('ctl-lit3-comma', Page.Lit3Comma.Caption());
        Observer.Observe('ctl-lit3-empty', Page.Lit3Empty.Caption());
        Observer.Observe('ctl-unknown9', Page.Unknown9.Caption());
        Observer.Observe('ctl-nocomma', Page.NoComma.Caption());
        Observer.Observe('ctl-emptycls', Page.EmptyCls.Caption());
        Observer.Observe('ctl-plain', Page.PlainCtl.Caption());
        Page.Close();
        Observer.Expect('id', 'Identifier');
        Observer.Expect('plain', 'Plain Field');
        Observer.Expect('table-lit', 'Table Literal');
        Observer.Expect('table-empty', 'Empty Class');
        Observer.Expect('ctl-lit3', 'Control Literal');
        Observer.Expect('ctl-lit3-comma', 'a,b,c');
        Observer.Expect('ctl-lit3-empty', 'No Class Control');
        Observer.Expect('ctl-unknown9', '9,x');
        Observer.Expect('ctl-nocomma', 'abc');
        Observer.Expect('ctl-emptycls', 'No Class Control');
        Observer.Expect('ctl-plain', 'No Class Control');
        Observer.Verify();
    end;

    [Test]
    procedure Page_DimensionClasses()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "LT P79 Cap Literal";
    begin
        // dimension captions depend on the database setup: only relations are asserted
        Page.OpenNew();
        Observer.Observe('table-dim-not-class', Format(Page.DimF.Caption() <> '1,1,x'));
        Observer.Observe('dim1x-not-class', Format(Page.Dim1x.Caption() <> '1,1,x'));
        Observer.Observe('dim1x-eq-control-caption', Format(Page.Dim1x.Caption() = 'Dim Control Caption'));
        Observer.Observe('dim2x-not-class', Format(Page.Dim2x.Caption() <> '1,2,x'));
        Observer.Observe('dim1plain-not-class', Format(Page.Dim1Plain.Caption() <> '1,1'));
        Observer.Observe('dim1x-eq-dim2x', Format(Page.Dim1x.Caption() = Page.Dim2x.Caption()));
        Observer.Observe('dim1x-eq-dim1plain', Format(Page.Dim1x.Caption() = Page.Dim1Plain.Caption()));
        Page.Close();
        Observer.Expect('table-dim-not-class', 'No');
        Observer.Expect('dim1x-not-class', 'No');
        Observer.Expect('dim1x-eq-control-caption', 'No');
        Observer.Expect('dim2x-not-class', 'No');
        Observer.Expect('dim1plain-not-class', 'No');
        Observer.Expect('dim1x-eq-dim2x', 'No');
        Observer.Expect('dim1x-eq-dim1plain', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Page_VariableExpression()
    var
        Observer: Codeunit "Probe Observer";
        Page: TestPage "LT P79 Cap Variable";
    begin
        Page.OpenNew();
        Observer.Observe('by-var', Page.ByVar.Caption());
        Observer.Observe('by-var-concat', Page.ByVar2.Caption());
        Page.Close();
        Observer.Expect('by-var', 'From Variable');
        Observer.Expect('by-var-concat', 'Concat 0');
        Observer.Verify();
    end;
}
