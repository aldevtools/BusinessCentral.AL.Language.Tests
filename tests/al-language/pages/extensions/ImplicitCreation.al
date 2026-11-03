// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own pages 81880-81886, page extensions 81881-81887, codeunit 81890 (ImplicitCreationObjects.al)
// Probe: corpus issue 673 item 6 (al-runtime-rs #297). Every literal asserted below is what BC 27.5, 28.5 and 29.0 produced in the corpus CI.
// Facts: a page extension adds actions to the implicit Creation area (and Processing, Navigation, Reporting) of pages that declare no actions or only area(Processing): List with a temporary Integer source and Worksheet (a ListPart has no implicit Creation area: must-not-compile case 1360); does a TestPage open with OpenView, OpenEdit and OpenNew, and do the added actions run with Invoke (Visible, Enabled, the OnAction log).
// BC versions: 27+

codeunit 81891 "LT BL Implicit Creation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The al-runtime-rs #297 repro.
    [Test]
    procedure Repro_OpenView_Close()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT BL Creation List";
    begin
        List.OpenView();
        List.Close();
        Observer.Observe('opened and closed', 'yes');
        Observer.Expect('opened and closed', 'yes');
        Observer.Verify();
    end;

    [Test]
    procedure List_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation List";
    begin
        Log.Take();
        Pg.OpenView();
        Observer.Observe('OpenView ProbeAction visible', Format(Pg.ProbeAction.Visible()));
        Observer.Observe('OpenView ProbeAction enabled', Format(Pg.ProbeAction.Enabled()));
        Pg.ProbeAction.Invoke();
        Observer.Observe('OpenView log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenView ProbeAction visible', 'Yes');
        Observer.Expect('OpenView ProbeAction enabled', 'Yes');
        Observer.Expect('OpenView log', 'ProbeAction;');
        Observer.Verify();
    end;

    [Test]
    procedure List_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation List";
    begin
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('OpenEdit ProbeAction visible', Format(Pg.ProbeAction.Visible()));
        Observer.Observe('OpenEdit ProbeAction enabled', Format(Pg.ProbeAction.Enabled()));
        Pg.ProbeAction.Invoke();
        Observer.Observe('OpenEdit log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenEdit ProbeAction visible', 'Yes');
        Observer.Expect('OpenEdit ProbeAction enabled', 'Yes');
        Observer.Expect('OpenEdit log', 'ProbeAction;');
        Observer.Verify();
    end;

    [Test]
    procedure List_OpenNew()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation List";
    begin
        Log.Take();
        Pg.OpenNew();
        Observer.Observe('OpenNew ProbeAction visible', Format(Pg.ProbeAction.Visible()));
        Observer.Observe('OpenNew ProbeAction enabled', Format(Pg.ProbeAction.Enabled()));
        Pg.ProbeAction.Invoke();
        Observer.Observe('OpenNew log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenNew ProbeAction visible', 'Yes');
        Observer.Expect('OpenNew ProbeAction enabled', 'Yes');
        Observer.Expect('OpenNew log', 'ProbeAction;');
        Observer.Verify();
    end;

    [Test]
    procedure Areas_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation Areas";
    begin
        Log.Take();
        Pg.OpenView();
        Observer.Observe('OpenView CreFirst visible', Format(Pg.CreFirst.Visible()));
        Observer.Observe('OpenView CreFirst enabled', Format(Pg.CreFirst.Enabled()));
        Pg.CreFirst.Invoke();
        Observer.Observe('OpenView ProcLast visible', Format(Pg.ProcLast.Visible()));
        Observer.Observe('OpenView ProcLast enabled', Format(Pg.ProcLast.Enabled()));
        Pg.ProcLast.Invoke();
        Observer.Observe('OpenView NavFirst visible', Format(Pg.NavFirst.Visible()));
        Observer.Observe('OpenView NavFirst enabled', Format(Pg.NavFirst.Enabled()));
        Pg.NavFirst.Invoke();
        Observer.Observe('OpenView RepLast visible', Format(Pg.RepLast.Visible()));
        Observer.Observe('OpenView RepLast enabled', Format(Pg.RepLast.Enabled()));
        Pg.RepLast.Invoke();
        Observer.Observe('OpenView log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenView CreFirst visible', 'Yes');
        Observer.Expect('OpenView CreFirst enabled', 'Yes');
        Observer.Expect('OpenView ProcLast visible', 'Yes');
        Observer.Expect('OpenView ProcLast enabled', 'Yes');
        Observer.Expect('OpenView NavFirst visible', 'Yes');
        Observer.Expect('OpenView NavFirst enabled', 'Yes');
        Observer.Expect('OpenView RepLast visible', 'Yes');
        Observer.Expect('OpenView RepLast enabled', 'Yes');
        Observer.Expect('OpenView log', 'CreFirst;ProcLast;NavFirst;RepLast;');
        Observer.Verify();
    end;

    [Test]
    procedure Areas_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation Areas";
    begin
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('OpenEdit CreFirst visible', Format(Pg.CreFirst.Visible()));
        Observer.Observe('OpenEdit CreFirst enabled', Format(Pg.CreFirst.Enabled()));
        Pg.CreFirst.Invoke();
        Observer.Observe('OpenEdit ProcLast visible', Format(Pg.ProcLast.Visible()));
        Observer.Observe('OpenEdit ProcLast enabled', Format(Pg.ProcLast.Enabled()));
        Pg.ProcLast.Invoke();
        Observer.Observe('OpenEdit NavFirst visible', Format(Pg.NavFirst.Visible()));
        Observer.Observe('OpenEdit NavFirst enabled', Format(Pg.NavFirst.Enabled()));
        Pg.NavFirst.Invoke();
        Observer.Observe('OpenEdit RepLast visible', Format(Pg.RepLast.Visible()));
        Observer.Observe('OpenEdit RepLast enabled', Format(Pg.RepLast.Enabled()));
        Pg.RepLast.Invoke();
        Observer.Observe('OpenEdit log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenEdit CreFirst visible', 'Yes');
        Observer.Expect('OpenEdit CreFirst enabled', 'Yes');
        Observer.Expect('OpenEdit ProcLast visible', 'Yes');
        Observer.Expect('OpenEdit ProcLast enabled', 'Yes');
        Observer.Expect('OpenEdit NavFirst visible', 'Yes');
        Observer.Expect('OpenEdit NavFirst enabled', 'Yes');
        Observer.Expect('OpenEdit RepLast visible', 'Yes');
        Observer.Expect('OpenEdit RepLast enabled', 'Yes');
        Observer.Expect('OpenEdit log', 'CreFirst;ProcLast;NavFirst;RepLast;');
        Observer.Verify();
    end;

    [Test]
    procedure Areas_OpenNew()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation Areas";
    begin
        Log.Take();
        Pg.OpenNew();
        Observer.Observe('OpenNew CreFirst visible', Format(Pg.CreFirst.Visible()));
        Observer.Observe('OpenNew CreFirst enabled', Format(Pg.CreFirst.Enabled()));
        Pg.CreFirst.Invoke();
        Observer.Observe('OpenNew ProcLast visible', Format(Pg.ProcLast.Visible()));
        Observer.Observe('OpenNew ProcLast enabled', Format(Pg.ProcLast.Enabled()));
        Pg.ProcLast.Invoke();
        Observer.Observe('OpenNew NavFirst visible', Format(Pg.NavFirst.Visible()));
        Observer.Observe('OpenNew NavFirst enabled', Format(Pg.NavFirst.Enabled()));
        Pg.NavFirst.Invoke();
        Observer.Observe('OpenNew RepLast visible', Format(Pg.RepLast.Visible()));
        Observer.Observe('OpenNew RepLast enabled', Format(Pg.RepLast.Enabled()));
        Pg.RepLast.Invoke();
        Observer.Observe('OpenNew log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenNew CreFirst visible', 'Yes');
        Observer.Expect('OpenNew CreFirst enabled', 'Yes');
        Observer.Expect('OpenNew ProcLast visible', 'Yes');
        Observer.Expect('OpenNew ProcLast enabled', 'Yes');
        Observer.Expect('OpenNew NavFirst visible', 'Yes');
        Observer.Expect('OpenNew NavFirst enabled', 'Yes');
        Observer.Expect('OpenNew RepLast visible', 'Yes');
        Observer.Expect('OpenNew RepLast enabled', 'Yes');
        Observer.Expect('OpenNew log', 'CreFirst;ProcLast;NavFirst;RepLast;');
        Observer.Verify();
    end;

    [Test]
    procedure ProcOnly_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation Proc Only";
    begin
        Log.Take();
        Pg.OpenView();
        Observer.Observe('OpenView BaseProc visible', Format(Pg.BaseProc.Visible()));
        Observer.Observe('OpenView BaseProc enabled', Format(Pg.BaseProc.Enabled()));
        Pg.BaseProc.Invoke();
        Observer.Observe('OpenView CreLast visible', Format(Pg.CreLast.Visible()));
        Observer.Observe('OpenView CreLast enabled', Format(Pg.CreLast.Enabled()));
        Pg.CreLast.Invoke();
        Observer.Observe('OpenView log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenView BaseProc visible', 'Yes');
        Observer.Expect('OpenView BaseProc enabled', 'Yes');
        Observer.Expect('OpenView CreLast visible', 'Yes');
        Observer.Expect('OpenView CreLast enabled', 'Yes');
        Observer.Expect('OpenView log', 'BaseProc;CreLast;');
        Observer.Verify();
    end;

    [Test]
    procedure ProcOnly_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation Proc Only";
    begin
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('OpenEdit BaseProc visible', Format(Pg.BaseProc.Visible()));
        Observer.Observe('OpenEdit BaseProc enabled', Format(Pg.BaseProc.Enabled()));
        Pg.BaseProc.Invoke();
        Observer.Observe('OpenEdit CreLast visible', Format(Pg.CreLast.Visible()));
        Observer.Observe('OpenEdit CreLast enabled', Format(Pg.CreLast.Enabled()));
        Pg.CreLast.Invoke();
        Observer.Observe('OpenEdit log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenEdit BaseProc visible', 'Yes');
        Observer.Expect('OpenEdit BaseProc enabled', 'Yes');
        Observer.Expect('OpenEdit CreLast visible', 'Yes');
        Observer.Expect('OpenEdit CreLast enabled', 'Yes');
        Observer.Expect('OpenEdit log', 'BaseProc;CreLast;');
        Observer.Verify();
    end;

    [Test]
    procedure ProcOnly_OpenNew()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation Proc Only";
    begin
        Log.Take();
        Pg.OpenNew();
        Observer.Observe('OpenNew BaseProc visible', Format(Pg.BaseProc.Visible()));
        Observer.Observe('OpenNew BaseProc enabled', Format(Pg.BaseProc.Enabled()));
        Pg.BaseProc.Invoke();
        Observer.Observe('OpenNew CreLast visible', Format(Pg.CreLast.Visible()));
        Observer.Observe('OpenNew CreLast enabled', Format(Pg.CreLast.Enabled()));
        Pg.CreLast.Invoke();
        Observer.Observe('OpenNew log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenNew BaseProc visible', 'Yes');
        Observer.Expect('OpenNew BaseProc enabled', 'Yes');
        Observer.Expect('OpenNew CreLast visible', 'Yes');
        Observer.Expect('OpenNew CreLast enabled', 'Yes');
        Observer.Expect('OpenNew log', 'BaseProc;CreLast;');
        Observer.Verify();
    end;

    [Test]
    procedure Worksheet_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation Worksheet";
    begin
        Log.Take();
        Pg.OpenView();
        Observer.Observe('OpenView WsCreLast visible', Format(Pg.WsCreLast.Visible()));
        Observer.Observe('OpenView WsCreLast enabled', Format(Pg.WsCreLast.Enabled()));
        Pg.WsCreLast.Invoke();
        Observer.Observe('OpenView log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenView WsCreLast visible', 'Yes');
        Observer.Expect('OpenView WsCreLast enabled', 'Yes');
        Observer.Expect('OpenView log', 'WsCreLast;');
        Observer.Verify();
    end;

    [Test]
    procedure Worksheet_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT BL Creation Log";
        Pg: TestPage "LT BL Creation Worksheet";
    begin
        Log.Take();
        Pg.OpenEdit();
        Observer.Observe('OpenEdit WsCreLast visible', Format(Pg.WsCreLast.Visible()));
        Observer.Observe('OpenEdit WsCreLast enabled', Format(Pg.WsCreLast.Enabled()));
        Pg.WsCreLast.Invoke();
        Observer.Observe('OpenEdit log', Log.Take());
        Pg.Close();
        Observer.Expect('OpenEdit WsCreLast visible', 'Yes');
        Observer.Expect('OpenEdit WsCreLast enabled', 'Yes');
        Observer.Expect('OpenEdit log', 'WsCreLast;');
        Observer.Verify();
    end;

    [Test]
    procedure Worksheet_OpenNew()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT BL Creation Worksheet";
    begin
        asserterror Pg.OpenNew();
        Observer.ObserveError('OpenNew');
        Observer.Expect('OpenNew|text', 'The view mode ''Create'' is not supported by the page ID ''81886''.');
        Observer.Expect('OpenNew|code', 'NotSupportedPageViewMode');
        Observer.Verify();
    end;
}
