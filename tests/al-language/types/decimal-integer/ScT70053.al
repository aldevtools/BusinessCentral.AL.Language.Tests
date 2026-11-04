// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70053
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format of Boolean, Char, Option, Text with format numbers
// BC versions: 29 (27 and 28 by CI)

codeunit 70053 "LT ScT Fmt Bool Char Opt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryF(V: Variant; N: Integer; var R: Text)
    begin
        R := Format(V, 0, N);
    end;

    local procedure F(V: Variant; N: Integer): Text
    var
        R: Text;
    begin
        if TryF(V, N, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Boolean_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
        n: Integer;
    begin
        B := true;
        for n := 0 to 9 do
            Observer.Observe('t' + Format(n), F(B, n));
        B := false;
        for n := 0 to 9 do
            Observer.Observe('f' + Format(n), F(B, n));
        Observer.Expect('t0', 'Yes');
        Observer.Expect('t1', 'Yes');
        Observer.Expect('t2', '1');
        Observer.Expect('t3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('t4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('t5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('t6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('t7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('t8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('t9', 'true');
        Observer.Expect('f0', 'No');
        Observer.Expect('f1', 'No');
        Observer.Expect('f2', '0');
        Observer.Expect('f3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('f4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('f5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('f6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('f7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('f8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('f9', 'false');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_Default()
    var
        Observer: Codeunit "Probe Observer";
        B: Boolean;
    begin
        Observer.Observe('default', Format(B));
        B := true;
        Observer.Observe('true', Format(B));
        Observer.Observe('len3', Format(B, 3));
        Observer.Observe('len10', Format(B, 10));
        Observer.Observe('len-10', Format(B, -10));
        Observer.Observe('literal_true', Format(true));
        Observer.Observe('literal_false', Format(false));
        Observer.Observe('not', Format(not B));
        Observer.Observe('and', Format(B and false));
        Observer.Observe('or', Format(B or false));
        Observer.Observe('xor', Format(B xor true));
        Observer.Expect('default', 'No');
        Observer.Expect('true', 'Yes');
        Observer.Expect('len3', 'Yes');
        Observer.Expect('len10', 'Yes       ');
        Observer.Expect('len-10', 'Yes');
        Observer.Expect('literal_true', 'Yes');
        Observer.Expect('literal_false', 'No');
        Observer.Expect('not', 'No');
        Observer.Expect('and', 'No');
        Observer.Expect('or', 'Yes');
        Observer.Expect('xor', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_FormatString()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('s1', Format(true, 0, '<Standard Format,1>'));
        Observer.Observe('s2', Format(true, 0, '<Standard Format,2>'));
        Observer.Observe('s0', Format(true, 0, '<Standard Format,0>'));
        Observer.Observe('f1', Format(false, 0, '<Standard Format,1>'));
        Observer.Observe('f2', Format(false, 0, '<Standard Format,2>'));
        Observer.Observe('f0', Format(false, 0, '<Standard Format,0>'));
        Observer.Observe('xml', Format(true, 0, 9));
        Observer.Observe('xmlf', Format(false, 0, 9));
        Observer.Expect('s1', 'Yes');
        Observer.Expect('s2', '1');
        Observer.Expect('s0', 'Yes');
        Observer.Expect('f1', 'No');
        Observer.Expect('f2', '0');
        Observer.Expect('f0', 'No');
        Observer.Expect('xml', 'true');
        Observer.Expect('xmlf', 'false');
        Observer.Verify();
    end;

    [Test]
    procedure Char_Format()
    var
        Observer: Codeunit "Probe Observer";
        C: Char;
        n: Integer;
    begin
        C := 'A';
        Observer.Observe('default', Format(C));
        for n := 0 to 9 do
            Observer.Observe('n' + Format(n), F(C, n));
        C := 0;
        Observer.Observe('zero_len', Format(StrLen(Format(C))));
        C := 65;
        Observer.Observe('from_int', Format(C));
        C := 97;
        Observer.Observe('lower', Format(C));
        C := 32;
        Observer.Observe('space_len', Format(StrLen(Format(C))));
        Observer.Expect('default', 'A');
        Observer.Expect('n0', 'A');
        Observer.Expect('n1', 'A');
        Observer.Expect('n2', 'A');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', 'A');
        Observer.Expect('zero_len', '1');
        Observer.Expect('from_int', 'A');
        Observer.Expect('lower', 'a');
        Observer.Expect('space_len', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Option_Format()
    var
        Observer: Codeunit "Probe Observer";
        O: Option Alpha,Beta,"Gamma Delta","";
        n: Integer;
    begin
        O := O::"Gamma Delta";
        Observer.Observe('default', Format(O));
        O := O::Alpha;
        Observer.Observe('first', Format(O));
        O := 3;
        Observer.Observe('blank_len', Format(StrLen(Format(O))));
        Observer.Observe('blank_ord', Format(O, 0, 2));
        Observer.Expect('default', 'Gamma Delta');
        Observer.Expect('first', 'Alpha');
        Observer.Expect('blank_len', '1');
        Observer.Expect('blank_ord', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Option_DefaultFormat()
    var
        Observer: Codeunit "Probe Observer";
        O: Option Alpha,Beta,Gamma;
    begin
        Observer.Observe('default', Format(O));
        Observer.Observe('len3', Format(O, 3));
        Observer.Observe('len-8', Format(O, -8));
        Observer.Observe('len8', Format(O, 8));
        Observer.Observe('std1', Format(O, 0, '<Standard Format,1>'));
        Observer.Observe('std2', Format(O, 0, '<Standard Format,2>'));
        Observer.Observe('std9', Format(O, 0, '<Standard Format,9>'));
        Observer.Expect('default', 'Alpha');
        Observer.Expect('len3', 'Alp');
        Observer.Expect('len-8', 'Alpha');
        Observer.Expect('len8', 'Alpha   ');
        Observer.Expect('std1', 'Alpha');
        Observer.Expect('std2', '0');
        Observer.Expect('std9', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Text_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        n: Integer;
    begin
        T := 'Hello <World> & "x"';
        for n := 0 to 9 do
            Observer.Observe('n' + Format(n), F(T, n));
        Observer.Observe('len5', Format(T, 5));
        Observer.Observe('len-5', Format(T, -5));
        Observer.Observe('len30', Format(T, 30));
        Observer.Expect('n0', 'Hello <World> & "x"');
        Observer.Expect('n1', 'Hello <World> & "x"');
        Observer.Expect('n2', 'Hello <World> & "x"');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', 'Hello <World> & "x"');
        Observer.Expect('len5', 'Hello');
        Observer.Expect('len-5', 'Hello');
        Observer.Expect('len30', 'Hello <World> & "x"           ');
        Observer.Verify();
    end;
}
