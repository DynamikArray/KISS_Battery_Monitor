# Version 1.3.1

# KISS_Battery_Monitor
Open TX Telemetry Script for reading and announcing battery mAh consumption.  Uses the mAh consumption as reported from KISS 24a ESC as Telemetry data and accepts a configurable user Target mAH and Percentage Notification.  The pilot can target how much mAh they intend to use that flight, adjust this value as needed, and this will be used as the "Battery".  The Percentage Notification allow for the pilot to receive verbal indication of the "Battery" at the desired intervals.  During the final 10% of the "Battery" an indication is given at every 1%.   After 100% usage of the "Battery" each additional % used will trigger a "Battery Critical" alarm.

# SCREENSHOTS
See the WIKI for more detailed information and screenshots on installation, and usage.  https://github.com/DynamikArray/KISS_Battery_Monitor/wiki


# REQUIREMENTS
* KISS 24a ESC
* OPEN TX 2.1 Firmware on Taranis

# INSTALLATION:
Download the latest release from the https://github.com/DynamikArray/KISS_Battery_Monitor/releases and place the file (KISS.lua) in the following directory on the SD_CARD of your Taranis.
``` SCRIPTS\TELEMETRY```  (if the TELEMETRY folder does not exist then you may need to create it).  

ADDITIONAL STEPS FOR SOME USERS
* Some users reported not having the battery critcal alarm sound file.  Since release  https://github.com/DynamikArray/KISS_Battery_Monitor/tree/v1.2.3 this issue has been addressed with the inclusion of the batcrit.wav file.  If your not getting the battery critical alarm, place the (batcrit.wav) if the  ``` SOUNDS\en ``` of your SD Card. (Or apporiate region ```SOUNDS\fr, SOUNDS\de, SOUNDS\nl, etc..```)

* If you are having issues after installation with sound playbacks not saying percentage, instead saying "miles per hour", "feet", or something other than "Percentage" then ensure you have the correct Open TX 2.1.X SOUND/SYSTEM files installed. Open TX sound packs are available for download here: http://voices-21.open-tx.org/

# SETUP:
Attach this script to one of your TELEMETRY screens inside your radio.

# USAGE
There are two parameters the Pilot may adjust as needed.
* Target mAh = The amount of mAh the pilot wants to consume.  
* Notification Percentage = The Percentages the pilot wants the verbal alerts to trigger.

On the main screen of the script, you may adjust the target mAh at anytime using by holding down either of the +/- keys to adjust the value.

Percentages Notification adjust may be accessed by pressing the [MENU] key.  On the Percentages Notification Screen you may adjust the Percentage using the +/- keys.  Pressing the [MENU] key again will bring you back to the main screen of this script.

# KNOWN ISSUES
- OpenTx2.2 imposed a 6 Charachter limit on the filename, so the .lua file needs to be renamed  - fixed in v.1.3.1
- The Telemetry data is not visible for viewing after RSSI loss (ie pilot lands and disconnects battery from multi rotor) - fixed in v.1.3.0 
