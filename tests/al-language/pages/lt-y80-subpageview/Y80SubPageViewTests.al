// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects of Y80SubPageViewObjects.al
// Probe (writer Y80): see Y80SubPageViewObjects.al. Observation form: the first run reads the values, the asserts follow.
// BC versions: 27, 28, 29

codeunit 94214 "LT Y80 SV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y80 SV Log";

    local procedure Seed()
    var
        Head: Record "LT Y80 SV Head";
        Line: Record "LT Y80 SV Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Log.Reset();
        InsertHead('H1');
        InsertHead('H2');
        InsertHead('H3');
        InsertLine('H1', 10000);
        InsertLine('H1', 20000);
        InsertLine('H2', 10000);
        InsertLine('H2', 20000);
        InsertLine('H3', 10000);
    end;

    local procedure InsertHead(HeadCode: Code[20])
    var
        Head: Record "LT Y80 SV Head";
    begin
        Head."Code" := HeadCode;
        Head.Insert();
    end;

    local procedure InsertLine(HeadCode: Code[20]; LineNo: Integer)
    var
        Line: Record "LT Y80 SV Line";
    begin
        Line."Head Code" := HeadCode;
        Line."Line No." := LineNo;
        Line.Insert();
    end;

    local procedure RowsF1(var Doc: TestPage "LT Y80 SV Host F1"; Tag: Text)
    var
        RowsText: Text;
    begin
        Observer.Observe(Tag + ' log', Log.Take());
        RowsText := '';
        if Doc.PartF1.First() then
            repeat
                RowsText += Doc.PartF1.HeadCtl.Value() + '/' + Doc.PartF1.LineNoCtl.Value() + ',';
            until not Doc.PartF1.Next();
        Observer.Observe(Tag + ' rows F1', RowsText);
        Observer.Observe(Tag + ' log reading rows', Log.Take());
    end;

    [Test]
    procedure Y80_SV_F1_OpenView()
    var
        Doc: TestPage "LT Y80 SV Host F1";
    begin
        Seed();
        Doc.OpenView();
        RowsF1(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F1_OpenEdit()
    var
        Doc: TestPage "LT Y80 SV Host F1";
    begin
        Seed();
        Doc.OpenEdit();
        RowsF1(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F1_OpenNew()
    var
        Doc: TestPage "LT Y80 SV Host F1";
    begin
        Seed();
        Doc.OpenNew();
        RowsF1(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F1_HostMoves()
    var
        Doc: TestPage "LT Y80 SV Host F1";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('open', Log.Take());
        Observer.Observe('next', Format(Doc.Next(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF1(Doc, 'next');
        Observer.Observe('last', Format(Doc.Last(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF1(Doc, 'last');
        Observer.Observe('previous', Format(Doc.Previous(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF1(Doc, 'previous');
        Observer.Observe('first', Format(Doc.First(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF1(Doc, 'first');
        Observer.Observe('goto', Format(Doc.GoToKey('H2'), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF1(Doc, 'goto');
        Doc.Close();
        Observer.Finish();
    end;

    local procedure RowsF2(var Doc: TestPage "LT Y80 SV Host F2"; Tag: Text)
    var
        RowsText: Text;
    begin
        Observer.Observe(Tag + ' log', Log.Take());
        RowsText := '';
        if Doc.PartF2.First() then
            repeat
                RowsText += Doc.PartF2.HeadCtl.Value() + '/' + Doc.PartF2.LineNoCtl.Value() + ',';
            until not Doc.PartF2.Next();
        Observer.Observe(Tag + ' rows F2', RowsText);
        Observer.Observe(Tag + ' log reading rows', Log.Take());
    end;

    [Test]
    procedure Y80_SV_F2_OpenView()
    var
        Doc: TestPage "LT Y80 SV Host F2";
    begin
        Seed();
        Doc.OpenView();
        RowsF2(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F2_OpenEdit()
    var
        Doc: TestPage "LT Y80 SV Host F2";
    begin
        Seed();
        Doc.OpenEdit();
        RowsF2(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F2_OpenNew()
    var
        Doc: TestPage "LT Y80 SV Host F2";
    begin
        Seed();
        Doc.OpenNew();
        RowsF2(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F2_HostMoves()
    var
        Doc: TestPage "LT Y80 SV Host F2";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('open', Log.Take());
        Observer.Observe('next', Format(Doc.Next(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF2(Doc, 'next');
        Observer.Observe('last', Format(Doc.Last(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF2(Doc, 'last');
        Observer.Observe('previous', Format(Doc.Previous(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF2(Doc, 'previous');
        Observer.Observe('first', Format(Doc.First(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF2(Doc, 'first');
        Observer.Observe('goto', Format(Doc.GoToKey('H2'), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF2(Doc, 'goto');
        Doc.Close();
        Observer.Finish();
    end;

    local procedure RowsF3(var Doc: TestPage "LT Y80 SV Host F3"; Tag: Text)
    var
        RowsText: Text;
    begin
        Observer.Observe(Tag + ' log', Log.Take());
        RowsText := '';
        if Doc.PartF3.First() then
            repeat
                RowsText += Doc.PartF3.HeadCtl.Value() + '/' + Doc.PartF3.LineNoCtl.Value() + ',';
            until not Doc.PartF3.Next();
        Observer.Observe(Tag + ' rows F3', RowsText);
        Observer.Observe(Tag + ' log reading rows', Log.Take());
    end;

    [Test]
    procedure Y80_SV_F3_OpenView()
    var
        Doc: TestPage "LT Y80 SV Host F3";
    begin
        Seed();
        Doc.OpenView();
        RowsF3(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F3_OpenEdit()
    var
        Doc: TestPage "LT Y80 SV Host F3";
    begin
        Seed();
        Doc.OpenEdit();
        RowsF3(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F3_OpenNew()
    var
        Doc: TestPage "LT Y80 SV Host F3";
    begin
        Seed();
        Doc.OpenNew();
        RowsF3(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F3_HostMoves()
    var
        Doc: TestPage "LT Y80 SV Host F3";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('open', Log.Take());
        Observer.Observe('next', Format(Doc.Next(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF3(Doc, 'next');
        Observer.Observe('last', Format(Doc.Last(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF3(Doc, 'last');
        Observer.Observe('previous', Format(Doc.Previous(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF3(Doc, 'previous');
        Observer.Observe('first', Format(Doc.First(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF3(Doc, 'first');
        Observer.Observe('goto', Format(Doc.GoToKey('H2'), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF3(Doc, 'goto');
        Doc.Close();
        Observer.Finish();
    end;

    local procedure RowsF4(var Doc: TestPage "LT Y80 SV Host F4"; Tag: Text)
    var
        RowsText: Text;
    begin
        Observer.Observe(Tag + ' log', Log.Take());
        RowsText := '';
        if Doc.PartF4.First() then
            repeat
                RowsText += Doc.PartF4.HeadCtl.Value() + '/' + Doc.PartF4.LineNoCtl.Value() + ',';
            until not Doc.PartF4.Next();
        Observer.Observe(Tag + ' rows F4', RowsText);
        Observer.Observe(Tag + ' log reading rows', Log.Take());
    end;

    [Test]
    procedure Y80_SV_F4_OpenView()
    var
        Doc: TestPage "LT Y80 SV Host F4";
    begin
        Seed();
        Doc.OpenView();
        RowsF4(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F4_OpenEdit()
    var
        Doc: TestPage "LT Y80 SV Host F4";
    begin
        Seed();
        Doc.OpenEdit();
        RowsF4(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F4_OpenNew()
    var
        Doc: TestPage "LT Y80 SV Host F4";
    begin
        Seed();
        Doc.OpenNew();
        RowsF4(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_F4_HostMoves()
    var
        Doc: TestPage "LT Y80 SV Host F4";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('open', Log.Take());
        Observer.Observe('next', Format(Doc.Next(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF4(Doc, 'next');
        Observer.Observe('last', Format(Doc.Last(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF4(Doc, 'last');
        Observer.Observe('previous', Format(Doc.Previous(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF4(Doc, 'previous');
        Observer.Observe('first', Format(Doc.First(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF4(Doc, 'first');
        Observer.Observe('goto', Format(Doc.GoToKey('H2'), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsF4(Doc, 'goto');
        Doc.Close();
        Observer.Finish();
    end;

    local procedure RowsAll(var Doc: TestPage "LT Y80 SV Host All"; Tag: Text)
    var
        RowsText: Text;
    begin
        Observer.Observe(Tag + ' log', Log.Take());
        RowsText := '';
        if Doc.PartF1.First() then
            repeat
                RowsText += Doc.PartF1.HeadCtl.Value() + '/' + Doc.PartF1.LineNoCtl.Value() + ',';
            until not Doc.PartF1.Next();
        Observer.Observe(Tag + ' rows F1', RowsText);
        RowsText := '';
        if Doc.PartF2.First() then
            repeat
                RowsText += Doc.PartF2.HeadCtl.Value() + '/' + Doc.PartF2.LineNoCtl.Value() + ',';
            until not Doc.PartF2.Next();
        Observer.Observe(Tag + ' rows F2', RowsText);
        RowsText := '';
        if Doc.PartF3.First() then
            repeat
                RowsText += Doc.PartF3.HeadCtl.Value() + '/' + Doc.PartF3.LineNoCtl.Value() + ',';
            until not Doc.PartF3.Next();
        Observer.Observe(Tag + ' rows F3', RowsText);
        RowsText := '';
        if Doc.PartF4.First() then
            repeat
                RowsText += Doc.PartF4.HeadCtl.Value() + '/' + Doc.PartF4.LineNoCtl.Value() + ',';
            until not Doc.PartF4.Next();
        Observer.Observe(Tag + ' rows F4', RowsText);
        Observer.Observe(Tag + ' log reading rows', Log.Take());
    end;

    [Test]
    procedure Y80_SV_All_OpenView()
    var
        Doc: TestPage "LT Y80 SV Host All";
    begin
        Seed();
        Doc.OpenView();
        RowsAll(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_All_OpenEdit()
    var
        Doc: TestPage "LT Y80 SV Host All";
    begin
        Seed();
        Doc.OpenEdit();
        RowsAll(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_All_OpenNew()
    var
        Doc: TestPage "LT Y80 SV Host All";
    begin
        Seed();
        Doc.OpenNew();
        RowsAll(Doc, 'open');
        Doc.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y80_SV_All_HostMoves()
    var
        Doc: TestPage "LT Y80 SV Host All";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('open', Log.Take());
        Observer.Observe('next', Format(Doc.Next(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsAll(Doc, 'next');
        Observer.Observe('last', Format(Doc.Last(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsAll(Doc, 'last');
        Observer.Observe('previous', Format(Doc.Previous(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsAll(Doc, 'previous');
        Observer.Observe('first', Format(Doc.First(), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsAll(Doc, 'first');
        Observer.Observe('goto', Format(Doc.GoToKey('H2'), 0, 9) + '/' + Doc.CodeCtl.Value());
        RowsAll(Doc, 'goto');
        Doc.Close();
        Observer.Finish();
    end;
}
