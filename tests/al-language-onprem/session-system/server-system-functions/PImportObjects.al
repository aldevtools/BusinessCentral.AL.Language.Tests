// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-importobjects-method
// Scope: in-scope (OnPrem app only: System.ImportObjects)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61245
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: none
//
// ImportObjects with a blank and a nonexistent file name only: error text start and code.
// BC versions: 29 (27 and 28 by CI)
codeunit 61245 "LT P109 ImportObjects"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryImport(FileName: Text; UseFormat: Boolean; FormatValue: Integer)
    begin
        if UseFormat then
            ImportObjects(FileName, FormatValue)
        else
            ImportObjects(FileName);
    end;

    local procedure Outcome(FileName: Text; UseFormat: Boolean; FormatValue: Integer): Text
    begin
        if TryImport(FileName, UseFormat, FormatValue) then
            exit('ok');
        exit('error:' + CopyStr(GetLastErrorText(), 1, 60) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_ImportObjects_Blank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('blank', Outcome('', false, 0));
        Observer.Observe('blank_format0', Outcome('', true, 0));
        Observer.Observe('blank_format1', Outcome('', true, 1));
        Observer.Expect('blank', 'error:The ImportObjects method is not supported.|MethodNotSupported');
        Observer.Expect('blank_format0', 'error:The ImportObjects method is not supported.|MethodNotSupported');
        Observer.Expect('blank_format1', 'error:The ImportObjects method is not supported.|MethodNotSupported');
        Observer.Verify();
    end;

    [Test]
    procedure P109_ImportObjects_Nonexistent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('nonexistent', Outcome('/ltp109-no-such-dir/none.txt', false, 0));
        Observer.Observe('nonexistent_format0', Outcome('/ltp109-no-such-dir/none.txt', true, 0));
        Observer.Observe('nonexistent_format1', Outcome('/ltp109-no-such-dir/none.txt', true, 1));
        Observer.Expect('nonexistent', 'error:The ImportObjects method is not supported.|MethodNotSupported');
        Observer.Expect('nonexistent_format0', 'error:The ImportObjects method is not supported.|MethodNotSupported');
        Observer.Expect('nonexistent_format1', 'error:The ImportObjects method is not supported.|MethodNotSupported');
        Observer.Verify();
    end;
}
