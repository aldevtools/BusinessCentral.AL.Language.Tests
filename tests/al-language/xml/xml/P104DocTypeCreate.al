// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table LT P104 Blob where an OutStream is written
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocumentType.Create, every overload by parameter types (Name; Name, PublicId; Name, PublicId, SystemId; with InternalSubSet), with Text, Code and literal arguments
// BC versions: 29 (27 and 28 by CI)

codeunit 71827 "LT P104 DocType Create"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(var Observer: Codeunit "Probe Observer"; Name: Text; var DT: XmlDocumentType)
    var
        N: Text;
        P: Text;
        S: Text;
        I: Text;
        W: Text;
    begin
        DT.GetName(N);
        DT.GetPublicId(P);
        DT.GetSystemId(S);
        DT.GetInternalSubset(I);
        DT.WriteTo(W);
        Observer.Observe(Name, '[' + N + '|' + P + '|' + S + '|' + I + '] ' + W);
    end;

    [TryFunction]
    local procedure TryCreate1(Name: Text; var DT: XmlDocumentType)
    begin
        DT := XmlDocumentType.Create(Name);
    end;

    [TryFunction]
    local procedure TryCreate2(Name: Text; PublicId: Text; var DT: XmlDocumentType)
    begin
        DT := XmlDocumentType.Create(Name, PublicId);
    end;

    [TryFunction]
    local procedure TryCreate3(Name: Text; PublicId: Text; SystemId: Text; var DT: XmlDocumentType)
    begin
        DT := XmlDocumentType.Create(Name, PublicId, SystemId);
    end;

    [TryFunction]
    local procedure TryCreate4(Name: Text; PublicId: Text; SystemId: Text; Subset: Text; var DT: XmlDocumentType)
    begin
        DT := XmlDocumentType.Create(Name, PublicId, SystemId, Subset);
    end;

    local procedure Run1(var Observer: Codeunit "Probe Observer"; Tag: Text; Name: Text)
    var
        DT: XmlDocumentType;
    begin
        if TryCreate1(Name, DT) then
            Describe(Observer, Tag, DT)
        else
            Observer.ObserveError(Tag);
    end;

    local procedure Run2(var Observer: Codeunit "Probe Observer"; Tag: Text; Name: Text; PublicId: Text)
    var
        DT: XmlDocumentType;
    begin
        if TryCreate2(Name, PublicId, DT) then
            Describe(Observer, Tag, DT)
        else
            Observer.ObserveError(Tag);
    end;

    local procedure Run3(var Observer: Codeunit "Probe Observer"; Tag: Text; Name: Text; PublicId: Text; SystemId: Text)
    var
        DT: XmlDocumentType;
    begin
        if TryCreate3(Name, PublicId, SystemId, DT) then
            Describe(Observer, Tag, DT)
        else
            Observer.ObserveError(Tag);
    end;

    local procedure Run4(var Observer: Codeunit "Probe Observer"; Tag: Text; Name: Text; PublicId: Text; SystemId: Text; Subset: Text)
    var
        DT: XmlDocumentType;
    begin
        if TryCreate4(Name, PublicId, SystemId, Subset, DT) then
            Describe(Observer, Tag, DT)
        else
            Observer.ObserveError(Tag);
    end;

    [Test]
    procedure P104_Create_InDocument()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        DT: XmlDocumentType;
        S: Text;
        V: Integer;
    begin
        for V := 1 to 4 do begin
            Doc := XmlDocument.Create();
            case V of
                1:
                    DT := XmlDocumentType.Create('r');
                2:
                    DT := XmlDocumentType.Create('r', 'pub');
                3:
                    DT := XmlDocumentType.Create('r', 'pub', 'sys.dtd');
                4:
                    DT := XmlDocumentType.Create('r', '', '', '<!ELEMENT r EMPTY>');
            end;
            Doc.Add(DT);
            Doc.Add(XmlElement.Create('r'));
            Doc.WriteTo(S);
            Observer.Observe('doc' + Format(V), S);
        end;
        Observer.Expect('doc1', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE r >\r\n<r />');
        Observer.Expect('doc2', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE r PUBLIC "pub" "">\r\n<r />');
        Observer.Expect('doc3', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE r PUBLIC "pub" "sys.dtd">\r\n<r />');
        Observer.Expect('doc4', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE r PUBLIC "" ""[<!ELEMENT r EMPTY>]>\r\n<r />');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Create_WriteTo_Overloads()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P104 Blob";
        DT: XmlDocumentType;
        Opt: XmlWriteOptions;
        OutS: OutStream;
        InS: InStream;
        S: Text;
        L: Text;
        T: Text;
    begin
        Rec.DeleteAll();
        DT := XmlDocumentType.Create('r', 'pub', 'sys.dtd');
        DT.WriteTo(S);
        Observer.Observe('text', S);
        Opt.PreserveWhitespace(true);
        DT.WriteTo(Opt, S);
        Observer.Observe('opt_true', S);
        Opt.PreserveWhitespace(false);
        DT.WriteTo(Opt, S);
        Observer.Observe('opt_false', S);
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
        Rec.Data.CreateOutStream(OutS);
        DT.WriteTo(OutS);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(L);
            T += L + '|';
        end;
        Observer.Observe('stream_len', Format(Rec.Data.Length()));
        Observer.Observe('stream_text', T);
        Rec.Id := 2;
        Rec.Insert();
        Rec.Data.CreateOutStream(OutS);
        Opt.PreserveWhitespace(true);
        DT.WriteTo(Opt, OutS);
        Rec.Modify();
        Rec.CalcFields(Data);
        Clear(InS);
        Rec.Data.CreateInStream(InS);
        T := '';
        while not InS.EOS() do begin
            InS.ReadText(L);
            T += L + '|';
        end;
        Observer.Observe('stream_opt_len', Format(Rec.Data.Length()));
        Observer.Observe('stream_opt_text', T);
        Observer.Expect('text', '<!DOCTYPE r PUBLIC "pub" "sys.dtd">');
        Observer.Expect('opt_true', '<!DOCTYPE r PUBLIC "pub" "sys.dtd">');
        Observer.Expect('opt_false', '<!DOCTYPE r PUBLIC "pub" "sys.dtd">');
        Observer.Expect('stream_len', '38');
        Observer.Expect('stream_text', 'Ù‹<!DOCTYPE r PUBLIC "pub" "sys.dtd">|');
        Observer.Expect('stream_opt_len', '38');
        Observer.Expect('stream_opt_text', 'Ù‹<!DOCTYPE r PUBLIC "pub" "sys.dtd">|');
        Observer.Verify();
    end;
}
