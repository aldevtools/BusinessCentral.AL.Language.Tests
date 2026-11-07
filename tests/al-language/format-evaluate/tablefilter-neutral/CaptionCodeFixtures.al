// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: Cloud-compatible; BC 27.5+.
// local object: field names, CaptionClass resolution, and the Code[10] filter target are under test.
table 69071 "FMT Caption Filter Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Nominal Price"; Decimal)
        {
            Caption = 'Static Price';
            CaptionClass = 'NFMTFILTER,PRICE';
        }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

// local object: a private caption area is resolved only while the test binds this subscriber.
codeunit 69072 "FMT Filter Caption Resolver"
{
    EventSubscriberInstance = Manual;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', false, false)]
    local procedure Resolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if (CaptionArea = 'NFMTFILTER') and (CaptionExpr = 'PRICE') then begin
            Caption := 'Displayed Price';
            Resolved := true;
        end;
    end;
}

// local object: the Code[10] field and compound TableFilter field names are under test.
table 69073 "FMT Blank Service Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Service Type"; Code[10]) { }
        field(3; Batch; Code[10]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
