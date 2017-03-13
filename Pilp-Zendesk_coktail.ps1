#requires -Version 3.0

$ZendeskDomain = 'YOURSUPPORTSITE.zendesk.com'
$Email = 'YOUR EMAIL'
$ZendeskToken = 'TOUR ZENDESK TOKEN'
$PiplToken = 'YOUR SOCIAL-PREMIUM PIPL LIZENSE'
 



Set-Variable -Name Headers -Value @{
  Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Email)/token:$($ZendeskToken)"))
} -Scope Global



$params = @{
  Uri     = ("https://$ZendeskDomain/api/v2/users.json").TrimEnd('&')
  Method  = 'Get'
  Headers = $Headers
}




Function Add-Photo ($ZendeskUsers)
{  
  
  Foreach ($User in $ZendeskUsers.users)
  {
    If (-not $User.photo -and $User.email)
    {
      Write-Information "Processing $User.name..."
      $Email = $User.email
      $Name = $User.name
      $params = @{
        Uri    = ("http://api.pipl.com/search?email=$Email&raw_name=$Name&country=DK&match_requirements=(email and image)&key=$PiplToken").TrimEnd('&')
        Method = 'Get'
      }
      $Pipl = Invoke-RestMethod @params -Verbose
      if ($Pipl.person.images)
      { 
        write-information "got image updating Zendesk."
        $id = $User.id
        $photourl = $Pipl.person.images[0].url
        Write-Verbose "Updating $Email whith pgoto $Photourl"
        $params = @{
          Uri         = ("https://$ZendeskDomain/api/v2/users/$id.json")
          Method      = 'PUT'
          Headers     = $Headers
          #Body        = ($User | ConvertTo-Json)
          Body = (@{"user" =  @{"remote_photo_url" = $photourl}} | ConvertTo-Json)
          ContentType = 'application/json'
        }
      
        $result = Invoke-RestMethod @params -Verbose

      }
    }
  }

  If ($ZendeskUsers.next_page) 
  {
    $params = @{
      Uri     = $ZendeskUsers.next_page
      Method  = 'Get'
      Headers = $Headers
    }
    $ZendeskUsers = Invoke-RestMethod @params -Verbose
    Add-Photo ($ZendeskUsers)
  } 
}

$ZendeskUsers = Invoke-RestMethod @params -Verbose
Add-Photo ($ZendeskUsers)



