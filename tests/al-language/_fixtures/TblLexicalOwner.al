// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// local object: tests lexical ownership of extension expressions when a dependency exposes the same public signature.
tableextension 97890 "TBL Lexical Owner Ext" extends "TBL Lexical Owner Base"
{
    fields
    {
        modify(BaseLabel) { CaptionClass = GetCaptionClass(2); }
        field(97890; CollisionCaption; Text[30])
        {
            DataClassification = SystemMetadata;
            CaptionClass = GetCaptionClass(97890);
        }
        field(97891; UniqueCaption; Text[30])
        {
            DataClassification = SystemMetadata;
            CaptionClass = UniqueCaptionClass(97891);
        }
        field(97892; ZeroCaption; Text[30])
        {
            DataClassification = SystemMetadata;
            CaptionClass = GetZeroCaption;
        }
    }

    local procedure GetCaptionClass(FieldNumber: Integer): Text
    begin
        exit('3,Extension ' + Format(FieldNumber));
    end;

    local procedure UniqueCaptionClass(FieldNumber: Integer): Text
    begin
        exit('3,Unique ' + Format(FieldNumber));
    end;

    procedure ExtensionBare(): Text
    begin
        exit(GetCaptionClass(19));
    end;

    local procedure GetZeroCaption(): Text
    begin
        exit('3,Extension zero');
    end;

    procedure ExtensionZeroBare(): Text
    begin
        exit(GetZeroCaption);
    end;
}
