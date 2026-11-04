// Fixture of the "LT CU" probes (corpus #670 item 42): a TableNo codeunit in a namespace, started by CuWriteTxTests.al
// (CodeunitRun_ByQualifiedName) with Codeunit.Run(Text) and its namespace-qualified name.
// Scope: in-scope
// Not a test codeunit.
namespace LTCU.Probe;

codeunit 85308 "LT CU Named Run"
{
    TableNo = "LT CU Row";

    trigger OnRun()
    begin
        Rec.Name := 'x';
    end;
}
