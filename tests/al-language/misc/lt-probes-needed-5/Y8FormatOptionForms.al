// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: Format of an Option field with a length and a format number, and of fields whose OptionCaption list is shorter or longer than the members
// (al-runtime-rs docs/probes-needed.md row "Format": `Format(Rec.Field, Length, FormatNumber)` and "a caption list as long as neither the members
// nor a literal"). Shapes already pinned elsewhere: length 5 with formats 0-9 (types/lt-ax-text-format-dates/AxFormatOption.al), the member forms
// (record/lt-x-table-props/XTablePropsTests.al:795), FieldRef.Value (misc/lt-probes-needed-5/PnE10Formats.al).
// Probe: written against the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix. Writer Y8 (2026-10-30).

table 91404 "LT Y8 Format Option Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option)
        {
            OptionMembers = "A-B",C,LongMemberName;
            OptionCaption = 'First,Second,Third Caption';
        }
        field(4; OptShort; Option)
        {
            OptionMembers = M0,M1,M2;
            OptionCaption = 'Zero,One';
        }
        field(5; OptLong; Option)
        {
            OptionMembers = M0,M1;
            OptionCaption = 'Zero,One,Two,Three';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 91404 "LT Y8 Format Option Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Forms(R: Record "LT Y8 Format Option Rec"): Text
    begin
        exit(StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8',
            Format(R.Opt, 0, 0), Format(R.Opt, 0, 1), Format(R.Opt, 0, 2), Format(R.Opt, 0, 9),
            Format(R.Opt, 3), Format(R.Opt, 3, 2), Format(R.Opt, 3, 9), Format(R.Opt, 20, 0)));
    end;

    [Test]
    procedure Y8_Field_LengthAndFormatNumber()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y8 Format Option Rec";
    begin
        R.Opt := R.Opt::"A-B";
        Observer.Observe('first', Forms(R));
        R.Opt := R.Opt::C;
        Observer.Observe('second', Forms(R));
        R.Opt := R.Opt::LongMemberName;
        Observer.Observe('third', Forms(R));
        R.Opt := 7;
        Observer.Observe('beyond', Forms(R));
        Observer.Expect('first', 'First|First|0|0|Fir|0  |0  |First               ');
        Observer.Expect('second', 'Second|Second|1|1|Sec|1  |1  |Second              ');
        Observer.Expect('third', 'Third Caption|Third Caption|2|2|Thi|2  |2  |Third Caption       ');
        Observer.Expect('beyond', '7|7|7|7|7  |7  |7  |7                   ');
        Observer.Verify();
    end;

    [Test]
    procedure Y8_CaptionList_ShorterAndLonger()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y8 Format Option Rec";
    begin
        R.OptShort := R.OptShort::M1;
        Observer.Observe('short_m1', StrSubstNo('%1|%2|%3', Format(R.OptShort), Format(R.OptShort, 0, 2), Format(R.OptShort, 0, 9)));
        R.OptShort := R.OptShort::M2;
        Observer.Observe('short_m2', StrSubstNo('%1|%2|%3', Format(R.OptShort), Format(R.OptShort, 0, 2), Format(R.OptShort, 0, 9)));
        Observer.Observe('short_member_m2', Format(R.OptShort::M2));
        R.OptLong := R.OptLong::M1;
        Observer.Observe('long_m1', StrSubstNo('%1|%2|%3', Format(R.OptLong), Format(R.OptLong, 0, 2), Format(R.OptLong, 0, 9)));
        R.OptLong := 3;
        Observer.Observe('long_3', StrSubstNo('%1|%2|%3', Format(R.OptLong), Format(R.OptLong, 0, 2), Format(R.OptLong, 0, 9)));
        Observer.Expect('short_m1', 'One|1|1');
        Observer.Expect('short_m2', 'M2|2|2');
        Observer.Expect('short_member_m2', 'M2');
        Observer.Expect('long_m1', 'One|1|1');
        Observer.Expect('long_3', '3|3|3');
        Observer.Verify();
    end;
}
