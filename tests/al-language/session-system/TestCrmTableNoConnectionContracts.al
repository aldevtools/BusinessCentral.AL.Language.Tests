// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-registertableconnection-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); ALT CRM Entity (60291, a TableType = CRM table); self-contained
//                codeunit 68820
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins what a TableType = CRM table does while no CRM table connection is registered
// (session/TestDatabaseTableConnectionCrm.al covers the registered '@@test@@' connection): nothing
// can touch it, not even the operations that read no data. The first use of a record variable of the table
// (Init, TableCaption, a field assignment, IsEmpty) and RecordRef.Open of the table fail, all with
//   "Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet
//   New-NAVTableConnection before it can be used." (two spaces after "connection")
// and the code Argument.
// BC versions: 27.5

codeunit 68820 "Probe Crm No Connection"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Reached: Boolean;

    local procedure OpInit()
    var
        Entity: Record "ALT CRM Entity";
    begin
        Entity.Init();
        Reached := true;
    end;

    local procedure OpCaption()
    var
        Entity: Record "ALT CRM Entity";
        Caption: Text;
    begin
        Caption := Entity.TableCaption();
        Reached := true;
    end;

    local procedure OpAssign()
    var
        Entity: Record "ALT CRM Entity";
    begin
        Entity.Name := 'x';
        Reached := true;
    end;

    local procedure OpIsEmpty()
    var
        Entity: Record "ALT CRM Entity";
        Empty: Boolean;
    begin
        Empty := Entity.IsEmpty();
        Reached := true;
    end;

    local procedure OpenRecordRef()
    var
        Ref: RecordRef;
    begin
        Ref.Open(Database::"ALT CRM Entity");
        Reached := true;
    end;

    local procedure AssertNoConnection(Context: Text)
    begin
        Assert.AreEqual('Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.', GetLastErrorText(), Context + ': text');
        Assert.AreEqual('Argument', GetLastErrorCode(), Context + ': code');
        Assert.IsFalse(Reached, Context + ': the statement after it did not run');
        ClearLastError();
    end;

    [Test]
    procedure RecordOfACrmTable_EveryFirstUse_RaisesTheConnectionError()
    begin
        Reached := false;
        asserterror OpInit();
        AssertNoConnection('Init');

        asserterror OpCaption();
        AssertNoConnection('TableCaption');

        asserterror OpAssign();
        AssertNoConnection('field assignment');

        asserterror OpIsEmpty();
        AssertNoConnection('IsEmpty');
    end;

    [Test]
    procedure RecordRefOpen_OfACrmTable_Fails()
    begin
        Reached := false;

        asserterror OpenRecordRef();

        AssertNoConnection('RecordRef.Open');
    end;
}
