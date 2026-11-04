// Probe writer-c, round 2: XmlPort FormatEvaluate = Xml with kinds not yet pinned (docs/probes-needed.md "XmlPort FormatEvaluate").
// Each import test feeds ONE field in the form under test (all other elements are MinOccurs = Zero) and records
// Imported, GetLastErrorText / code and the stored value. Observe-only.
// Fixtures: enum 69767, table 69768, xmlports 69769 / 69770, codeunit 69771.
// Writer TU (2026-10-29), TU_Export_TimeMilliseconds, xmlport 90130 (a temporary copy of the table): export of a Time and a DateTime with
//   milliseconds. Observed on the BC 29.0 SaaS sandbox (two runs, same values); other versions by the corpus CI matrix.
//   BC: FormatEvaluate = Xml writes the milliseconds with trailing zeros dropped (12:34:56.789, 12:34:56.78, 12:34:56.5, 12:34:56.007,
//   00:00:00 without a fraction); Legacy drops them. A row in the database table holds the value SQL Server stored: .789 comes back as .79,
//   00:00:00.001 as 00:00:00 and 23:59:59.999 as 00:00:00 (the DateTime moves to the next day). A temporary record keeps the exact value.

enum 69767 "PW FE Enum"
{
    Extensible = true;

    value(0; Zero) { Caption = 'Zero cap'; }
    value(1; One) { Caption = 'One cap'; }
}

table 69768 "PW FE Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tm; Time) { }
        field(3; Dur; Duration) { }
        field(4; Opt; Option) { OptionMembers = Alpha,Beta,Gamma; OptionCaption = 'Alpha cap,Beta cap,Gamma cap'; }
        field(5; En; Enum "PW FE Enum") { }
        field(6; Dec; Decimal) { }
        field(7; Bl; Boolean) { }
        field(8; Dtm; DateTime) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 69769 "PW FE Xml"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "PW FE Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Tm; T.Tm) { MinOccurs = Zero; }
                fieldelement(Dur; T.Dur) { MinOccurs = Zero; }
                fieldelement(Opt; T.Opt) { MinOccurs = Zero; }
                fieldelement(En; T.En) { MinOccurs = Zero; }
                fieldelement(Dec; T.Dec) { MinOccurs = Zero; }
                fieldelement(Bl; T.Bl) { MinOccurs = Zero; }
                fieldelement(Dtm; T.Dtm) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 69770 "PW FE Legacy"
{
    Format = Xml;
    Direction = Both;
    FormatEvaluate = Legacy;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "PW FE Table")
            {
                fieldelement(Id; T.Id) { MinOccurs = Zero; }
                fieldelement(Tm; T.Tm) { MinOccurs = Zero; }
                fieldelement(Dur; T.Dur) { MinOccurs = Zero; }
                fieldelement(Opt; T.Opt) { MinOccurs = Zero; }
                fieldelement(En; T.En) { MinOccurs = Zero; }
                fieldelement(Dec; T.Dec) { MinOccurs = Zero; }
                fieldelement(Bl; T.Bl) { MinOccurs = Zero; }
                fieldelement(Dtm; T.Dtm) { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 90130 "LT TU XP Time Temp"
{
    Format = Xml;
    Direction = Export;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(T; "PW FE Table")
            {
                UseTemporary = true;
                fieldelement(Id; T.Id) { }
                fieldelement(Tm; T.Tm) { }
                fieldelement(Dtm; T.Dtm) { }
            }
        }
    }

    procedure AddRow(NewId: Integer; NewTime: Time)
    begin
        T.Init();
        T.Id := NewId;
        T.Tm := NewTime;
        if NewTime <> 0T then
            T.Dtm := CreateDateTime(DMY2Date(5, 3, 2024), NewTime);
        T.Insert();
    end;
}

codeunit 69771 "PW XmlPort FmtEval Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure ExportText(XmlPortId: Integer): Text
    var
        Row: Record "PW FE Table";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Tm := 123456T;
        Row.Dur := 90061001;
        Row.Opt := Row.Opt::Beta;
        Row.En := Row.En::One;
        Row.Dec := 1234.5;
        Row.Bl := true;
        Row.Dtm := CreateDateTime(DMY2Date(5, 3, 2024), 123456T);
        Row.Insert();
        Commit();
        TempBlob.CreateOutStream(OutStr);
        Xmlport.Export(XmlPortId, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure ImportOne(XmlPortId: Integer; Element: Text; Value: Text; Name: Text)
    var
        Row: Record "PW FE Table";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Imported: Boolean;
        Stored: Text;
    begin
        Row.DeleteAll();
        Commit();
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('<?xml version="1.0" encoding="utf-8"?><Root><T><Id>1</Id><' + Element + '>' + Value + '</' + Element + '></T></Root>');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        ClearLastError();
        Imported := Xmlport.Import(XmlPortId, InStr);
        if Row.Get(1) then
            Stored := StrSubstNo('Tm=%1 Dur=%2 Opt=%3 En=%4 Dec=%5 Bl=%6 Dtm=%7', Row.Tm, Row.Dur, Row.Opt, Row.En, Row.Dec, Row.Bl, Row.Dtm)
        else
            Stored := 'no row';
        Observer.Observe(Name, StrSubstNo('imported=%1 error=[%2] code=[%3] stored=[%4]', Imported, GetLastErrorText(), GetLastErrorCode(), Stored));
        Commit();
    end;

    [Test]
    procedure Export_Xml_TimeDurationOptionEnum()
    begin
        Observer.Observe('export_xml', ExportText(Xmlport::"PW FE Xml"));
        Observer.Expect('export_xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Tm>12:34:56</Tm>|    <Dur>P1DT1H1M1.001S</Dur>|    <Opt>1</Opt>|    <En>1</En>|    <Dec>1234.50</Dec>|    <Bl>true</Bl>|    <Dtm>2024-03-05T12:34:56Z</Dtm>|  </T>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Legacy_TimeDurationOptionEnum()
    begin
        Observer.Observe('export_legacy', ExportText(Xmlport::"PW FE Legacy"));
        Observer.Expect('export_legacy', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Tm>12:34:56 PM</Tm>|    <Dur>1 day 1 hour 1 minute 1 second 1 millisecond</Dur>|    <Opt>Beta cap</Opt>|    <En>One cap</En>|    <Dec>1,234.50</Dec>|    <Bl>Yes</Bl>|    <Dtm>03/05/24 12:34 PM</Dtm>|  </T>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_Time()
    begin
        ImportOne(Xmlport::"PW FE Xml", 'Tm', '12:34:56', 'time_hms');
        ImportOne(Xmlport::"PW FE Xml", 'Tm', '12:34:56.789', 'time_hms_millis');
        ImportOne(Xmlport::"PW FE Xml", 'Tm', '12:34:56 PM', 'time_display_pm');
        Observer.Expect('time_hms', 'imported=Yes error=[] code=[] stored=[Tm=12:34:56 PM Dur= Opt=Alpha cap En=Zero cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('time_hms_millis', 'imported=Yes error=[] code=[] stored=[Tm=12:34:56 PM Dur= Opt=Alpha cap En=Zero cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('time_display_pm', 'imported=No error=[The value "12:34:56 PM" can''t be evaluated into type Time.] code=[Evaluate] stored=[no row]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_Duration()
    begin
        ImportOne(Xmlport::"PW FE Xml", 'Dur', 'PT1H', 'duration_iso');
        ImportOne(Xmlport::"PW FE Xml", 'Dur', '3600000', 'duration_ms');
        ImportOne(Xmlport::"PW FE Xml", 'Dur', '1 hour', 'duration_words');
        Observer.Expect('duration_iso', 'imported=Yes error=[] code=[] stored=[Tm= Dur=1 hour Opt=Alpha cap En=Zero cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('duration_ms', 'imported=No error=[The value "3600000" can''t be evaluated into type Duration.] code=[Evaluate] stored=[no row]');
        Observer.Expect('duration_words', 'imported=No error=[The value "1 hour" can''t be evaluated into type Duration.] code=[Evaluate] stored=[no row]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_Option()
    begin
        ImportOne(Xmlport::"PW FE Xml", 'Opt', 'Beta', 'option_member_name');
        ImportOne(Xmlport::"PW FE Xml", 'Opt', '1', 'option_ordinal');
        ImportOne(Xmlport::"PW FE Xml", 'Opt', 'Beta cap', 'option_caption');
        Observer.Expect('option_member_name', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Beta cap En=Zero cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('option_ordinal', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Beta cap En=Zero cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('option_caption', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Beta cap En=Zero cap Dec=0 Bl=No Dtm=]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_Enum()
    begin
        ImportOne(Xmlport::"PW FE Xml", 'En', 'One', 'enum_name');
        ImportOne(Xmlport::"PW FE Xml", 'En', '1', 'enum_ordinal');
        ImportOne(Xmlport::"PW FE Xml", 'En', 'One cap', 'enum_caption');
        Observer.Expect('enum_name', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=One cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('enum_ordinal', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=One cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('enum_caption', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=One cap Dec=0 Bl=No Dtm=]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_DisplayTextOfDecimalBooleanDateTime()
    begin
        ImportOne(Xmlport::"PW FE Xml", 'Dec', '1,234.50', 'decimal_display');
        ImportOne(Xmlport::"PW FE Xml", 'Dec', '1234.50', 'decimal_xml');
        ImportOne(Xmlport::"PW FE Xml", 'Bl', 'Yes', 'boolean_display_yes');
        ImportOne(Xmlport::"PW FE Xml", 'Bl', 'true', 'boolean_xml');
        ImportOne(Xmlport::"PW FE Xml", 'Bl', '1', 'boolean_one');
        ImportOne(Xmlport::"PW FE Xml", 'Dtm', '3/5/2024 12:34 PM', 'datetime_display');
        Observer.Expect('decimal_display', 'imported=No error=[The value "1,234.50" can''t be evaluated into type Decimal.] code=[Evaluate] stored=[no row]');
        Observer.Expect('decimal_xml', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=Zero cap Dec=1,234.5 Bl=No Dtm=]');
        Observer.Expect('boolean_display_yes', 'imported=No error=[The value "Yes" can''t be evaluated into type Boolean.] code=[Evaluate] stored=[no row]');
        Observer.Expect('boolean_xml', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=Zero cap Dec=0 Bl=Yes Dtm=]');
        Observer.Expect('boolean_one', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=Zero cap Dec=0 Bl=Yes Dtm=]');
        Observer.Expect('datetime_display', 'imported=No error=[The value "3/5/2024 12:34 PM" can''t be evaluated into type DateTime.] code=[Evaluate] stored=[no row]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Xml_DateTimeWithAndWithoutZ()
    begin
        ImportOne(Xmlport::"PW FE Xml", 'Dtm', '2024-03-05T12:34:56Z', 'datetime_z');
        ImportOne(Xmlport::"PW FE Xml", 'Dtm', '2024-03-05T12:34:56', 'datetime_no_z');
        ImportOne(Xmlport::"PW FE Xml", 'Dtm', '2024-03-05T12:34:56.789Z', 'datetime_millis_z');
        ImportOne(Xmlport::"PW FE Xml", 'Dtm', '2024-03-05T12:34:56+02:00', 'datetime_offset');
        Observer.Expect('datetime_z', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=Zero cap Dec=0 Bl=No Dtm=03/05/24 12:34 PM]');
        Observer.Expect('datetime_no_z', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=Zero cap Dec=0 Bl=No Dtm=03/05/24 12:34 PM]');
        Observer.Expect('datetime_millis_z', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=Zero cap Dec=0 Bl=No Dtm=03/05/24 12:34 PM]');
        Observer.Expect('datetime_offset', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=Zero cap Dec=0 Bl=No Dtm=03/05/24 10:34 AM]');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Legacy_Time_Duration_Option_Enum()
    begin
        ImportOne(Xmlport::"PW FE Legacy", 'Tm', '12:34:56 PM', 'legacy_time_display');
        ImportOne(Xmlport::"PW FE Legacy", 'Dur', '1 hour', 'legacy_duration_words');
        ImportOne(Xmlport::"PW FE Legacy", 'Opt', 'Beta', 'legacy_option_name');
        ImportOne(Xmlport::"PW FE Legacy", 'En', 'One', 'legacy_enum_name');
        Observer.Expect('legacy_time_display', 'imported=Yes error=[] code=[] stored=[Tm=12:34:56 PM Dur= Opt=Alpha cap En=Zero cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('legacy_duration_words', 'imported=Yes error=[] code=[] stored=[Tm= Dur=1 hour Opt=Alpha cap En=Zero cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('legacy_option_name', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Beta cap En=Zero cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('legacy_enum_name', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=One cap Dec=0 Bl=No Dtm=]');
        Observer.Verify();
    end;

    // Corpus issue 671 item 105 (microsoft/AL#5284, "Requested value ... was not found"): an Enum field element on import
    // given a value that is no member name, ordinal or caption of the enum.
    [Test]
    procedure Import_Xml_Enum_Invalid()
    begin
        ImportOne(Xmlport::"PW FE Xml", 'En', 'Two', 'enum_unknown_name');
        ImportOne(Xmlport::"PW FE Xml", 'En', '7', 'enum_unknown_ordinal');
        ImportOne(Xmlport::"PW FE Xml", 'En', 'one', 'enum_name_lower_case');
        ImportOne(Xmlport::"PW FE Xml", 'En', '', 'enum_empty');
        Observer.Expect('enum_unknown_name', 'imported=No error=[''Two'' is not an option. The existing options are: Zero cap,One cap] code=[InvalidOptionString] stored=[no row]');
        Observer.Expect('enum_unknown_ordinal', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=7 Dec=0 Bl=No Dtm=]');
        Observer.Expect('enum_name_lower_case', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=One cap Dec=0 Bl=No Dtm=]');
        Observer.Expect('enum_empty', 'imported=Yes error=[] code=[] stored=[Tm= Dur= Opt=Alpha cap En=Zero cap Dec=0 Bl=No Dtm=]');
        Observer.Verify();
    end;

    local procedure TuExportTimes(XmlPortId: Integer): Text
    var
        Row: Record "PW FE Table";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        Row.DeleteAll();
        TuTimeRow(1, 123456.789T);
        TuTimeRow(2, 123456.78T);
        TuTimeRow(3, 123456.007T);
        TuTimeRow(4, 000000.001T);
        TuTimeRow(5, 235959.999T);
        TuTimeRow(6, 0T);
        TuTimeRow(7, 123456.5T);
        TuTimeRow(8, 000000T);
        Commit();
        TempBlob.CreateOutStream(OutStr);
        Xmlport.Export(XmlPortId, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure TuTimeRow(NewId: Integer; NewTime: Time)
    var
        Row: Record "PW FE Table";
    begin
        Row.Id := NewId;
        Row.Tm := NewTime;
        if NewTime <> 0T then
            Row.Dtm := CreateDateTime(DMY2Date(5, 3, 2024), NewTime);
        Row.Insert();
    end;

    local procedure TuExportTimesTemp(): Text
    var
        Port: XmlPort "LT TU XP Time Temp";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        Port.AddRow(1, 123456.789T);
        Port.AddRow(2, 123456.78T);
        Port.AddRow(3, 123456.007T);
        Port.AddRow(4, 000000.001T);
        Port.AddRow(5, 235959.999T);
        Port.AddRow(6, 0T);
        Port.AddRow(7, 123456.5T);
        Port.AddRow(8, 000000T);
        Port.AddRow(9, 123456.1T);
        Port.AddRow(10, 123456.01T);
        TempBlob.CreateOutStream(OutStr);
        Port.SetDestination(OutStr);
        Port.Export();
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    [Test]
    procedure TU_Export_TimeMilliseconds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Rows with Time 12:34:56.789, .78, .007, 00:00:00.001, 23:59:59.999, 0T, .5 and 00:00:00, exported with FormatEvaluate = Xml and Legacy
        Observer.Observe('export_xml', TuExportTimes(Xmlport::"PW FE Xml"));
        Observer.Observe('export_legacy', TuExportTimes(Xmlport::"PW FE Legacy"));
        Observer.Observe('export_xml_temporary', TuExportTimesTemp());
        Observer.Expect('export_xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Tm>12:34:56.79</Tm>|    <Dur>P0DT0H0M0.0S</Dur>|    <Opt>0</Opt>|    <En>0</En>|    <Dec>0.00</Dec>|    <Bl>false</Bl>|    <Dtm>2024-03-05T12:34:56.79Z</Dtm>|  </T>|  <T>|    <Id>2</Id>|    <Tm>12:34:56.78</Tm>|    <Dur>P0DT0H0M0.0S</Dur>|    <Opt>0</Opt>|    <En>0</En>|    <Dec>0.00</Dec>|    <Bl>false</Bl>|    <Dtm>2024-03-05T12:34:56.78Z</Dtm>|  </T>|  <T>|    <Id>3</Id>|    <Tm>12:34:56.007</Tm>|    <Dur>P0DT0H0M0.0S</Dur>|    <Opt>0</Opt>|    <En>0</En>|    <Dec>0.00</Dec>|    <Bl>false</Bl>|    <Dtm>2024-03-05T12:34:56.007Z</Dtm>|  </T>|  <T>|    <Id>4</Id>|    <Tm>00:00:00</Tm>|    <Dur>P0DT0H0M0.0S</Dur>|    <Opt>0</Opt>|    <En>0</En>|    <Dec>0.00</Dec>|    <Bl>false</Bl>|    <Dtm>2024-03-05T00:00:00Z</Dtm>|  </T>|  <T>|    <Id>5</Id>|    <Tm>00:00:00</Tm>|    <Dur>P0DT0H0M0.0S</Dur>|    <Opt>0</Opt>|    <En>0</En>|    <Dec>0.00</Dec>|    <Bl>false</Bl>|    <Dtm>2024-03-06T00:00:00Z</Dtm>|  </T>|  <T>|    <Id>6</Id>|    <Tm />|    <Dur>P0DT0H0M0.0S</Dur>|    <Opt>0</Opt>|    <En>0</En>|    <Dec>0.00</Dec>|    <Bl>false</Bl>|    <Dtm />|  </T>|  <T>|    <Id>7</Id>|    <Tm>12:34:56.5</Tm>|    <Dur>P0DT0H0M0.0S</Dur>|    <Opt>0</Opt>|    <En>0</En>|    <Dec>0.00</Dec>|    <Bl>false</Bl>|    <Dtm>2024-03-05T12:34:56.5Z</Dtm>|  </T>|  <T>|    <Id>8</Id>|    <Tm>00:00:00</Tm>|    <Dur>P0DT0H0M0.0S</Dur>|    <Opt>0</Opt>|    <En>0</En>|    <Dec>0.00</Dec>|    <Bl>false</Bl>|    <Dtm>2024-03-05T00:00:00Z</Dtm>|  </T>|</Root>|');
        Observer.Expect('export_legacy', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Tm>12:34:56 PM</Tm>|    <Dur />|    <Opt>Alpha cap</Opt>|    <En>Zero cap</En>|    <Dec>0.00</Dec>|    <Bl>No</Bl>|    <Dtm>03/05/24 12:34 PM</Dtm>|  </T>|  <T>|    <Id>2</Id>|    <Tm>12:34:56 PM</Tm>|    <Dur />|    <Opt>Alpha cap</Opt>|    <En>Zero cap</En>|    <Dec>0.00</Dec>|    <Bl>No</Bl>|    <Dtm>03/05/24 12:34 PM</Dtm>|  </T>|  <T>|    <Id>3</Id>|    <Tm>12:34:56 PM</Tm>|    <Dur />|    <Opt>Alpha cap</Opt>|    <En>Zero cap</En>|    <Dec>0.00</Dec>|    <Bl>No</Bl>|    <Dtm>03/05/24 12:34 PM</Dtm>|  </T>|  <T>|    <Id>4</Id>|    <Tm>12:00:00 AM</Tm>|    <Dur />|    <Opt>Alpha cap</Opt>|    <En>Zero cap</En>|    <Dec>0.00</Dec>|    <Bl>No</Bl>|    <Dtm>03/05/24 12:00 AM</Dtm>|  </T>|  <T>|    <Id>5</Id>|    <Tm>12:00:00 AM</Tm>|    <Dur />|    <Opt>Alpha cap</Opt>|    <En>Zero cap</En>|    <Dec>0.00</Dec>|    <Bl>No</Bl>|    <Dtm>03/06/24 12:00 AM</Dtm>|  </T>|  <T>|    <Id>6</Id>|    <Tm />|    <Dur />|    <Opt>Alpha cap</Opt>|    <En>Zero cap</En>|    <Dec>0.00</Dec>|    <Bl>No</Bl>|    <Dtm />|  </T>|  <T>|    <Id>7</Id>|    <Tm>12:34:56 PM</Tm>|    <Dur />|    <Opt>Alpha cap</Opt>|    <En>Zero cap</En>|    <Dec>0.00</Dec>|    <Bl>No</Bl>|    <Dtm>03/05/24 12:34 PM</Dtm>|  </T>|  <T>|    <Id>8</Id>|    <Tm>12:00:00 AM</Tm>|    <Dur />|    <Opt>Alpha cap</Opt>|    <En>Zero cap</En>|    <Dec>0.00</Dec>|    <Bl>No</Bl>|    <Dtm>03/05/24 12:00 AM</Dtm>|  </T>|</Root>|');
        Observer.Expect('export_xml_temporary', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <T>|    <Id>1</Id>|    <Tm>12:34:56.789</Tm>|    <Dtm>2024-03-05T12:34:56.789Z</Dtm>|  </T>|  <T>|    <Id>2</Id>|    <Tm>12:34:56.78</Tm>|    <Dtm>2024-03-05T12:34:56.78Z</Dtm>|  </T>|  <T>|    <Id>3</Id>|    <Tm>12:34:56.007</Tm>|    <Dtm>2024-03-05T12:34:56.007Z</Dtm>|  </T>|  <T>|    <Id>4</Id>|    <Tm>00:00:00.001</Tm>|    <Dtm>2024-03-05T00:00:00.001Z</Dtm>|  </T>|  <T>|    <Id>5</Id>|    <Tm>23:59:59.999</Tm>|    <Dtm>2024-03-05T23:59:59.999Z</Dtm>|  </T>|  <T>|    <Id>6</Id>|    <Tm />|    <Dtm />|  </T>|  <T>|    <Id>7</Id>|    <Tm>12:34:56.5</Tm>|    <Dtm>2024-03-05T12:34:56.5Z</Dtm>|  </T>|  <T>|    <Id>8</Id>|    <Tm>00:00:00</Tm>|    <Dtm>2024-03-05T00:00:00Z</Dtm>|  </T>|  <T>|    <Id>9</Id>|    <Tm>12:34:56.1</Tm>|    <Dtm>2024-03-05T12:34:56.1Z</Dtm>|  </T>|  <T>|    <Id>10</Id>|    <Tm>12:34:56.01</Tm>|    <Dtm>2024-03-05T12:34:56.01Z</Dtm>|  </T>|</Root>|');
        Observer.Verify();
    end;
}
