// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61418
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): the IN operator with a DotNet DateTime variable on the left
//
// A DotNet System.DateTime value as an operand (issue 154 item 3). Every statement is wrapped in a TryFunction and observed as ok:<Format of the result> or error:<text>|<code>.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.DateTime"; NDtmDn) { }
    }
}

codeunit 61418 "LT DotNetOp DateTimeIn"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOp1(var Result: Text)
    var
        W: DotNet NDtmDn;
        W2: DotNet NDtmDn;
        Dt: DateTime;
        Dt2: DateTime;
        Dur: Duration;
        Dy: Date;
        T: Text;
    begin
        W := W.DateTime(2020, 1, 2, 3, 4, 5);
        W2 := W2.DateTime(2021, 2, 3, 4, 5, 6);
        Dt := CreateDateTime(DMY2Date(2, 1, 2020), 030405T);
        Dt2 := CreateDateTime(DMY2Date(3, 2, 2021), 040506T);
        Dur := 1000;
        Dy := DMY2Date(2, 1, 2020);
        T := 'x';
        Result := Format(W in [Dt .. Dt2]);
    end;

    local procedure Out1(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp1(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp2(var Result: Text)
    var
        W: DotNet NDtmDn;
        W2: DotNet NDtmDn;
        Dt: DateTime;
        Dt2: DateTime;
        Dur: Duration;
        Dy: Date;
        T: Text;
    begin
        W := W.DateTime(2020, 1, 2, 3, 4, 5);
        W2 := W2.DateTime(2021, 2, 3, 4, 5, 6);
        Dt := CreateDateTime(DMY2Date(2, 1, 2020), 030405T);
        Dt2 := CreateDateTime(DMY2Date(3, 2, 2021), 040506T);
        Dur := 1000;
        Dy := DMY2Date(2, 1, 2020);
        T := 'x';
        Result := Format(W2 in [Dt .. Dt]);
    end;

    local procedure Out2(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp2(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp3(var Result: Text)
    var
        W: DotNet NDtmDn;
        W2: DotNet NDtmDn;
        Dt: DateTime;
        Dt2: DateTime;
        Dur: Duration;
        Dy: Date;
        T: Text;
    begin
        W := W.DateTime(2020, 1, 2, 3, 4, 5);
        W2 := W2.DateTime(2021, 2, 3, 4, 5, 6);
        Dt := CreateDateTime(DMY2Date(2, 1, 2020), 030405T);
        Dt2 := CreateDateTime(DMY2Date(3, 2, 2021), 040506T);
        Dur := 1000;
        Dy := DMY2Date(2, 1, 2020);
        T := 'x';
        Result := Format(W in [Dt]);
    end;

    local procedure Out3(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp3(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure In_Sets()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('in_range_hit', Out1());
        Observer.Observe('in_range_miss', Out2());
        Observer.Observe('in_single', Out3());
        Observer.Expect('in_range_hit', 'ok:Yes');
        Observer.Expect('in_range_miss', 'ok:No');
        Observer.Expect('in_single', 'ok:Yes');
        Observer.Verify();
    end;
}
