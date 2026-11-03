#define LTBMDEFINED
#define LTBMSECOND
#undef LTBMSECOND
#undef BC27PLUS
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/directives/devenv-directives-in-al
// Scope: in-scope
// Fixtures used: none (the test codeunit is BmPreprocessorScope.al in this folder)
// Corpus #664 item 29: #define and #undef at the top of this file (they must come before the first token: must-not-compile 1573).
// This file defines LTBMDEFINED, defines and then undefines LTBMSECOND, and undefines the app.json symbol BC27PLUS (defined on every leg).
// Each procedure reports which #if branch was compiled; BmPreprocessorScope.al reads the same symbols in a second file.
// BC versions: 29 (27 and 28 by CI)
codeunit 81960 "LT BM Pp Define"
{
    procedure DefinedHere(): Text
    begin
#if LTBMDEFINED
        exit('defined');
#else
        exit('not defined');
#endif
    end;

    procedure DefinedThenUndefined(): Text
    begin
#if LTBMSECOND
        exit('defined');
#else
        exit('not defined');
#endif
    end;

    procedure AppSymbolUndefined(): Text
    begin
#if BC27PLUS
        exit('defined');
#else
        exit('not defined');
#endif
    end;

    procedure AndNot(): Text
    begin
#if LTBMDEFINED and not BC27PLUS
        exit('true');
#else
        exit('false');
#endif
    end;

    procedure OrForm(): Text
    begin
#if LTBMSECOND or BC27PLUS
        exit('true');
#else
        exit('false');
#endif
    end;

    procedure Parentheses(): Text
    begin
#if (BC27PLUS or LTBMDEFINED) and not (LTBMSECOND)
        exit('true');
#else
        exit('false');
#endif
    end;

    procedure ElifChain(): Text
    begin
#if BC27PLUS
        exit('if');
#elif LTBMSECOND
        exit('elif1');
#elif LTBMDEFINED
        exit('elif2');
#else
        exit('else');
#endif
    end;

    procedure CaseOfSymbol(): Text
    begin
#if ltbmdefined
        exit('defined');
#else
        exit('not defined');
#endif
    end;
}
