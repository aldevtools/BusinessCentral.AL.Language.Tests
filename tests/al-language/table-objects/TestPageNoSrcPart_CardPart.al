// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702)
//
// A subpage part whose OWN page declares NO SourceTable: a CardPart whose controls bind to
// page globals rather than to a record. Ordinary, legal AL — the "info box" shape that sits
// beside a list or on a card and shows computed text rather than table rows.
//
// The existing modal-part suite (60731/60732/60733) pins the mirror shape: a part WITH a
// source table on a host WITHOUT one. This page pins the other axis, the part itself having
// no source table, on both host shapes.
//
// Every control here is bound to a page global, and the page's own AL is what puts values
// into them: OnOpenPage seeds Tag, and Tag's OnValidate writes through to a table so a test
// can prove the part page's AL ran rather than inferring it from a control read.

page 60800 "Test Page NoSrc CardPart"
{
    PageType = CardPart;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Tag; TagValue)
            {
                ApplicationArea = All;
                Caption = 'Tag';

                trigger OnValidate()
                var
                    Echo: Record "Test Page Modal Handler Row";
                begin
                    Echo.Init();
                    Echo."No." := 'NOSRC-PART';
                    Echo.Descr := CopyStr(TagValue, 1, MaxStrLen(Echo.Descr));
                    if not Echo.Insert() then
                        Echo.Modify();
                end;
            }

            field(Guard; GuardValue)
            {
                ApplicationArea = All;
                Caption = 'Guard';

                trigger OnValidate()
                begin
                    if GuardValue = 'BAD' then
                        Error('Guard rejected the value BAD');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        TagValue := 'Hello';
    end;

    var
        TagValue: Text;
        GuardValue: Text;

    // The in-page access path the host's own AL uses (CurrPage.<part>.Page.SetTag): a part
    // page procedure reached from the host. Writing through to the table is the durable
    // proof the part page object is live rather than an inert shell.
    procedure SetTag(NewTag: Text)
    var
        Echo: Record "Test Page Modal Handler Row";
    begin
        TagValue := NewTag;
        Echo.Init();
        Echo."No." := 'NOSRC-VIA-HOST';
        Echo.Descr := CopyStr(NewTag, 1, MaxStrLen(Echo.Descr));
        if not Echo.Insert() then
            Echo.Modify();
    end;

    procedure GetTag(): Text
    begin
        exit(TagValue);
    end;
}
