// @expect AL0133 | Argument 1: cannot convert from 'XmlPort "MNC This XmlPort"' to 'Codeunit'
// BindSubscription(this) inside an xmlport.
xmlport 50000 "MNC This XmlPort"
{
    schema { textelement(Root) { } }

    trigger OnPreXmlPort()
    begin
        BindSubscription(this);
    end;
}
