// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-getenumvalueordinal-method
// Scope: in-scope
// Fixtures used: Assert (60021), ALT Field Enum Type Fix (60470; field 2 = Enum "ALT Field Enum Kind",
//                ordinals 0, 5, 10; field 3 = Option Alpha,Beta,Gamma), ALT Field Enum Kind (60469),
//                TPEDO Row (67485; field 2 = Enum "TPEDO Kind", declared order 4, 0, 1, 2),
//                TPEDO Kind (67485), TPEDO Kind Ext (67485).
//
// CLAIM: FieldRef.GetEnumValueOrdinal(Index), GetEnumValueCaption(Index) and
// GetEnumValueName(Index) take a 1-based POSITION in the enum's declared value list and answer
// the ordinal, caption and name of the value at that position. When the ordinals are not
// 0, 1, 2, ... in declared order -- a gapped enum (0, 5, 10) or an extended one whose base value
// is declared first (4, then 0, 1, 2) -- the ordinal is the declared one, never Index - 1, and
// the caption is that value's own caption. An Index outside 1..EnumValueCount() answers -1 for
// the ordinal and an empty caption. Codeunit 60131 covers only a contiguous 0..4 enum, where
// position and ordinal coincide and cannot be told apart.
//
// Written by agent stma-auto2-2, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4798. The expected
// values were written before any BC service tier ran them; this pull request's CI is the first
// real-BC measurement.

codeunit 67486 "FieldRef Enum Ordinal By Index"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure GappedKindField(var RecRef: RecordRef; var FldRef: FieldRef)
    begin
        RecRef.Open(Database::"ALT Field Enum Type Fix");
        FldRef := RecRef.Field(2);
    end;

    local procedure DeclaredOrderKindField(var RecRef: RecordRef; var FldRef: FieldRef)
    begin
        RecRef.Open(Database::"TPEDO Row");
        FldRef := RecRef.Field(2);
    end;

    // ── Gapped enum: ordinals 0, 5, 10 ─────────────────────────────────────────

    [Test]
    procedure GappedEnum_GetEnumValueOrdinal_ReturnsDeclaredOrdinals()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        GappedKindField(RecRef, FldRef);
        Assert.AreEqual(3, FldRef.EnumValueCount(), 'EnumValueCount() of ALT Field Enum Kind');
        Assert.AreEqual(0, FldRef.GetEnumValueOrdinal(1), 'GetEnumValueOrdinal(1) is the ordinal of Unassigned');
        Assert.AreEqual(5, FldRef.GetEnumValueOrdinal(2), 'GetEnumValueOrdinal(2) is the ordinal of Middle, not the position 1');
        Assert.AreEqual(10, FldRef.GetEnumValueOrdinal(3), 'GetEnumValueOrdinal(3) is the ordinal of Far Out, not the position 2');
    end;

    [Test]
    procedure GappedEnum_GetEnumValueCaption_ReturnsThatValuesCaption()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        GappedKindField(RecRef, FldRef);
        Assert.AreEqual('Not assigned', FldRef.GetEnumValueCaption(1), 'GetEnumValueCaption(1)');
        Assert.AreEqual('Middle', FldRef.GetEnumValueCaption(2), 'GetEnumValueCaption(2): a value with no Caption answers its name');
        Assert.AreEqual('Far out value', FldRef.GetEnumValueCaption(3), 'GetEnumValueCaption(3)');
    end;

    [Test]
    procedure GappedEnum_GetEnumValueName_ReturnsThatValuesName()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        GappedKindField(RecRef, FldRef);
        Assert.AreEqual('Unassigned', FldRef.GetEnumValueName(1), 'GetEnumValueName(1)');
        Assert.AreEqual('Far Out', FldRef.GetEnumValueName(3), 'GetEnumValueName(3)');
    end;

    [Test]
    procedure GappedEnum_IndexOutOfRange_AnswersMinusOneAndEmpty()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        GappedKindField(RecRef, FldRef);
        Assert.AreEqual(-1, FldRef.GetEnumValueOrdinal(0), 'GetEnumValueOrdinal(0) is below the 1-based range');
        Assert.AreEqual(-1, FldRef.GetEnumValueOrdinal(4), 'GetEnumValueOrdinal(4) is past the last of 3 values');
        Assert.AreEqual('', FldRef.GetEnumValueCaption(4), 'GetEnumValueCaption(4) is past the last of 3 values');
    end;

    // ── Declared order is not ordinal order: 4, then 0, 1, 2 ───────────────────

    [Test]
    procedure DeclaredOrderEnum_GetEnumValueOrdinal_FollowsDeclaredOrder()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        DeclaredOrderKindField(RecRef, FldRef);
        Assert.AreEqual(4, FldRef.EnumValueCount(), 'EnumValueCount() of TPEDO Kind with its extension');
        Assert.AreEqual(4, FldRef.GetEnumValueOrdinal(1), 'GetEnumValueOrdinal(1) is the base value Zulu, ordinal 4');
        Assert.AreEqual(0, FldRef.GetEnumValueOrdinal(2), 'GetEnumValueOrdinal(2) is Alpha, ordinal 0');
        Assert.AreEqual(1, FldRef.GetEnumValueOrdinal(3), 'GetEnumValueOrdinal(3) is Beta, ordinal 1');
        Assert.AreEqual(2, FldRef.GetEnumValueOrdinal(4), 'GetEnumValueOrdinal(4) is Gamma, ordinal 2');
    end;

    [Test]
    procedure DeclaredOrderEnum_GetEnumValueCaption_FollowsDeclaredOrder()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        DeclaredOrderKindField(RecRef, FldRef);
        Assert.AreEqual('Zulu caption', FldRef.GetEnumValueCaption(1), 'GetEnumValueCaption(1)');
        Assert.AreEqual('Alpha caption', FldRef.GetEnumValueCaption(2), 'GetEnumValueCaption(2)');
        Assert.AreEqual('Beta caption', FldRef.GetEnumValueCaption(3), 'GetEnumValueCaption(3)');
        Assert.AreEqual('Gamma caption', FldRef.GetEnumValueCaption(4), 'GetEnumValueCaption(4)');
        Assert.AreEqual('Zulu', FldRef.GetEnumValueName(1), 'GetEnumValueName(1)');
    end;

    // ── Control: a plain Option field, whose ordinal IS its position ───────────

    [Test]
    procedure PlainOption_GetEnumValueOrdinal_IsPositionMinusOne()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::"ALT Field Enum Type Fix");
        FldRef := RecRef.Field(3);
        Assert.AreEqual(0, FldRef.GetEnumValueOrdinal(1), 'Option Alpha is ordinal 0');
        Assert.AreEqual(2, FldRef.GetEnumValueOrdinal(3), 'Option Gamma is ordinal 2');
        Assert.AreEqual('Gamma', FldRef.GetEnumValueCaption(3), 'Option Gamma caption');
    end;

    // ── Writer SO (2026-10-28), aldevtools/BusinessCentral.AL.Runner#5987: an Option value or an integer as the ordinal argument ──
    // GetEnumValueCaptionFromOrdinalValue / GetEnumValueNameFromOrdinalValue on an Option FieldRef, called with FieldRef.Value()
    // (the reporter's shape) and with the integers -1, 0, 1, 2 (one past the last member) and 5; an integer assigned to an Option
    // field and passed for an Option parameter, with Format of the result. Table 89520 (media/lt-so-media-filter/SoMediaFilter.al):
    // Opt = Option1,Option2 with OptionCaption 'First caption,Second caption'; OptNoCap = Option1,Option2 without OptionCaption.

    [TryFunction]
    local procedure SoTryCaption(var FldRef: FieldRef; Ordinal: Integer; var Result: Text)
    begin
        Result := FldRef.GetEnumValueCaptionFromOrdinalValue(Ordinal);
    end;

    [TryFunction]
    local procedure SoTryName(var FldRef: FieldRef; Ordinal: Integer; var Result: Text)
    begin
        Result := FldRef.GetEnumValueNameFromOrdinalValue(Ordinal);
    end;

    local procedure SoFromOrdinal(var FldRef: FieldRef; Ordinal: Integer) Result: Text
    var
        Part: Text;
    begin
        ClearLastError();
        if SoTryCaption(FldRef, Ordinal, Part) then
            Result := 'caption=[' + Part + ']'
        else
            Result := 'caption error=[' + GetLastErrorText() + '] code=' + GetLastErrorCode();
        ClearLastError();
        if SoTryName(FldRef, Ordinal, Part) then
            Result += ' name=[' + Part + ']'
        else
            Result += ' name error=[' + GetLastErrorText() + '] code=' + GetLastErrorCode();
    end;

    local procedure SoTakesOption(Value: Option Alpha,Beta,Gamma): Text
    begin
        exit(Format(Value) + '|' + Format(Value, 0, 2));
    end;

    local procedure SoTakesInteger(Value: Integer): Text
    begin
        exit(Format(Value));
    end;

    [Test]
    procedure SO_OptionField_ValueAsOrdinalArgument_ReproShape()
    var
        Row: Record "LT SO Media Row";
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Row.Init();
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(Row.FieldNo(OptNoCap));
        Observer.Observe('no caption, value 0', FldRef.GetEnumValueCaptionFromOrdinalValue(FldRef.Value()));
        Observer.Observe('no caption, name of value 0', FldRef.GetEnumValueNameFromOrdinalValue(FldRef.Value()));
        FldRef := RecRef.Field(Row.FieldNo(Opt));
        Observer.Observe('caption, value 0', FldRef.GetEnumValueCaptionFromOrdinalValue(FldRef.Value()));
        Observer.Observe('caption, name of value 0', FldRef.GetEnumValueNameFromOrdinalValue(FldRef.Value()));
        FldRef.Value := 1;
        Observer.Observe('caption, value 1', FldRef.GetEnumValueCaptionFromOrdinalValue(FldRef.Value()));
        Observer.Observe('format value 1', Format(FldRef.Value()));
        Observer.Observe('value 1 as integer argument', SoTakesInteger(FldRef.Value()));
        Observer.Expect('no caption, value 0', 'Option1');
        Observer.Expect('no caption, name of value 0', 'Option1');
        Observer.Expect('caption, value 0', 'First caption');
        Observer.Expect('caption, name of value 0', 'Option1');
        Observer.Expect('caption, value 1', 'Second caption');
        Observer.Expect('format value 1', 'Second caption');
        Observer.Expect('value 1 as integer argument', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SO_OptionField_IntegerOrdinalArguments()
    var
        Row: Record "LT SO Media Row";
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::"LT SO Media Row");
        FldRef := RecRef.Field(Row.FieldNo(Opt));
        Observer.Observe('-1', SoFromOrdinal(FldRef, -1));
        Observer.Observe('0', SoFromOrdinal(FldRef, 0));
        Observer.Observe('1', SoFromOrdinal(FldRef, 1));
        Observer.Observe('2', SoFromOrdinal(FldRef, 2));
        Observer.Observe('5', SoFromOrdinal(FldRef, 5));
        FldRef := RecRef.Field(Row.FieldNo(OptNoCap));
        Observer.Observe('no caption 0', SoFromOrdinal(FldRef, 0));
        Observer.Observe('no caption 2', SoFromOrdinal(FldRef, 2));
        Observer.Expect('-1', 'caption=[-1] name=[]');
        Observer.Expect('0', 'caption=[First caption] name=[Option1]');
        Observer.Expect('1', 'caption=[Second caption] name=[Option2]');
        Observer.Expect('2', 'caption=[2] name=[]');
        Observer.Expect('5', 'caption=[5] name=[]');
        Observer.Expect('no caption 0', 'caption=[Option1] name=[Option1]');
        Observer.Expect('no caption 2', 'caption=[2] name=[]');
        Observer.Verify();
    end;

    [Test]
    procedure SO_OptionField_IntegerAssigned()
    var
        Row: Record "LT SO Media Row";
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Row.Init();
        Row.Opt := 1;
        Observer.Observe('field := 1', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2) + '|' + Format(Row.Opt, 0, 9));
        Row.Opt := 5;
        Observer.Observe('field := 5', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2) + '|' + Format(Row.Opt, 0, 9));
        Row.Opt := -1;
        Observer.Observe('field := -1', Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2));
        RecRef.Open(Database::"LT SO Media Row");
        FldRef := RecRef.Field(Row.FieldNo(Opt));
        FldRef.Value := 5;
        Observer.Observe('fieldref value := 5', Format(FldRef.Value()) + '|' + Format(FldRef.Value(), 0, 2));
        Observer.Observe('fieldref value 5 caption', SoFromOrdinal(FldRef, FldRef.Value()));
        Observer.Expect('field := 1', 'Second caption|1|1');
        Observer.Expect('field := 5', '5|5|5');
        Observer.Expect('field := -1', '-1|-1');
        Observer.Expect('fieldref value := 5', '5|5');
        Observer.Expect('fieldref value 5 caption', 'caption=[5] name=[]');
        Observer.Verify();
    end;

    [Test]
    procedure SO_OptionParameter_IntegerArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('0', SoTakesOption(0));
        Observer.Observe('1', SoTakesOption(1));
        Observer.Observe('2', SoTakesOption(2));
        Observer.Observe('3', SoTakesOption(3));
        Observer.Observe('-1', SoTakesOption(-1));
        Observer.Expect('0', 'Alpha|0');
        Observer.Expect('1', 'Beta|1');
        Observer.Expect('2', 'Gamma|2');
        Observer.Expect('3', '3|3');
        Observer.Expect('-1', '-1|-1');
        Observer.Verify();
    end;
}
