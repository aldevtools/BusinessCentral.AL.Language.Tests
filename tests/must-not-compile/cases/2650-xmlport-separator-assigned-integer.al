// @expect AL0133 | Argument 1: cannot convert from 'Integer' to 'Text'
// @expect AL0133 | Argument 1: cannot convert from 'Integer' to 'Text'
// currXMLport.FieldSeparator and FieldDelimiter take a Text or a Char; an Integer (a character code) is AL0133, also on assignment (writer Y67, gap cycle 6 follow-up).
table 52650 "MNC Y67 Sep Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

xmlport 52651 "MNC Y67 Sep Integer"
{
    Format = VariableText;
    Direction = Export;
    schema
    {
        textelement(Root)
        {
            tableelement(R; "MNC Y67 Sep Row")
            {
                fieldelement(Id; R.Id) { }
            }
        }
    }

    trigger OnPreXmlPort()
    var
        Code: Integer;
    begin
        currXMLport.FieldSeparator := 59;
        currXMLport.FieldDelimiter := Code;
    end;
}
