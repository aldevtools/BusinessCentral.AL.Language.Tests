// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-updatepropagation-property
// Scope: in-scope
// Fixtures used: Y88PageObjects.al of this folder (tables 94720-94721, pages 94707-94714, 94722, 94725, page extensions 94715-94719, profiles); Probe Observer (69160)
// Probe: see Y88PageObjects.al. Part edit on a host with and without a page extension, extension-added part, profile Enabled forms in All Profile.
// BC versions: 27 - 29
codeunit 94723 "LT Y88 Part Propagation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT Y88 Head";
        Line: Record "LT Y88 Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."No." := 'H1';
        Head.Total := 1;
        Head.Descr := 'orig';
        Head.Insert();
        Line."Doc No." := 'H1';
        Line."Line No." := 10000;
        Line.Qty := 1;
        Line.Insert();
    end;

    local procedure Stored(): Text
    var
        Head: Record "LT Y88 Head";
    begin
        Head.Get('H1');
        exit(Format(Head.Total));
    end;

    [Test]
    procedure Y88_Both_Base()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y88 Host Both";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('host total', TP.TotalF.Value());
        Observer.Observe('stored', Stored());
        TP.Close();
        Observer.Expect('host total', '5.00');
        Observer.Expect('stored', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_Both_Extended()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y88 Host Both X";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('host total', TP.TotalF.Value());
        Observer.Observe('host descr', TP.DescrF.Value());
        Observer.Observe('stored', Stored());
        TP.Close();
        Observer.Expect('host total', '5.00');
        Observer.Expect('host descr', 'orig');
        Observer.Expect('stored', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_SubPart_Base()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y88 Host Sub";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('host total', TP.TotalF.Value());
        Observer.Observe('stored', Stored());
        TP.Close();
        Observer.Expect('host total', '5.00');
        Observer.Expect('stored', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_SubPart_Extended()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y88 Host Sub X";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('host total', TP.TotalF.Value());
        Observer.Observe('host descr', TP.DescrF.Value());
        Observer.Observe('stored', Stored());
        TP.Close();
        Observer.Expect('host total', '5.00');
        Observer.Expect('host descr', 'orig');
        Observer.Expect('stored', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_Default_Base()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y88 Host Default";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('host total', TP.TotalF.Value());
        Observer.Observe('stored', Stored());
        TP.Close();
        Observer.Expect('host total', '5.00');
        Observer.Expect('stored', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_Default_Extended()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y88 Host Default X";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('host total', TP.TotalF.Value());
        Observer.Observe('host descr', TP.DescrF.Value());
        Observer.Observe('stored', Stored());
        TP.Close();
        Observer.Expect('host total', '5.00');
        Observer.Expect('host descr', 'orig');
        Observer.Expect('stored', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_ExtensionAddsPartWithBoth_EditBasePart()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y88 Host Ext Part";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('host total', TP.TotalF.Value());
        Observer.Observe('stored', Stored());
        TP.Close();
        Observer.Expect('host total', '5.00');
        Observer.Expect('stored', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_ExtensionAddsPartWithBoth_EditAddedPart()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y88 Host Ext Part";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.LinesBoth.QtyF.SetValue(7);
        Observer.Observe('host total', TP.TotalF.Value());
        Observer.Observe('stored', Stored());
        TP.Close();
        Observer.Expect('host total', '7.00');
        Observer.Expect('stored', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Y88_ExtensionModifiesBasePart_Both()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT Y88 Host Modify Part";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey('H1');
        TP.Lines.QtyF.SetValue(5);
        Observer.Observe('host total', TP.TotalF.Value());
        Observer.Observe('stored', Stored());
        TP.Close();
        Observer.Expect('host total', '5.00');
        Observer.Expect('stored', '5');
        Observer.Verify();
    end;
}

codeunit 94724 "LT Y88 Profile Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(Id: Text): Text
    var
        Profile: Record "All Profile";
    begin
        Profile.SetRange("Profile ID", Id);
        if not Profile.FindFirst() then
            exit('none count=' + Format(Profile.Count()));
        exit('count=' + Format(Profile.Count()) + ' enabled=' + Format(Profile.Enabled) + ' rc=' + Format(Profile."Role Center ID") + ' descr=' + Profile.Description + ' default=' + Format(Profile."Default Role Center"));
    end;

    [Test]
    procedure Y88_Profile_EnabledForms()
    var
        Observer: Codeunit "Probe Observer";
        Profile: Record "All Profile";
    begin
        Observer.Observe('profile Enabled=false', Show('LT Y88 PROF OFF'));
        Observer.Observe('profile Enabled omitted', Show('LT Y88 PROF DEFAULT'));
        Observer.Observe('profile false, extension true', Show('LT Y88 PROF BASE OFF'));
        Observer.Observe('profile true, extension caption only', Show('LT Y88 PROF BASE ON'));
        Profile.SetRange("Role Center ID", 94725);
        Observer.Observe('count by role center', Format(Profile.Count()));
        Profile.SetRange(Enabled, true);
        Observer.Observe('count enabled', Format(Profile.Count()));
        Profile.SetRange(Enabled, false);
        Observer.Observe('count disabled', Format(Profile.Count()));
        Observer.Expect('profile Enabled=false', 'count=1 enabled=No rc=94725 descr= default=No');
        Observer.Expect('profile Enabled omitted', 'count=1 enabled=Yes rc=94725 descr= default=No');
        Observer.Expect('profile false, extension true', 'count=1 enabled=Yes rc=94725 descr= default=No');
        Observer.Expect('profile true, extension caption only', 'count=1 enabled=Yes rc=94725 descr= default=No');
        Observer.Expect('count by role center', '4');
        Observer.Expect('count enabled', '3');
        Observer.Expect('count disabled', '1');
        Observer.Verify();
    end;
}
