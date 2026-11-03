// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Rec (74625), enum LT P89 Color (74626)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74632 "LT P89 Is PromptMode"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsPromptMode() then
            R += 'PromptMode,';
        if V.IsOption() then
            R += 'Option,';
        if V.IsInteger() then
            R += 'Integer,';
        if V.IsExecutionMode() then
            R += 'ExecutionMode,';
        exit(R);
    end;

    [Test]
    procedure PromptMode_InVariant()
    var
        Observer: Codeunit "Probe Observer";
        X: PromptMode;
        V: Variant;
    begin
        V := X; Observer.Observe('default', Flags(V));
        X := PromptMode::Prompt;
        V := X; Observer.Observe('prompt', Flags(V));
        Observer.Observe('prompt_format', Format(X));
        V := PromptMode::Prompt; Observer.Observe('literal', Flags(V));
        Observer.Expect('default', 'PromptMode,');
        Observer.Expect('prompt', 'PromptMode,');
        Observer.Expect('prompt_format', 'Prompt');
        Observer.Expect('literal', 'PromptMode,');
        Observer.Verify();
    end;
}
