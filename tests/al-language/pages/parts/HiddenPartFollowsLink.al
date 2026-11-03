// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sublink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: A part with Visible = false and a SubPageLink: does it follow the host row (assumption hidden-part-follows-link); the visible twin part as the comparison. Risky: reading a hidden part from a TestPage may raise.
// BC versions: 29 (27 and 28 by CI)

table 70386 "LT HPart Host"
{
    fields
    {
        field(1; "Key"; Code[10]) { }
        field(2; "Name"; Text[30]) { }
    }
    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

table 70387 "LT HPart Line"
{
    fields
    {
        field(1; "Key"; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Text"; Text[30]) { }
    }
    keys
    {
        key(PK; "Key", "Line No.") { Clustered = true; }
    }
}

page 70388 "LT HPart Lines"
{
    PageType = ListPart;
    SourceTable = "LT HPart Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Text"; Rec."Text") { ApplicationArea = All; }
            }
        }
    }
}

page 70389 "LT HPart Host List"
{
    PageType = List;
    SourceTable = "LT HPart Host";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Key"; Rec."Key") { ApplicationArea = All; }
                field("Name"; Rec."Name") { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Hidden; "LT HPart Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Key" = field("Key");
                Visible = ShowHidden;
            }
            part(Shown; "LT HPart Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Key" = field("Key");
                Visible = ShowShown;
            }
        }
    }

    var
        ShowHidden: Boolean;
        ShowShown: Boolean;

    trigger OnOpenPage()
    begin
        ShowHidden := false;
        ShowShown := true;
    end;
}

codeunit 70390 "LT HPart Follows Link"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Host: Record "LT HPart Host";
        Line: Record "LT HPart Line";
    begin
        Host.DeleteAll();
        Line.DeleteAll();
        AddHost('H1');
        AddHost('H2');
        AddLine('H1', 10, 'h1 first');
        AddLine('H1', 20, 'h1 second');
        AddLine('H2', 10, 'h2 first');
        AddLine('H2', 20, 'h2 second');
    end;

    local procedure AddHost(K: Code[10])
    var
        Host: Record "LT HPart Host";
    begin
        Host."Key" := K;
        Host.Name := 'Host ' + K;
        Host.Insert();
    end;

    local procedure AddLine(K: Code[10]; LineNo: Integer; T: Text[30])
    var
        Line: Record "LT HPart Line";
    begin
        Line."Key" := K;
        Line."Line No." := LineNo;
        Line."Text" := T;
        Line.Insert();
    end;

    [Test]
    procedure VisiblePart_FollowsHostRow_Result()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT HPart Host List";
    begin
        Seed();
        Host.OpenView();
        Host.First();
        Observer.Observe('shown_h1_first', Host.Shown."Text".Value());
        Host.Next();
        Observer.Observe('shown_h2_first', Host.Shown."Text".Value());
        Observer.Observe('shown_h2_line', Host.Shown."Line No.".Value());
        Host.Close();
        Observer.Expect('shown_h1_first', 'h1 first');
        Observer.Expect('shown_h2_first', 'h2 first');
        Observer.Expect('shown_h2_line', '10');
        Observer.Verify();
    end;
}
