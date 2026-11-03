// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-exportobjects-method
// Scope: in-scope (OnPrem app only: System.ExportObjects)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61244
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: reads the Object table (a Microsoft platform table) with a filter that selects nothing
//
// ExportObjects with a blank file name and a nonexistent directory: error text start and code only. Nothing can be written: the file name is blank or in a directory that does not exist.
// BC versions: 29 (27 and 28 by CI)
codeunit 61244 "LT P109 ExportObjects"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Prefix(Text: Text): Text
    begin
        exit(CopyStr(Text, 1, 60));
    end;

    [TryFunction]
    local procedure TryExport(FileName: Text; UseFormat: Boolean; Format: Integer)
    var
        Obj: Record AllObj;
    begin
        Obj.SetRange("Object ID", -1);
        if UseFormat then
            ExportObjects(FileName, Obj, Format)
        else
            ExportObjects(FileName, Obj);
    end;

    local procedure Outcome(FileName: Text; UseFormat: Boolean; FormatValue: Integer): Text
    begin
        if TryExport(FileName, UseFormat, FormatValue) then
            exit('ok');
        exit('error:' + Prefix(GetLastErrorText()) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_ExportObjects_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('blank', Outcome('', false, 0));
        Observer.Observe('blank_format0', Outcome('', true, 0));
        Observer.Observe('blank_format1', Outcome('', true, 1));
        Observer.Observe('blank_format_negative', Outcome('', true, -1));
        Observer.Observe('blank_format_99', Outcome('', true, 99));
        Observer.Expect('blank', 'error:The ExportObjects method is not supported.|MethodNotSupported');
        Observer.Expect('blank_format0', 'error:The ExportObjects method is not supported.|MethodNotSupported');
        Observer.Expect('blank_format1', 'error:The ExportObjects method is not supported.|MethodNotSupported');
        Observer.Expect('blank_format_negative', 'error:The ExportObjects method is not supported.|MethodNotSupported');
        Observer.Expect('blank_format_99', 'error:The ExportObjects method is not supported.|MethodNotSupported');
        Observer.Verify();
    end;

    [Test]
    procedure P109_ExportObjects_NonexistentDirectory()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('nonexistent_dir', Outcome('/ltp109-no-such-dir/none.txt', false, 0));
        Observer.Observe('nonexistent_dir_format1', Outcome('/ltp109-no-such-dir/none.txt', true, 1));
        Observer.Expect('nonexistent_dir', 'error:The ExportObjects method is not supported.|MethodNotSupported');
        Observer.Expect('nonexistent_dir_format1', 'error:The ExportObjects method is not supported.|MethodNotSupported');
        Observer.Verify();
    end;
}
