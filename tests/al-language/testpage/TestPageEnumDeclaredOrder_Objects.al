// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: none -- these objects ARE the fixtures for TestPageEnumDeclaredOrder_Tests.al.
//
// An enum whose DECLARED order is not its ordinal order: the base enum declares only
// value(4), and the enumextension adds 0, 1 and 2 after it. The declared order is therefore
// 4, 0, 1, 2 -- the same shape as Base Application's "Job Queue Report Output Type", whose base
// value is 4 and whose extension adds 0..3. Captions differ from member names so a test can tell
// which of the two a control answered with.

enum 67485 "TPEDO Kind"
{
    Extensible = true;

    value(4; Zulu) { Caption = 'Zulu caption'; }
}

enumextension 67485 "TPEDO Kind Ext" extends "TPEDO Kind"
{
    value(0; Alpha) { Caption = 'Alpha caption'; }
    value(1; Beta) { Caption = 'Beta caption'; }
    value(2; Gamma) { Caption = 'Gamma caption'; }
}

table 67485 "TPEDO Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Kind; Enum "TPEDO Kind") { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 67985 "TPEDO Card"
{
    PageType = Card;
    SourceTable = "TPEDO Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Kind; Rec.Kind) { ApplicationArea = All; }
        }
    }
}
