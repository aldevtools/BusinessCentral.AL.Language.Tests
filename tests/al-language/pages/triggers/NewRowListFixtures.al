// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects: table 72900, pages 72901-72903
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: fixtures of the blank new-row line of an editable list (Item Reference List shape: secondary key on Type + Ref, plain / InsertAllowed = false / DelayedInsert = true)
// BC versions: 29 (27 and 28 by CI)

table 72900 "LT NewRow Ref"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; RefType; Integer) { }
        field(3; RefNo; Code[20]) { }
        field(4; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(SK; RefType, RefNo) { }
    }
}

page 72901 "LT NewRow Ref List"
{
    PageType = List;
    SourceTable = "LT NewRow Ref";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(TypeF; Rec.RefType) { ApplicationArea = All; }
                field(NoF; Rec.RefNo) { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 72902 "LT NewRow Ref List NoIns"
{
    PageType = List;
    SourceTable = "LT NewRow Ref";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(TypeF; Rec.RefType) { ApplicationArea = All; }
                field(NoF; Rec.RefNo) { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 72903 "LT NewRow Ref List Delayed"
{
    PageType = List;
    SourceTable = "LT NewRow Ref";
    ApplicationArea = All;
    UsageCategory = None;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(TypeF; Rec.RefType) { ApplicationArea = All; }
                field(NoF; Rec.RefNo) { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}
