// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-methods
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), helper codeunit 71060, self-contained test codeunit 71061
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Procedure overloading, var vs value parameters, return values, named return variables, access modifiers
// BC versions: 29 (27 and 28 by CI)

codeunit 71060 "LT OjT Proc Helper"
{
    var
        Hidden: Integer;

    procedure Add(A: Integer; B: Integer): Integer
    begin
        exit(A + B);
    end;

    procedure Add(A: Decimal; B: Decimal): Decimal
    begin
        exit(A + B + 0.5);
    end;

    procedure Add(A: Text; B: Text): Text
    begin
        exit(A + '+' + B);
    end;

    procedure Add(A: Integer; B: Integer; C: Integer): Integer
    begin
        exit(A + B + C + 1000);
    end;

    procedure Pick(Value: Code[10]): Text
    begin
        exit('code');
    end;

    procedure Pick(Value: Boolean): Text
    begin
        exit('boolean');
    end;

    procedure Pick(Value: Date): Text
    begin
        exit('date');
    end;

    procedure ByValue(Value: Integer; Name: Text; Items: List of [Text])
    begin
        Value += 1;
        Name := 'changed';
        Items.Add('added in callee');
    end;

    procedure ByVar(var Value: Integer; var Name: Text; var Items: List of [Text])
    begin
        Value += 1;
        Name := 'changed';
        Items.Add('added in callee');
    end;

    procedure ReplaceList(var Items: List of [Text])
    var
        Fresh: List of [Text];
    begin
        Fresh.Add('fresh');
        Items := Fresh;
    end;

    procedure ReplaceListByValue(Items: List of [Text])
    var
        Fresh: List of [Text];
    begin
        Fresh.Add('fresh');
        Items := Fresh;
    end;

    procedure Swap(var A: Integer; var B: Integer)
    var
        Tmp: Integer;
    begin
        Tmp := A;
        A := B;
        B := Tmp;
    end;

    procedure NamedReturn() Result: Integer
    begin
        Result := 5;
    end;

    procedure NamedReturnOverriddenByExit() Result: Integer
    begin
        Result := 5;
        exit(9);
    end;

    procedure NamedReturnAssignedAfterExitPath(Early: Boolean) Result: Text
    begin
        Result := 'assigned';
        if Early then
            exit;
        Result := 'late';
    end;

    procedure NeverAssignedInteger(): Integer
    begin
    end;

    procedure NeverAssignedText(): Text
    begin
    end;

    procedure NeverAssignedBoolean(): Boolean
    begin
    end;

    procedure NeverAssignedDecimal(): Decimal
    begin
    end;

    procedure NeverAssignedDate(): Date
    begin
    end;

    procedure NeverAssignedCode(): Code[5]
    begin
    end;

    procedure NamedReturnList() Result: List of [Integer]
    begin
        Result.Add(1);
        Result.Add(2);
    end;

    procedure TextReturnTruncated(): Text[3]
    begin
        exit('abcdef');
    end;

    internal procedure InternalProc(): Text
    begin
        exit('internal');
    end;

    local procedure LocalProc(): Text
    begin
        exit('local');
    end;

    procedure CallLocal(): Text
    begin
        exit(LocalProc());
    end;

    procedure SetHidden(V: Integer)
    begin
        Hidden := V;
    end;

    procedure OptionalSideEffect(var Counter: Integer): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;

    procedure IsEven(N: Integer): Boolean
    begin
        if N = 0 then
            exit(true);
        exit(IsOdd(N - 1));
    end;

    procedure IsOdd(N: Integer): Boolean
    begin
        if N = 0 then
            exit(false);
        exit(IsEven(N - 1));
    end;

    procedure Factorial(N: Integer): BigInteger
    begin
        if N <= 1 then
            exit(1);
        exit(N * Factorial(N - 1));
    end;

    procedure Fib(N: Integer): Integer
    begin
        if N < 2 then
            exit(N);
        exit(Fib(N - 1) + Fib(N - 2));
    end;

    procedure SumTo(N: Integer): Integer
    begin
        if N = 0 then
            exit(0);
        exit(N + SumTo(N - 1));
    end;

    procedure Depth(N: Integer; var Max: Integer)
    begin
        if N > Max then
            Max := N;
        if N < 300 then
            Depth(N + 1, Max);
    end;

    procedure Collatz(N: Integer; Steps: Integer): Integer
    begin
        if N = 1 then
            exit(Steps);
        if N mod 2 = 0 then
            exit(Collatz(N div 2, Steps + 1));
        exit(Collatz(3 * N + 1, Steps + 1));
    end;
}

// Writer BP (corpus issue 664): code shapes that once compiled but failed when BC built the app (C# errors at publish).
// microsoft/AL issue 6924: two overloads that differ only in the interface type of the parameter. microsoft/AL issue 6679: a case
// statement with an else arm that assigns a codeunit returned by a procedure.
interface "LT BP ISome"
{
    procedure MyProcedure(): Text;
}

interface "LT BP ISomeOther"
{
    procedure MyProcedure(): Text;
}

codeunit 82552 "LT BP SomeImpl" implements "LT BP ISome"
{
    var
        Tag: Text;

    procedure MyProcedure(): Text
    begin
        exit('some' + Tag);
    end;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;
}

codeunit 82553 "LT BP Iface Caller"
{
    procedure CallMy(I: Interface "LT BP ISome"): Text
    begin
        exit('ISome:' + I.MyProcedure());
    end;

    procedure CallMy(I: Interface "LT BP ISomeOther"): Text
    begin
        exit('ISomeOther:' + I.MyProcedure());
    end;

    procedure CaseWithCodeunitResult(Selector: Integer): Text
    var
        Impl: Codeunit "LT BP SomeImpl";
    begin
        case Selector of
            1:
                Impl := GetImpl('-one');
            else
                Impl := GetImpl('-else');
        end;
        exit(Impl.MyProcedure());
    end;

    local procedure GetImpl(NewTag: Text): Codeunit "LT BP SomeImpl"
    var
        Impl: Codeunit "LT BP SomeImpl";
    begin
        Impl.SetTag(NewTag);
        exit(Impl);
    end;
}
codeunit 71061 "LT OjT Procedures"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Overload_Resolution()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT OjT Proc Helper";
        D: Decimal;
        I: Integer;
    begin
        Observer.Observe('int,int', Format(H.Add(1, 2)));
        Observer.Observe('dec,dec', Format(H.Add(1.5, 2)));
        Observer.Observe('int,dec', Format(H.Add(1, 2.5)));
        Observer.Observe('text,text', H.Add('a', 'b'));
        Observer.Observe('int,int,int', Format(H.Add(1, 2, 3)));
        D := 1;
        Observer.Observe('decVar,int', Format(H.Add(D, 2)));
        I := 4;
        Observer.Observe('intVar,intVar', Format(H.Add(I, I)));
        Observer.Expect('int,int', '3');
        Observer.Expect('dec,dec', '4');
        Observer.Expect('int,dec', '4');
        Observer.Expect('text,text', 'a+b');
        Observer.Expect('int,int,int', '1006');
        Observer.Expect('decVar,int', '3.5');
        Observer.Expect('intVar,intVar', '8');
        Observer.Verify();
    end;

    [Test]
    procedure Overload_ByTypeOfArgument()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT OjT Proc Helper";
        C: Code[10];
    begin
        C := 'ABC';
        Observer.Observe('code', H.Pick(C));
        Observer.Observe('boolean', H.Pick(true));
        Observer.Observe('date', H.Pick(Today()));
        Observer.Observe('dateLiteral', H.Pick(DMY2Date(1, 2, 2020)));
        Observer.Observe('zeroDate', H.Pick(0D));
        Observer.Expect('code', 'code');
        Observer.Expect('boolean', 'boolean');
        Observer.Expect('date', 'date');
        Observer.Expect('dateLiteral', 'date');
        Observer.Expect('zeroDate', 'date');
        Observer.Verify();
    end;

    [Test]
    procedure Parameters_ByValueAndByVar()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT OjT Proc Helper";
        N: Integer;
        T: Text;
        L: List of [Text];
    begin
        N := 1;
        T := 'orig';
        H.ByValue(N, T, L);
        Observer.Observe('value.int', Format(N));
        Observer.Observe('value.text', T);
        Observer.Observe('value.list', Format(L.Count()));
        H.ByVar(N, T, L);
        Observer.Observe('var.int', Format(N));
        Observer.Observe('var.text', T);
        Observer.Observe('var.list', Format(L.Count()));
        Observer.Expect('value.int', '1');
        Observer.Expect('value.text', 'orig');
        Observer.Expect('value.list', '1');
        Observer.Expect('var.int', '2');
        Observer.Expect('var.text', 'changed');
        Observer.Expect('var.list', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Parameters_ReplaceReferenceType()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT OjT Proc Helper";
        L: List of [Text];
    begin
        L.Add('mine');
        H.ReplaceListByValue(L);
        Observer.Observe('byValue.count', Format(L.Count()));
        Observer.Observe('byValue.first', L.Get(1));
        H.ReplaceList(L);
        Observer.Observe('byVar.count', Format(L.Count()));
        Observer.Observe('byVar.first', L.Get(1));
        Observer.Expect('byValue.count', '1');
        Observer.Expect('byValue.first', 'mine');
        Observer.Expect('byVar.count', '1');
        Observer.Expect('byVar.first', 'fresh');
        Observer.Verify();
    end;

    [Test]
    procedure Parameters_Swap()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT OjT Proc Helper";
        A: Integer;
        B: Integer;
    begin
        A := 1;
        B := 2;
        H.Swap(A, B);
        Observer.Observe('a', Format(A));
        Observer.Observe('b', Format(B));
        H.Swap(A, A);
        Observer.Observe('same', Format(A));
        Observer.Expect('a', '2');
        Observer.Expect('b', '1');
        Observer.Expect('same', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Parameters_VarEvaluationOrder()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT OjT Proc Helper";
        C: Integer;
    begin
        Observer.Observe('sum', Format(H.OptionalSideEffect(C) + H.OptionalSideEffect(C)));
        Observer.Observe('counter', Format(C));
        Observer.Observe('add', Format(H.Add(H.OptionalSideEffect(C), H.OptionalSideEffect(C))));
        Observer.Expect('sum', '3');
        Observer.Expect('counter', '2');
        Observer.Expect('add', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Return_NamedAndExit()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT OjT Proc Helper";
        L: List of [Integer];
    begin
        Observer.Observe('named', Format(H.NamedReturn()));
        Observer.Observe('exitOverrides', Format(H.NamedReturnOverriddenByExit()));
        Observer.Observe('earlyExit', H.NamedReturnAssignedAfterExitPath(true));
        Observer.Observe('lateAssign', H.NamedReturnAssignedAfterExitPath(false));
        L := H.NamedReturnList();
        Observer.Observe('list', Format(L.Count()) + '|' + Format(L.Get(2)));
        asserterror Observer.Observe('truncated', H.TextReturnTruncated());
        Observer.ObserveError('af344');
        Observer.Expect('named', '5');
        Observer.Expect('exitOverrides', '9');
        Observer.Expect('earlyExit', 'assigned');
        Observer.Expect('lateAssign', 'late');
        Observer.Expect('list', '2|2');
        Observer.Expect('af344|text', 'The length of the string is 6, but it must be less than or equal to 3 characters. Value: abcdef');
        Observer.Expect('af344|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure Return_NeverAssigned()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT OjT Proc Helper";
    begin
        Observer.Observe('integer', Format(H.NeverAssignedInteger()));
        Observer.Observe('text', '[' + H.NeverAssignedText() + ']');
        Observer.Observe('boolean', Format(H.NeverAssignedBoolean()));
        Observer.Observe('decimal', Format(H.NeverAssignedDecimal()));
        Observer.Observe('date', '[' + Format(H.NeverAssignedDate()) + ']');
        Observer.Observe('code', '[' + H.NeverAssignedCode() + ']');
        Observer.Expect('integer', '0');
        Observer.Expect('text', '[]');
        Observer.Expect('boolean', 'No');
        Observer.Expect('decimal', '0');
        Observer.Expect('date', '[]');
        Observer.Expect('code', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Access_InternalAndLocal()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT OjT Proc Helper";
    begin
        Observer.Observe('internal', H.InternalProc());
        Observer.Observe('localViaPublic', H.CallLocal());
        Observer.Expect('internal', 'internal');
        Observer.Expect('localViaPublic', 'local');
        Observer.Verify();
    end;

    [Test]
    procedure Recursion_Moderate()
    var
        Observer: Codeunit "Probe Observer";
        H: Codeunit "LT OjT Proc Helper";
        Max: Integer;
    begin
        Observer.Observe('fact10', Format(H.Factorial(10)));
        Observer.Observe('fact20', Format(H.Factorial(20)));
        Observer.Observe('fib15', Format(H.Fib(15)));
        Observer.Observe('sum100', Format(H.SumTo(100)));
        Observer.Observe('sum500', Format(H.SumTo(500)));
        H.Depth(0, Max);
        Observer.Observe('depth', Format(Max));
        Observer.Observe('even100', Format(H.IsEven(100)));
        Observer.Observe('odd101', Format(H.IsOdd(101)));
        Observer.Observe('even7', Format(H.IsEven(7)));
        Observer.Observe('collatz27', Format(H.Collatz(27, 0)));
        Observer.Expect('fact10', '3628800');
        Observer.Expect('fact20', '2432902008176640000');
        Observer.Expect('fib15', '610');
        Observer.Expect('sum100', '5050');
        Observer.Expect('sum500', '125250');
        Observer.Expect('depth', '300');
        Observer.Expect('even100', 'Yes');
        Observer.Expect('odd101', 'Yes');
        Observer.Expect('even7', 'No');
        Observer.Expect('collatz27', '111');
        Observer.Verify();
    end;

    // Writer BP (corpus issue 664, microsoft/AL issues 6924 and 6679).
    [Test]
    procedure BP_InterfaceOverload_And_CaseWithCodeunitResult()
    var
        Observer: Codeunit "Probe Observer";
        Caller: Codeunit "LT BP Iface Caller";
        Impl: Codeunit "LT BP SomeImpl";
        Some: Interface "LT BP ISome";
    begin
        Observer.Observe('overload codeunit argument', Caller.CallMy(Impl));
        Some := Impl;
        Observer.Observe('overload interface argument', Caller.CallMy(Some));
        Observer.Observe('case arm 1', Caller.CaseWithCodeunitResult(1));
        Observer.Observe('case else', Caller.CaseWithCodeunitResult(7));
        Observer.Expect('overload codeunit argument', 'ISome:some');
        Observer.Expect('overload interface argument', 'ISome:some');
        Observer.Expect('case arm 1', 'some-one');
        Observer.Expect('case else', 'some-else');
        Observer.Verify();
    end;
}
