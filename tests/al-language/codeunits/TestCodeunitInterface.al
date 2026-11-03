// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope

codeunit 60079 "Test Codeunit Interface"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Interface Assignment and Polymorphism ───────────────────────────────

    [Test]
    procedure Interface_Assign_DoubleImpl_ComputesDouble()
    var
        C: Interface IALTCompute;
        D: Codeunit ALTDouble;
        Result: Integer;
    begin
        Initialize();
        C := D;
        Result := C.Compute(10);
        Assert.AreEqual(20, Result, 'Interface via ALTDouble must return 2*X');
    end;

    [Test]
    procedure Interface_Assign_SquareImpl_ComputesSquare()
    var
        C: Interface IALTCompute;
        S: Codeunit ALTSquare;
        Result: Integer;
    begin
        Initialize();
        C := S;
        Result := C.Compute(3);
        Assert.AreEqual(9, Result, 'Interface via ALTSquare must return X²');
    end;

    [Test]
    procedure Interface_Reassign_ChangesImpl()
    var
        C: Interface IALTCompute;
        D: Codeunit ALTDouble;
        S: Codeunit ALTSquare;
        ResultDouble: Integer;
        ResultSquare: Integer;
    begin
        Initialize();
        C := D;
        ResultDouble := C.Compute(4);
        Assert.AreEqual(8, ResultDouble, 'Initial assignment to Double must return 2*X');

        C := S;
        ResultSquare := C.Compute(4);
        Assert.AreEqual(16, ResultSquare, 'After reassign to Square, must return X²');
    end;

    [Test]
    procedure Interface_Double_EdgeCase_Zero()
    var
        C: Interface IALTCompute;
        D: Codeunit ALTDouble;
        Result: Integer;
    begin
        Initialize();
        C := D;
        Result := C.Compute(0);
        Assert.AreEqual(0, Result, '2*0 must be 0');
    end;

    [Test]
    procedure Interface_Square_EdgeCase_One()
    var
        C: Interface IALTCompute;
        S: Codeunit ALTSquare;
        Result: Integer;
    begin
        Initialize();
        C := S;
        Result := C.Compute(1);
        Assert.AreEqual(1, Result, '1² must be 1');
    end;

    [Test]
    procedure Interface_Double_NegativeInput()
    var
        C: Interface IALTCompute;
        D: Codeunit ALTDouble;
        Result: Integer;
    begin
        Initialize();
        C := D;
        Result := C.Compute(-3);
        Assert.AreEqual(-6, Result, '2*(-3) must be -6');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
