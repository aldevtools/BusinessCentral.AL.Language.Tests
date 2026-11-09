// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xml-buffer
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Base Application's XML Buffer table (1235) as a temporary record; own codeunit 99670
// Probe: al-runner issue 7386 (XML Buffer.LoadFromText refused because XML Buffer Writer reads CredentialCache.DefaultNetworkCredentials).
// Facts: what the XML Buffer table holds after LoadFromText (and LoadFromStream) of a small document: one row per element, attribute and processing instruction (text is the Value of its element),
//   with Type (Element, Attribute, Processing Instruction), Name, Path, Value, Depth, parent row, Namespace. Observed on real BC; every literal asserted below is what BC produced.
// local object: none (the table is Microsoft's; a Base Application table is the only way to reach the loader the issue names)
// BC versions: 27, 28, 29 (corpus CI)

codeunit 99670 "XB Load Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(var Buffer: Record "XML Buffer" temporary): Text
    var
        Parent: Record "XML Buffer" temporary;
        Result: Text;
    begin
        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                Result += Format(Buffer.Type) + '|' + Buffer.Name + '|' + Buffer.Path + '|' + Buffer.Value + '|d' + Format(Buffer.Depth) + '|ns=' + Buffer.Namespace + '|dt=' + Format(Buffer."Data Type") + '|parent=';
                Parent.Copy(Buffer, true);
                if Buffer."Parent Entry No." <> 0 then begin
                    Parent.Reset();
                    if Parent.Get(Buffer."Parent Entry No.") then
                        Result += Parent.Name
                    else
                        Result += '?';
                end else
                    Result += '-';
                Result += ';';
            until Buffer.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure XmlBuffer_LoadFromText_ElementAttributeText()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "XML Buffer" temporary;
    begin
        Buffer.LoadFromText('<Root><Node Attr="1">x</Node></Root>');
        Observer.Observe('count', Format(Buffer.Count()));
        Observer.Observe('rows', Dump(Buffer));
        Observer.Finish();
    end;

    [Test]
    procedure XmlBuffer_LoadFromText_AttributeFilter()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "XML Buffer" temporary;
    begin
        // the shape of the issue: filter on Type, FindFirst
        Buffer.LoadFromText('<Root><Node Attr="1">x</Node></Root>');
        Buffer.SetRange(Type, Buffer.Type::Attribute);
        Observer.Observe('found', Format(Buffer.FindFirst()));
        Observer.Observe('name', Buffer.Name);
        Observer.Observe('value', Buffer.Value);
        Observer.Observe('path', Buffer.Path);
        Buffer.SetRange(Type, Buffer.Type::Element);
        Observer.Observe('elements', Format(Buffer.Count()));
        Buffer.SetRange(Type, Buffer.Type::"Processing Instruction");
        Observer.Observe('processing instructions', Format(Buffer.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure XmlBuffer_LoadFromText_NestedAndRepeated()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "XML Buffer" temporary;
    begin
        Buffer.LoadFromText('<Order id="7"><Line n="1"><Qty>2</Qty></Line><Line n="2"><Qty>3</Qty></Line><Empty/></Order>');
        Observer.Observe('count', Format(Buffer.Count()));
        Observer.Observe('rows', Dump(Buffer));
        Observer.Finish();
    end;

    [Test]
    procedure XmlBuffer_LoadFromText_NamespaceCommentCData()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "XML Buffer" temporary;
    begin
        Buffer.LoadFromText('<a:Root xmlns:a="urn:x" xmlns="urn:d"><?pi data?><a:Child a:At="v"><!-- note --><![CDATA[<raw>]]></a:Child><Plain>t &amp; u</Plain></a:Root>');
        Observer.Observe('count', Format(Buffer.Count()));
        Observer.Observe('rows', Dump(Buffer));
        Observer.Finish();
    end;

    [Test]
    procedure XmlBuffer_LoadFromText_DeclarationAndWhitespace()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "XML Buffer" temporary;
    begin
        Buffer.LoadFromText('<?xml version="1.0" encoding="utf-8"?>' + '<Root>' + ' ' + '<A>  padded  </A>' + ' ' + '</Root>');
        Observer.Observe('count', Format(Buffer.Count()));
        Observer.Observe('rows', Dump(Buffer));
        Observer.Finish();
    end;

    [Test]
    procedure XmlBuffer_LoadFromText_Invalid_Raises()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "XML Buffer" temporary;
    begin
        asserterror Buffer.LoadFromText('<Root><Open></Root>');
        Observer.ObserveError('invalid');
        asserterror Buffer.LoadFromText('');
        Observer.ObserveError('empty');
        Observer.Observe('count after', Format(Buffer.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure XmlBuffer_LoadFromText_SecondLoadReplacesOrAdds()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "XML Buffer" temporary;
    begin
        Buffer.LoadFromText('<One/>');
        Observer.Observe('after first', Format(Buffer.Count()));
        Buffer.LoadFromText('<Two><Child/></Two>');
        Observer.Observe('after second', Format(Buffer.Count()));
        Observer.Observe('rows', Dump(Buffer));
        Observer.Finish();
    end;

    [Test]
    procedure XmlBuffer_LoadFromStream_ElementAttributeText()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Buffer: Record "XML Buffer" temporary;
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Node Attr="1">x</Node></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Buffer.LoadFromStream(InS);
        Observer.Observe('count', Format(Buffer.Count()));
        Observer.Observe('rows', Dump(Buffer));
        Observer.Finish();
    end;

    [Test]
    procedure XmlBuffer_LoadFromText_ThenReaders()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "XML Buffer" temporary;
        Child: Record "XML Buffer" temporary;
    begin
        Buffer.LoadFromText('<Root><Node Attr="1">x</Node><Node Attr="2">y</Node></Root>');
        Buffer.SetRange(Type, Buffer.Type::Element);
        Buffer.SetRange(Name, 'Root');
        Buffer.FindFirst();
        Observer.Observe('has children', Format(Buffer.HasChildNodes()));
        Observer.Observe('child elements', Format(Buffer.CountChildElements()));
        Buffer.FindChildElements(Child);
        Observer.Observe('first child', Child.Name + '|' + Child.Path);
        Observer.Observe('attribute count', Format(Child.CountAttributes()));
        Observer.Finish();
    end;
}
