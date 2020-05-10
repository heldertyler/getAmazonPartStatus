param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$FilePath,

        [Parameter(Mandatory=$false, Position=1)]
        [int]$Timeout=30
)

if (! (Test-Path -Path $FilePath)) {
  throw "ERROR: $FilePath is not a valid file"
}

$uris = @{}
$results = @()
$counter = 0

foreach ($line in (Get-Content -Path "$FilePath")) {
  $k, $v = $line.split('|')
  $uris["$k"] = "$v"
}

foreach ($part in ($uris.Keys | sort)) {
    $part_obj = New-Object -TypeName psobject
    $counter++

    $part_uri = $uris["$part"]
    $part_id = ($part_uri | Select-String -Pattern ".+/(product|dp)/([A-Z0-9]{10})/.+").Matches.Groups[2].value
    $ccc_uri = "https://camelcamelcamel.com/product/" + "$part_id"

    $amazon_response = Invoke-WebRequest -Method Get -Uri "$part_uri"
    Write-Verbose "$part -> amazon -> $($amazon_response.StatusCode)"

    if (($amazon_response.ParsedHtml.Title) -eq "Robot Check") {
      Write-Output "INFO: Amazon Suspects That We Are A Robot. Starting Catcha Test"
      $captcha_img = "$env:USERPROFILE\Desktop\captcha.jpg"
      $captcha_uri = $amazon_response.ParsedHtml.IHTMLDocument3_documentElement.getElementsByTagName("img") | Where-Object {$_.src -like "*captcha*"} | Select-Object -ExpandProperty Src

      Write-Verbose "GET CAPTCHA Image -> $captcha_uri"
      Invoke-WebRequest -Method Get -Uri $captcha_uri -OutFile $captcha_img
      Invoke-Item -Path $captcha_img

      $captcha = Read-Host -Prompt "Please Enter CAPTCHA"

      $captcha_response = Invoke-WebRequest -Method Post -Uri "https://amazon.com/errors/validateCaptcha" -Body $captcha
      Write-Verbose "$part -> amazon -> $($captcha_response.StatusCode)"

      if ($captcha_response.StatusCode -eq 200) {
        Write-Output "INFO: Captcha Test Passed"
        Remove-Item -Path $captcha_img -Force
        $amazon_response = Invoke-WebRequest -Method Get -Uri "$part_uri"
        Write-Verbose "$part -> amazon -> $($amazon_response.StatusCode)"
      }
    }

    $title = $amazon_response.ParsedHtml.IHTMLDocument3_getElementById("productTitle").textContent

    try {
      try {
        $current_price = ($amazon_response.ParsedHtml.IHTMLDocument3_getElementById("price_inside_buybox").textContent |
                         Select-String -Pattern '(\d?,?\d+\.\d+)').Matches.Groups[0].value
      }
      catch {
        $current_price = ($amazon_response.ParsedHtml.IHTMLDocument3_getElementById("newBuyBoxPrice").textContent |
                         Select-String -Pattern '(\d?,?\d+\.\d+)').Matches.Groups[0].value
      }
    }
    catch {
      Write-Output "ERROR: price_inside_buybox element not found for $part. Part May No Longer Be For Sale. Setting Value to 0"
      $current_price = 0
    }

    $instock = $amazon_response.ParsedHtml.IHTMLDocument3_getElementById("availability").textContent

    if (!($instock)) {
      $instock = "NA"
    }

    $amazon_response.Dispose()

    $ccc_response = Invoke-WebRequest -Method Get -Uri "$ccc_uri"
    Write-Verbose "$part -> ccc -> $($ccc_response.StatusCode)"

    $lowest_price = ($ccc_response.ParsedHtml.IHTMLDocument3_documentElement.getElementsByClassName("lowest_price")[0].outerText | 
                     Select-String -Pattern '(\d?,?\d+\.\d+)').Matches.Groups[0].value
    $ccc_response.Dispose()

    if ($current_price -gt $lowest_price) { 
        $diff = ($current_price - $lowest_price) -le 20

        if ($diff) {
             $good_value = "GOOD"
          }
        else {
             $good_value = "WAIT"
          }
      }

    elseif ($current_price -le $lowest_price) {
        if ($current_price -ne 0) {
          $good_value = "BEST"
        }
        else {
          $good_value = "NA"
        }
    }

    $part_obj | Add-Member -MemberType NoteProperty -Name Name -Value "$title"
    $part_obj | Add-Member -MemberType NoteProperty -Name Part -Value $part.ToUpper()
    $part_obj | Add-Member -MemberType NoteProperty -Name CurrentPrice -Value "`$$current_price"
    $part_obj | Add-Member -MemberType NoteProperty -Name LowestPrice -Value "`$$lowest_price"
    $part_obj | Add-Member -MemberType NoteProperty -Name GoodValue -Value "$good_value"
    $part_obj | Add-Member -MemberType NoteProperty -Name InStock -Value $instock.Trim()

    $results += $part_obj

    #CCC Throws http error code 429 Too Many Requests. Request Rate Must Be Slowed. Default: 30
    if (($uris.Count) -ne $counter) {
      Start-Sleep -Seconds $Timeout
    }
}

$results