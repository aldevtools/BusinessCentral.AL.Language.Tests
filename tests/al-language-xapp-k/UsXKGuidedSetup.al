// Cross-app fixture K (al-runner 9111): this app declares a 535 x 534 progressive JPEG (9857 bytes) as its logo (app.json "logo": "logo.jpg") and
// registers an assisted setup when the login raises OnRegisterAssistedSetup, so the Icon of the item comes from this app's logo.
// The probe is tests/al-language-onprem/session-system/UsAppLogoJpegSizes.al.
codeunit 98073 "LT US XK Guided Setup"
{
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure RegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.InsertAssistedSetup('LT US XK assisted', 'LT US XK a', 'Assisted setup of the JPEG logo size probe', 1, ObjectType::Codeunit, 98073, Enum::"Assisted Setup Group"::Uncategorized, '', Enum::"Video Category"::Uncategorized, '');
    end;
}
