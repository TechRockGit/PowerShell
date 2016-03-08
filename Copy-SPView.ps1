#Using this script it’s possible to copy views from a source library to any target library.
#This includes copying views to libraries in other site collections / web applications or even other SharePoint servers!

#Summary of possible variables:

#– WebURL
#  URL of the source library
#– SourceList
#  Displayname of the source library what contains the view
#– SourceView
#  Name of the view that needs to be copied
#– NewViewName
#  Name of the view in the target libraries. (if left empty the source view name will be used.)
#– TargetURL
#URL of the target site / site collection of web application (If left empty the libraries in the WebURL are being
#   updated)
#– IgnoreLibs
#  Name of the libraries that need to be ignored.
#(The script contains a list of SharePoint Household Libraries
#  that are ignored by default including the Source Library.)
#  “Customized Reports”,”Form Templates”,”Shared Documents”,”Site Assets”,”Site Pages”,
#  “Style Library”,”Master Page Gallery”,”Picture”

#.Example 1
## This example copies the view to all document libraries within the source URL 
## PS C:\> .\Copy-SPView.ps1 -WebURL <source URL> -SourceList <Your Source Library> -SourceView <Name of View>

#.Example 2
## This example copies the view to all document libraries within the target URL. 
## PS C:> .Copy-SPView.ps1 -WebURL <source URL> -SourceList <Your Source Library> -SourceView <Name of the View> -TargetURL “<Your target URL>”

#.Example 3
## This example shows all possible variables that are currently working.
## PS C:> .Copy-SPView.ps1 -WebURL <source URL> -SourceList <Your Source Library> -SourceView <Name of the View> -TargetURL “<Your target URL>” -NewViewName “Rogier’s View” -IgnoreLibs “Shared Documents”

# Link: https://rogierdijkman.wordpress.com/2013/12/16/copy-views-to-other-libraries-with-powershell/

[CmdletBinding()]
 
Param
(
  [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$WebURL,
  [Parameter(Mandatory=$true)][string]$SourceList,
  [Parameter(Mandatory=$true)][string]$SourceView,
  [Parameter(Mandatory=$false)][string]$NewViewName,
  [Parameter(Mandatory=$false)][string]$TargetURL,
  [Parameter(Mandatory=$false)][string]$IgnoreLibs,
  [Parameter(Mandatory=$false)][string]$AsDefault,
  [Parameter(Mandatory=$false)][string]$OutputPath,
  [Parameter(Mandatory=$false)][string]$SmtpServer,
  [Parameter(Mandatory=$false)][string]$EmailFrom,
  [Parameter(Mandatory=$false)][string]$EmailTo
)
 
Function Copy-SPView
{
 
  Write-Host 'Loading Sytem Modules'
  Get-Module -listAvailable | import-module
 
  if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null )
  {
    Write-Host 'Loading Sharepoint Module'
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SharePoint')
    Add-PSSnapin -Name Microsoft.SharePoint.PowerShell
 
    if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell) -eq $null )
    {
      Write-Host 'Failed to load sharepoint snap-in. Could not proceed further, Aborting ...'
      Exit
    }
  }
 
  Start-SPAssignment -Global
 
  $SPWeb  = Get-SPWeb -Identity $WebURL -ErrorAction SilentlyContinue
  $SPWebT = Get-SPWeb -Identity $TargetURL -ErrorAction SilentlyContinue
 
  $ignoreList = 'Customized Reports','Form Templates','Shared Documents','Site Assets','Site Pages','Style Library','Master Page Gallery','Picture' + $SourceList + $IgnoreLibs
 
  if($SPWeb -eq $null){ Write-Host 'Unable to reach the provided URL, Aborting ...' ;Exit }
  if( ($SPWeb.Lists.TryGetList($SourceList) ) -eq $Null){ Write-Host 'The list $SourceList is not availible, Aborting ...'; Exit }
  if($AsDefault -ne $True){$AsDefault = $False}
 
  $SourceLists=$SPweb.lists['$SourceList']
 
  if( ($SourceLists.Views[$SourceView]) -eq $Null ){ Write-Host 'The view $SourceView does not exist, Aborting ...'; Exit  }
  if($NewViewName -lt 1){ $NewViewName = $SourceView }
 
  # Go through each document library in the target site
  $listIds = @();
  $i = 0;
 
  if($SPWebT -ne $null)
  {
    $lists=$SPWebT.lists
  }
  else
  {
    $lists=$SPWeb.lists
  }
 
  while ($i -lt $lists.Count)
  {
    $list = $lists[$i]
 
    if($list.BaseType -eq 'DocumentLibrary')
    {
      if ($Ignorelist -contains $list.Title)
      {
        write-host $list 'is Ignored' -foregroundcolor Yellow -backgroundcolor Black
      }
      else
      {
        $view = $list.Views[$NewViewName]
        if ($view -ne $null)
        {
          Write-Host 'Updating existing view' -foregroundcolor Yellow -backgroundcolor Black
 
          $list.views.delete($view.ID)
          $list.update()
        }
 
        $Viewfields = $Sourcelists.Views[$SourceView].ViewFields.ToStringCollection()
        $viewRowLimit='100'
        $viewPaged=$true
        $viewDefaultView=$AsDefault
 
        # Setting the Query for the View
        $viewQuery = $Sourcelists.Views[$SourceView].Query
        $viewName = $NewViewName
 
        # Finally – Provisioning the View
 
        try
        {
          $myListView = $list.Views.Add($viewName, $viewFields, $viewQuery, 100, $True, $False, 'HTML', $False)
        }
        catch
        {
          Write-Host 'Not all columns are availible in the target library' -foregroundcolor Yellow
        }
 
        # You need to Update the View for changes made to the view
        # Updating the List is not enough
        $myListView.DefaultView = $AsDefault
        $myListView.Update()
        $list.Update()
 
        Write-Host '$viewName added to Library $list'
      }
    }
  $i = $i + 1
  }
$SPWeb.Dispose()
}
 
Copy-SPView ($WebURL,$SourceList,$SourceView,$NewViewName)