// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-simple-statements
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 83851, codeunits 83852 and 83853
// Probe: corpus #664 item 40 (microsoft/AL issue 2229): the word Labels (a report section keyword) as a field, procedure, parameter and variable name
// Facts: Labels as table field name, procedure name, parameter name, global and local variable name: the code compiles and runs
// Facts (writer QT): the 22 keywords alc accepts as variable names (If, Repeat, For, Div, Mod, ...) work as variables and parameters
//   (QT_KeywordsAsVariableNames_Compile_AndHoldValues); the rejected ones are must-not-compile cases 2016-2040.
// BC versions: 27, 28, 29

table 83851 "LT BN3 Labels Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Labels; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Doubled(): Integer
    begin
        exit(Labels * 2);
    end;
}

codeunit 83852 "LT BN3 Labels Helper"
{
    var
        Count: Integer;

    procedure Labels(Labels: Boolean): Text
    begin
        Count += 1;
        exit(Format(not Labels) + '/' + Format(Count));
    end;

    procedure LocalLabels(): Integer
    var
        Labels: Integer;
    begin
        Labels := 41;
        Labels += 1;
        exit(Labels);
    end;
}

codeunit 83853 "LT BN3 Labels Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Labels: Text;

    [Test]
    procedure BN3_Labels_AsFieldProcedureParameterVariable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT BN3 Labels Helper";
        Row: Record "LT BN3 Labels Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Labels := 21;
        Row.Insert();
        Row.Get(1);
        Observer.Observe('field', Format(Row.Labels));
        Observer.Observe('field via procedure', Format(Row.Doubled()));
        Row.SetRange(Labels, 21);
        Observer.Observe('filter', Row.GetFilter(Labels) + '|' + Format(Row.Count()));
        Observer.Observe('field caption', Row.FieldCaption(Labels));
        Observer.Observe('procedure true', Helper.Labels(true));
        Observer.Observe('procedure false', Helper.Labels(false));
        Observer.Observe('local variable', Format(Helper.LocalLabels()));
        Labels := 'global';
        Observer.Observe('global variable', Labels);
        Observer.Expect('field', '21');
        Observer.Expect('field via procedure', '42');
        Observer.Expect('filter', '21|1');
        Observer.Expect('field caption', 'Labels');
        Observer.Expect('procedure true', 'No/1');
        Observer.Expect('procedure false', 'Yes/2');
        Observer.Expect('local variable', '42');
        Observer.Expect('global variable', 'global');
        Observer.Verify();
    end;

    // Writer QT (2026-10-22, al-runtime-rs PR 5642 and 5656): the 22 statement and operator keywords the AL compiler accepts as unquoted
    // variable names in a var section (If, Then, Else, Case, While, Do, Repeat, Until, For, To, DownTo, ForEach, In, Exit, And, Or, Xor,
    // Not, Div, Mod, With, AssertError), used quoted in statements; and keywords accepted as parameter names (If, Exit, Repeat, Local,
    // Fields, Keys, Layout). Used unquoted in a statement the compiler rejects them: must-not-compile case 2040 (AL0224).

    local procedure QtKeywordParameters(If: Integer; Exit: Integer; Repeat: Integer; Local: Integer; Fields: Integer; Keys: Integer; Layout: Integer): Integer
    begin
        exit("If" + "Exit" * 10 + "Repeat" * 100 + "Local" * 1000 + "Fields" * 10000 + "Keys" * 100000 + "Layout" * 1000000);
    end;

    [Test]
    procedure QT_KeywordsAsVariableNames_Compile_AndHoldValues()
    var
        Observer: Codeunit "Probe Observer";
        If: Integer;
        Then: Integer;
        Else: Integer;
        Case: Integer;
        While: Integer;
        Do: Integer;
        Repeat: Integer;
        Until: Integer;
        For: Integer;
        To: Integer;
        DownTo: Integer;
        ForEach: Integer;
        In: Integer;
        Exit: Integer;
        And: Integer;
        Or: Integer;
        Xor: Integer;
        Not: Integer;
        Div: Integer;
        Mod: Integer;
        With: Integer;
        AssertError: Text;
    begin
        "If" := 1;
        "Then" := 2;
        "Else" := 3;
        "Case" := 4;
        "While" := 5;
        "Do" := 6;
        "Repeat" := 7;
        "Until" := 8;
        "For" := 9;
        "To" := 10;
        "DownTo" := 11;
        "ForEach" := 12;
        "In" := 13;
        "Exit" := 14;
        "And" := 15;
        "Or" := 16;
        "Xor" := 17;
        "Not" := 18;
        "Div" := 19;
        "Mod" := 20;
        "With" := 21;
        "AssertError" := 'twenty-two';
        Observer.Observe('sum', Format("If" + "Then" + "Else" + "Case" + "While" + "Do" + "Repeat" + "Until" + "For" + "To" + "DownTo" + "ForEach" + "In" + "Exit" + "And" + "Or" + "Xor" + "Not" + "Div" + "Mod" + "With"));
        Observer.Observe('text', "AssertError");
        if "If" < "Then" then
            Observer.Observe('if on keyword variables', 'then')
        else
            Observer.Observe('if on keyword variables', 'else');
        for "For" := "To" to "DownTo" do
            "Repeat" += "For";
        Observer.Observe('for loop variable', Format("For") + '|' + Format("Repeat"));
        Observer.Observe('div mod', Format("Div" div 4) + '|' + Format("Mod" mod 6));
        Observer.Observe('keyword parameters', Format(QtKeywordParameters("If", "Then", "Else", "Case", "While", "Do", "Repeat")));
        Observer.Expect('sum', '231');
        Observer.Expect('text', 'twenty-two');
        Observer.Expect('if on keyword variables', 'then');
        Observer.Expect('for loop variable', '11|28');
        Observer.Expect('div mod', '4|2');
        Observer.Expect('keyword parameters', '28654321');
        Observer.Verify();
    end;
}
