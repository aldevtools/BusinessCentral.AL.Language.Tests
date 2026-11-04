// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-view-method
// Scope: in-scope
// Fixtures used: TPVE Row (60457), TPVE Card (60458), TPVE List (60459),
//                TPVE Open Probe (60460)
//
// Fixtures for "what do a list page's built-in View and Edit actions do when a test invokes
// them". Unlike every other page-opening route the corpus pins, no AL is involved on either
// side: the list declares CardPageId and nothing else, the test calls TestPage.View() or
// TestPage.Edit(), and the platform alone decides whether a page opens, which page, on which
// row, and in which mode.
//
// The card records its own opening in a SingleInstance codeunit rather than a table. Memory,
// not database, for the same reason TPARONH Open Probe (60286) exists: an observable a
// rollback cannot reach. Nothing in this codeunit provokes a rollback today, but the probe
// also counts opens, and a count is what separates "the card opened once" from "the list
// re-opened it" -- which a single log row cannot say.

table 60457 "TPVE Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// Counts card opens and records what the card saw when it opened. SingleInstance, so the
// state a [PageHandler] reads is the state the test reads afterwards.
codeunit 60460 "TPVE Open Probe"
{
    SingleInstance = true;

    var
        OpenCount: Integer;
        LastDescr: Text;
        HandlerRuns: Integer;
        LastHandlerEditable: Boolean;
        LastHandlerDescr: Text;

    procedure Reset()
    begin
        OpenCount := 0;
        LastDescr := '';
        HandlerRuns := 0;
        LastHandlerEditable := false;
        LastHandlerDescr := '';
    end;

    // Called from the card's OnOpenPage: proves the card really opened, and on which row.
    procedure MarkOpened(CurrentDescr: Text)
    begin
        OpenCount += 1;
        LastDescr := CurrentDescr;
    end;

    procedure GetOpenCount(): Integer
    begin
        exit(OpenCount);
    end;

    procedure GetLastDescr(): Text
    begin
        exit(LastDescr);
    end;

    // Called from the test's [PageHandler]: proves the platform looked a handler up and ran
    // it, and carries out what the handler could see about the page it was handed. A handler
    // cannot assert after the fact -- it is gone by the time the test resumes -- so what it
    // observed has to be recorded here.
    procedure MarkHandled(Editable: Boolean; CurrentDescr: Text)
    begin
        HandlerRuns += 1;
        LastHandlerEditable := Editable;
        LastHandlerDescr := CurrentDescr;
    end;

    procedure GetHandlerRuns(): Integer
    begin
        exit(HandlerRuns);
    end;

    procedure GetLastHandlerEditable(): Boolean
    begin
        exit(LastHandlerEditable);
    end;

    procedure GetLastHandlerDescr(): Text
    begin
        exit(LastHandlerDescr);
    end;
}

page 60458 "TPVE Card"
{
    PageType = Card;
    SourceTable = "TPVE Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
            field(Descr; Rec.Descr)
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    var
        Probe: Codeunit "TPVE Open Probe";
    begin
        Probe.MarkOpened(Rec.Descr);
    end;
}

// The subject. CardPageId is the whole declaration under test: it is what the built-in View
// and Edit actions open, and there is no AL anywhere on this page.
page 60459 "TPVE List"
{
    PageType = List;
    SourceTable = "TPVE Row";
    CardPageId = "TPVE Card";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
