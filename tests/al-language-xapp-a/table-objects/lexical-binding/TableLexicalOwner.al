// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// local object: the cross-app base declaration and its colliding public procedure are the subject of this probe.
table 61179 "TBL Lexical Owner Base"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; BaseLabel; Text[30]) { Caption = 'Base label'; }
    }
    keys { key(PK; Id) { Clustered = true; } }

    procedure GetCaptionClass(FieldNumber: Integer): Text
    begin
        exit('3,Base ' + Format(FieldNumber));
    end;

    procedure BaseCall(): Text
    begin
        exit(GetCaptionClass(17));
    end;

    procedure GetZeroCaption(): Text
    begin
        exit('3,Base zero');
    end;

    procedure BaseZeroCall(): Text
    begin
        exit(GetZeroCaption);
    end;
}
