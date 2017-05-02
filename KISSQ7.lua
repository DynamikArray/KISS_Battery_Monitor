local versionInfo = "KISS Telemetry - v1.4"

local blnMenuMode = 0

local editMahMode = 0

-- mahTarget is used to set our target mah consumption and mahAlertPerc is used for division of alerts
local mahTarget = 1200
local mahAlertPerc = 90

-- OpenTX 2.0 - Percent Unit = 8 // OpenTx 2.1 - Percent Unit = 13
-- see: https://opentx.gitbooks.io/opentx-lua-reference-guide/content/general/playNumber.html
local percentUnit = 13

local lastMahAlert = 0

-- Fixes mahAlert not appearing after battery disconnect
local lastKnownMah = 0
local swHaptic --default for "Switch C", adjust as necessary (used in line 82)
local swHVal = 600 --default value for Haptic Logical Switch to engage, alter as necessary (0 to 1000)

local minV = 100.0

----------------------------------------------------------------
-- Custom Functions
----------------------------------------------------------------
local function getTelemetryId(name)
 field = getFieldInfo(name)
 if getFieldInfo(name) then return field.id end
  return -1
end

local data = {}
  data.fuelUsed = getTelemetryId("Fuel")


-------------------------------------------------------------------------
-- Utilities
-------------------------------------------------------------------------
-- Rounding Function
local function round(val, decimal)
    local exp = decimal and 10^decimal or 1
    return math.ceil(val * exp - 0.5) / exp
end

--MahAlert and Logging of last Value Played
local function playMahPerc(percVal)
	if swHaptic < swHVal then
		playHaptic(100,100,PLAY_BACKGROUND)
	else
		playNumber(percVal,percentUnit)
	end
  lastMahAlert = percVal  -- Set our lastMahAlert
end

local function playCritical(percVal)
	if swHaptic < swHVal then
		for i = 1,7 do
			playHaptic(30,30,PLAY_BACKGROUND)
		end
	else
		playFile("batcrit.wav")
	end
  lastMahAlert = percVal  -- Set our lastMahAlert
end





local function playAlerts()

    percVal = 0
    curMah = getValue(data.fuelUsed)
	swHaptic = getValue('sc')

    if curMah ~= 0 then
      percVal =  round(((curMah/mahTarget) * 100),0)

      if percVal ~= lastMahAlert then
        -- Alert the user we are in critical alert
        if percVal > 100 and percVal % 2 == 0 then
          playCritical(percVal)
        elseif percVal > 90 and percVal < 100 then
          playMahPerc(percVal)
        elseif percVal % mahAlertPerc == 0 then
          playMahPerc(percVal)
        end
      end
    end

end

local function drawAlerts()

  percVal = 0

  -- Added to fix mah reseting to Zero on battery disconnects
  tmpMah = getValue(data.fuelUsed)

  if tmpMah ~= 0 then
    lastKnownMah = tmpMah
  end

  -- The display of MAH data is now pulled from the lastKnownMah var which will only
  -- be reset on Telemetry reset now.
  
  percVal =  round(((lastKnownMah/mahTarget) * 100),0)
  lcd.drawText(5, 9, "USED: "..lastKnownMah.."mah" , MIDSIZE)
  lcd.drawText(90, 23, percVal.." %" , MIDSIZE)

end


local function doMahAlert()
  playAlerts()
  drawAlerts()
end

local function draw()
  drawAlerts()
end


----------------------------------------------------------------
--
----------------------------------------------------------------
local function init_func()
  doMahAlert()
end
--------------------------------


----------------------------------------------------------------
--  Should handle any flow needed when the screen is NOT visible
----------------------------------------------------------------
local function bg_func()
  playAlerts()
end
--------------------------------

function round(num, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

----------------------------------------------------------------
--  Should handle any flow needed when the screen is visible
--  All screen updating should be done by as little (one) function
--  outside of this run_func
----------------------------------------------------------------
local function run_func(event)




  if blnMenuMode == 1 then
    --We are in our menu mode

    if event == 32 then
      --Take us out of menu mode
        blnMenuMode = 0
    end

    -- Respond to user KeyPresses for mahSetup
      if event == EVT_PLUS_FIRST or event == EVT_ROT_RIGHT then
        mahAlertPerc = mahAlertPerc + 5
      end

      -- Long Presses
      if event == 68 then
        mahAlertPerc = mahAlertPerc + 1
      end

      if event == EVT_MINUS_FIRST or event == EVT_ROT_LEFT then
        mahAlertPerc = mahAlertPerc - 5
      end

      -- Long Presses
      if event == 69 then
        mahAlertPerc = mahAlertPerc - 1
      end


    lcd.clear()

    lcd.drawScreenTitle(versionInfo,2,2)
    lcd.drawText(20,15, "Set Notification")
    lcd.drawText(25,28,"Every "..mahAlertPerc.." %",MIDSIZE)
    lcd.drawText(20,45, "Use wheel to change",SMLSIZE)

    lcd.drawText(15, 58, "Press [MENU] to return",SMLSIZE)

  else

	  if event == 32 then
		--Put us in menu mode
		  blnMenuMode = 1
		  editMahMode = 0
	  end
	  
	  if event == EVT_ENTER_BREAK then
		if editMahMode == 1 then
			editMahMode = 0
		else
			editMahMode = 1
		end
	  end

    -- Respond to user KeyPresses for mahSetup
      if editMahMode == 1 and event == EVT_ROT_RIGHT then
        mahTarget = mahTarget + 25
      end

      if editMahMode == 1 and event == EVT_ROT_LEFT then
        mahTarget = mahTarget - 25
      end


    --Update our screen
      lcd.clear()

      lcd.drawScreenTitle(versionInfo,1,2)

      lcd.drawGauge(6, 23, 70, 15, percVal, 100)
      lcd.drawText(6, 41, "Target mAh : ",SMLSIZE)
	  if editMahMode == 0 then
		lcd.drawText(65, 41, mahTarget,SMLSIZE)
	  else
		lcd.drawText(65, 41, mahTarget,INVERS)
	  end
	  
	  local vfas = getValue("VFAS")
	  if vfas < 0 then vfas = 0 end
	  lcd.drawText(95, 41, round(vfas, 2).."V", SMLSIZE)
	  
	  if vfas > 0 and vfas < minV then minV = vfas end
	  
	  if(minV < 100) then
		lcd.drawText(76, 49, "min:"..round(minV, 2).."V", SMLSIZE)
	  else
		lcd.drawText(76, 49, "min:0V", SMLSIZE)
	  end

      lcd.drawText(7, 58, "Press [MENU] for more",SMLSIZE)

      draw()
      doMahAlert()
  end

end
--------------------------------

return {run=run_func, background=bg_func, init=init_func  }