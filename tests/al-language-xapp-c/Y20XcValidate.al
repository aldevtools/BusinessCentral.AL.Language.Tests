// Cross-app validate order probe (writer Y20, al-runner issue 6486): this app's table extension adds OnBeforeValidate and
// OnAfterValidate to field F of cross-app fixture A's table "LT Y20 XA Validate"; each appends its tag to Log.
// Tests: tests/al-language/tableextension/lt-bw-cross-app/Y20CrossAppValidateOrder.al.

tableextension 61122 "LT Y20 XC Validate Ext" extends "LT Y20 XA Validate"
{
    fields
    {
        modify(F)
        {
            trigger OnBeforeValidate()
            begin
                Log += 'xc-before;';
            end;

            trigger OnAfterValidate()
            begin
                Log += 'xc-after;';
            end;
        }
    }
}
