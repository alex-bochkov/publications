Function Get-Target-Server {

    Return " < Target Server Name > "

}

Function Collect-AWS-Object-Configuration {
    Param(
        [String]$DatabaseServerTarget
    )

    Function Insert-Objects {
        Param(
            [String]$DatabaseServerTarget,
            $Objects,
            $IDField
        )

        $conn = New-Object System.Data.SqlClient.SqlConnection
        $conn.ConnectionString = "Data Source=$DatabaseServerTarget;Initial Catalog=DBA;Integrated Security=SSPI;"
        $conn.open()

        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $cmd.connection = $conn
        $cmd.commandtext = "EXEC [sp_InsertAWSObjectConfiguration] @ObjectId = @ObjectId, @ConfigurationJSON = @ConfigurationJSON"

        ForEach ($Object in $Objects) {

            $JSON = ConvertTo-Json $Object -Depth 100

            $cmd.Parameters.Clear();
            if ($IDField -eq "InstanceId") {
                $cmd.Parameters.AddWithValue("ObjectId", $Object.InstanceId) | Out-Null
            }
            if ($IDField -eq "GroupId") {
                $cmd.Parameters.AddWithValue("ObjectId", $Object.GroupId) | Out-Null
            }
            $cmd.Parameters.AddWithValue("ConfigurationJSON",  $JSON) | Out-Null
            $cmd.ExecuteNonQuery() | Out-Null

        } 

        $conn.Close();
    }

    try {

        $AllInstances = (Get-EC2Instance -Filter @{Name="tag:Owner";Value="DBA"}).Instances;

        Insert-Objects -DatabaseServerTarget $DatabaseServerTarget -Objects $AllInstances -IDField "InstanceId"

        $AllSG = (Get-EC2SecurityGroup -Filter @{Name="tag:Owner";Value="DBA"})

        Insert-Objects -DatabaseServerTarget $DatabaseServerTarget -Objects $AllSG -IDField "GroupId"


    } catch {}

}
