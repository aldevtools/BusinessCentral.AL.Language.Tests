// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-reserved-keywords
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75630, codeunit 75631, test codeunit 75632
// Probe (al-runner issue 8635): member names that are words of the AL language.
// Facts:
//   - Key, Area, Local, Value and Column work unquoted as members (Row.Key := 1); a row written through them is read back with Get
//     with every value.
//   - Fields and a procedure named If, This, Event, True, Begin and Exit work through the quoted member (Row."If", Callee."Exit"()).
//   - Not compiling (must-not-compile 3410 to 3455): one of 32 words unquoted after `.` in code (And, AssertError, Begin, Case, Div,
//     Do, DownTo, Else, End, Event, Exit, False, For, ForEach, If, In, Mod, Not, Of, Or, Procedure, Repeat, Then, This, To,
//     Trigger, True, Until, Var, While, With, Xor), with AL0107 at the name first: a field written or read, a method called, in
//     procedures and triggers of codeunits, tables, pages and reports, a TestPage control, an interface method, a query column,
//     a control's Visible expression, and a namespace segment in code.
// local object: the member names are under test.
// BC versions: 27, 28, 29 (by the corpus CI matrix)

table 75630 "LNG Keyword Member Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Key"; Integer) { }
        field(3; "Area"; Integer) { }
        field(4; Local; Integer) { }
        field(5; Value; Integer) { }
        field(6; Column; Integer) { }
        field(7; "If"; Integer) { }
        field(8; "This"; Integer) { }
        field(9; "Event"; Integer) { }
        field(10; "True"; Integer) { }
        field(11; "Begin"; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 75631 "LNG Keyword Member Callee"
{
    procedure "Exit"(): Integer
    begin
        exit(31);
    end;
}

codeunit 75632 "LNG Keyword Member Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure KeywordMemberNames_InsertGet_UnquotedMembers_HoldValues()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LNG Keyword Member Row";
    begin
        Initialize();
        Row.Init();
        Row.Id := 1;
        Row.Key := 11;
        Row.Area := 12;
        Row.Local := 13;
        Row.Value := 14;
        Row.Column := 15;
        Row.Insert();
        Clear(Row);
        Observer.Observe('get', Format(Row.Get(1)));
        Observer.Observe('Key', Format(Row.Key));
        Observer.Observe('Area', Format(Row.Area));
        Observer.Observe('Local', Format(Row.Local));
        Observer.Observe('Value', Format(Row.Value));
        Observer.Observe('Column', Format(Row.Column));
        Observer.Expect('get', 'Yes');
        Observer.Expect('Key', '11');
        Observer.Expect('Area', '12');
        Observer.Expect('Local', '13');
        Observer.Expect('Value', '14');
        Observer.Expect('Column', '15');
        Observer.Verify();
    end;

    [Test]
    procedure KeywordMemberNames_InsertGet_QuotedKeywordMembers_HoldValues()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LNG Keyword Member Row";
        Callee: Codeunit "LNG Keyword Member Callee";
    begin
        Initialize();
        Row.Init();
        Row.Id := 2;
        Row."If" := 21;
        Row."This" := 22;
        Row."Event" := 23;
        Row."True" := 24;
        Row."Begin" := 25;
        Row.Insert();
        Clear(Row);
        Observer.Observe('get', Format(Row.Get(2)));
        Observer.Observe('If', Format(Row."If"));
        Observer.Observe('This', Format(Row."This"));
        Observer.Observe('Event', Format(Row."Event"));
        Observer.Observe('True', Format(Row."True"));
        Observer.Observe('Begin', Format(Row."Begin"));
        Observer.Observe('Exit()', Format(Callee."Exit"()));
        Observer.Expect('get', 'Yes');
        Observer.Expect('If', '21');
        Observer.Expect('This', '22');
        Observer.Expect('Event', '23');
        Observer.Expect('True', '24');
        Observer.Expect('Begin', '25');
        Observer.Expect('Exit()', '31');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        Row: Record "LNG Keyword Member Row";
    begin
        Row.DeleteAll();
    end;
}
