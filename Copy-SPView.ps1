Function Copy-SPView([string]$WebURL,
  [string]$SourceList,
  [string]$SourceView,
  [string]$TargetURL,
  [string]$DestList  )
{
  Write-Host "Loading Sytem Modules";
  #Get-Module -listAvailable | import-module
  if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null )
  {
     Write-Host "Loading Sharepoint Module";
     [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
     Add-PSSnapin -Name Microsoft.SharePoint.PowerShell

     if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell) -eq $null )
        {
        Write-Host "Failed to load sharepoint snap-in. Could not proceed further, Aborting ...";   Exit
        }
   }
   Start-SPAssignment -Global
   $SPWeb  = Get-SPWeb -Identity $WebURL -ErrorAction SilentlyContinue
   $SPWebT = Get-SPWeb -Identity $TargetURL -ErrorAction SilentlyContinue  
   if($SPWeb -eq $null){ Write-Host "Unable to reach the provided URL, Aborting ..." ;Exit }
   if( ($SPWeb.Lists.TryGetList($SourceList) ) -eq $Null){ 
   Write-Host "The list $SourceList is not availible, Aborting ..."; Exit }
   $SourceLists=$SPweb.lists["$SourceList"]
   if( ($SourceLists.Views["$SourceView"]) -eq $Null ){  Write-Host "View not available, Aborting ..." ;Exit }
   if($SPWebT -ne $null)
   {
      $list=$SPWebT.lists["$DestList"]
    if($list.BaseType -eq "DocumentLibrary")
    {     
    $view = $list.Views[$SourceView]
    if ($view -ne $null)
    {
      Write-Host "Updating existing view" -foregroundcolor Yellow -backgroundcolor Black
      $list.views.delete($view.ID)
      $list.update()
    }

    $Viewfields = $Sourcelists.Views[$SourceView].ViewFields.ToStringCollection()
    $viewRowLimit="100";
    $viewPaged=$true
    $viewDefaultView=$AsDefault

    # Setting the Query for the View
    $viewQuery = $Sourcelists.Views[$SourceView].Query
    $viewName = $SourceView

    # Finally – Provisioning the View

    try
    {
      $myListView = $list.Views.Add($viewName, $viewFields, $viewQuery, 100, $True, $False, "HTML", $False)
    }
    catch
    {
      Write-Host "Not all columns are availible in the target library" -foregroundcolor Yellow
    }

    # You need to Update the View for changes made to the view
    # Updating the List is not enough
    $myListView.DefaultView = $AsDefault
    $myListView.Update()
    $list.Update()

    Write-Host "$viewName added to Library $list"
  }
  }
$SPWeb.Dispose()
$SPWebT.Dispose()
}
