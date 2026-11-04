// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-data-type
// Scope: in-scope
// Fixtures used: P94Fixtures.al (tables 73057-73059, xmlports 73060-73063, helper 73071), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Xmlport.FieldDelimiter, FieldSeparator, RecordSeparator, TableSeparator: get and set on an instance, and the effect on a variable text export to an OutStream
// BC versions: 29 (27 and 28 by CI)

codeunit 73073 "LT P94 Xp Delim"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";

    local procedure ExportPlain(var Xp: XmlPort "LT P94 Csv Plain"): Text
    var
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        exit(Helper.ReadBlob(Row, TextEncoding::UTF8));
    end;

    local procedure ExportDeclared(var Xp: XmlPort "LT P94 Csv Declared"): Text
    var
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        exit(Helper.ReadBlob(Row, TextEncoding::UTF8));
    end;

    local procedure ExportTwo(var Xp: XmlPort "LT P94 Csv Two"): Text
    var
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        exit(Helper.ReadBlob(Row, TextEncoding::UTF8));
    end;

    local procedure ExportTwoDecl(var Xp: XmlPort "LT P94 Csv Two Decl"): Text
    var
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        exit(Helper.ReadBlob(Row, TextEncoding::UTF8));
    end;

    [Test]
    procedure Getters_NothingDeclared()
    var
        Xp: XmlPort "LT P94 Csv Plain";
    begin
        Observer.Observe('delimiter', '[' + Xp.FieldDelimiter() + ']');
        Observer.Observe('separator', '[' + Xp.FieldSeparator() + ']');
        Observer.Observe('record', '[' + Xp.RecordSeparator() + ']');
        Observer.Observe('table', '[' + Xp.TableSeparator() + ']');
        Observer.Observe('encoding', Format(Xp.TextEncoding()));
        Observer.Expect('delimiter', '["]');
        Observer.Expect('separator', '[,]');
        Observer.Expect('record', '[\r\n]');
        Observer.Expect('table', '[\r\n\r\n]');
        Observer.Expect('encoding', 'MSDos');
        Observer.Verify();
    end;

    [Test]
    procedure Getters_Declared()
    var
        Xp: XmlPort "LT P94 Csv Declared";
    begin
        Observer.Observe('delimiter', '[' + Xp.FieldDelimiter() + ']');
        Observer.Observe('separator', '[' + Xp.FieldSeparator() + ']');
        Observer.Observe('record', '[' + Xp.RecordSeparator() + ']');
        Observer.Observe('table', '[' + Xp.TableSeparator() + ']');
        Observer.Observe('encoding', Format(Xp.TextEncoding()));
        Observer.Expect('delimiter', '[~]');
        Observer.Expect('separator', '[|]');
        Observer.Expect('record', '[\r\n]');
        Observer.Expect('table', '[]');
        Observer.Expect('encoding', 'UTF8');
        Observer.Verify();
    end;

    [Test]
    procedure Getters_DeclaredTwoTables()
    var
        Xp: XmlPort "LT P94 Csv Two Decl";
    begin
        Observer.Observe('delimiter', '[' + Xp.FieldDelimiter() + ']');
        Observer.Observe('separator', '[' + Xp.FieldSeparator() + ']');
        Observer.Observe('record', '[' + Xp.RecordSeparator() + ']');
        Observer.Observe('table', '[' + Xp.TableSeparator() + ']');
        Observer.Expect('delimiter', '[]');
        Observer.Expect('separator', '[;]');
        Observer.Expect('record', '[\n]');
        Observer.Expect('table', '[#]');
        Observer.Verify();
    end;

    [Test]
    procedure Setters_ReadBack()
    var
        Xp: XmlPort "LT P94 Csv Plain";
    begin
        Xp.FieldDelimiter('~');
        Observer.Observe('delimiter', '[' + Xp.FieldDelimiter() + ']');
        Xp.FieldSeparator(';');
        Observer.Observe('separator', '[' + Xp.FieldSeparator() + ']');
        Xp.RecordSeparator('<LF>');
        Observer.Observe('record', '[' + Xp.RecordSeparator() + ']');
        Xp.TableSeparator('<Space>');
        Observer.Observe('table', '[' + Xp.TableSeparator() + ']');
        Observer.Observe('delimiterStill', '[' + Xp.FieldDelimiter() + ']');
        Observer.Expect('delimiter', '[~]');
        Observer.Expect('separator', '[;]');
        Observer.Expect('record', '[<LF>]');
        Observer.Expect('table', '[<Space>]');
        Observer.Expect('delimiterStill', '[~]');
        Observer.Verify();
    end;

    [Test]
    procedure Setters_OverrideDeclared()
    var
        Xp: XmlPort "LT P94 Csv Declared";
    begin
        Xp.FieldDelimiter('"');
        Xp.FieldSeparator(',');
        Xp.RecordSeparator('<LF>');
        Xp.TableSeparator('<NewLine>');
        Observer.Observe('delimiter', '[' + Xp.FieldDelimiter() + ']');
        Observer.Observe('separator', '[' + Xp.FieldSeparator() + ']');
        Observer.Observe('record', '[' + Xp.RecordSeparator() + ']');
        Observer.Observe('table', '[' + Xp.TableSeparator() + ']');
        Observer.Expect('delimiter', '["]');
        Observer.Expect('separator', '[,]');
        Observer.Expect('record', '[<LF>]');
        Observer.Expect('table', '[<NewLine>]');
        Observer.Verify();
    end;

    [Test]
    procedure Setters_TwoInstancesIndependent()
    var
        A: XmlPort "LT P94 Csv Plain";
        B: XmlPort "LT P94 Csv Plain";
    begin
        A.FieldSeparator(';');
        Observer.Observe('a', '[' + A.FieldSeparator() + ']');
        Observer.Observe('b', '[' + B.FieldSeparator() + ']');
        B := A;
        Observer.Observe('bAfterAssign', '[' + B.FieldSeparator() + ']');
        Clear(A);
        Observer.Observe('aAfterClear', '[' + A.FieldSeparator() + ']');
        Observer.Expect('a', '[;]');
        Observer.Expect('b', '[,]');
        Observer.Expect('bAfterAssign', '[;]');
        Observer.Expect('aAfterClear', '[,]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldDelimiter_Variants()
    var
        Xp: XmlPort "LT P94 Csv Plain";
        Values: List of [Text];
        V: Text;
        i: Integer;
    begin
        Values.Add('');
        Values.Add('<None>');
        Values.Add('"');
        Values.Add('''');
        Values.Add('ab');
        Values.Add('<Comma>');
        Values.Add('<Tab>');
        Values.Add('<NewLine>');
        i := 0;
        foreach V in Values do begin
            i += 1;
            Xp.FieldDelimiter(V);
            Observer.Observe('v' + Format(i), '[' + Xp.FieldDelimiter() + ']');
        end;
        Observer.Expect('v1', '[]');
        Observer.Expect('v2', '[<None>]');
        Observer.Expect('v3', '["]');
        Observer.Expect('v4', '['']');
        Observer.Expect('v5', '[ab]');
        Observer.Expect('v6', '[<Comma>]');
        Observer.Expect('v7', '[<Tab>]');
        Observer.Expect('v8', '[<NewLine>]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldSeparator_Variants()
    var
        Xp: XmlPort "LT P94 Csv Plain";
        Values: List of [Text];
        V: Text;
        i: Integer;
    begin
        Values.Add('');
        Values.Add('<None>');
        Values.Add(';');
        Values.Add('<Comma>');
        Values.Add('<Semicolon>');
        Values.Add('<Tab>');
        Values.Add('<Space>');
        Values.Add('<NewLine>');
        Values.Add('ab');
        i := 0;
        foreach V in Values do begin
            i += 1;
            Xp.FieldSeparator(V);
            Observer.Observe('v' + Format(i), '[' + Xp.FieldSeparator() + ']');
        end;
        Observer.Expect('v1', '[]');
        Observer.Expect('v2', '[<None>]');
        Observer.Expect('v3', '[;]');
        Observer.Expect('v4', '[<Comma>]');
        Observer.Expect('v5', '[<Semicolon>]');
        Observer.Expect('v6', '[<Tab>]');
        Observer.Expect('v7', '[<Space>]');
        Observer.Expect('v8', '[<NewLine>]');
        Observer.Expect('v9', '[ab]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordSeparator_Variants()
    var
        Xp: XmlPort "LT P94 Csv Plain";
        Values: List of [Text];
        V: Text;
        i: Integer;
    begin
        Values.Add('');
        Values.Add('<None>');
        Values.Add('<NewLine>');
        Values.Add('<CR>');
        Values.Add('<LF>');
        Values.Add('<CR/LF>');
        Values.Add('<Tab>');
        Values.Add('xyz');
        i := 0;
        foreach V in Values do begin
            i += 1;
            Xp.RecordSeparator(V);
            Observer.Observe('v' + Format(i), '[' + Xp.RecordSeparator() + ']');
        end;
        Observer.Expect('v1', '[]');
        Observer.Expect('v2', '[<None>]');
        Observer.Expect('v3', '[<NewLine>]');
        Observer.Expect('v4', '[<CR>]');
        Observer.Expect('v5', '[<LF>]');
        Observer.Expect('v6', '[<CR/LF>]');
        Observer.Expect('v7', '[<Tab>]');
        Observer.Expect('v8', '[xyz]');
        Observer.Verify();
    end;

    [Test]
    procedure TableSeparator_Variants()
    var
        Xp: XmlPort "LT P94 Csv Two";
        Values: List of [Text];
        V: Text;
        i: Integer;
    begin
        Values.Add('');
        Values.Add('<None>');
        Values.Add('<NewLine>');
        Values.Add('<CR>');
        Values.Add('<LF>');
        Values.Add('<CR/LF>');
        Values.Add('<Tab>');
        Values.Add('#');
        i := 0;
        foreach V in Values do begin
            i += 1;
            Xp.TableSeparator(V);
            Observer.Observe('v' + Format(i), '[' + Xp.TableSeparator() + ']');
        end;
        Observer.Expect('v1', '[]');
        Observer.Expect('v2', '[<None>]');
        Observer.Expect('v3', '[<NewLine>]');
        Observer.Expect('v4', '[<CR>]');
        Observer.Expect('v5', '[<LF>]');
        Observer.Expect('v6', '[<CR/LF>]');
        Observer.Expect('v7', '[<Tab>]');
        Observer.Expect('v8', '[#]');
        Observer.Verify();
    end;

    [Test]
    procedure Export_NothingDeclared()
    var
        Xp: XmlPort "LT P94 Csv Plain";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('csv', ExportPlain(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_Declared()
    var
        Xp: XmlPort "LT P94 Csv Declared";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('csv', ExportDeclared(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_EmptyTable()
    var
        PlainXp: XmlPort "LT P94 Csv Plain";
        DeclXp: XmlPort "LT P94 Csv Declared";
    begin
        Helper.Wipe();
        Observer.Observe('plain', '[' + ExportPlain(PlainXp) + ']');
        Observer.Observe('declared', '[' + ExportDeclared(DeclXp) + ']');
        Observer.Expect('plain', '[]');
        Observer.Expect('declared', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Export_SetFieldSeparator()
    var
        Xp: XmlPort "LT P94 Csv Plain";
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.FieldSeparator(';');
        Observer.Observe('csv', ExportPlain(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_SetFieldDelimiterNone()
    var
        Xp: XmlPort "LT P94 Csv Plain";
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.FieldDelimiter('<None>');
        Observer.Observe('csv', ExportPlain(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_SetFieldDelimiterChar()
    var
        Xp: XmlPort "LT P94 Csv Plain";
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.FieldDelimiter('''');
        Observer.Observe('csv', ExportPlain(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_SetRecordSeparators()
    var
        Xp1: XmlPort "LT P94 Csv Plain";
        Xp2: XmlPort "LT P94 Csv Plain";
        Xp3: XmlPort "LT P94 Csv Plain";
        Xp4: XmlPort "LT P94 Csv Plain";
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp1.RecordSeparator('<CR>');
        Observer.Observe('cr', ExportPlain(Xp1));
        Xp2.RecordSeparator('<LF>');
        Observer.Observe('lf', ExportPlain(Xp2));
        Xp3.RecordSeparator('<CR/LF>');
        Observer.Observe('crlf', ExportPlain(Xp3));
        Xp4.RecordSeparator('<NewLine>');
        Observer.Observe('newline', ExportPlain(Xp4));
        Observer.Expect('cr', '');
        Observer.Expect('lf', '');
        Observer.Expect('crlf', '');
        Observer.Expect('newline', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_SetRecordSeparatorText()
    var
        Xp: XmlPort "LT P94 Csv Plain";
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.RecordSeparator('xyz');
        Observer.Observe('csv', ExportPlain(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_SetEmptySeparators()
    var
        Xp: XmlPort "LT P94 Csv Plain";
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.FieldSeparator('');
        Xp.FieldDelimiter('');
        Xp.RecordSeparator('');
        Observer.Observe('csv', ExportPlain(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_OverrideDeclared()
    var
        Xp: XmlPort "LT P94 Csv Declared";
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.FieldDelimiter('"');
        Xp.FieldSeparator(',');
        Xp.RecordSeparator('<LF>');
        Observer.Observe('csv', ExportDeclared(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_ValueContainsSeparators()
    var
        Xp: XmlPort "LT P94 Csv Declared";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a|b', 1);
        Helper.AddItem(2, 'c~d', 2);
        Helper.AddItem(3, 'e' + Helper.Chr(10) + 'f', 3);
        Observer.Observe('csv', ExportDeclared(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_TwoTablesDefault()
    var
        Xp: XmlPort "LT P94 Csv Two";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('csv', ExportTwo(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_TwoTablesDeclared()
    var
        Xp: XmlPort "LT P94 Csv Two Decl";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('csv', ExportTwoDecl(Xp));
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_TwoTablesSetTableSeparator()
    var
        Xp1: XmlPort "LT P94 Csv Two";
        Xp2: XmlPort "LT P94 Csv Two";
        Xp3: XmlPort "LT P94 Csv Two";
        Xp4: XmlPort "LT P94 Csv Two";
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp1.TableSeparator('<None>');
        Observer.Observe('none', ExportTwo(Xp1));
        Xp2.TableSeparator('<NewLine>');
        Observer.Observe('newline', ExportTwo(Xp2));
        Xp3.TableSeparator('<CR/LF>');
        Observer.Observe('crlf', ExportTwo(Xp3));
        Xp4.TableSeparator('--');
        Observer.Observe('text', ExportTwo(Xp4));
        Observer.Expect('none', '');
        Observer.Expect('newline', '');
        Observer.Expect('crlf', '');
        Observer.Expect('text', '');
        Observer.Verify();
    end;

    [Test]
    procedure Export_TwoTablesOneEmpty()
    var
        Xp: XmlPort "LT P94 Csv Two Decl";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Alpha', 10);
        Observer.Observe('lineEmpty', ExportTwoDecl(Xp));
        Helper.Wipe();
        Helper.AddLine(1, 'L1');
        Clear(Xp);
        Observer.Observe('itemEmpty', ExportTwoDecl(Xp));
        Observer.Expect('lineEmpty', '');
        Observer.Expect('itemEmpty', '');
        Observer.Verify();
    end;

    [Test]
    procedure InTrigger_SeeDeclaredValues()
    var
        Xp: XmlPort "LT P94 Csv Props Trig";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('csv', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('log', 'delim=[~];sep=[|];rec=[\n];table=[];enc=UTF8;after=[||~|\n|UTF8]');
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure InTrigger_SeeValuesSetOutside()
    var
        Xp: XmlPort "LT P94 Csv Props Trig";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.FieldSeparator(',');
        Xp.FieldDelimiter('<None>');
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('csv', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('log', 'delim=[<None>];sep=[,];rec=[\n];table=[];enc=UTF8;after=[,|<None>|\n|UTF8]');
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure InTrigger_SetFieldSeparator()
    var
        Xp: XmlPort "LT P94 Csv Props Trig";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.SetMode(1);
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('csv', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('log', 'delim=[~];sep=[|];rec=[\n];table=[];enc=UTF8;after=[;|~|\n|UTF8]');
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure InTrigger_SetFieldDelimiter()
    var
        Xp: XmlPort "LT P94 Csv Props Trig";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.SetMode(2);
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('csv', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('log', 'delim=[~];sep=[|];rec=[\n];table=[];enc=UTF8;after=[||"|\n|UTF8]');
        Observer.Expect('csv', '');
        Observer.Verify();
    end;

    [Test]
    procedure InTrigger_SetRecordSeparator()
    var
        Xp: XmlPort "LT P94 Csv Props Trig";
        Row: Record "LT P94 Blob" temporary;
        OutS: OutStream;
    begin
        Helper.Wipe();
        Helper.Seed();
        Xp.SetMode(3);
        Row.Data.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        Observer.Observe('log', Xp.GetLog());
        Observer.Observe('csv', Helper.ReadBlob(Row, TextEncoding::UTF8));
        Observer.Expect('log', 'delim=[~];sep=[|];rec=[\n];table=[];enc=UTF8;after=[||~|<CR/LF>|UTF8]');
        Observer.Expect('csv', '');
        Observer.Verify();
    end;
}
