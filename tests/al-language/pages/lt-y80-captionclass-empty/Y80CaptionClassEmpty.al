// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 94215, pages 94216 - 94221, test codeunit 94222
// Probe (writer Y80, from the runtime lane rt-pages-1102c): CaptionClass = '3,' with nothing after the comma on a page control.
//   pages/lt-page-report-events/P84CaptionClass3SM.al pins the literal '3,' on a Card read with OpenView: the control shows the caption of the LAST
//   control bound to the same field (its Caption, or the field's caption), its own caption when it is the only one. Here the same on a List (repeater
//   column), a Worksheet, a ListPart and a CardPart in a Document, a Card opened with OpenEdit and OpenNew, and the expression forms that give '3,':
//   a procedure that returns '3,' and '3,' + a Text variable that is empty. The captions are read with TestPage control Caption() after the open and
//   after the page moved (Next) or a field was set.
// BC versions: 27, 28, 29

table 94215 "LT Y80 CC Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Plain; Text[30]) { Caption = 'Plain Field'; }
        field(3; Other; Text[30]) { Caption = 'Other Field'; }
        field(4; Third; Text[30]) { Caption = 'Third Field'; }
        field(5; Fourth; Text[30]) { Caption = 'Fourth Field'; }
        field(6; Fifth; Text[30]) { Caption = 'Fifth Field'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 94216 "LT Y80 CC Card"
{
    PageType = Card;
    SourceTable = "LT Y80 CC Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(CtlA; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl A'; }
                field(CtlLit; Rec.Plain) { ApplicationArea = All; Caption = 'Own Lit'; CaptionClass = '3,'; }
                field(CtlB; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl B'; }
                field(CtlExpr; Rec.Other) { ApplicationArea = All; Caption = 'Own Expr'; CaptionClass = Cap3(); }
                field(CtlOtherNoCaption; Rec.Other) { ApplicationArea = All; }
                field(CtlAlone; Rec.Third) { ApplicationArea = All; Caption = 'Own Alone'; CaptionClass = '3,'; }
                field(CtlAloneExpr; Rec.Fourth) { ApplicationArea = All; Caption = 'Own Alone Expr'; CaptionClass = Cap3(); }
                field(CtlVar; Rec.Fifth) { ApplicationArea = All; Caption = 'Own Var'; CaptionClass = '3,' + CapText; }
            }
        }
    }

    local procedure Cap3(): Text
    begin
        exit('3,');
    end;

    var
        CapText: Text;
}

page 94217 "LT Y80 CC List"
{
    PageType = List;
    SourceTable = "LT Y80 CC Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CtlA; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl A'; }
                field(CtlLit; Rec.Plain) { ApplicationArea = All; Caption = 'Own Lit'; CaptionClass = '3,'; }
                field(CtlB; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl B'; }
                field(CtlExpr; Rec.Other) { ApplicationArea = All; Caption = 'Own Expr'; CaptionClass = Cap3(); }
                field(CtlOtherNoCaption; Rec.Other) { ApplicationArea = All; }
                field(CtlAlone; Rec.Third) { ApplicationArea = All; Caption = 'Own Alone'; CaptionClass = '3,'; }
                field(CtlAloneExpr; Rec.Fourth) { ApplicationArea = All; Caption = 'Own Alone Expr'; CaptionClass = Cap3(); }
                field(CtlVar; Rec.Fifth) { ApplicationArea = All; Caption = 'Own Var'; CaptionClass = '3,' + CapText; }
            }
        }
    }

    local procedure Cap3(): Text
    begin
        exit('3,');
    end;

    var
        CapText: Text;
}

page 94218 "LT Y80 CC Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y80 CC Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CtlA; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl A'; }
                field(CtlLit; Rec.Plain) { ApplicationArea = All; Caption = 'Own Lit'; CaptionClass = '3,'; }
                field(CtlB; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl B'; }
                field(CtlExpr; Rec.Other) { ApplicationArea = All; Caption = 'Own Expr'; CaptionClass = Cap3(); }
                field(CtlOtherNoCaption; Rec.Other) { ApplicationArea = All; }
                field(CtlAlone; Rec.Third) { ApplicationArea = All; Caption = 'Own Alone'; CaptionClass = '3,'; }
                field(CtlAloneExpr; Rec.Fourth) { ApplicationArea = All; Caption = 'Own Alone Expr'; CaptionClass = Cap3(); }
                field(CtlVar; Rec.Fifth) { ApplicationArea = All; Caption = 'Own Var'; CaptionClass = '3,' + CapText; }
            }
        }
    }

    local procedure Cap3(): Text
    begin
        exit('3,');
    end;

    var
        CapText: Text;
}

page 94219 "LT Y80 CC ListPart"
{
    PageType = ListPart;
    SourceTable = "LT Y80 CC Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CtlA; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl A'; }
                field(CtlLit; Rec.Plain) { ApplicationArea = All; Caption = 'Own Lit'; CaptionClass = '3,'; }
                field(CtlB; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl B'; }
                field(CtlExpr; Rec.Other) { ApplicationArea = All; Caption = 'Own Expr'; CaptionClass = Cap3(); }
                field(CtlOtherNoCaption; Rec.Other) { ApplicationArea = All; }
                field(CtlAlone; Rec.Third) { ApplicationArea = All; Caption = 'Own Alone'; CaptionClass = '3,'; }
                field(CtlAloneExpr; Rec.Fourth) { ApplicationArea = All; Caption = 'Own Alone Expr'; CaptionClass = Cap3(); }
                field(CtlVar; Rec.Fifth) { ApplicationArea = All; Caption = 'Own Var'; CaptionClass = '3,' + CapText; }
            }
        }
    }

    local procedure Cap3(): Text
    begin
        exit('3,');
    end;

    var
        CapText: Text;
}

page 94220 "LT Y80 CC CardPart"
{
    PageType = CardPart;
    SourceTable = "LT Y80 CC Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(CtlA; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl A'; }
                field(CtlLit; Rec.Plain) { ApplicationArea = All; Caption = 'Own Lit'; CaptionClass = '3,'; }
                field(CtlB; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl B'; }
                field(CtlExpr; Rec.Other) { ApplicationArea = All; Caption = 'Own Expr'; CaptionClass = Cap3(); }
                field(CtlOtherNoCaption; Rec.Other) { ApplicationArea = All; }
                field(CtlAlone; Rec.Third) { ApplicationArea = All; Caption = 'Own Alone'; CaptionClass = '3,'; }
                field(CtlAloneExpr; Rec.Fourth) { ApplicationArea = All; Caption = 'Own Alone Expr'; CaptionClass = Cap3(); }
                field(CtlVar; Rec.Fifth) { ApplicationArea = All; Caption = 'Own Var'; CaptionClass = '3,' + CapText; }
            }
        }
    }

    local procedure Cap3(): Text
    begin
        exit('3,');
    end;

    var
        CapText: Text;
}

page 94221 "LT Y80 CC Doc"
{
    PageType = Document;
    SourceTable = "LT Y80 CC Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(LP; "LT Y80 CC ListPart") { ApplicationArea = All; }
            part(CP; "LT Y80 CC CardPart") { ApplicationArea = All; }
        }
    }
}

codeunit 94222 "LT Y80 CC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y80 CC Rec";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Plain := 'p1';
        Row.Insert();
        Row.Id := 2;
        Row.Plain := 'p2';
        Row.Insert();
    end;

    [Test]
    procedure Y80_CC_Card_OpenView()
    var
        P: TestPage "LT Y80 CC Card";
        Tag: Text;
    begin
        Seed();
        Tag := 'open';
        P.OpenView();
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        Observer.Expect('open CtlA', 'Ctl A');
        Observer.Expect('open CtlLit', 'Ctl B');
        Observer.Expect('open CtlB', 'Ctl B');
        Observer.Expect('open CtlExpr', 'Other Field');
        Observer.Expect('open CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open CtlAlone', 'Own Alone');
        Observer.Expect('open CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_Card_OpenEdit()
    var
        P: TestPage "LT Y80 CC Card";
        Tag: Text;
    begin
        Seed();
        Tag := 'open';
        P.OpenEdit();
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        Observer.Expect('open CtlA', 'Ctl A');
        Observer.Expect('open CtlLit', 'Ctl B');
        Observer.Expect('open CtlB', 'Ctl B');
        Observer.Expect('open CtlExpr', 'Other Field');
        Observer.Expect('open CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open CtlAlone', 'Own Alone');
        Observer.Expect('open CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_Card_OpenNew()
    var
        P: TestPage "LT Y80 CC Card";
        Tag: Text;
    begin
        Seed();
        Tag := 'open';
        P.OpenNew();
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        Observer.Expect('open CtlA', 'Ctl A');
        Observer.Expect('open CtlLit', 'Ctl B');
        Observer.Expect('open CtlB', 'Ctl B');
        Observer.Expect('open CtlExpr', 'Other Field');
        Observer.Expect('open CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open CtlAlone', 'Own Alone');
        Observer.Expect('open CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_List_OpenView()
    var
        P: TestPage "LT Y80 CC List";
        Tag: Text;
    begin
        Seed();
        Tag := 'open';
        P.OpenView();
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        Observer.Expect('open CtlA', 'Ctl A');
        Observer.Expect('open CtlLit', 'Ctl B');
        Observer.Expect('open CtlB', 'Ctl B');
        Observer.Expect('open CtlExpr', 'Other Field');
        Observer.Expect('open CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open CtlAlone', 'Own Alone');
        Observer.Expect('open CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_List_OpenEdit()
    var
        P: TestPage "LT Y80 CC List";
        Tag: Text;
    begin
        Seed();
        Tag := 'open';
        P.OpenEdit();
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        Observer.Expect('open CtlA', 'Ctl A');
        Observer.Expect('open CtlLit', 'Ctl B');
        Observer.Expect('open CtlB', 'Ctl B');
        Observer.Expect('open CtlExpr', 'Other Field');
        Observer.Expect('open CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open CtlAlone', 'Own Alone');
        Observer.Expect('open CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_Worksheet_OpenView()
    var
        P: TestPage "LT Y80 CC Worksheet";
        Tag: Text;
    begin
        Seed();
        Tag := 'open';
        P.OpenView();
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        Observer.Expect('open CtlA', 'Ctl A');
        Observer.Expect('open CtlLit', 'Ctl B');
        Observer.Expect('open CtlB', 'Ctl B');
        Observer.Expect('open CtlExpr', 'Other Field');
        Observer.Expect('open CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open CtlAlone', 'Own Alone');
        Observer.Expect('open CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_Worksheet_OpenEdit()
    var
        P: TestPage "LT Y80 CC Worksheet";
        Tag: Text;
    begin
        Seed();
        Tag := 'open';
        P.OpenEdit();
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        Observer.Expect('open CtlA', 'Ctl A');
        Observer.Expect('open CtlLit', 'Ctl B');
        Observer.Expect('open CtlB', 'Ctl B');
        Observer.Expect('open CtlExpr', 'Other Field');
        Observer.Expect('open CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open CtlAlone', 'Own Alone');
        Observer.Expect('open CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_Doc_OpenView()
    var
        P: TestPage "LT Y80 CC Doc";
        Tag: Text;
    begin
        Seed();
        Tag := 'open';
        P.OpenView();
        Observer.Observe(Tag + ' LP CtlA', P.LP.CtlA.Caption());
        Observer.Observe(Tag + ' LP CtlLit', P.LP.CtlLit.Caption());
        Observer.Observe(Tag + ' LP CtlB', P.LP.CtlB.Caption());
        Observer.Observe(Tag + ' LP CtlExpr', P.LP.CtlExpr.Caption());
        Observer.Observe(Tag + ' LP CtlOtherNoCaption', P.LP.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' LP CtlAlone', P.LP.CtlAlone.Caption());
        Observer.Observe(Tag + ' LP CtlAloneExpr', P.LP.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' LP CtlVar', P.LP.CtlVar.Caption());
        Observer.Observe(Tag + ' CP CtlA', P.CP.CtlA.Caption());
        Observer.Observe(Tag + ' CP CtlLit', P.CP.CtlLit.Caption());
        Observer.Observe(Tag + ' CP CtlB', P.CP.CtlB.Caption());
        Observer.Observe(Tag + ' CP CtlExpr', P.CP.CtlExpr.Caption());
        Observer.Observe(Tag + ' CP CtlOtherNoCaption', P.CP.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CP CtlAlone', P.CP.CtlAlone.Caption());
        Observer.Observe(Tag + ' CP CtlAloneExpr', P.CP.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CP CtlVar', P.CP.CtlVar.Caption());
        Observer.Expect('open LP CtlA', 'Ctl A');
        Observer.Expect('open LP CtlLit', 'Ctl B');
        Observer.Expect('open LP CtlB', 'Ctl B');
        Observer.Expect('open LP CtlExpr', 'Other Field');
        Observer.Expect('open LP CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open LP CtlAlone', 'Own Alone');
        Observer.Expect('open LP CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open LP CtlVar', 'Own Var');
        Observer.Expect('open CP CtlA', 'Ctl A');
        Observer.Expect('open CP CtlLit', 'Ctl B');
        Observer.Expect('open CP CtlB', 'Ctl B');
        Observer.Expect('open CP CtlExpr', 'Other Field');
        Observer.Expect('open CP CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open CP CtlAlone', 'Own Alone');
        Observer.Expect('open CP CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open CP CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_Doc_OpenEdit()
    var
        P: TestPage "LT Y80 CC Doc";
        Tag: Text;
    begin
        Seed();
        Tag := 'open';
        P.OpenEdit();
        Observer.Observe(Tag + ' LP CtlA', P.LP.CtlA.Caption());
        Observer.Observe(Tag + ' LP CtlLit', P.LP.CtlLit.Caption());
        Observer.Observe(Tag + ' LP CtlB', P.LP.CtlB.Caption());
        Observer.Observe(Tag + ' LP CtlExpr', P.LP.CtlExpr.Caption());
        Observer.Observe(Tag + ' LP CtlOtherNoCaption', P.LP.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' LP CtlAlone', P.LP.CtlAlone.Caption());
        Observer.Observe(Tag + ' LP CtlAloneExpr', P.LP.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' LP CtlVar', P.LP.CtlVar.Caption());
        Observer.Observe(Tag + ' CP CtlA', P.CP.CtlA.Caption());
        Observer.Observe(Tag + ' CP CtlLit', P.CP.CtlLit.Caption());
        Observer.Observe(Tag + ' CP CtlB', P.CP.CtlB.Caption());
        Observer.Observe(Tag + ' CP CtlExpr', P.CP.CtlExpr.Caption());
        Observer.Observe(Tag + ' CP CtlOtherNoCaption', P.CP.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CP CtlAlone', P.CP.CtlAlone.Caption());
        Observer.Observe(Tag + ' CP CtlAloneExpr', P.CP.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CP CtlVar', P.CP.CtlVar.Caption());
        Observer.Expect('open LP CtlA', 'Ctl A');
        Observer.Expect('open LP CtlLit', 'Ctl B');
        Observer.Expect('open LP CtlB', 'Ctl B');
        Observer.Expect('open LP CtlExpr', 'Other Field');
        Observer.Expect('open LP CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open LP CtlAlone', 'Own Alone');
        Observer.Expect('open LP CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open LP CtlVar', 'Own Var');
        Observer.Expect('open CP CtlA', 'Ctl A');
        Observer.Expect('open CP CtlLit', 'Ctl B');
        Observer.Expect('open CP CtlB', 'Ctl B');
        Observer.Expect('open CP CtlExpr', 'Other Field');
        Observer.Expect('open CP CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open CP CtlAlone', 'Own Alone');
        Observer.Expect('open CP CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open CP CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_Doc_OpenNew()
    var
        P: TestPage "LT Y80 CC Doc";
        Tag: Text;
    begin
        Seed();
        Tag := 'open';
        P.OpenNew();
        Observer.Observe(Tag + ' LP CtlA', P.LP.CtlA.Caption());
        Observer.Observe(Tag + ' LP CtlLit', P.LP.CtlLit.Caption());
        Observer.Observe(Tag + ' LP CtlB', P.LP.CtlB.Caption());
        Observer.Observe(Tag + ' LP CtlExpr', P.LP.CtlExpr.Caption());
        Observer.Observe(Tag + ' LP CtlOtherNoCaption', P.LP.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' LP CtlAlone', P.LP.CtlAlone.Caption());
        Observer.Observe(Tag + ' LP CtlAloneExpr', P.LP.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' LP CtlVar', P.LP.CtlVar.Caption());
        Observer.Observe(Tag + ' CP CtlA', P.CP.CtlA.Caption());
        Observer.Observe(Tag + ' CP CtlLit', P.CP.CtlLit.Caption());
        Observer.Observe(Tag + ' CP CtlB', P.CP.CtlB.Caption());
        Observer.Observe(Tag + ' CP CtlExpr', P.CP.CtlExpr.Caption());
        Observer.Observe(Tag + ' CP CtlOtherNoCaption', P.CP.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CP CtlAlone', P.CP.CtlAlone.Caption());
        Observer.Observe(Tag + ' CP CtlAloneExpr', P.CP.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CP CtlVar', P.CP.CtlVar.Caption());
        Observer.Expect('open LP CtlA', 'Ctl A');
        Observer.Expect('open LP CtlLit', 'Ctl B');
        Observer.Expect('open LP CtlB', 'Ctl B');
        Observer.Expect('open LP CtlExpr', 'Other Field');
        Observer.Expect('open LP CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open LP CtlAlone', 'Own Alone');
        Observer.Expect('open LP CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open LP CtlVar', 'Own Var');
        Observer.Expect('open CP CtlA', 'Ctl A');
        Observer.Expect('open CP CtlLit', 'Ctl B');
        Observer.Expect('open CP CtlB', 'Ctl B');
        Observer.Expect('open CP CtlExpr', 'Other Field');
        Observer.Expect('open CP CtlOtherNoCaption', 'Other Field');
        Observer.Expect('open CP CtlAlone', 'Own Alone');
        Observer.Expect('open CP CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('open CP CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_Card_AfterNextAndSetValue()
    var
        P: TestPage "LT Y80 CC Card";
        Tag: Text;
    begin
        Seed();
        P.OpenEdit();
        Tag := 'next';
        P.Next();
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        Tag := 'set';
        P.CtlA.SetValue('changed');
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        P.Close();
        Observer.Expect('next CtlA', 'Ctl A');
        Observer.Expect('next CtlLit', 'Ctl B');
        Observer.Expect('next CtlB', 'Ctl B');
        Observer.Expect('next CtlExpr', 'Other Field');
        Observer.Expect('next CtlOtherNoCaption', 'Other Field');
        Observer.Expect('next CtlAlone', 'Own Alone');
        Observer.Expect('next CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('next CtlVar', 'Own Var');
        Observer.Expect('set CtlA', 'Ctl A');
        Observer.Expect('set CtlLit', 'Ctl B');
        Observer.Expect('set CtlB', 'Ctl B');
        Observer.Expect('set CtlExpr', 'Other Field');
        Observer.Expect('set CtlOtherNoCaption', 'Other Field');
        Observer.Expect('set CtlAlone', 'Own Alone');
        Observer.Expect('set CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('set CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_List_AfterNextAndSetValue()
    var
        P: TestPage "LT Y80 CC List";
        Tag: Text;
    begin
        Seed();
        P.OpenEdit();
        Tag := 'next';
        P.Next();
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        Tag := 'set';
        P.CtlA.SetValue('changed');
        Observer.Observe(Tag + ' CtlA', P.CtlA.Caption());
        Observer.Observe(Tag + ' CtlLit', P.CtlLit.Caption());
        Observer.Observe(Tag + ' CtlB', P.CtlB.Caption());
        Observer.Observe(Tag + ' CtlExpr', P.CtlExpr.Caption());
        Observer.Observe(Tag + ' CtlOtherNoCaption', P.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CtlAlone', P.CtlAlone.Caption());
        Observer.Observe(Tag + ' CtlAloneExpr', P.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CtlVar', P.CtlVar.Caption());
        P.Close();
        Observer.Expect('next CtlA', 'Ctl A');
        Observer.Expect('next CtlLit', 'Ctl B');
        Observer.Expect('next CtlB', 'Ctl B');
        Observer.Expect('next CtlExpr', 'Other Field');
        Observer.Expect('next CtlOtherNoCaption', 'Other Field');
        Observer.Expect('next CtlAlone', 'Own Alone');
        Observer.Expect('next CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('next CtlVar', 'Own Var');
        Observer.Expect('set CtlA', 'Ctl A');
        Observer.Expect('set CtlLit', 'Ctl B');
        Observer.Expect('set CtlB', 'Ctl B');
        Observer.Expect('set CtlExpr', 'Other Field');
        Observer.Expect('set CtlOtherNoCaption', 'Other Field');
        Observer.Expect('set CtlAlone', 'Own Alone');
        Observer.Expect('set CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('set CtlVar', 'Own Var');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_CC_Doc_AfterNext()
    var
        P: TestPage "LT Y80 CC Doc";
        Tag: Text;
    begin
        Seed();
        P.OpenEdit();
        Tag := 'next';
        P.Next();
        Observer.Observe(Tag + ' LP CtlA', P.LP.CtlA.Caption());
        Observer.Observe(Tag + ' LP CtlLit', P.LP.CtlLit.Caption());
        Observer.Observe(Tag + ' LP CtlB', P.LP.CtlB.Caption());
        Observer.Observe(Tag + ' LP CtlExpr', P.LP.CtlExpr.Caption());
        Observer.Observe(Tag + ' LP CtlOtherNoCaption', P.LP.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' LP CtlAlone', P.LP.CtlAlone.Caption());
        Observer.Observe(Tag + ' LP CtlAloneExpr', P.LP.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' LP CtlVar', P.LP.CtlVar.Caption());
        Observer.Observe(Tag + ' CP CtlA', P.CP.CtlA.Caption());
        Observer.Observe(Tag + ' CP CtlLit', P.CP.CtlLit.Caption());
        Observer.Observe(Tag + ' CP CtlB', P.CP.CtlB.Caption());
        Observer.Observe(Tag + ' CP CtlExpr', P.CP.CtlExpr.Caption());
        Observer.Observe(Tag + ' CP CtlOtherNoCaption', P.CP.CtlOtherNoCaption.Caption());
        Observer.Observe(Tag + ' CP CtlAlone', P.CP.CtlAlone.Caption());
        Observer.Observe(Tag + ' CP CtlAloneExpr', P.CP.CtlAloneExpr.Caption());
        Observer.Observe(Tag + ' CP CtlVar', P.CP.CtlVar.Caption());
        P.Close();
        Observer.Expect('next LP CtlA', 'Ctl A');
        Observer.Expect('next LP CtlLit', 'Ctl B');
        Observer.Expect('next LP CtlB', 'Ctl B');
        Observer.Expect('next LP CtlExpr', 'Other Field');
        Observer.Expect('next LP CtlOtherNoCaption', 'Other Field');
        Observer.Expect('next LP CtlAlone', 'Own Alone');
        Observer.Expect('next LP CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('next LP CtlVar', 'Own Var');
        Observer.Expect('next CP CtlA', 'Ctl A');
        Observer.Expect('next CP CtlLit', 'Ctl B');
        Observer.Expect('next CP CtlB', 'Ctl B');
        Observer.Expect('next CP CtlExpr', 'Other Field');
        Observer.Expect('next CP CtlOtherNoCaption', 'Other Field');
        Observer.Expect('next CP CtlAlone', 'Own Alone');
        Observer.Expect('next CP CtlAloneExpr', 'Own Alone Expr');
        Observer.Expect('next CP CtlVar', 'Own Var');
        Observer.Verify();
    end;
}
