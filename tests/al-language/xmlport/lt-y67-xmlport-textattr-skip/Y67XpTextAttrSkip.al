// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/xmlport/devenv-onbeforepassvariable-xmlport-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); xmlports 93615-93616, codeunits 93617-93618 (writer Y67, gap cycle 6 follow-up)
// Probe: a text element that has text attributes (and its own text), with OnBeforePassVariable and Skip, below container text elements
//   that are NOT inside a table element (the shape of an e-document EndpointID element): export with no Skip, Skip in the element, Skip
//   in one of its attributes, Skip in the containers, the element one, two and three levels below the root, an empty element with
//   attributes, a changed value; the order of the triggers; import of the same document (the order of OnAfterAssignVariable).
//   Y60 (xmlport/lt-y60-xmlport-container-skip/Y60XpContainerSkip.al) pins Skip two levels below a TABLE element.
// BC versions: 27, 28, 29

codeunit 93617 "LT Y67 TA Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

xmlport 93615 "LT Y67 TA Skip Export"
{
    Format = Xml;
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Direct)
            {
                textattribute(dscheme)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('direct dscheme');
                        dscheme := 'D8';
                        if Mode = 7 then
                            currXMLport.Skip();
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    Log.Add('direct');
                    Direct := 'dv';
                    if Mode = 6 then
                        currXMLport.Skip();
                end;
            }
            textelement(Cont1)
            {
                textelement(Cont2)
                {
                    textelement(EP)
                    {
                        textattribute(scheme)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('scheme');
                                scheme := '0088';
                                if Mode = 2 then
                                    currXMLport.Skip();
                            end;
                        }
                        textattribute(sid)
                        {
                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('sid');
                                sid := 'S1';
                            end;
                        }

                        trigger OnBeforePassVariable()
                        begin
                            Log.Add('ep');
                            case Mode of
                                3:
                                    EP := '';
                                8:
                                    EP := 'changed';
                                else
                                    EP := 'ep-value';
                            end;
                            if Mode = 1 then
                                currXMLport.Skip();
                        end;
                    }

                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('cont2');
                        if Mode = 4 then
                            currXMLport.Skip();
                    end;
                }
                textelement(Sib)
                {
                    trigger OnBeforePassVariable()
                    begin
                        Log.Add('sib');
                        Sib := 'sv';
                    end;
                }

                trigger OnBeforePassVariable()
                begin
                    Log.Add('cont1');
                    if Mode = 5 then
                        currXMLport.Skip();
                end;
            }
            textelement(D1)
            {
                textelement(D2)
                {
                    textelement(D3)
                    {
                        textelement(Deep)
                        {
                            textattribute(dk)
                            {
                                trigger OnBeforePassVariable()
                                begin
                                    Log.Add('dk');
                                    dk := 'K';
                                end;
                            }

                            trigger OnBeforePassVariable()
                            begin
                                Log.Add('deep');
                                Deep := 'dd';
                                if Mode = 9 then
                                    currXMLport.Skip();
                            end;
                        }
                    }
                }
            }
            textelement(After)
            {
                trigger OnBeforePassVariable()
                begin
                    Log.Add('after');
                    After := 'av';
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y67 TA Log";
        Mode: Integer;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;
}

xmlport 93616 "LT Y67 TA Skip Import"
{
    Format = Xml;
    Direction = Import;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            textelement(Cont1)
            {
                MinOccurs = Zero;
                textelement(Cont2)
                {
                    MinOccurs = Zero;
                    textelement(EP)
                    {
                        MinOccurs = Zero;
                        textattribute(scheme)
                        {
                            Occurrence = Optional;
                            trigger OnAfterAssignVariable()
                            begin
                                Log.Add('scheme=' + scheme);
                            end;
                        }
                        textattribute(sid)
                        {
                            Occurrence = Optional;
                            trigger OnAfterAssignVariable()
                            begin
                                Log.Add('sid=' + sid);
                            end;
                        }

                        trigger OnAfterAssignVariable()
                        begin
                            Log.Add('ep=' + EP);
                        end;
                    }

                    trigger OnAfterAssignVariable()
                    begin
                        Log.Add('cont2=[' + Cont2 + ']');
                    end;
                }

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('cont1=[' + Cont1 + ']');
                end;
            }
            textelement(After)
            {
                MinOccurs = Zero;
                trigger OnAfterAssignVariable()
                begin
                    Log.Add('after=' + After);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT Y67 TA Log";
}

codeunit 93618 "LT Y67 TA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y67 TA Log";

    local procedure ExportText(Mode: Integer): Text
    var
        Xp: XmlPort "LT Y67 TA Skip Export";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        Xp.SetMode(Mode);
        TempBlob.CreateOutStream(OutS);
        Xp.SetDestination(OutS);
        Xp.Export();
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure ImportText(Content: Text): Text
    var
        Xp: XmlPort "LT Y67 TA Skip Import";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        if Xp.Import() then
            exit('ok');
        exit('error ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Mode: Integer)
    begin
        Log.Take();
        Observer.Observe('m' + Format(Mode) + ' xml', ExportText(Mode));
        Observer.Observe('m' + Format(Mode) + ' log', Log.Take());
    end;

    [Test]
    procedure Export_NoSkip_And_SkipInElement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 0);
        One(Observer, 1);
        One(Observer, 2);
        Observer.Expect('m0 xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Direct dscheme="D8">dv</Direct>|  <Cont1>|    <Cont2>|      <EP scheme="0088" sid="S1">ep-value</EP>|    </Cont2>|    <Sib>sv</Sib>|  </Cont1>|  <D1>|    <D2>|      <D3>|        <Deep dk="K">dd</Deep>|      </D3>|    </D2>|  </D1>|  <After>av</After>|</Root>|');
        Observer.Expect('m0 log', 'direct;direct dscheme;cont1;cont2;ep;scheme;sid;sib;deep;dk;after;');
        Observer.Expect('m1 xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Direct dscheme="D8">dv</Direct>|  <Cont1>|    <Cont2 />|    <Sib>sv</Sib>|  </Cont1>|  <D1>|    <D2>|      <D3>|        <Deep dk="K">dd</Deep>|      </D3>|    </D2>|  </D1>|  <After>av</After>|</Root>|');
        Observer.Expect('m1 log', 'direct;direct dscheme;cont1;cont2;ep;sib;deep;dk;after;');
        Observer.Expect('m2 xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Direct dscheme="D8">dv</Direct>|  <Cont1>|    <Cont2>|      <EP sid="S1">ep-value</EP>|    </Cont2>|    <Sib>sv</Sib>|  </Cont1>|  <D1>|    <D2>|      <D3>|        <Deep dk="K">dd</Deep>|      </D3>|    </D2>|  </D1>|  <After>av</After>|</Root>|');
        Observer.Expect('m2 log', 'direct;direct dscheme;cont1;cont2;ep;scheme;sid;sib;deep;dk;after;');
        Observer.Verify();
    end;

    [Test]
    procedure Export_EmptyValue_ChangedValue_Containers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 3);
        One(Observer, 8);
        One(Observer, 4);
        Observer.Expect('m3 xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Direct dscheme="D8">dv</Direct>|  <Cont1>|    <Cont2>|      <EP scheme="0088" sid="S1" />|    </Cont2>|    <Sib>sv</Sib>|  </Cont1>|  <D1>|    <D2>|      <D3>|        <Deep dk="K">dd</Deep>|      </D3>|    </D2>|  </D1>|  <After>av</After>|</Root>|');
        Observer.Expect('m3 log', 'direct;direct dscheme;cont1;cont2;ep;scheme;sid;sib;deep;dk;after;');
        Observer.Expect('m8 xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Direct dscheme="D8">dv</Direct>|  <Cont1>|    <Cont2>|      <EP scheme="0088" sid="S1">changed</EP>|    </Cont2>|    <Sib>sv</Sib>|  </Cont1>|  <D1>|    <D2>|      <D3>|        <Deep dk="K">dd</Deep>|      </D3>|    </D2>|  </D1>|  <After>av</After>|</Root>|');
        Observer.Expect('m8 log', 'direct;direct dscheme;cont1;cont2;ep;scheme;sid;sib;deep;dk;after;');
        Observer.Expect('m4 xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Direct dscheme="D8">dv</Direct>|  <Cont1>|    <Sib>sv</Sib>|  </Cont1>|  <D1>|    <D2>|      <D3>|        <Deep dk="K">dd</Deep>|      </D3>|    </D2>|  </D1>|  <After>av</After>|</Root>|');
        Observer.Expect('m4 log', 'direct;direct dscheme;cont1;cont2;sib;deep;dk;after;');
        Observer.Verify();
    end;

    [Test]
    procedure Export_SkipContainer_And_Levels()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 5);
        One(Observer, 6);
        One(Observer, 7);
        One(Observer, 9);
        Observer.Expect('m5 xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Direct dscheme="D8">dv</Direct>|  <D1>|    <D2>|      <D3>|        <Deep dk="K">dd</Deep>|      </D3>|    </D2>|  </D1>|  <After>av</After>|</Root>|');
        Observer.Expect('m5 log', 'direct;direct dscheme;cont1;deep;dk;after;');
        Observer.Expect('m6 xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Cont1>|    <Cont2>|      <EP scheme="0088" sid="S1">ep-value</EP>|    </Cont2>|    <Sib>sv</Sib>|  </Cont1>|  <D1>|    <D2>|      <D3>|        <Deep dk="K">dd</Deep>|      </D3>|    </D2>|  </D1>|  <After>av</After>|</Root>|');
        Observer.Expect('m6 log', 'direct;cont1;cont2;ep;scheme;sid;sib;deep;dk;after;');
        Observer.Expect('m7 xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Direct>dv</Direct>|  <Cont1>|    <Cont2>|      <EP scheme="0088" sid="S1">ep-value</EP>|    </Cont2>|    <Sib>sv</Sib>|  </Cont1>|  <D1>|    <D2>|      <D3>|        <Deep dk="K">dd</Deep>|      </D3>|    </D2>|  </D1>|  <After>av</After>|</Root>|');
        Observer.Expect('m7 log', 'direct;direct dscheme;cont1;cont2;ep;scheme;sid;sib;deep;dk;after;');
        Observer.Expect('m9 xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Direct dscheme="D8">dv</Direct>|  <Cont1>|    <Cont2>|      <EP scheme="0088" sid="S1">ep-value</EP>|    </Cont2>|    <Sib>sv</Sib>|  </Cont1>|  <D1>|    <D2>|      <D3 />|    </D2>|  </D1>|  <After>av</After>|</Root>|');
        Observer.Expect('m9 log', 'direct;direct dscheme;cont1;cont2;ep;scheme;sid;sib;deep;after;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Observer.Observe('full ok', ImportText('<Root><Cont1><Cont2><EP scheme="0088" sid="S1">v</EP></Cont2></Cont1><After>z</After></Root>'));
        Observer.Observe('full log', Log.Take());
        Observer.Observe('no attr ok', ImportText('<Root><Cont1><Cont2><EP>v</EP></Cont2></Cont1></Root>'));
        Observer.Observe('no attr log', Log.Take());
        Observer.Observe('empty ep ok', ImportText('<Root><Cont1><Cont2><EP scheme="9" /></Cont2></Cont1></Root>'));
        Observer.Observe('empty ep log', Log.Take());
        Observer.Observe('missing ok', ImportText('<Root><Cont1 /><After>q</After></Root>'));
        Observer.Observe('missing log', Log.Take());
        Observer.Expect('full ok', 'ok');
        Observer.Expect('full log', 'scheme=0088;sid=S1;ep=v;cont2=[];cont1=[];after=z;');
        Observer.Expect('no attr ok', 'ok');
        Observer.Expect('no attr log', 'ep=v;cont2=[];cont1=[];');
        Observer.Expect('empty ep ok', 'ok');
        Observer.Expect('empty ep log', 'scheme=9;ep=;cont2=[];cont1=[];');
        Observer.Expect('missing ok', 'ok');
        Observer.Expect('missing log', 'cont1=[];after=q;');
        Observer.Verify();
    end;
}
