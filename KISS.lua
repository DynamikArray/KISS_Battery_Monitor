local versionInfo = "KISS Telemetry Data - v1.3.1"

local blnMenuMode = 0
local source -- used for switch allocation
local swHVal -- selected switch value for evaluation

-- mahTarget is used to set our target mah consumption and mahAlertPerc is used for division of alerts
local mahTarget
local mahAlertPerc = 50  -- set first alert midway

-- OpenTX 2.0 - Percent Unit = 8 // OpenTx 2.1 - Percent Unit = 13
-- see: https://opentx.gitbooks.io/opentx-lua-reference-guide/content/general/playNumber.html
local percentUnit = 13

local lastMahAlert = 0

-- Fixes mahAlert not appearing after battery disconnect
local lastKnownMah = 0
local swHaptic --default for "Switch C", adjust as necessary (used in line 70)
local editMode = not editMode
local saved = 0
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
	if getValue(source) < swHVal then
		playHaptic(100,100,PLAY_BACKGROUND)
	else
		playNumber(percVal,percentUnit)
	end
  lastMahAlert = percVal  -- Set our lastMahAlert
end

local function playCritical(percVal)
	if getValue(source) > swHVal then
		for i = 1,7 do
			playHaptic(30,30,PLAY_BACKGROUND)
		end
	else
		playFile("batcrit.wav")
	end
  lastMahAlert = percVal  -- Set our lastMahAlert
end

local function valueIncDec(event,value,min,max,step,cycle)
    if editMode then
      if event==EVT_PLUS_FIRST or event==EVT_PLUS_REPT then
        if value<=max-step then
          value=value+step
		 elseif cycle==true then
			value = min
        end
      elseif event==EVT_MINUS_FIRST or event==EVT_MINUS_REPT then
        if value>=min+step then
          value=value-step
		 elseif cycle==true then 
		value = max
        end
      end
    end
    return value
  end

local function fieldIncDec(event,value,max,force)
    if editMode or force==true then
      if event==EVT_PLUS_FIRST then
        value=value+max
      elseif event==EVT_MINUS_FIRST then
        value=value+max+2
      end
      value=value%(max+1)
    end
    return value
  end
  
 local function getFieldFlags(p)
    local flg = 0
    if activeField==p then
      flg=INVERS
      if editMode then
        flg=INVERS+BLINK
      end
    end
    return flg
  end

local function playAlerts()

    percVal = 0
    curMah = getValue(data.fuelUsed)
	
    if curMah ~= 0 then
      percVal =  round(((curMah/mahTarget) * 100),0)

      if percVal ~= lastMahAlert then
        -- Alert the user we are in critical alert
        if percVal > 100 and percVal % 2 == 0 then -- battery critical in 2% steps
          playCritical(percVal)
        elseif percVal > 90 and percVal < 100 and percVal % 5 == 0 then  -- alert at 90 / 95 / 100
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
  lcd.drawText(5, 10, "USED: "..lastKnownMah.."mah" , MIDSIZE)
  lcd.drawText(90, 30, percVal.." %" , MIDSIZE)

end


local function doMahAlert()
  playAlerts()
  drawAlerts()
end

local function draw()
  drawAlerts()
end


----------------------------------------------------------------
-- Initial load - bootstrap for haptic configure values
----------------------------------------------------------------
local function init_func()

local f = io.open("/SCRIPTS/"..'switch', "r")
	if not f then
		f = io.open("/SCRIPTS/"..'switch', "w")
		io.write(f,'92 512')
		source = 92
		swHVal = 512
	else
		source = tonumber(io.read(f,2))
		io.seek(f,2)
		swHVal = tonumber(io.read(f,4))
	end
io.close(f)

local f = io.open("/SCRIPTS/"..'mah', "r")
	if not f then
		f = io.open("/SCRIPTS/"..'mah', "w")
		io.write(f,' 900')
		mahTarget = 900
	else
		mahTarget = tonumber(io.read(f,4))
	end
io.close(f)

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


----------------------------------------------------------------
--  Should handle any flow needed when the screen is visible
--  All screen updating should be done by as little (one) function
--  outside of this run_func
----------------------------------------------------------------
local function run_func(event)


  if blnMenuMode == 1 then
    --We are in our first menu mode
	
    if event == 32 then
      --Cycle through to menu mode #2
        blnMenuMode = 2
		activeField = 0
		editMode = not editMode
    end
	
    -- Respond to user KeyPresses for mah percentage alert
    mahAlertPerc = valueIncDec(event, mahAlertPerc, 0, 100, 5)

      
	-- Draw Screen
    lcd.clear()
    lcd.drawScreenTitle(versionInfo,2,3)
    lcd.drawText(35,10, "Set Percentage Notification")
    lcd.drawText(70,20,"Every "..mahAlertPerc.." %",MIDSIZE)
    lcd.drawText(66, 35, "Use +/- to change",SMLSIZE)
	lcd.drawText(30, 55, "Press [MENU] for more options",SMLSIZE)

  elseif blnMenuMode ==2 then 
		fieldMax = 1

		if event == 32 then
    --Put us in Main Telemetry Screen
		blnMenuMode = 0
		activeField = 0
		editMode = not editMode
	end

	lcd.clear()
	lcd.drawScreenTitle(versionInfo,3,3)
	lcd.drawText(12,10,'Haptic Configuration',MIDSIZE)
	lcd.drawText(12,30,'Switch Selection:  ')
	lcd.drawSource(lcd.getLastPos(),30, source, getFieldFlags(0))
	lcd.drawText(12,42,'Engage Value > ')
	lcd.drawText(lcd.getLastPos(),42, round(swHVal/10.24)..'%', getFieldFlags(1))
	lcd.drawText(12, 54 ,'Switch Value:  ',SMLSIZE)
	lcd.drawText(lcd.getLastPos(),54,(getValue(source)/10.24)..'%',SMLSIZE)
	lcd.drawRectangle(140,25,70,26,SOLID)
	lcd.drawText(145, 28 ,'Haptic Test')
	lcd.drawText(134, 55, "[MENU] to return",SMLSIZE)
	if getValue(source) > swHVal then
		hTest = 'ON'
	else
		hTest = 'OFF'
	end
	lcd.drawText(168, 37,hTest,MIDSIZE)
	
	if event == EVT_ENTER_BREAK then
		editMode = not editMode
		f = io.open("/SCRIPTS/"..'switch', "w")
		io.write(f,string.format("%2d",source),string.format("%4d",swHVal))
		io.close(f)
		
	end
	if editMode then
		if activeField == 0 then
			source = valueIncDec(event, source, 92, 99, 1,true)
		else
			swHVal = valueIncDec(event, swHVal, -1045,1045, 10)
		end
	else
		activeField = fieldIncDec(event, activeField, fieldMax, true)
	end	
	
	
	else
	if event == EVT_MENU_BREAK then
	 --Put us in menu mode #1
	 blnMenuMode = 1
	 activeField = 0
	 editMode = not editMode
	end
    -- Respond to user KeyPresses for mahSetup
	if event == EVT_ENTER_BREAK then
	 f = io.open("/SCRIPTS/"..'mah', "w")
	 io.write(f,string.format("%4d",mahTarget))
	 io.close(f)
	 
	 saved = 1
	elseif event ~= EVT_ENTER_BREAK and event ~=0 then
	 mahTarget = valueIncDec(event, mahTarget, 0, 5000, 10)
	 saved = 0
	end
	
	--Update our screen
      lcd.clear()

      lcd.drawScreenTitle(versionInfo,1,3)

      lcd.drawGauge(6, 25, 70, 20, percVal, 100)
      lcd.drawText(130, 10, "Target mAh : ",MIDSIZE)
      lcd.drawText(160, 25, mahTarget,MIDSIZE)
      lcd.drawText(130, 40, "Use +/- to change",SMLSIZE)
	  if saved == 0 then
		lcd.drawText(105, 48, "[Enter] to Store Target",SMLSIZE)
	  else
	   lcd.drawText(134, 48, "mAh Taget Saved",SMLSIZE+INVERS)
	  end
      lcd.drawText(30, 55, "Press [MENU] for more options",SMLSIZE)

      draw()
      doMahAlert()
  end

end
--------------------------------

return {run=run_func, background=bg_func, init=init_func}
