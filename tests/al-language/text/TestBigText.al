codeunit 60089 "Test BigText"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
    [Test]
    procedure BigText_AddText_PreservesData()
    var
        BT: BigText;
        Sub: Text;
    begin
        Initialize();
        BT.AddText('TestData');
        BT.GetSubText(Sub, 1, 8);
        Assert.AreEqual('TestData', Sub, 'BigText GetSubText must return added text');
    end;

    local procedure Initialize()
    begin
        // Harmless initialization
    end;

    [Test]
    procedure BigText_AddText_IncreasesLength()
    var
        BT: BigText;
        Len: Integer;
    begin
        Initialize();
        BT.AddText('hello world');
        Len := BT.Length();
        Assert.IsTrue(Len > 0, 'BigText.Length after AddText must be greater than 0');
    end;

    [Test]
    procedure BigText_Length_ReturnsCorrectLength()
    var
        BT: BigText;
        Len: Integer;
    begin
        Initialize();
        BT.AddText('12345');
        Len := BT.Length();
        Assert.AreEqual(5, Len, 'BigText.Length after AddText("12345") must return 5');
    end;

    [Test]
    procedure BigText_GetSubText_ExtractsChars()
    var
        BT: BigText;
        Extracted: Text;
    begin
        Initialize();
        BT.AddText('Hello World');
        BT.GetSubText(Extracted, 1, 5);
        Assert.AreEqual('Hello', Extracted, 'BigText.GetSubText(1, 5) must extract "Hello"');
    end;

        [Test]
    procedure BigText_AddText_Twice_Appends()
    var
        BT: BigText;
        Len: Integer;
    begin
        Initialize();
        BT.AddText('foo');
        BT.AddText('bar');
        Len := BT.Length();
        Assert.AreEqual(6, Len, 'BigText after two AddText calls must have combined length 6');
    end;

    [Test]
    procedure BigText_GetSubText_FullRange_ReturnsFullText()
    var
        BT: BigText;
        Sub: Text;
    begin
        Initialize();
        BT.AddText('ab');
        BT.GetSubText(Sub, 1, 2);
        Assert.AreEqual('ab', Sub, 'BigText.GetSubText of full range must return full text');
    end;


    // ---- Writer SH, al-runner issue 5940: is BigText copied on assignment and on a by-value parameter?

    local procedure ShAddByValue(Value: BigText)
    begin
        Value.AddText('c');
    end;

    local procedure ShAddByVar(var Value: BigText)
    begin
        Value.AddText('v');
    end;

    local procedure ShText(var Value: BigText): Text
    var
        Sub: Text;
    begin
        Value.GetSubText(Sub, 1);
        exit(Sub);
    end;

    [Test]
    procedure BigText_Assign_CopiesTheValue()
    var
        Observer: Codeunit "Probe Observer";
        BigA: BigText;
        BigB: BigText;
    begin
        BigA.AddText('a');
        BigB := BigA;
        BigA.AddText('b');
        Observer.Observe('after A grows: A', ShText(BigA));
        Observer.Observe('after A grows: B', ShText(BigB));
        BigB.AddText('xyz');
        Observer.Observe('after B grows: A', ShText(BigA));
        Observer.Observe('after B grows: B', ShText(BigB));
        Observer.Expect('after A grows: A', 'ab');
        Observer.Expect('after A grows: B', 'a');
        Observer.Expect('after B grows: A', 'ab');
        Observer.Expect('after B grows: B', 'axyz');
        Observer.Verify();
    end;

    [Test]
    procedure BigText_Parameters_ByValueCopies_VarShares()
    var
        Observer: Codeunit "Probe Observer";
        BigA: BigText;
    begin
        BigA.AddText('a');
        ShAddByValue(BigA);
        Observer.Observe('after by-value call', ShText(BigA));
        ShAddByVar(BigA);
        Observer.Observe('after var call', ShText(BigA));
        Observer.Expect('after by-value call', 'a');
        Observer.Expect('after var call', 'av');
        Observer.Verify();
    end;

    [Test]
    procedure BigText_ClearOfACopy_KeepsTheOriginal()
    var
        Observer: Codeunit "Probe Observer";
        BigA: BigText;
        BigB: BigText;
        BigC: BigText;
    begin
        // The reporter's sequence (al-runner issue 5940).
        BigA.AddText('a');
        BigB := BigA;
        BigA.AddText('b');
        ShAddByValue(BigA);
        BigC := BigA;
        Clear(BigC);
        Observer.Observe('lengths', StrSubstNo('A=%1;B=%2;C=%3', BigA.Length(), BigB.Length(), BigC.Length()));
        Clear(BigA);
        Observer.Observe('B after Clear of A', ShText(BigB));
        Observer.Expect('lengths', 'A=2;B=1;C=0');
        Observer.Expect('B after Clear of A', 'a');
        Observer.Verify();
    end;
}
