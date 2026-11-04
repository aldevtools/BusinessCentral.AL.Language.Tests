// @expect AL0460 | Client-side events are supported only on pages and page extensions.
// @target OnPrem
// A global DotNet variable with both [RunOnClient] and [WithEvents] in a codeunit: client-side events are allowed only on pages and page extensions
// (Microsoft's Camera page and role center activity pages declare their [RunOnClient] [WithEvents] providers on the page). The same declaration on a page
// compiles: tests/al-language-onprem-dotnet/lt-bg-runonclient/Y16RunOnClientShapes.al. Writer Y16.
dotnet
{
    assembly("System")
    {
        type("System.Timers.Timer"; MncY16Timer) { }
    }
}

codeunit 59335 "MNC Y16 RoC WithEvents 2335"
{
    var
        [RunOnClient]
        [WithEvents]
        ClientTimer: DotNet MncY16Timer;

    procedure Run1()
    begin
    end;
}
