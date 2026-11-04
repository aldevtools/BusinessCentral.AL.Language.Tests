// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 74800
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocument WriteTo(Text), WriteTo(WriteOptions, Text), WriteTo(OutStream), WriteTo(WriteOptions, OutStream) for documents with and without declaration, root and whitespace, and uninitialised
// BC versions: 29 (27 and 28 by CI)

codeunit 74808 "LT P97 Doc WriteTo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Variant: 1 empty document, 2 root only, 3 declaration + comment + pi + root, 4 whitespace in text, 5 declaration only, 6 standalone declaration
    local procedure Build(var Doc: XmlDocument; Variant: Integer)
    var
        R: XmlElement;
    begin
        Doc := XmlDocument.Create();
        case Variant of
            2:
                Doc.Add(XmlElement.Create('r'));
            3:
                begin
                    Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
                    Doc.Add(XmlComment.Create('lead'));
                    Doc.Add(XmlProcessingInstruction.Create('pi', 'data'));
                    Doc.Add(XmlElement.Create('r', XmlElement.Create('c', XmlText.Create('v'))));
                end;
            4:
                begin
                    R := XmlElement.Create('r');
                    R.Add(XmlText.Create('  a  b  '));
                    R.Add(XmlElement.Create('c'));
                    R.Add(XmlText.Create(' tail '));
                    Doc.Add(R);
                end;
            5:
                Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-16', 'no'));
            6:
                begin
                    Doc.SetDeclaration(XmlDeclaration.Create('1.0', '', 'yes'));
                    Doc.Add(XmlElement.Create('r'));
                end;
        end;
    end;

    [TryFunction]
    local procedure TryText(var Doc: XmlDocument; var S: Text)
    begin
        Doc.WriteTo(S);
    end;

    [TryFunction]
    local procedure TryTextOpt(var Doc: XmlDocument; Preserve: Boolean; var S: Text)
    var
        Opt: XmlWriteOptions;
    begin
        Opt.PreserveWhitespace(Preserve);
        Doc.WriteTo(Opt, S);
    end;

    [TryFunction]
    local procedure TryStream(var Doc: XmlDocument; var Rec: Record "LT P97 Blob")
    var
        OutS: OutStream;
    begin
        Rec.Data.CreateOutStream(OutS);
        Doc.WriteTo(OutS);
    end;

    [TryFunction]
    local procedure TryStreamOpt(var Doc: XmlDocument; Preserve: Boolean; var Rec: Record "LT P97 Blob")
    var
        OutS: OutStream;
        Opt: XmlWriteOptions;
    begin
        Rec.Data.CreateOutStream(OutS);
        Opt.PreserveWhitespace(Preserve);
        Doc.WriteTo(Opt, OutS);
    end;

    local procedure ReadBack(var Rec: Record "LT P97 Blob"; var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        InS: InStream;
        T: Text;
    begin
        Rec.CalcFields(Data);
        Observer.Observe(Name + '_len', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(InS);
        if Rec.Data.Length() > 0 then
            InS.ReadText(T);
        Observer.Observe(Name + '_text', T);
    end;

    [Test]
    procedure WriteTo_Text_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        S: Text;
        V: Integer;
    begin
        for V := 1 to 6 do begin
            Build(Doc, V);
            S := 'untouched';
            if TryText(Doc, S) then
                Observer.Observe('v' + Format(V), S)
            else
                Observer.ObserveError('v' + Format(V));
        end;
        Observer.Expect('v1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('v1|code', 'InvalidOperation');
        Observer.Expect('v2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r />');
        Observer.Expect('v3', '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<!--lead-->\r\n<?pi data?>\r\n<r>\r\n  <c>v</c>\r\n</r>');
        Observer.Expect('v4', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>  a  b  <c /> tail </r>');
        Observer.Expect('v5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('v5|code', 'InvalidOperation');
        Observer.Expect('v6', '<?xml version="1.0" encoding="" standalone="yes"?>\r\n<r />');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_TextOptions_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        S: Text;
        V: Integer;
    begin
        for V := 1 to 6 do begin
            Build(Doc, V);
            S := 'untouched';
            if TryTextOpt(Doc, true, S) then
                Observer.Observe('keep' + Format(V), S)
            else
                Observer.ObserveError('keep' + Format(V));
            S := 'untouched';
            if TryTextOpt(Doc, false, S) then
                Observer.Observe('drop' + Format(V), S)
            else
                Observer.ObserveError('drop' + Format(V));
        end;
        Observer.Expect('keep1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('keep1|code', 'InvalidOperation');
        Observer.Expect('drop1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('drop1|code', 'InvalidOperation');
        Observer.Expect('keep2', '<?xml version="1.0" encoding="utf-16"?><r />');
        Observer.Expect('drop2', '<?xml version="1.0" encoding="utf-16"?><r />');
        Observer.Expect('keep3', '<?xml version="1.0" encoding="utf-8" standalone="yes"?><!--lead--><?pi data?><r><c>v</c></r>');
        Observer.Expect('drop3', '<?xml version="1.0" encoding="utf-8" standalone="yes"?><!--lead--><?pi data?><r><c>v</c></r>');
        Observer.Expect('keep4', '<?xml version="1.0" encoding="utf-16"?><r>  a  b  <c /> tail </r>');
        Observer.Expect('drop4', '<?xml version="1.0" encoding="utf-16"?><r>  a  b  <c /> tail </r>');
        Observer.Expect('keep5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('keep5|code', 'InvalidOperation');
        Observer.Expect('drop5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('drop5|code', 'InvalidOperation');
        Observer.Expect('keep6', '<?xml version="1.0" encoding="" standalone="yes"?><r />');
        Observer.Expect('drop6', '<?xml version="1.0" encoding="" standalone="yes"?><r />');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P97 Blob";
        Doc: XmlDocument;
        V: Integer;
    begin
        Rec.DeleteAll();
        for V := 1 to 6 do begin
            Rec.Init();
            Rec.Id := V;
            Rec.Insert();
            Build(Doc, V);
            if TryStream(Doc, Rec) then begin
                Rec.Modify();
                ReadBack(Rec, Observer, 'v' + Format(V));
            end else
                Observer.ObserveError('v' + Format(V));
        end;
        Observer.Expect('v1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('v1|code', 'InvalidOperation');
        Observer.Expect('v2_len', '48');
        Observer.Expect('v2_text', 'Ù‹<?xml version="1.0" encoding="utf-8"?>');
        Observer.Expect('v3_len', '107');
        Observer.Expect('v3_text', 'Ù‹<?xml version="1.0" encoding="utf-8" standalone="yes"?>');
        Observer.Expect('v4_len', '69');
        Observer.Expect('v4_text', 'Ù‹<?xml version="1.0" encoding="utf-8"?>');
        Observer.Expect('v5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('v5|code', 'InvalidOperation');
        Observer.Expect('v6_len', '116');
        Observer.Expect('v6_text', ' þ<');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStreamOptions_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P97 Blob";
        Doc: XmlDocument;
        V: Integer;
    begin
        Rec.DeleteAll();
        for V := 2 to 4 do begin
            Rec.Init();
            Rec.Id := V;
            Rec.Insert();
            Build(Doc, V);
            if TryStreamOpt(Doc, true, Rec) then begin
                Rec.Modify();
                ReadBack(Rec, Observer, 'keep' + Format(V));
            end else
                Observer.ObserveError('keep' + Format(V));
            Rec.Id := V + 10;
            Rec.Insert();
            if TryStreamOpt(Doc, false, Rec) then begin
                Rec.Modify();
                ReadBack(Rec, Observer, 'drop' + Format(V));
            end else
                Observer.ObserveError('drop' + Format(V));
        end;
        Observer.Expect('keep2_len', '46');
        Observer.Expect('keep2_text', 'Ù‹<?xml version="1.0" encoding="utf-8"?><r />');
        Observer.Expect('drop2_len', '46');
        Observer.Expect('drop2_text', 'Ù‹<?xml version="1.0" encoding="utf-8"?><r />');
        Observer.Expect('keep3_len', '95');
        Observer.Expect('keep3_text', 'Ù‹<?xml version="1.0" encoding="utf-8" standalone="yes"?><!--lead--><?pi data?><r><c>v</c></r>');
        Observer.Expect('drop3_len', '132');
        Observer.Expect('drop3_text', 'Ù‹<?xml version="1.0" encoding="utf-8" standalone="yes"?><!--lead--><?pi data?><r><c>v</c></r><!--lead--><?pi data?><r><c>v</c></r>');
        Observer.Expect('keep4_len', '67');
        Observer.Expect('keep4_text', 'Ù‹<?xml version="1.0" encoding="utf-8"?><r>  a  b  <c /> tail </r>');
        Observer.Expect('drop4_len', '67');
        Observer.Expect('drop4_text', 'Ù‹<?xml version="1.0" encoding="utf-8"?><r>  a  b  <c /> tail </r>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_Uninitialised()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P97 Blob";
        Doc: XmlDocument;
        S: Text;
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        if TryText(Doc, S) then
            Observer.Observe('text', S)
        else
            Observer.ObserveError('text');
        if TryTextOpt(Doc, true, S) then
            Observer.Observe('text_opt', S)
        else
            Observer.ObserveError('text_opt');
        if TryStream(Doc, Rec) then
            Observer.Observe('stream', 'ok')
        else
            Observer.ObserveError('stream');
        Observer.Expect('text|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('text|code', 'InvalidOperation');
        Observer.Expect('text_opt|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('text_opt|code', 'InvalidOperation');
        Observer.Expect('stream|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('stream|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Back: XmlDocument;
        S1: Text;
        S2: Text;
        V: Integer;
    begin
        for V := 2 to 4 do begin
            Build(Doc, V);
            Doc.WriteTo(S1);
            Observer.Observe('read' + Format(V), Format(XmlDocument.ReadFrom(S1, Back)));
            Back.WriteTo(S2);
            Observer.Observe('same' + Format(V), Format(S1 = S2));
        end;
        Observer.Expect('read2', 'Yes');
        Observer.Expect('same2', 'No');
        Observer.Expect('read3', 'Yes');
        Observer.Expect('same3', 'No');
        Observer.Expect('read4', 'Yes');
        Observer.Expect('same4', 'No');
        Observer.Verify();
    end;

    // Writer QZ: WriteTo(OutStream) of a document read with XmlDocument.ReadFrom from text that has no declaration (the form of System
    // Application's Xml Validation), and of documents with a utf-16 and a utf-8 declaration and a root, read back line by line from a Temp Blob.
    local procedure QzWriteAndRead(Source: Text; var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Doc: XmlDocument;
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Lines: Text;
        Bytes: Text;
        B: Byte;
        Code: Integer;
        Index: Integer;
    begin
        XmlDocument.ReadFrom(Source, Doc);
        TempBlob.CreateOutStream(OutS);
        Doc.WriteTo(OutS);
        Observer.Observe(Name + ' length', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        for Index := 1 to 3 do begin
            InS.Read(B);
            Code := B;
            Bytes += Format(Code) + ' ';
        end;
        Observer.Observe(Name + ' first bytes', Bytes);
        if Name = 'utf-16 declaration' then
            exit;
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Lines += Line + '|';
        end;
        Observer.Observe(Name + ' lines', Lines);
    end;

    [Test]
    procedure QZ_WriteTo_OutStream_ReadFromText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QzWriteAndRead('<a xmlns="urn:p">x</a>', Observer, 'no declaration');
        QzWriteAndRead('<?xml version="1.0" encoding="utf-16"?><a>x</a>', Observer, 'utf-16 declaration');
        QzWriteAndRead('<?xml version="1.0"?><a>x</a>', Observer, 'declaration without encoding');
        QzWriteAndRead('<?xml version="1.0" encoding="UTF-8"?><a><b>y</b></a>', Observer, 'upper-case utf-8 declaration');
        Observer.Expect('no declaration length', '65');
        Observer.Expect('no declaration first bytes', '239 187 191 ');
        Observer.Expect('no declaration lines', 'Ù‹<?xml version="1.0" encoding="utf-8"?>|<a xmlns="urn:p">x</a>|');
        Observer.Expect('utf-16 declaration length', '100');
        Observer.Expect('utf-16 declaration first bytes', '255 254 60 ');
        Observer.Expect('declaration without encoding length', '51');
        Observer.Expect('declaration without encoding first bytes', '239 187 191 ');
        Observer.Expect('declaration without encoding lines', 'Ù‹<?xml version="1.0" encoding="utf-8"?>|<a>x</a>|');
        Observer.Expect('upper-case utf-8 declaration length', '64');
        Observer.Expect('upper-case utf-8 declaration first bytes', '239 187 191 ');
        Observer.Expect('upper-case utf-8 declaration lines', 'Ù‹<?xml version="1.0" encoding="UTF-8"?>|<a>|  <b>y</b>|</a>|');
        Observer.Verify();
    end;
}
