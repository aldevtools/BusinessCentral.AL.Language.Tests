// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-edit-method
// Scope: in-scope
// Fixtures used: TPMS Row (60472), TPMS Open Probe (60473), TPMS Card (60474),
//                TPMS RO Card (60475), TPMS Plain List (60476), TPMS RO List (60477),
//                TPMS List (60478)
//
// Fixtures for the OTHER half of a page's built-in View and Edit actions. TPVE (60457-60461)
// pins what they do on a List that declares a CardPageId: a card opens. These pin what they do
// when no card opens at all -- the page already on screen changes mode in place -- and what
// Visible() and Enabled() answer on the two actions in each shape.
//
// Three cards and three lists, because the answer differs by shape:
//   * TPMS Card       -- an ordinary Card. The in-place switch subject.
//   * TPMS RO Card    -- a Card with Editable = false, as a switch target and as a card target.
//   * TPMS Plain List -- a List with NO CardPageId, so the actions have nothing to open.
//   * TPMS RO List    -- a List whose CardPageId card is read-only.
//   * TPMS List       -- a List with an editable CardPageId card (the TPVE shape, for the
//                        Visible/Enabled control).
//
// The probe counts opens in memory rather than in a table, for the reason TPVE Open Probe
// (60460) gives: a count is what separates "the page changed mode" from "a second copy of the
// page opened", and no single log row can say that.

table 60472 "TPMS Row"
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

codeunit 60473 "TPMS Open Probe"
{
    SingleInstance = true;

    var
        CardOpens: Integer;
        RoCardOpens: Integer;
        HandlerRuns: Integer;
        LastHandlerEditable: Boolean;
        Steps: Text;

    procedure Reset()
    begin
        CardOpens := 0;
        RoCardOpens := 0;
        HandlerRuns := 0;
        LastHandlerEditable := false;
        Steps := '';
    end;

    procedure MarkCardOpened()
    begin
        CardOpens += 1;
    end;

    procedure MarkRoCardOpened()
    begin
        RoCardOpens += 1;
    end;

    procedure GetCardOpens(): Integer
    begin
        exit(CardOpens);
    end;

    procedure GetRoCardOpens(): Integer
    begin
        exit(RoCardOpens);
    end;

    // Written from a [PageHandler]: a handler is gone by the time the test resumes, so what it
    // saw has to be recorded where the test can read it.
    procedure MarkHandled(Editable: Boolean)
    begin
        HandlerRuns += 1;
        LastHandlerEditable := Editable;
    end;

    procedure GetHandlerRuns(): Integer
    begin
        exit(HandlerRuns);
    end;

    procedure GetLastHandlerEditable(): Boolean
    begin
        exit(LastHandlerEditable);
    end;

    // A running log, for a handler that observes the same page more than once: three separate
    // "last value" fields could not say what order they happened in.
    procedure AddStep(Step: Text)
    begin
        if Steps <> '' then
            Steps += ';';
        Steps += Step;
    end;

    procedure GetSteps(): Text
    begin
        exit(Steps);
    end;
}

page 60474 "TPMS Card"
{
    PageType = Card;
    SourceTable = "TPMS Row";
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
        Probe: Codeunit "TPMS Open Probe";
    begin
        Probe.MarkCardOpened();
    end;
}

// Editable = false is the whole declaration under test here: it is what makes this card an
// unavailable Edit target, both for its own built-in Edit action and for a list that names it.
page 60475 "TPMS RO Card"
{
    PageType = Card;
    SourceTable = "TPMS Row";
    Editable = false;
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
        Probe: Codeunit "TPMS Open Probe";
    begin
        Probe.MarkRoCardOpened();
    end;
}

// No CardPageId. The built-in actions have no card to open.
page 60476 "TPMS Plain List"
{
    PageType = List;
    SourceTable = "TPMS Row";
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

page 60477 "TPMS RO List"
{
    PageType = List;
    SourceTable = "TPMS Row";
    CardPageId = "TPMS RO Card";
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

page 60478 "TPMS List"
{
    PageType = List;
    SourceTable = "TPMS Row";
    CardPageId = "TPMS Card";
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
