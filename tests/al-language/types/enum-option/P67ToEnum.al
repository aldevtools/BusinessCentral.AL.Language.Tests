// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums 70190-70194 (P67Defs.al), self-contained test codeunit 70200
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: P67 Evaluate and FromInteger into an Enum from Text, Code, Decimal, BigInteger
// BC versions: 29 (27 and 28 by CI)

codeunit 70200 "LT P67 To Enum Eval"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EvaluateFromText()
    var
        Observer: Codeunit "Probe Observer";
        D: Enum "LT P67 Dst";
        T: Text;
        Ok: Boolean;
    begin
        T := 'Uno';
        Ok := Evaluate(D, T);
        Observer.Observe('uno', Format(Ok) + '|' + Format(D));
        T := 'tres';
        Ok := Evaluate(D, T);
        Observer.Observe('tres_lower', Format(Ok) + '|' + Format(D));
        T := 'Tres Cap';
        Ok := Evaluate(D, T);
        Observer.Observe('caption', Format(Ok) + '|' + Format(D));
        T := '2';
        Ok := Evaluate(D, T);
        Observer.Observe('ordinal2', Format(Ok) + '|' + Format(D));
        T := '7';
        D := D::Dos;
        Ok := Evaluate(D, T);
        Observer.Observe('ordinal7', Format(Ok) + '|[' + Format(D) + ']|' + Format(D.AsInteger()));
        T := '';
        D := D::Dos;
        Ok := Evaluate(D, T);
        Observer.Observe('blank', Format(Ok) + '|[' + Format(D) + ']');
        T := 'Nope';
        D := D::Dos;
        Ok := Evaluate(D, T);
        Observer.Observe('unknown', Format(Ok) + '|[' + Format(D) + ']');
        Observer.Expect('uno', 'Yes|Uno');
        Observer.Expect('tres_lower', 'Yes|Tres Cap');
        Observer.Expect('caption', 'Yes|Tres Cap');
        Observer.Expect('ordinal2', 'Yes|Dos');
        Observer.Expect('ordinal7', 'Yes|[7]|7');
        Observer.Expect('blank', 'No|[Dos]');
        Observer.Expect('unknown', 'No|[Dos]');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateFromText_Errors()
    var
        Observer: Codeunit "Probe Observer";
        D: Enum "LT P67 Dst";
        T: Text;
    begin
        T := 'Nope';
        asserterror Evaluate(D, T);
        Observer.ObserveError('unknown_ignored');
        Observer.Observe('unknown_text', GetLastErrorText());
        Observer.Expect('unknown_ignored|text', '''Nope'' is not an option. The existing options are: None,Uno,Dos,Tres Cap');
        Observer.Expect('unknown_ignored|code', 'InvalidOptionString');
        Observer.Expect('unknown_text', '');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateFromCode()
    var
        Observer: Codeunit "Probe Observer";
        D: Enum "LT P67 Dst";
        C: Code[20];
        Ok: Boolean;
    begin
        C := 'UNO';
        Ok := Evaluate(D, C);
        Observer.Observe('uno_upper', Format(Ok) + '|' + Format(D));
        C := 'DOS';
        Ok := Evaluate(D, C);
        Observer.Observe('dos_upper', Format(Ok) + '|' + Format(D));
        C := '3';
        Ok := Evaluate(D, C);
        Observer.Observe('ordinal3', Format(Ok) + '|' + Format(D));
        Observer.Expect('uno_upper', 'Yes|Uno');
        Observer.Expect('dos_upper', 'Yes|Dos');
        Observer.Expect('ordinal3', 'Yes|Tres Cap');
        Observer.Verify();
    end;

    [Test]
    procedure FromIntegerLackingAndNegative()
    var
        Observer: Codeunit "Probe Observer";
        D: Enum "LT P67 Dst";
    begin
        D := Enum::"LT P67 Dst".FromInteger(7);
        Observer.Observe('lacking7', 'no error');
        D := Enum::"LT P67 Dst".FromInteger(-1);
        Observer.Observe('negative', 'no error');
        D := Enum::"LT P67 Dst".FromInteger(0);
        Observer.Observe('zero', Format(D));
        Observer.Expect('lacking7', 'no error');
        Observer.Expect('negative', 'no error');
        Observer.Expect('zero', 'None');
        Observer.Verify();
    end;
}
