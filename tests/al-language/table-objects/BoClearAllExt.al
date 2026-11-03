// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures for corpus issue #664 item 113: ClearAll() in a table extension (procedure and field trigger) of "Probe Rb Row" (69527)
// and in a page extension (procedure and OnOpenPage) of "Probe Ui Card" (68124); codeunit 82362 keeps the OnOpenPage trace. Both compile; the tests in record/ProbeClearAllSetKeyHyperlink.al
// (codeunit 69532) observe what ClearAll clears there.

tableextension 82360 "LT BO Rb Row Ext" extends "Probe Rb Row"
{
    fields
    {
        field(10; LtBoNum; Integer)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                LtBoExtGlobal := 7;
                ClearAll();
                LtBoTrace := 'ext=' + Format(LtBoExtGlobal) + ',Id=' + Format(Id) + ',Name=' + Name + ',num=' + Format(LtBoNum);
            end;
        }
    }

    var
        LtBoExtGlobal: Integer;
        LtBoTrace: Text;

    procedure LtBoSetExtGlobal(Value: Integer)
    begin
        LtBoExtGlobal := Value;
    end;

    procedure LtBoGetExtGlobal(): Integer
    begin
        exit(LtBoExtGlobal);
    end;

    procedure LtBoClearAllInExt(): Text
    begin
        ClearAll();
        exit('ext=' + Format(LtBoExtGlobal) + ',Id=' + Format(Id) + ',Name=' + Name + ',num=' + Format(LtBoNum));
    end;

    procedure LtBoTraceOfValidate(): Text
    begin
        exit(LtBoTrace);
    end;
}

pageextension 82361 "LT BO Ui Card Ext" extends "Probe Ui Card"
{
    var
        LtBoPageGlobal: Integer;
        LtBoPageText: Text;

    trigger OnOpenPage()
    var
        Trace: Codeunit "LT BO ClearAll Trace";
    begin
        Trace.Add('open before=' + LtBoDescribe());
        LtBoPageGlobal := 3;
        LtBoPageText := 'opened';
        ClearAll();
        Trace.Add('open after=' + LtBoDescribe());
    end;

    procedure LtBoSetPageGlobals(Value: Integer; Txt: Text)
    begin
        LtBoPageGlobal := Value;
        LtBoPageText := Txt;
    end;

    procedure LtBoDescribe(): Text
    begin
        exit('int=' + Format(LtBoPageGlobal) + ',text=' + LtBoPageText);
    end;

    procedure LtBoClearAllInPageExt(): Text
    begin
        ClearAll();
        exit(LtBoDescribe());
    end;
}

codeunit 82362 "LT BO ClearAll Trace"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}
