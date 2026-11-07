// Support codeunit for TestInterfaceCodeunitStateField.al.
//
/// <summary>
/// Implementation of "IInterface State Provider". Owns a global (instance) var-record
/// field `Probe`. The AL compiler allocates `Probe` inside the codeunit's emitted
/// private InitializeComponent(), which runs only from the codeunit constructor —
/// exercising the same shape an interface-enum cast must keep alive across the cast.
/// </summary>
codeunit 60371 "Interface Impl Vendor" implements "IInterface State Provider"
{
    var
        Probe: Record "ALT Shape 04";

    procedure GetProbedName(): Text
    begin
        Probe."No." := 'PROBE';
        Probe."Name" := 'alive';
        exit(Probe."Name");
    end;
}
