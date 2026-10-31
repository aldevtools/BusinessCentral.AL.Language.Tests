// Cross-app validate order probe (writer Y20, al-runner issue 6486): a table of cross-app fixture A whose field F has an OnValidate
// trigger, and a table extension of this app that adds OnBeforeValidate and OnAfterValidate to F. Cross-app fixtures B, C and D and
// the AL Language Coverage Tests app add their own. Each trigger appends its tag to Log.
// Tests: tests/al-language/tableextension/lt-bw-cross-app/Y20CrossAppValidateOrder.al.

table 61176 "LT Y20 XA Validate"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K; Code[10]) { }
        field(2; F; Code[10])
        {
            trigger OnValidate()
            begin
                Log += 'table;';
            end;
        }
        field(3; Log; Text[250]) { }
    }
    keys { key(PK; K) { Clustered = true; } }
}

tableextension 61177 "LT Y20 XA Validate Ext" extends "LT Y20 XA Validate"
{
    fields
    {
        modify(F)
        {
            trigger OnBeforeValidate()
            begin
                Log += 'xa-before;';
            end;

            trigger OnAfterValidate()
            begin
                Log += 'xa-after;';
            end;
        }
    }
}
