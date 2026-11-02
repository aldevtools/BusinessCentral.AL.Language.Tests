// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-ternary-operator
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunit 94253
// Probe (writer Y81): a conditional expression with a Label as one branch (against another Label, a text literal, a Text variable and a Code variable, both orders) that ends
// in a Variant through different routes: assignment, Variant parameter, return value, Variant array element (List of [Variant] and Dictionary of [Text, Variant]
// do not compile: AL0408, must-not-compile 2770 and 2771).
// Each result is read for IsText, IsCode, IsTextConstant, Format (0 and 9), the text value taken back into a Text, a Code[20] and a Text[5].
// Pinned elsewhere: assignment of the pairs and the kind of the Variant: types/lt-y66-ternary-label/Y66TernaryLabel.al, types/TestTernaryContracts.al:568-579.
// BC versions: 27, 28, 29

codeunit 94253 "LT Y81 Label Variant"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()) + '/' + Format(V.IsCode()) + '/' + Format(V.IsTextConstant()) + '/' + Format(V.IsChar()) + '/' + Format(V, 0, 0) + '/' + Format(V, 0, 9));
    end;

    [TryFunction]
    local procedure TryBack(V: Variant; var R: Text)
    var
        T: Text;
        C: Code[20];
        S: Text[5];
    begin
        T := V;
        R := '[' + T + ']';
        C := V;
        R += '[' + C + ']';
        S := V;
        R += '[' + S + ']';
    end;

    local procedure Back(V: Variant): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryBack(V, R) then
            exit(R);
        exit(R + ' E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReturnLabelOrLiteral(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : 'literal');
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
    end;

    local procedure TakeVariant(V: Variant): Text
    begin
        exit(Describe(V));
    end;

    local procedure Pairs(Cond: Boolean; Route: Integer): Text
    var
        V: Variant;
        Arr: array[2] of Variant;
        S: Text;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            1:
                begin
                    V := Cond ? LblA : LblB;
                    S := Describe(V);
                end;
            2:
                begin
                    V := Cond ? LblA : 'literal';
                    S := Describe(V);
                end;
            3:
                begin
                    V := Cond ? 'literal' : LblA;
                    S := Describe(V);
                end;
            4:
                begin
                    V := Cond ? LblA : TxtVar;
                    S := Describe(V);
                end;
            5:
                begin
                    V := Cond ? TxtVar : LblA;
                    S := Describe(V);
                end;
            6:
                begin
                    V := Cond ? LblA : CodeVar;
                    S := Describe(V);
                end;
            7:
                begin
                    V := Cond ? CodeVar : LblA;
                    S := Describe(V);
                end;
            8:
                S := TakeVariant(Cond ? LblA : LblB);
            9:
                S := TakeVariant(Cond ? LblA : 'literal');
            10:
                S := TakeVariant(Cond ? LblA : TxtVar);
            11:
                S := Describe(ReturnLabelOrLiteral(Cond));
            12:
                S := Describe(ReturnLiteralOrLabel(Cond));
            16:
                begin
                    Arr[2] := Cond ? LblA : LblB;
                    S := Describe(Arr[2]);
                end;
            17:
                begin
                    V := Cond ? LblA : LblB;
                    S := Back(V);
                end;
            18:
                begin
                    V := Cond ? LblA : 'literal';
                    S := Back(V);
                end;
            19:
                begin
                    V := Cond ? LblA : CodeVar;
                    S := Back(V);
                end;
        end;
        exit(S);
    end;

    [Test]
    procedure Y81_LabelVariant_Assign()
    var
        Route: Integer;
    begin
        for Route := 1 to 7 do begin
            Observer.Observe('route ' + Format(Route) + ' true', Pairs(true, Route));
            Observer.Observe('route ' + Format(Route) + ' false', Pairs(false, Route));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariant_ParameterAndReturn()
    var
        Route: Integer;
    begin
        for Route := 8 to 12 do begin
            Observer.Observe('route ' + Format(Route) + ' true', Pairs(true, Route));
            Observer.Observe('route ' + Format(Route) + ' false', Pairs(false, Route));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariant_ArrayElement()
    var
        Route: Integer;
    begin
        for Route := 16 to 16 do begin
            Observer.Observe('route ' + Format(Route) + ' true', Pairs(true, Route));
            Observer.Observe('route ' + Format(Route) + ' false', Pairs(false, Route));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariant_TakenBack()
    var
        Route: Integer;
    begin
        for Route := 17 to 19 do begin
            Observer.Observe('route ' + Format(Route) + ' true', Pairs(true, Route));
            Observer.Observe('route ' + Format(Route) + ' false', Pairs(false, Route));
        end;
        Observer.Finish();
    end;
}
