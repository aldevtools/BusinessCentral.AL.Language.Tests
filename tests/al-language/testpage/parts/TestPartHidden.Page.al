// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-visible-method
// Scope: in-scope
// Fixtures used: ALT TestPart Row (60341)
//
// A second ListPart over the same table, hosted alongside the first one but declared
// Visible = false and Enabled = false on the HOST's part control.
//
// It was added so TestPart.Visible() and TestPart.Enabled() would have a discriminator: with
// only one part in play both answer true, and an implementation hardcoding `true` would pass.
//
// A real service tier then established something sharper, and this fixture is what
// established it: a part declared Visible = false is NOT RENDERED INTO THE TEST PAGE'S
// CONTROL TREE AT ALL. Reaching `Host.Hidden` errors with "The part with ID = <n> was not
// found on the page" rather than yielding a handle that reports false. So the discriminating
// PAIR is not constructible -- Visible() and Enabled() can never be observed returning false
// from AL -- and this part's role changed from "the false arm" to "the unreachable arm".
// Codeunit 60346 pins the error, which is the only observable BC offers here.
//
// Keep both properties. Enabled = false is now untestable in isolation for the same reason
// (its only host declares it alongside Visible = false), but removing either would silently
// change what the unreachability test is a test OF.

page 60343 "ALT TestPart Hidden"
{
    PageType = ListPart;
    SourceTable = "ALT TestPart Row";
    Caption = 'Hidden Part Caption';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                    Caption = 'Group';
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
            }
        }
    }
}
