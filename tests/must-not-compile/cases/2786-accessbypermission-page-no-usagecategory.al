// @expect AL0167 | The Property 'AccessByPermission' can only be used if the property 'UsageCategory' is set with any of the values of: 'Lists,Tasks,ReportsAndAnalysis,Documents,History,Administration'
// @expect AL0167 | The Property 'AccessByPermission' can only be used if the property 'UsageCategory' is set with any of the values of: 'Lists,Tasks,ReportsAndAnalysis,Documents,History,Administration'
// AccessByPermission on the page object and on the report object needs a UsageCategory of the search kinds; UsageCategory = None is rejected as well (writer Y84, permission probes).
table 50000 "MNC Y84 2786 T"
{
    fields { field(1; Id; Integer) { } }
}

page 50001 "MNC Y84 2786 P"
{
    SourceTable = "MNC Y84 2786 T";
    UsageCategory = None;
    AccessByPermission = tabledata "MNC Y84 2786 T" = R;
}

report 50002 "MNC Y84 2786 R"
{
    ProcessingOnly = true;
    AccessByPermission = tabledata "MNC Y84 2786 T" = R;
}
