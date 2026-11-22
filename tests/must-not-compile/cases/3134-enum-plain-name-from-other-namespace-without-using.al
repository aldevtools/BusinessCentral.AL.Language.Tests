// A namespaced enum of Base Application ("Sales Document Type", namespace Microsoft.Sales.Document) named by its plain name in a
// local variable, from a file in another namespace that has no `using` of Microsoft.Sales.Document: the name does not resolve.
// The same shape inside one app (al-runner issue 7921, outside reporter, alc 18.1) gives the same AL0185. With the `using`, or with
// the qualified name Microsoft.Sales.Document."Sales Document Type", it compiles.
// @expect AL0185 | Enum 'Sales Document Type' is missing
namespace MNC.Probe;

codeunit 50000 "MNC NQ Plain Enum Name"
{
    procedure P(): Integer
    var
        K: Enum "Sales Document Type";
    begin
        exit(K.AsInteger());
    end;
}
