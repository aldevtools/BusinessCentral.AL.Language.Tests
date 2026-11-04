// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-objectid-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// Page.ObjectId(UseNames) (CurrPage.ObjectId in a trigger and the Page variable form): ObjectId(false) is "Page <id>"; ObjectId(true) is "Page <caption>" for a page with a Caption
// ("Page PR Oid caption") and "Page <name>" for a page without one ("Page PR Oid Plain Page").
// Fixtures used: self-contained table 69543, codeunit 69547 (log), pages 69545 and 69546, codeunit 69548 (tests)
// BC versions: 27.5

table 69543 "PR Oid Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69547 "PR Oid Log"
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
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 69545 "PR Oid Captioned Page"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'PR Oid caption';
    SourceTable = "PR Oid Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "PR Oid Log";
    begin
        Log.Add('captioned false=' + CurrPage.ObjectId(false) + ' true=' + CurrPage.ObjectId(true));
    end;
}

page 69546 "PR Oid Plain Page"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "PR Oid Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "PR Oid Log";
    begin
        Log.Add('plain false=' + CurrPage.ObjectId(false) + ' true=' + CurrPage.ObjectId(true));
    end;
}

codeunit 69548 "PR Oid Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CurrPage_ObjectId_InTriggers()
    var
        Captioned: TestPage "PR Oid Captioned Page";
        Plain: TestPage "PR Oid Plain Page";
        Log: Codeunit "PR Oid Log";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Captioned.OpenView();
        Captioned.Close();
        Plain.OpenView();
        Plain.Close();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'captioned false=Page 69545 true=Page PR Oid caption;plain false=Page 69546 true=Page PR Oid Plain Page;');
        Observer.Verify();
    end;

    [Test]
    procedure PageVariable_ObjectId()
    var
        Captioned: Page "PR Oid Captioned Page";
        Plain: Page "PR Oid Plain Page";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('captioned_false', Captioned.ObjectId(false));
        Observer.Observe('captioned_true', Captioned.ObjectId(true));
        Observer.Observe('plain_false', Plain.ObjectId(false));
        Observer.Observe('plain_true', Plain.ObjectId(true));
        Observer.Expect('captioned_false', 'Page 69545');
        Observer.Expect('captioned_true', 'Page PR Oid caption');
        Observer.Expect('plain_false', 'Page 69546');
        Observer.Expect('plain_true', 'Page PR Oid Plain Page');
        Observer.Verify();
    end;
}
