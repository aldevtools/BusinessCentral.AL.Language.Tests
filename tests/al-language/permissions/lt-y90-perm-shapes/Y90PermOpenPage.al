// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y90PermObjects.al (94780-94829); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probe P22 (Y84 pinned: under an exact set a page trigger that calls a codeunit ends the page open with 'Page <name> has to close.',
//   FormAbort:Permission, even when the page and the codeunit are granted by name). What else changes that: Execute on all codeunits (codeunit * = X), on all
//   pages (page * = X), both, only on all codeunits without the page; a set assigned with Set (not exact); the call in OnInit, OnAfterGetRecord, through
//   Codeunit.Run; and whether the abort text shows the page name or the Caption property (page 94783 has Caption = 'LT Y90 Shown Caption'). Every case
//   uses its own page and codeunit, because Execute is checked the first time a session loads an object.
// BC versions: 27, 28, 29

codeunit 94808 "LT Y90 Perm OpenPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

#if BC28PLUS
    [Test]
    procedure Y90_Open_CaptionAndGrants()
#else
    // Linux suspect on BC 27: Windows 27.5 gives the asserted value, the Linux 27.5 container does not (hand-off, Fix round 27.5). Not a test on 27.
    procedure Suspect_Open_CaptionAndGrants()
#endif
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('caption', 'LT Y90 P Pages', 1, true);
        Run('pages_cu_star', 'LT Y90 P PagesCuStar', 2, true);
        Run('pages_star', 'LT Y90 P PagesStar', 3, true);
        Run('star_star', 'LT Y90 P StarStar', 4, true);
        RestoreMock(WasStarted);
        Observer.Expect('caption',
            'Page LT Y90 Shown Caption has to close. | FormAbort:Permission');
        Observer.Expect('pages_cu_star',
            'LT Y90 ok opened | Dialog');
        Observer.Expect('pages_star',
            'Page LT Y90 Open 3 has to close. | FormAbort:Permission');
        Observer.Expect('star_star',
            'LT Y90 ok opened | Dialog');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure Y90_Open_CodeunitStarSystemStarSet()
#else
    // Linux suspect on BC 27: Windows 27.5 gives the asserted value, the Linux 27.5 container does not (hand-off, Fix round 27.5). Not a test on 27.
    procedure Suspect_Open_CodeunitStarSystemStarSet()
#endif
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('cu_star_only', 'LT Y90 P CuStar', 5, true);
        Run('exact_sys_star', 'LT Y90 P PagesSys', 6, true);
        Run('set_not_exact', 'LT Y90 P Pages', 6, false);
        RestoreMock(WasStarted);
        Observer.Expect('cu_star_only',
            'Page LT Y90 Open 5 has to close. | FormAbort:Permission');
        Observer.Expect('exact_sys_star',
            'LT Y90 ok opened | Dialog');
        Observer.Expect('set_not_exact',
            'LT Y90 ok opened | Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_Open_TriggerKinds()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('on_init', 'LT Y90 P Pages', 7, true);
        Run('after_get_record', 'LT Y90 P Pages', 8, true);
        Run('codeunit_run', 'LT Y90 P Pages', 9, true);
        RestoreMock(WasStarted);
        Observer.Expect('on_init',
            'Page LT Y90 Open 7 has to close. | FormAbort:Permission');
        Observer.Expect('after_get_record',
            'Page LT Y90 Open 8 has to close. | FormAbort:Permission');
        Observer.Expect('codeunit_run',
            'Page LT Y90 Open 9 has to close. | FormAbort:Permission');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_Open_D365BasicPlusAppSet()
    var
        WasStarted: Boolean;
        PageA: TestPage "LT Y90 D365 Page A";
        Trig: Record "LT Y90 Row";
    begin
        // Shape of runner issue 6867: Set('D365 BASIC') (wildcard Execute) + Assign(a set that grants the callee codeunit X by name), page trigger calls
        // the codeunit.
        WasStarted := StartMock();
        Mock.ClearAssignments();
        Trig.DeleteAll();
        Trig.Id := 1;
        Trig.Insert();
        Mock.Set('D365 BASIC');
        Mock.Assign('LT Y90 D365 Set A');
        asserterror begin
            PageA.OpenEdit();
            PageA.Close();
            Error('LT Y90 ok opened');
        end;
        Observer.Observe('basic_plus_app', GetLastErrorText() + ' | ' + GetLastErrorCode());
        Mock.ClearAssignments();
        ClearLastError();
        RestoreMock(WasStarted);
        Observer.Expect('basic_plus_app',
            'LT Y90 ok opened | Dialog');
        Observer.Verify();
    end;

    local procedure Run(Tag: Text; SetName: Code[20]; Which: Integer; Exact: Boolean)
    var
        Trig: Record "LT Y90 Row";
        ErrorText: Text;
        ErrorCode: Text;
    begin
        Mock.ClearAssignments();
        Trig.DeleteAll();
        Trig.Id := 1;
        Trig.Insert();
        if Exact then
            Mock.SetExactPermissionSet(SetName)
        else
            Mock.Set(SetName);
        asserterror Op(Which);
        ErrorText := GetLastErrorText();
        ErrorCode := GetLastErrorCode();
        Mock.ClearAssignments();
        ClearLastError();
        Observer.Observe(Tag, ErrorText + ' | ' + ErrorCode);
    end;

    local procedure Op(Which: Integer)
    var
        P1: TestPage "LT Y90 Open 1";
        P2: TestPage "LT Y90 Open 2";
        P3: TestPage "LT Y90 Open 3";
        P4: TestPage "LT Y90 Open 4";
        P5: TestPage "LT Y90 Open 5";
        P6: TestPage "LT Y90 Open 6";
        P7: TestPage "LT Y90 Open 7";
        P8: TestPage "LT Y90 Open 8";
        P9: TestPage "LT Y90 Open 9";
    begin
        case Which of
            1:
                begin
                    P1.OpenView();
                    P1.Close();
                end;
            2:
                begin
                    P2.OpenView();
                    P2.Close();
                end;
            3:
                begin
                    P3.OpenView();
                    P3.Close();
                end;
            4:
                begin
                    P4.OpenView();
                    P4.Close();
                end;
            5:
                begin
                    P5.OpenView();
                    P5.Close();
                end;
            6:
                begin
                    P6.OpenView();
                    P6.Close();
                end;
            7:
                begin
                    P7.OpenView();
                    P7.Close();
                end;
            8:
                begin
                    P8.OpenView();
                    P8.Close();
                end;
            9:
                begin
                    P9.OpenView();
                    P9.Close();
                end;
        end;
        Error('LT Y90 ok opened');
    end;

    local procedure StartMock() WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    local procedure RestoreMock(WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;
}
