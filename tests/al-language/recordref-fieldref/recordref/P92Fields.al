// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-field-method
// Scope: in-scope
// Fixtures used: tables 72200-72201, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against BC 29 (draft, measured later by the lead).
// Facts: RecordRef.Field and FieldExist by number, missing numbers, FieldIndex, system fields, FieldRef copies refer to the same field
// BC versions: 29 (27 and 28 by CI)

codeunit 72211 "LT P92 Fields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryField(var RecRef: RecordRef; No: Integer; var NameOut: Text)
    var
        Fld: FieldRef;
    begin
        Fld := RecRef.Field(No);
        NameOut := Fld.Name();
    end;

    local procedure FieldName(var RecRef: RecordRef; No: Integer): Text
    var
        N: Text;
    begin
        if TryField(RecRef, No, N) then
            exit(N);
        exit('error|' + GetLastErrorCode());
    end;

#if BC29PLUS
    [Test]
    procedure FieldExist_ByNumber()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.Open(72200);
        for i := 0 to 12 do
            Observer.Observe('exist_' + Format(i), Format(RecRef.FieldExist(i)));
        Observer.Observe('exist_neg1', Format(RecRef.FieldExist(-1)));
        Observer.Observe('exist_big', Format(RecRef.FieldExist(99999)));
        Observer.Observe('exist_systemid', Format(RecRef.FieldExist(2000000000)));
        Observer.Observe('exist_createdat', Format(RecRef.FieldExist(2000000001)));
        Observer.Observe('exist_createdby', Format(RecRef.FieldExist(2000000002)));
        Observer.Observe('exist_modifiedat', Format(RecRef.FieldExist(2000000003)));
        Observer.Observe('exist_modifiedby', Format(RecRef.FieldExist(2000000004)));
        Observer.Observe('exist_2000000005', Format(RecRef.FieldExist(2000000005)));
        Observer.Observe('exist_maxint', Format(RecRef.FieldExist(2147483647)));
        RecRef.Close();
        Observer.Expect('exist_0', 'No');
        Observer.Expect('exist_1', 'Yes');
        Observer.Expect('exist_2', 'Yes');
        Observer.Expect('exist_3', 'Yes');
        Observer.Expect('exist_4', 'Yes');
        Observer.Expect('exist_5', 'Yes');
        Observer.Expect('exist_6', 'Yes');
        Observer.Expect('exist_7', 'Yes');
        Observer.Expect('exist_8', 'Yes');
        Observer.Expect('exist_9', 'Yes');
        Observer.Expect('exist_10', 'Yes');
        Observer.Expect('exist_11', 'No');
        Observer.Expect('exist_12', 'No');
        Observer.Expect('exist_neg1', 'No');
        Observer.Expect('exist_big', 'No');
        Observer.Expect('exist_systemid', 'Yes');
        Observer.Expect('exist_createdat', 'Yes');
        Observer.Expect('exist_createdby', 'Yes');
        Observer.Expect('exist_modifiedat', 'Yes');
        Observer.Expect('exist_modifiedby', 'Yes');
        Observer.Expect('exist_2000000005', 'Yes');
        Observer.Expect('exist_maxint', 'No');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure Field_ByNumberNames()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.Open(72200);
        for i := 1 to 10 do
            Observer.Observe('name_' + Format(i), FieldName(RecRef, i));
        Observer.Observe('name_systemid', FieldName(RecRef, 2000000000));
        Observer.Observe('name_createdat', FieldName(RecRef, 2000000001));
        Observer.Observe('name_modifiedat', FieldName(RecRef, 2000000003));
        RecRef.Close();
        Observer.Expect('name_1', 'Code');
        Observer.Expect('name_2', 'Name');
        Observer.Expect('name_3', 'Qty');
        Observer.Expect('name_4', 'Amt');
        Observer.Expect('name_5', 'Flag');
        Observer.Expect('name_6', 'Dt');
        Observer.Expect('name_7', 'Kind');
        Observer.Expect('name_8', 'Note');
        Observer.Expect('name_9', 'Pic');
        Observer.Expect('name_10', 'Cd');
        Observer.Expect('name_systemid', '$systemId');
        Observer.Expect('name_createdat', 'SystemCreatedAt');
        Observer.Expect('name_modifiedat', 'SystemModifiedAt');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRef_CopyRefersToSameField()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Fld2: FieldRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.FindFirst();
        Fld := RecRef.Field(2);
        Fld2 := Fld;
        Observer.Observe('copy_number', Format(Fld2.Number()));
        Fld2.Value := 'Changed';
        Observer.Observe('via_original', Format(Fld.Value));
        Observer.Observe('via_recref', Format(RecRef.Field(2).Value));
        Fld.Value := 'Again';
        Observer.Observe('via_copy', Format(Fld2.Value));
        RecRef.FindLast();
        Observer.Observe('after_find_last_original', Format(Fld.Value));
        Observer.Observe('after_find_last_copy', Format(Fld2.Value));
        RecRef.Close();
        Observer.Expect('copy_number', '2');
        Observer.Expect('via_original', 'Changed');
        Observer.Expect('via_recref', 'Changed');
        Observer.Expect('via_copy', 'Again');
        Observer.Expect('after_find_last_original', '');
        Observer.Expect('after_find_last_copy', '');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRef_Uninitialized()
    var
        Observer: Codeunit "Probe Observer";
        Fld: FieldRef;
        Dummy: Text;
        N: Integer;
    begin
        asserterror Dummy := Fld.Name();
        Observer.ObserveError('name');
        asserterror N := Fld.Number();
        Observer.ObserveError('number');
        asserterror Dummy := Format(Fld.Value);
        Observer.ObserveError('value');
        asserterror Dummy := Fld.Caption();
        Observer.ObserveError('caption');
        asserterror Fld.TestField();
        Observer.ObserveError('testfield');
        asserterror Fld.FieldError();
        Observer.ObserveError('fielderror');
        Observer.Expect('name|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('name|code', 'NotInitialized');
        Observer.Expect('number|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('number|code', 'NotInitialized');
        Observer.Expect('value|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('value|code', 'NotInitialized');
        Observer.Expect('caption|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('caption|code', 'NotInitialized');
        Observer.Expect('testfield|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('testfield|code', 'NotInitialized');
        Observer.Expect('fielderror|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('fielderror|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure FieldExist_ClosedRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        B: Boolean;
    begin
        asserterror B := RecRef.FieldExist(1);
        Observer.ObserveError('closed_fieldexist');
        RecRef.Open(72200);
        RecRef.Close();
        asserterror B := RecRef.FieldExist(1);
        Observer.ObserveError('after_close_fieldexist');
        Observer.Expect('closed_fieldexist|text', 'The record is not open.');
        Observer.Expect('closed_fieldexist|code', 'RecordNotOpened');
        Observer.Expect('after_close_fieldexist|text', 'The record is not open.');
        Observer.Expect('after_close_fieldexist|code', 'RecordNotOpened');
        Observer.Verify();
    end;

#if not BC29PLUS
    // Writer PX (probes-needed "Platform tables and session facts": RecordRef.FieldExist(2000000005) before BC 29; BC 29 answers Yes,
    // FieldExist_ByNumber above). The four user-name system fields 2000000005-2000000008 arrived with BC 29; 2000000009 for comparison.
    [Test]
    procedure PX_FieldExist_UserNameSystemFields_Before29()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.Open(72200);
        for i := 2000000005 to 2000000009 do
            Observer.Observe('exist_' + Format(i), Format(RecRef.FieldExist(i)));
        Observer.Expect('exist_2000000005', 'No');
        Observer.Expect('exist_2000000006', 'No');
        Observer.Expect('exist_2000000007', 'No');
        Observer.Expect('exist_2000000008', 'No');
        Observer.Expect('exist_2000000009', 'No');
        Observer.Verify();
    end;
#endif
}
