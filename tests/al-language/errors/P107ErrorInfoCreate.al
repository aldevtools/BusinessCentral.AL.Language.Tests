// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-create-method
// Scope: in-scope
// Fixtures used: none, Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: ErrorInfo.Create(Message: Text, ...) with a Text variable, and with each optional argument
// BC versions: 29 (27 and 28 by CI)

codeunit 72701 "LT P107 ErrorInfo Create"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P107_CreateTextMessage()
    var
        Observer: Codeunit "Probe Observer";
        Info: ErrorInfo;
        Msg: Text;
    begin
        Msg := 'hello';
        Info := ErrorInfo.Create(Msg);
        Observer.Observe('message', Info.Message);
        Observer.Observe('collectible', Format(Info.Collectible));
        Observer.Observe('verbosity', Format(Info.Verbosity));
        Observer.Observe('fieldno', Format(Info.FieldNo));
        Observer.Observe('pageno', Format(Info.PageNo));
        Observer.Observe('controlname', '[' + Info.ControlName + ']');
        Observer.Observe('dataclass', Format(Info.DataClassification));
        Observer.Observe('dims', Format(Info.CustomDimensions.Count()));
        Msg := '';
        Info := ErrorInfo.Create(Msg);
        Observer.Observe('empty_message', '[' + Info.Message + ']');
        Msg := 'ünï ✓ ' + PadStr('', 300, 'x');
        Info := ErrorInfo.Create(Msg);
        Observer.Observe('long_len', Format(StrLen(Info.Message)));
        Observer.Expect('message', 'hello');
        Observer.Expect('collectible', 'No');
        Observer.Expect('verbosity', 'Error');
        Observer.Expect('fieldno', '0');
        Observer.Expect('pageno', '0');
        Observer.Expect('controlname', '[]');
        Observer.Expect('dataclass', 'CustomerContent');
        Observer.Expect('dims', '0');
        Observer.Expect('empty_message', '[]');
        Observer.Expect('long_len', '306');
        Observer.Verify();
    end;

    [Test]
    procedure P107_CreateTextAllArgs()
    var
        Observer: Codeunit "Probe Observer";
        Info: ErrorInfo;
        Rec: Record "LT P107 Rec" temporary;
        Dims: Dictionary of [Text, Text];
        Msg: Text;
        Ctl: Text;
    begin
        Msg := 'full';
        Ctl := 'MyControl';
        Dims.Add('k1', 'v1');
        Dims.Add('k2', 'v2');
        Rec.Code := 'R1';
        Rec.Insert();
        Info := ErrorInfo.Create(Msg, true, Rec, 3, 21, Ctl, Verbosity::Warning, DataClassification::SystemMetadata, Dims);
        Observer.Observe('message', Info.Message);
        Observer.Observe('collectible', Format(Info.Collectible));
        Observer.Observe('verbosity', Format(Info.Verbosity));
        Observer.Observe('fieldno', Format(Info.FieldNo));
        Observer.Observe('pageno', Format(Info.PageNo));
        Observer.Observe('controlname', Info.ControlName);
        Observer.Observe('dataclass', Format(Info.DataClassification));
        Observer.Observe('dims', Format(Info.CustomDimensions.Count()));
        Observer.Observe('dim_k2', Info.CustomDimensions.Get('k2'));
        Observer.Observe('recordid_set', Format(Format(Info.RecordId) <> ''));
        Observer.Expect('message', 'full');
        Observer.Expect('collectible', 'Yes');
        Observer.Expect('verbosity', 'Warning');
        Observer.Expect('fieldno', '3');
        Observer.Expect('pageno', '21');
        Observer.Expect('controlname', 'MyControl');
        Observer.Expect('dataclass', 'SystemMetadata');
        Observer.Expect('dims', '2');
        Observer.Expect('dim_k2', 'v2');
        Observer.Expect('recordid_set', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P107_CreateTextPartial()
    var
        Observer: Codeunit "Probe Observer";
        Info: ErrorInfo;
        Msg: Text;
    begin
        Msg := 'part';
        Info := ErrorInfo.Create(Msg, true);
        Observer.Observe('collectible', Format(Info.Collectible));
        Info := ErrorInfo.Create(Msg, false);
        Observer.Observe('not_collectible', Format(Info.Collectible));
        Observer.Expect('collectible', 'Yes');
        Observer.Expect('not_collectible', 'No');
        Observer.Verify();
    end;
}
