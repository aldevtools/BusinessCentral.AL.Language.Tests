// dotnet declarations in a namespace for Y20DotNetFullTypeName.al (writer Y20, al-runner issue 6488).
namespace LtY20.DotNetNs;

dotnet
{
    assembly(mscorlib)
    {
        type("System.Text.StringBuilder"; Y20NsBuilder) { }
        type("System.Text.StringBuilder"; "System.Text.StringBuilder") { }
    }
}
