// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-assertequals-method
// Scope: in-scope
// Fixtures used: TPF Row (69932), TPF Enum (69932)
//
// One control per field type a TestPage control can show, plus page-variable-bound copies of a few.

page 69932 "TPF Card"
{
    PageType = Card;
    SourceTable = "TPF Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TPF Card';

    layout
    {
        area(Content)
        {
            field(PK; Rec.PK) { ApplicationArea = All; }
            field(Num; Rec.Num) { ApplicationArea = All;  }
            field(Big; Rec.Big) { ApplicationArea = All;  }
            field(Dec2; Rec.Dec2) { ApplicationArea = All; DecimalPlaces = 2 : 2; }
            field(Dec1; Rec.Dec1) { ApplicationArea = All; DecimalPlaces = 1 : 1; }
            field(Dec5; Rec.Dec5) { ApplicationArea = All; DecimalPlaces = 5 : 5; }
            field(DecDef; Rec.DecDef) { ApplicationArea = All;  }
            field(DecRng; Rec.DecRng) { ApplicationArea = All; DecimalPlaces = 0 : 5; }
            field(DecBZ; Rec.DecBZ) { ApplicationArea = All; BlankZero = true; }
            field(DecBZT; Rec.DecBZT) { ApplicationArea = All;  }
            field(DecBNP; Rec.DecBNP) { ApplicationArea = All; BlankNumbers = BlankZeroAndPos; }
            field(DecBNN; Rec.DecBNN) { ApplicationArea = All; BlankNumbers = BlankNeg; }
            field(DecAF; Rec.DecAF) { ApplicationArea = All; AutoFormatType = 11; AutoFormatExpression = '<Precision,4:4><Standard Format,0>'; }
            field(NumBZ; Rec.NumBZ) { ApplicationArea = All; BlankZero = true; }
            field(Flag; Rec.Flag) { ApplicationArea = All;  }
            field(Opt; Rec.Opt) { ApplicationArea = All;  }
            field(Enm; Rec.Enm) { ApplicationArea = All;  }
            field(Dt; Rec.Dt) { ApplicationArea = All;  }
            field(Tm; Rec.Tm) { ApplicationArea = All;  }
            field(DtTm; Rec.DtTm) { ApplicationArea = All;  }
            field(Cd; Rec.Cd) { ApplicationArea = All;  }
            field(Txt; Rec.Txt) { ApplicationArea = All;  }
            field(Gd; Rec.Gd) { ApplicationArea = All;  }
            field(Dur; Rec.Dur) { ApplicationArea = All;  }
            field(GlobDec; GlobDec) { ApplicationArea = All; DecimalPlaces = 2 : 2; }
            field(GlobNum; GlobNum) { ApplicationArea = All;  }
            field(GlobDt; GlobDt) { ApplicationArea = All;  }
            field(GlobDur; GlobDur) { ApplicationArea = All;  }
            field(GlobFlag; GlobFlag) { ApplicationArea = All;  }
        }
    }

    var
        GlobDec: Decimal;
        GlobNum: Integer;
        GlobDt: Date;
        GlobDur: Duration;
        GlobFlag: Boolean;

    trigger OnAfterGetRecord()
    begin
        GlobDec := Rec.Dec2;
        GlobNum := Rec.Num;
        GlobDt := Rec.Dt;
        GlobDur := Rec.Dur;
        GlobFlag := Rec.Flag;
    end;
}
