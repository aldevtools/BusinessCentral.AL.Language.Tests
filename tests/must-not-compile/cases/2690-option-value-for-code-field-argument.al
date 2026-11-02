// @expect AL0193 | Argument 2: cannot convert from 'ClientType' to the type of Argument 1 'Code[20]'
// @expect AL0193 | Argument 2: cannot convert from 'Enum "MNC Y71 Mode"' to the type of Argument 1 'Code[20]'
// @expect AL0193 | Argument 2: cannot convert from 'Integer' to the type of Argument 1 'Code[20]'
// @expect AL0193 | Argument 3: cannot convert from 'ClientType' to the type of Argument 1 'Code[20]'
// @expect AL0193 | Argument 3: cannot convert from 'Enum "MNC Y71 Mode"' to the type of Argument 1 'Code[20]'
// @expect AL0193 | Argument 3: cannot convert from 'Integer' to the type of Argument 1 'Code[20]'
// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Code[20]'. Use an explicit conversion or change the type.
// @expect AL0193 | Argument 2: cannot convert from 'Enum "MNC Y71 Mode"' to the type of Argument 1 'Code[20]'
// @expect AL0193 | Argument 2: cannot convert from 'Integer' to the type of Argument 1 'Code[20]'
// An Option value (ClientType::Web, an own Option variable) and an Enum value are not accepted as the value argument of SetRange or SetFilter for a Code field, nor
// assigned or validated into it. Record.Get accepts all of them as a key value (it takes any value and converts at run time): tests/al-language/types/lt-y71-value-conversions/Y71ValueConversions.al.
table 52690 "MNC Y71 Key"
{
    fields
    {
        field(1; U; Code[50]) { }
        field(2; Target; Code[20]) { }
    }

    keys
    {
        key(PK; U, Target) { Clustered = true; }
    }
}

enum 52690 "MNC Y71 Mode"
{
    value(0; Web) { }
    value(1; Two) { }
}

codeunit 52690 "MNC Y71 Option Args"
{
    procedure Probe()
    var
        K: Record "MNC Y71 Key";
        Mode: Enum "MNC Y71 Mode";
        OptionValue: Option Web,Two,Three;
    begin
        K.SetRange(Target, ClientType::Web);
        K.SetRange(Target, Mode::Two);
        K.SetRange(Target, OptionValue::Two);
        K.SetFilter(Target, '%1', ClientType::Web);
        K.SetFilter(Target, '%1', Mode::Two);
        K.SetFilter(Target, '%1', OptionValue::Two);
        K.Target := OptionValue::Two;
        K.Validate(Target, Mode::Two);
        K.Validate(Target, OptionValue::Three);
    end;
}
