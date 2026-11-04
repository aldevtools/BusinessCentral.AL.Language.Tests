// Migrated from AL Runner tests/runner-extras/testpage-record-triggers (TrtSrc.al).
// Fixture table backing the "TRT Card" family of pages used by TestPage record-trigger tests.
table 60839 "TRT Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        // Deliberately ordered so the DEFAULT (0) is the wrong answer. A page that seeds this
        // in OnNewRecord and a runner that skips the trigger differ visibly; if Tenant were 0
        // the bug would be invisible.
        field(2; Kind; Option) { OptionMembers = Extension,Tenant; }
        field(3; Note; Text[50]) { }
        // Written ONLY by OnInsertRecord, never by a TestPage control — a field the
        // client also writes (like Note, above) gets the client-edited value at insert
        // regardless of what OnInsertRecord assigns it, so an insert-time stamp needs a
        // field of its own to be provable at all.
        field(4; "Insert Stamp"; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
