// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-variables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own codeunit 99761
// Probe: al-runner issue 8629: the word Local (the procedure modifier) as the name of a variable or parameter, used unquoted in code
// Facts: a variable named Local declared after a comma (Other, Local: Integer), a quoted declaration "Local", a parameter and a var
// parameter named Local, and a global variable named Local all compile and work when the code names them unquoted: assignment, +=,
// read in an expression, argument of a var parameter, for loop variable, case and if, array index, List methods, unary minus and not.
// Local as the first unquoted name of a declaration, or as a named return value, does not compile (AL0104 'procedure' expected),
// so this file never declares it that way.
// Measured with the AL compilers of BC 27, 28 and 29: every shape here compiles. The expected values follow from the plain integer,
// array, List and Boolean semantics; the corpus CI run on BC 27, 28 and 29 is the first run that checks them on BC.
// BC versions: 27, 28, 29
codeunit 99760 "LANG Local As Name Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LocalAsName_AfterComma_Assign_HoldsValue()
    var
        Other, Local: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Other := 40;
        Local := 2;
        Observer.Observe('local', Format(Local));
        Observer.Observe('other plus local', Format(Other + Local));
        Observer.Expect('local', '2');
        Observer.Expect('other plus local', '42');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_AfterComma_CompoundAssign_AddsValue()
    var
        Other, Local: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Other := 40;
        Local := 5;
        Local += 2;
        Observer.Observe('local', Format(Local));
        Observer.Observe('other plus local', Format(Other + Local));
        Observer.Expect('local', '7');
        Observer.Expect('other plus local', '47');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_Parameter_Read_ReturnsDouble()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('twice 21', Format(Twice(21)));
        Observer.Expect('twice 21', '42');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_Parameter_Assign_ReturnsBumpedCallerKeepsValue()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        N := 41;
        Observer.Observe('bump 41', Format(Bump(N)));
        Observer.Observe('caller after bump', Format(N));
        Observer.Expect('bump 41', '42');
        Observer.Expect('caller after bump', '41');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_VarParameter_Assign_ChangesCaller()
    var
        Other, Local: Integer;
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        N := 1;
        SetTo(N);
        Observer.Observe('caller variable after SetTo', Format(N));
        Other := 1;
        Local := 0;
        SetTo(Local);
        Observer.Observe('caller Local after SetTo', Format(Local));
        Observer.Observe('caller Other untouched', Format(Other));
        Observer.Expect('caller variable after SetTo', '7');
        Observer.Expect('caller Local after SetTo', '7');
        Observer.Expect('caller Other untouched', '1');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_ForLoopVariable_SumsRange()
    var
        Other, Local: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Other := 0;
        for Local := 1 to 3 do
            Other += Local;
        Observer.Observe('sum 1 to 3', Format(Other));
        Observer.Observe('local after loop', Format(Local));
        Observer.Expect('sum 1 to 3', '6');
        Observer.Expect('local after loop', '3');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_CaseAndIf_SelectBranch()
    var
        Other, Local: Integer;
        Observer: Codeunit "Probe Observer";
        Branch: Text;
    begin
        Other := 0;
        Local := 2;
        case Local of
            1:
                Branch := 'one';
            2:
                Branch := 'two';
            else
                Branch := 'other';
        end;
        Observer.Observe('case local 2', Branch);
        if Local = 0 then
            Branch := 'zero'
        else
            Branch := 'not zero';
        Observer.Observe('if local 2 = 0', Branch);
        Local := Other;
        if Local = 0 then
            Branch := 'zero'
        else
            Branch := 'not zero';
        Observer.Observe('if local 0 = 0', Branch);
        Observer.Expect('case local 2', 'two');
        Observer.Expect('if local 2 = 0', 'not zero');
        Observer.Expect('if local 0 = 0', 'zero');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_Array_ElementAssign_HoldsValue()
    var
        Other, Local: array[3] of Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Other[1] := 38;
        Local[1] := 4;
        Observer.Observe('local 1', Format(Local[1]));
        Observer.Observe('local 2', Format(Local[2]));
        Observer.Observe('other 1 plus local 1', Format(Other[1] + Local[1]));
        Observer.Observe('array length of local', Format(ArrayLen(Local)));
        Observer.Expect('local 1', '4');
        Observer.Expect('local 2', '0');
        Observer.Expect('other 1 plus local 1', '42');
        Observer.Expect('array length of local', '3');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_List_AddCount_HoldsItem()
    var
        Other, Local: List of [Integer];
        Observer: Codeunit "Probe Observer";
    begin
        Local.Add(4);
        Observer.Observe('local count', Format(Local.Count()));
        Observer.Observe('local get 1', Format(Local.Get(1)));
        Observer.Observe('other count', Format(Other.Count()));
        Observer.Expect('local count', '1');
        Observer.Expect('local get 1', '4');
        Observer.Expect('other count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_UnaryMinusAndNot_Negate()
    var
        Other, Local: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('negate 42', Format(Negate(42)));
        Local := false;
        Other := not Local;
        if Other then
            Observer.Observe('not local false', 'true')
        else
            Observer.Observe('not local false', 'false');
        Local := true;
        if not Local then
            Observer.Observe('if not local true', 'then branch')
        else
            Observer.Observe('if not local true', 'else branch');
        Observer.Expect('negate 42', '-42');
        Observer.Expect('not local false', 'true');
        Observer.Expect('if not local true', 'else branch');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_GlobalVar_AssignRead_HoldsValue()
    var
        Globals: Codeunit "LANG Local As Name Globals";
        Observer: Codeunit "Probe Observer";
    begin
        Globals.SetLocal(41);
        Observer.Observe('global local', Format(Globals.GetLocal()));
        Observer.Observe('global other plus local', Format(Globals.GetOtherPlusLocal()));
        Observer.Expect('global local', '41');
        Observer.Expect('global other plus local', '42');
        Observer.Verify();
    end;

    [Test]
    procedure LocalAsName_QuotedDeclaration_UnquotedUse_HoldsValue()
    var
        "Local": Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Local := 2;
        Observer.Observe('local', Format(Local));
        Observer.Observe('local times 21', Format(Local * 21));
        Observer.Expect('local', '2');
        Observer.Expect('local times 21', '42');
        Observer.Verify();
    end;

    local procedure Twice(Local: Integer): Integer
    begin
        exit(Local * 2);
    end;

    local procedure Bump(Local: Integer): Integer
    begin
        Local := Local + 1;
        exit(Local);
    end;

    local procedure SetTo(var Local: Integer)
    begin
        Local := 7;
    end;

    local procedure Negate(Local: Integer): Integer
    begin
        exit(-Local);
    end;
}

// local object: its global var section, a variable named Local after a comma, is what LocalAsName_GlobalVar_AssignRead_HoldsValue checks
codeunit 99761 "LANG Local As Name Globals"
{
    var
        Other, Local: Integer;

    procedure SetLocal(Value: Integer)
    begin
        Other := 1;
        Local := Value;
    end;

    procedure GetLocal(): Integer
    begin
        exit(Local);
    end;

    procedure GetOtherPlusLocal(): Integer
    begin
        exit(Other + Local);
    end;
}
