// Fixture of writer QY's subscriber order probes (tests in BwSubscriberOrderTests.al): this app's subscriber of the two events of
// "LT QY XA Order Publisher" (cross-app fixture A, tests/al-language-xapp-a/QyXaObjects.al).

codeunit 87620 "LT QY M Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyOrder', '', false, false)]
    local procedure OnQyOrder(var Log: Text)
    begin
        Log += 'M;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyIndep', '', false, false)]
    local procedure OnQyIndep(var Log: Text)
    begin
        Log += 'M;';
    end;
}
