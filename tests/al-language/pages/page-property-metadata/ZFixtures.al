// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); this file holds the shared table 76000, card page 76001 and log codeunit 76002 of the lt-z-* folders
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 76000 "LT Z Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; Dt; Date) { AllowInCustomizations = AsReadWrite; }
        field(5; Opt; Option)
        {
            OptionMembers = A,B,C;
            OptionCaption = 'Alpha,Beta,Gamma';
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 76001 "LT Z Card"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

// Text log shared by the tests of the lt-z-* folders.
codeunit 76002 "LT Z Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        HideNow: Boolean;

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

    procedure SetHide(NewValue: Boolean)
    begin
        HideNow := NewValue;
    end;

    procedure GetHide(): Boolean
    begin
        exit(HideNow);
    end;
}
