// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-wordmergedataitem-property
// Scope: in-scope
// Fixtures used: Test Rpt Meta Cols Sample (60359)
//
// Fixture report for the Report Metadata (2000000139) / Report Data Items (2000000203)
// column tests. Every property here is declared to a value that is NOT the platform default,
// so a test reading the column back cannot pass against an implementation that answers a
// default or a hardcode:
//
//   ProcessingOnly     = false  (a report that renders, so "always processing-only" is wrong)
//   WordMergeDataItem  = Src    (non-empty, so an empty-string answer is wrong)
//   DataItemTableView  sorted DESCENDING on a named key, so the direction is observable
//   RequestFilterFields names field 2, not field 1, so "the first field" is not the answer
//
// The Filtered and Plain data items exist for the two columns that report field NUMBERS
// (Sorting Fields, Request Filter Fields). Filtered declares both properties against the
// SECONDARY key, naming fields that are neither field 1 nor in ascending field order, and it
// declares them in two DIFFERENT orders — so "the primary key", "the first field", "ascending
// field order" and "whatever the other column says" are each a wrong answer. Plain declares
// neither, which is the shape whose correct answer is empty for both.

report 60360 "Test Rpt Meta Cols Fixture"
{
    UsageCategory = None;
    ProcessingOnly = false;
    WordMergeDataItem = Src;

    dataset
    {
        dataitem(Src; "Test Rpt Meta Cols Sample")
        {
            DataItemTableView = sorting("Entry No.") order(descending);
            RequestFilterFields = Description;

            column(EntryNo; "Entry No.") { }
            column(SampleDescription; Description) { }

            dataitem(Child; "Test Rpt Meta Cols Sample")
            {
                DataItemLink = "Entry No." = field("Entry No.");
                column(ChildEntryNo; "Entry No.") { }
            }
        }

        // Sorts on key Alt = ("Alt Code", Description) = fields 5 then 2.
        // Filters on Description then "Alt Code"           = fields 2 then 5.
        dataitem(Filtered; "Test Rpt Meta Cols Sample")
        {
            DataItemTableView = sorting("Alt Code", Description);
            RequestFilterFields = Description, "Alt Code";

            column(FilteredEntryNo; "Entry No.") { }
        }

        dataitem(Plain; "Test Rpt Meta Cols Sample")
        {
            column(PlainEntryNo; "Entry No.") { }
        }
    }
}
