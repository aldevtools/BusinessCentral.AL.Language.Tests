// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-programming-in-al#pages
// Scope: in-scope
//
// A page COMPILED BY THIS TEST APP whose SourceTable names a table declared by a
// DEPENDENCY (Base Application's "Location", table 14) rather than by this app or by
// _fixtures/. Deliberately not a fixture-library object: the claim under test is that a
// source-compiled page can bind Rec to a dependency's table at all, so the page has to be
// one this app compiles itself, over a table it does not own.

page 60908 "TP Dep Table Card"
{
    PageType = Card;
    SourceTable = Location;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}
