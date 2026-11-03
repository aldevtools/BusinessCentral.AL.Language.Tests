// @expect AL0133 | Argument 1: cannot convert from 'Integer' to 'TextEncoding'
// currXMLport.TextEncoding is a TextEncoding: an Integer is AL0133 on assignment (writer Y67, gap cycle 6 follow-up).
table 52652 "MNC Y67 Enc Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

xmlport 52653 "MNC Y67 Enc Integer"
{
    Format = VariableText;
    Direction = Export;
    schema
    {
        textelement(Root)
        {
            tableelement(R; "MNC Y67 Enc Row")
            {
                fieldelement(Id; R.Id) { }
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        currXMLport.TextEncoding := 1;
    end;
}
