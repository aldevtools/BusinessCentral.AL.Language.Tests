// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optionmembers-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75690, test codeunit 75691
// Probe (al-runner issue 8657): option members whose names are words of the AL language.
// Facts:
//   - An option variable's members "Key" and "End" quoted and Local and Exit unquoted compile; Format gives the member's name
//     and the ordinal is its place.
//   - A table field's OptionMembers takes Key and Local unquoted and "If" quoted; Format gives the name.
//   - Not compiling (must-not-compile 3560 to 3597): an option type's member named, unquoted, by one of 24 words (Actions,
//     Area, Begin, ChartPart, CueGroup, End, Event, Extends, False, FieldAttribute, FieldElement, FieldGroups, Key, Of,
//     PageExtension, Procedure, ProfileExtension, TableElement, TableExtension, TextAttribute, TextElement, Trigger, True,
//     Var), in a variable, a global, a parameter or a return type, AL0105 at the name first (AL0104 for Begin, End and Var,
//     AL0519 for End in a return type); and an OptionMembers member named If, Else, True, False, PageExtension,
//     ProfileExtension or TableExtension, unquoted, AL0105.
// local object: the option member names are under test.
// BC versions: 27, 28, 29 (by the corpus CI matrix)

table 75690 "TYP Keyword Option Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = Zero,Key,Local,"If"; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 75691 "TYP Keyword Option Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure KeywordOptionMembers_Variable_QuotedAndPlainNames()
    var
        Observer: Codeunit "Probe Observer";
        Option: Option Zero,"Key","End",Local,Exit;
    begin
        Initialize();
        Option := Option::"Key";
        Observer.Observe('Key', Format(Option) + '/' + Format(Option, 0, 9));
        Option := Option::"End";
        Observer.Observe('End', Format(Option) + '/' + Format(Option, 0, 9));
        Option := Option::Local;
        Observer.Observe('Local', Format(Option) + '/' + Format(Option, 0, 9));
        Option := Option::"Exit";
        Observer.Observe('Exit', Format(Option) + '/' + Format(Option, 0, 9));
        Observer.Expect('Key', 'Key/1');
        Observer.Expect('End', 'End/2');
        Observer.Expect('Local', 'Local/3');
        Observer.Expect('Exit', 'Exit/4');
        Observer.Verify();
    end;

    [Test]
    procedure KeywordOptionMembers_OptionMembers_PlainKeyAndQuotedIf()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TYP Keyword Option Row";
    begin
        Initialize();
        Row.Id := 1;
        Row.Opt := Row.Opt::Key;
        Row.Insert();
        Row.Get(1);
        Observer.Observe('Key', Format(Row.Opt));
        Row.Opt := Row.Opt::"If";
        Observer.Observe('If', Format(Row.Opt) + '/' + Format(Row.Opt, 0, 9));
        Observer.Expect('Key', 'Key');
        Observer.Expect('If', 'If/3');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        Row: Record "TYP Keyword Option Row";
    begin
        Row.DeleteAll();
    end;
}
