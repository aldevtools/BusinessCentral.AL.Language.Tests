// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702)
//
// A pageextension on Base Application's "Item Attribute" card — a page this test app never
// compiles itself, reached only as a declared dependency. Its action captures what the
// trigger's Rec observes into the shared fixture table, so the test codeunit can assert the
// cursor the page was standing on when the action ran. Sibling of "TP Modal Handler
// Precompiled" (60902), which pins handler dispatch against precompiled pages; this pins
// GoToRecord positioning and the pageextension trigger's view of Rec.

pageextension 60735 "TP Precompiled Capture Ext" extends "Item Attribute"
{
    actions
    {
        addlast(processing)
        {
            action(CaptureRow)
            {
                ApplicationArea = All;
                Caption = 'Capture Row';

                trigger OnAction()
                var
                    Capture: Record "Test Page Modal Handler Row";
                begin
                    Capture.Init();
                    Capture."No." := 'CAPTURED-NAME';
                    Capture.Descr := CopyStr(Rec.Name, 1, MaxStrLen(Capture.Descr));
                    if not Capture.Insert() then
                        Capture.Modify();

                    Capture.Init();
                    Capture."No." := 'CAPTURED-SYSTEMID';
                    Capture.Descr := CopyStr(Format(Rec.SystemId), 1, MaxStrLen(Capture.Descr));
                    if not Capture.Insert() then
                        Capture.Modify();
                end;
            }
        }
    }
}
