// Cross-app fixtures for al-runner issue 7358, the order rule: report 97996 of app A, extended by apps B, D, E and F. The four
// apps depend on A only and not on each other, so no dependency path orders their report extensions.
//   B: extension 61385 "RPT Rule Ext 3" (app c87ced6d-11a6-4ad2-87c7-ac10083d0a2f, Zulu Probe Publisher)
//   D: extension 61166 "RPT Rule Ext 1" (app e92be076-de11-44ed-895e-17031341df29, Mike Probe Publisher)
//   E: extension 61195 "RPT Rule Ext 4" (app 0b3f52e8-9d3a-4f61-b8e2-5a07c3d91f45, Echo Probe Publisher)
//   F: extension 61198 "RPT Rule Ext 2" (app f2a8c113-3c17-4e9a-a5d4-e81b26f07c39, Whiskey Probe Publisher)
// CI publishes D, B, then E and F last. The rules that agree with B before D (reports/extensions/IndependentAppsReportExtensions.al)
// each predict another order:
//   app id as text: E B D F            app id as the bytes of Guid.ToByteArray: F B D E
//   app id as a SQL Server uniqueidentifier, descending: F B E D
//   app name: B D E F                  publisher then name, descending: B F D E
//   publish order, descending: F E B D
//   (not an app rule) extension object id: D E F B; extension name: D F B E.
// Every trigger appends '<app>:<trigger>' to the SingleInstance log 97993.
// Tests: tests/al-language/reports/extensions/IndependentAppsOrderRule.al.
report 97996 "RPT XA Order Rule"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Head; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(HeadNo; Number) { }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('A:pre');
    end;

    var
        Log: Codeunit "RPT XA Indep Log";
}
