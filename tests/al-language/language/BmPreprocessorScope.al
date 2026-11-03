// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/directives/devenv-directives-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160), codeunit 81960 (BmPreprocessorDefine.al)
// Corpus #664 item 29: the scope of #define and #undef. BmPreprocessorDefine.al defines LTBMDEFINED and undefines BC27PLUS at its top;
// this file has no directives, so it shows whether those reach a second file of the same app.
// BC versions: 29 (27 and 28 by CI)
codeunit 81961 "LT BM Pp Scope"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BM_Preprocessor_DefineUndefScope()
    var
        Observer: Codeunit "Probe Observer";
        Def: Codeunit "LT BM Pp Define";
    begin
        Observer.Observe('file1_defined_here', Def.DefinedHere());
        Observer.Observe('file1_defined_then_undefined', Def.DefinedThenUndefined());
        Observer.Observe('file1_app_symbol_undefined', Def.AppSymbolUndefined());
        Observer.Observe('file1_and_not', Def.AndNot());
        Observer.Observe('file1_or', Def.OrForm());
        Observer.Observe('file1_parentheses', Def.Parentheses());
        Observer.Observe('file1_elif_chain', Def.ElifChain());
        Observer.Observe('file1_lower_case_symbol', Def.CaseOfSymbol());
        Observer.Observe('file2_sees_define_of_file1', File2Defined());
        Observer.Observe('file2_app_symbol', File2AppSymbol());
        Observer.Expect('file1_defined_here', 'defined');
        Observer.Expect('file1_defined_then_undefined', 'not defined');
        Observer.Expect('file1_app_symbol_undefined', 'not defined');
        Observer.Expect('file1_and_not', 'true');
        Observer.Expect('file1_or', 'false');
        Observer.Expect('file1_parentheses', 'true');
        Observer.Expect('file1_elif_chain', 'elif2');
        Observer.Expect('file1_lower_case_symbol', 'not defined');
        Observer.Expect('file2_sees_define_of_file1', 'not defined');
        Observer.Expect('file2_app_symbol', 'defined');
        Observer.Verify();
    end;

    local procedure File2Defined(): Text
    begin
#if LTBMDEFINED
        exit('defined');
#else
        exit('not defined');
#endif
    end;

    local procedure File2AppSymbol(): Text
    begin
#if BC27PLUS
        exit('defined');
#else
        exit('not defined');
#endif
    end;
}
