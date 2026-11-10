// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99004
// Probe (observe only): al-runner issue 7394. Clear of a DotNet variable that holds a System.Security.Cryptography.Xml.Reference, the way the System
//   Application codeunit "SignedXml Impl." does it (AddReference, then Clear of the variable, then ComputeSignature):
//     IsNull of the variable before and after Clear, the reference count of the SignedXml after Clear, and whether the signature is still
//     computed and checks; a second variable that holds the same Reference after Clear of the first (its Uri and transform count);
//     Clear of a Reference that was never added; Clear of a variable that was never assigned; Clear of the SignedXml variable itself while
//     another variable holds it; Clear of an XmlDsigExcC14NTransform that a Reference holds.
//   The RSA key is created at run time, so only the structure and CheckSignature are observed, not the signature bytes.
//   Each step runs in a TryFunction: the answer, or the error text and code.
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Security.Cryptography.Xml")
    {
        type("System.Security.Cryptography.Xml.SignedXml"; LtCsrSignedXml) { }
        type("System.Security.Cryptography.Xml.Reference"; LtCsrReference) { }
        type("System.Security.Cryptography.Xml.XmlDsigExcC14NTransform"; LtCsrC14NTransform) { }
    }
    assembly("netstandard")
    {
        type("System.Security.Cryptography.RSA"; LtCsrRSA) { }
        type("System.Xml.XmlDocument"; LtCsrXmlDocument) { }
    }
}

codeunit 99004 "LT CSR Clear Xml Reference"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryStep(Step: Integer; var Answer: Text)
    var
        Doc: DotNet LtCsrXmlDocument;
        Signed: DotNet LtCsrSignedXml;
        Signed2: DotNet LtCsrSignedXml;
        Ref: DotNet LtCsrReference;
        Ref2: DotNet LtCsrReference;
        Never: DotNet LtCsrReference;
        Transform: DotNet LtCsrC14NTransform;
        RsaKey: DotNet LtCsrRSA;
    begin
        Doc := Doc.XmlDocument();
        Doc.LoadXml('<Root><Data>x</Data></Root>');
        Signed := Signed.SignedXml(Doc);
        RsaKey := RsaKey.Create();
        Signed.SigningKey := RsaKey;
        case Step of
            1:
                begin
                    // The System Application sequence.
                    Ref := Ref.Reference('');
                    Transform := Transform.XmlDsigExcC14NTransform('');
                    Ref.AddTransform(Transform);
                    Answer := 'null before add=' + Format(IsNull(Ref));
                    Signed.AddReference(Ref);
                    Clear(Ref);
                    Answer += ' null after Clear=' + Format(IsNull(Ref));
                    Answer += ' references=' + Format(Signed.SignedInfo.References.Count);
                    Signed.ComputeSignature();
                    Answer += ' computed check=' + Format(Signed.CheckSignature());
                    Answer += ' signature element=' + Format(Signed.GetXml().Name);
                end;
            2:
                begin
                    // A second variable holds the same Reference.
                    Ref := Ref.Reference('#x');
                    Transform := Transform.XmlDsigExcC14NTransform();
                    Ref.AddTransform(Transform);
                    Ref2 := Ref;
                    Clear(Ref);
                    Answer := 'first null=' + Format(IsNull(Ref)) + ' second null=' + Format(IsNull(Ref2));
                    Answer += ' second uri=' + Format(Ref2.Uri);
                    Answer += ' second transforms=' + Format(Ref2.TransformChain.Count);
                end;
            3:
                begin
                    // A Reference that was never added.
                    Ref := Ref.Reference('');
                    Clear(Ref);
                    Answer := 'null after Clear=' + Format(IsNull(Ref)) + ' references=' + Format(Signed.SignedInfo.References.Count);
                    Ref := Ref.Reference('');
                    Signed.AddReference(Ref);
                    Signed.ComputeSignature();
                    Answer += ' assigned again and added, check=' + Format(Signed.CheckSignature());
                end;
            4:
                begin
                    Answer := 'null before=' + Format(IsNull(Never));
                    Clear(Never);
                    Answer += ' null after Clear=' + Format(IsNull(Never));
                end;
            5:
                begin
                    // Clear of the SignedXml variable while another variable holds the object.
                    Ref := Ref.Reference('');
                    Signed.AddReference(Ref);
                    Signed2 := Signed;
                    Clear(Signed);
                    Answer := 'first null=' + Format(IsNull(Signed)) + ' second references=' + Format(Signed2.SignedInfo.References.Count);
                    Signed2.ComputeSignature();
                    Answer += ' check=' + Format(Signed2.CheckSignature());
                end;
            6:
                begin
                    // Clear of the transform that the Reference holds, and of the key that the SignedXml holds.
                    Ref := Ref.Reference('');
                    Transform := Transform.XmlDsigExcC14NTransform('');
                    Ref.AddTransform(Transform);
                    Clear(Transform);
                    Signed.AddReference(Ref);
                    Clear(Ref);
                    Clear(RsaKey);
                    Answer := 'transform null=' + Format(IsNull(Transform)) + ' key null=' + Format(IsNull(RsaKey));
                    Signed.ComputeSignature();
                    Answer += ' check=' + Format(Signed.CheckSignature());
                end;
            7:
                begin
                    // Clear twice, and a call on the cleared variable.
                    Ref := Ref.Reference('');
                    Clear(Ref);
                    Clear(Ref);
                    Answer := 'null after two Clears=' + Format(IsNull(Ref));
                    Answer += ' uri=' + Format(Ref.Uri);
                end;
        end;
    end;

    local procedure ObserveStep(var Observer: Codeunit "Probe Observer"; Step: Integer; Name: Text)
    var
        Answer: Text;
    begin
        ClearLastError();
        if TryStep(Step, Answer) then
            Observer.Observe(Name, Answer)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure Clear_ReferenceAddedToSignedXml_SignatureStillComputes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStep(Observer, 1, 'add, Clear, ComputeSignature');
        ObserveStep(Observer, 6, 'Clear of the transform and the key too');
        Observer.Finish();
    end;

    [Test]
    procedure Clear_Reference_OtherHolders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStep(Observer, 2, 'second variable holds the Reference');
        ObserveStep(Observer, 5, 'Clear of the SignedXml variable, second variable holds it');
        Observer.Finish();
    end;

    [Test]
    procedure Clear_Reference_NeverAdded_NeverAssigned_Twice()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStep(Observer, 3, 'never added');
        ObserveStep(Observer, 4, 'never assigned');
        ObserveStep(Observer, 7, 'Clear twice, then a property read');
        Observer.Finish();
    end;
}
