// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: blank option members as an Option variable: " ", "" and an unquoted empty member at the first, middle and last position and combinations of two blanks.
//        Evaluate (boolean and statement form, format 0, 2 and 9), Format of every ordinal, the member name forms O::" " and O::"", comparisons and StrSubstNo.
//        Observed on a real BC; each cell is an observation name and the text BC produced.
// BC versions: 27, 28, 29

codeunit 67803 "LT OB Var"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Nul(): Text
    var
        C: Char;
        T: Text;
    begin
        C := 0;
        T := '';
        T += C;
        exit(T);
    end;

    local procedure Desc(T: Text): Text
    var
        i: Integer;
        Code: Integer;
        R: Text;
    begin
        R := '[' + T + ']' + Format(StrLen(T));
        if StrLen(T) > 0 then begin
            R += ':';
            for i := 1 to StrLen(T) do begin
                if i > 4 then
                    break;
                Code := T[i];
                if i > 1 then
                    R += ',';
                R += Format(Code);
            end;
        end;
        exit(R);
    end;

    [TryFunction]
    local procedure TryEvFS(Txt: Text; var V: Option " ",A,B)
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_FS_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option " ",A,B;
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvFS('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvFS(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvFS(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvFS('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'Yes|0');
        Observer.Expect('ev_sp', 'Yes|0');
        Observer.Expect('ev_sp2', 'Yes|0');
        Observer.Expect('ev_nul', 'Yes|0');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('st_empty', 'ok|0');
        Observer.Expect('st_sp', 'ok|0');
        Observer.Expect('st_nul', 'ok|0');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are:  ,A,B');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FS_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option " ",A,B;
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'Yes|0');
        Observer.Expect('evf2_empty', 'Yes|0');
        Observer.Expect('evf9_empty', 'Yes|0');
        Observer.Expect('evf0_sp', 'Yes|0');
        Observer.Expect('evf2_sp', 'Yes|0');
        Observer.Expect('evf9_sp', 'Yes|0');
        Observer.Expect('evf0_A', 'Yes|1');
        Observer.Expect('evf2_A', 'Yes|1');
        Observer.Expect('evf9_A', 'Yes|1');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FS_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option " ",A,B;
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[ ]1:32');
        Observer.Expect('f1', '[A]1:65');
        Observer.Expect('f2', '[B]1:66');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[ ][ ][0][0]');
        Observer.Expect('f1_n', '[A][A][1][1]');
        Observer.Expect('f2_n', '[B][B][2][2]');
        Observer.Expect('de0', '[ ]1:32');
        Observer.Expect('de1', '[A]1:65');
        Observer.Expect('de2', '[B]1:66');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FS_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option " ",A,B;
        T1: Text[1];
    begin
        O := 3;
        O := O::" ";
        Observer.Observe('name_o0', Format(O, 0, 2));
        O := 0;
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := 1;
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := 2;
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('name_o0', '0');
        Observer.Expect('cmp_S_o0', 'Yes');
        Observer.Expect('cmp_S_o1', 'No');
        Observer.Expect('cmp_S_o2', 'No');
        Observer.Expect('blank_o0', 'NoYes');
        Observer.Expect('subst_o0', '[ ]1:32');
        Observer.Expect('t1_o0', '[ ]1:32');
        Observer.Expect('blank_o1', 'NoNo');
        Observer.Expect('subst_o1', '[A]1:65');
        Observer.Expect('t1_o1', '[A]1:65');
        Observer.Expect('blank_o2', 'NoNo');
        Observer.Expect('subst_o2', '[B]1:66');
        Observer.Expect('t1_o2', '[B]1:66');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvMS(Txt: Text; var V: Option A," ",B)
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_MS_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A," ",B;
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvMS('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvMS(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvMS(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvMS('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'Yes|1');
        Observer.Expect('ev_sp', 'Yes|1');
        Observer.Expect('ev_sp2', 'Yes|1');
        Observer.Expect('ev_nul', 'Yes|1');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('st_empty', 'ok|1');
        Observer.Expect('st_sp', 'ok|1');
        Observer.Expect('st_nul', 'ok|1');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A, ,B');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MS_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A," ",B;
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'Yes|1');
        Observer.Expect('evf2_empty', 'Yes|1');
        Observer.Expect('evf9_empty', 'Yes|1');
        Observer.Expect('evf0_sp', 'Yes|1');
        Observer.Expect('evf2_sp', 'Yes|1');
        Observer.Expect('evf9_sp', 'Yes|1');
        Observer.Expect('evf0_A', 'Yes|0');
        Observer.Expect('evf2_A', 'Yes|0');
        Observer.Expect('evf9_A', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MS_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A," ",B;
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[A]1:65');
        Observer.Expect('f1', '[ ]1:32');
        Observer.Expect('f2', '[B]1:66');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[A][A][0][0]');
        Observer.Expect('f1_n', '[ ][ ][1][1]');
        Observer.Expect('f2_n', '[B][B][2][2]');
        Observer.Expect('de0', '[A]1:65');
        Observer.Expect('de1', '[ ]1:32');
        Observer.Expect('de2', '[B]1:66');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MS_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A," ",B;
        T1: Text[1];
    begin
        O := 3;
        O := O::" ";
        Observer.Observe('name_o1', Format(O, 0, 2));
        O := 0;
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := 1;
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := 2;
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('name_o1', '1');
        Observer.Expect('cmp_S_o0', 'No');
        Observer.Expect('cmp_S_o1', 'Yes');
        Observer.Expect('cmp_S_o2', 'No');
        Observer.Expect('blank_o0', 'NoNo');
        Observer.Expect('subst_o0', '[A]1:65');
        Observer.Expect('t1_o0', '[A]1:65');
        Observer.Expect('blank_o1', 'NoYes');
        Observer.Expect('subst_o1', '[ ]1:32');
        Observer.Expect('t1_o1', '[ ]1:32');
        Observer.Expect('blank_o2', 'NoNo');
        Observer.Expect('subst_o2', '[B]1:66');
        Observer.Expect('t1_o2', '[B]1:66');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvLS(Txt: Text; var V: Option A,B," ")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_LS_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B," ";
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvLS('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvLS(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvLS(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvLS('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'Yes|2');
        Observer.Expect('ev_sp', 'Yes|2');
        Observer.Expect('ev_sp2', 'Yes|2');
        Observer.Expect('ev_nul', 'Yes|2');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('st_empty', 'ok|2');
        Observer.Expect('st_sp', 'ok|2');
        Observer.Expect('st_nul', 'ok|2');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A,B, ');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LS_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B," ";
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'Yes|2');
        Observer.Expect('evf2_empty', 'Yes|2');
        Observer.Expect('evf9_empty', 'Yes|2');
        Observer.Expect('evf0_sp', 'Yes|2');
        Observer.Expect('evf2_sp', 'Yes|2');
        Observer.Expect('evf9_sp', 'Yes|2');
        Observer.Expect('evf0_A', 'Yes|0');
        Observer.Expect('evf2_A', 'Yes|0');
        Observer.Expect('evf9_A', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LS_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B," ";
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[A]1:65');
        Observer.Expect('f1', '[B]1:66');
        Observer.Expect('f2', '[ ]1:32');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[A][A][0][0]');
        Observer.Expect('f1_n', '[B][B][1][1]');
        Observer.Expect('f2_n', '[ ][ ][2][2]');
        Observer.Expect('de0', '[A]1:65');
        Observer.Expect('de1', '[B]1:66');
        Observer.Expect('de2', '[ ]1:32');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LS_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B," ";
        T1: Text[1];
    begin
        O := 3;
        O := O::" ";
        Observer.Observe('name_o2', Format(O, 0, 2));
        O := 0;
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := 1;
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := 2;
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('name_o2', '2');
        Observer.Expect('cmp_S_o0', 'No');
        Observer.Expect('cmp_S_o1', 'No');
        Observer.Expect('cmp_S_o2', 'Yes');
        Observer.Expect('blank_o0', 'NoNo');
        Observer.Expect('subst_o0', '[A]1:65');
        Observer.Expect('t1_o0', '[A]1:65');
        Observer.Expect('blank_o1', 'NoNo');
        Observer.Expect('subst_o1', '[B]1:66');
        Observer.Expect('t1_o1', '[B]1:66');
        Observer.Expect('blank_o2', 'NoYes');
        Observer.Expect('subst_o2', '[ ]1:32');
        Observer.Expect('t1_o2', '[ ]1:32');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvFQ(Txt: Text; var V: Option "",A,B)
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_FQ_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option "",A,B;
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvFQ('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvFQ(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvFQ(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvFQ('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('ev_sp2', 'No|3');
        Observer.Expect('ev_nul', 'No|3');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('st_empty', 'err:InvalidOptionString|3');
        Observer.Expect('st_empty_text', ''''' is not an option. The existing options are: ,A,B');
        Observer.Expect('st_sp', 'err:InvalidOptionString|3');
        Observer.Expect('st_sp_text', ''' '' is not an option. The existing options are: ,A,B');
        Observer.Expect('st_nul', 'err:InvalidOptionString|3');
        Observer.Expect('st_nul_text', '''\u0000'' is not an option. The existing options are: ,A,B');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: ,A,B');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FQ_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option "",A,B;
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'No|3');
        Observer.Expect('evf2_empty', 'No|3');
        Observer.Expect('evf9_empty', 'No|3');
        Observer.Expect('evf0_sp', 'No|3');
        Observer.Expect('evf2_sp', 'No|3');
        Observer.Expect('evf9_sp', 'No|3');
        Observer.Expect('evf0_A', 'Yes|1');
        Observer.Expect('evf2_A', 'Yes|1');
        Observer.Expect('evf9_A', 'Yes|1');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FQ_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option "",A,B;
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[0]1:48');
        Observer.Expect('f1', '[A]1:65');
        Observer.Expect('f2', '[B]1:66');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[0][0][0][0]');
        Observer.Expect('f1_n', '[A][A][1][1]');
        Observer.Expect('f2_n', '[B][B][2][2]');
        Observer.Expect('de0', '[0]1:48');
        Observer.Expect('de1', '[A]1:65');
        Observer.Expect('de2', '[B]1:66');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FQ_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option "",A,B;
        T1: Text[1];
    begin
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('blank_o0', 'NoNo');
        Observer.Expect('subst_o0', '[0]1:48');
        Observer.Expect('t1_o0', '[0]1:48');
        Observer.Expect('blank_o1', 'NoNo');
        Observer.Expect('subst_o1', '[A]1:65');
        Observer.Expect('t1_o1', '[A]1:65');
        Observer.Expect('blank_o2', 'NoNo');
        Observer.Expect('subst_o2', '[B]1:66');
        Observer.Expect('t1_o2', '[B]1:66');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvMQ(Txt: Text; var V: Option A,"",B)
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_MQ_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,"",B;
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvMQ('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvMQ(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvMQ(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvMQ('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('ev_sp2', 'No|3');
        Observer.Expect('ev_nul', 'No|3');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('st_empty', 'err:InvalidOptionString|3');
        Observer.Expect('st_empty_text', ''''' is not an option. The existing options are: A,,B');
        Observer.Expect('st_sp', 'err:InvalidOptionString|3');
        Observer.Expect('st_sp_text', ''' '' is not an option. The existing options are: A,,B');
        Observer.Expect('st_nul', 'err:InvalidOptionString|3');
        Observer.Expect('st_nul_text', '''\u0000'' is not an option. The existing options are: A,,B');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A,,B');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MQ_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,"",B;
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'No|3');
        Observer.Expect('evf2_empty', 'No|3');
        Observer.Expect('evf9_empty', 'No|3');
        Observer.Expect('evf0_sp', 'No|3');
        Observer.Expect('evf2_sp', 'No|3');
        Observer.Expect('evf9_sp', 'No|3');
        Observer.Expect('evf0_A', 'Yes|0');
        Observer.Expect('evf2_A', 'Yes|0');
        Observer.Expect('evf9_A', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MQ_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,"",B;
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[A]1:65');
        Observer.Expect('f1', '[1]1:49');
        Observer.Expect('f2', '[B]1:66');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[A][A][0][0]');
        Observer.Expect('f1_n', '[1][1][1][1]');
        Observer.Expect('f2_n', '[B][B][2][2]');
        Observer.Expect('de0', '[A]1:65');
        Observer.Expect('de1', '[1]1:49');
        Observer.Expect('de2', '[B]1:66');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MQ_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,"",B;
        T1: Text[1];
    begin
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('blank_o0', 'NoNo');
        Observer.Expect('subst_o0', '[A]1:65');
        Observer.Expect('t1_o0', '[A]1:65');
        Observer.Expect('blank_o1', 'NoNo');
        Observer.Expect('subst_o1', '[1]1:49');
        Observer.Expect('t1_o1', '[1]1:49');
        Observer.Expect('blank_o2', 'NoNo');
        Observer.Expect('subst_o2', '[B]1:66');
        Observer.Expect('t1_o2', '[B]1:66');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvLQ(Txt: Text; var V: Option A,B,"")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_LQ_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,"";
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvLQ('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvLQ(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvLQ(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvLQ('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('ev_sp2', 'No|3');
        Observer.Expect('ev_nul', 'No|3');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('st_empty', 'err:InvalidOptionString|3');
        Observer.Expect('st_empty_text', ''''' is not an option. The existing options are: A,B,');
        Observer.Expect('st_sp', 'err:InvalidOptionString|3');
        Observer.Expect('st_sp_text', ''' '' is not an option. The existing options are: A,B,');
        Observer.Expect('st_nul', 'err:InvalidOptionString|3');
        Observer.Expect('st_nul_text', '''\u0000'' is not an option. The existing options are: A,B,');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A,B,');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LQ_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,"";
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'No|3');
        Observer.Expect('evf2_empty', 'No|3');
        Observer.Expect('evf9_empty', 'No|3');
        Observer.Expect('evf0_sp', 'No|3');
        Observer.Expect('evf2_sp', 'No|3');
        Observer.Expect('evf9_sp', 'No|3');
        Observer.Expect('evf0_A', 'Yes|0');
        Observer.Expect('evf2_A', 'Yes|0');
        Observer.Expect('evf9_A', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LQ_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,"";
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[A]1:65');
        Observer.Expect('f1', '[B]1:66');
        Observer.Expect('f2', '[2]1:50');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[A][A][0][0]');
        Observer.Expect('f1_n', '[B][B][1][1]');
        Observer.Expect('f2_n', '[2][2][2][2]');
        Observer.Expect('de0', '[A]1:65');
        Observer.Expect('de1', '[B]1:66');
        Observer.Expect('de2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LQ_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,"";
        T1: Text[1];
    begin
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('blank_o0', 'NoNo');
        Observer.Expect('subst_o0', '[A]1:65');
        Observer.Expect('t1_o0', '[A]1:65');
        Observer.Expect('blank_o1', 'NoNo');
        Observer.Expect('subst_o1', '[B]1:66');
        Observer.Expect('t1_o1', '[B]1:66');
        Observer.Expect('blank_o2', 'NoNo');
        Observer.Expect('subst_o2', '[2]1:50');
        Observer.Expect('t1_o2', '[2]1:50');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvFU(Txt: Text; var V: Option ,A,B)
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_FU_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option ,A,B;
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvFU('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvFU(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvFU(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvFU('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('ev_sp2', 'No|3');
        Observer.Expect('ev_nul', 'No|3');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('st_empty', 'err:InvalidOptionString|3');
        Observer.Expect('st_empty_text', ''''' is not an option. The existing options are: ,A,B');
        Observer.Expect('st_sp', 'err:InvalidOptionString|3');
        Observer.Expect('st_sp_text', ''' '' is not an option. The existing options are: ,A,B');
        Observer.Expect('st_nul', 'err:InvalidOptionString|3');
        Observer.Expect('st_nul_text', '''\u0000'' is not an option. The existing options are: ,A,B');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: ,A,B');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FU_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option ,A,B;
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'No|3');
        Observer.Expect('evf2_empty', 'No|3');
        Observer.Expect('evf9_empty', 'No|3');
        Observer.Expect('evf0_sp', 'No|3');
        Observer.Expect('evf2_sp', 'No|3');
        Observer.Expect('evf9_sp', 'No|3');
        Observer.Expect('evf0_A', 'Yes|1');
        Observer.Expect('evf2_A', 'Yes|1');
        Observer.Expect('evf9_A', 'Yes|1');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FU_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option ,A,B;
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[0]1:48');
        Observer.Expect('f1', '[A]1:65');
        Observer.Expect('f2', '[B]1:66');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[0][0][0][0]');
        Observer.Expect('f1_n', '[A][A][1][1]');
        Observer.Expect('f2_n', '[B][B][2][2]');
        Observer.Expect('de0', '[0]1:48');
        Observer.Expect('de1', '[A]1:65');
        Observer.Expect('de2', '[B]1:66');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_FU_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option ,A,B;
        T1: Text[1];
    begin
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('blank_o0', 'NoNo');
        Observer.Expect('subst_o0', '[0]1:48');
        Observer.Expect('t1_o0', '[0]1:48');
        Observer.Expect('blank_o1', 'NoNo');
        Observer.Expect('subst_o1', '[A]1:65');
        Observer.Expect('t1_o1', '[A]1:65');
        Observer.Expect('blank_o2', 'NoNo');
        Observer.Expect('subst_o2', '[B]1:66');
        Observer.Expect('t1_o2', '[B]1:66');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvMU(Txt: Text; var V: Option A,,B)
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_MU_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,,B;
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvMU('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvMU(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvMU(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvMU('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('ev_sp2', 'No|3');
        Observer.Expect('ev_nul', 'No|3');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('st_empty', 'err:InvalidOptionString|3');
        Observer.Expect('st_empty_text', ''''' is not an option. The existing options are: A,,B');
        Observer.Expect('st_sp', 'err:InvalidOptionString|3');
        Observer.Expect('st_sp_text', ''' '' is not an option. The existing options are: A,,B');
        Observer.Expect('st_nul', 'err:InvalidOptionString|3');
        Observer.Expect('st_nul_text', '''\u0000'' is not an option. The existing options are: A,,B');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A,,B');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MU_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,,B;
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'No|3');
        Observer.Expect('evf2_empty', 'No|3');
        Observer.Expect('evf9_empty', 'No|3');
        Observer.Expect('evf0_sp', 'No|3');
        Observer.Expect('evf2_sp', 'No|3');
        Observer.Expect('evf9_sp', 'No|3');
        Observer.Expect('evf0_A', 'Yes|0');
        Observer.Expect('evf2_A', 'Yes|0');
        Observer.Expect('evf9_A', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MU_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,,B;
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[A]1:65');
        Observer.Expect('f1', '[1]1:49');
        Observer.Expect('f2', '[B]1:66');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[A][A][0][0]');
        Observer.Expect('f1_n', '[1][1][1][1]');
        Observer.Expect('f2_n', '[B][B][2][2]');
        Observer.Expect('de0', '[A]1:65');
        Observer.Expect('de1', '[1]1:49');
        Observer.Expect('de2', '[B]1:66');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_MU_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,,B;
        T1: Text[1];
    begin
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('blank_o0', 'NoNo');
        Observer.Expect('subst_o0', '[A]1:65');
        Observer.Expect('t1_o0', '[A]1:65');
        Observer.Expect('blank_o1', 'NoNo');
        Observer.Expect('subst_o1', '[1]1:49');
        Observer.Expect('t1_o1', '[1]1:49');
        Observer.Expect('blank_o2', 'NoNo');
        Observer.Expect('subst_o2', '[B]1:66');
        Observer.Expect('t1_o2', '[B]1:66');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvLU(Txt: Text; var V: Option A,B,)
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_LU_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,;
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvLU('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvLU(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvLU(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvLU('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'No|3');
        Observer.Expect('ev_sp', 'No|3');
        Observer.Expect('ev_sp2', 'No|3');
        Observer.Expect('ev_nul', 'No|3');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('st_empty', 'err:InvalidOptionString|3');
        Observer.Expect('st_empty_text', ''''' is not an option. The existing options are: A,B,');
        Observer.Expect('st_sp', 'err:InvalidOptionString|3');
        Observer.Expect('st_sp_text', ''' '' is not an option. The existing options are: A,B,');
        Observer.Expect('st_nul', 'err:InvalidOptionString|3');
        Observer.Expect('st_nul_text', '''\u0000'' is not an option. The existing options are: A,B,');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A,B,');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LU_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,;
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'No|3');
        Observer.Expect('evf2_empty', 'No|3');
        Observer.Expect('evf9_empty', 'No|3');
        Observer.Expect('evf0_sp', 'No|3');
        Observer.Expect('evf2_sp', 'No|3');
        Observer.Expect('evf9_sp', 'No|3');
        Observer.Expect('evf0_A', 'Yes|0');
        Observer.Expect('evf2_A', 'Yes|0');
        Observer.Expect('evf9_A', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LU_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,;
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[A]1:65');
        Observer.Expect('f1', '[B]1:66');
        Observer.Expect('f2', '[2]1:50');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[A][A][0][0]');
        Observer.Expect('f1_n', '[B][B][1][1]');
        Observer.Expect('f2_n', '[2][2][2][2]');
        Observer.Expect('de0', '[A]1:65');
        Observer.Expect('de1', '[B]1:66');
        Observer.Expect('de2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_LU_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,;
        T1: Text[1];
    begin
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('blank_o0', 'NoNo');
        Observer.Expect('subst_o0', '[A]1:65');
        Observer.Expect('t1_o0', '[A]1:65');
        Observer.Expect('blank_o1', 'NoNo');
        Observer.Expect('subst_o1', '[B]1:66');
        Observer.Expect('t1_o1', '[B]1:66');
        Observer.Expect('blank_o2', 'NoNo');
        Observer.Expect('subst_o2', '[2]1:50');
        Observer.Expect('t1_o2', '[2]1:50');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvQS1(Txt: Text; var V: Option " ",A,"")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_QS1_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option " ",A,"";
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvQS1('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvQS1(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvQS1(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvQS1('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'Yes|0');
        Observer.Expect('ev_sp', 'Yes|0');
        Observer.Expect('ev_sp2', 'Yes|0');
        Observer.Expect('ev_nul', 'Yes|0');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('st_empty', 'ok|0');
        Observer.Expect('st_sp', 'ok|0');
        Observer.Expect('st_nul', 'ok|0');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are:  ,A,');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS1_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option " ",A,"";
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'Yes|0');
        Observer.Expect('evf2_empty', 'Yes|0');
        Observer.Expect('evf9_empty', 'Yes|0');
        Observer.Expect('evf0_sp', 'Yes|0');
        Observer.Expect('evf2_sp', 'Yes|0');
        Observer.Expect('evf9_sp', 'Yes|0');
        Observer.Expect('evf0_A', 'Yes|1');
        Observer.Expect('evf2_A', 'Yes|1');
        Observer.Expect('evf9_A', 'Yes|1');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS1_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option " ",A,"";
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[ ]1:32');
        Observer.Expect('f1', '[A]1:65');
        Observer.Expect('f2', '[2]1:50');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[ ][ ][0][0]');
        Observer.Expect('f1_n', '[A][A][1][1]');
        Observer.Expect('f2_n', '[2][2][2][2]');
        Observer.Expect('de0', '[ ]1:32');
        Observer.Expect('de1', '[A]1:65');
        Observer.Expect('de2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS1_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option " ",A,"";
        T1: Text[1];
    begin
        O := 3;
        O := O::" ";
        Observer.Observe('name_o0', Format(O, 0, 2));
        O := 0;
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := 1;
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := 2;
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('name_o0', '0');
        Observer.Expect('cmp_S_o0', 'Yes');
        Observer.Expect('cmp_S_o1', 'No');
        Observer.Expect('cmp_S_o2', 'No');
        Observer.Expect('blank_o0', 'NoYes');
        Observer.Expect('subst_o0', '[ ]1:32');
        Observer.Expect('t1_o0', '[ ]1:32');
        Observer.Expect('blank_o1', 'NoNo');
        Observer.Expect('subst_o1', '[A]1:65');
        Observer.Expect('t1_o1', '[A]1:65');
        Observer.Expect('blank_o2', 'NoNo');
        Observer.Expect('subst_o2', '[2]1:50');
        Observer.Expect('t1_o2', '[2]1:50');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvQS2(Txt: Text; var V: Option "",A," ")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure OptionBlank_QS2_Var_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Option "",A," ";
    begin
        O := 3;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := 3;
        ClearLastError();
        if TryEvQS2('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvQS2(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvQS2(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := 3;
        ClearLastError();
        if TryEvQS2('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'Yes|2');
        Observer.Expect('ev_sp', 'Yes|2');
        Observer.Expect('ev_sp2', 'Yes|2');
        Observer.Expect('ev_nul', 'Yes|2');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('st_empty', 'ok|2');
        Observer.Expect('st_sp', 'ok|2');
        Observer.Expect('st_nul', 'ok|2');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|3');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: ,A, ');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS2_Var_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option "",A," ";
    begin
        O := 3;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := 3;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'Yes|2');
        Observer.Expect('evf2_empty', 'Yes|2');
        Observer.Expect('evf9_empty', 'Yes|2');
        Observer.Expect('evf0_sp', 'Yes|2');
        Observer.Expect('evf2_sp', 'Yes|2');
        Observer.Expect('evf9_sp', 'Yes|2');
        Observer.Expect('evf0_A', 'Yes|1');
        Observer.Expect('evf2_A', 'Yes|1');
        Observer.Expect('evf9_A', 'Yes|1');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS2_Var_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option "",A," ";
        Saved: Integer;
    begin
        O := 0;
        Observer.Observe('f0', Desc(Format(O)));
        O := 1;
        Observer.Observe('f1', Desc(Format(O)));
        O := 2;
        Observer.Observe('f2', Desc(Format(O)));
        O := 3;
        Observer.Observe('f3', Desc(Format(O)));
        O := 0;
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 1;
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := 2;
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := 0;
        Observer.Observe('de0', Desc(Format(O)));
        O := 1;
        Observer.Observe('de1', Desc(Format(O)));
        O := 2;
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[0]1:48');
        Observer.Expect('f1', '[A]1:65');
        Observer.Expect('f2', '[ ]1:32');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[0][0][0][0]');
        Observer.Expect('f1_n', '[A][A][1][1]');
        Observer.Expect('f2_n', '[ ][ ][2][2]');
        Observer.Expect('de0', '[0]1:48');
        Observer.Expect('de1', '[A]1:65');
        Observer.Expect('de2', '[ ]1:32');
        Observer.Verify();
    end;

    [Test]
    procedure OptionBlank_QS2_Var_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Option "",A," ";
        T1: Text[1];
    begin
        O := 3;
        O := O::" ";
        Observer.Observe('name_o2', Format(O, 0, 2));
        O := 0;
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := 1;
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := 2;
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := 0;
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := 1;
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := 2;
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Expect('name_o2', '2');
        Observer.Expect('cmp_S_o0', 'No');
        Observer.Expect('cmp_S_o1', 'No');
        Observer.Expect('cmp_S_o2', 'Yes');
        Observer.Expect('blank_o0', 'NoNo');
        Observer.Expect('subst_o0', '[0]1:48');
        Observer.Expect('t1_o0', '[0]1:48');
        Observer.Expect('blank_o1', 'NoNo');
        Observer.Expect('subst_o1', '[A]1:65');
        Observer.Expect('t1_o1', '[A]1:65');
        Observer.Expect('blank_o2', 'NoYes');
        Observer.Expect('subst_o2', '[ ]1:32');
        Observer.Expect('t1_o2', '[ ]1:32');
        Observer.Verify();
    end;

}
