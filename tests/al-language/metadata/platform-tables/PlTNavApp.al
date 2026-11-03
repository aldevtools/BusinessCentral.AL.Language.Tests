// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunits 74206 (tests) and 74207 (helper in the same app, used to observe the caller)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Members: NavApp.GetCurrentModuleInfo, GetModuleInfo, GetCallerModuleInfo; ModuleInfo.Id/Name/Publisher/AppVersion/DataVersion/PackageId/Dependencies;
// ModuleDependencyInfo.Id/Name/Publisher; Version.Major/Minor/Build/Revision.
// BC versions: 29 (27 and 28 by CI)

codeunit 74207 "LT PlT NavApp Helper"
{
    procedure CallerOk(var Info: ModuleInfo): Boolean
    begin
        exit(NavApp.GetCallerModuleInfo(Info));
    end;
}

codeunit 74206 "LT PlT NavApp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Same(A: ModuleInfo; B: ModuleInfo): Text
    begin
        exit(Format(A.Id() = B.Id()) + '|' + Format(A.Name() = B.Name()) + '|' + Format(A.Publisher() = B.Publisher()) + '|' + Format(Format(A.AppVersion()) = Format(B.AppVersion())) + '|' +
             Format(Format(A.DataVersion()) = Format(B.DataVersion())) + '|' + Format(A.PackageId() = B.PackageId()) + '|' + Format(A.Dependencies().Count() = B.Dependencies().Count()));
    end;

    [Test]
    procedure CurrentModuleInfo_Basics()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('ok', Format(NavApp.GetCurrentModuleInfo(Info)));
        Observer.Observe('id_null', Format(IsNullGuid(Info.Id())));
        Observer.Observe('id_len', Format(StrLen(Format(Info.Id()))));
        Observer.Observe('name_empty', Format(Info.Name() = ''));
        Observer.Observe('publisher_empty', Format(Info.Publisher() = ''));
        Observer.Observe('packageid_null', Format(IsNullGuid(Info.PackageId())));
        Observer.Observe('packageid_equals_id', Format(Info.PackageId() = Info.Id()));
        Observer.Observe('appversion_empty', Format(Format(Info.AppVersion()) = ''));
        Observer.Observe('dataversion_empty', Format(Format(Info.DataVersion()) = ''));
        Observer.Observe('appversion_is_dataversion', Format(Format(Info.AppVersion()) = Format(Info.DataVersion())));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('id_null', 'No');
        Observer.Expect('id_len', '38');
        Observer.Expect('name_empty', 'No');
        Observer.Expect('publisher_empty', 'No');
        Observer.Expect('packageid_null', 'No');
        Observer.Expect('packageid_equals_id', 'No');
        Observer.Expect('appversion_empty', 'No');
        Observer.Expect('dataversion_empty', 'No');
        Observer.Expect('appversion_is_dataversion', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CurrentModuleInfo_RepeatableAndIndependent()
    var
        Observer: Codeunit "Probe Observer";
        A: ModuleInfo;
        B: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(A);
        NavApp.GetCurrentModuleInfo(B);
        Observer.Observe('same_two_calls', Same(A, B));
        NavApp.GetCurrentModuleInfo(A);
        Observer.Observe('same_reuse_var', Same(A, B));
        Clear(A);
        Observer.Observe('cleared_id_null', Format(IsNullGuid(A.Id())));
        Observer.Observe('cleared_name', A.Name());
        Observer.Observe('cleared_publisher', A.Publisher());
        Observer.Observe('cleared_deps', Format(A.Dependencies().Count()));
        Observer.Observe('cleared_differs', Same(A, B));
        Observer.Expect('same_two_calls', 'Yes|Yes|Yes|Yes|Yes|Yes|Yes');
        Observer.Expect('same_reuse_var', 'Yes|Yes|Yes|Yes|Yes|Yes|Yes');
        Observer.Expect('cleared_id_null', 'Yes');
        Observer.Expect('cleared_name', '');
        Observer.Expect('cleared_publisher', '');
        Observer.Expect('cleared_deps', '0');
        Observer.Expect('cleared_differs', 'No|No|No|No|No|No|No');
        Observer.Verify();
    end;

    [Test]
    procedure ModuleInfo_Uninitialized()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('id', Format(Info.Id()));
        Observer.Observe('name', Info.Name());
        Observer.Observe('publisher', Info.Publisher());
        Observer.Observe('appversion', Format(Info.AppVersion()));
        Observer.Observe('dataversion', Format(Info.DataVersion()));
        Observer.Observe('packageid', Format(Info.PackageId()));
        Observer.Observe('deps', Format(Info.Dependencies().Count()));
        Observer.Observe('major', Format(Info.AppVersion().Major()));
        Observer.Observe('minor', Format(Info.AppVersion().Minor()));
        Observer.Observe('build', Format(Info.AppVersion().Build()));
        Observer.Observe('revision', Format(Info.AppVersion().Revision()));
        Observer.Expect('id', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('name', '');
        Observer.Expect('publisher', '');
        Observer.Expect('appversion', '0.0.0.0');
        Observer.Expect('dataversion', '0.0.0.0');
        Observer.Expect('packageid', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('deps', '0');
        Observer.Expect('major', '0');
        Observer.Expect('minor', '0');
        Observer.Expect('build', '0');
        Observer.Expect('revision', '0');
        Observer.Verify();
    end;

    [Test]
    procedure GetModuleInfo_OwnId()
    var
        Observer: Codeunit "Probe Observer";
        Current: ModuleInfo;
        ById: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Current);
        Observer.Observe('ok', Format(NavApp.GetModuleInfo(Current.Id(), ById)));
        Observer.Observe('same', Same(Current, ById));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('same', 'Yes|Yes|Yes|Yes|Yes|Yes|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CallerModuleInfo_ViaHelperInSameApp()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT PlT NavApp Helper";
        Caller: ModuleInfo;
        Current: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Current);
        Observer.Observe('ok', Format(Helper.CallerOk(Caller)));
        Observer.Observe('same_as_current', Same(Caller, Current));
        Observer.Observe('id_null', Format(IsNullGuid(Caller.Id())));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('same_as_current', 'Yes|Yes|Yes|Yes|Yes|Yes|Yes');
        Observer.Expect('id_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CallerModuleInfo_Direct()
    var
        Observer: Codeunit "Probe Observer";
        Caller: ModuleInfo;
    begin
        // From a test procedure the caller is the platform; only whether the call works and that a second call agrees are observed.
        Observer.Observe('ok', Format(NavApp.GetCallerModuleInfo(Caller)));
        Observer.Observe('twice_equal', Format(NavApp.GetCallerModuleInfo(Caller)));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('twice_equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Dependencies_Relations()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
        Dep: ModuleDependencyInfo;
        Info2: ModuleInfo;
        Deps: List of [ModuleDependencyInfo];
        AllIdsSet: Boolean;
        AllNamesSet: Boolean;
        AllPublishersSet: Boolean;
        AllResolve: Boolean;
        ResolvedSame: Boolean;
        Count: Integer;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Deps := Info.Dependencies();
        AllIdsSet := true;
        AllNamesSet := true;
        AllPublishersSet := true;
        AllResolve := true;
        ResolvedSame := true;
        foreach Dep in Deps do begin
            Count += 1;
            if IsNullGuid(Dep.Id()) then
                AllIdsSet := false;
            if Dep.Name() = '' then
                AllNamesSet := false;
            if Dep.Publisher() = '' then
                AllPublishersSet := false;
            if not NavApp.GetModuleInfo(Dep.Id(), Info2) then
                AllResolve := false
            else
                if Info2.Name() <> Dep.Name() then
                    ResolvedSame := false;
        end;
        Observer.Observe('count_matches_list', Format(Count = Deps.Count()));
        Observer.Observe('count_matches_second_call', Format(Count = Info.Dependencies().Count()));
        Observer.Observe('has_dependencies', Format(Count > 0));
        Observer.Observe('all_ids_set', Format(AllIdsSet));
        Observer.Observe('all_names_set', Format(AllNamesSet));
        Observer.Observe('all_publishers_set', Format(AllPublishersSet));
        Observer.Observe('all_resolve', Format(AllResolve));
        Observer.Observe('resolved_names_equal', Format(ResolvedSame));
        Observer.Expect('count_matches_list', 'Yes');
        Observer.Expect('count_matches_second_call', 'Yes');
        Observer.Expect('has_dependencies', 'Yes');
        Observer.Expect('all_ids_set', 'Yes');
        Observer.Expect('all_names_set', 'Yes');
        Observer.Expect('all_publishers_set', 'Yes');
        Observer.Expect('all_resolve', 'Yes');
        Observer.Expect('resolved_names_equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure DependencyInfo_Uninitialized()
    var
        Observer: Codeunit "Probe Observer";
        Dep: ModuleDependencyInfo;
    begin
        Observer.Observe('id', Format(Dep.Id()));
        Observer.Observe('name', Dep.Name());
        Observer.Observe('publisher', Dep.Publisher());
        Observer.Expect('id', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('name', '');
        Observer.Expect('publisher', '');
        Observer.Verify();
    end;

    [Test]
    procedure AppVersion_Parts()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
        V: Version;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        V := Info.AppVersion();
        Observer.Observe('major_nonneg', Format(V.Major() >= 0));
        Observer.Observe('minor_nonneg', Format(V.Minor() >= 0));
        Observer.Observe('build_nonneg', Format(V.Build() >= 0));
        Observer.Observe('revision_nonneg', Format(V.Revision() >= 0));
        Observer.Observe('format_is_parts', Format(Format(V) = StrSubstNo('%1.%2.%3.%4', V.Major(), V.Minor(), V.Build(), V.Revision())));
        Observer.Observe('data_version_parts', Format(Format(Info.DataVersion()) = StrSubstNo('%1.%2.%3.%4', Info.DataVersion().Major(), Info.DataVersion().Minor(), Info.DataVersion().Build(), Info.DataVersion().Revision())));
        Observer.Observe('equal_to_self', Format(V = Info.AppVersion()));
        Observer.Observe('not_less_than_self', Format(V < Info.AppVersion()));
        Observer.Expect('major_nonneg', 'Yes');
        Observer.Expect('minor_nonneg', 'Yes');
        Observer.Expect('build_nonneg', 'Yes');
        Observer.Expect('revision_nonneg', 'Yes');
        Observer.Expect('format_is_parts', 'Yes');
        Observer.Expect('data_version_parts', 'Yes');
        Observer.Expect('equal_to_self', 'Yes');
        Observer.Expect('not_less_than_self', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Version_CreateAndCompare()
    var
        V: Version;
        Observer: Codeunit "Probe Observer";
        A: Version;
        B: Version;
    begin
        A := Version.Create(1, 2, 3, 4);
        B := Version.Create('1.2.3.5');
        Observer.Observe('a', Format(A));
        Observer.Observe('b', Format(B));
        Observer.Observe('a_lt_b', Format(A < B));
        Observer.Observe('a_eq_b', Format(A = B));
        Observer.Observe('a_ne_b', Format(A <> B));
        Observer.Observe('a_ge_b', Format(A >= B));
        Observer.Observe('parts', StrSubstNo('%1.%2.%3.%4', A.Major(), A.Minor(), A.Build(), A.Revision()));
        Observer.Observe('two_part', Format(Version.Create('3.4')));
        Observer.Observe('three_part', Format(Version.Create('3.4.5')));
        Observer.Observe('major_numeric_order', Format(Version.Create('10.0.0.0') > Version.Create('9.0.0.0')));
        asserterror Observer.Observe('v', Format(Version.Create('x.y')));
        Observer.ObserveError('bad_text');
        asserterror Observer.Observe('v', Format(Version.Create('1')));
        Observer.ObserveError('one_part');
        asserterror Observer.Observe('v', Format(Version.Create('1.2.3.4.5')));
        Observer.ObserveError('five_parts');
        Observer.Observe('v', Format(Version.Create(-1, 0, 0, 0)));
        Observer.Observe('negative', 'no error');
        Observer.Expect('a', '1.2.3.4');
        Observer.Expect('b', '1.2.3.5');
        Observer.Expect('a_lt_b', 'Yes');
        Observer.Expect('a_eq_b', 'No');
        Observer.Expect('a_ne_b', 'Yes');
        Observer.Expect('a_ge_b', 'No');
        Observer.Expect('parts', '1.2.3.4');
        Observer.Expect('two_part', '3.4.0.0');
        Observer.Expect('three_part', '3.4.5.0');
        Observer.Expect('major_numeric_order', 'Yes');
        Observer.Expect('bad_text|text', 'Could not parse string ''x.y'' into a version.');
        Observer.Expect('bad_text|code', 'Argument');
        Observer.Expect('one_part|text', 'Could not parse string ''1'' into a version.');
        Observer.Expect('one_part|code', 'Argument');
        Observer.Expect('five_parts|text', 'Could not parse string ''1.2.3.4.5'' into a version.');
        Observer.Expect('five_parts|code', 'Argument');
        Observer.Expect('v', '0.0.0.0');
        Observer.Expect('negative', 'no error');
        Observer.Verify();
    end;

    // Writer SN (2026-10-25, runtime hand-off refuse-platform "Version.Create(-1,0,0,0) formats 0.0.0.0; Major() etc. of it not pinned"):
    [Test]
    procedure Version_NegativeParts()
    var
        Observer: Codeunit "Probe Observer";
        V: Version;
    begin
        V := Version.Create(-1, 0, 0, 0);
        Observer.Observe('neg_major_format', Format(V));
        Observer.Observe('neg_major_parts', StrSubstNo('%1|%2|%3|%4', V.Major(), V.Minor(), V.Build(), V.Revision()));
        Observer.Observe('neg_major_eq_zero', Format(V = Version.Create(0, 0, 0, 0)));
        Observer.Observe('neg_major_lt_zero', Format(V < Version.Create(0, 0, 0, 0)));
        V := Version.Create(1, 2, -1, -1);
        Observer.Observe('neg_build_format', Format(V));
        Observer.Observe('neg_build_parts', StrSubstNo('%1|%2|%3|%4', V.Major(), V.Minor(), V.Build(), V.Revision()));
        V := Version.Create(1, 2, 3, -1);
        Observer.Observe('neg_rev_format', Format(V));
        Observer.Observe('neg_rev_parts', StrSubstNo('%1|%2|%3|%4', V.Major(), V.Minor(), V.Build(), V.Revision()));
        Observer.Observe('neg_rev_eq_three_part', Format(V = Version.Create('1.2.3')));
        V := Version.Create(-5, -6, 3, 4);
        Observer.Observe('neg_two_format', Format(V));
        Observer.Observe('neg_two_parts', StrSubstNo('%1|%2|%3|%4', V.Major(), V.Minor(), V.Build(), V.Revision()));
        Observer.Expect('neg_major_format', '0.0.0.0');
        Observer.Expect('neg_major_parts', '0|0|0|0');
        Observer.Expect('neg_major_eq_zero', 'Yes');
        Observer.Expect('neg_major_lt_zero', 'No');
        Observer.Expect('neg_build_format', '1.2.0.0');
        Observer.Expect('neg_build_parts', '1|2|0|0');
        Observer.Expect('neg_rev_format', '1.2.3.0');
        Observer.Expect('neg_rev_parts', '1|2|3|0');
        Observer.Expect('neg_rev_eq_three_part', 'Yes');
        Observer.Expect('neg_two_format', '0.0.3.4');
        Observer.Expect('neg_two_parts', '0|0|3|4');
        Observer.Verify();
    end;
}
