// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.security.encryption.signedxml
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); System Application codeunits SignedXml (1460), "Signature Key" and RSA; own test codeunit 75104
// Probe (observe only): al-runner issue 7394. The System Application codeunit SignedXml keeps a DotNet Reference in a variable, hands it to the
//   .NET SignedXml in AddReferenceToSignedXML and clears the variable right after. This probe runs the reported sequence
//   (InitializeSignedXml, InitializeReference(''), AddXmlDsigExcC14NTransformToReference(''), AddReferenceToSignedXML, SetSigningKey,
//   ComputeSignature) and variations: no explicit AddReferenceToSignedXML (ComputeSignature adds the reference), AddReferenceToSignedXML called
//   twice, two references, the enveloped-signature transform, a digest method, and ComputeSignature with no reference at all.
//   The RSA key is made at run time (RSA.InitializeRSA(2048)), so the SignatureValue differs from run to run: observed are the structure of the
//   Signature element (algorithms, reference URIs, transforms, DigestValue, the length of SignatureValue) and CheckSignature.
//   The DigestValue depends only on the document and the transforms. Each step runs in a TryFunction.
// BC versions: 27, 28, 29

codeunit 75104 "LT SXR SignedXml Reference"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure NewKey(var SignatureKey: Codeunit "Signature Key")
    var
        RSA: Codeunit RSA;
    begin
        RSA.InitializeRSA(2048);
        SignatureKey.FromXmlString(RSA.ToSecretXmlString(true));
    end;

    local procedure Describe(Signature: XmlElement): Text
    var
        Nodes: XmlNodeList;
        Node: XmlNode;
        Attr: XmlAttribute;
        Ns: XmlNamespaceManager;
        Result: Text;
        Value: Text;
    begin
        Ns.AddNamespace('ds', 'http://www.w3.org/2000/09/xmldsig#');
        Result := 'root=' + Signature.Name + ' ns=' + Signature.NamespaceUri;
        if Signature.SelectSingleNode('ds:SignedInfo/ds:CanonicalizationMethod/@Algorithm', Ns, Node) then
            Result += ' c14n=' + Node.AsXmlAttribute().Value;
        if Signature.SelectSingleNode('ds:SignedInfo/ds:SignatureMethod/@Algorithm', Ns, Node) then
            Result += ' method=' + Node.AsXmlAttribute().Value;
        if Signature.SelectNodes('ds:SignedInfo/ds:Reference', Ns, Nodes) then begin
            Result += ' references=' + Format(Nodes.Count());
            foreach Node in Nodes do begin
                Result += ' [';
                if Node.AsXmlElement().Attributes().Get('URI', Attr) then
                    Result += 'uri=' + Attr.Value
                else
                    Result += 'no uri';
                Result += ' transforms=' + AttributeList(Node.AsXmlElement(), 'ds:Transforms/ds:Transform/@Algorithm', Ns);
                Result += ' digest method=' + AttributeList(Node.AsXmlElement(), 'ds:DigestMethod/@Algorithm', Ns);
                Result += ' digest=' + ElementText(Node.AsXmlElement(), 'ds:DigestValue', Ns) + ']';
            end;
        end;
        Value := ElementText(Signature, 'ds:SignatureValue', Ns);
        Result += ' signature value length=' + Format(StrLen(Value));
        Result += ' key info=' + Format(Signature.SelectSingleNode('ds:KeyInfo', Ns, Node));
        exit(Result);
    end;

    local procedure AttributeList(Element: XmlElement; Path: Text; Ns: XmlNamespaceManager): Text
    var
        Nodes: XmlNodeList;
        Node: XmlNode;
        Result: Text;
    begin
        if Element.SelectNodes(Path, Ns, Nodes) then
            foreach Node in Nodes do
                Result += Node.AsXmlAttribute().Value + ',';
        exit(Result);
    end;

    local procedure ElementText(Element: XmlElement; Path: Text; Ns: XmlNamespaceManager): Text
    var
        Node: XmlNode;
    begin
        if Element.SelectSingleNode(Path, Ns, Node) then
            exit(Node.AsXmlElement().InnerText);
        exit('<none>');
    end;

    [TryFunction]
    local procedure TrySign(Step: Integer; var Answer: Text)
    var
        SignedXml: Codeunit SignedXml;
        SignatureKey: Codeunit "Signature Key";
        Doc: XmlDocument;
        Signature: XmlElement;
    begin
        XmlDocument.ReadFrom('<Root><Data Id="d1">x</Data><Data Id="d2">y</Data></Root>', Doc);
        NewKey(SignatureKey);
        SignedXml.InitializeSignedXml(Doc);
        case Step of
            1:
                begin
                    // The reported sequence.
                    SignedXml.InitializeReference('');
                    SignedXml.AddXmlDsigExcC14NTransformToReference('');
                    SignedXml.AddReferenceToSignedXML();
                    SignedXml.SetSigningKey(SignatureKey);
                end;
            2:
                begin
                    // ComputeSignature adds the reference that is still in the variable.
                    SignedXml.InitializeReference('');
                    SignedXml.AddXmlDsigExcC14NTransformToReference('');
                    SignedXml.SetSigningKey(SignatureKey);
                end;
            3:
                begin
                    SignedXml.InitializeReference('');
                    SignedXml.AddXmlDsigExcC14NTransformToReference('');
                    SignedXml.AddReferenceToSignedXML();
                    SignedXml.AddReferenceToSignedXML();
                    SignedXml.SetSigningKey(SignatureKey);
                end;
            4:
                begin
                    SignedXml.InitializeReference('#d1');
                    SignedXml.AddXmlDsigExcC14NTransformToReference('');
                    SignedXml.AddReferenceToSignedXML();
                    SignedXml.InitializeReference('#d2');
                    SignedXml.AddXmlDsigExcC14NTransformToReference('');
                    SignedXml.AddReferenceToSignedXML();
                    SignedXml.SetSigningKey(SignatureKey);
                end;
            5:
                begin
                    SignedXml.InitializeReference('');
                    SignedXml.AddXmlDsigEnvelopedSignatureTransform();
                    SignedXml.AddXmlDsigExcC14NTransformToReference();
                    SignedXml.SetDigestMethod(SignedXml.GetXmlDsigSHA1Url());
                    SignedXml.AddReferenceToSignedXML();
                    SignedXml.SetSigningKey(SignatureKey);
                end;
            6:
                // No reference at all.
                SignedXml.SetSigningKey(SignatureKey);
            7:
                begin
                    // A reference that is initialized twice before it is added: only the second one is added.
                    SignedXml.InitializeReference('#d1');
                    SignedXml.InitializeReference('#d2');
                    SignedXml.AddReferenceToSignedXML();
                    SignedXml.SetSigningKey(SignatureKey);
                end;
            8:
                begin
                    // No signing key.
                    SignedXml.InitializeReference('');
                    SignedXml.AddReferenceToSignedXML();
                end;
        end;
        SignedXml.ComputeSignature();
        Signature := SignedXml.GetXml();
        Answer := Describe(Signature);
        Answer += ' check=' + Format(SignedXml.CheckSignature());
    end;

    local procedure ObserveStep(var Observer: Codeunit "Probe Observer"; Step: Integer; Name: Text)
    var
        Answer: Text;
    begin
        ClearLastError();
        if TrySign(Step, Answer) then
            Observer.Observe(Name, Answer)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure SignedXml_ReportedSequence_ComputesSignature()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStep(Observer, 1, 'reference added, then key, then ComputeSignature');
        ObserveStep(Observer, 2, 'reference not added before ComputeSignature');
        ObserveStep(Observer, 3, 'AddReferenceToSignedXML twice');
        Observer.Expect('reference added, then key, then ComputeSignature', 'root=:Signature ns=http://www.w3.org/2000/09/xmldsig# c14n=http://www.w3.org/TR/2001/REC-xml-c14n-20010315 method=http://www.w3.org/2001/04/xmldsig-more#rsa-sha256 references=1 [uri= transforms=http://www.w3.org/2001/10/xml-exc-c14n#, digest method=http://www.w3.org/2001/04/xmlenc#sha256, digest=EqWbCBAs3bfcRdcZ6yh4t2OXEmNPK2CFDUEM3YlTR74=] signature value length=344 key info=No check=No');
        Observer.Expect('reference not added before ComputeSignature', 'root=:Signature ns=http://www.w3.org/2000/09/xmldsig# c14n=http://www.w3.org/TR/2001/REC-xml-c14n-20010315 method=http://www.w3.org/2001/04/xmldsig-more#rsa-sha256 references=1 [uri= transforms=http://www.w3.org/2001/10/xml-exc-c14n#, digest method=http://www.w3.org/2001/04/xmlenc#sha256, digest=EqWbCBAs3bfcRdcZ6yh4t2OXEmNPK2CFDUEM3YlTR74=] signature value length=344 key info=No check=No');
        Observer.Expect('AddReferenceToSignedXML twice', 'root=:Signature ns=http://www.w3.org/2000/09/xmldsig# c14n=http://www.w3.org/TR/2001/REC-xml-c14n-20010315 method=http://www.w3.org/2001/04/xmldsig-more#rsa-sha256 references=1 [uri= transforms=http://www.w3.org/2001/10/xml-exc-c14n#, digest method=http://www.w3.org/2001/04/xmlenc#sha256, digest=EqWbCBAs3bfcRdcZ6yh4t2OXEmNPK2CFDUEM3YlTR74=] signature value length=344 key info=No check=No');
        Observer.Verify();
    end;

    [Test]
    procedure SignedXml_TwoReferences_Transforms_DigestMethod()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStep(Observer, 4, 'two references by id');
        ObserveStep(Observer, 5, 'enveloped signature and C14N transforms, SHA1 digest');
        ObserveStep(Observer, 7, 'InitializeReference twice, then add');
        Observer.Expect('two references by id', 'root=:Signature ns=http://www.w3.org/2000/09/xmldsig# c14n=http://www.w3.org/TR/2001/REC-xml-c14n-20010315 method=http://www.w3.org/2001/04/xmldsig-more#rsa-sha256 references=2 [uri=#d1 transforms=http://www.w3.org/2001/10/xml-exc-c14n#, digest method=http://www.w3.org/2001/04/xmlenc#sha256, digest=zro6v3waKxtez9qcsDFWB0SZmQ43+rx0MS6+YtMtGLA=] [uri=#d2 transforms=http://www.w3.org/2001/10/xml-exc-c14n#, digest method=http://www.w3.org/2001/04/xmlenc#sha256, digest=Jsq5V6S2uwFIzxhoObHpLaOymNKcqpUY0iyzmiJuWC8=] signature value length=344 key info=No check=No');
        Observer.Expect('enveloped signature and C14N transforms, SHA1 digest', 'root=:Signature ns=http://www.w3.org/2000/09/xmldsig# c14n=http://www.w3.org/TR/2001/REC-xml-c14n-20010315 method=http://www.w3.org/2001/04/xmldsig-more#rsa-sha256 references=1 [uri= transforms=http://www.w3.org/2000/09/xmldsig#enveloped-signature,http://www.w3.org/2001/10/xml-exc-c14n#, digest method=http://www.w3.org/2000/09/xmldsig#sha1, digest=gPC+WCwT6GGgD4SthnopOwaMgyQ=] signature value length=344 key info=No check=No');
        Observer.Expect('InitializeReference twice, then add', 'root=:Signature ns=http://www.w3.org/2000/09/xmldsig# c14n=http://www.w3.org/TR/2001/REC-xml-c14n-20010315 method=http://www.w3.org/2001/04/xmldsig-more#rsa-sha256 references=1 [uri=#d2 transforms= digest method=http://www.w3.org/2001/04/xmlenc#sha256, digest=Jsq5V6S2uwFIzxhoObHpLaOymNKcqpUY0iyzmiJuWC8=] signature value length=344 key info=No check=No');
        Observer.Verify();
    end;

    [Test]
    procedure SignedXml_NoReference_NoKey_Errors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStep(Observer, 6, 'no reference');
        ObserveStep(Observer, 8, 'no signing key');
        Observer.Expect('no reference|text', 'A call to System.Security.Cryptography.Xml.SignedXml.ComputeSignature failed with this message: At least one Reference element is required.');
        Observer.Expect('no reference|code', 'DotNetInvoke:Cryptographic');
        Observer.Expect('no signing key|text', 'A call to System.Security.Cryptography.Xml.SignedXml.ComputeSignature failed with this message: Signing key is not loaded.');
        Observer.Expect('no signing key|code', 'DotNetInvoke:Cryptographic');
        Observer.Verify();
    end;
}
