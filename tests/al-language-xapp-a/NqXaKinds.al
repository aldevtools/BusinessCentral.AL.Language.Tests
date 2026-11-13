// A namespaced enum of cross-app fixture A for must-not-compile case 3135 (al-runner issue 7921): a dependent app that names it by
// its plain name, from another namespace and without a `using`, gets AL0185.
// local object: the enum's namespace is under test.
namespace XA.Probe.Kinds;

enum 61172 "LT NQ XA Kind"
{
    Extensible = true;
    value(0; Zero) { }
    value(1; One) { }
}
