// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-data-type
// Scope: in-scope
//
// Backing table for the TestFilter surface suite (codeunit 60350).
//
// Three things about this table are deliberate, and each one makes a test in that suite
// discriminating rather than vacuous:
//
//   1. THREE KEYS, whose orders DISAGREE on the seeded rows. The primary key ("Entry No.")
//      and the two secondary keys (Rank; Grp+Rank) each walk the same three rows in a
//      DIFFERENT order. SetCurrentKey() is only measurable if changing the key changes the
//      observed row order -- with one key, or with keys that happen to agree, every
//      SetCurrentKey assertion would pass against an implementation that ignored its
//      argument entirely.
//
//   2. "Entry No." IS NOT THE INSERTION ORDER OF Rank. Row 1 has the highest Rank, so
//      walking by "Entry No." and walking by Rank produce reversed sequences. That is what
//      lets one assertion distinguish "the key was applied" from "the rows came back in
//      primary-key order regardless".
//
//   3. OffPage CARRIES NO CONTROL ON THE PAGE. TestFilter's field argument resolves against
//      the SOURCE TABLE, not the page's control set -- `L.Filter.GetFilter(EntryNo)` (the
//      control name) is error AL0118 while `L.Filter.GetFilter("Entry No.")` (the table
//      field) compiles. OffPage is the sharp end of that: a field the page does not display
//      at all, which the compiler still accepts as a filter target. Whether filtering it
//      actually restricts the rowset is a runtime question only a service tier can answer.

table 60347 "ALT TestFilter Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Rank; Integer) { }
        field(4; Descr; Text[50]) { }
        // No control on ALT TestFilter List displays this field.
        field(5; OffPage; Code[10]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByRank; Rank) { }
        key(ByGrpRank; Grp, Rank) { }
    }
}
