# Volvo-VIDA
Reverse engineering Volvo VIDA for retrieving information from the CAN-bus.

With the files in this repository, a lot of information buried deep inside VIDA can be easily exported. It's also possible to read Diagnostic Trouble Codes (DTCs)! 

The repositories and internet articles below have been a great help for this project.
- alfaa123 - <a href="http://github.com/Alfaa123/Volvo-CAN-Gauge" target=_blank>Volvo-CAN-Gauge</a>
- <a href="http://www.stevediraddo.com/2019/01/13/volvo-canbus-tinkering/" target=_blank>Volvo CANBUS Tinkering</a>
- <a href="https://waal70blog.wordpress.com/2015/12/02/the-can-network-on-a-volvo-part-three-message-interpretation/" target=_blank>CAN Network on a Volvo - Part three - Request Message format</a> (their github repo might be interesting as well: <a href="https://github.com/waal70/S60CAN" target=_blank>S60CAN</a>)


### Setup:
- Volvo C30 T5 2008
- VIDA 2014D running on Windows 7
- VIDA databases running in a MSSQL Docker container for easier/faster PowerShell access (optional)
- DICE CANBus sniffer (optional)

## VIDA
As VIDA is able to diagnose cars without an internet connection, all the data needed for this communication is presumably stored locally, alongside VIDA itself. A prime candidate for this storage is MSSQL. In `C:\Vida\`, there's a file called "VidaConfigApplication.Exe.Config", which contains the following SQL credentials:

> DBUser: sa<br>
> DBPass: GunnarS3g3

Using these credentials, you can open the SQL databases using something like Microsoft SQL Management Studio. The most important databases are `carcom` and `DiagSwdlRepository`, these contain information that we are most interested in. As the name would suggest, the carcom database (probably) contains all the car-information that VIDA uses to communicate with any connected vehicles. Some of the most important tables are:

- T100_EcuVariant
- T141_Block
- T144_BlockChild
- T150_Blockvalue
- T191_TextData  

All the databases also contain SQL 'Stored Procedures' and (table) Functions. These procedures are called from VIDA, and contain certain steps to retrieve information from the different SQL databases and tables. For example, when selecting a car on the Vehicle Profile screen in VIDA, the procedure 'GetCompatibleProfiles' from the database CarCom is called. The GetCompatibleProfiles procedure consists of a SQL query to select the vehicle-model, year, engine, transmission, steering config, market etc. Subsequently clicking on 'Diagnostics' calls the procedure 'GetEcuTypeDescriptions', where all the ECUs (for the vehicle selected in Vehicle Profile) are retrieved. That query looks like: `SELECT DISTINCT identifier, description from T102_EcuType WHERE identifier <> 0`. The steps for every single action performed in VIDA can be found in these procedures.

With the information in these procedures and functions, I was able to make some queries myself (which can be found in this repo) that can be used to easily select the ECU identifiers and hex values to retrieve ecu-related data from my car. Below some examples which you can retrieve from your vehicle using these CAN-values:

**ECM:**<br>
- A/C Pressure
- Boost Pressure
- Lambda sensor readings
- Engine speed
- Vehicle speed

**BCM:**<br>
- Yaw sensor 
- Velocity of car
- Acceleration of each wheel in m/s²

**DIM:**<br>
- Fuel level
- Hours since last service

This is just a short list and does not include every single parameter you could request from the vehicle. The ECM alone has 250+ rows of parameters for example.

### Storage 
To keep the necessary storage of VIDA down, the developers opted to compress images, scripts, etc and store them as hex-strings in the SQL databases. We can take this hexstring, remove the `0x` at the front and write the remaining bytes directly to a file. In case of images, giving this file the correct extension (like jpg) makes it a valid image right away. Multiple image formats are used:
- JPEG
- GIF
- CGM
- SVG
- JPG 

Exporting Scripts is a bit more involved. The content of the files is again stored as a hexstring in the database `[DiagSwdlRepository].[dbo].ScriptContent` -> column `XMLDataCompressed`. Writing the raw bytes to a file, a zip file is revealed. After unzipping this archive a single file is stored within, which is an XML file. What the scripts are used for exactly, is currently unknown. Most of the parameter values do not line up with the values I retrieved from the SQL databases itself.

The documents which can be found under the information tab (Parts catalog, repair, installation instructions, specifications, etc) are also stored as compressed XML in SQL. These can be exported the same way as the scripts above. In the exported XML files, there are references to images and text, which VIDA uses to create the pages you can see.      


### VIDA Diagnostic log

After prying around more in the VIDA files, I found a diagnostic-log which stores pretty much all user-actions that are performed on the Vehicle Profile and Car Communication pages. As an example, below you can see the log which is generated when VIDA is started, a vehicle profile has been selected and the user navigated to Diagnostics -> Vehicle Communication -> Select ECM -> Expand ECM. I've marked interesting information in bold.  

#### Select Vehicle Profile:
> 16:07:25,573 [SoftwareProductI][001][Event]   Database: DiagSwdlRepository, SP: **GetSWDLSupportedVehicleModels**<br>
> 16:07:25,635 [SoftwareProductI][001][Event]   Database: DiagSwdlRepository, SP: GetSWProduct, SwProdId: 30668295, Culture: en-GB<br>
> 16:07:25,714 [DotNetPreLoader ][001][Info]    PreLoad time: 00:00:01.2031250<br>

#### Navigate to Diagnostics tab:
> 16:07:41,557 [UiBase          ][001][User]    DIAGNOSTICS tab entered. VIN: YV1MK67**********<br>
> 16:07:41,573 [CarComRepository][001][Event]   Database: carcom, SP: **vadis_GetHwSettings**, VehicleProfile: 0b00c8af83aff6c7,0b00c8af83d4c9a2,0b00c8af83aff6ca,<br>
> 16:07:41,870 [VehicleInformati][001][User]    Activate VehicleInformationForm<br>
> 16:07:41,932 [CarStatus       ][00C][Info]    Init CarStatus<br>
> 16:07:41,964 [NavImageProvider][001][Info]    Database: DiagSwdlRepository, SP: **GetNavImage**<br>
> 16:51:28,529 [NavImageProvider][001][Event]   Loading image 'http:\\localhost\Vida\Diagnostics\navimage\0800c8af847e9b53_0_0.cgm'<br>
> 16:51:28,544 [VehicleInformati][001][User]    Activate VehicleInformationForm <br>
> 16:51:28,544 [CarStatus       ][001][Info]    Start reading CarStatus<br>
> 16:51:28,544 [CarStatusWF     ][001][Info]    CarStatus read conditions not correct.<br>
> 16:51:29,451 [FaultCounterForm][001][User]    Tab: Vehicle communication selected (DiagnosticManager)<br>
> 16:51:29,513 [CarStatus       ][001][Info]    Stop reading CarStatus<br>
> 16:51:29,716 [DiagnosticManage][001][Event]   Activate VehCommForm<br>
> 16:51:29,763 [CarStatus       ][001][Info]    Init CarStatus<br>
> 16:51:29,810 [CarComRepository][001][Event]   Database: CarCom, SP: **vadis_GetEcuTypeDescriptions**<br>


#### Click on Vehicle communication under Diagnostics tab:
> 16:51:31,544 [ScriptProvider  ][001][Event]   Database: DiagSwdlRepository, SP: **GetScript**,  Type: 'VehCommSpecification' ScriptId: '' Language: 'en-US' EcuType: '284101' Profile: '0b00c8af83aff6c7,0b00c8af83d4c9a2,0b00c8af83aff6ca,'<br>
> 16:51:31,576 [ScriptProvider  ][001][Info]    Fetched script: 'VCC-235622-1 1.14' title: 'VehCom, P1 ECM Bosch ME9 03w38/47-'<br>
> 16:51:31,591 [Script          ][001][Info]    Running script: **'VCC-235622-1 1.14'** title: 'VehCom, P1 ECM Bosch ME9 03w38/47-'<br>
> 16:51:31,591 [ScriptProvider  ][001][Event]   Database: DiagSwdlRepository, SP: GetValidLinksForSelected<br>
> 16:51:32,326 [CarComRepository][001][Event]   Database: CarCom, SP: vadis_GetDefaultEcuVariants, Profile: 0b00c8af83d4c9a5<br>
> 16:51:32,341 [VehicleCommunica][001][Warning] No data in session for ecu '**284101**', using default diagnostic number '31211150 AA'<br>
> 16:51:32,341 [CarComRepository][001][Event]   Database: CarCom, SP: general_GetEcuId, EcuId: **31211150 AA**, Result: **1310**<br>

As you can see, when VIDA is started and you select the correct vehicle profile / VIN, VIDA uses that profile to get the vehicle (nav) image, a profile, default ECU descriptions etc. Using this EcuID, it will provide a list of parameters using the stored procedure (SP): general_GetEcuID. The ID returned is *1310*, which corresponds to default diagnostic (ecu) number: *31211150 AA* according to `[carcom].[dbo].EcuVariant`. Below you can see how VIDA gets the selected parameter, Boost Pressure as an example, using a stored procedure. 
 
#### Selecting parameter on Vehicle Communication page
> 16:51:39,232 [CarComRepository][001][Event]   Database: CarCom, SP: vadis_GetParameterData, EcuId: 1310, TextId: 5249, Id: **129D**<br>
> 16.51.39,247 [ScriptProvider][001][Event]   Database:  DiagSwdlRepository, SP: GetValidLinksForSelected<br>

The Stored Procedure `vadis_GetParameterData` returns the text `PVDKDS : Pressure in front of throttle valve of pressure sensor` and `Boost Pressure` as a shorter name, and most importantly the hex value 0x12, 0x9D. Using this hex value in a Diagnostic CAN request, the current boost pressure is returned by the ECM.

To recap:
- Database: CarCom
- Stored Procedure: vadis_GetParameterData
- EcuID: 1310 (31211150 AA)
- TextID: 5249 (`SELECT * FROM [carcom].[dbo].[T191_TextData] where fkT190_Text = '5249'` returns Boost Pressure in 17 languages)
- Id: 129D (Hex parameter value)

The file `Get-ParameterDataUsingEcuAndTextId.sql` in this repo is very similar to this specific Stored Procedure. The file `Get-CANValuesUsingEcuId.sql` retrieves all parameters for a given ECU. Both of these SQL-queries also add the RequestType and the conversion factor.

![](images/Get-CANValuesUsingEcuId.png?raw=true "CAN Values for ECU 284101, showcasing Boost Pressure")


## CAN messages
The Volvo VIDA protocol is a diagnostic protocol similar to UDS. However, unlike UDS the VIDA protocol, the first byte is a DLC and the second byte is the ECU address. An example can be found below:

**Request**: ID: `0x000FFFFE` Data: `CD 7A A6 12 9D 01 00 00`
- 0x000FFFFE is the CAN diagnostic address
- CD is C8 + number of significant bytes to follow.
- 7A is the address of the ME7 ECU (ECM)
- A6 is the "Read Current Data By Identifier" command
- 12,9D is the Boost Pressure parameter
- 01 is probably "Send the record once"
- 00s are padding the rest of the frame to keep it 8 bytes long

**Response:** ID `0x00400021` Data: `CD 7A E6 12 9D 95 00 00`
- 00400021 is the CAN address for response
- CD is C8 + number of significant bytes to follow.
- 7A is the address of the ME7 ECU
- E6 is response to A6
- 12,9D is confirming the request parameter
- 95 is the return value
- 00s are padding

More information on this can be found in Alfaa123's Volvo-CAN-Gauge repository and in waal70's blogposts.

There are more commands besides `A6`. The requestType returned in the earlier SQL queries, correspond to these commands. `A6` is Read Current Data by Identifier, which corresponds to the 'REID' (Request Extended ID (by Identifier)?) requestType. A different command is `AE`, which is 'Read DTC'. Sending this command to a ECU makes it spit out any stored DTC codes (if any). A list of all commands can be found in `ECU-commands.txt` in this repo. 

With the CAN values exported from VIDA using the scripts in this repo, we can easily retrieve a ton of information from the different ECUs in our car. Some examples:

- (ECM) Battery Voltage: `0x000FFFFE CD 7A A6 10 0A 01 00 00` -> Response: `0x00400021 CD 7A E6 10 0A 94 00 00` -> 96 -> 150
- (DIM) Total Fuel Level: `0x000FFFFE CD 51 A6 00 01 01 00 00` -> Response: `0x00600009 CD 51 E6 00 01 6A 00 00` -> 6A -> 106
- (DIM) Hours since Service: `0x000FFFFE CD 51 B9 07 00 00 00 00` -> Response: `0x00600009 F9 11 F9 00 D9 00 00 00` -> D9 -> 217

As seen above, the Response ID for every ECU is different. Also, the command `B9` (Read Data Block By Offset) returns its response in message byte 5 instead of 6 (command A6). The responses are all in hex, so these have to be converted to decimal.

The response values are not in the correct unit yet and/or do not have the correct scaling applied. This is where the Conversion Factor comes in to play. In the exported Parameter data, it also shows the unit of the final response and a mathematical calculation how to scale the response correctly. For the above parameters:

- (ECM) Battery Voltage: `x*1/10.6113989637306` -> `150*1/10.6113989637306` -> 14.14 Volts
- (DIM) Total Fuel Level: `x/2` -> `106/2` -> 53 Litres
- (DIM) Hours since Service: `x*1` -> `217*1` = 217 Hours

Not all ECUs in a vehicle are connected to the same CAN-bus. For example, the ECM in my car runs at 500kbps (high speed), whereas the DIM (Driver Information Module, gauge cluster) only responds to CAN messages sent on the 125kbps bus. (low speed) An overview of which ECU is connected to which CAN-bus can be found in VIDA.       

### CAN-bus sniffing
When I started this project, I used a canbus sniffer to retrieve information from the car. This worked but it took a lot of time, mostly because it's not directly obvious which CAN-message is associated with a certain function in the car. Having found all the ECU parameters data in SQL, I have not needed to sniff for messages on the bus anymore.

## Scripts
Below you can find more information about the PowerShell scripts in this repo and how to use them.

All scripts have been tested in PowerShell Version 5.1 and can be used in VS Code, or from the deprecated PowerShell ISE. The scripts ask for the SQL credentials on first-run, these can be found above. Some scripts might also ask to enter an export path, or ask for a path to certain files. Make sure that the path you enter exist, otherwise exporting or reading data will fail. You can stop execution of a script by pressing `Ctrl + C`.

**Parameters**<br>
Using the script `Get-ParametersForAllECUs.ps1`, all ECU Parameters for a given car/model can be exported. These ECU Identifiers contain data that can subsequently be sent on the CAN-bus to retrieve engine related information, like boost pressure, intake temperature, etc. The results are exported to multiple CSV files.

**Images**<br>
The script `Export-VidaPictures.ps1` exports all (compressed) pictures in VIDA to their respective file extension. This script can take a couple of minutes to finish. Should return ~92692 pictures, just under 3GB in total. 

**Scripts**<br>
In my experience, the parameter values that the VIDA-Scripts returned did not match the expected values but I might be missing something. As the parameter values (exported using `Get-ParametersForAllECUs.ps1`) did return the correct values, I had no reason to look into the scripts anymore. There might still be some interesting info there, so the PowerShell scripts to export the scripts and parse them, is still provided:

The script `Export-ScriptsToXML.ps1` prompts to enter a vehicle model (like: C30), and then exports all the VIDA-Scripts for that model (all model years) to a certain path (like C:\temp\export). If you want to export just one model year, enter "C30 2008".

With the scripts `Parse/Search-XMLFiles.ps1`, you can easily search through the exported scripts. 

## Disclaimer

There might be some scripts or parameter values which you can use to communicate/interfere with safety systems and/or deploy airbags, enter crash mode, etc. I am not in anyway responsible for any damage inflicted to your vehicle using the parameter values and/or scripts which you can export using the files in this repo.<br>

If you have any questions about the information provided in this repo or if you have any more information about VIDA, do not hesitate to get in touch!    