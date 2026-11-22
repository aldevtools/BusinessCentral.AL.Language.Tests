// Cross-app fixture E (outside issue al-runner 8061): this app declares a JPEG logo (app.json "logo": "logo.jpg", 8 x 8 baseline
// JPEG, 307 bytes) and registers an assisted setup when the login raises OnRegisterAssistedSetup, so the Icon of the item comes from
// this app's logo. The probe is tests/al-language-onprem/session-system/UsAppLogoJpeg.al.
codeunit 98030 "LT US XE Guided Setup"
{
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure RegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.InsertAssistedSetup('LT US XE assisted', 'LT US XE a', 'Assisted setup of the JPEG logo probe', 1, ObjectType::Codeunit, 98030, Enum::"Assisted Setup Group"::Uncategorized, '', Enum::"Video Category"::Uncategorized, '');
    end;
}
