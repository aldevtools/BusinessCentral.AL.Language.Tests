// Fixture line table for TestPagePartDraftLineLink.al.
//
// "Header No." is the FIRST field of the primary key on purpose. The SubPageLink on the host
// card targets it, and BC's RecordImplementation.InitRecordFromFilters copies a filtered
// value onto a new record only when the field is part of the primary key (or the page sets
// PopulateAllFields, or the caller names the filter group) -- so this is the shape where the
// link's value IS carried onto a row the page starts. "PKFL Line" (60642) is the mirror shape
// with the linked field left out of the key.
//
// Descr's OnValidate is the whole point of the table. It does two things:
//   * TestField("Header No.") -- the same guard every Base Application line table runs on the
//     first field a user types into (Sales Line's "No." OnValidate reaches it through
//     TestStatusOpen -> GetSalesHeader). It raises when the row it is validating has no key,
//     which is what a page-started row without its link values looks like.
//   * copies "Header No." into "Header Seen By Validate", so a test can assert what the
//     trigger SAW rather than only what the finished row holds. A row whose link value is
//     stamped AFTER the typed field's OnValidate would still end up with the right
//     "Header No." while this field stayed blank.
table 60997 "TPDL Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[50])
        {
            trigger OnValidate()
            begin
                TestField("Header No.");
                "Header Seen By Validate" := "Header No.";
            end;
        }
        field(4; "Header Seen By Validate"; Code[20]) { }
        // Written only by the part page's OnNewRecord trigger, so a test can tell whether the
        // platform's new-record step ran for the row at all.
        field(5; "Set By OnNewRecord"; Code[20]) { }
    }

    keys
    {
        key(PK; "Header No.", "Line No.") { Clustered = true; }
    }
}
