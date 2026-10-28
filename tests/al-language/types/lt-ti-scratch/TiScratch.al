codeunit 89910 "LT TI Ternary Observe"
{
    Subtype = Test;

    // Code20 : Label 7
    [Test]
    procedure TI_Ternary_CodeTrueLabelFalse_1()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TICodeTrueLabelFalse0(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Code20 : Label 7 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Code20 : Label 20
    [Test]
    procedure TI_Ternary_CodeTrueLabelFalse_2()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TICodeTrueLabelFalse1(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Code20 : Label 20 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Code20 : Label 30
    [Test]
    procedure TI_Ternary_CodeTrueLabelFalse_3()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TICodeTrueLabelFalse2(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Code20 : Label 30 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Label 7 : Code20
    [Test]
    procedure TI_Ternary_LabelTrueCodeFalse_1()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TILabelTrueCodeFalse0(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Label 7 : Code20 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Label 20 : Code20
    [Test]
    procedure TI_Ternary_LabelTrueCodeFalse_2()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TILabelTrueCodeFalse1(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Label 20 : Code20 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Label 30 : Code20
    [Test]
    procedure TI_Ternary_LabelTrueCodeFalse_3()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TILabelTrueCodeFalse2(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Label 30 : Code20 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Text10 : Label 7
    [Test]
    procedure TI_Ternary_TextNLabel_1()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TITextNLabel0(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Text10 : Label 7 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Text10 : Label 10
    [Test]
    procedure TI_Ternary_TextNLabel_2()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TITextNLabel1(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Text10 : Label 10 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Text10 : Label 15
    [Test]
    procedure TI_Ternary_TextNLabel_3()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TITextNLabel2(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Text10 : Label 15 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Label 15 : Text10
    [Test]
    procedure TI_Ternary_TextNLabel_4()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TITextNLabel3(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Label 15 : Text10 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Label 7 : Label 30
    [Test]
    procedure TI_Ternary_LabelLabelAndConst_1()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TILabelLabelAndConst0(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Label 7 : Label 30 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Label 30 : Label 7
    [Test]
    procedure TI_Ternary_LabelLabelAndConst_2()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TILabelLabelAndConst1(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Label 30 : Label 7 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // Label 7 : literal 15
    [Test]
    procedure TI_Ternary_LabelLabelAndConst_3()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TILabelLabelAndConst2(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('Label 7 : literal 15 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    // literal 15 : Label 7
    [Test]
    procedure TI_Ternary_LabelLabelAndConst_4()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        S: Text;
        Kind: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            S := '';
            for Kind := 1 to 6 do begin
                if TILabelLabelAndConst3(T, Kind, R) then
                    S += '[' + R + ']'
                else
                    S += '[E ' + GetLastErrorCode() + ' ' + GetLastErrorText().Replace('The length of the string is ', 'L').Replace(', but it must be less than or equal to ', '/').Replace(' characters. Value: ', ' V:') + ']';
                ClearLastError();
            end;
            Observer.Observe('literal 15 : Label 7 ' + Format(T), S);
        end;
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TICodeTrueLabelFalse0(Cond: Boolean; Kind: Integer; var R: Text)
    var
        C20: Code[20];
        Lbl: Label 'abc def';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        C20 := 'mycode';
        case Kind of
            1: begin RT := Cond ? C20 : Lbl; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? C20 : Lbl; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? C20 : Lbl; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? C20 : Lbl);
            5: R := Format(StrLen(Cond ? C20 : Lbl));
            6: R := Format(Cond ? C20 : Lbl);
        end;
    end;

    [TryFunction]
    local procedure TICodeTrueLabelFalse1(Cond: Boolean; Kind: Integer; var R: Text)
    var
        C20: Code[20];
        Lbl: Label 'abcdefghij klmnopqrs';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        C20 := 'mycode';
        case Kind of
            1: begin RT := Cond ? C20 : Lbl; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? C20 : Lbl; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? C20 : Lbl; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? C20 : Lbl);
            5: R := Format(StrLen(Cond ? C20 : Lbl));
            6: R := Format(Cond ? C20 : Lbl);
        end;
    end;

    [TryFunction]
    local procedure TICodeTrueLabelFalse2(Cond: Boolean; Kind: Integer; var R: Text)
    var
        C20: Code[20];
        Lbl: Label 'abcdefghij klmnopqrst uvwxyz12';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        C20 := 'mycode';
        case Kind of
            1: begin RT := Cond ? C20 : Lbl; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? C20 : Lbl; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? C20 : Lbl; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? C20 : Lbl);
            5: R := Format(StrLen(Cond ? C20 : Lbl));
            6: R := Format(Cond ? C20 : Lbl);
        end;
    end;

    [TryFunction]
    local procedure TILabelTrueCodeFalse0(Cond: Boolean; Kind: Integer; var R: Text)
    var
        C20: Code[20];
        Lbl: Label 'abc def';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        C20 := 'mycode';
        case Kind of
            1: begin RT := Cond ? Lbl : C20; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? Lbl : C20; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? Lbl : C20; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? Lbl : C20);
            5: R := Format(StrLen(Cond ? Lbl : C20));
            6: R := Format(Cond ? Lbl : C20);
        end;
    end;

    [TryFunction]
    local procedure TILabelTrueCodeFalse1(Cond: Boolean; Kind: Integer; var R: Text)
    var
        C20: Code[20];
        Lbl: Label 'abcdefghij klmnopqrs';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        C20 := 'mycode';
        case Kind of
            1: begin RT := Cond ? Lbl : C20; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? Lbl : C20; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? Lbl : C20; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? Lbl : C20);
            5: R := Format(StrLen(Cond ? Lbl : C20));
            6: R := Format(Cond ? Lbl : C20);
        end;
    end;

    [TryFunction]
    local procedure TILabelTrueCodeFalse2(Cond: Boolean; Kind: Integer; var R: Text)
    var
        C20: Code[20];
        Lbl: Label 'abcdefghij klmnopqrst uvwxyz12';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        C20 := 'mycode';
        case Kind of
            1: begin RT := Cond ? Lbl : C20; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? Lbl : C20; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? Lbl : C20; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? Lbl : C20);
            5: R := Format(StrLen(Cond ? Lbl : C20));
            6: R := Format(Cond ? Lbl : C20);
        end;
    end;

    [TryFunction]
    local procedure TITextNLabel0(Cond: Boolean; Kind: Integer; var R: Text)
    var
        T10: Text[10];
        Lbl: Label 'abc def';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        T10 := 'short abc';
        case Kind of
            1: begin RT := Cond ? T10 : Lbl; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? T10 : Lbl; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? T10 : Lbl; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? T10 : Lbl);
            5: R := Format(StrLen(Cond ? T10 : Lbl));
            6: R := Format(Cond ? T10 : Lbl);
        end;
    end;

    [TryFunction]
    local procedure TITextNLabel1(Cond: Boolean; Kind: Integer; var R: Text)
    var
        T10: Text[10];
        Lbl: Label 'abcdefghij';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        T10 := 'short abc';
        case Kind of
            1: begin RT := Cond ? T10 : Lbl; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? T10 : Lbl; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? T10 : Lbl; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? T10 : Lbl);
            5: R := Format(StrLen(Cond ? T10 : Lbl));
            6: R := Format(Cond ? T10 : Lbl);
        end;
    end;

    [TryFunction]
    local procedure TITextNLabel2(Cond: Boolean; Kind: Integer; var R: Text)
    var
        T10: Text[10];
        Lbl: Label 'abcde fghij klm';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        T10 := 'short abc';
        case Kind of
            1: begin RT := Cond ? T10 : Lbl; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? T10 : Lbl; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? T10 : Lbl; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? T10 : Lbl);
            5: R := Format(StrLen(Cond ? T10 : Lbl));
            6: R := Format(Cond ? T10 : Lbl);
        end;
    end;

    [TryFunction]
    local procedure TITextNLabel3(Cond: Boolean; Kind: Integer; var R: Text)
    var
        T10: Text[10];
        Lbl: Label 'abcde fghij klm';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        T10 := 'short abc';
        case Kind of
            1: begin RT := Cond ? Lbl : T10; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? Lbl : T10; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? Lbl : T10; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? Lbl : T10);
            5: R := Format(StrLen(Cond ? Lbl : T10));
            6: R := Format(Cond ? Lbl : T10);
        end;
    end;

    [TryFunction]
    local procedure TILabelLabelAndConst0(Cond: Boolean; Kind: Integer; var R: Text)
    var
        Lbl: Label 'abc def';
        Lbl2: Label 'abcdefghij klmnopqrst uvwxyz12';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        case Kind of
            1: begin RT := Cond ? Lbl : Lbl2; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? Lbl : Lbl2; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? Lbl : Lbl2; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? Lbl : Lbl2);
            5: R := Format(StrLen(Cond ? Lbl : Lbl2));
            6: R := Format(Cond ? Lbl : Lbl2);
        end;
    end;

    [TryFunction]
    local procedure TILabelLabelAndConst1(Cond: Boolean; Kind: Integer; var R: Text)
    var
        Lbl: Label 'abc def';
        Lbl2: Label 'abcdefghij klmnopqrst uvwxyz12';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        case Kind of
            1: begin RT := Cond ? Lbl2 : Lbl; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? Lbl2 : Lbl; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? Lbl2 : Lbl; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? Lbl2 : Lbl);
            5: R := Format(StrLen(Cond ? Lbl2 : Lbl));
            6: R := Format(Cond ? Lbl2 : Lbl);
        end;
    end;

    [TryFunction]
    local procedure TILabelLabelAndConst2(Cond: Boolean; Kind: Integer; var R: Text)
    var
        Lbl: Label 'abc def';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        case Kind of
            1: begin RT := Cond ? Lbl : 'xyz uvw 1234567'; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? Lbl : 'xyz uvw 1234567'; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? Lbl : 'xyz uvw 1234567'; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? Lbl : 'xyz uvw 1234567');
            5: R := Format(StrLen(Cond ? Lbl : 'xyz uvw 1234567'));
            6: R := Format(Cond ? Lbl : 'xyz uvw 1234567');
        end;
    end;

    [TryFunction]
    local procedure TILabelLabelAndConst3(Cond: Boolean; Kind: Integer; var R: Text)
    var
        Lbl: Label 'abc def';
        RT: Text;
        RC20: Code[20];
        RT10: Text[10];
    begin
        case Kind of
            1: begin RT := Cond ? 'xyz uvw 1234567' : Lbl; R := RT + '|' + Format(StrLen(RT)); end;
            2: begin RC20 := Cond ? 'xyz uvw 1234567' : Lbl; R := RC20 + '|' + Format(StrLen(RC20)); end;
            3: begin RT10 := Cond ? 'xyz uvw 1234567' : Lbl; R := RT10 + '|' + Format(StrLen(RT10)); end;
            4: R := TakeCode10(Cond ? 'xyz uvw 1234567' : Lbl);
            5: R := Format(StrLen(Cond ? 'xyz uvw 1234567' : Lbl));
            6: R := Format(Cond ? 'xyz uvw 1234567' : Lbl);
        end;
    end;

    local procedure TakeCode10(C: Code[10]): Text
    begin
        exit(C + '|' + Format(StrLen(C)));
    end;
}
