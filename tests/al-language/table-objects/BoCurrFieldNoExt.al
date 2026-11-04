// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-currfieldno-method
// Scope: in-scope
// Fixture for corpus issue #664 item 111: CurrFieldNo read and assigned (CurrFieldNo := N) in a table extension of
// "LT P69 Curr Row" (71169). Must-not-compile case 1427 pins that CurrFieldNo is refused outside table code; here the
// question is whether the extension publishes and what the extension and the base table see.
// The test is CurrFieldNo_InTableExtension in misc/lt-inferred-behaviors/P69CurrFieldNo.al.

tableextension 82359 "LT BO Curr Row Ext" extends "LT P69 Curr Row"
{
    fields
    {
        field(10; LtBoExtNum; Integer)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                LtBoSeen := 'ext validate CurrFieldNo=' + Format(CurrFieldNo);
                CurrFieldNo := 1;
                LtBoSeen += ' after assign=' + Format(CurrFieldNo);
            end;
        }
    }

    var
        LtBoSeen: Text;

    procedure LtBoAssignInExt(FieldNumber: Integer): Integer
    begin
        CurrFieldNo := FieldNumber;
        exit(CurrFieldNo);
    end;

    procedure LtBoReadInExt(): Integer
    begin
        exit(CurrFieldNo);
    end;

    procedure LtBoSeenInValidate(): Text
    begin
        exit(LtBoSeen);
    end;
}
