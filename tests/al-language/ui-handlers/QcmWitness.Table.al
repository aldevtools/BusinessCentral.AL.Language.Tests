// Fixture for TestPageQueryCloseMessageHandler_Tests.al.
/// <summary>
/// Records what a [MessageHandler] saw, so the suite can assert the handler fired and with which
/// text WITHOUT asserting inside the handler itself. That distinction matters on this surface:
/// the handler runs deep inside the platform's close round trip, so an assertion failure raised
/// there would arrive wrapped in whatever the close handler does with an exception, and the test
/// could not tell "the handler never ran" from "the handler ran and disagreed".
///
/// A single row keyed on a caller-chosen tag, written by the handler and read back by the test
/// after the round trip has finished, keeps every assertion on the test's own stack.
/// </summary>
table 60601 "QCM Witness"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Tag"; Code[20]) { }
        field(2; "Seen Count"; Integer) { }
        field(3; "Last Text"; Text[250]) { }
    }

    keys
    {
        key(PK; "Tag") { Clustered = true; }
    }
}
