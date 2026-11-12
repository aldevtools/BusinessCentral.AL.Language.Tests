// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local enum, relation tables and filtered Card
// BC versions: 27.5+

// local object: the exact FlowFilter and related field share this enum type.
enum 50891 "REC Enum Group Kind"
{
    value(0; Other) { }
    value(1; Selected) { }
}

// local object: the TableRelation and enum field metadata are the behavior under test.
table 50891 "REC Enum Group Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Kind; Enum "REC Enum Group Kind") { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

// local object: the TableRelation and enum field metadata are the behavior under test.
table 50892 "REC Enum Group Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Kind Filter"; Enum "REC Enum Group Kind") { FieldClass = FlowFilter; }
        field(3; Target; Code[20])
        {
            TableRelation = "REC Enum Group Target".Code where(Kind = field("Kind Filter"));
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// local object: the Card carries the group 2 view into validation of a new row.
page 50891 "REC Enum Group Card"
{
    PageType = Card;
    SourceTable = "REC Enum Group Source";
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { }
                field(Target; Rec.Target) { }
            }
        }
    }
}

codeunit 50893 "REC Enum Group Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TestField_SetValue_GroupTwoEnumMatch_AcceptsTarget()
    // CLAIM: The matching target is stored in the page buffer.
    var
        Card: TestPage "REC Enum Group Card";
    begin
        Initialize();
        OpenFilteredNewCard(Card, 1);
        Card.Target.SetValue('MATCH');
        if Card.Target.Value() <> 'MATCH' then
            Error('The matching relation was not assigned.');
        Card.Close();
    end;

    [Test]
    procedure TestField_SetValue_GroupTwoEnumMismatch_RejectsTarget()
    // CLAIM: The target from the wrong enum value is rejected.
    var
        Card: TestPage "REC Enum Group Card";
    begin
        Initialize();
        OpenFilteredNewCard(Card, 2);
        asserterror Card.Target.SetValue('OTHER');
        if StrPos(GetLastErrorText(), 'Target') = 0 then
            Error('Expected validation of Target to fail, got %1', GetLastErrorText());
        Card.Close();
    end;

    [Test]
    procedure Record_Validate_GroupTwoEnumMismatch_RejectsTarget()
    // CLAIM: The source FlowFilter constrains direct validation after returning to group 0.
    var
        Source: Record "REC Enum Group Source";
    begin
        Initialize();
        SetGroupTwoFilter(Source);
        Source.Validate(Target, 'MATCH');
        Source.TestField(Target, 'MATCH');
        asserterror Source.Validate(Target, 'OTHER');
        if StrPos(GetLastErrorText(), 'OTHER') = 0 then
            Error('Expected a relation error for OTHER, got %1', GetLastErrorText());
    end;

    local procedure OpenFilteredNewCard(var Card: TestPage "REC Enum Group Card"; Id: Integer)
    var
        Source: Record "REC Enum Group Source";
    begin
        SetGroupTwoFilter(Source);
        Card.Trap();
        Page.Run(Page::"REC Enum Group Card", Source);
        Card.New();
        Card.Id.SetValue(Id);
    end;

    local procedure Initialize()
    var
        Source: Record "REC Enum Group Source";
        Target: Record "REC Enum Group Target";
    begin
        Source.DeleteAll();
        Target.DeleteAll();
        Target.Code := 'MATCH';
        Target.Kind := Target.Kind::Selected;
        Target.Insert();
        Target.Code := 'OTHER';
        Target.Kind := Target.Kind::Other;
        Target.Insert();
    end;

    local procedure SetGroupTwoFilter(var Source: Record "REC Enum Group Source")
    begin
        Source.FilterGroup(2);
        Source.SetRange("Kind Filter", Source."Kind Filter"::Selected);
        Source.FilterGroup(0);
    end;
}
