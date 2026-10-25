// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-saveasxml-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables and helper of P105Fix.al; query 72275 of P105QryXml.al
// Facts: the full text Query.SaveAsXml writes for a query with Integer, Text[30] and Decimal columns (the same six calls as P105QryXml.al, whose content is not asserted):
// default, SetRange, empty result, TopNumberOfRows(1), the static form, a SetFilter on the Text column. Lines are read with InStream.ReadText and joined with '|'.
// BC versions: 27, 28, 29

codeunit 89241 "LT SM QryXml Content"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P105 Helper";

    local procedure Fresh(var Store: Record "LT P105 Store"; var OutStr: OutStream)
    begin
        Helper.Seed();
        Store.Id := 1;
        Store.Insert();
        Store.Data.CreateOutStream(OutStr);
    end;

    [Test]
    procedure SaveAsXml_Default_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Observer.Observe('ok', Format(Qry.SaveAsXml(OutStr)));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsXml_SetRange_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Qry.SetRange(Grp, 2);
        Observer.Observe('ok', Format(Qry.SaveAsXml(OutStr)));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsXml_EmptyResult_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Qry.SetRange(Grp, 99);
        Observer.Observe('ok', Format(Qry.SaveAsXml(OutStr)));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsXml_Top1_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Qry.TopNumberOfRows(1);
        Observer.Observe('ok', Format(Qry.SaveAsXml(OutStr)));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsXml_Static_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Observer.Observe('ok', Format(Query.SaveAsXml(Query::"LT P105 XmlQry", OutStr)));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsXml_TextFilter_Content()
    var
        Observer: Codeunit "Probe Observer";
        Store: Record "LT P105 Store";
        Qry: Query "LT P105 XmlQry";
        OutStr: OutStream;
    begin
        Fresh(Store, OutStr);
        Qry.SetFilter(Name, '*o*');
        Observer.Observe('ok', Format(Qry.SaveAsXml(OutStr)));
        Store.Modify();
        Observer.Observe('content', Helper.ReadAll(Store));
        Observer.Finish();
    end;
}
