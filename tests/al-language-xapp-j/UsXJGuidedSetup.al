// Cross-app fixture J (al-runner 9111): this app declares a 400 x 300 baseline JPEG (62851 bytes) as its logo (app.json "logo": "logo.jpg") and
// registers an assisted setup when the login raises OnRegisterAssistedSetup, so the Icon of the item comes from this app's logo.
// The probe is tests/al-language-onprem/session-system/UsAppLogoJpegSizes.al.
codeunit 98082 "LT US XJ Guided Setup"
{
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure RegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.InsertAssistedSetup('LT US XJ assisted', 'LT US XJ a', 'Assisted setup of the JPEG logo size probe', 1, ObjectType::Codeunit, 98082, Enum::"Assisted Setup Group"::Uncategorized, '', Enum::"Video Category"::Uncategorized, '');
    end;
}
