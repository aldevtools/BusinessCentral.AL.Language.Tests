// A namespaced enum of a corpus dependency app (enum 61172 "LT NQ XA Kind" in namespace XA.Probe.Kinds of AL Language XApp A,
// tests/al-language-xapp-a/NqXaKinds.al) named by its plain name in a local variable, from a file in another namespace without a
// `using` of XA.Probe.Kinds: AL0185, as for the same shape inside one app (al-runner issue 7921, outside reporter, alc 18.1).
// @depends AL Language XApp A,Base Application,System Application
// @expect AL0185 | Enum 'LT NQ XA Kind' is missing
namespace MNC.Probe;

codeunit 50000 "MNC NQ Plain XA Enum Name"
{
    procedure P(): Integer
    var
        K: Enum "LT NQ XA Kind";
    begin
        exit(K.AsInteger());
    end;
}
