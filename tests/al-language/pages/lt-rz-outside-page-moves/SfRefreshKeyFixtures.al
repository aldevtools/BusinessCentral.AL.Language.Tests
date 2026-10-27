// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: own objects 89300 - 89302 (writer SF); log through LT RZ Log Mgt (88902, a table, no SingleInstance state)
// Probe: fixtures of the SF_Key_* and SF_Pk_* tests in RzUpdateFromValidate.al (al-runner issue 5888): a Worksheet whose header field
//   GroupFilter runs Rec.SetRange(Grp, GroupFilter) and CurrPage.Update(false) in its OnValidate. Page 89301 calls
//   Rec.SetCurrentKey(Grp, Name) in OnOpenPage (a key other than the primary key); page 89302 is the same page in the primary key.
// Rows (SfSeed): Id 1 (A, N4), 2 (B, N3), 3 (A, N2), 4 (B, N1); order in the key ByGroupName: 3, 1, 4, 2.
// Log: R:<Id> = OnAfterGetRecord, C:<Id> = OnAfterGetCurrRecord.
// BC versions: 27, 28, 29

table 89300 "LT SF Refresh Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Name; Code[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGroupName; Grp, Name) { }
    }
}

page 89301 "LT SF Refresh Key Ws"
{
    PageType = Worksheet;
    SourceTable = "LT SF Refresh Row";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(FilterBar)
            {
                field(GroupFilter; GroupFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        if GroupFilter = '' then
                            Rec.SetRange(Grp)
                        else
                            Rec.SetRange(Grp, GroupFilter);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Rows)
            {
                Editable = false;
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Grp, Name);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    var
        GroupFilter: Code[10];
}

page 89302 "LT SF Refresh Pk Ws"
{
    PageType = Worksheet;
    SourceTable = "LT SF Refresh Row";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(FilterBar)
            {
                field(GroupFilter; GroupFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        if GroupFilter = '' then
                            Rec.SetRange(Grp)
                        else
                            Rec.SetRange(Grp, GroupFilter);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Rows)
            {
                Editable = false;
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    var
        GroupFilter: Code[10];
}
