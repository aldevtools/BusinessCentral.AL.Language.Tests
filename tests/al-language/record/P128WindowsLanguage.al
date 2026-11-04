// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73123
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the columns "Localization Exist" and "Globally Enabled" of the platform table "Windows Language" (2000000045), which the existing probes
// (record/TestWindowsLanguageTable.al, record/ProbePlatformTableAssumptions.al) leave out as installation dependent: their value for a few language ids, and
// the Find() that Microsoft's LogInManagement.LogInStart does (SetRange on both, "Language ID" := id, Find()).
// BC versions: 29 (27 and 28 by CI)

codeunit 73123 "LT P128 Win Lang"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(Id: Integer): Text
    var
        Lang: Record "Windows Language";
    begin
        if not Lang.Get(Id) then
            exit('no row');
        exit(Format(Lang."Localization Exist") + '|' + Format(Lang."Globally Enabled"));
    end;

    local procedure FindLikeLogIn(Id: Integer): Text
    var
        Lang: Record "Windows Language";
        Found: Boolean;
    begin
        Lang.SetRange("Localization Exist", true);
        Lang.SetRange("Globally Enabled", true);
        Lang."Language ID" := Id;
        Found := Lang.Find();
        exit(Format(Found) + '|' + Format(Lang."Language ID"));
    end;

    [Test]
    procedure P128_WindowsLanguage_FlagsPerRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1033', Flags(1033));
        Observer.Observe('1031', Flags(1031));
        Observer.Observe('1036', Flags(1036));
        Observer.Observe('2057', Flags(2057));
        Observer.Observe('1040', Flags(1040));
        Observer.Observe('99999', Flags(99999));
        Observer.Expect('1033', 'Yes|Yes');
        Observer.Expect('1031', 'Yes|Yes');
        Observer.Expect('1036', 'Yes|Yes');
        Observer.Expect('2057', 'Yes|Yes');
        Observer.Expect('1040', 'Yes|Yes');
        Observer.Expect('99999', 'no row');
        Observer.Verify();
    end;

    [Test]
    procedure P128_WindowsLanguage_FindLikeLogInStart()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('find 1033', FindLikeLogIn(1033));
        Observer.Observe('find 1031', FindLikeLogIn(1031));
        Observer.Observe('find 1036', FindLikeLogIn(1036));
        Observer.Observe('find 2057', FindLikeLogIn(2057));
        Observer.Observe('find 99999', FindLikeLogIn(99999));
        Observer.Observe('find 0', FindLikeLogIn(0));
        Observer.Expect('find 1033', 'Yes|1033');
        Observer.Expect('find 1031', 'Yes|1031');
        Observer.Expect('find 1036', 'Yes|1036');
        Observer.Expect('find 2057', 'Yes|2057');
        Observer.Expect('find 99999', 'No|99999');
        Observer.Expect('find 0', 'No|0');
        Observer.Verify();
    end;

    [Test]
    procedure P128_WindowsLanguage_FilterRelations()
    var
        Observer: Codeunit "Probe Observer";
        Lang: Record "Windows Language";
        All: Integer;
        Exist: Integer;
        Enabled: Integer;
        Both: Integer;
    begin
        All := Lang.Count();
        Lang.SetRange("Localization Exist", true);
        Exist := Lang.Count();
        Lang.SetRange("Globally Enabled", true);
        Both := Lang.Count();
        Lang.SetRange("Localization Exist");
        Enabled := Lang.Count();
        Observer.Observe('exist at most all', Format(Exist <= All));
        Observer.Observe('exist at least one', Format(Exist > 0));
        Observer.Observe('enabled at most all', Format(Enabled <= All));
        Observer.Observe('both at most exist', Format(Both <= Exist));
        Observer.Observe('both at most enabled', Format(Both <= Enabled));
        Observer.Observe('both at least one', Format(Both > 0));
        Lang.Reset();
        Lang.SetRange("Localization Exist", false);
        Observer.Observe('not exist plus exist is all', Format(Lang.Count() + Exist = All));
        Observer.Expect('exist at most all', 'Yes');
        Observer.Expect('exist at least one', 'Yes');
        Observer.Expect('enabled at most all', 'Yes');
        Observer.Expect('both at most exist', 'Yes');
        Observer.Expect('both at most enabled', 'Yes');
        Observer.Expect('both at least one', 'Yes');
        Observer.Expect('not exist plus exist is all', 'Yes');
        Observer.Verify();
    end;
}
