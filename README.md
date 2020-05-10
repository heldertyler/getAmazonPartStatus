# getAmazonPartStatus
A simple Powershell script to determine if a given amazon product is currently a good buy

## Purpose
During times of COVID-19 with production and manufacturing facilities not operating at peak capacity, prices of good such as pc components and other technology may inherantly become more expensive. getAmazonPartStatus.ps1 was created to help determine if now is a good time to buy.

## How it works
Using GET requests, we retrieve the product name, current price, and availability of the product directly from that amazon uri provided. Next we retrieve the lowest price recorded for the product from camelcamelcamel.

Create txt file with following format for use with -FilePath argument (See Example: partList.txt):
```
<tag with no spaces>|<Amazon Uri>
```

## Features
* Gets tag and Amazon Uri's from txt file
* If amazon believes we are a robot, script will download the captcha image to the desktop of the user running the script and open it with your default image viewer. After passing the captcha test, the image is deleted.
* Gets product information directly from the amazon uri provided. Supports Amazon direct product Uri's and cart Uri's.
* Gets lowest price information from camelcamelcamel.com (Must have minimum timeout of 20 sec between requests, else they get refused)
* Returns unformatted PowerShell object

## Example
```
PS C:\Users\user> .\Documents\WindowsPowerShell\getAmazonPartStatus.ps1 -FilePath $env:USERPROFILE\Desktop\partList.txt -Timeout 20 | Format-Table -AutoSize                                                                                                                           
INFO: Amazon Suspects That We Are A Robot. Starting Catcha Test                                                                         
Please Enter CAPTCHA: FNPNNR                                                                                                             
INFO: Captcha Test Passed
ERROR: price_inside_buybox element not found for case. Part May No Longer Be For Sale. Setting Value to 0
ERROR: price_inside_buybox element not found for mb. Part May No Longer Be For Sale. Setting Value to 0

Name                                                                                                                                                                            Part       CurrentPrice LowestPrice GoodValue InStock
----                                                                                                                                                                            ----       ------------ ----------- --------- -------
NZXT H510 - CA-H510B-B1 - Compact ATX Mid-Tower PC Gaming Case - Front I/O USB Type-C Port - Tempered Glass Side Panel - Cable Management System - Water-Cooling Ready - Black  CASE       $0           $69.00      NA        Available from these sellers.
AMD Ryzen 9 3950X 16-Core, 32-Thread Unlocked Desktop Processor, Without Cooler                                                                                                 CPU        $719.99      $719.99     BEST      Only 10 left in stock - order soon.
Noctua NH-D15, Premium CPU Cooler with 2x NF-A15 PWM 140mm Fans                                                                                                                 CPU_COOLER $89.95       $79.50      GOOD      Only 7 left in stock - order soon.
ASUS ROG STRIX GeForce RTX 2080TI Overclocked 11G GDDR6 HDMI DP 1.4 USB Type-C Gaming Graphics Card (ROG-STRIX-RTX-2080TI-O11G)                                                 GPU        $1,279.99    $1,153.48   WAIT      In stock on May 21, 2020. Order it now.
ASUS Tuf Plus Gaming AM4 AMD X570 ATX DDR4-SDRAM Motherboard                                                                                                                    MB         $0           $227.53     NA        Available from these sellers.
G.SKILL TridentZ RGB Series 32GB (2 x 16GB) DDR4 3200Mhz DIMM CAS 16 F4-3200C16D-32GTZR                                                                                         MEMORY     $159.99      $139.99     GOOD      In Stock.
SilverStone Technology 850W Computer Power Supply PSU Fully Modular with 80 Plus Gold & 140mm Design Power Supply (SST-ST85F-GS-V2)                                             PSU        $147.65      $147.65     BEST      In Stock.
```
