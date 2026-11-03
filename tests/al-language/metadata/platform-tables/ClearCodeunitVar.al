// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73999
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: Clear on a codeunit variable: state restarts; SingleInstance codeunit keeps state
// BC versions: 29
// Tag: P95

codeunit 73997 "LT P95 State 73997"
{
    var
        Counter: Integer;
        Name: Text;

    procedure Bump(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;

    procedure SetName(N: Text)
    begin
        Name := N;
    end;

    procedure GetName(): Text
    begin
        exit(Name);
    end;
}

codeunit 73998 "LT P95 Single 73998"
{
    SingleInstance = true;

    var
        Counter: Integer;

    procedure Bump(): Integer
    begin
        Counter += 1;
        exit(Counter);
    end;
}

codeunit 73999 "LT P95 Clear Codeunit"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearCodeunitVar()
    var
        Observer: Codeunit "Probe Observer";
        St: Codeunit "LT P95 State 73997";
        Sg: Codeunit "LT P95 Single 73998";
        Sg2: Codeunit "LT P95 Single 73998";
    begin
        St.Bump();
        St.Bump();
        St.SetName('x');
        Observer.Observe('before', Format(St.Bump()) + '|' + St.GetName());
        Clear(St);
        Observer.Observe('after_clear', Format(St.Bump()) + '|[' + St.GetName() + ']');
        Clear(St);
        Clear(St);
        Observer.Observe('clear_twice', Format(St.Bump()));
        Sg.Bump();
        Sg.Bump();
        Observer.Observe('single_before', Format(Sg.Bump()));
        Clear(Sg);
        Observer.Observe('single_after_clear', Format(Sg.Bump()));
        Sg2.Bump();
        Observer.Observe('single_second_var_shares', Format(Sg2.Bump()));
        Clear(Sg2);
        Observer.Observe('single_after_second_clear', Format(Sg.Bump()));

        Observer.Expect('before', '3|x');
        Observer.Expect('after_clear', '1|[]');
        Observer.Expect('clear_twice', '1');
        Observer.Expect('single_before', '3');
        Observer.Expect('single_after_clear', '4');
        Observer.Expect('single_second_var_shares', '6');
        Observer.Expect('single_after_second_clear', '7');
        Observer.Verify();
    end;

}
