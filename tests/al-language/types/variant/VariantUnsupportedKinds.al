// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 73773, test codeunit 73774
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 7 (NP Retail blockers) as far as the platform decides it: Microsoft's Library Assert (Assert.AreEqual with Variant
// parameters) raises "Equality assertions only support Boolean, Option, Integer, ..." from its own AL code when the Variant is of a kind it does not list
// (Guid, RecordId, Blob, Media). The text comes from Microsoft's AL source, not from the platform. What the platform decides is which Is... flags a Variant that
// holds a Guid, a RecordId, a Blob field value or a Media field value answers, what Format of it gives, and the TypeName it reports. That is pinned here.
// BC versions: 27, 28, 29

table 73773 "LT VUK Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Blb; Blob) { }
        field(3; Med; Media) { }
        field(4; Gd; Guid) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73774 "LT VUK Variant Kinds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsBoolean then
            R += 'IsBoolean ';
        if V.IsOption then
            R += 'IsOption ';
        if V.IsInteger then
            R += 'IsInteger ';
        if V.IsByte then
            R += 'IsByte ';
        if V.IsBigInteger then
            R += 'IsBigInteger ';
        if V.IsDecimal then
            R += 'IsDecimal ';
        if V.IsText then
            R += 'IsText ';
        if V.IsCode then
            R += 'IsCode ';
        if V.IsChar then
            R += 'IsChar ';
        if V.IsTextConstant then
            R += 'IsTextConstant ';
        if V.IsDate then
            R += 'IsDate ';
        if V.IsTime then
            R += 'IsTime ';
        if V.IsDuration then
            R += 'IsDuration ';
        if V.IsDateTime then
            R += 'IsDateTime ';
        if V.IsDateFormula then
            R += 'IsDateFormula ';
        if V.IsGuid then
            R += 'IsGuid ';
        if V.IsRecordId then
            R += 'IsRecordId ';
        if V.IsRecord then
            R += 'IsRecord ';
        if V.IsRecordRef then
            R += 'IsRecordRef ';
        if V.IsFieldRef then
            R += 'IsFieldRef ';
        if V.IsAction then
            R += 'IsAction ';
        if V.IsCodeunit then
            R += 'IsCodeunit ';
        if V.IsNotification then
            R += 'IsNotification ';
        if V.IsDotNet then
            R += 'IsDotNet ';
        if V.IsFile then
            R += 'IsFile ';
        if V.IsInStream then
            R += 'IsInStream ';
        if V.IsOutStream then
            R += 'IsOutStream ';
        if V.IsJsonObject then
            R += 'IsJsonObject ';
        if V.IsList then
            R += 'IsList ';
        if V.IsDictionary then
            R += 'IsDictionary ';
        exit(R);
    end;

    [Test]
    procedure Variant_GuidAndRecordId()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT VUK Rec";
        G: Guid;
        RI: RecordId;
        V: Variant;
    begin
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        V := G;
        Observer.Observe('guid_flags', Flags(V));
        Observer.Observe('guid_format', Format(V));
        Observer.Observe('guid_format2', Format(V, 0, 2));
        Rec.Id := 1;
        RI := Rec.RecordId;
        V := RI;
        Observer.Observe('recordid_flags', Flags(V));
        Observer.Observe('recordid_format', Format(V));
        Observer.Observe('recordid_format2', Format(V, 0, 2));
        Observer.Expect('guid_flags', 'IsGuid ');
        Observer.Expect('guid_format', '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('guid_format2', '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('recordid_flags', 'IsRecordId ');
        Observer.Expect('recordid_format', 'LT VUK Rec: 1');
        Observer.Expect('recordid_format2', 'LT VUK Rec: 1');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_BlobAndMediaFieldValues()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT VUK Rec";
        V: Variant;
    begin
        V := Rec.Blb;
        Observer.Observe('blob_flags', Flags(V));
        V := Rec.Med;
        Observer.Observe('media_flags', Flags(V));
        Observer.Expect('blob_flags', '');
        Observer.Expect('media_flags', '');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_BlobAndMediaFormat()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT VUK Rec";
        V: Variant;
        Res: Text;
    begin
        V := Rec.Blb;
        Res := Format(V);
        Observer.Observe('blob_format', Res);
        Res := Format(V, 0, 2);
        Observer.Observe('blob_format2', Res);
        V := Rec.Med;
        Res := Format(V);
        Observer.Observe('media_format', Res);
        Res := Format(V, 0, 2);
        Observer.Observe('media_format2', Res);
        Observer.Expect('blob_format', ' ');
        Observer.Expect('blob_format2', ' ');
        Observer.Expect('media_format', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('media_format2', '{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;
}
