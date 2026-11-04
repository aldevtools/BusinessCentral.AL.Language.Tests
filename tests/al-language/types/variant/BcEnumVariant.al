// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in BcEnumObjects.al
// Corpus issue 659 item 1 (from al-runtime-rs #250): Library Assert.AreEqual(Kind::Normal, TempLine."Enum Field") passes on BC 29. Library Assert's
// TypeOf decides with Variant.IsBoolean, IsOption or IsInteger or IsByte, IsBigInteger, IsDecimal, IsText/IsCode/IsChar/IsTextConstant, IsDate,
// IsTime, IsDuration, IsDateTime, IsDateFormula, IsGuid, IsRecordId (else error 'Unsupported Type'), and Equal compares TypeOf and Format(V, 0, 2).
// The corpus app does not depend on Library Assert, so these tests assert those primitives on enum values and enum fields.

codeunit 80954 "BC Enum Variant Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsBoolean() then
            R += 'Boolean,';
        if V.IsOption() then
            R += 'Option,';
        if V.IsInteger() then
            R += 'Integer,';
        if V.IsByte() then
            R += 'Byte,';
        if V.IsBigInteger() then
            R += 'BigInteger,';
        if V.IsDecimal() then
            R += 'Decimal,';
        if V.IsText() then
            R += 'Text,';
        if V.IsCode() then
            R += 'Code,';
        if V.IsChar() then
            R += 'Char,';
        if V.IsTextConstant() then
            R += 'TextConstant,';
        if V.IsDate() then
            R += 'Date,';
        if V.IsTime() then
            R += 'Time,';
        if V.IsDuration() then
            R += 'Duration,';
        if V.IsDateTime() then
            R += 'DateTime,';
        if V.IsDateFormula() then
            R += 'DateFormula,';
        if V.IsGuid() then
            R += 'Guid,';
        if V.IsRecordId() then
            R += 'RecordId,';
        if V.IsRecord() then
            R += 'Record,';
        if V.IsFieldRef() then
            R += 'FieldRef,';
        exit(R + '|' + Format(V, 0, 2) + '|' + Format(V, 0, 9) + '|' + Format(V));
    end;

    // The same comparison Library Assert's Equal makes when neither side is a number (IsDecimal, IsInteger, IsChar).
    local procedure SameAsAssert(Left: Variant; Right: Variant): Text
    begin
        exit(Format(Left.IsOption() = Right.IsOption()) + '|' + Format(Format(Left, 0, 2) = Format(Right, 0, 2)));
    end;

    [Test]
    procedure EnumValue_And_Variable_Flags()
    var
        Observer: Codeunit "Probe Observer";
        Kind: Enum "BC Kind";
        KindInt: Enum "BC Kind Internal";
        KindExt: Enum "BC Kind Ext";
        V: Variant;
    begin
        V := Kind::Normal;
        Observer.Observe('literal normal', Flags(V));
        V := Kind::Other;
        Observer.Observe('literal other', Flags(V));
        V := Kind;
        Observer.Observe('default variable', Flags(V));
        Kind := Kind::Other;
        V := Kind;
        Observer.Observe('variable other', Flags(V));
        V := KindInt::Other;
        Observer.Observe('internal literal other', Flags(V));
        KindInt := KindInt::Normal;
        V := KindInt;
        Observer.Observe('internal variable normal', Flags(V));
        V := KindExt::Extra;
        Observer.Observe('extension value', Flags(V));
        V := "BC Kind Ext".FromInteger(80950);
        Observer.Observe('fromint extension value', Flags(V));
        V := Kind::Other.AsInteger();
        Observer.Observe('asinteger', Flags(V));
        Observer.Expect('literal normal', 'Option,|0|0|Normal');
        Observer.Expect('literal other', 'Option,|1|1|Other');
        Observer.Expect('default variable', 'Option,|0|0|Normal');
        Observer.Expect('variable other', 'Option,|1|1|Other');
        Observer.Expect('internal literal other', 'Option,|1|1|Other');
        Observer.Expect('internal variable normal', 'Option,|0|0|Normal');
        Observer.Expect('extension value', 'Option,|80950|80950|Extra');
        Observer.Expect('fromint extension value', 'Option,|80950|80950|Extra');
        Observer.Expect('asinteger', 'Integer,|1|1|1');
        Observer.Verify();
    end;

    [Test]
    procedure EnumField_OfTableExtension_TempRecord_AfterInsertGet()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "Sales Invoice Line" temporary;
        Kind: Enum "BC Kind";
        V: Variant;
    begin
        Line."Document No." := 'BC-REPRO';
        Line."Line No." := 10000;
        Line.Insert();
        Line.Get('BC-REPRO', 10000);
        V := Line."BC Kind";
        Observer.Observe('ext field default', Flags(V));
        Observer.Observe('assert same default', SameAsAssert(Kind::Normal, Line."BC Kind"));
        Observer.Observe('assert differs', SameAsAssert(Kind::Other, Line."BC Kind"));
        V := Line."BC Kind Internal";
        Observer.Observe('ext internal field default', Flags(V));
        V := Line."BC Kind Ext";
        Observer.Observe('ext extensible field default', Flags(V));
        Line."BC Kind" := Line."BC Kind"::Other;
        Line."BC Kind Internal" := Line."BC Kind Internal"::Other;
        Line."BC Kind Ext" := Line."BC Kind Ext"::Extra;
        Line.Modify();
        Line.Get('BC-REPRO', 10000);
        V := Line."BC Kind";
        Observer.Observe('ext field other', Flags(V));
        Observer.Observe('assert same other', SameAsAssert(Kind::Other, Line."BC Kind"));
        V := Line."BC Kind Internal";
        Observer.Observe('ext internal field other', Flags(V));
        V := Line."BC Kind Ext";
        Observer.Observe('ext extensible field extra', Flags(V));
        V := Line.Type;
        Observer.Observe('base enum field Type', Flags(V));
        Observer.Expect('ext field default', 'Option,|0|0|Normal');
        Observer.Expect('assert same default', 'Yes|Yes');
        Observer.Expect('assert differs', 'Yes|No');
        Observer.Expect('ext internal field default', 'Option,|0|0|Normal');
        Observer.Expect('ext extensible field default', 'Option,|0|0|Normal');
        Observer.Expect('ext field other', 'Option,|1|1|Other');
        Observer.Expect('assert same other', 'Yes|Yes');
        Observer.Expect('ext internal field other', 'Option,|1|1|Other');
        Observer.Expect('ext extensible field extra', 'Option,|80950|80950|Extra');
        Observer.Expect('base enum field Type', 'Option,|0|0| ');
        Observer.Verify();
    end;

    [Test]
    procedure EnumField_OfTable_TempRecord_AfterInsertGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Enum Row" temporary;
        Kind: Enum "BC Kind";
        V: Variant;
    begin
        Row.Id := 1;
        Row.Insert();
        Row.Get(1);
        V := Row.Kind;
        Observer.Observe('field default', Flags(V));
        Observer.Observe('assert same default', SameAsAssert(Kind::Normal, Row.Kind));
        V := Row.KindInternal;
        Observer.Observe('internal field default', Flags(V));
        V := Row.Opt;
        Observer.Observe('option field default', Flags(V));
        Observer.Observe('assert enum vs option', SameAsAssert(Kind::Normal, Row.Opt));
        Row.Kind := Row.Kind::Other;
        Row.KindInternal := Row.KindInternal::Other;
        Row.KindExt := Row.KindExt::Extra;
        Row.Opt := Row.Opt::Two;
        Row.Modify();
        Row.Get(1);
        V := Row.Kind;
        Observer.Observe('field other', Flags(V));
        V := Row.KindInternal;
        Observer.Observe('internal field other', Flags(V));
        V := Row.KindExt;
        Observer.Observe('extensible field extra', Flags(V));
        V := Row.Opt;
        Observer.Observe('option field two', Flags(V));
        Observer.Expect('field default', 'Option,|0|0|Normal');
        Observer.Expect('assert same default', 'Yes|Yes');
        Observer.Expect('internal field default', 'Option,|0|0|Normal');
        Observer.Expect('option field default', 'Option,|0|0|Zero');
        Observer.Expect('assert enum vs option', 'Yes|Yes');
        Observer.Expect('field other', 'Option,|1|1|Other');
        Observer.Expect('internal field other', 'Option,|1|1|Other');
        Observer.Expect('extensible field extra', 'Option,|80950|80950|Extra');
        Observer.Expect('option field two', 'Option,|2|2|Two');
        Observer.Verify();
    end;

    [Test]
    procedure EnumField_ThroughFieldRef_Value()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Enum Row" temporary;
        RecRef: RecordRef;
        V: Variant;
    begin
        Row.Id := 1;
        Row.Kind := Row.Kind::Other;
        Row.Insert();
        RecRef.GetTable(Row);
        V := RecRef.Field(Row.FieldNo(Kind)).Value;
        Observer.Observe('fieldref value', Flags(V));
        V := RecRef.Field(Row.FieldNo(Kind));
        Observer.Observe('fieldref itself', Flags(V));
        Observer.Expect('fieldref value', 'Option,|1|1|Other');
        Observer.Expect('fieldref itself', 'FieldRef,|1|1|Other');
        Observer.Verify();
    end;
}
