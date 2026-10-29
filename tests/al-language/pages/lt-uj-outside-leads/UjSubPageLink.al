// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90392 - 90396, 90403 (writer UJ)
// Probe: SubPageLink with const and a qualified enum value ("Enum"::Value) on a card with three parts of one list part page. Part 1 links a
//   key field that has the same name as its enum type ("LT UJ Src" of enum "LT UJ Src") to const("LT UJ Src"::Resource); part 2 links the same
//   field to the unqualified const(Header); part 3 links a field with another name ("Alt Src") to const("LT UJ Src"::Item). Does it compile,
//   which rows does each part show, which value does a new row in each part get.
// Source: al-runner issue 6181 ("SubPageLink const with a qualified enum value is refused: is not a member of the enum").
// BC versions: 27, 28, 29

enum 90392 "LT UJ Src"
{
    Extensible = true;

    value(0; Resource) { }
    value(1; Header) { }
    value(2; Item) { }
}

table 90393 "LT UJ Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 90394 "LT UJ Filter Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Setup Code"; Code[10]) { }
        field(2; "LT UJ Src"; Enum "LT UJ Src") { }
        field(3; "Line No."; Integer) { }
        field(4; Description; Text[30]) { }
        field(5; "Alt Src"; Enum "LT UJ Src") { }
    }

    keys
    {
        key(PK; "Setup Code", "LT UJ Src", "Line No.") { Clustered = true; }
    }
}

page 90395 "LT UJ Filter Part"
{
    PageType = ListPart;
    SourceTable = "LT UJ Filter Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(SrcCtl; Rec."LT UJ Src") { }
                field(LineNoCtl; Rec."Line No.") { }
                field(DescriptionCtl; Rec.Description) { }
                field(AltSrcCtl; Rec."Alt Src") { }
            }
        }
    }
}

page 90396 "LT UJ Setup Card"
{
    PageType = Card;
    SourceTable = "LT UJ Setup";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { }
            part(ResourceLines; "LT UJ Filter Part")
            {
                SubPageLink = "Setup Code" = field("Code"), "LT UJ Src" = const("LT UJ Src"::Resource);
            }
            part(HeaderLines; "LT UJ Filter Part")
            {
                SubPageLink = "Setup Code" = field("Code"), "LT UJ Src" = const(Header);
            }
            part(AltItemLines; "LT UJ Filter Part")
            {
                SubPageLink = "Setup Code" = field("Code"), "Alt Src" = const("LT UJ Src"::Item);
            }
        }
    }
}

codeunit 90403 "LT UJ SubPageLink Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Setup: Record "LT UJ Setup";
        Line: Record "LT UJ Filter Line";
    begin
        Line.DeleteAll();
        Setup.DeleteAll();
        Setup.Code := 'S1';
        Setup.Insert();
        AddLine('S1', "LT UJ Src"::Resource, 1, 'res one', "LT UJ Src"::Resource);
        AddLine('S1', "LT UJ Src"::Resource, 2, 'res two', "LT UJ Src"::Item);
        AddLine('S1', "LT UJ Src"::Header, 1, 'head one', "LT UJ Src"::Item);
        AddLine('S1', "LT UJ Src"::Item, 1, 'item one', "LT UJ Src"::Item);
        AddLine('S2', "LT UJ Src"::Resource, 1, 'other setup', "LT UJ Src"::Item);
    end;

    local procedure AddLine(SetupCode: Code[10]; Src: Enum "LT UJ Src"; LineNo: Integer; Descr: Text[30]; Alt: Enum "LT UJ Src")
    var
        Line: Record "LT UJ Filter Line";
    begin
        Line."Setup Code" := SetupCode;
        Line."LT UJ Src" := Src;
        Line."Line No." := LineNo;
        Line.Description := Descr;
        Line."Alt Src" := Alt;
        Line.Insert();
    end;

    local procedure ResourceRows(var Card: TestPage "LT UJ Setup Card"): Text
    var
        Result: Text;
        More: Boolean;
    begin
        More := Card.ResourceLines.First();
        while More do begin
            Result += Card.ResourceLines.SrcCtl.Value() + '/' + Card.ResourceLines.LineNoCtl.Value() + '/' + Card.ResourceLines.DescriptionCtl.Value() + ',';
            More := Card.ResourceLines.Next();
        end;
        exit(Result);
    end;

    local procedure HeaderRows(var Card: TestPage "LT UJ Setup Card"): Text
    var
        Result: Text;
        More: Boolean;
    begin
        More := Card.HeaderLines.First();
        while More do begin
            Result += Card.HeaderLines.SrcCtl.Value() + '/' + Card.HeaderLines.LineNoCtl.Value() + '/' + Card.HeaderLines.DescriptionCtl.Value() + ',';
            More := Card.HeaderLines.Next();
        end;
        exit(Result);
    end;

    local procedure AltRows(var Card: TestPage "LT UJ Setup Card"): Text
    var
        Result: Text;
        More: Boolean;
    begin
        More := Card.AltItemLines.First();
        while More do begin
            Result += Card.AltItemLines.SrcCtl.Value() + '/' + Card.AltItemLines.LineNoCtl.Value() + '/' + Card.AltItemLines.DescriptionCtl.Value() + ',';
            More := Card.AltItemLines.Next();
        end;
        exit(Result);
    end;

    local procedure Stored(): Text
    var
        Line: Record "LT UJ Filter Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Setup Code" + ':' + Format(Line."LT UJ Src") + ':' + Format(Line."Line No.") + ':' + Format(Line."Alt Src") + ',';
            until Line.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure UJ_SubPageLink_ConstEnum_Rows()
    var
        Card: TestPage "LT UJ Setup Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('qualified, field named like the enum', ResourceRows(Card));
        Observer.Observe('unqualified, field named like the enum', HeaderRows(Card));
        Observer.Observe('qualified, other field name', AltRows(Card));
        Card.Close();
        Observer.Expect('qualified, field named like the enum', 'Resource/1/res one,Resource/2/res two,');
        Observer.Expect('unqualified, field named like the enum', 'Header/1/head one,');
        Observer.Expect('qualified, other field name', 'Resource/2/res two,Header/1/head one,Item/1/item one,');
        Observer.Verify();
    end;

    [Test]
    procedure UJ_SubPageLink_ConstEnum_NewRow()
    var
        Card: TestPage "LT UJ Setup Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.ResourceLines.New();
        Observer.Observe('resource part new row shows', Card.ResourceLines.SrcCtl.Value() + '/' + Card.ResourceLines.AltSrcCtl.Value());
        Card.ResourceLines.LineNoCtl.SetValue(9);
        Card.HeaderLines.New();
        Observer.Observe('header part new row shows', Card.HeaderLines.SrcCtl.Value() + '/' + Card.HeaderLines.AltSrcCtl.Value());
        Card.HeaderLines.LineNoCtl.SetValue(9);
        Card.AltItemLines.New();
        Observer.Observe('alt part new row shows', Card.AltItemLines.SrcCtl.Value() + '/' + Card.AltItemLines.AltSrcCtl.Value());
        Card.AltItemLines.LineNoCtl.SetValue(29);
        Card.Close();
        Observer.Observe('stored', Stored());
        Observer.Expect('resource part new row shows', 'Resource/Resource');
        Observer.Expect('header part new row shows', 'Header/Resource');
        Observer.Expect('alt part new row shows', 'Resource/Resource');
        Observer.Expect('stored', 'S1:Resource:1:Resource,S1:Resource:2:Item,S1:Resource:9:Resource,S1:Resource:29:Resource,S1:Header:1:Item,S1:Header:9:Resource,S1:Item:1:Item,S2:Resource:1:Item,');
        Observer.Verify();
    end;
}
