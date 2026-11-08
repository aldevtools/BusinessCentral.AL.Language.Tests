// Objects of cross-app fixture B for the cross-app protected variable probe (al-runner issues 6983 and 6984).
// Tests: tests/al-language/table-objects/extensions/ProtectedVarCrossApp.al.
//   95524: extends cross-app fixture A's table 95520. It reads and writes the protected variables of that table (BaseText, BaseFlag) and
//          of A's extension 95521 (ExtHide, ExtText), on Rec (bare name) and on another record variable of the table (Other.ExtHide);
//          a field trigger reads ExtHide (the shape of issue 6983); it declares a protected variable of its own (XbCounter).
// local object: the protected variable declarations and uses of this object are under test.

tableextension 95524 "TBL ProtVar XB Ext" extends "TBL ProtVar XA Table"
{
    fields
    {
        field(95524; "XB Weight"; Decimal)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if not ExtHide and ("XB Weight" <> 0) then
                    "XB Synced" := true
                else
                    "XB Synced" := false;
            end;
        }
        field(95525; "XB Synced"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    protected var
        XbCounter: Integer;

    // Rec: the bare names.
    procedure XbGetExtHide(): Boolean
    begin
        exit(ExtHide);
    end;

    procedure XbSetExtHide(Value: Boolean)
    begin
        ExtHide := Value;
    end;

    procedure XbSetExtText(Value: Text)
    begin
        ExtText := Value;
    end;

    procedure XbGetBaseText(): Text
    begin
        exit(BaseText);
    end;

    procedure XbSetBaseText(Value: Text)
    begin
        BaseText := Value;
    end;

    procedure XbSetBaseFlag(Value: Boolean)
    begin
        BaseFlag := Value;
    end;

    procedure XbGetCounter(): Integer
    begin
        exit(XbCounter);
    end;

    procedure XbSetCounter(Value: Integer)
    begin
        XbCounter := Value;
    end;

    // Another record variable of the same table: the member form.
    procedure XbSetOtherExtHide(var Other: Record "TBL ProtVar XA Table"; Value: Boolean)
    begin
        Other.ExtHide := Value;
    end;

    procedure XbGetOtherExtHide(var Other: Record "TBL ProtVar XA Table"): Boolean
    begin
        exit(Other.ExtHide);
    end;

    procedure XbSetOtherBaseText(var Other: Record "TBL ProtVar XA Table"; Value: Text)
    begin
        Other.BaseText := Value;
    end;

    procedure XbGetOtherBaseText(var Other: Record "TBL ProtVar XA Table"): Text
    begin
        exit(Other.BaseText);
    end;

    // A local record variable: written through the member form, read back through a procedure of the declaring object.
    procedure XbLocalOtherRoundTrip(Value: Text): Text
    var
        Other: Record "TBL ProtVar XA Table";
    begin
        Other.ExtText := Value;
        Other.BaseText := Value + '/base';
        exit(Other.XaGetExtText() + '|' + Other.XaGetBaseText() + '|' + ExtText + '|' + BaseText);
    end;
}
