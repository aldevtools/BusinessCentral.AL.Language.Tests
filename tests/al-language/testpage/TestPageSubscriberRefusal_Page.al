// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
// Scope: in-scope
// Fixtures used: TestPage SubErr Row (60823), TP SubErr Guard (60824)
//
// A list page whose PurgeAll control binds to a page GLOBAL variable rather than to a field of
// the source table — the same binding shape Base Application page 9816 "Permission Set by User"
// uses for AllUsersHavePermission.
//
// The control's own OnValidate raises nothing. It calls Delete(true), and the refusal comes from
// "TP SubErr Guard"'s OnBeforeDeleteEvent subscriber underneath that. That is the whole point:
// the page cannot be the source of the error the tests trap.
page 60825 "TestPage SubErr Page"
{
    PageType = List;
    SourceTable = "TestPage SubErr Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            field(PurgeAll; PurgeAll)
            {
                ApplicationArea = All;
                Caption = 'Purge All';

                trigger OnValidate()
                var
                    Row: Record "TestPage SubErr Row";
                begin
                    if not PurgeAll then
                        exit;
                    if Row.FindSet() then
                        repeat
                            Row.Delete(true);
                        until Row.Next() = 0;
                end;
            }
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Guarded; Rec.Guarded)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        PurgeAll: Boolean;
}
