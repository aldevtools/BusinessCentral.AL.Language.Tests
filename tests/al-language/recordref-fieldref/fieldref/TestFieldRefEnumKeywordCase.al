// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-type
// Scope: in-scope
// Fixtures used: ALT Case Enum (60505), which declares the SAME enum type "ALT Status" on
//   three fields written `Enum` (field 10), `enum` (field 11) and `ENUM` (field 12).
// BC versions: 27.0+
//
// CLAIM (the file's subject): AL keywords are case-insensitive, so a field's enum metadata
// does not depend on how the author capitalized the `enum` type keyword. All three spellings
// are the same declaration and must answer identically.
//
// Nothing else in the corpus declares a field type in anything but the canonical
// capitalization, so nothing else can distinguish a consumer that resolves the type from one
// that pattern-matches the source spelling. That distinction is the whole subject here: a
// consumer can get the field's TYPE right from a case-insensitive comparison while losing
// the enum's option metadata to a case-sensitive one, which leaves ordinary reads of the
// field working and only the enum-metadata surface wrong.
//
// Every assertion is made three times, once per spelling, against the SAME expected value —
// the canonical-case field is the control arm for the other two, and it is what makes a
// uniform failure distinguishable from a case-specific one.
//
// Written by agent stma-auto-2.

codeunit 60501 "Test FieldRef Enum Kwd Case"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure FieldOf(FieldNo: Integer) FldRef: FieldRef
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(60505);  // ALT Case Enum
        FldRef := RecRef.Field(FieldNo);
    end;

    // ── The enum's option count ──────────────────────────────────────────────────────────

    [Test]
    procedure EnumKeywordCase_EnumValueCount_IsTheSameForEveryCapitalization()
    // CLAIM: "ALT Status" declares five values, and all three fields report five. A field
    // whose enum metadata failed to resolve reports a different count.
    begin
        Assert.AreEqual(5, FieldOf(10).EnumValueCount(), 'field declared `Enum` must report 5 values');
        Assert.AreEqual(5, FieldOf(11).EnumValueCount(), 'field declared `enum` must report 5 values');
        Assert.AreEqual(5, FieldOf(12).EnumValueCount(), 'field declared `ENUM` must report 5 values');
    end;

    // ── Ordinal-keyed name and caption lookups ───────────────────────────────────────────

    [Test]
    procedure EnumKeywordCase_GetEnumValueNameFromOrdinalValue_IsTheSameForEveryCapitalization()
    // CLAIM: ordinal 3 is "Closed" in "ALT Status" whichever way the field's type keyword was
    // written. This is the ORDINAL-keyed lookup, not the 1-based index one, so it exercises
    // the enum's own ordinal map rather than array position.
    begin
        Assert.AreEqual('Closed', FieldOf(10).GetEnumValueNameFromOrdinalValue(3),
          'field declared `Enum` must resolve ordinal 3 to Closed');
        Assert.AreEqual('Closed', FieldOf(11).GetEnumValueNameFromOrdinalValue(3),
          'field declared `enum` must resolve ordinal 3 to Closed');
        Assert.AreEqual('Closed', FieldOf(12).GetEnumValueNameFromOrdinalValue(3),
          'field declared `ENUM` must resolve ordinal 3 to Closed');
    end;

    [Test]
    procedure EnumKeywordCase_GetEnumValueCaptionFromOrdinalValue_IsTheSameForEveryCapitalization()
    // CLAIM: the same for the CAPTION, which is a second, separately-stored piece of the enum
    // metadata — a consumer can carry the names and lose the captions.
    begin
        Assert.AreEqual('Closed', FieldOf(10).GetEnumValueCaptionFromOrdinalValue(3),
          'field declared `Enum` must resolve ordinal 3 to caption Closed');
        Assert.AreEqual('Closed', FieldOf(11).GetEnumValueCaptionFromOrdinalValue(3),
          'field declared `enum` must resolve ordinal 3 to caption Closed');
        Assert.AreEqual('Closed', FieldOf(12).GetEnumValueCaptionFromOrdinalValue(3),
          'field declared `ENUM` must resolve ordinal 3 to caption Closed');
    end;

    [Test]
    procedure EnumKeywordCase_GetEnumValueOrdinal_IsTheSameForEveryCapitalization()
    // CLAIM: the reverse direction — 1-based index 5 is ordinal 4 (Archived). Asserting both
    // directions means a consumer cannot pass by returning the argument back.
    begin
        Assert.AreEqual(4, FieldOf(10).GetEnumValueOrdinal(5), 'field declared `Enum`: index 5 is ordinal 4');
        Assert.AreEqual(4, FieldOf(11).GetEnumValueOrdinal(5), 'field declared `enum`: index 5 is ordinal 4');
        Assert.AreEqual(4, FieldOf(12).GetEnumValueOrdinal(5), 'field declared `ENUM`: index 5 is ordinal 4');
    end;

    // ── The field's type, which is the half that already worked ──────────────────────────

    [Test]
    procedure EnumKeywordCase_FieldTypeIsOption_ForEveryCapitalization()
    // CLAIM: an enum-typed field is an Option field at runtime whichever way the keyword was
    // written. Stated separately from the metadata arms above because it is the half a
    // case-insensitive TYPE comparison already gets right — so if this passes while the arms
    // above fail, the failure is specifically in the enum metadata and not in type
    // resolution.
    begin
        Assert.AreEqual('Option', Format(FieldOf(10).Type), 'field declared `Enum` must be an Option field');
        Assert.AreEqual('Option', Format(FieldOf(11).Type), 'field declared `enum` must be an Option field');
        Assert.AreEqual('Option', Format(FieldOf(12).Type), 'field declared `ENUM` must be an Option field');
    end;
}
