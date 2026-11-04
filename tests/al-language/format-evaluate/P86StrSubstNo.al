// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-strsubstno-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects
// Probe: written against BC 29 (P86); the final facts are measured on a local BC 29 tier and added later.
// Facts: StrSubstNo with missing arguments, %%, field width placeholders, repeated and high-numbered placeholders, surplus arguments, texts with %
// BC versions: 29

codeunit 73528 "LT P86 StrSubstNo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySub(Fmt: Text; N: Integer; var R: Text)
    begin
        case N of
            0:
                R := StrSubstNo(Fmt);
            1:
                R := StrSubstNo(Fmt, 'a');
            2:
                R := StrSubstNo(Fmt, 'a', 'b');
            3:
                R := StrSubstNo(Fmt, 'a', 'b', 'c');
            4:
                R := StrSubstNo(Fmt, 'a', 'b', 'c', 'd');
        end;
    end;

    local procedure S(Fmt: Text; N: Integer): Text
    var
        R: Text;
    begin
        R := '<unset>';
        if TrySub(Fmt, N, R) then
            exit('ok|' + R);
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + R);
    end;

    [TryFunction]
    local procedure TrySubNum(Fmt: Text; A1: Integer; A2: Decimal; var R: Text)
    begin
        R := StrSubstNo(Fmt, A1, A2);
    end;

    local procedure SN(Fmt: Text; A1: Integer; A2: Decimal): Text
    var
        R: Text;
    begin
        R := '<unset>';
        if TrySubNum(Fmt, A1, A2, R) then
            exit('ok|' + R);
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + R);
    end;

    [Test]
    procedure Sub_MissingArg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('%1 %2 %3', 2));
        Observer.Observe('t2', S('%3', 2));
        Observer.Observe('t3', S('%3', 0));
        Observer.Observe('t4', S('%2', 1));
        Observer.Observe('t5', S('%1', 0));
        Observer.Observe('t6', S('x%3y', 2));
        Observer.Observe('t7', S('%1 %3', 3));
        Observer.Observe('t8', S('%1%2%3', 1));
        Observer.Observe('t9', S('%4', 3));
        Observer.Observe('t10', S('%1 %2 %3 %4', 4));
        Observer.Observe('t11', S('%2 %1', 2));
        Observer.Observe('t12', S('%3 %2 %1', 3));
        Observer.Expect('t1', 'ok|a b %3');
        Observer.Expect('t2', 'ok|%3');
        Observer.Expect('t3', 'ok|%3');
        Observer.Expect('t4', 'ok|%2');
        Observer.Expect('t5', 'ok|%1');
        Observer.Expect('t6', 'ok|x%3y');
        Observer.Expect('t7', 'ok|a c');
        Observer.Expect('t8', 'ok|a%2%3');
        Observer.Expect('t9', 'ok|%4');
        Observer.Expect('t10', 'ok|a b c d');
        Observer.Expect('t11', 'ok|b a');
        Observer.Expect('t12', 'ok|c b a');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_Percent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('%%', 0));
        Observer.Observe('t2', S('%%', 1));
        Observer.Observe('t3', S('%%1', 1));
        Observer.Observe('t4', S('%%%1', 1));
        Observer.Observe('t5', S('100%', 0));
        Observer.Observe('t6', S('100%', 1));
        Observer.Observe('t7', S('%', 0));
        Observer.Observe('t8', S('%', 1));
        Observer.Observe('t9', S('%1%', 1));
        Observer.Observe('t10', S('%a', 1));
        Observer.Observe('t11', S('%0', 1));
        Observer.Observe('t12', S('%-1', 1));
        Observer.Observe('t13', S('% 1', 1));
        Observer.Observe('t14', S('%1%%2', 2));
        Observer.Observe('t15', S('%%%%', 0));
        Observer.Observe('t16', S('50%% of %1', 1));
        Observer.Observe('t17', S('%1 %% %2', 2));
        Observer.Observe('t18', S('%%1 %1', 1));
        Observer.Observe('t19', S('%01', 1));
        Observer.Observe('t20', S('%001', 1));
        Observer.Expect('t1', 'ok|%%');
        Observer.Expect('t2', 'ok|%%');
        Observer.Expect('t3', 'ok|%a');
        Observer.Expect('t4', 'ok|%%a');
        Observer.Expect('t5', 'ok|100%');
        Observer.Expect('t6', 'ok|100%');
        Observer.Expect('t7', 'ok|%');
        Observer.Expect('t8', 'ok|%');
        Observer.Expect('t9', 'ok|a%');
        Observer.Expect('t10', 'ok|%a');
        Observer.Expect('t11', 'ok|%0');
        Observer.Expect('t12', 'ok|%-1');
        Observer.Expect('t13', 'ok|% 1');
        Observer.Expect('t14', 'ok|a%b');
        Observer.Expect('t15', 'ok|%%%%');
        Observer.Expect('t16', 'ok|50%% of a');
        Observer.Expect('t17', 'ok|a %% b');
        Observer.Expect('t18', 'ok|%a a');
        Observer.Expect('t19', 'ok|%01');
        Observer.Expect('t20', 'ok|%001');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_Repeated()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('%1 %1 %1', 1));
        Observer.Observe('t2', S('%1%1', 1));
        Observer.Observe('t3', S('%2 %1 %2', 2));
        Observer.Observe('t4', S('%1 %2 %1 %2', 2));
        Observer.Observe('t5', S('%1-%1-%1-%1', 1));
        Observer.Observe('t6', S('%2%2', 2));
        Observer.Observe('t7', S('%3 %3', 3));
        Observer.Observe('t8', S('%1%2%3%1', 3));
        Observer.Expect('t1', 'ok|a a a');
        Observer.Expect('t2', 'ok|aa');
        Observer.Expect('t3', 'ok|b a b');
        Observer.Expect('t4', 'ok|a b a b');
        Observer.Expect('t5', 'ok|a-a-a-a');
        Observer.Expect('t6', 'ok|bb');
        Observer.Expect('t7', 'ok|c c');
        Observer.Expect('t8', 'ok|abca');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_Surplus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('x', 1));
        Observer.Observe('t2', S('x', 3));
        Observer.Observe('t3', S('%1', 2));
        Observer.Observe('t4', S('%1', 4));
        Observer.Observe('t5', S('%2', 4));
        Observer.Observe('t6', S('', 2));
        Observer.Observe('t7', S('', 0));
        Observer.Observe('t8', S('%1 %2', 3));
        Observer.Observe('t9', S('%4', 4));
        Observer.Observe('t10', S('plain text', 2));
        Observer.Expect('t1', 'ok|x');
        Observer.Expect('t2', 'ok|x');
        Observer.Expect('t3', 'ok|a');
        Observer.Expect('t4', 'ok|a');
        Observer.Expect('t5', 'ok|b');
        Observer.Expect('t6', 'ok|');
        Observer.Expect('t7', 'ok|');
        Observer.Expect('t8', 'ok|a b');
        Observer.Expect('t9', 'ok|d');
        Observer.Expect('t10', 'ok|plain text');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_FieldWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('#1####', 1));
        Observer.Observe('t2', S('#1####|', 1));
        Observer.Observe('t3', S('#1#', 1));
        Observer.Observe('t4', S('#1', 1));
        Observer.Observe('t5', S('#####', 1));
        Observer.Observe('t6', S('#1####x#2####', 2));
        Observer.Observe('t7', S('[#1######]', 1));
        Observer.Observe('t8', S('#2####', 1));
        Observer.Observe('t9', S('#1####%1', 1));
        Observer.Observe('t10', S('%1#1####', 1));
        Observer.Observe('t11', S('#1###########################', 1));
        Observer.Observe('t12', S('a#1#', 3));
        Observer.Observe('t13', S('#3###', 3));
        Observer.Observe('t14', S('#1####', 0));
        Observer.Observe('t15', S('#1####', 2));
        Observer.Observe('t16', S('# 1###', 1));
        Observer.Observe('t17', S('#0###', 1));
        Observer.Observe('t18', S('##1##', 1));
        Observer.Observe('t19', S('#1#### #1####', 1));
        Observer.Expect('t1', 'ok|a     ');
        Observer.Expect('t2', 'ok|a     |');
        Observer.Expect('t3', 'ok|a  ');
        Observer.Expect('t4', 'ok|a ');
        Observer.Expect('t5', 'ok|#####');
        Observer.Expect('t6', 'ok|a     xb     ');
        Observer.Expect('t7', 'ok|[a       ]');
        Observer.Expect('t8', 'ok|#2####');
        Observer.Expect('t9', 'ok|a     a');
        Observer.Expect('t10', 'ok|aa     ');
        Observer.Expect('t11', 'ok|a                            ');
        Observer.Expect('t12', 'ok|aa  ');
        Observer.Expect('t13', 'ok|c    ');
        Observer.Expect('t14', 'ok|#1####');
        Observer.Expect('t15', 'ok|a     ');
        Observer.Expect('t16', 'ok|# 1###');
        Observer.Expect('t17', 'ok|#0###');
        Observer.Expect('t18', 'ok|a    ');
        Observer.Expect('t19', 'ok|a      a     ');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('', 0));
        Observer.Observe('t2', S('', 1));
        Observer.Observe('t3', S(' ', 1));
        Observer.Observe('t4', S('%1', 1));
        Observer.Observe('t5', S(' %1 ', 1));
        Observer.Observe('t6', S('%1%2', 2));
        Observer.Expect('t1', 'ok|');
        Observer.Expect('t2', 'ok|');
        Observer.Expect('t3', 'ok| ');
        Observer.Expect('t4', 'ok|a');
        Observer.Expect('t5', 'ok| a ');
        Observer.Expect('t6', 'ok|ab');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', SN('%1 %2', 5, 1.5));
        Observer.Observe('t2', SN('%1|%2', -5, -1234567.891));
        Observer.Observe('t3', SN('#1####|#2####', 5, 1.5));
        Observer.Observe('t4', SN('#1####|#2####', -5, -1.5));
        Observer.Observe('t5', SN('#1##|#2##', 123456, 123456.789));
        Observer.Observe('t6', SN('%2 %2', 0, 0));
        Observer.Observe('t7', SN('%1', 1000000, 0));
        Observer.Observe('t8', SN('#2####|', 0, 12.3456789));
        Observer.Observe('t9', SN('%3', 1, 2));
        Observer.Observe('t10', SN('%%2 %2', 1, 2.5));
        Observer.Expect('t1', 'ok|5 1.5');
        Observer.Expect('t2', 'ok|-5|-1,234,567.891');
        Observer.Expect('t3', 'ok|5     |1.5   ');
        Observer.Expect('t4', 'ok|-5    |-1.5  ');
        Observer.Expect('t5', 'ok|****|****');
        Observer.Expect('t6', 'ok|0 0');
        Observer.Expect('t7', 'ok|1000000');
        Observer.Expect('t8', 'ok|******|');
        Observer.Expect('t9', 'ok|%3');
        Observer.Expect('t10', 'ok|%2.5 2.5');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_TenArguments()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', StrSubstNo('%1%2%3%4%5%6%7%8%9%10', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t2', StrSubstNo('%10', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t3', StrSubstNo('%10 %1', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t4', StrSubstNo('%11', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t5', StrSubstNo('%1%2%3%4%5%6%7%8%9%10%11', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t6', StrSubstNo('%1', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t7', StrSubstNo('%10', 'a'));
        Observer.Observe('t8', StrSubstNo('%1%0', 'a'));
        Observer.Expect('t1', 'abcdefghij');
        Observer.Expect('t2', 'j');
        Observer.Expect('t3', 'j a');
        Observer.Expect('t4', '%11');
        Observer.Expect('t5', 'abcdefghij%11');
        Observer.Expect('t6', 'a');
        Observer.Expect('t7', '%10');
        Observer.Expect('t8', 'a%0');
        Observer.Verify();
    end;

    [Test]
    procedure Sub_ArgumentWithPercent()
    var
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := '100%';
        Observer.Observe('t1', StrSubstNo('%1', P));
        Observer.Observe('t2', StrSubstNo('%1 %2', P, '%1'));
        Observer.Observe('t3', StrSubstNo('%1', '%2'));
        Observer.Observe('t4', StrSubstNo('%1', '%%'));
        Observer.Observe('t5', StrSubstNo('%1', '#1####'));
        Observer.Observe('t6', StrSubstNo('#1####|', P));
        Observer.Observe('t7', StrSubstNo('%1%2', '%2', 'x'));
        Observer.Observe('t8', StrSubstNo(P));
        Observer.Observe('t9', StrSubstNo(P, 'a'));
        Observer.Observe('t10', StrSubstNo('%1', ''));
        Observer.Expect('t1', '100%');
        Observer.Expect('t2', '100% %1');
        Observer.Expect('t3', '%2');
        Observer.Expect('t4', '%%');
        Observer.Expect('t5', '#1####');
        Observer.Expect('t6', '100%  |');
        Observer.Expect('t7', '%2x');
        Observer.Expect('t8', '100%');
        Observer.Expect('t9', '100%');
        Observer.Expect('t10', '');
        Observer.Verify();
    end;
}

