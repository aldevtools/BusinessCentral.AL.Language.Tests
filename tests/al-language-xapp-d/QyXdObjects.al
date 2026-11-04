// Cross-app fixture D (writer QY; al-runtime-rs backlog "PROBES from multiapp-runtime", item 2): one subscriber of
// "LT QY XA Order Publisher".OnQyIndep (cross-app fixture A, tests/al-language-xapp-a/QyXaObjects.al). This app depends on A only: it and
// cross-app fixtures B and C and the main test app do not depend on each other, so only the publish order or a static rule can place it.
// Its subscriber id (61160) is higher than the subscribers of A, B and C on that event and lower than the main app's (87620).

codeunit 61160 "LT QY XD Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QY XA Order Publisher", 'OnQyIndep', '', false, false)]
    local procedure OnQyIndep(var Log: Text)
    begin
        Log += 'D;';
    end;
}

// Outside issue 6148 (writer US): this app declares a logo (app.json "logo": "logo.png", a 1 x 1 gray PNG of 67 bytes) and registers
// Guided Experience items as the calling app, so the Icon of the item comes from this app's logo. No app depends on this one, so the
// probe (tests/al-language-onprem/session/UsAppLogo.al) starts it by id: Codeunit.Run(61169).
codeunit 61169 "LT US XD Guided Setup"
{
    trigger OnRun()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.InsertAssistedSetup('LT US XD assisted', 'LT US XD a', 'Assisted setup of the logo probe', 1, ObjectType::Codeunit, 61169, Enum::"Assisted Setup Group"::Uncategorized, '', Enum::"Video Category"::Uncategorized, '');
        GuidedExperience.InsertManualSetup('LT US XD manual', 'LT US XD m', 'Manual setup of the logo probe', 1, ObjectType::Codeunit, 61169, Enum::"Manual Setup Category"::Uncategorized, 'lt us xd');
    end;
}
