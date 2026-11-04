// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extending-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enums 73775 and 73776, table 73777, table extension 73778, test codeunit 73779
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 7 refinement (NP Retail blockers): a Variant that holds an enum field value, where the field is added by a table extension and
// its enum has Access = Internal, next to an enum field of the base table: IsOption, the other Is... flags that answer, Format and the enum ordinal.
// Microsoft's Library Assert (AreEqual) decides its error from these answers; its text lives in Microsoft's AL source.
// BC versions: 27, 28, 29

enum 73775 "LT EEV Base Enum"
{
    Extensible = true;
    value(0; A) { }
    value(1; B) { }
}

enum 73776 "LT EEV Internal Enum"
{
    Access = Internal;
    Extensible = false;
    value(0; X) { }
    value(1; Y) { }
}

table 73777 "LT EEV Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; BaseEnum; Enum "LT EEV Base Enum") { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 73778 "LT EEV Rec Ext" extends "LT EEV Rec"
{
    fields
    {
        field(73778; InternalEnum; Enum "LT EEV Internal Enum") { }
    }
}

codeunit 73779 "LT EEV Enum Ext Variant"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsOption then
            R += 'IsOption ';
        if V.IsInteger then
            R += 'IsInteger ';
        if V.IsText then
            R += 'IsText ';
        if V.IsCode then
            R += 'IsCode ';
        if V.IsDecimal then
            R += 'IsDecimal ';
        if V.IsBoolean then
            R += 'IsBoolean ';
        exit(R);
    end;

    [Test]
    procedure Variant_EnumFieldOfBaseTable()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT EEV Rec";
        V: Variant;
    begin
        Rec.BaseEnum := Rec.BaseEnum::B;
        V := Rec.BaseEnum;
        Observer.Observe('flags', Flags(V));
        Observer.Observe('format', Format(V));
        Observer.Observe('format_ordinal', Format(V, 0, 2));
        Observer.Expect('flags', 'IsOption ');
        Observer.Expect('format', 'B');
        Observer.Expect('format_ordinal', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_InternalEnumFieldFromTableExtension()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT EEV Rec";
        V: Variant;
        W: Variant;
    begin
        Rec.InternalEnum := Rec.InternalEnum::Y;
        V := Rec.InternalEnum;
        Observer.Observe('flags', Flags(V));
        Observer.Observe('format', Format(V));
        Observer.Observe('format_ordinal', Format(V, 0, 2));
        W := Rec.InternalEnum::Y;
        Observer.Observe('literal_flags', Flags(W));
        Observer.Observe('same_value', Format(Format(V) = Format(W)));
        Observer.Expect('flags', 'IsOption ');
        Observer.Expect('format', 'Y');
        Observer.Expect('format_ordinal', '1');
        Observer.Expect('literal_flags', 'IsOption ');
        Observer.Expect('same_value', 'Yes');
        Observer.Verify();
    end;
}
