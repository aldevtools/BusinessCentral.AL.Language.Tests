// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-testpermissions-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table "LT CP Ledger" (CpPermObjects.al).
// Probe: corpus issue 669 items 87 and 88. The effective permissions of a test method under each codeunit TestPermissions value (and none),
//   with and without the method attribute [TestPermissions(TestPermissions::InheritFromTestCodeunit)], under Microsoft's test runner as the corpus
//   CI uses it. Each test inserts into and deletes from a table that no permission set of the user names directly, with no Permissions Mock call.
//   Method-level Disabled, Restrictive and NonRestrictive are in lt-ac/ACAttributes.al.
// BC versions: 27, 28, 29

codeunit 85019 "LT CP TestPerm Restrictive"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    [Test]
    procedure TestPerm_Restrictive_NoAttribute()
    begin
        InsertAndDelete(101);
    end;

    [Test]
    [TestPermissions(TestPermissions::InheritFromTestCodeunit)]
    procedure TestPerm_Restrictive_InheritAttribute()
    begin
        InsertAndDelete(102);
    end;

    local procedure InsertAndDelete(EntryNo: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Ledger: Record "LT CP Ledger";
    begin
        if Ledger.Get(EntryNo) then
            Ledger.Delete();
        Ledger."Entry No." := EntryNo;
        if Ledger.Insert() then
            Observer.Observe('insert', 'true')
        else
            Observer.ObserveError('insert');
        if Ledger.Delete() then
            Observer.Observe('delete', 'true')
        else
            Observer.ObserveError('delete');
        Observer.Expect('insert', 'true');
        Observer.Expect('delete', 'true');
        Observer.Verify();
    end;
}

codeunit 85020 "LT CP TestPerm NonRestrictive"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    [Test]
    procedure TestPerm_NonRestrictive_NoAttribute()
    begin
        InsertAndDelete(111);
    end;

    [Test]
    [TestPermissions(TestPermissions::InheritFromTestCodeunit)]
    procedure TestPerm_NonRestrictive_InheritAttribute()
    begin
        InsertAndDelete(112);
    end;

    local procedure InsertAndDelete(EntryNo: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Ledger: Record "LT CP Ledger";
    begin
        if Ledger.Get(EntryNo) then
            Ledger.Delete();
        Ledger."Entry No." := EntryNo;
        if Ledger.Insert() then
            Observer.Observe('insert', 'true')
        else
            Observer.ObserveError('insert');
        if Ledger.Delete() then
            Observer.Observe('delete', 'true')
        else
            Observer.ObserveError('delete');
        Observer.Expect('insert', 'true');
        Observer.Expect('delete', 'true');
        Observer.Verify();
    end;
}

codeunit 85021 "LT CP TestPerm Disabled"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TestPerm_Disabled_NoAttribute()
    begin
        InsertAndDelete(121);
    end;

    [Test]
    [TestPermissions(TestPermissions::InheritFromTestCodeunit)]
    procedure TestPerm_Disabled_InheritAttribute()
    begin
        InsertAndDelete(122);
    end;

    local procedure InsertAndDelete(EntryNo: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Ledger: Record "LT CP Ledger";
    begin
        if Ledger.Get(EntryNo) then
            Ledger.Delete();
        Ledger."Entry No." := EntryNo;
        if Ledger.Insert() then
            Observer.Observe('insert', 'true')
        else
            Observer.ObserveError('insert');
        if Ledger.Delete() then
            Observer.Observe('delete', 'true')
        else
            Observer.ObserveError('delete');
        Observer.Expect('insert', 'true');
        Observer.Expect('delete', 'true');
        Observer.Verify();
    end;
}

codeunit 85022 "LT CP TestPerm None"
{
    Subtype = Test;

    [Test]
    procedure TestPerm_None_NoAttribute()
    begin
        InsertAndDelete(131);
    end;

    [Test]
    [TestPermissions(TestPermissions::InheritFromTestCodeunit)]
    procedure TestPerm_None_InheritAttribute()
    begin
        InsertAndDelete(132);
    end;

    local procedure InsertAndDelete(EntryNo: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Ledger: Record "LT CP Ledger";
    begin
        if Ledger.Get(EntryNo) then
            Ledger.Delete();
        Ledger."Entry No." := EntryNo;
        if Ledger.Insert() then
            Observer.Observe('insert', 'true')
        else
            Observer.ObserveError('insert');
        if Ledger.Delete() then
            Observer.Observe('delete', 'true')
        else
            Observer.ObserveError('delete');
        Observer.Expect('insert', 'true');
        Observer.Expect('delete', 'true');
        Observer.Verify();
    end;
}

codeunit 85023 "LT CP TestPerm Inherit"
{
    Subtype = Test;
    TestPermissions = InheritFromTestCodeunit;

    [Test]
    procedure TestPerm_Inherit_NoAttribute()
    begin
        InsertAndDelete(141);
    end;

    [Test]
    [TestPermissions(TestPermissions::InheritFromTestCodeunit)]
    procedure TestPerm_Inherit_InheritAttribute()
    begin
        InsertAndDelete(142);
    end;

    local procedure InsertAndDelete(EntryNo: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Ledger: Record "LT CP Ledger";
    begin
        if Ledger.Get(EntryNo) then
            Ledger.Delete();
        Ledger."Entry No." := EntryNo;
        if Ledger.Insert() then
            Observer.Observe('insert', 'true')
        else
            Observer.ObserveError('insert');
        if Ledger.Delete() then
            Observer.Observe('delete', 'true')
        else
            Observer.ObserveError('delete');
        Observer.Expect('insert', 'true');
        Observer.Expect('delete', 'true');
        Observer.Verify();
    end;
}
