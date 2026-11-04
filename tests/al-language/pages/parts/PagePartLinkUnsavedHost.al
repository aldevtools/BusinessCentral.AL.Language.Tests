// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), own tables 71247-71250, pages 71251-71253
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a card (ListPlus style) opened with TestPage.OpenNew whose two list parts are linked on the card's key (SubPageLink "X" = field(Code)).
//   Part 1 links a field that has a TableRelation to the host table itself, part 2 a field that has a TableRelation to an unrelated Group table.
//   Typing the key into the new host before saving: is the part's link field validated against its TableRelation at that moment (errors, rows
//   seen in the parts) or only when the host row is inserted / the part writes a line? Contrast: OpenEdit on an existing host.
//   Existing pins: handlers/TestPageOpenNewPartLink.al (key typed, line written; no TableRelation on the link field).
// BC versions: 29 (27 and 28 by CI)

table 71247 "LT PLK Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Descr; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 71248 "LT PLK Group"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 71249 "LT PLK Line H"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Host Code"; Code[10]) { TableRelation = "LT PLK Host"."Code"; }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[30]) { }
    }

    keys { key(PK; "Host Code", "Line No.") { Clustered = true; } }
}

table 71250 "LT PLK Line G"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Group Code"; Code[10]) { TableRelation = "LT PLK Group"."Code"; }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[30]) { }
    }

    keys { key(PK; "Group Code", "Line No.") { Clustered = true; } }
}

page 71251 "LT PLK Lines H"
{
    PageType = ListPart;
    SourceTable = "LT PLK Line H";
    ApplicationArea = All;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 71252 "LT PLK Lines G"
{
    PageType = ListPart;
    SourceTable = "LT PLK Line G";
    ApplicationArea = All;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 71253 "LT PLK Card"
{
    PageType = Card;
    SourceTable = "LT PLK Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec.Code) { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
            part(LinesH; "LT PLK Lines H")
            {
                ApplicationArea = All;
                SubPageLink = "Host Code" = field(Code);
            }
            part(LinesG; "LT PLK Lines G")
            {
                ApplicationArea = All;
                SubPageLink = "Group Code" = field(Code);
            }
        }
    }
}

// Writer PY-B (2026-10-20): the same card with one linked part and with no part, for contrast (pages 85191, 85192).
page 85191 "LT PYB PLK Card One"
{
    PageType = Card;
    SourceTable = "LT PLK Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec.Code) { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
            part(LinesG; "LT PLK Lines G")
            {
                ApplicationArea = All;
                SubPageLink = "Group Code" = field(Code);
            }
        }
    }
}

page 85192 "LT PYB PLK Card None"
{
    PageType = Card;
    SourceTable = "LT PLK Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec.Code) { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
        }
    }
}

codeunit 71254 "LT Part Link Unsaved Host"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Host: Record "LT PLK Host";
        Group: Record "LT PLK Group";
        LineH: Record "LT PLK Line H";
        LineG: Record "LT PLK Line G";
    begin
        LineH.DeleteAll();
        LineG.DeleteAll();
        Host.DeleteAll();
        Group.DeleteAll();
        Group.Code := 'G1';
        Group.Insert();
    end;

    local procedure ObserveDb(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Host: Record "LT PLK Host";
        LineH: Record "LT PLK Line H";
        LineG: Record "LT PLK Line G";
    begin
        Observer.Observe(Prefix + 'hosts', Format(Host.Count()));
        Observer.Observe(Prefix + 'lines_h', Format(LineH.Count()));
        Observer.Observe(Prefix + 'lines_g', Format(LineG.Count()));
    end;

    [Test]
    procedure P174_OpenNew_KeyWithGroup_PartsAfterKey()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PLK Card";
    begin
        Seed();
        Card.OpenNew();
        Observer.Observe('before_h_first', Format(Card.LinesH.First()));
        Observer.Observe('before_g_first', Format(Card.LinesG.First()));
        Card.Code.SetValue('G1');
        ObserveDb(Observer, 'a_');
        Observer.Observe('after_code', Card.Code.Value());
        Observer.Observe('after_h_first', Format(Card.LinesH.First()));
        Observer.Observe('after_g_first', Format(Card.LinesG.First()));
        Observer.Expect('before_h_first', 'No');
        Observer.Expect('before_g_first', 'No');
        Observer.Expect('a_hosts', '1');
        Observer.Expect('a_lines_h', '0');
        Observer.Expect('a_lines_g', '0');
        Observer.Expect('after_code', '');
        Observer.Expect('after_h_first', 'No');
        Observer.Expect('after_g_first', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P174_OpenNew_KeyWithGroup_ThenWritePartG()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PLK Card";
        LineG: Record "LT PLK Line G";
    begin
        Seed();
        Card.OpenNew();
        Card.Code.SetValue('G1');
        Card.LinesG.Descr.SetValue('typed');
        ObserveDb(Observer, 'a_');
        if LineG.FindFirst() then
            Observer.Observe('line_g_key', LineG."Group Code" + '|' + Format(LineG."Line No.") + '|' + LineG.Descr);
        Observer.Expect('a_hosts', '1');
        Observer.Expect('a_lines_h', '0');
        Observer.Expect('a_lines_g', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P174_OpenNew_KeyThenClose_WithoutOtherField()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PLK Card";
    begin
        Seed();
        Card.OpenNew();
        Card.Code.SetValue('G1');
        Card.Close();
        ObserveDb(Observer, 'a_');
        Observer.Expect('a_hosts', '1');
        Observer.Expect('a_lines_h', '0');
        Observer.Expect('a_lines_g', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P174_OpenEdit_ExistingHostWithGroup_Parts()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PLK Card";
        Host: Record "LT PLK Host";
    begin
        Seed();
        Host.Code := 'G1';
        Host.Insert();
        Card.OpenEdit();
        Observer.Observe('goto', Format(Card.GoToKey('G1')));
        Card.LinesG.Descr.SetValue('typed');
        Card.LinesH.Descr.SetValue('typed');
        ObserveDb(Observer, 'a_');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('a_hosts', '1');
        Observer.Expect('a_lines_h', '0');
        Observer.Expect('a_lines_g', '1');
        Observer.Verify();
    end;

    local procedure CountHosts(): Integer
    var
        Host: Record "LT PLK Host";
    begin
        exit(Host.Count());
    end;

    // Writer PY-B (2026-10-20): what a new card shows and stores after its key is typed, with two linked parts, one, or none.
    // Rule seen: typing the key alone inserts nothing; the card shows the key and the parts filter on it; the row is inserted with the key
    // when the next host field is typed. The same with 0, 1 or 2 parts and for a key missing from the Group table. If the host row was
    // already inserted with a blank key (a non-key field typed, or a part touched: TestPart.First()), the key typed later is lost: the card
    // shows blank and the row keeps the blank key (this is what P174_OpenNew_KeyWithGroup_PartsAfterKey reads).
    local procedure HostRows(): Text
    var
        Host: Record "LT PLK Host";
        Rows: Text;
    begin
        if Host.FindSet() then
            repeat
                Rows += '[' + Host.Code + '|' + Host.Descr + ']';
            until Host.Next() = 0;
        exit(Format(Host.Count()) + ' ' + Rows);
    end;

    [TryFunction]
    local procedure TryCode2(var Card: TestPage "LT PLK Card"; Value: Text)
    begin
        Card.Code.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryDescr2(var Card: TestPage "LT PLK Card"; Value: Text)
    begin
        Card.Descr.SetValue(Value);
    end;

    local procedure Ok(var Observer: Codeunit "Probe Observer"; Name: Text; Done: Boolean)
    begin
        if Done then
            Observer.Observe(Name, 'ok')
        else
            Observer.Observe(Name, 'E[' + GetLastErrorText() + '|' + GetLastErrorCode() + ']');
        ClearLastError();
    end;

    [Test]
    procedure PYB_TwoParts_KeyTyped_WhatIsShownAndStored()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PLK Card";
    begin
        Seed();
        Card.OpenNew();
        Ok(Observer, 'code', TryCode2(Card, 'G1'));
        Observer.Observe('db_after_code', HostRows());
        Observer.Observe('code_value', '[' + Card.Code.Value() + ']');
        Observer.Observe('descr_value', '[' + Card.Descr.Value() + ']');
        Observer.Observe('h_filter', '[' + Card.LinesH.Filter.GetFilter("Host Code") + ']');
        Observer.Observe('g_filter', '[' + Card.LinesG.Filter.GetFilter("Group Code") + ']');
        Ok(Observer, 'descr', TryDescr2(Card, 'd1'));
        Observer.Observe('db_after_descr', HostRows());
        Observer.Observe('code_value_after_descr', '[' + Card.Code.Value() + ']');
        Card.Close();
        Observer.Observe('db_after_close', HostRows());
        Observer.Expect('code', 'ok');
        Observer.Expect('db_after_code', '0 ');
        Observer.Expect('code_value', '[G1]');
        Observer.Expect('descr_value', '[]');
        Observer.Expect('h_filter', '[G1]');
        Observer.Expect('g_filter', '[G1]');
        Observer.Expect('descr', 'ok');
        Observer.Expect('db_after_descr', '1 [G1|]');
        Observer.Expect('code_value_after_descr', '[G1]');
        Observer.Expect('db_after_close', '1 [G1|d1]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_TwoParts_KeyNotInGroupTable()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PLK Card";
    begin
        Seed();
        Card.OpenNew();
        Ok(Observer, 'code', TryCode2(Card, 'X1'));
        Observer.Observe('db_after_code', HostRows());
        Observer.Observe('code_value', '[' + Card.Code.Value() + ']');
        Card.Close();
        Observer.Observe('db_after_close', HostRows());
        Observer.Expect('code', 'ok');
        Observer.Expect('db_after_code', '0 ');
        Observer.Expect('code_value', '[X1]');
        Observer.Expect('db_after_close', '1 [X1|]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_TwoParts_DescrFirstThenKey()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PLK Card";
    begin
        Seed();
        Card.OpenNew();
        Ok(Observer, 'descr', TryDescr2(Card, 'd1'));
        Observer.Observe('db_after_descr', HostRows());
        Ok(Observer, 'code', TryCode2(Card, 'G1'));
        Observer.Observe('db_after_code', HostRows());
        Observer.Observe('code_value', '[' + Card.Code.Value() + ']');
        Card.Close();
        Observer.Observe('db_after_close', HostRows());
        Observer.Expect('descr', 'ok');
        Observer.Expect('db_after_descr', '1 [|]');
        Observer.Expect('code', 'ok');
        Observer.Expect('db_after_code', '1 [|]');
        Observer.Expect('code_value', '[]');
        Observer.Expect('db_after_close', '1 [|d1]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_OnePart_KeyTyped()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PYB PLK Card One";
    begin
        Seed();
        Card.OpenNew();
        Card.Code.SetValue('G1');
        Observer.Observe('db_after_code', HostRows());
        Observer.Observe('code_value', '[' + Card.Code.Value() + ']');
        Observer.Observe('g_filter', '[' + Card.LinesG.Filter.GetFilter("Group Code") + ']');
        Card.Descr.SetValue('d1');
        Observer.Observe('db_after_descr', HostRows());
        Observer.Observe('code_value_after_descr', '[' + Card.Code.Value() + ']');
        Card.Close();
        Observer.Observe('db_after_close', HostRows());
        Observer.Expect('db_after_code', '0 ');
        Observer.Expect('code_value', '[G1]');
        Observer.Expect('g_filter', '[G1]');
        Observer.Expect('db_after_descr', '1 [G1|]');
        Observer.Expect('code_value_after_descr', '[G1]');
        Observer.Expect('db_after_close', '1 [G1|d1]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_NoPart_KeyTyped()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PYB PLK Card None";
    begin
        Seed();
        Card.OpenNew();
        Card.Code.SetValue('G1');
        Observer.Observe('db_after_code', HostRows());
        Observer.Observe('code_value', '[' + Card.Code.Value() + ']');
        Card.Descr.SetValue('d1');
        Observer.Observe('db_after_descr', HostRows());
        Observer.Observe('code_value_after_descr', '[' + Card.Code.Value() + ']');
        Card.Close();
        Observer.Observe('db_after_close', HostRows());
        Observer.Expect('db_after_code', '0 ');
        Observer.Expect('code_value', '[G1]');
        Observer.Expect('db_after_descr', '1 [G1|]');
        Observer.Expect('code_value_after_descr', '[G1]');
        Observer.Expect('db_after_close', '1 [G1|d1]');
        Observer.Verify();
    end;


    [Test]
    procedure PYB_TwoParts_PartFirstThenKey()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PLK Card";
    begin
        Seed();
        Card.OpenNew();
        Observer.Observe('h_first', Format(Card.LinesH.First()));
        Observer.Observe('db_after_first', HostRows());
        Card.Code.SetValue('G1');
        Observer.Observe('db_after_code', HostRows());
        Observer.Observe('code_value', '[' + Card.Code.Value() + ']');
        Card.Close();
        Observer.Observe('db_after_close', HostRows());
        Observer.Expect('h_first', 'No');
        Observer.Expect('db_after_first', '1 [|]');
        Observer.Expect('db_after_code', '1 [|]');
        Observer.Expect('code_value', '[]');
        Observer.Expect('db_after_close', '1 [|]');
        Observer.Verify();
    end;

    [Test]
    procedure PYB_NoPart_DescrFirstThenKey()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PYB PLK Card None";
    begin
        Seed();
        Card.OpenNew();
        Card.Descr.SetValue('d1');
        Observer.Observe('db_after_descr', HostRows());
        Card.Code.SetValue('G1');
        Observer.Observe('db_after_code', HostRows());
        Observer.Observe('code_value', '[' + Card.Code.Value() + ']');
        Card.Close();
        Observer.Observe('db_after_close', HostRows());
        Observer.Expect('db_after_descr', '1 [|]');
        Observer.Expect('db_after_code', '1 [|]');
        Observer.Expect('code_value', '[]');
        Observer.Expect('db_after_close', '1 [|d1]');
        Observer.Verify();
    end;

}
