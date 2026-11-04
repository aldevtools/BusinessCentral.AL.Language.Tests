// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optioncaption-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 95425, enum 95426, table 95431, page 95432, test codeunit 95439 (writer r6945)
// local object: the test reads controls bound to fields of the page's own global record variable; their OptionCaption and enum captions are under test
// Probe: al-runner issue 7005 (the reporter's Windows BC 28.5 OnPrem run: the control shows the member name `Short`, and an empty value while
//   the list has no rows); written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: a List page whose header group (and repeater) shows fields of a GLOBAL record variable of the page that is never stored (OnOpenPage
//   only assigns them): an Option field with OptionCaption, an Option field without one, and an Enum field whose value captions differ from
//   the value names; next to them the same kinds of field of Rec in the repeater. The Value text of each control with one row, with two rows
//   after Next, and with no row in the list.
//   Neighbours: pages/controls/SaOtherRecordControl.al (the same controls on a Worksheet whose record variable is read from the table).
// Result (CI legs 27.5, 28.5 and 29.0, Linux): the Option control of the other record shows the member name (`Short`) on 27.5 and 28.5
//   (BC29PLUS guards) and the OptionCaption (`Short Lines`) on 29.0; the reporter's Windows BC 28.5 OnPrem run shows `Short` too, so
//   28.5 is confirmed on Windows; 27.5 is measured on Linux only. The Enum control shows the value caption and the Option field without
//   OptionCaption the member name on every version. With no row in the list every control reads blank: the controls of the other
//   record in the group and in the repeater (whatever the record holds) and those of Rec.
// BC versions: 27, 28, 29

table 95425 "PAG OtherRecOpt Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Avail. Filter"; Option)
        {
            OptionMembers = All,Short,Covered;
            OptionCaption = 'Every Line,Short Lines,Covered Lines';
        }
        field(3; Plain; Option)
        {
            OptionMembers = A,B,C;
        }
        field(4; Kind; Enum "PAG OtherRecOpt Kind") { }
    }
    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}

enum 95426 "PAG OtherRecOpt Kind"
{
    Extensible = false;

    value(0; First) { Caption = 'First Kind'; }
    value(1; Second) { Caption = 'Second Kind'; }
}

table 95431 "PAG OtherRecOpt Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option)
        {
            OptionMembers = All,Short,Covered;
            OptionCaption = 'Every Line,Short Lines,Covered Lines';
        }
        field(3; Kind; Enum "PAG OtherRecOpt Kind") { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 95432 "PAG OtherRecOpt List"
{
    PageType = List;
    SourceTable = "PAG OtherRecOpt Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(VarOpt; FilterSetup."Avail. Filter") { ApplicationArea = All; }
                field(VarPlain; FilterSetup.Plain) { ApplicationArea = All; }
                field(VarKind; FilterSetup.Kind) { ApplicationArea = All; }
            }
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(RecOpt; Rec.Opt) { ApplicationArea = All; }
                field(RecKind; Rec.Kind) { ApplicationArea = All; }
                field(RowVarOpt; FilterSetup."Avail. Filter") { ApplicationArea = All; }
                field(RowVarKind; FilterSetup.Kind) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        FilterSetup."Avail. Filter" := FilterSetup."Avail. Filter"::Short;
        FilterSetup.Plain := FilterSetup.Plain::B;
        FilterSetup.Kind := FilterSetup.Kind::Second;
    end;

    var
        FilterSetup: Record "PAG OtherRecOpt Setup";
}

codeunit 95439 "PAG OtherRecOpt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed(Rows: Integer)
    var
        Line: Record "PAG OtherRecOpt Line";
        i: Integer;
    begin
        Line.DeleteAll();
        for i := 1 to Rows do begin
            Line.Init();
            Line.Id := i;
            Line.Opt := Line.Opt::Covered;
            Line.Kind := Line.Kind::First;
            Line.Insert();
        end;
    end;

    local procedure Shows(var P: TestPage "PAG OtherRecOpt List"; Tag: Text)
    begin
        Observer.Observe(Tag + ' var opt', '[' + P.VarOpt.Value() + ']');
        Observer.Observe(Tag + ' var plain', '[' + P.VarPlain.Value() + ']');
        Observer.Observe(Tag + ' var kind', '[' + P.VarKind.Value() + ']');
        Observer.Observe(Tag + ' rec opt', '[' + P.RecOpt.Value() + ']');
        Observer.Observe(Tag + ' rec kind', '[' + P.RecKind.Value() + ']');
        Observer.Observe(Tag + ' row var opt', '[' + P.RowVarOpt.Value() + ']');
        Observer.Observe(Tag + ' row var kind', '[' + P.RowVarKind.Value() + ']');
    end;

    // The reporter's shape: one row in the list.
    [Test]
    procedure OtherRecordOption_OneRow_Values()
    var
        P: TestPage "PAG OtherRecOpt List";
    begin
        Seed(1);
        P.OpenView();
        Shows(P, 'one');
        P.Close();
#if BC29PLUS
        Observer.Expect('one var opt', '[Short Lines]');
#else
        Observer.Expect('one var opt', '[Short]');
#endif
        Observer.Expect('one var plain', '[B]');
        Observer.Expect('one var kind', '[Second Kind]');
        Observer.Expect('one rec opt', '[Covered Lines]');
        Observer.Expect('one rec kind', '[First Kind]');
#if BC29PLUS
        Observer.Expect('one row var opt', '[Short Lines]');
#else
        Observer.Expect('one row var opt', '[Short]');
#endif
        Observer.Expect('one row var kind', '[Second Kind]');
        Observer.Verify();
    end;

    // No row in the list.
    [Test]
    procedure OtherRecordOption_NoRows_Values()
    var
        P: TestPage "PAG OtherRecOpt List";
    begin
        Seed(0);
        P.OpenView();
        Shows(P, 'none');
        P.Close();
        Observer.Expect('none var opt', '[]');
        Observer.Expect('none var plain', '[]');
        Observer.Expect('none var kind', '[]');
        Observer.Expect('none rec opt', '[]');
        Observer.Expect('none rec kind', '[]');
        Observer.Expect('none row var opt', '[]');
        Observer.Expect('none row var kind', '[]');
        Observer.Verify();
    end;

    // Two rows, after Next; the page opened for edit.
    [Test]
    procedure OtherRecordOption_TwoRows_AfterNext_Values()
    var
        P: TestPage "PAG OtherRecOpt List";
    begin
        Seed(2);
        P.OpenEdit();
        P.Next();
        Shows(P, 'next');
        P.Close();
#if BC29PLUS
        Observer.Expect('next var opt', '[Short Lines]');
#else
        Observer.Expect('next var opt', '[Short]');
#endif
        Observer.Expect('next var plain', '[B]');
        Observer.Expect('next var kind', '[Second Kind]');
        Observer.Expect('next rec opt', '[Covered Lines]');
        Observer.Expect('next rec kind', '[First Kind]');
#if BC29PLUS
        Observer.Expect('next row var opt', '[Short Lines]');
#else
        Observer.Expect('next row var opt', '[Short]');
#endif
        Observer.Expect('next row var kind', '[Second Kind]');
        Observer.Verify();
    end;
}
