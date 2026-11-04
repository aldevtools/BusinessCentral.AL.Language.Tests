// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-inherentpermissions-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus issue 629 items 4 and 10: the run-time effect of the InherentPermissions attribute on a procedure and of the
// RequiredPermissions attribute on an external business event. A test codeunit with TestPermissions = Restrictive runs with
// the permission set 'D365 Full Access' when Tests-TestLibraries is installed (BiTpRestr.al), which does not grant table
// 81562 of this app; so a plain insert into it is refused, and each procedure below shows what its attribute changes.
// Every test declares [HandlerFunctions] so the CI runner routes the codeunit to Microsoft's test runner (BiTpHelper.al).
// Facts (27.5, 28.5, 29.0 identical): inherent 'I' lets the insert pass, also when the insert is in a callee of the procedure
// that has the attribute; inherent 'R' does not; scope Permissions and Both grant, Entitlements alone does not;
// ReadPermission/WritePermission inside the procedure report the inherent permissions. RequiredPermissions has no run-time
// effect on raising the event: the raise succeeds without the named permission and the code after it runs.
// Probe: observed values; every literal asserted below is what the BC tier produced (corpus CI job test-testlibraries,
// runs 39234234851 / 39234269710 / 39234304686 on BC 27.5 / 28.5 / 29.0).
// BC versions: 27, 28, 29
table 81562 "LT BI IP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

enumextension 81565 "LT BI Event Category" extends EventCategory
{
    value(81565; "LT BI Category")
    {
        Caption = 'LT BI Category';
    }
}

codeunit 81563 "LT BI IP Probe"
{
    var
        Steps: Integer;

    procedure StepCount(): Integer
    begin
        exit(Steps);
    end;

    procedure InsertPlain()
    begin
        InsertRow();
        Error('LT BI inserted');
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT BI IP Row", 'I')]
    procedure InsertInherentI()
    var
        Row: Record "LT BI IP Row";
    begin
        Row."Entry No." := 1;
        Row.Insert();
        Error('LT BI inserted');
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT BI IP Row", 'R')]
    procedure InsertInherentR()
    var
        Row: Record "LT BI IP Row";
    begin
        Row."Entry No." := 1;
        Row.Insert();
        Error('LT BI inserted');
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT BI IP Row", 'I', InherentPermissionsScope::Permissions)]
    procedure InsertScopePermissions()
    var
        Row: Record "LT BI IP Row";
    begin
        Row."Entry No." := 1;
        Row.Insert();
        Error('LT BI inserted');
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT BI IP Row", 'I', InherentPermissionsScope::Entitlements)]
    procedure InsertScopeEntitlements()
    var
        Row: Record "LT BI IP Row";
    begin
        Row."Entry No." := 1;
        Row.Insert();
        Error('LT BI inserted');
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT BI IP Row", 'I', InherentPermissionsScope::Both)]
    procedure InsertScopeBoth()
    var
        Row: Record "LT BI IP Row";
    begin
        Row."Entry No." := 1;
        Row.Insert();
        Error('LT BI inserted');
    end;

    // The attribute is on the caller; the insert happens in a procedure without one.
    [InherentPermissions(PermissionObjectType::TableData, Database::"LT BI IP Row", 'I')]
    procedure InsertInCallee()
    begin
        InsertRow();
        Error('LT BI inserted');
    end;

    // ReadPermission and WritePermission of the record inside a procedure that has inherent R / RIMD.
    [InherentPermissions(PermissionObjectType::TableData, Database::"LT BI IP Row", 'R')]
    procedure PermissionsInsideR(): Text
    var
        Row: Record "LT BI IP Row";
    begin
        exit(Format(Row.ReadPermission()) + '/' + Format(Row.WritePermission()));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT BI IP Row", 'RIMD')]
    procedure PermissionsInsideRIMD(): Text
    var
        Row: Record "LT BI IP Row";
    begin
        exit(Format(Row.ReadPermission()) + '/' + Format(Row.WritePermission()));
    end;

    procedure PermissionsPlain(): Text
    var
        Row: Record "LT BI IP Row";
    begin
        exit(Format(Row.ReadPermission()) + '/' + Format(Row.WritePermission()));
    end;

    // Raises an external business event whose RequiredPermissions names table 81562 (read), which the session lacks.
    procedure RaiseBusinessEvent()
    begin
        Steps := 1;
        OnLtBiBusinessEvent('LT BI');
        Steps := 2;
    end;

    [TryFunction]
    procedure RaiseBusinessEventTry()
    begin
        RaiseBusinessEvent();
    end;

    local procedure InsertRow()
    var
        Row: Record "LT BI IP Row";
    begin
        Row."Entry No." := 1;
        Row.Insert();
    end;

    [ExternalBusinessEvent('lt_bi_event', 'LT BI event', 'Corpus probe of RequiredPermissions.', EventCategory::"LT BI Category", '1.0')]
    [RequiredPermissions(PermissionObjectType::TableData, Database::"LT BI IP Row", 'R')]
    local procedure OnLtBiBusinessEvent(Payload: Text[30])
    begin
    end;
}

codeunit 81564 "LT BI IP Tests"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    [Test]
    [HandlerFunctions('BiIpMsg')]
    procedure BiIp_InsertPlain()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI IP Probe";
    begin
        Message('LT BI');
        asserterror Probe.InsertPlain();
        Observer.ObserveError('ins');
        Observer.Expect('ins|text', 'Sorry, the current permissions prevented the action. (TableData 81562 LT BI IP Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('ins|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiIpMsg')]
    procedure BiIp_InherentI()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI IP Probe";
    begin
        Message('LT BI');
        asserterror Probe.InsertInherentI();
        Observer.ObserveError('ins');
        Observer.Expect('ins|text', 'LT BI inserted');
        Observer.Expect('ins|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiIpMsg')]
    procedure BiIp_InherentR()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI IP Probe";
    begin
        Message('LT BI');
        asserterror Probe.InsertInherentR();
        Observer.ObserveError('ins');
        Observer.Expect('ins|text', 'Sorry, the current permissions prevented the action. (TableData 81562 LT BI IP Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('ins|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiIpMsg')]
    procedure BiIp_ScopePermissions()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI IP Probe";
    begin
        Message('LT BI');
        asserterror Probe.InsertScopePermissions();
        Observer.ObserveError('ins');
        Observer.Expect('ins|text', 'LT BI inserted');
        Observer.Expect('ins|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiIpMsg')]
    procedure BiIp_ScopeEntitlements()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI IP Probe";
    begin
        Message('LT BI');
        asserterror Probe.InsertScopeEntitlements();
        Observer.ObserveError('ins');
        Observer.Expect('ins|text', 'Sorry, the current permissions prevented the action. (TableData 81562 LT BI IP Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('ins|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiIpMsg')]
    procedure BiIp_ScopeBoth()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI IP Probe";
    begin
        Message('LT BI');
        asserterror Probe.InsertScopeBoth();
        Observer.ObserveError('ins');
        Observer.Expect('ins|text', 'LT BI inserted');
        Observer.Expect('ins|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiIpMsg')]
    procedure BiIp_InsertInCallee()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI IP Probe";
    begin
        Message('LT BI');
        asserterror Probe.InsertInCallee();
        Observer.ObserveError('ins');
        Observer.Expect('ins|text', 'LT BI inserted');
        Observer.Expect('ins|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiIpMsg')]
    procedure BiIp_PermissionFunctions()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI IP Probe";
    begin
        Message('LT BI');
        Observer.Observe('plain', Probe.PermissionsPlain());
        Observer.Observe('inherent_r', Probe.PermissionsInsideR());
        Observer.Observe('inherent_rimd', Probe.PermissionsInsideRIMD());
        Observer.Expect('plain', 'No/No');
        Observer.Expect('inherent_r', 'Yes/No');
        Observer.Expect('inherent_rimd', 'Yes/Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiIpMsg')]
    procedure BiIp_RequiredPermissionsRaise()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI IP Probe";
    begin
        Message('LT BI');
        if Probe.RaiseBusinessEventTry() then
            Observer.Observe('raise', 'ok')
        else
            Observer.ObserveError('raise');
        Observer.Observe('steps', Format(Probe.StepCount()));
        Observer.Expect('raise', 'ok');
        Observer.Expect('steps', '2');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure BiIpMsg(Msg: Text[1024])
    begin
    end;
}
