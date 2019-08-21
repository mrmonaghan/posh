function Send-SESEmail {
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory)]
        [string]$To,

        [Parameter(Mandatory)]
        [String]$Subject,

        [Parameter(Mandatory)]
        [object]$Body,

        [Parameter()]
        [String]$Attachment


        )

    begin {
        $AWSSMTPUsername = "<ENTER USERNAME HERE>"
        $AWSSMTPSecret = "<ENTER SECRET KEY HERE>"


        $SECURE_KEY = $(ConvertTo-SecureString -AsPlainText -String $AWSSMTPSecret -Force)
        $creds = $(New-Object System.Management.Automation.PSCredential ($AWSSMTPUsername, $SECURE_KEY))

        $Params = @{
            To = $To
            From = "<ENTER 'FROM' ADDRESS HERE>"
            Subject = $Subject
            Body = $Body
            SmtpServer = "<ENTER AWS SES REGION URL HERE>"
            Credential = $Creds
            Port = 587
            UseSSL = $True
            }
    }

    process {
        if ($Attachment) {
            $Params.Attachments = $Attachment
            }
        }

    end {
        Send-MailMessage @Params
        }
    }


