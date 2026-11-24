// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 75600
// Probe (al-runner issue 8630): table field names that are words of the AL language.
// Facts:
//   - The unquoted field names Local, If, Exit, Keys, Fields and Layout compile in a table, and a row written through them is read back
//     with Get with every value. Local, Keys, Fields and Layout work unquoted as members (Row.Local); If and Exit need the quoted member
//     form (Row."If"): unquoted, Row.If, Row.Exit and SetRange(If, ...) do not compile (must-not-compile 3328 to 3330).
//   - The quoted field names "Area" and "Key" compile, and hold their values the same way.
//   - Not compiling (must-not-compile 3300 to 3327): an unquoted field name that is one of 24 words (Actions, Area, Begin, ChartPart,
//     CueGroup, End, Event, Extends, False, FieldAttribute, FieldElement, FieldGroups, Key, Of, PageExtension, Procedure,
//     ProfileExtension, TableElement, TableExtension, TextAttribute, TextElement, Trigger, True, Var), in a table or a table extension,
//     with AL0107 at the name first.
// local object: the field names of the table are under test.
// BC versions: 27, 28, 29 (by the corpus CI matrix)

table 75600 "TBL Keyword Field Names Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Local; Integer) { }
        field(3; If; Integer) { }
        field(4; Exit; Integer) { }
        field(5; Keys; Integer) { }
        field(6; Fields; Integer) { }
        field(7; Layout; Integer) { }
        field(8; "Area"; Integer) { }
        field(9; "Key"; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 75601 "TBL Keyword Field Names Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure KeywordFieldNames_InsertGet_UnquotedNames_HoldValues()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TBL Keyword Field Names Row";
    begin
        Initialize();
        Row.Init();
        Row.Id := 1;
        Row.Local := 11;
        Row."If" := 12;
        Row."Exit" := 13;
        Row.Keys := 14;
        Row.Fields := 15;
        Row.Layout := 16;
        Row.Insert();
        Clear(Row);
        Observer.Observe('get', Format(Row.Get(1)));
        Observer.Observe('Local', Format(Row.Local));
        Observer.Observe('If', Format(Row."If"));
        Observer.Observe('Exit', Format(Row."Exit"));
        Observer.Observe('Keys', Format(Row.Keys));
        Observer.Observe('Fields', Format(Row.Fields));
        Observer.Observe('Layout', Format(Row.Layout));
        Observer.Expect('get', 'Yes');
        Observer.Expect('Local', '11');
        Observer.Expect('If', '12');
        Observer.Expect('Exit', '13');
        Observer.Expect('Keys', '14');
        Observer.Expect('Fields', '15');
        Observer.Expect('Layout', '16');
        Observer.Verify();
    end;

    [Test]
    procedure KeywordFieldNames_InsertGet_QuotedAreaKey_HoldValues()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TBL Keyword Field Names Row";
    begin
        Initialize();
        Row.Init();
        Row.Id := 2;
        Row."Area" := 21;
        Row."Key" := 22;
        Row.Insert();
        Clear(Row);
        Observer.Observe('get', Format(Row.Get(2)));
        Observer.Observe('Area', Format(Row."Area"));
        Observer.Observe('Key', Format(Row."Key"));
        Observer.Expect('get', 'Yes');
        Observer.Expect('Area', '21');
        Observer.Expect('Key', '22');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        Row: Record "TBL Keyword Field Names Row";
    begin
        Row.DeleteAll();
    end;
}
