// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG Doc (70137), LT PnG Doc Parts (70138), LT PnG Part (70136), LT PnG Doc Close (70140), LT PnG Part Close (70139), LT PnG Head (70131), LT PnG Line (70132), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md rows 70 (Parts: order of OnInit/OnOpenPage of host and parts, a part's mode, a part whose Visible is false still runs OnInit), 71 (Parts: a part page declaring OnClosePage/OnQueryClosePage, what runs when the host closes) and 73 (Parts: Enabled() / Visible() of a part)
// Facts: the trigger log of opening and closing a document with parts, Editable() of a part in OpenEdit/OpenView, Enabled()/Visible() of plain, disabled, hidden and read-only part controls
// BC versions: 29 (27 and 28 by CI)

codeunit 70180 "LT PnG Part Triggers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT PnG Head";
        Line: Record "LT PnG Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."Code" := 'D1';
        Head.Descr := 'Doc one';
        Head.Insert();
        Head."Code" := 'D2';
        Head.Descr := 'Doc two';
        Head.Insert();
        Line."Head Code" := 'D1';
        Line."Line No." := 10000;
        Line.Descr := 'D1 line 10000';
        Line.Qty := 1;
        Line.Insert();
        Line."Line No." := 20000;
        Line.Descr := 'D1 line 20000';
        Line.Qty := 2;
        Line.Insert();
        Line."Head Code" := 'D2';
        Line."Line No." := 10000;
        Line.Descr := 'D2 line 10000';
        Line.Qty := 3;
        Line.Insert();
    end;

    [Test]
    procedure OpenOrderOfHostAndPart()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Doc: TestPage "LT PnG Doc";
    begin
        Seed();
        Log.Reset();
        Doc.OpenEdit();
        Observer.Observe('open-edit-log', Log.Dump());
        Doc.Close();
        Log.Reset();
        Doc.OpenView();
        Observer.Observe('open-view-log', Log.Dump());
        Doc.Close();
        Observer.Expect('open-edit-log', 'Doc.OnInit;Part.OnInit;Doc.OnOpenPage;Part.OnOpenPage();Doc.AGR(D1);Part.AGR(D1/10000);Part.AGR(D1/20000);Part.AGR(D1/10000)');
        Observer.Expect('open-view-log', 'Doc.OnInit;Part.OnInit;Doc.OnOpenPage;Part.OnOpenPage();Doc.AGR(D1);Part.AGR(D1/10000);Part.AGR(D1/20000);Part.AGR(D1/10000)');
        Observer.Verify();
    end;

    [Test]
    procedure OpenOrderOfHostWithSixParts()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Doc: TestPage "LT PnG Doc Parts";
    begin
        Seed();
        Log.Reset();
        Doc.OpenEdit();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('log-count', Format(Log.Count()));
        Doc.Close();
        Observer.Expect('log', 'DocParts.OnInit;Part.OnInit;Part.OnInit;Part.OnInit;Part.OnInit;Part.OnInit;Part.OnInit;DocParts.OnOpenPage;Part.OnOpenPage();Part.OnOpenPage();Part.OnOpenPage();Part.OnOpenPage();Part.OnOpenPage();Part.OnOpenPage();Part.AGR(D1/10000);Part.AGR(D1/20000);Part.AGR(D1/10000);Part.AGR(D1/10000);Part.AGR(D1/20000);Part.AGR(D1/10000);Part.AGR(D1/10000);Part.AGR(D1/20000);Part.AGR(D1/10000);Part.AGR(D1/10000);Part.AGR(D1/20000);Part.AGR(D1/10000);Part.AGR(D1/10000);Part.AGR(D1/20000);Part.AGR(D1/10000);Part.AGR(D1/20000);Part.AGR(D1/10000)');
        Observer.Expect('log-count', '31');
        Observer.Verify();
    end;

    [Test]
    procedure PartModeFollowsHost()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('edit-part-editable', Format(Doc.Lines.Editable()));
        Doc.Close();
        Doc.OpenView();
        Observer.Observe('view-part-editable', Format(Doc.Lines.Editable()));
        Doc.Close();
        Doc.OpenNew();
        Observer.Observe('new-part-editable', Format(Doc.Lines.Editable()));
        Doc.Close();
        Observer.Expect('edit-part-editable', 'Yes');
        Observer.Expect('view-part-editable', 'No');
        Observer.Expect('new-part-editable', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PartControlEnabledAndVisible()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc Parts";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('plain-enabled', Format(Doc.PlainLines.Enabled()));
        Observer.Observe('plain-visible', Format(Doc.PlainLines.Visible()));
        Observer.Observe('plain-editable', Format(Doc.PlainLines.Editable()));
        Observer.Observe('readonly-enabled', Format(Doc.ReadOnlyLines.Enabled()));
        Observer.Observe('readonly-visible', Format(Doc.ReadOnlyLines.Visible()));
        Observer.Observe('readonly-editable', Format(Doc.ReadOnlyLines.Editable()));
        Observer.Observe('disabled-visible', Format(Doc.DisabledLines.Visible()));
        Observer.Observe('disabled-editable', Format(Doc.DisabledLines.Editable()));
        Observer.Observe('viewfiltered-enabled', Format(Doc.ViewFilteredLines.Enabled()));
        Doc.Close();
        Observer.Expect('plain-enabled', 'Yes');
        Observer.Expect('plain-visible', 'Yes');
        Observer.Expect('plain-editable', 'Yes');
        Observer.Expect('readonly-enabled', 'Yes');
        Observer.Expect('readonly-visible', 'Yes');
        Observer.Expect('readonly-editable', 'Yes');
        Observer.Expect('disabled-visible', 'Yes');
        Observer.Expect('disabled-editable', 'Yes');
        Observer.Expect('viewfiltered-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure DisabledPartControlEnabled()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc Parts";
    begin
        Seed();
        Doc.OpenEdit();
        asserterror begin Observer.Observe('disabled-enabled', Format(Doc.DisabledLines.Enabled())); Error('LT-NOERROR'); end;
        Observer.ObserveError('disabled-enabled-call');
        asserterror begin Observer.Observe('disabled-first', Format(Doc.DisabledLines.First())); Error('LT-NOERROR'); end;
        Observer.ObserveError('disabled-first-call');
        Doc.Close();
        Observer.Expect('disabled-enabled', 'No');
        Observer.Expect('disabled-enabled-call|text', 'LT-NOERROR');
        Observer.Expect('disabled-enabled-call|code', 'Dialog');
        Observer.Expect('disabled-first', 'Yes');
        Observer.Expect('disabled-first-call|text', 'LT-NOERROR');
        Observer.Expect('disabled-first-call|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure HiddenPartExpression()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Doc: TestPage "LT PnG Doc Parts";
    begin
        Seed();
        Log.Reset();
        Doc.OpenEdit();
        asserterror begin Observer.Observe('hidden-visible', Format(Doc.HiddenLines.Visible())); Error('LT-NOERROR'); end;
        Observer.ObserveError('hidden-visible-call');
        asserterror begin Observer.Observe('hidden-first', Format(Doc.HiddenLines.First())); Error('LT-NOERROR'); end;
        Observer.ObserveError('hidden-first-call');
        Doc.Close();
        Observer.Expect('hidden-visible', 'No');
        Observer.Expect('hidden-visible-call|text', 'LT-NOERROR');
        Observer.Expect('hidden-visible-call|code', 'Dialog');
        Observer.Expect('hidden-first', 'Yes');
        Observer.Expect('hidden-first-call|text', 'LT-NOERROR');
        Observer.Expect('hidden-first-call|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure HostCloseRunsPartTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Doc: TestPage "LT PnG Doc Close";
    begin
        Seed();
        Log.Reset();
        Doc.OpenEdit();
        Observer.Observe('open-log', Log.Dump());
        Log.Reset();
        Doc.Close();
        Observer.Observe('close-log', Log.Dump());
        Observer.Expect('open-log', '');
        Observer.Expect('close-log', 'PartClose.OnQueryClosePage;PartClose.OnClosePage;DocClose.OnClosePage');
        Observer.Verify();
    end;

    [Test]
    procedure HostCloseAfterPartMove()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Doc: TestPage "LT PnG Doc Close";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.Lines.First();
        Doc.Lines.Next();
        Log.Reset();
        Doc.Close();
        Observer.Observe('close-log-after-part-moves', Log.Dump());
        Log.Reset();
        Doc.OpenView();
        Doc.Close();
        Observer.Observe('view-open-close-log', Log.Dump());
        Observer.Expect('close-log-after-part-moves', 'PartClose.OnQueryClosePage;PartClose.OnClosePage;DocClose.OnClosePage');
        Observer.Expect('view-open-close-log', 'PartClose.OnQueryClosePage;PartClose.OnClosePage;DocClose.OnClosePage');
        Observer.Verify();
    end;
}
