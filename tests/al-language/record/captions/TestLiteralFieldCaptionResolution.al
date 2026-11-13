// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fieldcaption-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

using System.Reflection;

codeunit 51883 "REC LiteralFieldCapti Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LiteralFieldCaptionReadsUseOneResolution()
    var
        Row: Record "Probe Literal Caption Row";
        Pg: TestPage "Probe Literal Caption Page";
        Subscriber: Codeunit "Probe Caption Subscriber";
        AtOpen: Integer;
        FirstCaption: Text;
        SecondCaption: Text;
        ThirdCaption: Text;
    begin
        Initialize();
        Row.Id := 1;
        Row.Insert();
        BindSubscription(Subscriber);
        Pg.OpenEdit();
        AtOpen := Subscriber.Count();
        FirstCaption := Pg.Payload.Caption();
        SecondCaption := Pg.Payload.Caption();
        Pg.EditValue.SetValue('X');
        ThirdCaption := Pg.Payload.Caption();
        if (FirstCaption <> 'Literal1') or (SecondCaption <> FirstCaption) or (ThirdCaption <> FirstCaption) or (Subscriber.Count() <> 1) then
            Error('Caption observation: %1|%2|%3|%4|%5', AtOpen, FirstCaption, SecondCaption, ThirdCaption, Subscriber.Count());
        Pg.Close();
        UnbindSubscription(Subscriber);
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Probe Literal Caption Row";
    begin
        ProbeTable1.DeleteAll();
    end;
}
