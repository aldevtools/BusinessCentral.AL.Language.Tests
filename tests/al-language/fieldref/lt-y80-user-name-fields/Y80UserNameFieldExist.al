// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-fieldexist-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 94200, test codeunit 94201
// Probe (writer Y80, from the runtime lane rt-pages-1102c): RecordRef.FieldExist for the user-name system fields 2000000005 to 2000000008
//   (SystemCreatedByUserName, SystemCreatedByFullName, SystemModifiedByUserName, SystemModifiedByFullName; BC 29) and the numbers around them,
//   on an own table, a Base Application table, a temporary RecordRef, a virtual table and a platform table; what FieldCount and FieldIndex
//   show; what Field(n) gives when the field does not exist; Type, Class, Length, Name and Caption of the four fields through a FieldRef.
//   Y66FieldRefLengthTypes.al pins FieldExist for 2000000000 to 2000000004 and Length/Type of 2000000005 only.
// BC versions: 27, 28, 29

table 94200 "LT Y80 UN Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 94201 "LT Y80 UN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Exists(var RecRef: RecordRef; FromNo: Integer; ToNo: Integer): Text
    var
        No: Integer;
        Result: Text;
    begin
        for No := FromNo to ToNo do
            Result += Format(No - 2000000000) + '=' + Format(RecRef.FieldExist(No), 0, 9) + ';';
        exit(Result);
    end;

    local procedure Describe(var FieldRef: FieldRef): Text
    begin
        exit(FieldRef.Name() + '|' + Format(FieldRef.Type()) + '|' + Format(FieldRef.Class()) + '|' + Format(FieldRef.Length()) + '|' + Format(FieldRef.Number()) + '|' + FieldRef.Caption());
    end;

    [Test]
    procedure Y80_FieldExist_OwnTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT Y80 UN Row");
        Observer.Observe('own', Exists(RecRef, 2000000000, 2000000012));
        RecRef.Close();
        #if BC29PLUS
        Observer.Expect('own', '0=true;1=true;2=true;3=true;4=true;5=true;6=true;7=true;8=true;9=false;10=false;11=false;12=false;');
#else
        Observer.Expect('own', '0=true;1=true;2=true;3=true;4=true;5=false;6=false;7=false;8=false;9=false;10=false;11=false;12=false;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Y80_FieldExist_BaseApplicationTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Customer);
        Observer.Observe('customer', Exists(RecRef, 2000000003, 2000000010));
        RecRef.Close();
        RecRef.Open(Database::"Sales Header");
        Observer.Observe('sales header', Exists(RecRef, 2000000004, 2000000009));
        RecRef.Close();
        #if BC29PLUS
        Observer.Expect('customer', '3=true;4=true;5=true;6=true;7=true;8=true;9=false;10=false;');
        Observer.Expect('sales header', '4=true;5=true;6=true;7=true;8=true;9=false;');
#else
        Observer.Expect('customer', '3=true;4=true;5=false;6=false;7=false;8=false;9=false;10=false;');
        Observer.Expect('sales header', '4=true;5=false;6=false;7=false;8=false;9=false;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Y80_FieldExist_TemporaryAndGetTable()
    var
        RecRef: RecordRef;
        Row: Record "LT Y80 UN Row";
        TempRow: Record "LT Y80 UN Row" temporary;
    begin
        RecRef.Open(Database::"LT Y80 UN Row", true);
        Observer.Observe('temporary open', Exists(RecRef, 2000000004, 2000000009));
        RecRef.Close();
        RecRef.GetTable(TempRow);
        Observer.Observe('temporary get table', Exists(RecRef, 2000000004, 2000000009));
        RecRef.Close();
        RecRef.GetTable(Row);
        Observer.Observe('get table', Exists(RecRef, 2000000004, 2000000009));
        #if BC29PLUS
        Observer.Expect('temporary open', '4=true;5=true;6=true;7=true;8=true;9=false;');
        Observer.Expect('temporary get table', '4=true;5=true;6=true;7=true;8=true;9=false;');
        Observer.Expect('get table', '4=true;5=true;6=true;7=true;8=true;9=false;');
#else
        Observer.Expect('temporary open', '4=true;5=false;6=false;7=false;8=false;9=false;');
        Observer.Expect('temporary get table', '4=true;5=false;6=false;7=false;8=false;9=false;');
        Observer.Expect('get table', '4=true;5=false;6=false;7=false;8=false;9=false;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Y80_FieldExist_VirtualAndPlatformTables()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Integer);
        Observer.Observe('integer', Exists(RecRef, 2000000000, 2000000009));
        RecRef.Close();
        RecRef.Open(Database::Date);
        Observer.Observe('date', Exists(RecRef, 2000000000, 2000000009));
        RecRef.Close();
        RecRef.Open(Database::Company);
        Observer.Observe('company', Exists(RecRef, 2000000000, 2000000009));
        RecRef.Close();
        RecRef.Open(Database::"Table Metadata");
        Observer.Observe('table metadata', Exists(RecRef, 2000000000, 2000000009));
        RecRef.Close();
        RecRef.Open(Database::"Permission Set");
        Observer.Observe('permission set', Exists(RecRef, 2000000000, 2000000009));
        RecRef.Close();
        #if BC29PLUS
        Observer.Expect('integer', '0=true;1=true;2=true;3=true;4=true;5=true;6=true;7=true;8=true;9=false;');
        Observer.Expect('date', '0=true;1=true;2=true;3=true;4=true;5=true;6=true;7=true;8=true;9=false;');
        Observer.Expect('company', '0=true;1=true;2=true;3=true;4=true;5=true;6=true;7=true;8=true;9=false;');
        Observer.Expect('table metadata', '0=true;1=true;2=true;3=true;4=true;5=true;6=true;7=true;8=true;9=false;');
        Observer.Expect('permission set', '0=true;1=true;2=true;3=true;4=true;5=true;6=true;7=true;8=true;9=false;');
#else
        Observer.Expect('integer', '0=true;1=true;2=true;3=true;4=true;5=false;6=false;7=false;8=false;9=false;');
        Observer.Expect('date', '0=true;1=true;2=true;3=true;4=true;5=false;6=false;7=false;8=false;9=false;');
        Observer.Expect('company', '0=true;1=true;2=true;3=true;4=true;5=false;6=false;7=false;8=false;9=false;');
        Observer.Expect('table metadata', '0=true;1=true;2=true;3=true;4=true;5=false;6=false;7=false;8=false;9=false;');
        Observer.Expect('permission set', '0=true;1=true;2=true;3=true;4=true;5=false;6=false;7=false;8=false;9=false;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Y80_FieldCountAndFieldIndex()
    var
        RecRef: RecordRef;
        I: Integer;
        Names: Text;
    begin
        RecRef.Open(Database::"LT Y80 UN Row");
        Observer.Observe('field count', Format(RecRef.FieldCount()));
        for I := 1 to RecRef.FieldCount() do
            Names += RecRef.FieldIndex(I).Name() + ',';
        Observer.Observe('index names', Names);
        Observer.Observe('key field count', Format(RecRef.KeyIndex(1).FieldCount()));
        Observer.Expect('field count', '2');
        Observer.Expect('index names', 'Id,Txt,');
        Observer.Expect('key field count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Field_WhenItDoesNotExist()
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(Database::"LT Y80 UN Row");
        asserterror FieldRef := RecRef.Field(2000000009);
        Observer.ObserveError('field 9');
        asserterror FieldRef := RecRef.Field(2000000100);
        Observer.ObserveError('field 100');
        asserterror FieldRef := RecRef.Field(3);
        Observer.ObserveError('field 3');
#if not BC29PLUS
        asserterror FieldRef := RecRef.Field(2000000005);
        Observer.ObserveError('field 2000000005 before BC 29');
        asserterror FieldRef := RecRef.Field(2000000008);
        Observer.ObserveError('field 2000000008 before BC 29');
#endif
        Observer.Expect('field 9|text', 'The supplied field number ''2000000009'' cannot be found in the ''LT Y80 UN Row'' table.');
        Observer.Expect('field 9|code', 'FieldNotFound');
        Observer.Expect('field 100|text', 'The supplied field number ''2000000100'' cannot be found in the ''LT Y80 UN Row'' table.');
        Observer.Expect('field 100|code', 'FieldNotFound');
        Observer.Expect('field 3|text', 'The supplied field number ''3'' cannot be found in the ''LT Y80 UN Row'' table.');
        Observer.Expect('field 3|code', 'FieldNotFound');
#if not BC29PLUS
        Observer.Expect('field 2000000005 before BC 29|text', 'The supplied field number ''2000000005'' cannot be found in the ''LT Y80 UN Row'' table.');
        Observer.Expect('field 2000000005 before BC 29|code', 'FieldNotFound');
        Observer.Expect('field 2000000008 before BC 29|text', 'The supplied field number ''2000000008'' cannot be found in the ''LT Y80 UN Row'' table.');
        Observer.Expect('field 2000000008 before BC 29|code', 'FieldNotFound');
#endif
        Observer.Verify();
    end;

#if BC29PLUS
    [Test]
    procedure Y80_UserNameFields_FieldRefProperties()
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        No: Integer;
    begin
        RecRef.Open(Database::"LT Y80 UN Row");
        for No := 2000000005 to 2000000008 do begin
            FieldRef := RecRef.Field(No);
            Observer.Observe(Format(No), Describe(FieldRef));
        end;
        RecRef.Close();
        RecRef.Open(Database::Customer);
        for No := 2000000005 to 2000000008 do begin
            FieldRef := RecRef.Field(No);
            Observer.Observe('customer ' + Format(No), Describe(FieldRef));
        end;
        Observer.Expect('2000000005', 'SystemCreatedByUserName|Text|FlowField|50|2000000005|Created By (User Name)');
        Observer.Expect('2000000006', 'SystemCreatedByFullName|Text|FlowField|80|2000000006|Created By (Full Name)');
        Observer.Expect('2000000007', 'SystemModifiedByUserName|Text|FlowField|50|2000000007|Modified By (User Name)');
        Observer.Expect('2000000008', 'SystemModifiedByFullName|Text|FlowField|80|2000000008|Modified By (Full Name)');
        Observer.Expect('customer 2000000005', 'SystemCreatedByUserName|Text|FlowField|50|2000000005|Created By (User Name)');
        Observer.Expect('customer 2000000006', 'SystemCreatedByFullName|Text|FlowField|80|2000000006|Created By (Full Name)');
        Observer.Expect('customer 2000000007', 'SystemModifiedByUserName|Text|FlowField|50|2000000007|Modified By (User Name)');
        Observer.Expect('customer 2000000008', 'SystemModifiedByFullName|Text|FlowField|80|2000000008|Modified By (Full Name)');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_UserNameFields_Values()
    var
        Row: Record "LT Y80 UN Row";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        No: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        RecRef.GetTable(Row);
        for No := 2000000005 to 2000000008 do begin
            FieldRef := RecRef.Field(No);
            Observer.Observe('before calc ' + Format(No - 2000000000), Format(Format(FieldRef.Value) = '', 0, 9));
            FieldRef.CalcField();
        end;
        Observer.Observe('created by user name is the user', Format(Format(RecRef.Field(2000000005).Value) = UserId(), 0, 9));
        Observer.Observe('modified by user name is the user', Format(Format(RecRef.Field(2000000007).Value) = UserId(), 0, 9));
        Row.Delete();
        Observer.Expect('before calc 5', 'true');
        Observer.Expect('before calc 6', 'true');
        Observer.Expect('before calc 7', 'true');
        Observer.Expect('before calc 8', 'true');
        Observer.Expect('created by user name is the user', 'true');
        Observer.Expect('modified by user name is the user', 'true');
        Observer.Verify();
    end;
#endif
}
