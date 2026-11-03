// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90645, table 90646
// Probe: written against al-runner issue 6313 (a temporary copy of the Field row of a user-name system field); every value asserted below is what the BC service tier produced.
// Facts: the Field row of an ordinary field and of the user-name system fields (2000000005 to 2000000008, BC 29 only) copied into a temporary Field record and inserted:
//        whether the insert runs, the SystemId of the row before and after, and the other columns that survive the copy.
// BC versions: 29

#if BC29PLUS
table 90646 "LT WC Field Item"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 90645 "LT WC Field Row Copy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure CopyRow(FieldNo: Integer): Text
    var
        FieldRec: Record Field;
        TempField: Record Field temporary;
        Result: Text;
    begin
        FieldRec.Get(Database::"LT WC Field Item", FieldNo);
        Result := 'src sysid=' + Format(FieldRec.SystemId) + '|name=' + FieldRec.FieldName + '|type=' + Format(FieldRec.Type);
        TempField := FieldRec;
        Result += '|copy sysid=' + Format(TempField.SystemId);
        TempField.Insert();
        Result += '|count=' + Format(TempField.Count());
        TempField.Get(Database::"LT WC Field Item", FieldNo);
        Result += '|back sysid=' + Format(TempField.SystemId) + '|name=' + TempField.FieldName;
        exit(Result);
    end;

    [Test]
    procedure WC_FieldRow_Copy_Ordinary()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('description', CopyRow(2));
        Observer.Expect('description', 'src sysid={77359429-6216-0001-0200-000000000000}|name=Description|type=Text|copy sysid={77359429-6216-0001-0200-000000000000}|count=1|back sysid={77359429-6216-0001-0200-000000000000}|name=Description');
        Observer.Verify();
    end;

    [Test]
    procedure WC_FieldRow_Copy_UserNameSystemFields()
    var
        Observer: Codeunit "Probe Observer";
        FieldNo: Integer;
    begin
        for FieldNo := 2000000005 to 2000000008 do
            Observer.Observe(Format(FieldNo), CopyRow(FieldNo));
        Observer.Expect('2000000005', 'src sysid={77359429-6216-0001-0594-357700000000}|name=SystemCreatedByUserName|type=Text|copy sysid={77359429-6216-0001-0594-357700000000}|count=1|back sysid={77359429-6216-0001-0594-357700000000}|name=SystemCreatedByUserName');
        Observer.Expect('2000000006', 'src sysid={77359429-6216-0001-0694-357700000000}|name=SystemCreatedByFullName|type=Text|copy sysid={77359429-6216-0001-0694-357700000000}|count=1|back sysid={77359429-6216-0001-0694-357700000000}|name=SystemCreatedByFullName');
        Observer.Expect('2000000007', 'src sysid={77359429-6216-0001-0794-357700000000}|name=SystemModifiedByUserName|type=Text|copy sysid={77359429-6216-0001-0794-357700000000}|count=1|back sysid={77359429-6216-0001-0794-357700000000}|name=SystemModifiedByUserName');
        Observer.Expect('2000000008', 'src sysid={77359429-6216-0001-0894-357700000000}|name=SystemModifiedByFullName|type=Text|copy sysid={77359429-6216-0001-0894-357700000000}|count=1|back sysid={77359429-6216-0001-0894-357700000000}|name=SystemModifiedByFullName');
        Observer.Verify();
    end;

    [Test]
    procedure WC_FieldRow_Copy_AllFieldsOfTable()
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
        TempField: Record Field temporary;
    begin
        FieldRec.SetRange(TableNo, Database::"LT WC Field Item");
        if FieldRec.FindSet() then
            repeat
                TempField := FieldRec;
                TempField.Insert();
            until FieldRec.Next() = 0;
        Observer.Observe('source count', Format(FieldRec.Count()));
        Observer.Observe('copy count', Format(TempField.Count()));
        Observer.Expect('source count', '11');
        Observer.Expect('copy count', '11');
        Observer.Verify();
    end;
}
#endif
