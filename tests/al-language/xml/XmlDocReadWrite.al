// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 73400
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 73400 "LT XmT Doc ReadWrite"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure NL(): Text
    var
        Lf: Text[1];
    begin
        Lf[1] := 10;
        exit(Lf);
    end;

    local procedure Out(Doc: XmlDocument): Text
    var
        Txt: Text;
    begin
        Doc.WriteTo(Txt);
        exit(Txt);
    end;

    [Test]
    procedure ReadFrom_Simple()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Txt: Text;
    begin
        Observer.Observe('ok', Format(XmlDocument.ReadFrom('<a><b>x</b></a>', Doc)));
        Observer.Observe('root', Format(Doc.GetRoot(Root)));
        Observer.Observe('rootname', Root.Name());
        Doc.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('root', 'Yes');
        Observer.Expect('rootname', 'a');
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b>x</b>\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_WithDeclaration()
    var
        Doc: XmlDocument;
        Decl: XmlDeclaration;
        Txt: Text;
    begin
        Observer.Observe('ok', Format(XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-8"?><a/>', Doc)));
        Observer.Observe('hasdecl', Format(Doc.GetDeclaration(Decl)));
        Observer.Observe('version', Decl.Version());
        Observer.Observe('encoding', Decl.Encoding());
        Observer.Observe('standalone', Decl.Standalone());
        Doc.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('hasdecl', 'Yes');
        Observer.Expect('version', '1.0');
        Observer.Expect('encoding', 'utf-8');
        Observer.Expect('standalone', '');
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-8"?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_NoDeclaration()
    var
        Doc: XmlDocument;
        Decl: XmlDeclaration;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a/>', Doc);
        Observer.Observe('hasdecl', Format(Doc.GetDeclaration(Decl)));
        Doc.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Observer.Expect('hasdecl', 'No');
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_Invalid()
    var
        Doc: XmlDocument;
    begin
        Observer.Observe('empty', Format(XmlDocument.ReadFrom('', Doc)));
        Observer.Observe('empty_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('notxml', Format(XmlDocument.ReadFrom('hello', Doc)));
        Observer.Observe('notxml_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('unclosed', Format(XmlDocument.ReadFrom('<a><b></a>', Doc)));
        Observer.Observe('unclosed_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('noend', Format(XmlDocument.ReadFrom('<a>', Doc)));
        Observer.Observe('noend_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('two_roots', Format(XmlDocument.ReadFrom('<a/><b/>', Doc)));
        Observer.Observe('two_roots_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('badattr', Format(XmlDocument.ReadFrom('<a x=1/>', Doc)));
        Observer.Observe('badattr_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('dupattr', Format(XmlDocument.ReadFrom('<a x="1" x="2"/>', Doc)));
        Observer.Observe('dupattr_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('badentity', Format(XmlDocument.ReadFrom('<a>&foo;</a>', Doc)));
        Observer.Observe('badentity_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('lt_in_text', Format(XmlDocument.ReadFrom('<a>1 < 2</a>', Doc)));
        Observer.Observe('lt_in_text_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('badprefix', Format(XmlDocument.ReadFrom('<p:a/>', Doc)));
        Observer.Observe('badprefix_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('badname', Format(XmlDocument.ReadFrom('<1a/>', Doc)));
        Observer.Observe('badname_err', GetLastErrorText());
        ClearLastError();
        Observer.Expect('empty', 'No');
        Observer.Expect('empty_err', 'The following exception was encountered when processing XML data: ''Root element is missing.'' at line 0 and position 0.');
        Observer.Expect('notxml', 'No');
        Observer.Expect('notxml_err', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 1.'' at line 1 and position 1.');
        Observer.Expect('unclosed', 'No');
        Observer.Expect('unclosed_err', 'The following exception was encountered when processing XML data: ''The ''b'' start tag on line 1 position 5 does not match the end tag of ''a''. Line 1, position 9.'' at line 1 and position 9.');
        Observer.Expect('noend', 'No');
        Observer.Expect('noend_err', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 1.'' at line 1 and position 1.');
        Observer.Expect('two_roots', 'No');
        Observer.Expect('two_roots_err', 'The following exception was encountered when processing XML data: ''There are multiple root elements. Line 1, position 6.'' at line 1 and position 6.');
        Observer.Expect('badattr', 'No');
        Observer.Expect('badattr_err', 'The following exception was encountered when processing XML data: ''''1'' is an unexpected token. The expected token is ''"'' or ''''''. Line 1, position 6.'' at line 1 and position 6.');
        Observer.Expect('dupattr', 'No');
        Observer.Expect('dupattr_err', 'The following exception was encountered when processing XML data: ''''x'' is a duplicate attribute name. Line 1, position 10.'' at line 1 and position 10.');
        Observer.Expect('badentity', 'No');
        Observer.Expect('badentity_err', 'The following exception was encountered when processing XML data: ''Reference to undeclared entity ''foo''. Line 1, position 5.'' at line 1 and position 5.');
        Observer.Expect('lt_in_text', 'No');
        Observer.Expect('lt_in_text_err', 'The following exception was encountered when processing XML data: ''Name cannot begin with the '' '' character, hexadecimal value 0x20. Line 1, position 7.'' at line 1 and position 7.');
        Observer.Expect('badprefix', 'No');
        Observer.Expect('badprefix_err', 'The following exception was encountered when processing XML data: ''''p'' is an undeclared prefix. Line 1, position 2.'' at line 1 and position 2.');
        Observer.Expect('badname', 'No');
        Observer.Expect('badname_err', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''1'' character, hexadecimal value 0x31. Line 1, position 2.'' at line 1 and position 2.');
        Observer.Verify();
    end;





    [Test]
    procedure ReadFrom_Invalid_Leading()
    var
        Doc: XmlDocument;
    begin
        Observer.Observe('leading_space_decl', Format(XmlDocument.ReadFrom(' <?xml version="1.0"?><a/>', Doc)));
        Observer.Observe('leading_space_decl_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('bad_version', Format(XmlDocument.ReadFrom('<?xml version="9.9"?><a/>', Doc)));
        Observer.Observe('bad_version_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('bad_encoding', Format(XmlDocument.ReadFrom('<?xml version="1.0" encoding="nope"?><a/>', Doc)));
        Observer.Observe('bad_encoding_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('text_after_root', Format(XmlDocument.ReadFrom('<a/>x', Doc)));
        Observer.Observe('text_after_root_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('comment_only', Format(XmlDocument.ReadFrom('<!-- c -->', Doc)));
        Observer.Observe('comment_only_err', GetLastErrorText());
        ClearLastError();
        Observer.Observe('dtd', Format(XmlDocument.ReadFrom('<!DOCTYPE a><a/>', Doc)));
        Observer.Observe('dtd_err', GetLastErrorText());
        ClearLastError();
        Observer.Expect('leading_space_decl', 'No');
        Observer.Expect('leading_space_decl_err', 'The following exception was encountered when processing XML data: ''Unexpected XML declaration. The XML declaration must be the first node in the document, and no whitespace characters are allowed to appear before it. Line 1, position 4.'' at line 1 and position 4.');
        Observer.Expect('bad_version', 'No');
        Observer.Expect('bad_version_err', 'The following exception was encountered when processing XML data: ''Version number ''9.9'' is invalid. Line 1, position 16.'' at line 1 and position 16.');
        Observer.Expect('bad_encoding', 'Yes');
        Observer.Expect('bad_encoding_err', '');
        Observer.Expect('text_after_root', 'No');
        Observer.Expect('text_after_root_err', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 5.'' at line 1 and position 5.');
        Observer.Expect('comment_only', 'No');
        Observer.Expect('comment_only_err', 'The following exception was encountered when processing XML data: ''Root element is missing.'' at line 0 and position 0.');
        Observer.Expect('dtd', 'Yes');
        Observer.Expect('dtd_err', '');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_Whitespace_Default()
    var
        Doc: XmlDocument;
    begin
        XmlDocument.ReadFrom('<a>' + NL() + '  <b/>' + NL() + '</a>', Doc);
        Observer.Observe('out', Out(Doc));
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_Whitespace_Options()
    var
        Doc: XmlDocument;
        Opt: XmlReadOptions;
        Root: XmlElement;
        Nodes: XmlNodeList;
        Src: Text;
    begin
        Src := '<a>' + NL() + '  <b/>' + NL() + '</a>';
        Observer.Observe('default_preserve', Format(Opt.PreserveWhitespace()));
        Opt.PreserveWhitespace(true);
        Observer.Observe('set_preserve', Format(Opt.PreserveWhitespace()));
        XmlDocument.ReadFrom(Src, Opt, Doc);
        Doc.GetRoot(Root);
        Nodes := Root.GetChildNodes();
        Observer.Observe('preserve_children', Format(Nodes.Count()));
        Observer.Observe('preserve_out', Out(Doc));
        Opt.PreserveWhitespace(false);
        XmlDocument.ReadFrom(Src, Opt, Doc);
        Doc.GetRoot(Root);
        Nodes := Root.GetChildNodes();
        Observer.Observe('nopreserve_children', Format(Nodes.Count()));
        Observer.Observe('nopreserve_out', Out(Doc));
        Observer.Expect('default_preserve', 'No');
        Observer.Expect('set_preserve', 'Yes');
        Observer.Expect('preserve_children', '3');
        Observer.Expect('preserve_out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b />\r\n</a>');
        Observer.Expect('nopreserve_children', '3');
        Observer.Expect('nopreserve_out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_Whitespace_TextNode()
    var
        Doc: XmlDocument;
        Opt: XmlReadOptions;
        Root: XmlElement;
    begin
        XmlDocument.ReadFrom('<a>  x  </a>', Doc);
        Doc.GetRoot(Root);
        Observer.Observe('default_inner', '[' + Root.InnerText() + ']');
        Opt.PreserveWhitespace(false);
        XmlDocument.ReadFrom('<a>  x  </a>', Opt, Doc);
        Doc.GetRoot(Root);
        Observer.Observe('nopreserve_inner', '[' + Root.InnerText() + ']');
        XmlDocument.ReadFrom('<a>   </a>', Doc);
        Doc.GetRoot(Root);
        Observer.Observe('blank_default', '[' + Root.InnerText() + ']');
        Opt.PreserveWhitespace(true);
        XmlDocument.ReadFrom('<a>   </a>', Opt, Doc);
        Doc.GetRoot(Root);
        Observer.Observe('blank_preserve', '[' + Root.InnerText() + ']');
        XmlDocument.ReadFrom('<a xml:space="preserve">  <b/>  </a>', Doc);
        Observer.Observe('xmlspace', Out(Doc));
        Observer.Expect('default_inner', '[  x  ]');
        Observer.Expect('nopreserve_inner', '[  x  ]');
        Observer.Expect('blank_default', '[   ]');
        Observer.Expect('blank_preserve', '[   ]');
        Observer.Expect('xmlspace', '<?xml version="1.0" encoding="utf-16"?>\r\n<a xml:space="preserve">  <b />  </a>');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_InStream()
    var
        Doc: XmlDocument;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Txt: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('<a><b>1</b></a>');
        TempBlob.CreateInStream(InS);
        Observer.Observe('ok', Format(XmlDocument.ReadFrom(InS, Doc)));
        Doc.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b>1</b>\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_InStream_Options()
    var
        Doc: XmlDocument;
        Opt: XmlReadOptions;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('<a>' + NL() + ' <b/></a>');
        Opt.PreserveWhitespace(true);
        TempBlob.CreateInStream(InS);
        Observer.Observe('ok', Format(XmlDocument.ReadFrom(InS, Opt, Doc)));
        Observer.Observe('out', Out(Doc));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n <b /></a>');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_InStream_Invalid()
    var
        Doc: XmlDocument;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('<a><b></a>');
        TempBlob.CreateInStream(InS);
        Observer.Observe('ok', Format(XmlDocument.ReadFrom(InS, Doc)));
        Observer.Observe('err', GetLastErrorText());
        ClearLastError();
        TempBlob.CreateInStream(InS);
        Observer.Expect('ok', 'No');
        Observer.Expect('err', 'The following exception was encountered when processing XML data: ''The ''b'' start tag on line 1 position 5 does not match the end tag of ''a''. Line 1, position 9.'' at line 1 and position 9.');
        Observer.Verify();
    end;

    // Issue 6049: the stream overload with options, PreserveWhitespace true and false, on a document with whitespace-only text nodes.
    [Test]
    procedure ReadFrom_InStream_Options_WhitespaceNodes()
    var
        Doc: XmlDocument;
        Opt: XmlReadOptions;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Root: XmlElement;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('<a>' + NL() + '  <b/>' + NL() + '</a>');
        Opt.PreserveWhitespace(true);
        TempBlob.CreateInStream(InS);
        Observer.Observe('ok_true', Format(XmlDocument.ReadFrom(InS, Opt, Doc)));
        Doc.GetRoot(Root);
        Observer.Observe('children_true', Format(Root.GetChildNodes().Count()));
        Observer.Observe('out_true', Out(Doc));
        Opt.PreserveWhitespace(false);
        TempBlob.CreateInStream(InS);
        Observer.Observe('ok_false', Format(XmlDocument.ReadFrom(InS, Opt, Doc)));
        Doc.GetRoot(Root);
        Observer.Observe('children_false', Format(Root.GetChildNodes().Count()));
        Observer.Observe('out_false', Out(Doc));
        TempBlob.CreateInStream(InS);
        Observer.Observe('ok_none', Format(XmlDocument.ReadFrom(InS, Doc)));
        Doc.GetRoot(Root);
        Observer.Observe('children_none', Format(Root.GetChildNodes().Count()));
        Observer.Observe('out_none', Out(Doc));
        Observer.Expect('ok_true', 'X');
        Observer.Expect('children_true', 'X');
        Observer.Expect('out_true', 'X');
        Observer.Expect('ok_false', 'X');
        Observer.Expect('children_false', 'X');
        Observer.Expect('out_false', 'X');
        Observer.Expect('ok_none', 'X');
        Observer.Expect('children_none', 'X');
        Observer.Expect('out_none', 'X');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_InStream_Options_Invalid()
    var
        Doc: XmlDocument;
        Opt: XmlReadOptions;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('<a><b></a>');
        Opt.PreserveWhitespace(true);
        TempBlob.CreateInStream(InS);
        Observer.Observe('ok', Format(XmlDocument.ReadFrom(InS, Opt, Doc)));
        Observer.Observe('err', GetLastErrorText());
        ClearLastError();
        Observer.Expect('ok', 'X');
        Observer.Expect('err', 'X');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_InStream_Empty()
    var
        Doc: XmlDocument;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        TempBlob.CreateInStream(InS);
        Observer.Observe('ok', Format(XmlDocument.ReadFrom(InS, Doc)));
        Observer.Observe('err', GetLastErrorText());
        ClearLastError();
        Observer.Expect('ok', 'No');
        Observer.Expect('err', 'The following exception was encountered when processing XML data: ''Root element is missing.'' at line 0 and position 0.');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_RoundTrip()
    var
        Doc: XmlDocument;
        Doc2: XmlDocument;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a x="1"><b>t</b></a>', Doc);
        TempBlob.CreateOutStream(OutS);
        Doc.WriteTo(OutS);
        TempBlob.CreateInStream(InS);
        InS.ReadText(Txt);
        Observer.Observe('text', Txt);
        TempBlob.CreateInStream(InS);
        Observer.Observe('reread', Format(XmlDocument.ReadFrom(InS, Doc2)));
        Observer.Observe('reread_out', Out(Doc2));
        Observer.Expect('text', 'Ù‹<?xml version="1.0" encoding="utf-8"?>');
        Observer.Expect('reread', 'Yes');
        Observer.Expect('reread_out', '<?xml version="1.0" encoding="utf-8"?>\r\n\r\n<a x="1">\r\n  <b>t</b>\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_Unicode()
    var
        Doc: XmlDocument;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a>äöü€</a>', Doc);
        TempBlob.CreateOutStream(OutS);
        Doc.WriteTo(OutS);
        Observer.Observe('size', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        InS.ReadText(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('size', '59');
        Observer.Expect('text', 'Ù‹<?xml version="1.0" encoding="utf-8"?>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_Options()
    var
        Doc: XmlDocument;
        Opt: XmlWriteOptions;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a><b>1</b><c/></a>', Doc);
        Observer.Observe('default_prefix_indent', Format(Opt.PreserveWhitespace()));
        Doc.WriteTo(Txt);
        Observer.Observe('default', Txt);
        Opt.PreserveWhitespace(true);
        Observer.Observe('set', Format(Opt.PreserveWhitespace()));
        Doc.WriteTo(Opt, Txt);
        Observer.Observe('preserve_true', Txt);
        Opt.PreserveWhitespace(false);
        Doc.WriteTo(Opt, Txt);
        Observer.Observe('preserve_false', Txt);
        Observer.Expect('default_prefix_indent', 'No');
        Observer.Expect('default', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b>1</b>\r\n  <c />\r\n</a>');
        Observer.Expect('set', 'Yes');
        Observer.Expect('preserve_true', '<?xml version="1.0" encoding="utf-16"?><a><b>1</b><c /></a>');
        Observer.Expect('preserve_false', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b>1</b>\r\n  <c />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_Options_Whitespace()
    var
        Doc: XmlDocument;
        ROpt: XmlReadOptions;
        Opt: XmlWriteOptions;
        Txt: Text;
    begin
        ROpt.PreserveWhitespace(true);
        XmlDocument.ReadFrom('<a>' + NL() + '  <b/>' + NL() + '</a>', ROpt, Doc);
        Opt.PreserveWhitespace(true);
        Doc.WriteTo(Opt, Txt);
        Observer.Observe('preserve_true', Txt);
        Opt.PreserveWhitespace(false);
        Doc.WriteTo(Opt, Txt);
        Observer.Observe('preserve_false', Txt);
        Doc.WriteTo(Txt);
        Observer.Observe('plain', Txt);
        Observer.Expect('preserve_true', '<?xml version="1.0" encoding="utf-16"?><a>\r\n  <b />\r\n</a>');
        Observer.Expect('preserve_false', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b />\r\n</a>');
        Observer.Expect('plain', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_Options()
    var
        Doc: XmlDocument;
        Opt: XmlWriteOptions;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a><b/></a>', Doc);
        Opt.PreserveWhitespace(true);
        TempBlob.CreateOutStream(OutS);
        Doc.WriteTo(Opt, OutS);
        TempBlob.CreateInStream(InS);
        InS.ReadText(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('text', 'Ù‹<?xml version="1.0" encoding="utf-8"?><a><b /></a>');
        Observer.Verify();
    end;

    [Test]
    procedure Create_Empty()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Txt: Text;
    begin
        Doc := XmlDocument.Create();
        Observer.Observe('hasroot', Format(Doc.GetRoot(Root)));
        asserterror Doc.WriteTo(Txt);
        Observer.ObserveError('af387');
        Observer.Observe('out', '[' + Txt + ']');
        Observer.Observe('childcount', Format(Doc.GetChildNodes().Count()));
        Observer.Expect('hasroot', 'No');
        Observer.Expect('af387|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('af387|code', 'InvalidOperation');
        Observer.Expect('out', '[]');
        Observer.Expect('childcount', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Create_WithRoot()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Txt: Text;
    begin
        Doc := XmlDocument.Create();
        Doc.Add(XmlElement.Create('root'));
        Observer.Observe('hasroot', Format(Doc.GetRoot(Root)));
        Observer.Observe('name', Root.Name());
        Doc.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Observer.Expect('hasroot', 'Yes');
        Observer.Expect('name', 'root');
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-16"?>\r\n<root />');
        Observer.Verify();
    end;

    [Test]
    procedure Create_WithDeclaration()
    var
        Doc: XmlDocument;
        Decl: XmlDeclaration;
        Txt: Text;
    begin
        Doc := XmlDocument.Create(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
        Doc.Add(XmlElement.Create('r'));
        Doc.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Observer.Observe('hasdecl', Format(Doc.GetDeclaration(Decl)));
        Observer.Observe('standalone', Decl.Standalone());
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<r />');
        Observer.Expect('hasdecl', 'Yes');
        Observer.Expect('standalone', 'yes');
        Observer.Verify();
    end;

    [Test]
    procedure Create_WithRootElementContent()
    var
        Doc: XmlDocument;
        Txt: Text;
    begin
        Doc := XmlDocument.Create(XmlElement.Create('r', '', XmlText.Create('hi')));
        Doc.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>hi</r>');
        Observer.Verify();
    end;

    [Test]
    procedure Document_TwoRoots_Error()
    var
        Doc: XmlDocument;
    begin
        Doc := XmlDocument.Create();
        Doc.Add(XmlElement.Create('a'));
        asserterror Doc.Add(XmlElement.Create('b'));
        Observer.ObserveError('second_root');
        Observer.Observe('count', Format(Doc.GetChildNodes().Count()));
        Observer.Expect('second_root|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('second_root|code', 'InvalidOperation');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Document_AddText_Error()
    var
        Doc: XmlDocument;
    begin
        Doc := XmlDocument.Create();
        asserterror Doc.Add(XmlText.Create('x'));
        Observer.ObserveError('add_text');
        asserterror Doc.Add(XmlCData.Create('x'));
        Observer.ObserveError('add_cdata');
        Doc.Add(XmlComment.Create('c'));
        asserterror Observer.Observe('add_comment', Out(Doc));
        Observer.ObserveError('af462');
        Doc.Add(XmlProcessingInstruction.Create('t', 'd'));
        asserterror Observer.Observe('add_pi', Out(Doc));
        Observer.ObserveError('af465');
        Observer.Expect('add_text|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('add_text|code', 'Argument');
        Observer.Expect('add_cdata|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('add_cdata|code', 'Argument');
        Observer.Expect('af462|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('af462|code', 'InvalidOperation');
        Observer.Expect('af465|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('af465|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Document_AddFirst_Comment()
    var
        Doc: XmlDocument;
    begin
        XmlDocument.ReadFrom('<a/>', Doc);
        Doc.AddFirst(XmlComment.Create('first'));
        Observer.Observe('addfirst', Out(Doc));
        Doc.Add(XmlComment.Create('last'));
        Observer.Observe('add', Out(Doc));
        Observer.Observe('children', Format(Doc.GetChildNodes().Count()));
        Observer.Expect('addfirst', '<?xml version="1.0" encoding="utf-16"?>\r\n<!--first-->\r\n<a />');
        Observer.Expect('add', '<?xml version="1.0" encoding="utf-16"?>\r\n<!--first-->\r\n<a />\r\n<!--last-->');
        Observer.Expect('children', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Document_GetRoot_Missing()
    var
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        Observer.Observe('default_doc_root', Format(Doc.GetRoot(Root)));
        Doc := XmlDocument.Create();
        Observer.Observe('empty_doc_root', Format(Doc.GetRoot(Root)));
        Observer.Expect('default_doc_root', 'No');
        Observer.Expect('empty_doc_root', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Document_SetDeclaration()
    var
        Doc: XmlDocument;
        Decl: XmlDeclaration;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a/>', Doc);
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-16', 'no'));
        Doc.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Doc.GetDeclaration(Decl);
        Observer.Observe('enc', Decl.Encoding());
        Observer.Observe('standalone', Decl.Standalone());
        Decl.Encoding('utf-8');
        Decl.Standalone('yes');
        Decl.Version('1.0');
        Observer.Observe('enc_set', Decl.Encoding());
        Observer.Observe('standalone_set', Decl.Standalone());
        Observer.Observe('version_set', Decl.Version());
        Doc.SetDeclaration(Decl);
        Doc.WriteTo(Txt);
        Observer.Observe('out2', Txt);
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-16" standalone="no"?>\r\n<a />');
        Observer.Expect('enc', 'utf-16');
        Observer.Expect('standalone', 'no');
        Observer.Expect('enc_set', 'utf-8');
        Observer.Expect('standalone_set', 'yes');
        Observer.Expect('version_set', '1.0');
        Observer.Expect('out2', '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure Declaration_Create_Variants()
    var
        Decl: XmlDeclaration;
    begin
        Decl := XmlDeclaration.Create('1.0', '', '');
        Observer.Observe('empty_enc', '[' + Decl.Encoding() + ']');
        Observer.Observe('empty_sa', '[' + Decl.Standalone() + ']');
        Decl := XmlDeclaration.Create('1.0', 'utf-8', 'no');
        Observer.Observe('no', Decl.Standalone());
        Observer.Observe('is_enc', Decl.Encoding());
        Decl := XmlDeclaration.Create('1.0', 'iso-8859-1', 'yes');
        Observer.Observe('iso', Decl.Encoding());
        Decl := XmlDeclaration.Create('2.0', 'utf-8', 'maybe');
        Observer.Observe('v2', Decl.Version());
        Observer.Observe('maybe', Decl.Standalone());
        Decl := XmlDeclaration.Create('1.0', 'bogus', 'no');
        Observer.Observe('bogus', Decl.Encoding());
        Observer.Expect('empty_enc', '[]');
        Observer.Expect('empty_sa', '[]');
        Observer.Expect('no', 'no');
        Observer.Expect('is_enc', 'utf-8');
        Observer.Expect('iso', 'iso-8859-1');
        Observer.Expect('v2', '2.0');
        Observer.Expect('maybe', 'maybe');
        Observer.Expect('bogus', 'bogus');
        Observer.Verify();
    end;

    [Test]
    procedure Declaration_WriteTo()
    var
        Decl: XmlDeclaration;
        Txt: Text;
    begin
        Decl := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        Decl.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Decl := XmlDeclaration.Create('1.0', '', '');
        Decl.WriteTo(Txt);
        Observer.Observe('out_min', Txt);
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-8" standalone="yes"?>');
        Observer.Expect('out_min', '<?xml version="1.0" encoding="" standalone=""?>');
        Observer.Verify();
    end;

    [Test]
    procedure Document_ReadFrom_Unicode_Entities()
    var
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        XmlDocument.ReadFrom('<a>&lt;&gt;&amp;&quot;&apos;&#65;&#x42;&#8364;</a>', Doc);
        Doc.GetRoot(Root);
        Observer.Observe('inner', Root.InnerText());
        Observer.Observe('out', Out(Doc));
        Observer.Observe('innerxml', Root.InnerXml());
        Observer.Expect('inner', '<>&"''AB€');
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>&lt;&gt;&amp;"''AB€</a>');
        Observer.Expect('innerxml', '&lt;&gt;&amp;"''AB€');
        Observer.Verify();
    end;

    [Test]
    procedure Document_Reuse_ReadFrom()
    var
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        XmlDocument.ReadFrom('<a/>', Doc);
        XmlDocument.ReadFrom('<b/>', Doc);
        Doc.GetRoot(Root);
        Observer.Observe('second', Root.Name());
        Observer.Observe('bad_overwrites', Format(XmlDocument.ReadFrom('<c>', Doc)));
        Clear(Doc);
        Observer.Observe('cleared_root', Format(Doc.GetRoot(Root)));
        Observer.Expect('second', 'b');
        Observer.Expect('bad_overwrites', 'No');
        Observer.Expect('cleared_root', 'No');
        Observer.Verify();
    end;

    local procedure Kinds(Root: XmlElement): Text
    var
        Nodes: XmlNodeList;
        N: XmlNode;
        R: Text;
    begin
        Nodes := Root.GetChildNodes();
        R := Format(Nodes.Count()) + ':';
        foreach N in Nodes do
            if N.IsXmlElement() then
                R += 'element ' + N.AsXmlElement().Name() + ';'
            else
                if N.IsXmlText() then
                    R += 'text [' + N.AsXmlText().Value() + '];'
                else
                    R += 'other;';
        exit(R);
    end;

    // Corpus issue 671 item 91 (microsoft/AL#5881): the line breaks and indentation between elements of a document built with
    // TextBuilder.AppendLine, after ReadFrom without options and with PreserveWhitespace true and false.
    [Test]
    procedure ReadFrom_AppendLine_Whitespace_Nodes()
    var
        Doc: XmlDocument;
        Opt: XmlReadOptions;
        Root: XmlElement;
        TB: TextBuilder;
    begin
        TB.AppendLine('<root>');
        TB.AppendLine('  <a>1</a>');
        TB.AppendLine('  <b/>');
        TB.Append('</root>');
        XmlDocument.ReadFrom(TB.ToText(), Doc);
        Doc.GetRoot(Root);
        Observer.Observe('no_options', Kinds(Root));
        Opt.PreserveWhitespace(true);
        XmlDocument.ReadFrom(TB.ToText(), Opt, Doc);
        Doc.GetRoot(Root);
        Observer.Observe('preserve_true', Kinds(Root));
        Opt.PreserveWhitespace(false);
        XmlDocument.ReadFrom(TB.ToText(), Opt, Doc);
        Doc.GetRoot(Root);
        Observer.Observe('preserve_false', Kinds(Root));
        Observer.Observe('inner_text', Root.InnerText());
        Observer.Expect('no_options', '5:text [\n  ];element a;text [\n  ];element b;text [\n];');
        Observer.Expect('preserve_true', '5:text [\n  ];element a;text [\n  ];element b;text [\n];');
        Observer.Expect('preserve_false', '5:text [\n  ];element a;text [\n  ];element b;text [\n];');
        Observer.Expect('inner_text', '\n  1\n  \n');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryWriteText(Doc: XmlDocument; var Result: Text)
    begin
        Doc.WriteTo(Result);
    end;

    [TryFunction]
    local procedure TryWriteStream(Doc: XmlDocument; var Length: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Doc.WriteTo(OutS);
        Length := TempBlob.Length();
    end;

    local procedure WriteBadChar(Name: Text; Code: Integer)
    var
        Doc: XmlDocument;
        C: Text[1];
        Txt: Text;
        Length: Integer;
    begin
        C[1] := Code;
        Doc := XmlDocument.Create();
        Doc.Add(XmlElement.Create('a', '', 'x' + C + 'y'));
        ClearLastError();
        Observer.Observe(Name + '_text_ok', Format(TryWriteText(Doc, Txt)));
        Observer.ObserveError(Name + '_text');
        Observer.Observe(Name + '_text', Txt);
        Observer.Observe(Name + '_stream_ok', Format(TryWriteStream(Doc, Length)));
        Observer.ObserveError(Name + '_stream');
        Observer.Observe(Name + '_stream_length', Format(Length));
    end;

    // Corpus issue 671 item 93 (microsoft/AL#8082): XmlDocument.WriteTo when element text holds a character XML 1.0 does not allow.
    [Test]
    procedure WriteTo_Char_Not_Allowed_In_Xml()
    begin
        WriteBadChar('char1', 1);
        WriteBadChar('char11', 11);
        WriteBadChar('lone_surrogate', 55296);
        WriteBadChar('tab_allowed', 9);
        Observer.Expect('char1_text_ok', 'No');
        Observer.Expect('char1_text|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('char1_text|code', 'Argument');
        Observer.Expect('char1_text', '');
        Observer.Expect('char1_stream_ok', 'No');
        Observer.Expect('char1_stream|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('char1_stream|code', 'Argument');
        Observer.Expect('char1_stream_length', '0');
        Observer.Expect('char11_text_ok', 'No');
        Observer.Expect('char11_text|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('char11_text|code', 'Argument');
        Observer.Expect('char11_text', '');
        Observer.Expect('char11_stream_ok', 'No');
        Observer.Expect('char11_stream|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('char11_stream|code', 'Argument');
        Observer.Expect('char11_stream_length', '0');
        Observer.Expect('lone_surrogate_text_ok', 'No');
        Observer.Expect('lone_surrogate_text|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('lone_surrogate_text|code', 'Argument');
        Observer.Expect('lone_surrogate_text', '');
        Observer.Expect('lone_surrogate_stream_ok', 'No');
        Observer.Expect('lone_surrogate_stream|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('lone_surrogate_stream|code', 'Argument');
        Observer.Expect('lone_surrogate_stream_length', '0');
        Observer.Expect('tab_allowed_text_ok', 'Yes');
        Observer.Expect('tab_allowed_text|text', '');
        Observer.Expect('tab_allowed_text|code', '');
        Observer.Expect('tab_allowed_text', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>x\ty</a>');
        Observer.Expect('tab_allowed_stream_ok', 'Yes');
        Observer.Expect('tab_allowed_stream|text', '');
        Observer.Expect('tab_allowed_stream|code', '');
        Observer.Expect('tab_allowed_stream_length', '53');
        Observer.Verify();
    end;
}
