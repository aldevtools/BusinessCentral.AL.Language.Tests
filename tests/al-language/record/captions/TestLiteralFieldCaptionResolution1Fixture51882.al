// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fieldcaption-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

using System.Reflection;

// local object: this object defines the page, record, or trigger behavior that the test exercises.
codeunit 51882 "Probe Caption Subscriber"
{
    EventSubscriberInstance = Manual;
    var
        Calls: Integer;

    procedure Count(): Integer
    begin
        exit(Calls);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', false, false)]
    local procedure Resolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionArea <> 'PRB503' then
            exit;
        Calls += 1;
        Caption := CaptionExpr + Format(Calls);
        Resolved := true;
    end;
}
