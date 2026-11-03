// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope
// Fixtures used: ALT TestPart Lines (60342), ALT TestPart Hidden (60343), ALT TestPart Row (60341)
//
// The host for the TestPart surface suite. It has NO SourceTable, so no parent record is
// involved in building or driving any of its parts -- the parts stand on their own source
// table, which keeps every assertion in the suite a statement about TestPart rather than
// about SubPageLink resolution.
//
// It hosts THREE parts over the same table, differing only in the properties the suite
// measures. That is the whole design: every boolean accessor on TestPart (Visible, Enabled,
// Editable) is asserted across a PAIR of parts on ONE open host, so an implementation that
// hardcodes the answer, or reads it from the host instead of the part control, fails.
//
//   Lines     Visible = true,  Enabled = true,  Editable = true   (the default arm)
//   Hidden    Visible = false, Enabled = false                    (the Visible/Enabled arm)
//   ReadOnly  Visible = true,  Enabled = true,  Editable = false  (the Editable arm)
//
// The host's own caption is spelled differently from every part caption and every part
// control caption, so Caption() cannot pass by coincidence.

page 60344 "ALT TestPart Host"
{
    PageType = Worksheet;
    Caption = 'Host Page Caption';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(Mode; SelectedMode)
                {
                    ApplicationArea = All;
                    Caption = 'Mode';
                }
            }

            // The default arm. The part control carries NO Caption of its own, so
            // TestPart.Caption() on it can only come from the part PAGE's caption.
            part(Lines; "ALT TestPart Lines")
            {
                ApplicationArea = All;
            }

            // The Visible/Enabled arm.
            part(Hidden; "ALT TestPart Hidden")
            {
                ApplicationArea = All;
                Visible = false;
                Enabled = false;
            }

            // The Editable arm: same part page as Lines, made non-editable by the HOST's
            // control property. Editable() must therefore answer from the control, not from
            // the part page, and the pair (Lines editable, ReadOnly not) proves it.
            part(ReadOnlyLines; "ALT TestPart Lines")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }

    var
        SelectedMode: Text;
}
