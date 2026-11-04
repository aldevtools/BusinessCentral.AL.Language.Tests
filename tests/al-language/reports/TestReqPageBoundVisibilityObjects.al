// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-visible-property
// Scope: in-scope
// Fixtures for codeunit 60008 "Req Page Bound Visibility".
//
// Report 60008 carries request-page controls whose Visible / Editable are bound to REPORT
// globals, the shape Base Application's batch-post reports use (Visible = VATDateEnabled).
// The globals are copied in the request page's OnOpenPage from codeunit 60009, a
// SingleInstance holder the test sets first, so no database write (and no Commit) is needed
// before Report.Run.
//
// Codeunit 60010 is a manually bound subscriber that steers two Base Application reports the
// same way without touching setup tables: it answers VAT Reporting Date Mgt.'s
// OnBeforeIsVATDateEnabledForUse, and it short-circuits report 296's request-page
// OnOpenPage so VATDateEnabled keeps its initial false whatever the company's setup is.

codeunit 60009 "RPVB Flags"
{
    SingleInstance = true;

    var
        ShowField: Boolean;
        EditField: Boolean;
        ShowGroup: Boolean;

    procedure Set(NewShowField: Boolean; NewEditField: Boolean; NewShowGroup: Boolean)
    begin
        ShowField := NewShowField;
        EditField := NewEditField;
        ShowGroup := NewShowGroup;
    end;

    procedure GetShowField(): Boolean
    begin
        exit(ShowField);
    end;

    procedure GetEditField(): Boolean
    begin
        exit(EditField);
    end;

    procedure GetShowGroup(): Boolean
    begin
        exit(ShowGroup);
    end;
}

report 60008 "RPVB Report"
{
    Caption = 'RPVB Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(BoundField; BoundValue)
                    {
                        ApplicationArea = All;
                        Caption = 'Bound Field';
                        ToolTip = 'Visible and Editable are bound to report globals.';
                        Visible = ShowFieldGlobal;
                        Editable = EditFieldGlobal;
                    }
                }
                group(Toggled)
                {
                    Visible = ShowGroupGlobal;
                    field(InGroupField; InGroupValue)
                    {
                        ApplicationArea = All;
                        Caption = 'In Group Field';
                        ToolTip = 'Declares no Visible of its own; its group is bound to a report global.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            Flags: Codeunit "RPVB Flags";
        begin
            ShowFieldGlobal := Flags.GetShowField();
            EditFieldGlobal := Flags.GetEditField();
            ShowGroupGlobal := Flags.GetShowGroup();
        end;
    }

    var
        BoundValue: Text[30];
        InGroupValue: Text[30];
        ShowFieldGlobal: Boolean;
        EditFieldGlobal: Boolean;
        ShowGroupGlobal: Boolean;
}

codeunit 60010 "RPVB Subscribers"
{
    EventSubscriberInstance = Manual;

    var
        VATDateEnabled: Boolean;

    procedure SetVATDateEnabled(NewValue: Boolean)
    begin
        VATDateEnabled := NewValue;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VAT Reporting Date Mgt", 'OnBeforeIsVATDateEnabledForUse', '', false, false)]
    local procedure AnswerVATDateEnabled(var IsEnabled: Boolean; var IsHandled: Boolean)
    begin
        IsEnabled := VATDateEnabled;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Batch Post Sales Orders", 'OnBeforeOnOpenPage', '', false, false)]
    local procedure SkipBatchPostOnOpenPage(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
