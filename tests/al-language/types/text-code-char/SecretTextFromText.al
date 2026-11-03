// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/secrettext/secrettext-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 71885
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: a Text passed where a SecretText is expected: as an argument of SecretStrSubstNo, as a Text variable and as a Text literal passed
//   to a SecretText parameter. Only IsEmpty() is observable in a Cloud app. Already pinned in types/TestSecretText.al: assignment of a
//   Text variable to a SecretText variable and SecretStrSubstNo with SecretText arguments.
// BC versions: 27, 28, 29
codeunit 71885 "LT SecretText From Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Emptiness(Secret: SecretText): Text
    begin
        exit(Format(Secret.IsEmpty()));
    end;

    [Test]
    procedure SecretStrSubstNo_TextArgument()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Text;
        Blank: Text;
        Secret: SecretText;
    begin
        Plain := 'value';
        Secret := SecretStrSubstNo('x=%1', Plain);
        Observer.Observe('text_var_in_template', Format(Secret.IsEmpty()));
        Secret := SecretStrSubstNo('%1', Plain);
        Observer.Observe('text_var_bare_template', Format(Secret.IsEmpty()));
        Secret := SecretStrSubstNo('%1', Blank);
        Observer.Observe('blank_text_bare_template', Format(Secret.IsEmpty()));
        Secret := SecretStrSubstNo('x=%1', Blank);
        Observer.Observe('blank_text_in_template', Format(Secret.IsEmpty()));
        Blank := ' ';
        Secret := SecretStrSubstNo('%1', Blank);
        Observer.Observe('single_space_bare_template', Format(Secret.IsEmpty()));
        Observer.Expect('text_var_in_template', 'No');
        Observer.Expect('text_var_bare_template', 'No');
        Observer.Expect('blank_text_bare_template', 'Yes');
        Observer.Expect('blank_text_in_template', 'No');
        Observer.Expect('single_space_bare_template', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SecretText_TextToParameter()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Text;
        Blank: Text;
        Code20: Code[20];
    begin
        Plain := 'value';
        Observer.Observe('text_var', Emptiness(Plain));
        Observer.Observe('blank_text_var', Emptiness(Blank));
        Observer.Observe('code_var_blank', Emptiness(Code20));
        Code20 := 'ABC';
        Observer.Observe('code_var', Emptiness(Code20));
        Observer.Observe('concatenation', Emptiness(Plain + '!'));
        Observer.Expect('text_var', 'No');
        Observer.Expect('blank_text_var', 'Yes');
        Observer.Expect('code_var_blank', 'Yes');
        Observer.Expect('code_var', 'No');
        Observer.Expect('concatenation', 'No');
        Observer.Verify();
    end;
}
