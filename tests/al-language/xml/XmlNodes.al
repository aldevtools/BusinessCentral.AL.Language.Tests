// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlnode/xmlnode-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 73403
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 73403 "LT XmT Nodes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Load(Src: Text; var Root: XmlElement)
    var
        Doc: XmlDocument;
    begin
        XmlDocument.ReadFrom(Src, Doc);
        Doc.GetRoot(Root);
    end;

    local procedure NodeStr(N: XmlNode): Text
    var
        Txt: Text;
    begin
        N.WriteTo(Txt);
        exit(Txt);
    end;

    local procedure PT(P: XmlProcessingInstruction): Text
    var
        R: Text;
    begin
        P.GetTarget(R);
        exit(R);
    end;

    local procedure PD(P: XmlProcessingInstruction): Text
    var
        R: Text;
    begin
        P.GetData(R);
        exit(R);
    end;

    local procedure Kind(N: XmlNode): Text
    begin
        if N.IsXmlElement() then
            exit('element');
        if N.IsXmlAttribute() then
            exit('attribute');
        if N.IsXmlText() then
            exit('text');
        if N.IsXmlCData() then
            exit('cdata');
        if N.IsXmlComment() then
            exit('comment');
        if N.IsXmlProcessingInstruction() then
            exit('pi');
        if N.IsXmlDeclaration() then
            exit('declaration');
        if N.IsXmlDocument() then
            exit('document');
        if N.IsXmlDocumentType() then
            exit('doctype');
        exit('unknown');
    end;

    [Test]
    procedure Text_Create()
    var
        T: XmlText;
        Txt: Text;
    begin
        T := XmlText.Create('hello');
        Observer.Observe('value', T.Value());
        T.WriteTo(Txt);
        Observer.Observe('writeto', Txt);
        T := XmlText.Create('<&>');
        T.WriteTo(Txt);
        Observer.Observe('escaped', Txt);
        Observer.Observe('escaped_value', T.Value());
        T := XmlText.Create('');
        Observer.Observe('empty', '[' + T.Value() + ']');
        T.WriteTo(Txt);
        Observer.Observe('empty_writeto', '[' + Txt + ']');
        T.Value('new');
        Observer.Observe('set', T.Value());
        Observer.Expect('value', 'hello');
        Observer.Expect('writeto', 'hello');
        Observer.Expect('escaped', '&lt;&amp;&gt;');
        Observer.Expect('escaped_value', '<&>');
        Observer.Expect('empty', '[]');
        Observer.Expect('empty_writeto', '[]');
        Observer.Expect('set', 'new');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Whitespace_Entities()
    var
        T: XmlText;
        Txt: Text;
        Lf: Text[1];
    begin
        Lf[1] := 10;
        T := XmlText.Create('  a' + Lf + 'b  ');
        T.WriteTo(Txt);
        Observer.Observe('writeto', Txt);
        Observer.Observe('len', Format(StrLen(T.Value())));
        T := XmlText.Create('"quotes" and ''apos''');
        T.WriteTo(Txt);
        Observer.Observe('quotes', Txt);
        T := XmlText.Create(']]>');
        T.WriteTo(Txt);
        Observer.Observe('cdata_end', Txt);
        Observer.Expect('writeto', '  a\r\nb  ');
        Observer.Expect('len', '7');
        Observer.Expect('quotes', '"quotes" and ''apos''');
        Observer.Expect('cdata_end', ']]&gt;');
        Observer.Verify();
    end;

    [Test]
    procedure CData_Create()
    var
        C: XmlCData;
        Txt: Text;
    begin
        C := XmlCData.Create('<a>&</a>');
        Observer.Observe('value', C.Value());
        C.WriteTo(Txt);
        Observer.Observe('writeto', Txt);
        C := XmlCData.Create('');
        C.WriteTo(Txt);
        Observer.Observe('empty', Txt);
        C := XmlCData.Create('a]]>b');
        C.WriteTo(Txt);
        Observer.Observe('contains_end', Txt);
        Observer.Observe('contains_end_value', C.Value());
        C.Value('set');
        Observer.Observe('set', C.Value());
        Observer.Expect('value', '<a>&</a>');
        Observer.Expect('writeto', '<![CDATA[<a>&</a>]]>');
        Observer.Expect('empty', '<![CDATA[]]>');
        Observer.Expect('contains_end', '<![CDATA[a]]]]><![CDATA[>b]]>');
        Observer.Expect('contains_end_value', 'a]]>b');
        Observer.Expect('set', 'set');
        Observer.Verify();
    end;

    [Test]
    procedure Comment_Create()
    var
        C: XmlComment;
        Txt: Text;
    begin
        C := XmlComment.Create('hello');
        Observer.Observe('value', C.Value());
        C.WriteTo(Txt);
        Observer.Observe('writeto', Txt);
        C := XmlComment.Create('');
        C.WriteTo(Txt);
        Observer.Observe('empty', Txt);
        C := XmlComment.Create('a--b');
        C.WriteTo(Txt);
        Observer.Observe('double_dash', Txt);
        C := XmlComment.Create('a-');
        C.WriteTo(Txt);
        Observer.Observe('trailing_dash', Txt);
        C := XmlComment.Create('x');
        C.Value('<!-- y -->');
        C.WriteTo(Txt);
        Observer.Observe('set_value', Txt);
        Observer.Expect('value', 'hello');
        Observer.Expect('writeto', '<!--hello-->');
        Observer.Expect('empty', '<!---->');
        Observer.Expect('double_dash', '<!--a- -b-->');
        Observer.Expect('trailing_dash', '<!--a- -->');
        Observer.Expect('set_value', '<!--<!- - y - ->-->');
        Observer.Verify();
    end;

    [Test]
    procedure PI_Create()
    var
        P: XmlProcessingInstruction;
        Txt: Text;
    begin
        P := XmlProcessingInstruction.Create('target', 'data here');
        Observer.Observe('target', PT(P));
        Observer.Observe('data', PD(P));
        P.WriteTo(Txt);
        Observer.Observe('writeto', Txt);
        P := XmlProcessingInstruction.Create('target', '');
        P.WriteTo(Txt);
        Observer.Observe('nodata', Txt);
        P.SetData('later');
        Observer.Observe('setdata', PD(P));
        P.SetTarget('t2');
        Observer.Observe('settarget', PT(P));
        asserterror P := XmlProcessingInstruction.Create('', 'd');
        Observer.ObserveError('empty_target');
        asserterror P := XmlProcessingInstruction.Create('xml', 'd');
        Observer.ObserveError('xml_target');
        asserterror P := XmlProcessingInstruction.Create('a b', 'd');
        Observer.ObserveError('space_target');
        P := XmlProcessingInstruction.Create('t', 'a?>b');
        Observer.Observe('bad_data', 'no error');
        Observer.Expect('target', 'target');
        Observer.Expect('data', 'data here');
        Observer.Expect('writeto', '<?target data here?>');
        Observer.Expect('nodata', '<?target?>');
        Observer.Expect('setdata', 'later');
        Observer.Expect('settarget', 't2');
        Observer.Expect('empty_target|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty_target|code', 'Argument');
        Observer.Expect('xml_target|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('xml_target|code', 'Argument');
        Observer.Expect('space_target|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('space_target|code', 'Xml:Xml');
        Observer.Expect('bad_data', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Node_Kinds_FromRead()
    var
        E: XmlElement;
        L: XmlNodeList;
        N: XmlNode;
        Doc: XmlDocument;
        Kinds: Text;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0"?><!--top--><?pi d?><a x="1">t<![CDATA[c]]><!--m--><?p2 q?><b/></a>', Doc);
        Doc.GetRoot(E);
        foreach N in Doc.GetChildNodes() do
            Kinds += Kind(N) + ',';
        Observer.Observe('doc_children', Kinds);
        Kinds := '';
        foreach N in E.GetChildNodes() do
            Kinds += Kind(N) + ',';
        Observer.Observe('root_children', Kinds);
        Observer.Observe('root_kind', Kind(E.AsXmlNode()));
        Observer.Observe('doc_kind', Kind(Doc.AsXmlNode()));
        Observer.Expect('doc_children', 'comment,pi,element,');
        Observer.Expect('root_children', 'text,cdata,comment,pi,element,');
        Observer.Expect('root_kind', 'element');
        Observer.Expect('doc_kind', 'document');
        Observer.Verify();
    end;

    [Test]
    procedure Node_AdjacentText_Merge()
    var
        E: XmlElement;
        L: XmlNodeList;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlText.Create('one'));
        E.Add(XmlText.Create('two'));
        L := E.GetChildNodes();
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('inner', E.InnerText());
        E.Add(XmlCData.Create('three'));
        L := E.GetChildNodes();
        Observer.Observe('count_cdata', Format(L.Count()));
        Observer.Expect('count', '2');
        Observer.Expect('inner', 'onetwo');
        Observer.Expect('count_cdata', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Node_AsConversions_Errors()
    var
        E: XmlElement;
        N: XmlNode;
        Txt: Text;
    begin
        E := XmlElement.Create('a');
        N := E.AsXmlNode();
        Observer.Observe('is_element', Format(N.IsXmlElement()));
        Observer.Observe('is_text', Format(N.IsXmlText()));
        Observer.Observe('is_attr', Format(N.IsXmlAttribute()));
        Observer.Observe('is_doc', Format(N.IsXmlDocument()));
        asserterror Txt := Format(N.AsXmlText().Value());
        Observer.ObserveError('as_text');
        asserterror Txt := Format(N.AsXmlAttribute().Value());
        Observer.ObserveError('as_attr');
        asserterror N.AsXmlDocument().WriteTo(Txt);
        Observer.ObserveError('as_doc');
        asserterror Txt := Format(N.AsXmlComment().Value());
        Observer.ObserveError('as_comment');
        asserterror Txt := Format(N.AsXmlCData().Value());
        Observer.ObserveError('as_cdata');
        asserterror N.AsXmlProcessingInstruction().GetTarget(Txt);
        Observer.ObserveError('as_pi');
        asserterror Txt := Format(N.AsXmlDeclaration().Version());
        Observer.ObserveError('as_decl');
        Observer.Expect('is_element', 'Yes');
        Observer.Expect('is_text', 'No');
        Observer.Expect('is_attr', 'No');
        Observer.Expect('is_doc', 'No');
        Observer.Expect('as_text|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlElement to Microsoft.Dynamics.Nav.Runtime.NavXmlText.');
        Observer.Expect('as_text|code', 'Conversion');
        Observer.Expect('as_attr|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlElement to Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute.');
        Observer.Expect('as_attr|code', 'Conversion');
        Observer.Expect('as_doc|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlElement to Microsoft.Dynamics.Nav.Runtime.NavXmlDocument.');
        Observer.Expect('as_doc|code', 'Conversion');
        Observer.Expect('as_comment|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlElement to Microsoft.Dynamics.Nav.Runtime.NavXmlComment.');
        Observer.Expect('as_comment|code', 'Conversion');
        Observer.Expect('as_cdata|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlElement to Microsoft.Dynamics.Nav.Runtime.NavXmlCData.');
        Observer.Expect('as_cdata|code', 'Conversion');
        Observer.Expect('as_pi|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlElement to Microsoft.Dynamics.Nav.Runtime.NavXmlProcessingInstruction.');
        Observer.Expect('as_pi|code', 'Conversion');
        Observer.Expect('as_decl|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlElement to Microsoft.Dynamics.Nav.Runtime.NavXmlDeclaration.');
        Observer.Expect('as_decl|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure Node_Uninitialized()
    var
        N: XmlNode;
        Txt: Text;
        Par: XmlElement;
    begin
        Observer.Observe('is_element', Format(N.IsXmlElement()));
        Observer.Observe('is_text', Format(N.IsXmlText()));
        Observer.Observe('is_doc', Format(N.IsXmlDocument()));
        asserterror N.WriteTo(Txt);
        Observer.ObserveError('writeto');
        asserterror Observer.Observe('parent', Format(N.GetParent(Par)));
        Observer.ObserveError('parent');
        Observer.Expect('is_element', 'No');
        Observer.Expect('is_text', 'No');
        Observer.Expect('is_doc', 'No');
        Observer.Expect('writeto|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('writeto|code', 'NotInitialized');
        Observer.Expect('parent|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('parent|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Node_Navigation()
    var
        E: XmlElement;
        N: XmlNode;
        Par: XmlElement;
        Doc: XmlDocument;
        L: XmlNodeList;
        C: XmlNode;
    begin
        Load('<a><b>x</b></a>', E);
        L := E.GetChildNodes();
        L.Get(1, N);
        Observer.Observe('child_kind', Kind(N));
        Observer.Observe('parent', Format(N.GetParent(Par)));
        Observer.Observe('parent_name', Par.Name());
        Observer.Observe('doc', Format(N.GetDocument(Doc)));
        Observer.Observe('child_out', NodeStr(N));
        L := N.AsXmlElement().GetChildNodes();
        L.Get(1, C);
        Observer.Observe('text_kind', Kind(C));
        Observer.Observe('text_out', NodeStr(C));
        Observer.Observe('text_parent', Format(C.GetParent(Par)));
        Observer.Observe('text_parent_name', Par.Name());
        Observer.Expect('child_kind', 'element');
        Observer.Expect('parent', 'Yes');
        Observer.Expect('parent_name', 'a');
        Observer.Expect('doc', 'Yes');
        Observer.Expect('child_out', '<b>x</b>');
        Observer.Expect('text_kind', 'text');
        Observer.Expect('text_out', 'x');
        Observer.Expect('text_parent', 'Yes');
        Observer.Expect('text_parent_name', 'b');
        Observer.Verify();
    end;

    [Test]
    procedure Node_AddAfterBeforeRemove()
    var
        E: XmlElement;
        L: XmlNodeList;
        N: XmlNode;
        Txt: Text;
    begin
        Load('<a><b/>t<c/></a>', E);
        L := E.GetChildNodes();
        L.Get(2, N);
        N.AddAfterSelf(XmlComment.Create('after'));
        E.WriteTo(Txt);
        Observer.Observe('after', Txt);
        N.AddBeforeSelf(XmlComment.Create('before'));
        E.WriteTo(Txt);
        Observer.Observe('before', Txt);
        N.ReplaceWith(XmlText.Create('R'));
        E.WriteTo(Txt);
        Observer.Observe('replace', Txt);
        L := E.GetChildNodes();
        L.Get(1, N);
        N.Remove();
        E.WriteTo(Txt);
        Observer.Observe('remove', Txt);
        Observer.Expect('after', '<a>\r\n  <b />t<!--after--><c /></a>');
        Observer.Expect('before', '<a>\r\n  <b />\r\n  <!--before-->t<!--after--><c /></a>');
        Observer.Expect('replace', '<a>\r\n  <b />\r\n  <!--before-->R<!--after--><c /></a>');
        Observer.Expect('remove', '<a>\r\n  <!--before-->R<!--after--><c /></a>');
        Observer.Verify();
    end;

    [Test]
    procedure Node_Compare_Identity()
    var
        E: XmlElement;
        N1: XmlNode;
        N2: XmlNode;
        L: XmlNodeList;
    begin
        Load('<a><b/><b/></a>', E);
        L := E.GetChildElements('b');
        L.Get(1, N1);
        L.Get(2, N2);
        Observer.Observe('same_node_twice', Format(NodeStr(N1) = NodeStr(N2)));
        L.Get(1, N2);
        N2.AsXmlElement().SetAttribute('k', 'v');
        Observer.Observe('shared_change', NodeStr(N1));
        Observer.Expect('same_node_twice', 'Yes');
        Observer.Expect('shared_change', '<b k="v" />');
        Observer.Verify();
    end;

    [Test]
    procedure NodeList_Basics()
    var
        E: XmlElement;
        L: XmlNodeList;
        N: XmlNode;
    begin
        Load('<a><b>1</b><b>2</b><b>3</b></a>', E);
        L := E.GetChildElements('b');
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('get1', Format(L.Get(1, N)));
        Observer.Observe('get1_text', N.AsXmlElement().InnerText());
        Observer.Observe('get3', Format(L.Get(3, N)));
        Observer.Observe('get3_text', N.AsXmlElement().InnerText());
        Observer.Observe('get0', Format(L.Get(0, N)));
        Observer.Observe('get4', Format(L.Get(4, N)));
        Observer.Observe('getneg', Format(L.Get(-1, N)));
        Observer.Expect('count', '3');
        Observer.Expect('get1', 'Yes');
        Observer.Expect('get1_text', '1');
        Observer.Expect('get3', 'Yes');
        Observer.Expect('get3_text', '3');
        Observer.Expect('get0', 'No');
        Observer.Expect('get4', 'No');
        Observer.Expect('getneg', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure NodeList_Empty()
    var
        E: XmlElement;
        L: XmlNodeList;
        N: XmlNode;
    begin
        Load('<a/>', E);
        L := E.GetChildNodes();
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('get1', Format(L.Get(1, N)));
        L := E.GetChildElements();
        Observer.Observe('elem_count', Format(L.Count()));
        L := E.GetDescendantNodes();
        Observer.Observe('desc_count', Format(L.Count()));
        Observer.Expect('count', '0');
        Observer.Expect('get1', 'No');
        Observer.Expect('elem_count', '0');
        Observer.Expect('desc_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NodeList_Foreach_Order()
    var
        E: XmlElement;
        N: XmlNode;
        Acc: Text;
    begin
        Load('<a><b>1</b><c>2</c><b>3</b></a>', E);
        foreach N in E.GetChildElements() do
            Acc += N.AsXmlElement().Name() + N.AsXmlElement().InnerText() + ',';
        Observer.Observe('child_order', Acc);
        Acc := '';
        foreach N in E.GetDescendantNodes() do
            Acc += Kind(N) + ',';
        Observer.Observe('desc_kinds', Acc);
        Observer.Expect('child_order', 'b1,c2,b3,');
        Observer.Expect('desc_kinds', 'element,text,element,text,element,text,');
        Observer.Verify();
    end;

    [Test]
    procedure NodeList_Snapshot_Or_Live()
    var
        E: XmlElement;
        L: XmlNodeList;
    begin
        Load('<a><b/></a>', E);
        L := E.GetChildElements();
        E.Add(XmlElement.Create('c'));
        Observer.Observe('count_after_add', Format(L.Count()));
        L := E.GetChildNodes();
        E.Add(XmlElement.Create('d'));
        Observer.Observe('nodes_count_after_add', Format(L.Count()));
        Observer.Expect('count_after_add', '1');
        Observer.Expect('nodes_count_after_add', '2');
        Observer.Verify();
    end;

    [Test]
    procedure NodeList_Remove_During_Foreach()
    var
        E: XmlElement;
        N: XmlNode;
        Acc: Text;
    begin
        Load('<a><b/><c/><d/></a>', E);
        foreach N in E.GetChildElements() do begin
            Acc += N.AsXmlElement().Name();
            N.Remove();
        end;
        Observer.Observe('visited', Acc);
        Observer.Observe('left', Format(E.GetChildNodes().Count()));
        Observer.Expect('visited', 'bcd');
        Observer.Expect('left', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Document_Navigation()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Docu: XmlDocument;
        N: XmlNode;
        Par: XmlElement;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a><b/></a>', Doc);
        Doc.GetRoot(Root);
        Observer.Observe('root_parent', Format(Root.GetParent(Par)));
        Observer.Observe('root_doc', Format(Root.GetDocument(Docu)));
        Docu.WriteTo(Txt);
        Observer.Observe('root_doc_out', Txt);
        Observer.Observe('doc_getparent_node', 'n/a');
        N := Doc.AsXmlNode();
        Observer.Observe('doc_as_node_kind', Kind(N));
        Observer.Observe('doc_as_node_parent', Format(N.GetParent(Par)));
        Observer.Observe('doc_node_out', NodeStr(N));
        Observer.Expect('root_parent', 'No');
        Observer.Expect('root_doc', 'Yes');
        Observer.Expect('root_doc_out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b />\r\n</a>');
        Observer.Expect('doc_getparent_node', 'n/a');
        Observer.Expect('doc_as_node_kind', 'document');
        Observer.Expect('doc_as_node_parent', 'No');
        Observer.Expect('doc_node_out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Document_Copy_Semantics()
    var
        D1: XmlDocument;
        D2: XmlDocument;
        R: XmlElement;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a/>', D1);
        D2 := D1;
        D2.GetRoot(R);
        R.SetAttribute('k', 'v');
        D1.WriteTo(Txt);
        Observer.Observe('d1_after_d2_change', Txt);
        D1.GetRoot(R);
        R.Add(XmlText.Create('t'));
        D2.WriteTo(Txt);
        Observer.Observe('d2_after_d1_change', Txt);
        Observer.Expect('d1_after_d2_change', '<?xml version="1.0" encoding="utf-16"?>\r\n<a k="v" />');
        Observer.Expect('d2_after_d1_change', '<?xml version="1.0" encoding="utf-16"?>\r\n<a k="v">t</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Element_Move_Between_Documents()
    var
        D1: XmlDocument;
        D2: XmlDocument;
        R1: XmlElement;
        R2: XmlElement;
        N: XmlNode;
        L: XmlNodeList;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a><x>1</x></a>', D1);
        XmlDocument.ReadFrom('<b/>', D2);
        D1.GetRoot(R1);
        D2.GetRoot(R2);
        L := R1.GetChildElements('x');
        L.Get(1, N);
        R2.Add(N);
        D1.WriteTo(Txt);
        Observer.Observe('d1', Txt);
        D2.WriteTo(Txt);
        Observer.Observe('d2', Txt);
        Observer.Expect('d1', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <x>1</x>\r\n</a>');
        Observer.Expect('d2', '<?xml version="1.0" encoding="utf-16"?>\r\n<b>\r\n  <x>1</x>\r\n</b>');
        Observer.Verify();
    end;

    [Test]
    procedure Element_Copy_Via_Reparse()
    var
        D1: XmlDocument;
        R1: XmlElement;
        R2: XmlElement;
        Txt: Text;
        D2: XmlDocument;
    begin
        XmlDocument.ReadFrom('<a><x>1</x></a>', D1);
        D1.GetRoot(R1);
        R1.WriteTo(Txt);
        XmlDocument.ReadFrom(Txt, D2);
        D2.GetRoot(R2);
        R2.Add(XmlElement.Create('y'));
        R1.WriteTo(Txt);
        Observer.Observe('orig', Txt);
        R2.WriteTo(Txt);
        Observer.Observe('copy', Txt);
        Observer.Expect('orig', '<a>\r\n  <x>1</x>\r\n</a>');
        Observer.Expect('copy', '<a>\r\n  <x>1</x>\r\n<y /></a>');
        Observer.Verify();
    end;

    // Writer TP (NP lane, 2026-10-28): Clear of an XmlNodeList variable, then Count, Get, foreach and reuse.
    [TryFunction]
    local procedure TpTryCount(L: XmlNodeList; var C: Integer)
    begin
        C := L.Count();
    end;

    local procedure TpCount(L: XmlNodeList): Text
    var
        C: Integer;
    begin
        if TpTryCount(L, C) then
            exit(Format(C));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TpTryForeach(L: XmlNodeList; var Acc: Text)
    var
        N: XmlNode;
    begin
        foreach N in L do
            Acc += N.AsXmlElement().InnerText() + ',';
    end;

    [Test]
    procedure TP_NodeList_Clear()
    var
        Doc: XmlDocument;
        L: XmlNodeList;
        Copy: XmlNodeList;
        Fresh: XmlNodeList;
        N: XmlNode;
        Acc: Text;
    begin
        XmlDocument.ReadFrom('<a><b>1</b><b>2</b><c>3</c></a>', Doc);
        Observer.Observe('fresh count', TpCount(Fresh));
        Clear(Fresh);
        Observer.Observe('fresh cleared count', TpCount(Fresh));
        Doc.SelectNodes('//b', L);
        Copy := L;
        Observer.Observe('count', TpCount(L));
        Clear(L);
        Observer.Observe('cleared count', TpCount(L));
        Observer.Observe('copy count', TpCount(Copy));
        ClearLastError();
        Observer.Observe('cleared get1', Format(L.Get(1, N)));
        Observer.Observe('cleared foreach', Format(TpTryForeach(L, Acc)) + ' ' + Acc + ' ' + GetLastErrorText());
        ClearLastError();
        Observer.Observe('select again', Format(Doc.SelectNodes('//c', L)));
        Observer.Observe('reused count', TpCount(L));
        Observer.Observe('reused get1', Format(L.Get(1, N)) + ' ' + N.AsXmlElement().InnerText());
        Observer.Observe('select none', Format(Doc.SelectNodes('//d', L)));
        Observer.Observe('none count', TpCount(L));
        Observer.Finish();
    end;
}
