// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionfields-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects in Y37ListCaptionObjects.al (92623 - 92637)
// Probe: gap cycle 3 spec C3-13. Every literal asserted below is what the BC service tier produced.
// Facts: TestPage.Caption() of a List, Worksheet and ListPart whose record carries a filter: on a field the page's DataCaptionFields names,
//   on a field the table's DataCaptionFields names, on a primary-key field when neither names any, on a FlowFilter; single values,
//   ranges, | lists, wildcards, blank; two caption fields; filter group 2 (SourceTableView, OnOpenPage, the caller); a filter set
//   through TestPage.Filter; Date and Option values. Read in a ModalPageHandler for Page.RunModal, through TestPage.Trap for Page.Run.
// BC versions: 27, 28, 29

codeunit 92638 "LT Y37 Cap Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Cap: Text;

    local procedure Seed()
    var
        B: Record "LT Y37 Cap B";
        B2: Record "LT Y37 Cap B2";
        H: Record "LT Y37 Cap HL";
        L: Record "LT Y37 Cap LL";
    begin
        B.DeleteAll();
        B2.DeleteAll();
        H.DeleteAll();
        L.DeleteAll();
        AddB('B1', 'Z1', 'A1', DMY2Date(5, 3, 2024), 0);
        AddB('B2', 'Z1', 'A2', DMY2Date(6, 3, 2024), 1);
        AddB('B3', 'Z2', 'A1', DMY2Date(7, 3, 2024), 1);
        AddB2('B1', 'Z1', 'A1');
        AddB2('B2', 'Z1', 'A2');
        AddB2('B3', 'Z2', 'A1');
        H."No." := 'H1';
        H.Insert();
        H."No." := 'H2';
        H.Insert();
        L."Doc No." := 'H1';
        L."Line No." := 10000;
        L.Zone := 'Z1';
        L.Insert();
        L."Line No." := 20000;
        L.Insert();
    end;

    local procedure AddB(Code: Code[20]; Zone: Code[10]; AreaCode: Code[10]; Dt: Date; Kind: Integer)
    var
        B: Record "LT Y37 Cap B";
    begin
        B."Code" := Code;
        B.Zone := Zone;
        B."Area" := AreaCode;
        B.Dt := Dt;
        B.Kind := Kind;
        B.Insert();
    end;

    local procedure AddB2(Code: Code[20]; Zone: Code[10]; AreaCode: Code[10])
    var
        B2: Record "LT Y37 Cap B2";
    begin
        B2."Code" := Code;
        B2.Zone := Zone;
        B2."Area" := AreaCode;
        B2.Insert();
    end;

    local procedure RunLZ(Name: Text; var B: Record "LT Y37 Cap B")
    begin
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LZ", B);
        Observer.Observe(Name, Cap);
    end;

    [ModalPageHandler]
    procedure HLZ(var P: TestPage "LT Y37 Cap LZ")
    begin
        Cap := P.Caption();
    end;

    [ModalPageHandler]
    procedure HLN(var P: TestPage "LT Y37 Cap LN")
    begin
        Cap := P.Caption();
    end;

    [ModalPageHandler]
    procedure HLT(var P: TestPage "LT Y37 Cap LT")
    begin
        Cap := P.Caption();
    end;

    [ModalPageHandler]
    procedure HLZA(var P: TestPage "LT Y37 Cap LZA")
    begin
        Cap := P.Caption();
    end;

    [ModalPageHandler]
    procedure HWZ(var P: TestPage "LT Y37 Cap WZ")
    begin
        Cap := P.Caption();
    end;

    [ModalPageHandler]
    procedure HLG(var P: TestPage "LT Y37 Cap LG")
    begin
        Cap := P.Caption();
    end;

    [ModalPageHandler]
    procedure HLGO(var P: TestPage "LT Y37 Cap LGO")
    begin
        Cap := P.Caption();
    end;

    [ModalPageHandler]
    procedure HLD(var P: TestPage "LT Y37 Cap LD")
    begin
        Cap := P.Caption();
    end;

    [ModalPageHandler]
    procedure HLK(var P: TestPage "LT Y37 Cap LK")
    begin
        Cap := P.Caption();
    end;

    [Test]
    [HandlerFunctions('HLZ')]
    procedure LT_C313_PageDCF_SetRange()
    var
        B: Record "LT Y37 Cap B";
    begin
        Seed();
        RunLZ('none', B);
        B.SetRange(Zone, 'Z1');
        RunLZ('zone Z1', B);
        B.SetRange(Zone, 'Z2');
        RunLZ('zone Z2', B);
        B.Reset();
        B.SetRange("Code", 'B1');
        RunLZ('pk only', B);
        B.Reset();
        B.SetFilter("Item Filter", 'I1');
        RunLZ('flowfilter only', B);
        B.SetRange("Code", 'B1');
        B.SetRange(Zone, 'Z1');
        RunLZ('all three', B);
        Observer.Expect('none', 'C313 Zone List');
        Observer.Expect('zone Z1', 'C313 Zone List - Z1');
        Observer.Expect('zone Z2', 'C313 Zone List - Z2');
        Observer.Expect('pk only', 'C313 Zone List');
        Observer.Expect('flowfilter only', 'C313 Zone List');
        Observer.Expect('all three', 'C313 Zone List - Z1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLN')]
    procedure LT_C313_NoDCF_FilterOnPK1()
    var
        B: Record "LT Y37 Cap B";
        Pg: Page "LT Y37 Cap LN";
        P: TestPage "LT Y37 Cap LN";
    begin
        Seed();
        B.SetRange("Code", 'B1');
        P.Trap();
        Pg.SetTableView(B);
        Pg.Run();
        Observer.Observe('run pk', P.Caption());
        P.Close();
        Clear(Pg);
        B.Reset();
        B.SetRange(Zone, 'Z1');
        P.Trap();
        Pg.SetTableView(B);
        Pg.Run();
        Observer.Observe('run zone', P.Caption());
        P.Close();
        B.Reset();
        B.SetFilter("Code", 'B1..B2');
        P.Trap();
        Page.Run(Page::"LT Y37 Cap LN", B);
        Observer.Observe('page.run pk range', P.Caption());
        P.Close();
        B.Reset();
        B.SetRange("Code", 'B1');
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LN", B);
        Observer.Observe('runmodal pk', Cap);
        Observer.Expect('run pk', 'C313 Plain List');
        Observer.Expect('run zone', 'C313 Plain List');
        Observer.Expect('page.run pk range', 'C313 Plain List');
        Observer.Expect('runmodal pk', 'C313 Plain List');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C313_Part_LinkOnPK()
    var
        D: TestPage "LT Y37 Cap D";
    begin
        Seed();
        D.OpenEdit();
        D.GoToKey('H1');
        Observer.Observe('h1 part', D.Lines.Caption());
        Observer.Observe('h1 host', D.Caption());
        Observer.Observe('next', Format(D.Next()));
        Observer.Observe('h2 part', D.Lines.Caption());
        Observer.Observe('h2 host', D.Caption());
        D.Close();
        D.OpenView();
        D.GoToKey('H2');
        Observer.Observe('h2 direct part', D.Lines.Caption());
        D.Close();
        Observer.Expect('h1 part', 'C313 Lines');
        Observer.Expect('h1 host', 'C313 Doc - H1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('h2 part', 'C313 Lines');
        Observer.Expect('h2 host', 'C313 Doc - H2');
        Observer.Expect('h2 direct part', 'C313 Lines');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLT')]
    procedure LT_C313_TableDCF_SetRange()
    var
        B2: Record "LT Y37 Cap B2";
    begin
        Seed();
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LT", B2);
        Observer.Observe('none', Cap);
        B2.SetRange(Zone, 'Z1');
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LT", B2);
        Observer.Observe('zone Z1', Cap);
        B2.Reset();
        B2.SetRange("Code", 'B1');
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LT", B2);
        Observer.Observe('pk only', Cap);
        Observer.Expect('none', 'C313 Table DCF List');
        Observer.Expect('zone Z1', 'C313 Table DCF List');
        Observer.Expect('pk only', 'C313 Table DCF List');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HWZ')]
    procedure LT_C313_Worksheet_PageDCF_SetRange()
    var
        B: Record "LT Y37 Cap B";
    begin
        Seed();
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap WZ", B);
        Observer.Observe('none', Cap);
        B.SetRange(Zone, 'Z1');
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap WZ", B);
        Observer.Observe('zone Z1', Cap);
        Observer.Expect('none', 'C313 Zone Worksheet');
        Observer.Expect('zone Z1', 'C313 Zone Worksheet - Z1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLZ')]
    procedure LT_C313_PageDCF_FilterKinds()
    var
        B: Record "LT Y37 Cap B";
    begin
        Seed();
        B.SetFilter(Zone, 'Z1|Z2');
        RunLZ('or list', B);
        B.SetFilter(Zone, 'Z1..Z2');
        RunLZ('range', B);
        B.SetFilter(Zone, 'Z*');
        RunLZ('wildcard', B);
        B.SetRange(Zone, '');
        RunLZ('blank', B);
        B.SetFilter(Zone, '<>Z2');
        RunLZ('not equal', B);
        B.SetFilter(Zone, '%1', 'Z2');
        RunLZ('setfilter single', B);
        Observer.Expect('or list', 'C313 Zone List');
        Observer.Expect('range', 'C313 Zone List');
        Observer.Expect('wildcard', 'C313 Zone List');
        Observer.Expect('blank', 'C313 Zone List');
        Observer.Expect('not equal', 'C313 Zone List');
        Observer.Expect('setfilter single', 'C313 Zone List - Z2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLZA')]
    procedure LT_C313_TwoDCF()
    var
        B: Record "LT Y37 Cap B";
    begin
        Seed();
        B.SetRange(Zone, 'Z1');
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LZA", B);
        Observer.Observe('zone only', Cap);
        B.Reset();
        B.SetRange("Area", 'A1');
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LZA", B);
        Observer.Observe('area only', Cap);
        B.SetRange(Zone, 'Z1');
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LZA", B);
        Observer.Observe('both', Cap);
        Observer.Expect('zone only', 'C313 Zone Area List - Z1');
        Observer.Expect('area only', 'C313 Zone Area List - A1');
        Observer.Expect('both', 'C313 Zone Area List - Z1 ∙ A1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLG,HLGO,HLZ')]
    procedure LT_C313_FilterGroup()
    var
        B: Record "LT Y37 Cap B";
    begin
        Seed();
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LG", B);
        Observer.Observe('sourcetableview', Cap);
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LGO", B);
        Observer.Observe('onopenpage group 2', Cap);
        B.FilterGroup(2);
        B.SetRange(Zone, 'Z1');
        B.FilterGroup(0);
        RunLZ('caller group 2', B);
        Observer.Expect('sourcetableview', 'C313 View List - Z1');
        Observer.Expect('onopenpage group 2', 'C313 Group List - Z1');
        Observer.Expect('caller group 2', 'C313 Zone List - Z1');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C313_TestPageFilter()
    var
        P: TestPage "LT Y37 Cap LZ";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', P.Caption());
        P.Filter.SetFilter(Zone, 'Z1');
        Observer.Observe('filter Z1', P.Caption());
        P.Filter.SetFilter(Zone, '');
        Observer.Observe('cleared', P.Caption());
        P.Close();
        Observer.Expect('open', 'C313 Zone List');
        Observer.Expect('filter Z1', 'C313 Zone List - Z1');
        Observer.Expect('cleared', 'C313 Zone List');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLD')]
    procedure LT_C313_DCF_Date()
    var
        B: Record "LT Y37 Cap B";
    begin
        Seed();
        B.SetRange(Dt, DMY2Date(5, 3, 2024));
        Cap := '<not run>';
        asserterror Page.RunModal(Page::"LT Y37 Cap LD", B);
        Observer.Observe('date caption', Cap);
        Observer.Observe('date error', CopyStr(GetLastErrorText(), 1, 160));
        Observer.Observe('date code', GetLastErrorCode());
        ClearLastError();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HLK')]
    procedure LT_C313_DCF_Option()
    var
        B: Record "LT Y37 Cap B";
    begin
        Seed();
        B.SetRange(Kind, B.Kind::B);
        Cap := '<not run>';
        Page.RunModal(Page::"LT Y37 Cap LK", B);
        Observer.Observe('option', Cap);
        Observer.Finish();
    end;
}
