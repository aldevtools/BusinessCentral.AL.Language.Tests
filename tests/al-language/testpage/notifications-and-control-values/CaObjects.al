// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures for the probes of corpus issue 667 (odd AL behavior leads, part B: pages), items 1 to 16 (writer CA):
// table 84100, log codeunits 84101 (CaTestPageTests.al only) and 84102 (CaNotificationTests.al only), pages 84100-84103. The tests are in CaTestPageTests.al (84110) and CaNotificationTests.al (84111).

table 84100 "LT CA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { Caption = 'LT CA Name Caption'; }
        field(3; Amt; Decimal) { }
        field(4; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 84101 "LT CA Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        R: Text;
    begin
        R := Entries;
        Entries := '';
        exit(R);
    end;
}

page 84100 "LT CA Card"
{
    PageType = Card;
    SourceTable = "LT CA Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(AmtBlankZero; Rec.Amt) { ApplicationArea = All; BlankZero = true; }
            field(AmtPlain; Rec.Amt) { ApplicationArea = All; }
            field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DialogLocal)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT CA Log";
                    LocalWindow: Dialog;
                begin
                    Log.Add('local:gui=' + Format(GuiAllowed()));
                    LocalWindow.Open('Step #1####');
                    LocalWindow.Update(1, 5);
                    LocalWindow.Close();
                    Log.Add('local:done');
                end;
            }
            action(DialogGlobal)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT CA Log";
                begin
                    Log.Add('global:gui=' + Format(GuiAllowed()));
                    GlobalWindow.Open('Step #1####');
                    GlobalWindow.Update(1, 5);
                    GlobalWindow.Close();
                    Log.Add('global:done');
                end;
            }
            action(DialogGlobalLeftOpen)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT CA Log";
                begin
                    GlobalWindow.Open('Step #1####');
                    GlobalWindow.Update(1, 7);
                    Log.Add('open-left:done');
                end;
            }
        }
    }

    var
        GlobalWindow: Dialog;
}

page 84101 "LT CA List"
{
    PageType = List;
    SourceTable = "LT CA Row";
    ApplicationArea = All;
    UsageCategory = None;
    CardPageId = "LT CA Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 84102 "LT CA Editable List"
{
    PageType = List;
    SourceTable = "LT CA Row";
    ApplicationArea = All;
    UsageCategory = None;
    CardPageId = "LT CA Card";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 84103 "LT CA Role Center"
{
    PageType = RoleCenter;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT CA Role Center Caption';

    actions
    {
        area(Processing)
        {
            action(RcAction)
            {
                ApplicationArea = All;
                Caption = 'LT CA RC Action';
                RunObject = page "LT CA List";
            }
        }
    }
}

// The log of CaNotificationTests.al (84111) only: a SingleInstance codeunit has one owner test codeunit.
codeunit 84102 "LT CA Notif Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        R: Text;
    begin
        R := Entries;
        Entries := '';
        exit(R);
    end;
}
