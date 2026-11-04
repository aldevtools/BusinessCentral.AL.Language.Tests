// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope
// Fixtures used: none (objects for BbProbes.al)
// Probe: corpus issue 653 items 2 and 9, issue 639 items 10, 11, 12 and 18: a report extension procedure with the name of a base report
//   procedure and other parameter types; two enums where the target has AssignmentCompatibility = true; a list page whose system part sets
//   EntityName and EntitySetName, whose field sets FileUploadAction and which sets HelpLink to a URL (all compile; the refused forms are
//   must-not-compile cases 1249, 1252 to 1264 and 0848).
// BC versions: 27, 28, 29
table 80850 "LT BB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

report 80851 "LT BB Base Report"
{
    ProcessingOnly = true;

    dataset { dataitem(Row; "LT BB Row") { } }

    procedure Bump(A: Integer): Text
    begin
        exit('base integer ' + Format(A));
    end;
}

reportextension 80852 "LT BB Base Report Ext" extends "LT BB Base Report"
{
    procedure Bump(A: Text): Text
    begin
        exit('extension text ' + A);
    end;
}

enum 80853 "LT BB Enum A"
{
    value(0; Zero) { }
    value(1; One) { }
    value(5; Five) { }
}

enum 80854 "LT BB Enum B"
{
    AssignmentCompatibility = true;

    value(0; Zero) { }
    value(1; One) { }
}

page 80855 "LT BB Controls"
{
    PageType = List;
    SourceTable = "LT BB Row";
    ApplicationArea = All;
    UsageCategory = None;
    HelpLink = 'https://example.com/help/lt-bb-controls';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; FileUploadAction = UploadFiles; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            systempart(NotesPart; Notes)
            {
                ApplicationArea = All;
                EntityName = 'bbNote';
                EntitySetName = 'bbNotes';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            fileuploadaction(UploadFiles)
            {
                ApplicationArea = All;
                AllowMultipleFiles = true;

                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
        }
    }
}
