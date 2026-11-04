// Subscriber order probe inside one app (al-runtime-rs ADR-046 amendment 1, probe Q1; corpus #664 item 152), writer BW. One of five
// subscriber codeunits P..T; ids, names, namespace, folder and position in the file are chosen so every candidate rule predicts another order.
// See BwSubscriberOrderTests.al for the table of predictions.
// This file: T (83964, "LT BW Y Subs"), folder c-order.

codeunit 83964 "LT BW Y Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BW XA Order Publisher", 'OnBwOrder', '', false, false)]
    local procedure OnBwOrder(var Log: Text)
    begin
        Log += 'T;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BW Order Publisher", 'OnBwLocalOrder', '', false, false)]
    local procedure OnBwLocalOrder(var Log: Text)
    begin
        Log += 'T;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    var
        Writer: Codeunit "LT BW Install Writer";
    begin
        Writer.WriteRow('T', 'company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    var
        Writer: Codeunit "LT BW Install Writer";
    begin
        Writer.WriteRow('T', 'database');
    end;
}
