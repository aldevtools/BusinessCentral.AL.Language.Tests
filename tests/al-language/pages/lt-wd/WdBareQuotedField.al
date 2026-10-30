// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-controls
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 90770-90775
// Probe: written against al-runner issue 6314. A page field whose source is a bare quoted field name with a space (field(X; "Profile Name"), no Rec., warning AL0604), on a page and in a page extension,
//        compared with a bare one-word name: the control's Value, Editable() with an Editable expression, SetValue writing the field, and the same through a TestPage opened in view mode.
//        Every value asserted below is what the BC service tier produced.
// BC versions: 27, 28, 29

table 90770 "LT WD Document"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Profile Name"; Text[50]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

tableextension 90771 "LT WD Document Ext" extends "LT WD Document"
{
    fields
    {
        field(90771; "LT WD Profile Code"; Code[20]) { }
    }
}

#pragma warning disable AL0604
page 90772 "LT WD Documents"
{
    PageType = List;
    SourceTable = "LT WD Document";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { }
                field(ProfileName; "Profile Name") { Editable = LineEditable; }
                field(AmountCtl; Amount) { Editable = LineEditable; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LineEditable := Rec."No." = 'D1';
    end;

    var
        LineEditable: Boolean;
}

page 90773 "LT WD Document Card"
{
    PageType = Card;
    SourceTable = "LT WD Document";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { }
            }
        }
    }
}

pageextension 90774 "LT WD Document Card Ext" extends "LT WD Document Card"
{
    layout
    {
        addlast(General)
        {
            field("LT WD Profile"; "LT WD Profile Code") { }
        }
    }
}
#pragma warning restore AL0604

codeunit 90775 "LT WD Bare Quoted Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        Doc: Record "LT WD Document";
    begin
        Doc.DeleteAll();
        Doc."No." := 'D1';
        Doc."Profile Name" := 'Profile 1';
        Doc.Amount := 5;
        Doc."LT WD Profile Code" := 'P1';
        Doc.Insert();
        Doc."No." := 'D2';
        Doc."Profile Name" := 'Profile 2';
        Doc.Amount := 7;
        Doc."LT WD Profile Code" := 'P2';
        Doc.Insert();
    end;

    [Test]
    procedure WD_BareName_OnAPage_ValueAndEditable()
    var
        Observer: Codeunit "Probe Observer";
        Docs: TestPage "LT WD Documents";
    begin
        Setup();
        Docs.OpenEdit();
        Docs.First();
        Observer.Observe('D1 quoted name: value', Docs.ProfileName.Value());
        Observer.Observe('D1 quoted name: editable', Format(Docs.ProfileName.Editable()));
        Observer.Observe('D1 one word: value', Docs.AmountCtl.Value());
        Observer.Observe('D1 one word: editable', Format(Docs.AmountCtl.Editable()));
        Docs.Next();
        Observer.Observe('D2 quoted name: value', Docs.ProfileName.Value());
        Observer.Observe('D2 quoted name: editable', Format(Docs.ProfileName.Editable()));
        Observer.Observe('D2 one word: value', Docs.AmountCtl.Value());
        Observer.Observe('D2 one word: editable', Format(Docs.AmountCtl.Editable()));
        Docs.Close();
        Observer.Finish();
    end;

    [Test]
    procedure WD_BareName_OnAPage_SetValueWritesTheField()
    var
        Observer: Codeunit "Probe Observer";
        Doc: Record "LT WD Document";
        Docs: TestPage "LT WD Documents";
    begin
        Setup();
        Docs.OpenEdit();
        Docs.First();
        Docs.ProfileName.SetValue('Changed');
        Observer.Observe('value after SetValue', Docs.ProfileName.Value());
        Docs.Next();
        Docs.First();
        Doc.Get('D1');
        Observer.Observe('stored field', Doc."Profile Name");
        Docs.Close();
        Observer.Finish();
    end;

    [Test]
    procedure WD_BareName_InAPageExtension()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT WD Document Card";
    begin
        Setup();
        Card.OpenView();
        Card.First();
        Observer.Observe('D1 value', Card."LT WD Profile".Value());
        Observer.Observe('D1 editable', Format(Card."LT WD Profile".Editable()));
        Card.Next();
        Observer.Observe('D2 value', Card."LT WD Profile".Value());
        Card.Close();
        Card.OpenEdit();
        Card.First();
        Observer.Observe('edit mode editable', Format(Card."LT WD Profile".Editable()));
        Card.Close();
        Observer.Finish();
    end;
}
