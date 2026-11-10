// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: none
// Probe: objects of the blank option member matrix (FMOptionBlankVar.al, FMOptionBlankField.al, FMOptionBlankEnum.al). One table with an Option field per blank form,
//        one Enum per blank form (a blank form is " ", "" or an unquoted empty member; F = first, M = middle, L = last position; A and B are the other members),
//        and the same enums again with a Caption on every blank value.
// local object: the OptionMembers, the member names and the Caption of these objects are the claim under test (standing rule 2)
// BC versions: 27, 28, 29

table 67770 "LT OB Row FS"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = " ",A,B; }
        field(3; OptCap; Option)
        {
            OptionMembers = " ",A,B;
            OptionCaption = 'Blank0,A,B';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

table 67771 "LT OB Row MS"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = A," ",B; }
        field(3; OptCap; Option)
        {
            OptionMembers = A," ",B;
            OptionCaption = 'A,Blank1,B';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

table 67772 "LT OB Row LS"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = A,B," "; }
        field(3; OptCap; Option)
        {
            OptionMembers = A,B," ";
            OptionCaption = 'A,B,Blank2';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

table 67773 "LT OB Row FQ"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = "",A,B; }
        field(3; OptCap; Option)
        {
            OptionMembers = "",A,B;
            OptionCaption = 'Blank0,A,B';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

table 67774 "LT OB Row MQ"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = A,"",B; }
        field(3; OptCap; Option)
        {
            OptionMembers = A,"",B;
            OptionCaption = 'A,Blank1,B';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

table 67775 "LT OB Row LQ"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = A,B,""; }
        field(3; OptCap; Option)
        {
            OptionMembers = A,B,"";
            OptionCaption = 'A,B,Blank2';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

table 67776 "LT OB Row FU"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = ,A,B; }
        field(3; OptCap; Option)
        {
            OptionMembers = ,A,B;
            OptionCaption = 'Blank0,A,B';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

table 67777 "LT OB Row MU"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = A,,B; }
        field(3; OptCap; Option)
        {
            OptionMembers = A,,B;
            OptionCaption = 'A,Blank1,B';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

table 67778 "LT OB Row LU"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = A,B,; }
        field(3; OptCap; Option)
        {
            OptionMembers = A,B,;
            OptionCaption = 'A,B,Blank2';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

table 67779 "LT OB Row QS1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = " ",A,""; }
        field(3; OptCap; Option)
        {
            OptionMembers = " ",A,"";
            OptionCaption = 'Blank0,A,Blank2';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

table 67780 "LT OB Row QS2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Opt; Option) { OptionMembers = "",A," "; }
        field(3; OptCap; Option)
        {
            OptionMembers = "",A," ";
            OptionCaption = 'Blank0,A,Blank2';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

enum 67783 "LT OB Enum FS"
{
    Extensible = false;

    value(0; " ") { }
    value(1; A) { }
    value(2; B) { }
}

enum 67793 "LT OB Enum FS Cap"
{
    Extensible = false;

    value(0; " ") { Caption = 'Cap0'; }
    value(1; A) { }
    value(2; B) { }
}

enum 67784 "LT OB Enum MS"
{
    Extensible = false;

    value(0; A) { }
    value(1; " ") { }
    value(2; B) { }
}

enum 67794 "LT OB Enum MS Cap"
{
    Extensible = false;

    value(0; A) { }
    value(1; " ") { Caption = 'Cap1'; }
    value(2; B) { }
}

enum 67785 "LT OB Enum LS"
{
    Extensible = false;

    value(0; A) { }
    value(1; B) { }
    value(2; " ") { }
}

enum 67795 "LT OB Enum LS Cap"
{
    Extensible = false;

    value(0; A) { }
    value(1; B) { }
    value(2; " ") { Caption = 'Cap2'; }
}

enum 67786 "LT OB Enum FQ"
{
    Extensible = false;

    value(0; "") { }
    value(1; A) { }
    value(2; B) { }
}

enum 67796 "LT OB Enum FQ Cap"
{
    Extensible = false;

    value(0; "") { Caption = 'Cap0'; }
    value(1; A) { }
    value(2; B) { }
}

enum 67787 "LT OB Enum MQ"
{
    Extensible = false;

    value(0; A) { }
    value(1; "") { }
    value(2; B) { }
}

enum 67797 "LT OB Enum MQ Cap"
{
    Extensible = false;

    value(0; A) { }
    value(1; "") { Caption = 'Cap1'; }
    value(2; B) { }
}

enum 67788 "LT OB Enum LQ"
{
    Extensible = false;

    value(0; A) { }
    value(1; B) { }
    value(2; "") { }
}

enum 67798 "LT OB Enum LQ Cap"
{
    Extensible = false;

    value(0; A) { }
    value(1; B) { }
    value(2; "") { Caption = 'Cap2'; }
}

enum 67789 "LT OB Enum QS1"
{
    Extensible = false;

    value(0; " ") { }
    value(1; A) { }
    value(2; "") { }
}

enum 67799 "LT OB Enum QS1 Cap"
{
    Extensible = false;

    value(0; " ") { Caption = 'Cap0'; }
    value(1; A) { }
    value(2; "") { Caption = 'Cap2'; }
}

enum 67790 "LT OB Enum QS2"
{
    Extensible = false;

    value(0; "") { }
    value(1; A) { }
    value(2; " ") { }
}

enum 67800 "LT OB Enum QS2 Cap"
{
    Extensible = false;

    value(0; "") { Caption = 'Cap0'; }
    value(1; A) { }
    value(2; " ") { Caption = 'Cap2'; }
}

