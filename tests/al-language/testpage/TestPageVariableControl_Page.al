// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Test Page Variable Control Row (60714), Test Page Variable Control (60715)
//
// A list page whose first controls bind to page GLOBAL VARIABLES rather than to a
// source-table field — the standard AL shape for a mode/filter selector above a repeater.
//
// The OnValidate triggers write into the table so the test can observe, from outside the
// page, that setting the control actually ran the page's AL — not merely that a value was
// stashed somewhere and handed back.

page 60715 "Test Page Variable Control"
{
    PageType = List;
    SourceTable = "Test Page Variable Control Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            field(Mode; SelectedMode)
            {
                ApplicationArea = All;
                Caption = 'Mode';

                trigger OnValidate()
                var
                    Echo: Record "Test Page Variable Control Row";
                begin
                    if Echo.Get('ECHO') then begin
                        Echo.Descr := SelectedMode;
                        Echo.Modify();
                    end else begin
                        Echo.Init();
                        Echo."No." := 'ECHO';
                        Echo.Descr := SelectedMode;
                        Echo.Insert();
                    end;
                end;
            }
            // An Option control bound to a page variable, whose CAPTIONS differ from its
            // member names. A TestPage sets an option by what the user sees (the caption,
            // 'Blocks'), not by the member name ('Block'), so resolving it needs the
            // control's OptionCaption list and not just the option's own metadata.
            field(KindSelector; SelectedKind)
            {
                ApplicationArea = All;
                Caption = 'Kind';
                OptionCaption = 'Fields,Blocks,Images,Fonts,Custom Fields,Labels';

                trigger OnValidate()
                var
                    Echo: Record "Test Page Variable Control Row";
                begin
                    if not Echo.Get('KIND') then begin
                        Echo.Init();
                        Echo."No." := 'KIND';
                        Echo.Descr := Format(SelectedKind);
                        Echo.Insert();
                    end else begin
                        Echo.Descr := Format(SelectedKind);
                        Echo.Modify();
                    end;
                end;
            }
            // A Code-typed page global. Distinct from Mode (Text) above: Code and Text are
            // both string-backed AL types, but a TestPage's generated SetValue/Value dispatch
            // sees them as different NavValue subtypes under the hood, so Code needs its own
            // coverage rather than being assumed to behave like Text.
            field(CodeField; SelectedCode)
            {
                ApplicationArea = All;
                Caption = 'Code';

                trigger OnValidate()
                var
                    Echo: Record "Test Page Variable Control Row";
                begin
                    if not Echo.Get('CODE') then begin
                        Echo.Init();
                        Echo."No." := 'CODE';
                        Echo.Descr := SelectedCode;
                        Echo.Insert();
                    end else begin
                        Echo.Descr := SelectedCode;
                        Echo.Modify();
                    end;
                end;
            }
            // A Date-typed page global — the other primitive TestPage control type besides
            // Text/Code/Option that a page-global (as opposed to Rec-bound) control can bind
            // to.
            field(DateField; SelectedDate)
            {
                ApplicationArea = All;
                Caption = 'Date';

                trigger OnValidate()
                var
                    Echo: Record "Test Page Variable Control Row";
                begin
                    if not Echo.Get('DATE') then begin
                        Echo.Init();
                        Echo."No." := 'DATE';
                        Echo.Descr := Format(SelectedDate);
                        Echo.Insert();
                    end else begin
                        Echo.Descr := Format(SelectedDate);
                        Echo.Modify();
                    end;
                end;
            }
            // A page-global control that REFUSES a value. Every control above writes into the
            // table so a test can see the trigger ran; this one exists so a test can see what
            // happens when the trigger REFUSES, which is a different question and the only one
            // this page could not previously ask. Nothing else writes to it, so the arms above
            // are unaffected.
            field(GuardField; SelectedGuard)
            {
                ApplicationArea = All;
                Caption = 'Guard';

                trigger OnValidate()
                begin
                    if SelectedGuard = RefuseTok then
                        Error(GuardRefusedErr);
                end;
            }
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        SelectedMode: Text[30];
        SelectedKind: Option Field,Block,Image,Font,Custom,Label;
        SelectedCode: Code[20];
        SelectedDate: Date;
        SelectedGuard: Text[30];
        RefuseTok: Label 'REFUSE', Locked = true;
        GuardRefusedErr: Label 'Guard control refused the value', Locked = true;
}
