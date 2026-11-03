// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 74966 and 74967, pages 74968 and 74969, test codeunit 74970
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: which rows of a list part show for SubPageLink with const(''), filter(''), field(host field) and the same on a non-key field, with the host record's field blank and not blank.
// BC versions: 29 (27 and 28 by CI)

table 74966 "LT SP Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Zone; Code[10]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 74967 "LT SP Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Header No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Zone; Code[10]) { }
    }

    keys { key(PK; "Header No.", "Line No.") { Clustered = true; } }
}

page 74968 "LT SP Lines Part"
{
    PageType = ListPart;
    SourceTable = "LT SP Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }
}

page 74969 "LT SP Card"
{
    PageType = Card;
    SourceTable = "LT SP Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Zone; Rec.Zone) { ApplicationArea = All; }
            part(KeyConst; "LT SP Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = const('');
            }
            part(KeyFilter; "LT SP Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = filter('');
            }
            part(KeyField; "LT SP Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
            part(ZoneConst; "LT SP Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = Zone = const('');
            }
            part(ZoneFilter; "LT SP Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = Zone = filter('');
            }
            part(ZoneField; "LT SP Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = Zone = field(Zone);
            }
        }
    }
}

codeunit 74970 "LT SubPageLink Empty Term"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        H: Record "LT SP Header";
        L: Record "LT SP Line";
    begin
        H.DeleteAll();
        L.DeleteAll();
        H."No." := ''; H.Zone := ''; H.Insert();
        H."No." := 'A'; H.Zone := 'Z1'; H.Insert();
        H."No." := 'B'; H.Zone := ''; H.Insert();
        AddLine('', 1, '');
        AddLine('', 2, 'Z1');
        AddLine('A', 3, '');
        AddLine('A', 4, 'Z1');
        AddLine('B', 5, 'Z2');
        AddLine('B', 6, '');
    end;

    local procedure AddLine(HeaderNo: Code[10]; LineNo: Integer; Zone: Code[10])
    var
        L: Record "LT SP Line";
    begin
        L."Header No." := HeaderNo;
        L."Line No." := LineNo;
        L.Zone := Zone;
        L.Insert();
    end;

    local procedure RowsKeyConst(var Card: TestPage "LT SP Card"): Text
    var
        Result: Text;
    begin
        if not Card.KeyConst.First() then
            exit('none');
        repeat
            Result += Card.KeyConst.LineNo.Value + ',';
        until not Card.KeyConst.Next();
        exit(Result);
    end;

    local procedure RowsKeyFilter(var Card: TestPage "LT SP Card"): Text
    var
        Result: Text;
    begin
        if not Card.KeyFilter.First() then
            exit('none');
        repeat
            Result += Card.KeyFilter.LineNo.Value + ',';
        until not Card.KeyFilter.Next();
        exit(Result);
    end;

    local procedure RowsKeyField(var Card: TestPage "LT SP Card"): Text
    var
        Result: Text;
    begin
        if not Card.KeyField.First() then
            exit('none');
        repeat
            Result += Card.KeyField.LineNo.Value + ',';
        until not Card.KeyField.Next();
        exit(Result);
    end;

    local procedure RowsZoneConst(var Card: TestPage "LT SP Card"): Text
    var
        Result: Text;
    begin
        if not Card.ZoneConst.First() then
            exit('none');
        repeat
            Result += Card.ZoneConst.LineNo.Value + ',';
        until not Card.ZoneConst.Next();
        exit(Result);
    end;

    local procedure RowsZoneFilter(var Card: TestPage "LT SP Card"): Text
    var
        Result: Text;
    begin
        if not Card.ZoneFilter.First() then
            exit('none');
        repeat
            Result += Card.ZoneFilter.LineNo.Value + ',';
        until not Card.ZoneFilter.Next();
        exit(Result);
    end;

    local procedure RowsZoneField(var Card: TestPage "LT SP Card"): Text
    var
        Result: Text;
    begin
        if not Card.ZoneField.First() then
            exit('none');
        repeat
            Result += Card.ZoneField.LineNo.Value + ',';
        until not Card.ZoneField.Next();
        exit(Result);
    end;

    local procedure ProbeHost(HostNo: Code[10]; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        H: Record "LT SP Header";
        Card: TestPage "LT SP Card";
    begin
        H.Get(HostNo);
        Card.OpenView();
        Card.GoToRecord(H);
        Observer.Observe(Prefix + '_key_const', RowsKeyConst(Card));
        Observer.Observe(Prefix + '_key_filter', RowsKeyFilter(Card));
        Observer.Observe(Prefix + '_key_field', RowsKeyField(Card));
        Observer.Observe(Prefix + '_zone_const', RowsZoneConst(Card));
        Observer.Observe(Prefix + '_zone_filter', RowsZoneFilter(Card));
        Observer.Observe(Prefix + '_zone_field', RowsZoneField(Card));
        Card.Close();
    end;

    [Test]
    procedure SubPageLink_EmptyTerm_HostBlankKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ProbeHost('', 'blank_host', Observer);
        Observer.Expect('blank_host_key_const', '1,2,');
        Observer.Expect('blank_host_key_filter', '1,2,');
        Observer.Expect('blank_host_key_field', '1,2,');
        Observer.Expect('blank_host_zone_const', '1,3,6,');
        Observer.Expect('blank_host_zone_filter', '1,3,6,');
        Observer.Expect('blank_host_zone_field', '1,3,6,');
        Observer.Verify();
    end;

    [Test]
    procedure SubPageLink_EmptyTerm_HostFilledKeyBlankZone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ProbeHost('B', 'b_host', Observer);
        Observer.Expect('b_host_key_const', '1,2,');
        Observer.Expect('b_host_key_filter', '1,2,');
        Observer.Expect('b_host_key_field', '5,6,');
        Observer.Expect('b_host_zone_const', '1,3,6,');
        Observer.Expect('b_host_zone_filter', '1,3,6,');
        Observer.Expect('b_host_zone_field', '1,3,6,');
        Observer.Verify();
    end;

    [Test]
    procedure SubPageLink_EmptyTerm_HostFilledKeyFilledZone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ProbeHost('A', 'a_host', Observer);
        Observer.Expect('a_host_key_const', '1,2,');
        Observer.Expect('a_host_key_filter', '1,2,');
        Observer.Expect('a_host_key_field', '3,4,');
        Observer.Expect('a_host_zone_const', '1,3,6,');
        Observer.Expect('a_host_zone_filter', '1,3,6,');
        Observer.Expect('a_host_zone_field', '2,4,');
        Observer.Verify();
    end;
}
