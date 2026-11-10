// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: blank enum values (" " and "" names, with and without a Caption) at the first, middle and last position: Names(), Ordinals(), FromInteger, Format with every format number,
//        Evaluate (boolean and statement form, format 0, 2 and 9) and the error text of a rejected name.
// BC versions: 27, 28, 29

codeunit 67805 "LT OB Enum"
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
    local procedure TryEvFS(Txt: Text; var V: Enum "LT OB Enum FS")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_FS_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FS";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvFS('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFS(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFS(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|1');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are:  ,A,B');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FS_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FS";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_FS_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FS";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum FS".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum FS".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum FS".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum FS".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum FS".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum FS".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum FS".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum FS".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum FS".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum FS".FromInteger(2);
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
    procedure EnumBlank_FS_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FS";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum FS".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum FS".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum FS".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[ ][A][B]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FS_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FS";
        T1: Text[1];
    begin
        O := O::A;
        O := O::" ";
        Observer.Observe('name_o0', Format(O.AsInteger()));
        O := Enum::"LT OB Enum FS".FromInteger(0);
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := Enum::"LT OB Enum FS".FromInteger(1);
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := Enum::"LT OB Enum FS".FromInteger(2);
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := Enum::"LT OB Enum FS".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum FS".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum FS".FromInteger(2);
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
    local procedure TryEvFSCap(Txt: Text; var V: Enum "LT OB Enum FS Cap")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_FSCap_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FS Cap";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvFSCap('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFSCap(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFSCap(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFSCap('zzz', O) then
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|1');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: Cap0,A,B');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FSCap_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FS Cap";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_FSCap_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FS Cap";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum FS Cap".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum FS Cap".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum FS Cap".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum FS Cap".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum FS Cap".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum FS Cap".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum FS Cap".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum FS Cap".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum FS Cap".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum FS Cap".FromInteger(2);
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[Cap0]4:67,97,112,48');
        Observer.Expect('f1', '[A]1:65');
        Observer.Expect('f2', '[B]1:66');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[Cap0][Cap0][0][0]');
        Observer.Expect('f1_n', '[A][A][1][1]');
        Observer.Expect('f2_n', '[B][B][2][2]');
        Observer.Expect('de0', '[Cap0]4:67,97,112,48');
        Observer.Expect('de1', '[A]1:65');
        Observer.Expect('de2', '[B]1:66');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FSCap_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FS Cap";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum FS Cap".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum FS Cap".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum FS Cap".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[ ][A][B]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FSCap_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FS Cap";
        T1: Text;
    begin
        O := O::A;
        O := O::" ";
        Observer.Observe('name_o0', Format(O.AsInteger()));
        O := Enum::"LT OB Enum FS Cap".FromInteger(0);
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := Enum::"LT OB Enum FS Cap".FromInteger(1);
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := Enum::"LT OB Enum FS Cap".FromInteger(2);
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := Enum::"LT OB Enum FS Cap".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum FS Cap".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum FS Cap".FromInteger(2);
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryEvMS(Txt: Text; var V: Enum "LT OB Enum MS")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_MS_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MS";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvMS('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMS(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMS(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|0');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A, ,B');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MS_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MS";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_MS_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MS";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum MS".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum MS".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum MS".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum MS".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum MS".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum MS".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum MS".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum MS".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum MS".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum MS".FromInteger(2);
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
    procedure EnumBlank_MS_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MS";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum MS".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum MS".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum MS".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[A][ ][B]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MS_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MS";
        T1: Text[1];
    begin
        O := O::A;
        O := O::" ";
        Observer.Observe('name_o1', Format(O.AsInteger()));
        O := Enum::"LT OB Enum MS".FromInteger(0);
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := Enum::"LT OB Enum MS".FromInteger(1);
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := Enum::"LT OB Enum MS".FromInteger(2);
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := Enum::"LT OB Enum MS".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum MS".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum MS".FromInteger(2);
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
    local procedure TryEvMSCap(Txt: Text; var V: Enum "LT OB Enum MS Cap")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_MSCap_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MS Cap";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvMSCap('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMSCap(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMSCap(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMSCap('zzz', O) then
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|0');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A,Cap1,B');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MSCap_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MS Cap";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_MSCap_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MS Cap";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum MS Cap".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum MS Cap".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum MS Cap".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum MS Cap".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum MS Cap".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum MS Cap".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum MS Cap".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum MS Cap".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum MS Cap".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum MS Cap".FromInteger(2);
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[A]1:65');
        Observer.Expect('f1', '[Cap1]4:67,97,112,49');
        Observer.Expect('f2', '[B]1:66');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[A][A][0][0]');
        Observer.Expect('f1_n', '[Cap1][Cap1][1][1]');
        Observer.Expect('f2_n', '[B][B][2][2]');
        Observer.Expect('de0', '[A]1:65');
        Observer.Expect('de1', '[Cap1]4:67,97,112,49');
        Observer.Expect('de2', '[B]1:66');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MSCap_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MS Cap";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum MS Cap".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum MS Cap".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum MS Cap".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[A][ ][B]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MSCap_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MS Cap";
        T1: Text;
    begin
        O := O::A;
        O := O::" ";
        Observer.Observe('name_o1', Format(O.AsInteger()));
        O := Enum::"LT OB Enum MS Cap".FromInteger(0);
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := Enum::"LT OB Enum MS Cap".FromInteger(1);
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := Enum::"LT OB Enum MS Cap".FromInteger(2);
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := Enum::"LT OB Enum MS Cap".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum MS Cap".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum MS Cap".FromInteger(2);
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryEvLS(Txt: Text; var V: Enum "LT OB Enum LS")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_LS_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LS";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvLS('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLS(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLS(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|0');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A,B, ');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LS_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LS";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_LS_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LS";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum LS".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum LS".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum LS".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum LS".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum LS".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum LS".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum LS".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum LS".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum LS".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum LS".FromInteger(2);
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
    procedure EnumBlank_LS_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LS";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum LS".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum LS".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum LS".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[A][B][ ]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LS_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LS";
        T1: Text[1];
    begin
        O := O::A;
        O := O::" ";
        Observer.Observe('name_o2', Format(O.AsInteger()));
        O := Enum::"LT OB Enum LS".FromInteger(0);
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := Enum::"LT OB Enum LS".FromInteger(1);
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := Enum::"LT OB Enum LS".FromInteger(2);
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := Enum::"LT OB Enum LS".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum LS".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum LS".FromInteger(2);
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
    local procedure TryEvLSCap(Txt: Text; var V: Enum "LT OB Enum LS Cap")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_LSCap_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LS Cap";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvLSCap('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLSCap(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLSCap(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLSCap('zzz', O) then
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|0');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A,B,Cap2');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LSCap_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LS Cap";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_LSCap_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LS Cap";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum LS Cap".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum LS Cap".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum LS Cap".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum LS Cap".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum LS Cap".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum LS Cap".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum LS Cap".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum LS Cap".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum LS Cap".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum LS Cap".FromInteger(2);
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[A]1:65');
        Observer.Expect('f1', '[B]1:66');
        Observer.Expect('f2', '[Cap2]4:67,97,112,50');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[A][A][0][0]');
        Observer.Expect('f1_n', '[B][B][1][1]');
        Observer.Expect('f2_n', '[Cap2][Cap2][2][2]');
        Observer.Expect('de0', '[A]1:65');
        Observer.Expect('de1', '[B]1:66');
        Observer.Expect('de2', '[Cap2]4:67,97,112,50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LSCap_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LS Cap";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum LS Cap".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum LS Cap".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum LS Cap".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[A][B][ ]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LSCap_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LS Cap";
        T1: Text;
    begin
        O := O::A;
        O := O::" ";
        Observer.Observe('name_o2', Format(O.AsInteger()));
        O := Enum::"LT OB Enum LS Cap".FromInteger(0);
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := Enum::"LT OB Enum LS Cap".FromInteger(1);
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := Enum::"LT OB Enum LS Cap".FromInteger(2);
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := Enum::"LT OB Enum LS Cap".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum LS Cap".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum LS Cap".FromInteger(2);
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryEvFQ(Txt: Text; var V: Enum "LT OB Enum FQ")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_FQ_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FQ";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvFQ('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFQ(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFQ(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFQ('zzz', O) then
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|1');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: ,A,B');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FQ_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FQ";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_FQ_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FQ";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum FQ".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum FQ".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum FQ".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum FQ".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ".FromInteger(2);
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
    procedure EnumBlank_FQ_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FQ";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum FQ".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum FQ".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum FQ".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[][A][B]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FQ_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FQ";
        T1: Text[1];
    begin
        O := Enum::"LT OB Enum FQ".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum FQ".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum FQ".FromInteger(2);
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
    local procedure TryEvFQCap(Txt: Text; var V: Enum "LT OB Enum FQ Cap")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_FQCap_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FQ Cap";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvFQCap('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFQCap(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFQCap(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvFQCap('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'No|1');
        Observer.Expect('ev_sp', 'No|1');
        Observer.Expect('ev_sp2', 'No|1');
        Observer.Expect('ev_nul', 'No|1');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|1');
        Observer.Expect('st_empty', 'err:InvalidOptionString|1');
        Observer.Expect('st_empty_text', ''''' is not an option. The existing options are: Cap0,A,B');
        Observer.Expect('st_sp', 'err:InvalidOptionString|1');
        Observer.Expect('st_sp_text', ''' '' is not an option. The existing options are: Cap0,A,B');
        Observer.Expect('st_nul', 'err:InvalidOptionString|1');
        Observer.Expect('st_nul_text', '''\u0000'' is not an option. The existing options are: Cap0,A,B');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|1');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: C');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FQCap_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FQ Cap";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'No|1');
        Observer.Expect('evf2_empty', 'No|1');
        Observer.Expect('evf9_empty', 'No|1');
        Observer.Expect('evf0_sp', 'No|1');
        Observer.Expect('evf2_sp', 'No|1');
        Observer.Expect('evf9_sp', 'No|1');
        Observer.Expect('evf0_A', 'Yes|1');
        Observer.Expect('evf2_A', 'Yes|1');
        Observer.Expect('evf9_A', 'Yes|1');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FQCap_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FQ Cap";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum FQ Cap".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ Cap".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ Cap".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ Cap".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ Cap".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum FQ Cap".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum FQ Cap".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum FQ Cap".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ Cap".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum FQ Cap".FromInteger(2);
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[Cap0]4:67,97,112,48');
        Observer.Expect('f1', '[A]1:65');
        Observer.Expect('f2', '[B]1:66');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[Cap0][Cap0][0][0]');
        Observer.Expect('f1_n', '[A][A][1][1]');
        Observer.Expect('f2_n', '[B][B][2][2]');
        Observer.Expect('de0', '[Cap0]4:67,97,112,48');
        Observer.Expect('de1', '[A]1:65');
        Observer.Expect('de2', '[B]1:66');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FQCap_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FQ Cap";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum FQ Cap".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum FQ Cap".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum FQ Cap".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[][A][B]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_FQCap_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum FQ Cap";
        T1: Text;
    begin
        O := Enum::"LT OB Enum FQ Cap".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum FQ Cap".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum FQ Cap".FromInteger(2);
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryEvMQ(Txt: Text; var V: Enum "LT OB Enum MQ")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_MQ_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MQ";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvMQ('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMQ(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMQ(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMQ('zzz', O) then
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|0');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A,,B');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MQ_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MQ";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_MQ_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MQ";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum MQ".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum MQ".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum MQ".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum MQ".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ".FromInteger(2);
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
    procedure EnumBlank_MQ_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MQ";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum MQ".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum MQ".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum MQ".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[A][][B]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MQ_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MQ";
        T1: Text[1];
    begin
        O := Enum::"LT OB Enum MQ".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum MQ".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum MQ".FromInteger(2);
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
    local procedure TryEvMQCap(Txt: Text; var V: Enum "LT OB Enum MQ Cap")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_MQCap_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MQ Cap";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvMQCap('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMQCap(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMQCap(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvMQCap('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'No|0');
        Observer.Expect('ev_sp', 'No|0');
        Observer.Expect('ev_sp2', 'No|0');
        Observer.Expect('ev_nul', 'No|0');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('st_empty', 'err:InvalidOptionString|0');
        Observer.Expect('st_empty_text', ''''' is not an option. The existing options are: A,Cap1,B');
        Observer.Expect('st_sp', 'err:InvalidOptionString|0');
        Observer.Expect('st_sp_text', ''' '' is not an option. The existing options are: A,Cap1,B');
        Observer.Expect('st_nul', 'err:InvalidOptionString|0');
        Observer.Expect('st_nul_text', '''\u0000'' is not an option. The existing options are: A,Cap1,B');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|0');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MQCap_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MQ Cap";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'No|0');
        Observer.Expect('evf2_empty', 'No|0');
        Observer.Expect('evf9_empty', 'No|0');
        Observer.Expect('evf0_sp', 'No|0');
        Observer.Expect('evf2_sp', 'No|0');
        Observer.Expect('evf9_sp', 'No|0');
        Observer.Expect('evf0_A', 'Yes|0');
        Observer.Expect('evf2_A', 'Yes|0');
        Observer.Expect('evf9_A', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MQCap_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MQ Cap";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum MQ Cap".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ Cap".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ Cap".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ Cap".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ Cap".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum MQ Cap".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum MQ Cap".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum MQ Cap".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ Cap".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum MQ Cap".FromInteger(2);
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[A]1:65');
        Observer.Expect('f1', '[Cap1]4:67,97,112,49');
        Observer.Expect('f2', '[B]1:66');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[A][A][0][0]');
        Observer.Expect('f1_n', '[Cap1][Cap1][1][1]');
        Observer.Expect('f2_n', '[B][B][2][2]');
        Observer.Expect('de0', '[A]1:65');
        Observer.Expect('de1', '[Cap1]4:67,97,112,49');
        Observer.Expect('de2', '[B]1:66');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MQCap_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MQ Cap";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum MQ Cap".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum MQ Cap".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum MQ Cap".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[A][][B]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_MQCap_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum MQ Cap";
        T1: Text;
    begin
        O := Enum::"LT OB Enum MQ Cap".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum MQ Cap".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum MQ Cap".FromInteger(2);
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryEvLQ(Txt: Text; var V: Enum "LT OB Enum LQ")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_LQ_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LQ";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvLQ('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLQ(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLQ(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLQ('zzz', O) then
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|0');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A,B,');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LQ_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LQ";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_LQ_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LQ";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum LQ".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum LQ".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum LQ".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum LQ".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ".FromInteger(2);
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
    procedure EnumBlank_LQ_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LQ";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum LQ".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum LQ".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum LQ".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[A][B][]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LQ_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LQ";
        T1: Text[1];
    begin
        O := Enum::"LT OB Enum LQ".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum LQ".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum LQ".FromInteger(2);
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
    local procedure TryEvLQCap(Txt: Text; var V: Enum "LT OB Enum LQ Cap")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_LQCap_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LQ Cap";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvLQCap('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLQCap(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLQCap(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvLQCap('zzz', O) then
            Observer.Observe('st_zzz', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_zzz', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_zzz_text', GetLastErrorText());
        end;
        Observer.Expect('ev_empty', 'No|0');
        Observer.Expect('ev_sp', 'No|0');
        Observer.Expect('ev_sp2', 'No|0');
        Observer.Expect('ev_nul', 'No|0');
        Observer.Expect('ev_z', 'Yes|0');
        Observer.Expect('ev_one', 'Yes|1');
        Observer.Expect('ev_A', 'Yes|0');
        Observer.Expect('st_empty', 'err:InvalidOptionString|0');
        Observer.Expect('st_empty_text', ''''' is not an option. The existing options are: A,B,Cap2');
        Observer.Expect('st_sp', 'err:InvalidOptionString|0');
        Observer.Expect('st_sp_text', ''' '' is not an option. The existing options are: A,B,Cap2');
        Observer.Expect('st_nul', 'err:InvalidOptionString|0');
        Observer.Expect('st_nul_text', '''\u0000'' is not an option. The existing options are: A,B,Cap2');
        Observer.Expect('st_zzz', 'err:InvalidOptionString|0');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: A');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LQCap_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LQ Cap";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_A', Format(Evaluate(O, 'A', 9)) + '|' + Format(O, 0, 2));
        Observer.Expect('evf0_empty', 'No|0');
        Observer.Expect('evf2_empty', 'No|0');
        Observer.Expect('evf9_empty', 'No|0');
        Observer.Expect('evf0_sp', 'No|0');
        Observer.Expect('evf2_sp', 'No|0');
        Observer.Expect('evf9_sp', 'No|0');
        Observer.Expect('evf0_A', 'Yes|0');
        Observer.Expect('evf2_A', 'Yes|0');
        Observer.Expect('evf9_A', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LQCap_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LQ Cap";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum LQ Cap".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ Cap".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ Cap".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ Cap".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ Cap".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum LQ Cap".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum LQ Cap".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum LQ Cap".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ Cap".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum LQ Cap".FromInteger(2);
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[A]1:65');
        Observer.Expect('f1', '[B]1:66');
        Observer.Expect('f2', '[Cap2]4:67,97,112,50');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[A][A][0][0]');
        Observer.Expect('f1_n', '[B][B][1][1]');
        Observer.Expect('f2_n', '[Cap2][Cap2][2][2]');
        Observer.Expect('de0', '[A]1:65');
        Observer.Expect('de1', '[B]1:66');
        Observer.Expect('de2', '[Cap2]4:67,97,112,50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LQCap_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LQ Cap";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum LQ Cap".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum LQ Cap".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum LQ Cap".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[A][B][]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_LQCap_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum LQ Cap";
        T1: Text;
    begin
        O := Enum::"LT OB Enum LQ Cap".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum LQ Cap".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum LQ Cap".FromInteger(2);
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryEvQS1(Txt: Text; var V: Enum "LT OB Enum QS1")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_QS1_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS1";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvQS1('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS1(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS1(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|1');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are:  ,A,');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_QS1_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS1";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_QS1_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS1";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum QS1".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum QS1".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum QS1".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum QS1".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1".FromInteger(2);
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
    procedure EnumBlank_QS1_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS1";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum QS1".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum QS1".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum QS1".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[ ][A][]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_QS1_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS1";
        T1: Text[1];
    begin
        O := O::A;
        O := O::" ";
        Observer.Observe('name_o0', Format(O.AsInteger()));
        O := Enum::"LT OB Enum QS1".FromInteger(0);
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := Enum::"LT OB Enum QS1".FromInteger(1);
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := Enum::"LT OB Enum QS1".FromInteger(2);
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := Enum::"LT OB Enum QS1".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum QS1".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum QS1".FromInteger(2);
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
    local procedure TryEvQS1Cap(Txt: Text; var V: Enum "LT OB Enum QS1 Cap")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_QS1Cap_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS1 Cap";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvQS1Cap('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS1Cap(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS1Cap(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS1Cap('zzz', O) then
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|1');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: Cap0,A,Cap2');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_QS1Cap_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS1 Cap";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_QS1Cap_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS1 Cap";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(2);
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[Cap0]4:67,97,112,48');
        Observer.Expect('f1', '[A]1:65');
        Observer.Expect('f2', '[Cap2]4:67,97,112,50');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[Cap0][Cap0][0][0]');
        Observer.Expect('f1_n', '[A][A][1][1]');
        Observer.Expect('f2_n', '[Cap2][Cap2][2][2]');
        Observer.Expect('de0', '[Cap0]4:67,97,112,48');
        Observer.Expect('de1', '[A]1:65');
        Observer.Expect('de2', '[Cap2]4:67,97,112,50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_QS1Cap_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS1 Cap";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[ ][A][]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_QS1Cap_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS1 Cap";
        T1: Text;
    begin
        O := O::A;
        O := O::" ";
        Observer.Observe('name_o0', Format(O.AsInteger()));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(0);
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(1);
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(2);
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum QS1 Cap".FromInteger(2);
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryEvQS2(Txt: Text; var V: Enum "LT OB Enum QS2")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_QS2_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS2";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvQS2('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS2(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS2(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS2('zzz', O) then
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|1');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: ,A, ');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_QS2_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS2";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_QS2_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS2";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum QS2".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum QS2".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum QS2".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum QS2".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2".FromInteger(2);
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
    procedure EnumBlank_QS2_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS2";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum QS2".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum QS2".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum QS2".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[][A][ ]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_QS2_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS2";
        T1: Text[1];
    begin
        O := O::A;
        O := O::" ";
        Observer.Observe('name_o2', Format(O.AsInteger()));
        O := Enum::"LT OB Enum QS2".FromInteger(0);
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := Enum::"LT OB Enum QS2".FromInteger(1);
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := Enum::"LT OB Enum QS2".FromInteger(2);
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := Enum::"LT OB Enum QS2".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum QS2".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum QS2".FromInteger(2);
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

    [TryFunction]
    local procedure TryEvQS2Cap(Txt: Text; var V: Enum "LT OB Enum QS2 Cap")
    begin
        Evaluate(V, Txt);
    end;

    [Test]
    procedure EnumBlank_QS2Cap_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS2 Cap";
    begin
        O := O::A;
        Observer.Observe('ev_empty', Format(Evaluate(O, '')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp', Format(Evaluate(O, ' ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_sp2', Format(Evaluate(O, '  ')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_nul', Format(Evaluate(O, Nul())) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_z', Format(Evaluate(O, '0')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_one', Format(Evaluate(O, '1')) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('ev_A', Format(Evaluate(O, 'A')) + '|' + Format(O, 0, 2));
        O := O::A;
        ClearLastError();
        if TryEvQS2Cap('', O) then
            Observer.Observe('st_empty', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_empty', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_empty_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS2Cap(' ', O) then
            Observer.Observe('st_sp', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_sp', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_sp_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS2Cap(Nul(), O) then
            Observer.Observe('st_nul', 'ok|' + Format(O, 0, 2))
        else begin
            Observer.Observe('st_nul', 'err:' + GetLastErrorCode() + '|' + Format(O, 0, 2));
            Observer.Observe('st_nul_text', GetLastErrorText());
        end;
        O := O::A;
        ClearLastError();
        if TryEvQS2Cap('zzz', O) then
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
        Observer.Expect('st_zzz', 'err:InvalidOptionString|1');
        Observer.Expect('st_zzz_text', '''zzz'' is not an option. The existing options are: Cap0,A,Cap2');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_QS2Cap_EvaluateFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS2 Cap";
    begin
        O := O::A;
        Observer.Observe('evf0_empty', Format(Evaluate(O, '', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_empty', Format(Evaluate(O, '', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_empty', Format(Evaluate(O, '', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_sp', Format(Evaluate(O, ' ', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_sp', Format(Evaluate(O, ' ', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf9_sp', Format(Evaluate(O, ' ', 9)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf0_A', Format(Evaluate(O, 'A', 0)) + '|' + Format(O, 0, 2));
        O := O::A;
        Observer.Observe('evf2_A', Format(Evaluate(O, 'A', 2)) + '|' + Format(O, 0, 2));
        O := O::A;
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
    procedure EnumBlank_QS2Cap_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS2 Cap";
        Saved: Integer;
    begin
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(0);
        Observer.Observe('f0', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(1);
        Observer.Observe('f1', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(2);
        Observer.Observe('f2', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(3);
        Observer.Observe('f3', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(0);
        Observer.Observe('f0_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(1);
        Observer.Observe('f1_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(2);
        Observer.Observe('f2_n', '[' + Format(O, 0, 0) + '][' + Format(O, 0, 1) + '][' + Format(O, 0, 2) + '][' + Format(O, 0, 9) + ']');
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(0);
        Observer.Observe('de0', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(1);
        Observer.Observe('de1', Desc(Format(O)));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(2);
        Observer.Observe('de2', Desc(Format(O)));
        GlobalLanguage(Saved);
        Observer.Expect('f0', '[Cap0]4:67,97,112,48');
        Observer.Expect('f1', '[A]1:65');
        Observer.Expect('f2', '[Cap2]4:67,97,112,50');
        Observer.Expect('f3', '[3]1:51');
        Observer.Expect('f0_n', '[Cap0][Cap0][0][0]');
        Observer.Expect('f1_n', '[A][A][1][1]');
        Observer.Expect('f2_n', '[Cap2][Cap2][2][2]');
        Observer.Expect('de0', '[Cap0]4:67,97,112,48');
        Observer.Expect('de1', '[A]1:65');
        Observer.Expect('de2', '[Cap2]4:67,97,112,50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_QS2Cap_Names()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS2 Cap";
        k: Text;
        Ord: Integer;
        NamesText: Text;
        OrdText: Text;
    begin
        foreach k in O.Names() do
            NamesText += '[' + k + ']';
        Observer.Observe('names', NamesText);
        Observer.Observe('names_count', Format(O.Names().Count()));
        foreach Ord in O.Ordinals() do
            OrdText += Format(Ord) + ',';
        Observer.Observe('ordinals', OrdText);
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(0);
        Observer.Observe('as_int_0', Format(O.AsInteger()));
        Observer.Observe('fmt9_0', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(1);
        Observer.Observe('as_int_1', Format(O.AsInteger()));
        Observer.Observe('fmt9_1', Desc(Format(O, 0, 9)));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(2);
        Observer.Observe('as_int_2', Format(O.AsInteger()));
        Observer.Observe('fmt9_2', Desc(Format(O, 0, 9)));
        Observer.Expect('names', '[][A][ ]');
        Observer.Expect('names_count', '3');
        Observer.Expect('ordinals', '0,1,2,');
        Observer.Expect('as_int_0', '0');
        Observer.Expect('fmt9_0', '[0]1:48');
        Observer.Expect('as_int_1', '1');
        Observer.Expect('fmt9_1', '[1]1:49');
        Observer.Expect('as_int_2', '2');
        Observer.Expect('fmt9_2', '[2]1:50');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlank_QS2Cap_NamesCompare()
    var
        Observer: Codeunit "Probe Observer";
        O: Enum "LT OB Enum QS2 Cap";
        T1: Text;
    begin
        O := O::A;
        O := O::" ";
        Observer.Observe('name_o2', Format(O.AsInteger()));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(0);
        Observer.Observe('cmp_S_o0', Format(O = O::" "));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(1);
        Observer.Observe('cmp_S_o1', Format(O = O::" "));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(2);
        Observer.Observe('cmp_S_o2', Format(O = O::" "));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(0);
        Observer.Observe('blank_o0', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o0', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o0', Desc(T1));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(1);
        Observer.Observe('blank_o1', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o1', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o1', Desc(T1));
        O := Enum::"LT OB Enum QS2 Cap".FromInteger(2);
        Observer.Observe('blank_o2', Format(Format(O) = '') + Format(Format(O) = ' '));
        Observer.Observe('subst_o2', Desc(StrSubstNo('%1', O)));
        T1 := Format(O);
        Observer.Observe('t1_o2', Desc(T1));
        Observer.Finish();
    end;

}
