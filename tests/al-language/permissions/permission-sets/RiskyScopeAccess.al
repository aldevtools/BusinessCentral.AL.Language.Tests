// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: none. RISKY: table Scope = Cloud, enum Scope/Access, Access = Internal on table, codeunit, query.
// Scope = OnPrem is not possible in the Cloud app; Access = Internal use from another app is not possible here.

table 70471 "LT P116 Scope Cloud"
{
    Scope = Cloud;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Name; Text[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 70472 "LT P116 Access Int"
{
    Access = Internal;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Name; Text[20]) { Access = Internal; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

enum 70473 "LT P116 Enum Int"
{
    Access = Internal;
    Extensible = false;

    value(0; None) { }
    value(1; One) { }
}

enum 70474 "LT P116 Enum Cloud"
{
    Scope = Cloud;
    Extensible = true;

    value(0; None) { }
    value(1; One) { }
}

codeunit 70475 "LT P116 Access Int Cu"
{
    Access = Internal;

    procedure Twice(Value: Integer): Integer
    begin
        exit(Value * 2);
    end;

    internal procedure Thrice(Value: Integer): Integer
    begin
        exit(Value * 3);
    end;
}

codeunit 70476 "LT P116 Scope Access"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P116_ScopeCloudTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P116 Scope Cloud";
    begin
        Row.DeleteAll();
        Row."Entry No." := 1;
        Row.Name := 'a';
        Row.Insert();
        Observer.Observe('count', Format(Row.Count()));
        Row.Get(1);
        Observer.Observe('name', Row.Name);
        Observer.Observe('table id in range', Format(Row.RecordId.TableNo = Database::"LT P116 Scope Cloud"));
        Observer.Expect('count', '1');
        Observer.Expect('name', 'a');
        Observer.Expect('table id in range', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P116_AccessInternalTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P116 Access Int";
    begin
        Row.DeleteAll();
        Row."Entry No." := 1;
        Row.Name := 'b';
        Row.Insert();
        Observer.Observe('count', Format(Row.Count()));
        Row.Get(1);
        Observer.Observe('name', Row.Name);
        Observer.Observe('fieldname', Row.FieldName(Name));
        Observer.Expect('count', '1');
        Observer.Expect('name', 'b');
        Observer.Expect('fieldname', 'Name');
        Observer.Verify();
    end;

    [Test]
    procedure P116_EnumAccessAndScope()
    var
        Observer: Codeunit "Probe Observer";
        IntEnum: Enum "LT P116 Enum Int";
        CloudEnum: Enum "LT P116 Enum Cloud";
    begin
        IntEnum := IntEnum::One;
        CloudEnum := CloudEnum::One;
        Observer.Observe('internal enum', Format(IntEnum));
        Observer.Observe('internal ordinal', Format(IntEnum.AsInteger()));
        Observer.Observe('cloud enum', Format(CloudEnum));
        Observer.Observe('cloud ordinal', Format(CloudEnum.AsInteger()));
        Observer.Observe('internal names', Format(IntEnum.Names().Count()));
        Observer.Observe('cloud names', Format(CloudEnum.Names().Count()));
        Observer.Observe('cloud from ordinal', Format(Enum::"LT P116 Enum Cloud".FromInteger(0)));
        Observer.Expect('internal enum', 'One');
        Observer.Expect('internal ordinal', '1');
        Observer.Expect('cloud enum', 'One');
        Observer.Expect('cloud ordinal', '1');
        Observer.Expect('internal names', '2');
        Observer.Expect('cloud names', '2');
        Observer.Expect('cloud from ordinal', 'None');
        Observer.Verify();
    end;

    [Test]
    procedure P116_InternalCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Cu: Codeunit "LT P116 Access Int Cu";
    begin
        Observer.Observe('twice', Format(Cu.Twice(4)));
        Observer.Observe('thrice', Format(Cu.Thrice(4)));
        Observer.Expect('twice', '8');
        Observer.Expect('thrice', '12');
        Observer.Verify();
    end;

    // Writer QB (corpus issue #664 item 91): a Cloud app calls a public procedure of an OnPrem-target app (System Application) whose
    // implementation is a [Scope('OnPrem')] procedure: User Settings.GetAllowedCompaniesForCurrentUser calls User Settings Impl.
    // GetAllowedCompaniesForCurrentUser, which is Scope OnPrem and uses DotNet NavUserAccountHelper. Calling the Impl procedure directly
    // from this app is AL0296 (compare must-not-compile 0981). Does the call through the public procedure run?
    [Test]
    procedure QB_CloudCallsPublicProcedureWithOnPremScopedImpl()
    var
        Observer: Codeunit "Probe Observer";
        UserSettings: Codeunit "User Settings";
        TempCompany: Record Company temporary;
    begin
        ClearLastError();
        if TryAllowedCompanies(UserSettings, TempCompany) then
            Observer.Observe('call', 'ok')
        else
            Observer.ObserveError('call');
        Observer.Observe('contains current company', Format(TempCompany.Get(CompanyName())));
        Observer.Expect('call', 'ok');
        Observer.Expect('contains current company', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAllowedCompanies(var UserSettings: Codeunit "User Settings"; var TempCompany: Record Company temporary)
    begin
        UserSettings.GetAllowedCompaniesForCurrentUser(TempCompany);
    end;
}
