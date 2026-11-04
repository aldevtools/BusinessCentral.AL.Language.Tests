// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Big Line (60923)
//
// Line table whose split-key field is a BigInteger. AutoSplitKey acts on the LAST field of
// the primary key and supports Integer, BigInteger, Decimal and GUID; the Integer case is
// pinned by "ASK Line" (60916), this table pins that the 64-bit path really is 64-bit —
// its seed values do not fit in an Integer at all. No OnInsert, no number series: any
// "Line No." value came from the page property.

table 60923 "ASK Big Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Line No."; BigInteger) { }
        field(3; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.", "Line No.") { Clustered = true; }
    }
}
