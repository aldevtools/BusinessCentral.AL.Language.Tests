// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-data-type
// Scope: in-scope
// Fixtures used: tables 73000, 73001, enum 73000 (RfTObjects.al), codeunit 73010 (RfTHelpers.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// FieldRef Value get and set for every field type, unassigned FieldRef, wrong types and truncation.
// Writer QP (al-runtime-rs asks): QP_Blob_* read a Blob field (13) of a stored row without CalcFields (Get + RecordRef.GetTable, and
//   RecordRef.Open + FindFirst), assign FieldRef.Value to the Blob field of a temporary record and read HasValue, Length and the text;
//   then FieldRef.CalcField and the same again. QP_DateFormula_* Evaluate the formulas <1M+CM>, 10D, <-1Y> and CW into the DateFormula
//   field (15) of a stored row, Modify, and read it back with Format(Field), Format(Field, 0, 9), FieldRef.Value and after Get on a new
//   record variable (the stored form of a DateFormula as AL code sees it).
// BC versions: 29 (27 and 28 by CI)

codeunit 73024 "LT RfT Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure OpenRow(var RecRef: RecordRef)
    var
        Helper: Codeunit "LT RfT Helper";
    begin
        Helper.Reset();
        RecRef.Open(73001);
        RecRef.Init();
        RecRef.Field(1).Value := 'V1';
    end;

    [Test]
    procedure Value_Get_Defaults()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Num: Integer;
        NumTxt: Text;
    begin
        OpenRow(RecRef);
        foreach NumTxt in '1,2,3,4,5,6,7,8,9,10,11,12,14,15,16,17,18,19,20'.Split(',') do begin
            Evaluate(Num, NumTxt);
            Observer.Observe('default' + NumTxt, Format(RecRef.Field(Num).Value));
        end;
        Observer.Expect('default1', 'V1');
        Observer.Expect('default2', '');
        Observer.Expect('default3', '0');
        Observer.Expect('default4', '0');
        Observer.Expect('default5', 'No');
        Observer.Expect('default6', '');
        Observer.Expect('default7', '');
        Observer.Expect('default8', '');
        Observer.Expect('default9', 'Erste');
        Observer.Expect('default10', 'Red');
        Observer.Expect('default11', '0');
        Observer.Expect('default12', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('default14', '');
        Observer.Expect('default15', '');
        Observer.Expect('default16', '');
        Observer.Expect('default17', '');
        Observer.Expect('default18', '0');
        Observer.Expect('default19', '');
        Observer.Expect('default20', '');
        Observer.Verify();
    end;

    [Test]
    procedure Value_Set_And_Get_Types()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        OpenRow(RecRef);
        RecRef.Field(2).Value := 'hello';
        RecRef.Field(3).Value := 42;
        RecRef.Field(4).Value := 3.14159;
        RecRef.Field(5).Value := true;
        RecRef.Field(6).Value := DMY2Date(15, 3, 2021);
        RecRef.Field(7).Value := 123456T;
        RecRef.Field(8).Value := CreateDateTime(DMY2Date(1, 2, 2020), 101500T);
        RecRef.Field(9).Value := 2;
        RecRef.Field(10).Value := Enum::"LT RfT Color"::Blue;
        RecRef.Field(11).Value := 9876543210L;
        RecRef.Field(14).Value := 3600000;
        RecRef.Field(16).Value := 'code50';
        Observer.Observe('txt', Format(RecRef.Field(2).Value));
        Observer.Observe('int', Format(RecRef.Field(3).Value));
        Observer.Observe('dec', Format(RecRef.Field(4).Value));
        Observer.Observe('bool', Format(RecRef.Field(5).Value));
        Observer.Observe('date', Format(RecRef.Field(6).Value, 0, 9));
        Observer.Observe('time', Format(RecRef.Field(7).Value, 0, 9));
        Observer.Observe('datetime', Format(RecRef.Field(8).Value, 0, 9));
        Observer.Observe('opt', Format(RecRef.Field(9).Value));
        Observer.Observe('opt_int', Format(RecRef.Field(9).Value, 0, 2));
        Observer.Observe('enum', Format(RecRef.Field(10).Value));
        Observer.Observe('enum_int', Format(RecRef.Field(10).Value, 0, 2));
        Observer.Observe('big', Format(RecRef.Field(11).Value));
        Observer.Observe('dur', Format(RecRef.Field(14).Value));
        Observer.Observe('code50', Format(RecRef.Field(16).Value));
        Fld := RecRef.Field(3);
        Observer.Observe('int_as_decimal', Format(Fld.Value));
        Observer.Expect('txt', 'hello');
        Observer.Expect('int', '42');
        Observer.Expect('dec', '3.14159');
        Observer.Expect('bool', 'Yes');
        Observer.Expect('date', '2021-03-15');
        Observer.Expect('time', '12:34:56');
        Observer.Expect('datetime', '2020-02-01T10:15:00Z');
        Observer.Expect('opt', 'Dritte');
        Observer.Expect('opt_int', '2');
        Observer.Expect('enum', 'Blue Caption');
        Observer.Expect('enum_int', '5');
        Observer.Expect('big', '9876543210');
        Observer.Expect('dur', '1 hour');
        Observer.Expect('code50', 'CODE50');
        Observer.Expect('int_as_decimal', '42');
        Observer.Verify();
    end;

    [Test]
    procedure Value_Truncation_And_Length()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
        Long: Text;
    begin
        OpenRow(RecRef);
        Long := '123456789012345678901234567890XYZ';
        Fld := RecRef.Field(2);
        asserterror Fld.Value := Long;
        Observer.ObserveError('text30_too_long');
        Fld.Value := CopyStr(Long, 1, 30);
        Observer.Observe('text30_exact', Format(Fld.Value));
        Fld := RecRef.Field(1);
        asserterror Fld.Value := Long;
        Observer.ObserveError('code20_too_long');
        Fld.Value := 'lower';
        Observer.Observe('code_case', Format(Fld.Value));
        Observer.Observe('code_length', Format(StrLen(Format(Fld.Value))));
        Fld := RecRef.Field(20);
        Fld.Value := PadStr('', 250, 'a');
        Observer.Observe('text250_len', Format(StrLen(Format(Fld.Value))));
        asserterror Fld.Value := PadStr('', 251, 'a');
        Observer.ObserveError('text250_over');
        Observer.Expect('text30_too_long|text', 'The length of the string is 33, but it must be less than or equal to 30 characters. Value: 123456789012345678901234567890XYZ');
        Observer.Expect('text30_too_long|code', 'StringLengthExceeded');
        Observer.Expect('text30_exact', '123456789012345678901234567890');
        Observer.Expect('code20_too_long|text', 'The length of the string is 33, but it must be less than or equal to 20 characters. Value: 123456789012345678901234567890XYZ');
        Observer.Expect('code20_too_long|code', 'StringLengthExceeded');
        Observer.Expect('code_case', 'LOWER');
        Observer.Expect('code_length', '5');
        Observer.Expect('text250_len', '250');
        Observer.Expect('text250_over|text', 'The length of the string is 251, but it must be less than or equal to 250 characters. Value: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa...');
        Observer.Expect('text250_over|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure Value_Rounding_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        OpenRow(RecRef);
        Fld := RecRef.Field(4);
        Fld.Value := 1.23456789;
        Observer.Observe('stored_precision', Format(Fld.Value, 0, 9));
        RecRef.Insert();
        RecRef.Get(RecRef.RecordId());
        Observer.Observe('after_reload', Format(RecRef.Field(4).Value, 0, 9));
        Observer.Observe('formatted', Format(RecRef.Field(4).Value));
        Fld.Value := -0.5;
        Observer.Observe('negative', Format(Fld.Value));
        Fld.Value := 0;
        Observer.Observe('zero', Format(Fld.Value));
        Observer.Expect('stored_precision', '1.23456789');
        Observer.Expect('after_reload', '1.23456789');
        Observer.Expect('formatted', '1.23456789');
        Observer.Expect('negative', '-0.5');
        Observer.Expect('zero', '0');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure Value_Blob_Cases()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
        Rec: Record "LT RfT Data";
        InS: InStream;
        OutS: OutStream;
        Content: Text;
    begin
        OpenRow(RecRef);
        Fld := RecRef.Field(13);
        Observer.Observe('type', Format(Fld.Type()));
        Observer.Observe('class', Format(Fld.Class()));
        Observer.Observe('format_empty', Format(Fld.Value));
        RecRef.Insert();
        Rec.Get('V1');
        Rec.Bl.CreateOutStream(OutS);
        OutS.WriteText('blob content');
        Rec.Modify();
        Clear(RecRef);
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(13);
        Observer.Observe('hasvalue_before', Format(Rec.Bl.HasValue()));
        Fld.CalcField();
        Observer.Observe('calcfield_blob', 'ok');
        Observer.Observe('format_value', Format(Fld.Value));
        asserterror Fld.Value := 'x';
        Observer.Observe('set_blob_text|raised', Format(GetLastErrorText() <> ''));
        ClearLastError();
        Observer.Expect('type', 'BLOB');
        Observer.Expect('class', 'Normal');
        Observer.Expect('format_empty', ' ');
        Observer.Expect('hasvalue_before', 'Yes');
        Observer.Expect('calcfield_blob', 'ok');
        Observer.Expect('format_value', '*');
        Observer.Expect('set_blob_text|raised', 'Yes');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure Value_Guid_RecordId_DateFormula()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
        G: Guid;
        DF: DateFormula;
        Rec: Record "LT RfT Data";
    begin
        OpenRow(RecRef);
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        Fld := RecRef.Field(12);
        Fld.Value := G;
        Observer.Observe('guid', Format(Fld.Value));
        Fld.Value := '{AAAAAAAA-2222-3333-4444-555555555555}';
        Observer.Observe('guid_from_text', Format(Fld.Value));
        Evaluate(DF, '<1M+CM>');
        Fld := RecRef.Field(15);
        Fld.Value := DF;
        Observer.Observe('dateformula', Format(Fld.Value));
        Fld := RecRef.Field(19);
        Rec.Code := 'V1';
        Fld.Value := Rec.RecordId();
        Observer.Observe('recordid', Format(Fld.Value));
        Observer.Observe('recordid_type', Format(Fld.Type()));
        Observer.Expect('guid', '{11111111-2222-3333-4444-555555555555}');
        Observer.Expect('guid_from_text', '{AAAAAAAA-2222-3333-4444-555555555555}');
        Observer.Expect('dateformula', '1M+CM');
        Observer.Expect('recordid', 'LT RfT Data: V1');
        Observer.Expect('recordid_type', 'RecordID');
        Observer.Verify();
    end;

    [Test]
    procedure Value_Unassigned_FieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Fld: FieldRef;
        Txt: Text;
        Num: Integer;
        B: Boolean;
    begin
        asserterror Txt := Format(Fld.Value);
        Observer.ObserveError('value');
        asserterror Fld.Value := 1;
        Observer.ObserveError('set_value');
        asserterror Txt := Fld.Name();
        Observer.ObserveError('name');
        asserterror Txt := Fld.Caption();
        Observer.ObserveError('caption');
        asserterror Num := Fld.Number();
        Observer.ObserveError('number');
        asserterror Txt := Format(Fld.Type());
        Observer.ObserveError('type');
        asserterror Num := Fld.Length();
        Observer.ObserveError('length');
        asserterror Txt := Format(Fld.Class());
        Observer.ObserveError('class');
        asserterror B := Fld.Active();
        Observer.ObserveError('active');
        asserterror B := Fld.IsEnum();
        Observer.ObserveError('isenum');
        asserterror Txt := Fld.GetFilter();
        Observer.ObserveError('getfilter');
        asserterror Fld.SetRange(1);
        Observer.ObserveError('setrange');
        asserterror Fld.SetFilter('1');
        Observer.ObserveError('setfilter');
        asserterror Fld.Validate(1);
        Observer.ObserveError('validate');
        asserterror Fld.TestField();
        Observer.ObserveError('testfield');
        asserterror Fld.FieldError();
        Observer.ObserveError('fielderror');
        asserterror Fld.CalcField();
        Observer.ObserveError('calcfield');
        asserterror Txt := Fld.OptionMembers();
        Observer.ObserveError('optionmembers');
        asserterror Txt := Fld.OptionCaption();
        Observer.ObserveError('optioncaption');
        asserterror Num := Fld.EnumValueCount();
        Observer.ObserveError('enumvaluecount');
        asserterror Txt := Fld.GetEnumValueName(1);
        Observer.ObserveError('enumvaluename');
        asserterror Num := Fld.Relation();
        Observer.ObserveError('relation');
        Observer.Expect('value|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('value|code', 'NotInitialized');
        Observer.Expect('set_value|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('set_value|code', 'NotInitialized');
        Observer.Expect('name|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('name|code', 'NotInitialized');
        Observer.Expect('caption|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('caption|code', 'NotInitialized');
        Observer.Expect('number|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('number|code', 'NotInitialized');
        Observer.Expect('type|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('type|code', 'NotInitialized');
        Observer.Expect('length|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('length|code', 'NotInitialized');
        Observer.Expect('class|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('class|code', 'NotInitialized');
        Observer.Expect('active|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('active|code', 'NotInitialized');
        Observer.Expect('isenum|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('isenum|code', 'NotInitialized');
        Observer.Expect('getfilter|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('getfilter|code', 'NotInitialized');
        Observer.Expect('setrange|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('setrange|code', 'NotInitialized');
        Observer.Expect('setfilter|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('setfilter|code', 'NotInitialized');
        Observer.Expect('validate|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('validate|code', 'NotInitialized');
        Observer.Expect('testfield|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('testfield|code', 'NotInitialized');
        Observer.Expect('fielderror|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('fielderror|code', 'NotInitialized');
        Observer.Expect('calcfield|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('calcfield|code', 'NotInitialized');
        Observer.Expect('optionmembers|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('optionmembers|code', 'NotInitialized');
        Observer.Expect('optioncaption|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('optioncaption|code', 'NotInitialized');
        Observer.Expect('enumvaluecount|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('enumvaluecount|code', 'NotInitialized');
        Observer.Expect('enumvaluename|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('enumvaluename|code', 'NotInitialized');
        Observer.Expect('relation|text', 'Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.');
        Observer.Expect('relation|code', 'NotInitialized');
        Observer.Verify();
    end;





    [Test]
    procedure FieldRef_Assignment_Aliasing()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
        Fld2: FieldRef;
    begin
        OpenRow(RecRef);
        Fld := RecRef.Field(2);
        Fld2 := Fld;
        Fld2.Value := 'via copy';
        Observer.Observe('original_sees', Format(Fld.Value));
        Observer.Observe('same_number', Format(Fld2.Number()));
        Fld2 := RecRef.Field(3);
        Observer.Observe('reassigned', Fld2.Name());
        Observer.Observe('first_unchanged', Fld.Name());
        Observer.Expect('original_sees', 'via copy');
        Observer.Expect('same_number', '2');
        Observer.Expect('reassigned', 'Int');
        Observer.Expect('first_unchanged', 'Txt');
        Observer.Verify();
    end;

    local procedure QP_StoreBlob(Content: Text)
    var
        Helper: Codeunit "LT RfT Helper";
        Row: Record "LT RfT Data";
        Out: OutStream;
    begin
        Helper.Reset();
        Row.Init();
        Row.Code := 'B1';
        Row.Insert();
        Row.Bl.CreateOutStream(Out);
        Out.WriteText(Content);
        Row.Modify();
    end;

    local procedure QP_BlobFacts(var Observer: Codeunit "Probe Observer"; Prefix: Text; var Fld: FieldRef)
    var
        Tmp: Record "LT RfT Data" temporary;
        Ins: InStream;
        T: Text;
    begin
        Tmp.Bl := Fld.Value;
        Observer.Observe(Prefix + '_hasvalue', Format(Tmp.Bl.HasValue()));
        Observer.Observe(Prefix + '_length', Format(Tmp.Bl.Length()));
        Tmp.Bl.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe(Prefix + '_text', T);
    end;

    [Test]
    procedure QP_Blob_GetTable_ValueWithoutCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RfT Data";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        QP_StoreBlob('blob text');
        Row.Get('B1');
        RecRef.GetTable(Row);
        Fld := RecRef.Field(13);
        QP_BlobFacts(Observer, 'before', Fld);
        Observer.Observe('calcfield', Format(Fld.CalcField()));
        QP_BlobFacts(Observer, 'after', Fld);
        Observer.Expect('before_hasvalue', 'No');
        Observer.Expect('before_length', '0');
        Observer.Expect('before_text', '');
        Observer.Expect('calcfield', 'Yes');
        Observer.Expect('after_hasvalue', 'Yes');
        Observer.Expect('after_length', '9');
        Observer.Expect('after_text', 'blob text');
        Observer.Verify();
    end;

    [Test]
    procedure QP_Blob_OpenFind_ValueWithoutCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        QP_StoreBlob('blob text');
        RecRef.Open(Database::"LT RfT Data");
        RecRef.FindFirst();
        Fld := RecRef.Field(13);
        QP_BlobFacts(Observer, 'before', Fld);
        Fld.CalcField();
        QP_BlobFacts(Observer, 'after', Fld);
        Observer.Expect('before_hasvalue', 'No');
        Observer.Expect('before_length', '0');
        Observer.Expect('before_text', '');
        Observer.Expect('after_hasvalue', 'Yes');
        Observer.Expect('after_length', '9');
        Observer.Expect('after_text', 'blob text');
        Observer.Verify();
    end;

    [Test]
    procedure QP_Blob_GetTable_EmptyBlob()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        Row: Record "LT RfT Data";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Reset();
        Row.Init();
        Row.Code := 'B1';
        Row.Insert();
        Clear(Row);
        Row.Get('B1');
        RecRef.GetTable(Row);
        Fld := RecRef.Field(13);
        QP_BlobFacts(Observer, 'before', Fld);
        Fld.CalcField();
        QP_BlobFacts(Observer, 'after', Fld);
        Observer.Expect('before_hasvalue', 'No');
        Observer.Expect('before_length', '0');
        Observer.Expect('before_text', '');
        Observer.Expect('after_hasvalue', 'No');
        Observer.Expect('after_length', '0');
        Observer.Expect('after_text', '');
        Observer.Verify();
    end;

    local procedure QP_DateFormulaFacts(var Observer: Codeunit "Probe Observer"; Name: Text; Formula: Text)
    var
        Helper: Codeunit "LT RfT Helper";
        Row: Record "LT RfT Data";
        Back: Record "LT RfT Data";
        RecRef: RecordRef;
    begin
        Helper.Reset();
        Row.Init();
        Row.Code := 'D1';
        Row.Insert();
        Observer.Observe(Name + '_evaluate', Format(Evaluate(Row.DF, Formula)));
        Row.Modify();
        Observer.Observe(Name + '_format', Format(Row.DF));
        Observer.Observe(Name + '_format9', Format(Row.DF, 0, 9));
        RecRef.GetTable(Row);
        Observer.Observe(Name + '_fieldref', Format(RecRef.Field(15).Value));
        Back.Get('D1');
        Observer.Observe(Name + '_get_format', Format(Back.DF));
        Observer.Observe(Name + '_get_format9', Format(Back.DF, 0, 9));
        Observer.Observe(Name + '_get_calcdate', Format(CalcDate(Back.DF, 20240115D), 0, 9));
        RecRef.Close();
        RecRef.Open(Database::"LT RfT Data");
        RecRef.FindFirst();
        Observer.Observe(Name + '_open_fieldref', Format(RecRef.Field(15).Value));
        Observer.Observe(Name + '_open_fieldref9', Format(RecRef.Field(15).Value, 0, 9));
    end;

    [Test]
    procedure QP_DateFormula_MonthPlusCurrentMonth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QP_DateFormulaFacts(Observer, 'm', '<1M+CM>');
        Observer.Expect('m_evaluate', 'Yes');
        Observer.Expect('m_format', '1M+CM');
        Observer.Expect('m_format9', '1M+CM');
        Observer.Expect('m_fieldref', '1M+CM');
        Observer.Expect('m_get_format', '1M+CM');
        Observer.Expect('m_get_format9', '1M+CM');
        Observer.Expect('m_get_calcdate', '2024-02-29');
        Observer.Expect('m_open_fieldref', '1M+CM');
        Observer.Expect('m_open_fieldref9', '1M+CM');
        Observer.Verify();
    end;

    [Test]
    procedure QP_DateFormula_TenDaysNoBrackets()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QP_DateFormulaFacts(Observer, 'd', '10D');
        Observer.Expect('d_evaluate', 'Yes');
        Observer.Expect('d_format', '10D');
        Observer.Expect('d_format9', '10D');
        Observer.Expect('d_fieldref', '10D');
        Observer.Expect('d_get_format', '10D');
        Observer.Expect('d_get_format9', '10D');
        Observer.Expect('d_get_calcdate', '2024-01-25');
        Observer.Expect('d_open_fieldref', '10D');
        Observer.Expect('d_open_fieldref9', '10D');
        Observer.Verify();
    end;

    [Test]
    procedure QP_DateFormula_MinusOneYear()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QP_DateFormulaFacts(Observer, 'y', '<-1Y>');
        Observer.Expect('y_evaluate', 'Yes');
        Observer.Expect('y_format', '-1Y');
        Observer.Expect('y_format9', '-1Y');
        Observer.Expect('y_fieldref', '-1Y');
        Observer.Expect('y_get_format', '-1Y');
        Observer.Expect('y_get_format9', '-1Y');
        Observer.Expect('y_get_calcdate', '2023-01-15');
        Observer.Expect('y_open_fieldref', '-1Y');
        Observer.Expect('y_open_fieldref9', '-1Y');
        Observer.Verify();
    end;

    [Test]
    procedure QP_DateFormula_CurrentWeekNoBrackets()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QP_DateFormulaFacts(Observer, 'cw', 'CW');
        Observer.Expect('cw_evaluate', 'Yes');
        Observer.Expect('cw_format', 'CW');
        Observer.Expect('cw_format9', 'CW');
        Observer.Expect('cw_fieldref', 'CW');
        Observer.Expect('cw_get_format', 'CW');
        Observer.Expect('cw_get_format9', 'CW');
        Observer.Expect('cw_get_calcdate', '2024-01-21');
        Observer.Expect('cw_open_fieldref', 'CW');
        Observer.Expect('cw_open_fieldref9', 'CW');
        Observer.Verify();
    end;
}
