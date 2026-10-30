// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-ternary-operator
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: a conditional expression whose true branch is a Text[50] global and whose false branch is a built-in function returning Text
// (CompanyName(), UserId(), Format(x)): X <> '' ? X : CompanyName(). Facts: it compiles; which value each branch yields; the length of the
// result and MaxStrLen of a Text[N] target when the false value is longer than N. Sized-Text pins are in types/lt-qx-ternary-sized.

codeunit 99850 "LT SS Ternary Builtin Holder"
{
    var
        Named: Text[50];

    procedure SetNamed(NewName: Text[50])
    begin
        Named := NewName;
    end;

    procedure Company(): Text
    var
        Result: Text;
    begin
        Result := Named <> '' ? Named : CompanyName();
        exit(Result);
    end;

    procedure User(): Text
    begin
        exit(Named <> '' ? Named : UserId());
    end;

    procedure Formatted(Value: Integer): Text
    begin
        exit(Named <> '' ? Named : Format(Value));
    end;

    procedure CompanyIntoText10(var Target: Text[10])
    begin
        Target := Named <> '' ? Named : CompanyName();
    end;
}

codeunit 99851 "LT SS Ternary Builtin"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Ternary_TextNTrue_BuiltinFalse_ValuesAndLengths()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT SS Ternary Builtin Holder";
    begin
        Observer.Observe('company_empty_is_companyname', Format(Holder.Company() = CompanyName()));
        Observer.Observe('user_empty_is_userid', Format(Holder.User() = UserId()));
        Observer.Observe('format_empty', Holder.Formatted(12345));
        Holder.SetNamed('Named Company');
        Observer.Observe('company_set', Holder.Company());
        Observer.Observe('user_set', Holder.User());
        Observer.Observe('format_set', Holder.Formatted(12345));
        Observer.Observe('company_set_len', Format(StrLen(Holder.Company())));
        Observer.Expect('company_empty_is_companyname', 'Yes');
        Observer.Expect('user_empty_is_userid', 'Yes');
        Observer.Expect('format_empty', '12345');
        Observer.Expect('company_set', 'Named Company');
        Observer.Expect('user_set', 'Named Company');
        Observer.Expect('format_set', 'Named Company');
        Observer.Expect('company_set_len', '13');
        Observer.Verify();
    end;

    [Test]
    procedure Ternary_TextNTrue_BuiltinFalse_IntoShorterTarget()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT SS Ternary Builtin Holder";
        Target: Text[10];
        Ok: Boolean;
    begin
        Holder.SetNamed('Short');
        Holder.CompanyIntoText10(Target);
        Observer.Observe('true_branch_fits', Target);
        Holder.SetNamed('');
        Ok := TryCompanyIntoText10(Holder, Target);
        Observer.Observe('false_branch_long_ok', Format(Ok));
        Observer.Observe('false_branch_long_error', GetLastErrorText());
        Observer.Observe('target_after', Target);
        Observer.Observe('maxstrlen_target', Format(MaxStrLen(Target)));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryCompanyIntoText10(var Holder: Codeunit "LT SS Ternary Builtin Holder"; var Target: Text[10])
    begin
        Holder.CompanyIntoText10(Target);
    end;
}
