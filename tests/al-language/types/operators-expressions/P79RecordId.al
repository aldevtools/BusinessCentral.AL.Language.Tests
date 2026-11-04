// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordid/recordid-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own tables 73960-73964, test codeunits 73965-73968
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordId in Error/GetLastErrorText, StrSubstNo, Format numbers 0-9 and custom strings; temporary, never-read and blank RecordIds; Code/Integer/Date/Guid/composite primary keys
// BC versions: 29 (27 and 28 by CI)

table 73960 "LT P79 RId Code"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

table 73961 "LT P79 RId Int"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; No; Integer) { }
    }
    keys { key(PK; No) { Clustered = true; } }
}

table 73962 "LT P79 RId Date"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; D; Date) { }
    }
    keys { key(PK; D) { Clustered = true; } }
}

table 73963 "LT P79 RId Guid"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; G; Guid) { }
    }
    keys { key(PK; G) { Clustered = true; } }
}

table 73964 "LT P79 RId Comp"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; C; Code[10]) { }
        field(2; N; Integer) { }
        field(3; D; Date) { }
        field(4; T; Text[30]) { }
    }
    keys { key(PK; C, N, D) { Clustered = true; } }
}

codeunit 73965 "LT P79 RId Error Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup(var RC: Record "LT P79 RId Code"; var RI: Record "LT P79 RId Int")
    begin
        RC.DeleteAll();
        RI.DeleteAll();
        RC.Code := 'A-1';
        RC.Insert();
        RI.No := 42;
        RI.Insert();
    end;

    [Test]
    procedure Error_RecordIdInText()
    var
        Observer: Codeunit "Probe Observer";
        RC: Record "LT P79 RId Code";
        RI: Record "LT P79 RId Int";
    begin
        Setup(RC, RI);
        asserterror Error('%1', RC.RecordId);
        Observer.ObserveError('code-key');
        asserterror Error('%1', RI.RecordId);
        Observer.ObserveError('int-key');
        asserterror Error('Record %1 is locked (%2)', RC.RecordId, 7);
        Observer.ObserveError('longer-text');
        asserterror Error('%1 and %2', RC.RecordId, RI.RecordId);
        Observer.ObserveError('two-ids');
        asserterror Error('Id: %1.', RC.RecordId);
        Observer.ObserveError('trailing-dot');
        asserterror Error('%1', Format(RC.RecordId));
        Observer.ObserveError('formatted');
        asserterror Error('%1', Format(RC.RecordId, 0, 9));
        Observer.ObserveError('formatted9');
        Observer.Expect('code-key|text', 'LT P79 RId Code: A-1');
        Observer.Expect('code-key|code', 'Dialog');
        Observer.Expect('int-key|text', 'LT P79 RId Int: 42');
        Observer.Expect('int-key|code', 'Dialog');
        Observer.Expect('longer-text|text', 'Record LT P79 RId Code: A-1 is locked (7)');
        Observer.Expect('longer-text|code', 'Dialog');
        Observer.Expect('two-ids|text', 'LT P79 RId Code: A-1 and LT P79 RId Int: 42');
        Observer.Expect('two-ids|code', 'Dialog');
        Observer.Expect('trailing-dot|text', 'Id: LT P79 RId Code: A-1.');
        Observer.Expect('trailing-dot|code', 'Dialog');
        Observer.Expect('formatted|text', 'LT P79 RId Code: A-1');
        Observer.Expect('formatted|code', 'Dialog');
        Observer.Expect('formatted9|text', 'LT P79 RId Code: A-1');
        Observer.Expect('formatted9|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure GetLastErrorText_WithRecordId()
    var
        Observer: Codeunit "Probe Observer";
        RC: Record "LT P79 RId Code";
        RI: Record "LT P79 RId Int";
    begin
        Setup(RC, RI);
        asserterror Error('%1', RC.RecordId);
        Observer.Observe('last-text', GetLastErrorText());
        Observer.Observe('last-code', GetLastErrorCode());
        ClearLastError();
        asserterror RC.FieldError(Code, 'is not allowed for ' + Format(RC.RecordId));
        Observer.ObserveError('fielderror-with-id');
        asserterror RC.TestField(Descr);
        Observer.ObserveError('testfield-blank');
        asserterror RI.TestField(No, 1);
        Observer.ObserveError('testfield-value');
        Observer.Expect('last-text', 'LT P79 RId Code: A-1');
        Observer.Expect('last-code', 'Dialog');
        Observer.Expect('fielderror-with-id|text', 'Code is not allowed for LT P79 RId Code: A-1 in LT P79 RId Code Code=''A-1''.');
        Observer.Expect('fielderror-with-id|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('testfield-blank|text', 'Descr must have a value in LT P79 RId Code: Code=A-1. It cannot be zero or empty.');
        Observer.Expect('testfield-blank|code', 'TestField');
        Observer.Expect('testfield-value|text', 'No must be equal to ''1''  in LT P79 RId Int: No=42. Current value is ''42''.');
        Observer.Expect('testfield-value|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure StrSubstNo_WithRecordId()
    var
        Observer: Codeunit "Probe Observer";
        RC: Record "LT P79 RId Code";
        RI: Record "LT P79 RId Int";
        RecRef: RecordRef;
    begin
        Setup(RC, RI);
        RecRef.GetTable(RC);
        Observer.Observe('subst-recref', StrSubstNo('%1', RecRef.RecordId));
        Observer.Observe('subst-rec', StrSubstNo('%1', RC.RecordId));
        Observer.Observe('subst-int', StrSubstNo('%1', RI.RecordId));
        Observer.Observe('subst-long', StrSubstNo('Rec=%1;Cnt=%2;Rec2=%3', RC.RecordId, 3, RI.RecordId));
        Observer.Observe('subst-padded', StrSubstNo('[%1]', RC.RecordId));
        Observer.Observe('subst-width', StrSubstNo('%1', Format(RC.RecordId)));
        Observer.Observe('subst-len', Format(StrLen(StrSubstNo('%1', RC.RecordId))));
        Observer.Observe('concat', 'X' + Format(RC.RecordId) + 'Y');
        Observer.Observe('text-var', CopyStr(Format(RC.RecordId), 1, 10));
        Observer.Expect('subst-recref', 'LT P79 RId Code: A-1');
        Observer.Expect('subst-rec', 'LT P79 RId Code: A-1');
        Observer.Expect('subst-int', 'LT P79 RId Int: 42');
        Observer.Expect('subst-long', 'Rec=LT P79 RId Code: A-1;Cnt=3;Rec2=LT P79 RId Int: 42');
        Observer.Expect('subst-padded', '[LT P79 RId Code: A-1]');
        Observer.Expect('subst-width', 'LT P79 RId Code: A-1');
        Observer.Expect('subst-len', '20');
        Observer.Expect('concat', 'XLT P79 RId Code: A-1Y');
        Observer.Expect('text-var', 'LT P79 RId');
        Observer.Verify();
    end;
}

codeunit 73966 "LT P79 RId Format Numbers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFmt(RId: RecordId; N: Integer; var R: Text)
    begin
        R := Format(RId, 0, N);
    end;

    local procedure F(RId: RecordId; N: Integer): Text
    var
        R: Text;
    begin
        if TryFmt(RId, N, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCustom(RId: RecordId; Fmt: Text; var R: Text)
    begin
        R := Format(RId, 0, Fmt);
    end;

    local procedure FC(RId: RecordId; Fmt: Text): Text
    var
        R: Text;
    begin
        if TryCustom(RId, Fmt, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure CodeKey_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        RC: Record "LT P79 RId Code";
        i: Integer;
    begin
        RC.DeleteAll();
        RC.Code := 'A-1';
        RC.Insert();
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(RC.RecordId, i));
        Observer.Observe('default', Format(RC.RecordId));
        Observer.Expect('n0', 'LT P79 RId Code: A-1');
        Observer.Expect('n1', 'LT P79 RId Code: A-1');
        Observer.Expect('n2', 'LT P79 RId Code: A-1');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n9', 'LT P79 RId Code: A-1');
        Observer.Expect('default', 'LT P79 RId Code: A-1');
        Observer.Verify();
    end;

    [Test]
    procedure IntKey_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        RI: Record "LT P79 RId Int";
        i: Integer;
    begin
        RI.DeleteAll();
        RI.No := 1234567;
        RI.Insert();
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(RI.RecordId, i));
        Observer.Observe('default', Format(RI.RecordId));
        Observer.Expect('n0', 'LT P79 RId Int: 1234567');
        Observer.Expect('n1', 'LT P79 RId Int: 1234567');
        Observer.Expect('n2', 'LT P79 RId Int: 1234567');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n9', 'LT P79 RId Int: 1234567');
        Observer.Expect('default', 'LT P79 RId Int: 1234567');
        Observer.Verify();
    end;

    [Test]
    procedure DateKey_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        RD: Record "LT P79 RId Date";
        i: Integer;
    begin
        RD.DeleteAll();
        RD.D := DMY2Date(5, 3, 2021);
        RD.Insert();
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(RD.RecordId, i));
        Observer.Observe('default', Format(RD.RecordId));
        Observer.Expect('n0', 'LT P79 RId Date: 03/05/21');
        Observer.Expect('n1', 'LT P79 RId Date: 03/05/21');
        Observer.Expect('n2', 'LT P79 RId Date: 030521D');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n9', 'LT P79 RId Date: 2021-03-05');
        Observer.Expect('default', 'LT P79 RId Date: 03/05/21');
        Observer.Verify();
    end;

    [Test]
    procedure GuidKey_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        RG: Record "LT P79 RId Guid";
        i: Integer;
    begin
        RG.DeleteAll();
        Evaluate(RG.G, '{12345678-1234-1234-1234-123456789ABC}');
        RG.Insert();
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(RG.RecordId, i));
        Observer.Observe('default', Format(RG.RecordId));
        Observer.Expect('n0', 'LT P79 RId Guid: {12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('n1', 'LT P79 RId Guid: {12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('n2', 'LT P79 RId Guid: {12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n9', 'LT P79 RId Guid: {12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('default', 'LT P79 RId Guid: {12345678-1234-1234-1234-123456789ABC}');
        Observer.Verify();
    end;

    [Test]
    procedure CompositeKey_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        RP: Record "LT P79 RId Comp";
        i: Integer;
    begin
        RP.DeleteAll();
        RP.C := 'K,1';
        RP.N := -5;
        RP.D := DMY2Date(31, 12, 2020);
        RP.T := 'ignored';
        RP.Insert();
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(RP.RecordId, i));
        Observer.Observe('default', Format(RP.RecordId));
        Observer.Expect('n0', 'LT P79 RId Comp: "K,1",-5,12/31/20');
        Observer.Expect('n1', 'LT P79 RId Comp: "K,1",-5,12/31/20');
        Observer.Expect('n2', 'LT P79 RId Comp: "K,1",-5,123120D');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''RecordID''.|InvalidStandardFormat');
        Observer.Expect('n9', 'LT P79 RId Comp: "K,1",-5,2020-12-31');
        Observer.Expect('default', 'LT P79 RId Comp: "K,1",-5,12/31/20');
        Observer.Verify();
    end;

    [Test]
    procedure CompositeKey_SpecialCharacters()
    var
        Observer: Codeunit "Probe Observer";
        RP: Record "LT P79 RId Comp";
        RC: Record "LT P79 RId Code";
    begin
        RP.DeleteAll();
        RC.DeleteAll();
        RP.C := 'A"B';
        RP.N := 0;
        RP.Insert();
        Observer.Observe('quote', Format(RP.RecordId));
        RP.C := 'A,B';
        RP.N := 1;
        RP.Insert();
        Observer.Observe('comma', Format(RP.RecordId));
        RP.C := 'A: B';
        RP.N := 2;
        RP.Insert();
        Observer.Observe('colon', Format(RP.RecordId));
        RP.C := '';
        RP.N := 3;
        RP.Insert();
        Observer.Observe('blank-code', Format(RP.RecordId));
        RC.Code := 'ÄÖü';
        RC.Insert();
        Observer.Observe('unicode', Format(RC.RecordId));
        RC.Code := 'a b';
        RC.Insert();
        Observer.Observe('space', Format(RC.RecordId));
        Observer.Expect('quote', 'LT P79 RId Comp: A"B,0,""');
        Observer.Expect('comma', 'LT P79 RId Comp: "A,B",1,""');
        Observer.Expect('colon', 'LT P79 RId Comp: A: B,2,""');
        Observer.Expect('blank-code', 'LT P79 RId Comp: "",3,""');
        Observer.Expect('unicode', 'LT P79 RId Code: ÄÖÜ');
        Observer.Expect('space', 'LT P79 RId Code: A B');
        Observer.Verify();
    end;

    [Test]
    procedure CustomFormatStrings()
    var
        Observer: Codeunit "Probe Observer";
        RC: Record "LT P79 RId Code";
    begin
        RC.DeleteAll();
        RC.Code := 'A-1';
        RC.Insert();
        Observer.Observe('x', FC(RC.RecordId, 'X'));
        Observer.Observe('empty', FC(RC.RecordId, ''));
        Observer.Observe('std0', FC(RC.RecordId, '<Standard Format,0>'));
        Observer.Observe('std1', FC(RC.RecordId, '<Standard Format,1>'));
        Observer.Observe('std2', FC(RC.RecordId, '<Standard Format,2>'));
        Observer.Observe('std9', FC(RC.RecordId, '<Standard Format,9>'));
        Observer.Observe('text', FC(RC.RecordId, '<Text>'));
        Observer.Observe('text-mixed', FC(RC.RecordId, 'ID: <Standard Format,0>!'));
        Observer.Observe('at', FC(RC.RecordId, '@@@@@@@@@@'));
        Observer.Observe('len-5', Format(RC.RecordId, 5));
        Observer.Observe('len-30', Format(RC.RecordId, 30));
        Observer.Observe('len-neg-5', Format(RC.RecordId, -5));
        Observer.Expect('x', 'X');
        Observer.Expect('empty', '');
        Observer.Expect('std0', 'LT P79 RId Code: A-1');
        Observer.Expect('std1', 'LT P79 RId Code: A-1');
        Observer.Expect('std2', 'LT P79 RId Code: A-1');
        Observer.Expect('std9', 'LT P79 RId Code: A-1');
        Observer.Expect('text', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Text>|InvalidFormatString');
        Observer.Expect('text-mixed', 'ID: LT P79 RId Code: A-1!');
        Observer.Expect('at', '@@@@@@@@@@');
        Observer.Expect('len-5', 'LT P7');
        Observer.Expect('len-30', 'LT P79 RId Code: A-1          ');
        Observer.Expect('len-neg-5', 'LT P7');
        Observer.Verify();
    end;
}

codeunit 73967 "LT P79 RId Blank Temp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure NeverRead_BlankRecordId()
    var
        Observer: Codeunit "Probe Observer";
        RC: Record "LT P79 RId Code";
        RI: Record "LT P79 RId Int";
        RP: Record "LT P79 RId Comp";
        RG: Record "LT P79 RId Guid";
        RD: Record "LT P79 RId Date";
        RId: RecordId;
    begin
        RC.DeleteAll();
        Observer.Observe('uninit-var', Format(RId));
        Observer.Observe('uninit-var-len', Format(StrLen(Format(RId))));
        Observer.Observe('uninit-tableno', Format(RId.TableNo()));
        Observer.Observe('code-blank', Format(RC.RecordId));
        Observer.Observe('int-blank', Format(RI.RecordId));
        Observer.Observe('comp-blank', Format(RP.RecordId));
        Observer.Observe('guid-blank', Format(RG.RecordId));
        Observer.Observe('date-blank', Format(RD.RecordId));
        Observer.Observe('code-blank-subst', StrSubstNo('(%1)', RC.RecordId));
        Observer.Observe('code-blank-tableno', Format(RC.RecordId.TableNo()));
        Observer.Observe('code-blank-eq-var', Format(RC.RecordId = RId));
        Observer.Expect('uninit-var', '');
        Observer.Expect('uninit-var-len', '0');
        Observer.Expect('uninit-tableno', '0');
        Observer.Expect('code-blank', 'LT P79 RId Code: ""');
        Observer.Expect('int-blank', 'LT P79 RId Int: 0');
        Observer.Expect('comp-blank', 'LT P79 RId Comp: "",0,""');
        Observer.Expect('guid-blank', 'LT P79 RId Guid: {00000000-0000-0000-0000-000000000000}');
        Observer.Expect('date-blank', 'LT P79 RId Date: ""');
        Observer.Expect('code-blank-subst', '(LT P79 RId Code: "")');
        Observer.Expect('code-blank-tableno', '73960');
        Observer.Expect('code-blank-eq-var', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure NeverRead_InError()
    var
        Observer: Codeunit "Probe Observer";
        RC: Record "LT P79 RId Code";
        RId: RecordId;
    begin
        asserterror Error('%1', RC.RecordId);
        Observer.ObserveError('blank-rec');
        asserterror Error('%1', RId);
        Observer.ObserveError('blank-var');
        asserterror Error('[%1]', RC.RecordId);
        Observer.ObserveError('blank-rec-bracket');
        Observer.Expect('blank-rec|text', 'LT P79 RId Code: ""');
        Observer.Expect('blank-rec|code', 'Dialog');
        Observer.Expect('blank-var|text', '');
        Observer.Expect('blank-var|code', 'Dialog');
        Observer.Expect('blank-rec-bracket|text', '[LT P79 RId Code: ""]');
        Observer.Expect('blank-rec-bracket|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Temporary_RecordId()
    var
        Observer: Codeunit "Probe Observer";
        Tmp: Record "LT P79 RId Code" temporary;
        TmpComp: Record "LT P79 RId Comp" temporary;
        Real: Record "LT P79 RId Code";
    begin
        Real.DeleteAll();
        Tmp.Code := 'T-1';
        Tmp.Insert();
        Observer.Observe('temp', Format(Tmp.RecordId));
        Observer.Observe('temp-n1', Format(Tmp.RecordId, 0, 1));
        Observer.Observe('temp-n9', Format(Tmp.RecordId, 0, 9));
        Real.Code := 'T-1';
        Real.Insert();
        Observer.Observe('real', Format(Real.RecordId));
        Observer.Observe('equal', Format(Tmp.RecordId = Real.RecordId));
        TmpComp.C := 'X';
        TmpComp.N := 9;
        TmpComp.D := DMY2Date(1, 1, 2000);
        TmpComp.Insert();
        Observer.Observe('temp-comp', Format(TmpComp.RecordId));
        asserterror Error('%1', Tmp.RecordId);
        Observer.ObserveError('temp-in-error');
        Observer.Observe('temp-subst', StrSubstNo('<%1>', Tmp.RecordId));
        Observer.Expect('temp', 'LT P79 RId Code: T-1');
        Observer.Expect('temp-n1', 'LT P79 RId Code: T-1');
        Observer.Expect('temp-n9', 'LT P79 RId Code: T-1');
        Observer.Expect('real', 'LT P79 RId Code: T-1');
        Observer.Expect('equal', 'Yes');
        Observer.Expect('temp-comp', 'LT P79 RId Comp: X,9,01/01/00');
        Observer.Expect('temp-in-error|text', 'LT P79 RId Code: T-1');
        Observer.Expect('temp-in-error|code', 'Dialog');
        Observer.Expect('temp-subst', '<LT P79 RId Code: T-1>');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_RecordId()
    var
        Observer: Codeunit "Probe Observer";
        RC: Record "LT P79 RId Code";
        RecRef: RecordRef;
    begin
        RC.DeleteAll();
        RecRef.Open(Database::"LT P79 RId Code");
        Observer.Observe('open-blank', Format(RecRef.RecordId));
        Observer.Observe('open-blank-subst', StrSubstNo('%1', RecRef.RecordId));
        RC.Code := 'R-1';
        RC.Insert();
        RecRef.GetTable(RC);
        Observer.Observe('gettable', Format(RecRef.RecordId));
        Observer.Observe('same-as-rec', Format(RecRef.RecordId = RC.RecordId));
        RecRef.Close();
        Observer.Expect('open-blank', 'LT P79 RId Code: ""');
        Observer.Expect('open-blank-subst', 'LT P79 RId Code: ""');
        Observer.Expect('gettable', 'LT P79 RId Code: R-1');
        Observer.Expect('same-as-rec', 'Yes');
        Observer.Verify();
    end;
}

codeunit 73968 "LT P79 RId In Messages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RecordId_InLongerTexts()
    var
        Observer: Codeunit "Probe Observer";
        RP: Record "LT P79 RId Comp";
        RG: Record "LT P79 RId Guid";
        RD: Record "LT P79 RId Date";
    begin
        RP.DeleteAll();
        RG.DeleteAll();
        RD.DeleteAll();
        RP.C := 'ABC';
        RP.N := 10;
        RP.D := DMY2Date(2, 2, 2022);
        RP.Insert();
        Evaluate(RG.G, '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        RG.Insert();
        RD.D := DMY2Date(15, 6, 2023);
        RD.Insert();
        Observer.Observe('comp-in-text', 'Failed for ' + Format(RP.RecordId) + ' today');
        Observer.Observe('comp-subst-3', StrSubstNo('%1 / %2 / %3', RP.RecordId, RG.RecordId, RD.RecordId));
        Observer.Observe('comp-subst-width', StrSubstNo('%1', Format(RP.RecordId, 20)));
        asserterror Error('Failed for %1 (%2)', RP.RecordId, RP.N);
        Observer.ObserveError('comp-error');
        asserterror Error('Guid %1', RG.RecordId);
        Observer.ObserveError('guid-error');
        asserterror Error('Date %1', RD.RecordId);
        Observer.ObserveError('date-error');
        asserterror Error(StrSubstNo('Wrapped %1', RP.RecordId));
        Observer.ObserveError('wrapped');
        Observer.Observe('long-lengths', Format(StrLen(Format(RP.RecordId))) + '/' + Format(StrLen(Format(RG.RecordId))) + '/' + Format(StrLen(Format(RD.RecordId))));
        RP.DeleteAll();
        RG.DeleteAll();
        RD.DeleteAll();
        Observer.Expect('comp-in-text', 'Failed for LT P79 RId Comp: ABC,10,02/02/22 today');
        Observer.Expect('comp-subst-3', 'LT P79 RId Comp: ABC,10,02/02/22 / LT P79 RId Guid: {AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE} / LT P79 RId Date: 06/15/23');
        Observer.Expect('comp-subst-width', 'LT P79 RId Comp: ABC');
        Observer.Expect('comp-error|text', 'Failed for LT P79 RId Comp: ABC,10,02/02/22 (10)');
        Observer.Expect('comp-error|code', 'Dialog');
        Observer.Expect('guid-error|text', 'Guid LT P79 RId Guid: {AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}');
        Observer.Expect('guid-error|code', 'Dialog');
        Observer.Expect('date-error|text', 'Date LT P79 RId Date: 06/15/23');
        Observer.Expect('date-error|code', 'Dialog');
        Observer.Expect('wrapped|text', 'Wrapped LT P79 RId Comp: ABC,10,02/02/22');
        Observer.Expect('wrapped|code', 'Dialog');
        Observer.Expect('long-lengths', '32/55/25');
        Observer.Verify();
    end;

    [Test]
    procedure RecordId_Comparison()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT P79 RId Code";
        B: Record "LT P79 RId Code";
        I: Record "LT P79 RId Int";
    begin
        A.DeleteAll();
        A.Code := 'A';
        A.Insert();
        B.Code := 'B';
        B.Insert();
        I.DeleteAll();
        I.No := 1;
        I.Insert();
        Observer.Observe('eq-self', Format(A.RecordId = A.RecordId));
        Observer.Observe('eq-other', Format(A.RecordId = B.RecordId));
        Observer.Observe('ne', Format(A.RecordId <> B.RecordId));
        Observer.Observe('diff-tables', Format(A.RecordId = I.RecordId));
        A.DeleteAll();
        I.DeleteAll();
        Observer.Expect('eq-self', 'Yes');
        Observer.Expect('eq-other', 'No');
        Observer.Expect('ne', 'Yes');
        Observer.Expect('diff-tables', 'No');
        Observer.Verify();
    end;
}
