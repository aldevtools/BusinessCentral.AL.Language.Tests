// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
// Scope: in-scope
// Fixtures used: (none — this table exists only to give the card page below a SourceTable)
//
// Backing table for the blank-temporal TestPage rendering suite. One field per temporal type,
// so a blank DateTime, a blank Date and a blank Time can each be read through a control on the
// same row, in one page, without the three claims contaminating each other. Marker gives the
// row a non-temporal field so a test can prove the row was found at all before asserting on a
// value that is legitimately empty — otherwise "the control reads ''" and "the page is on no
// row" are indistinguishable.

table 60660 "TP Blank Temporal Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Marker; Text[30]) { }
        field(3; "When"; DateTime) { }
        field(4; "On"; Date) { }
        field(5; "At"; Time) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}
