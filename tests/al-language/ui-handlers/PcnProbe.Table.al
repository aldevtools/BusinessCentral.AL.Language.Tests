// Fixture for "PCN Tests" (60535): what a [ModalPageHandler] saw in "PCN Line" (60534) at a
// chosen moment, read by the test AFTER the modal round trip has finished. The shape is
// "Opf Result" (60638)'s, and it is here for one arm only.
//
// The two-row discriminator asks whether Cancel keeps the part row that New() already committed.
// Without this witness a final count of 0 would have had two causes -- Cancel rolled a committed
// row back, or New() never committed the first row and Cancel dropped two pending ones -- and
// nothing else in the fixture separates them. The handler records the count right after the
// second New(), the moment the first row is expected to have been committed.
//
// BC answered 2, not 0, so the ambiguity did not arise; the probe is what says so rather than
// leaving it assumed. It read 1 on all eight cloud legs of run 35239632216, which is what makes
// the 2 mean "Cancel kept both" instead of "nothing was ever committed".
table 60536 "PCN Probe"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Line Count"; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
