// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xml-buffer
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Base Application's XML Buffer table (1235) as a temporary record; own codeunit 99670
// Probe: al-runner issue 7386 (XML Buffer.LoadFromText refused because XML Buffer Writer reads CredentialCache.DefaultNetworkCredentials).
// Facts: what the XML Buffer table holds after LoadFromText (and LoadFromStream) of a small document: one row per element, attribute and processing instruction (text is the Value of its element),
//   with Type (Element, Attribute, Processing Instruction), Name, Path, Value, Depth, parent row, Namespace. Observed on real BC; every literal asserted below is what BC produced.
// local object: none (the table is Microsoft's; a Base Application table is the only way to reach the loader the issue names)
// Results (BC 27.5, 28.5 and 29.0 identical): LoadFromText and LoadFromStream work and fill one row per element, attribute and processing
//   instruction; text that is not well-formed XML, or an empty text, raises the System.Xml error text with code DotNetInvoke:Xml.
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
        Observer.Expect('count', '3');
        Observer.Expect('rows', 'Element|Root|/Root||d1|ns=|dt=Text|parent=-;Element|Node|/Root/Node|x|d2|ns=|dt=Text|parent=Root;Attribute|Attr|/Root/Node/@Attr|1|d3|ns=|dt=Decimal|parent=Node;');
        Observer.Verify();
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
        Observer.Expect('found', 'Yes');
        Observer.Expect('name', 'Attr');
        Observer.Expect('value', '1');
        Observer.Expect('path', '/Root/Node/@Attr');
        Observer.Expect('elements', '2');
        Observer.Expect('processing instructions', '0');
        Observer.Verify();
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
        Observer.Expect('count', '9');
        Observer.Expect('rows', 'Element|Order|/Order||d1|ns=|dt=Text|parent=-;Attribute|id|/Order/@id|7|d2|ns=|dt=Decimal|parent=Order;Element|Line|/Order/Line||d2|ns=|dt=Text|parent=Order;Attribute|n|/Order/Line/@n|1|d3|ns=|dt=Decimal|parent=Line;Element|Qty|/Order/Line/Qty|2|d3|ns=|dt=Decimal|parent=Line;Element|Line|/Order/Line||d2|ns=|dt=Text|parent=Order;Attribute|n|/Order/Line/@n|2|d3|ns=|dt=Decimal|parent=Line;Element|Qty|/Order/Line/Qty|3|d3|ns=|dt=Decimal|parent=Line;Element|Empty|/Order/Empty||d2|ns=|dt=Text|parent=Order;');
        Observer.Verify();
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
        Observer.Expect('count', '7');
        Observer.Expect('rows', 'Element|Root|/a:Root||d1|ns=a|dt=Text|parent=-;Attribute|xmlns:a|/a:Root/@xmlns:a|urn:x|d2|ns=|dt=Text|parent=Root;Attribute|xmlns|/a:Root/@xmlns|urn:d|d2|ns=|dt=Text|parent=Root;Processing Instruction|pi|/a:Root/processing-instruction(''pi'')|data|d2|ns=|dt=Text|parent=Root;Element|Child|/a:Root/a:Child||d2|ns=a|dt=Text|parent=Root;Attribute|a:At|/a:Root/a:Child/@a:At|v|d3|ns=|dt=Text|parent=Child;Element|Plain|/a:Root/Plain|t & u|d2|ns=|dt=Text|parent=Root;');
        Observer.Verify();
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
        Observer.Expect('count', '2');
        Observer.Expect('rows', 'Element|Root|/Root||d1|ns=|dt=Text|parent=-;Element|A|/Root/A|  padded  |d2|ns=|dt=Text|parent=Root;');
        Observer.Verify();
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
        Observer.Expect('invalid|text', 'A call to System.Xml.XmlTextReaderImpl.Read failed with this message: The ''Open'' start tag on line 1 position 8 does not match the end tag of ''Root''. Line 1, position 15.');
        Observer.Expect('invalid|code', 'DotNetInvoke:Xml');
        Observer.Expect('empty|text', 'A call to System.Xml.XmlTextReaderImpl.Read failed with this message: Root element is missing.');
        Observer.Expect('empty|code', 'DotNetInvoke:Xml');
        Observer.Expect('count after', '2');
        Observer.Verify();
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
        Observer.Expect('after first', '1');
        Observer.Expect('after second', '2');
        Observer.Expect('rows', 'Element|One|/One||d1|ns=|dt=Text|parent=-;Element|Two|/Two||d1|ns=|dt=Text|parent=-;Element|Child|/Two/Child||d2|ns=|dt=Text|parent=Two;');
        Observer.Verify();
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
        Observer.Expect('count', '3');
        Observer.Expect('rows', 'Element|Root|/Root||d1|ns=|dt=Text|parent=-;Element|Node|/Root/Node|x|d2|ns=|dt=Text|parent=Root;Attribute|Attr|/Root/Node/@Attr|1|d3|ns=|dt=Decimal|parent=Node;');
        Observer.Verify();
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
        Observer.Expect('has children', 'Yes');
        Observer.Expect('child elements', '2');
        Observer.Expect('first child', 'Root|/Root');
        Observer.Expect('attribute count', '0');
        Observer.Verify();
    end;
}
