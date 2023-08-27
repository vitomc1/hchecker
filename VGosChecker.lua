script_version("5.0")
script_version_number(16)
require "lib.moonloader"
local sampev 		= require "lib.samp.events" -- // Евенты
local imgui 		= require "imgui" -- // Подключение ImGui.
local as_action 	= require("moonloader").audiostream_state -- // Состояние стрим музыки
local encoding 		= require "encoding" -- // Кодировка
encoding.default 	= "CP1251"
u8 = encoding.UTF8

local effil = require 'effil'

local rx, ry 				= getScreenResolution() -- // Размер экрана
local mainMenu				= imgui.ImBool(false) -- // Основное меню

local currentNumOfHouses = { US = 0, AF = 0, RC = 0 }
local lastCurrentNumOfHouses = { US = 0, AF = 0, RC = 0 }

local checkInGosHouse, checkAllHouse = {}, {}
local closeDialog = false
local parksMin = 0
local priceRange = 0
local gosCheckerMessage = false

local race_cp = nil
local cp_coords = {}

local TextHouse = imgui.ImBool(true)

local afkgos = false
local houseInGos = false
local cordHouseCoint = 0

local groupToken = "vk1.a.JAPeFveGsN0T0SG3b3oeBqkBsh1EuHmIBX8LuwlWixWcFvIvH2QTUy8lCgfpicULP203rYmzRYT7Ix-G4Ictw_Ciq7XA1KXkcy-JFMlvz8VR2KtU5pmkuQJks9gcjis8pInek3ynK4_VM30pdwQMLtKywY56rV1mkN66naT8lFKoMOXMLg17iaUI9ogre5FiBrGloVGuC6Ad1GvEowUbwA"
local prefixTG = "0"

local testTG = "0"

local maximTG = "1042512028"
local andreyTG = "409972132"
local tomasTG = "610314342"
local patricioTG = "5215921081"
local juniorTG = "5621053685"
local jaiTG = "889551922"
local forestTG = "1338972792"
local jeysonTG = "1296159319"
local codynamiltonTG = "796395442"
local bodyaTG = "1368260205"
local fedyaTG = "1159452429"
local botTG = "5614538474:AAGOKPENb_fO-WFpkkrS_-Zr6vHPJt7DuDw"


local dlstatus = require('moonloader').download_status

function update()
  local fpath = os.getenv('TEMP') .. '\\testing_version.json' -- куда будет качаться наш файлик для сравнения версии
  downloadUrlToFile('https://raw.githubusercontent.com/vitomc1/hchecker/main/version.json', fpath, function(id, status, p1, p2) -- ссылку на ваш гитхаб где есть строчки которые я ввёл в теме или любой другой сайт
    if status == dlstatus.STATUS_ENDDOWNLOADDATA then
    local f = io.open(fpath, 'r') -- открывает файл
    if f then
      local info = decodeJson(f:read('*a')) -- читает
      updatelink = info.updateurl
      if info and info.latest then
        version = tonumber(info.latest) -- переводит версию в число
        if version > tonumber(thisScript().version) then -- если версия больше чем версия установленная то...
          lua_thread.create(goupdate) -- апдейт
        else -- если меньше, то
          update = false -- не даём обновиться
          sampAddChatMessage('[GC]: {8be547}Ваша версия скрипта актуальная. Обновление не требуется. Версия: '..thisScript().version, -1)
        end
      end
    end
  end
end)
end
--скачивание актуальной версии
--"[GC]: {8be547}Чекер домов. /gosmenu - основное меню, /gos - просмотр кол-ва домов, /gos [паркинги] [цена]", -1
function goupdate()
sampAddChatMessage('[GC]: {8be547}Обнаружено обновление. AutoReload может конфликтовать. Обновляюсь...', -1)
sampAddChatMessage('[GC]: {8be547}Текущая версия: '..thisScript().version..". Новая версия: "..version, -1)
wait(300)
downloadUrlToFile(updatelink, thisScript().path, function(id3, status1, p13, p23) -- качает ваш файлик с latest version
  if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
		local _, id = sampGetPlayerIdByCharHandle(playerPed)
  sampAddChatMessage('[GC]: {8be547}Обновление завершено!', -1)
  thisScript():reload()
end
end)
end

-- ВСЁ!



-- // Если нет конфига - создаем
if not doesDirectoryExist(getWorkingDirectory().."/config") then
	createDirectory(getWorkingDirectory().."/config")
end
if not doesDirectoryExist(getWorkingDirectory().."/config/gosChecker") then
	createDirectory(getWorkingDirectory().."/config/gosChecker")
end
-- // Нет файла с настройками - создаем
if not doesFileExist(getWorkingDirectory().."/config/gosChecker/nsettings.json") then
	local fee = io.open(getWorkingDirectory().."/config/gosChecker/nsettings.json", "w")
	fee:write(encodeJson({
		HOUSE = {},
		settings = {
			activScript = true,
			activSound = false,
			volumeSound = 40,
			activMessage = true,
			colorMessage = 0xFF32CD32,
			textMessage = "[GC]: {AA0000}ВНИМАНИЕ!{8be547} В {COUNTRY} слетел новый дом. При последней проверке было {FFFFFF}{LAST_COUNT} {8be547}домов, сейчас их {FFFFFF}{NOW_COUNT}",
			activPayday = false,
			activMonitor = true,
			posMonitorX = 200,
			posMonitorY = 200,
			sizeMonitor = 9,
			fontMonitor = "gtasa",
			textMonitor = "{FFFFFF}US: {32CD32}{US} {FFFFFF}| AF:  {32CD32}{AF}  {FFFFFF}| RC:  {32CD32}{RC}",
			timeWait = 5000,
		}
	}))
	io.close(fee)
end
-- // Если есть - подключаем
if doesFileExist(getWorkingDirectory().."/config/gosChecker/nsettings.json") then
	local fee = io.open(getWorkingDirectory().."/config/gosChecker/nsettings.json", "r")
	if fee then
		database = decodeJson(fee:read("*a"))
		io.close(fee)
	end
end

local sliderVolume = imgui.ImFloat(tonumber(database["settings"]["volumeSound"])) -- // Слайдер звука

local tableCheckbox = {
	activScript = imgui.ImBool(database["settings"]["activScript"]),
	activSound = imgui.ImBool(database["settings"]["activSound"]),
	activMessage = imgui.ImBool(database["settings"]["activMessage"]),
	activMonitor = imgui.ImBool(database["settings"]["activMonitor"]),
	vvvp = imgui.ImBool(database["settings"]["activPayday"])
}

local tableImInt = {
	sizeMonitor = imgui.ImInt(database["settings"]["sizeMonitor"]),
	timeWait = imgui.ImInt(database["settings"]["timeWait"] / 1000)
}

local tableInput = {
	fontMonitor = imgui.ImBuffer(database["settings"]["fontMonitor"], 32),
	--colorMessage = imgui.ImBuffer(database["settings"]["colorMessage"], 100),
	textMonitor = imgui.ImBuffer(u8(database["settings"]["textMonitor"]), 3000),
	textMessage = imgui.ImBuffer(u8(database["settings"]["textMessage"]), 3000)
}


function checkForNewHouses()

--	if ip:find("185.169.134.83") or ip:find("185.169.134.84") or ip:find("185.169.134.85") then
	local cities = {"US", "AF", "RC"}
	for i = 1, #cities do
		local city = cities[i]
		if currentNumOfHouses[city] > lastCurrentNumOfHouses[city] and isRunningFirstTime then
			if database["settings"]["activMessage"] and database["settings"]["textMessage"] then
				local text = database["settings"]["textMessage"]
				local text = text:gsub("{COUNTRY}", city)
				local text = text:gsub("{LAST_COUNT}", lastCurrentNumOfHouses[city])
				local text = text:gsub("{NOW_COUNT}", currentNumOfHouses[city])
				sampAddChatMessage(text, database["settings"]["colorMessage"])
				local sendVk = "[GC]: В "..city.." слетел новый дом. При последней проверке было "..lastCurrentNumOfHouses[city].." домов, сейчас их "..currentNumOfHouses[city]..""

				local _, id = sampGetPlayerIdByCharHandle(playerPed)
				local ip = sampGetCurrentServerAddress()
				if ip == "185.169.134.83" then
					prefixTG = "[RPG]"
					local sendTG = ""..prefixTG..":  В  "..city.."  слетел  дом.  Было:  "..lastCurrentNumOfHouses[city]..",  а  сейчас  -  "..currentNumOfHouses[city].."  "..os.date("Время:  %H:%M:%S  Дата: %d.%m.20%y").."  ("..sampGetPlayerNickname(id)..")."
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. andreyTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. tomasTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. patricioTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. juniorTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jaiTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. forestTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jeysonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. codynamiltonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. bodyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. fedyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
				elseif ip == "185.169.134.84" then
					prefixTG = "[TRP1]"
					local sendTG = ""..prefixTG..":  В  "..city.."  слетел  дом.  Было:  "..lastCurrentNumOfHouses[city]..",  а  сейчас  -  "..currentNumOfHouses[city].."  "..os.date("Время:  %H:%M:%S  Дата: %d.%m.20%y").."  ("..sampGetPlayerNickname(id)..")."
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. andreyTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. tomasTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. patricioTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. juniorTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jaiTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. forestTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jeysonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. codynamiltonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. bodyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. fedyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
				elseif ip == "185.169.134.85" then
					prefixTG = "[TRP2]"
					local sendTG = ""..prefixTG..":  В  "..city.."  слетел  дом.  Было:  "..lastCurrentNumOfHouses[city]..",  а  сейчас  -  "..currentNumOfHouses[city].."  "..os.date("Время:  %H:%M:%S  Дата: %d.%m.20%y").."  ("..sampGetPlayerNickname(id)..")."
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. andreyTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. tomasTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. patricioTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. juniorTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jaiTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. forestTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jeysonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. codynamiltonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. fedyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
				end
			--	end

			--[[	local rnd = math.random(-2147483648, 2147483647)
				async_http_request('https://api.vk.com/method/messages.send', 'peer_id=' .. testVk .. '&random_id=' .. rnd .. '&message=' ..  sendVk  .. '&access_token=' .. groupToken.. '&v=5.131',
				function (result)
			end)
				async_http_request('https://api.vk.com/method/messages.send', 'peer_id=' .. maximVk .. '&random_id=' .. rnd .. '&message=' ..  sendVk  .. '&access_token=' .. groupToken.. '&v=5.131',
				function (result)
			end)--]]

			end
				if getAudioStreamState(loadSound) ~= as_action.PLAY then
					setAudioStreamVolume(loadSound, database["settings"]["volumeSound"])
					setAudioStreamState(loadSound, as_action.PLAY)
				end
		--	end
			lastCurrentNumOfHouses[city] = currentNumOfHouses[city]
		end
		lastCurrentNumOfHouses[city] = currentNumOfHouses[city]
	end
	if not isRunningFirstTime then isRunningFirstTime = true end
end

function sampev.onServerMessage(color, text)
	if text:find("Перед использованием данной возможности следует закрыть все активные диалоговые окна") then
		return false
	end
	if text:find("Вы не можете использовать статичные телефоны для звонков на эти номера.") then
		return false
	end
	if text:find("Вы уже разговариваете по мобильному телефону.") then
		return false
	end
	lua_thread.create(function()
		if database["settings"]["activPayday"] then
			if text:find("Администрация проекта благодарит вас за то") then
				wait(1000)
				sampAddChatMessage("[GC]: {8be547}Поиск слетевших домов...", -1)
				sampProcessChatInput("/gos 0 1-9000000")
			end
		end
	end)
	lua_thread.create(function()
	if afkgos then
		if text:find("Администрация проекта благодарит вас за то") then
			wait(10)
			sampProcessChatInput("/gos")
		end
		end
		end)

		if color == -68395521 and text:find("Чекпоинт GPS подсказки успешно снят.") and race_cp ~= nil then deleteCheckpoint(race_cp) end

end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
	if activationScript then
		-- // Просмотр всех домов
		if checkAllHouse[1] and id == 2110 and title:find("Поиск выставленных на продажу домов") then
			sampSendDialogResponse(2110, 1, 0, "")
			checkAllHouse[1], checkAllHouse[2] = false, true
			return false
		end
		if checkAllHouse[2] and id == 2111 then
			local i = 1
			for num in string.gmatch(text, "%{abcdef%}(%d+)") do
				if i == 4 then currentNumOfHouses.US = tonumber(num) end
				if i == 6 then currentNumOfHouses.AF = tonumber(num) end
				if i == 8 then currentNumOfHouses.RC = tonumber(num) end
				i = i + 1




			end
			if gosCheckerMessage then
				sampAddChatMessage(	"[GC]: {8be547}Количество домов в госе: US - {ffffff}" .. currentNumOfHouses.US .. "{8be547} | AF - {ffffff}" .. currentNumOfHouses.AF .. "{8be547} | RC - {ffffff}" .. currentNumOfHouses.RC, -1)
				gosCheckerMessage = false
			end
			checkForNewHouses()
			checkAllHouse[2], closeDialog = false, true
			sampSendDialogResponse(2111, 1, 0, "")
			return false
		end

		-- // Поиск по данным
		if checkInGosHouse[1] and id == 2110 and title:find("Поиск выставленных на продажу домов") then
			sampSendDialogResponse(2110, 1, 2, "")
			checkInGosHouse[1], checkInGosHouse[2] = false, true
			checkInGosViborGos = true
			return false
		end
		if checkInGosHouse[2] and id == 2112 and title:find("Мастер поиска домов") then
			sampSendDialogResponse(2112, 1, 1, "")
			checkInGosHouse[2], checkInGosHouse[3] = false, true
			return false
		end
		if checkInGosHouse[3] and id == 2112 and title:find("Мастер поиска домов") then
			sampSendDialogResponse(2112, 1, 2, "")
			checkInGosHouse[3], checkInGosHouse[4] = false, true
			return false
		end
		if checkInGosHouse[4] and id == 2116 then
			sampSendDialogResponse(2116, 1, 0, parksMin)
			checkInGosHouse[4], checkInGosHouse[5] = false, true
			return false
		end
		if checkInGosHouse[5] and id == 2118 then
			checkInGosHouse[5], checkInGosHouse[6], checkInGosHouse[7] = false, true, true
			if xfunc then
				lua_thread.create(function()
					priceRange = priceRange:match("(%d+%-%d+).*")
					wait(100)
					sampSetCurrentDialogEditboxText(tostring(priceRange))
					xfunc = false
				end)
				return
			else
				sampSendDialogResponse(2118, 1, 0, tostring(priceRange))
				return false
			end
		end
		if checkInGosHouse[6] and id == 2111 and text:find("По вашему запросу не найдено") then
			sampAddChatMessage("[GC]: {8be547}По вашему запросу не найдено ни одного предложения о продаже.", -1)
			sampSendDialogResponse(2111, 1, 0, "")
			checkInGosHouse[6], checkInGosHouse[7], closeDialog = false, false, true
			return false
		end
		if checkInGosHouse[7] and id == 2111 and text:find("По вашему запросу найдено") then
			local kolvoGosHouse = text:match("{fbec5d}(%d+){ffffff}")
			sampSendDialogResponse(2111, 1, 0, "")
			sampAddChatMessage("[GC]: {8be547}По вашему запросу найдено {FFFFFF}"..kolvoGosHouse.. "{8be547} предложений. Ближайшее к вам отмечено на радаре.", -1)

			checkInGosHouse[6], checkInGosHouse[7], closeDialog = false, false, true
			houseInGos = true
			return false
		end

		-- // Закрытие диалога /call realty
		if closeDialog and id == 2110 then
			sampSendDialogResponse(2110, 0, 0, "")
			closeDialog = false
			return false
		end
	end
end

function char_to_hex(str)
  return string.format("%%%02X", string.byte(str))
end
function url_encode(str)
	return string.gsub(string.gsub(str, "\\", "\\"), "([^%w])", char_to_hex)
end
function requestRunner() -- создание effil потока с функцией https запроса
	return effil.thread(function(u, a)
		local https = require 'ssl.https'
		local ok, result = pcall(https.request, u, a)
		if ok then
			return {true, result}
		else
			return {false, result}
		end
	end)
end

function threadHandle(runner, url, args, resolve, reject) -- обработка effil потока без блокировок
	local t = runner(url, args)
	local r = t:get(0)
	while not r do
		r = t:get(0)
		wait(0)
	end
	local status = t:status()
	if status == 'completed' then
		local ok, result = r[1], r[2]
		if ok then resolve(result) else reject(result) end
	elseif err then
		reject(err)
	elseif status == 'canceled' then
		reject(status)
	end
	t:cancel(0)
end

function async_http_request(url, args, resolve, reject)
	local runner = requestRunner()
	if not reject then reject = function() end end
	lua_thread.create(function()
		threadHandle(runner, url, args, resolve, reject)
	end)
end

-- // IMGUI окна
function imgui.OnDrawFrame()
	if mainMenu.v then
		if database["settings"]["activScript"] then
			imgui.SetNextWindowPos(imgui.ImVec2(rx / 2 - 365 / 2, ry / 2 - 465 / 2))
			imgui.SetNextWindowSize(imgui.ImVec2(365, 465))
		else
			imgui.SetNextWindowPos(imgui.ImVec2(rx / 2 - 365 / 2, ry / 2 - 70 / 2))
			imgui.SetNextWindowSize(imgui.ImVec2(365, 70))
		end
		imgui.Begin(u8(" GOS Checker | Trinity GTA"), mainMenu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
			imgui.BeginChild("#UP_PANEL", imgui.ImVec2(350, 35), true)
				if imgui.Checkbox(u8(" Активация. Включить скрипт?"), tableCheckbox["activScript"]) then
					database["settings"]["activScript"] = tableCheckbox["activScript"].v
					saveDataBase()
				end
			imgui.EndChild()
			if database["settings"]["activScript"] then
				imgui.BeginChild("##CENTER_PANEL", imgui.ImVec2(350, -1), true)
					imgui.BeginChild("##timeWait", imgui.ImVec2(335, 35), true)
						imgui.PushItemWidth(90)
							if imgui.InputInt(u8(" Задержка между чеками (в сек.)"), tableImInt["timeWait"]) then
								database["settings"]["timeWait"] = tableImInt["timeWait"].v * 1000
								saveDataBase()
							end
						imgui.PopItemWidth()
						imgui.SameLine()
						imgui.Button("(?)", imgui.ImVec2(25, 20))
						imgui.Hint(u8("Задержка при получении информации о текущих домах на сервере. Указывать в секундах"))
					imgui.EndChild()
					imgui.Spacing()

					if imgui.Checkbox(u8(" Выводить мониторинг?"), tableCheckbox["activMonitor"]) then
						database["settings"]["activMonitor"] = tableCheckbox["activMonitor"].v
						saveDataBase()
					end
					if database["settings"]["activMonitor"] then
						imgui.BeginChild("##activMonitor", imgui.ImVec2(335, 110), true)
							imgui.PushItemWidth(290)
								if imgui.InputText("##textMonitor", tableInput["textMonitor"]) then
									database["settings"]["textMonitor"] = u8:decode(tableInput["textMonitor"].v)
									saveDataBase()
								end
							imgui.PopItemWidth()
							imgui.SameLine()
							imgui.Button("(?)", imgui.ImVec2(25, 20))
							imgui.Hint(u8("Текст который будет выводится на экран для мониторинга. Используйте {AF}, {US}, {RC} - для вывода кол-ва домов в странах. Можно использовать цвета в формате {ЦВЕТ_HTML}. Пример белого цвета: {FFFFFF}"))

							imgui.PushItemWidth(150)
								if imgui.InputText(u8(" Название шрифта"), tableInput["fontMonitor"]) then
									database["settings"]["fontMonitor"] = tableInput["fontMonitor"].v
									saveDataBase()
									font = renderCreateFont(database["settings"]["fontMonitor"], tableImInt["sizeMonitor"], 5)
								end
								if imgui.InputInt(u8(" Размер шрифта"), tableImInt["sizeMonitor"]) then
									database["settings"]["sizeMonitor"] = tableImInt["sizeMonitor"].v
									saveDataBase()
									font = renderCreateFont(database["settings"]["fontMonitor"], database["settings"]["sizeMonitor"], 5)
								end
							imgui.PopItemWidth()
							if imgui.Button(u8("Изменить положение мониторинга"), imgui.ImVec2(-1, 25)) then
								changePos = true
								mainMenu.v = false
							end
						imgui.EndChild()
					end

					if imgui.Checkbox(u8(" Проигровать звук?"), tableCheckbox["activSound"]) then
						if not doesFileExist(getWorkingDirectory().."/config/gosChecker/sound.mp3") then
							database["settings"]["activSound"] = false
							saveDataBase()
							sampAddChatMessage("[GS]: Не обнаружено файла sound.mp3. Добавьте файл по пути: /config/gosChecker/sound.mp3", database["settings"]["colorMessage"])
						else
							loadSound = loadAudioStream(getWorkingDirectory().."/config/gosChecker/sound.mp3")
							database["settings"]["activSound"] = tableCheckbox["activSound"].v
							saveDataBase()
						end
					end
					if database["settings"]["activSound"] and doesFileExist(getWorkingDirectory().."/config/gosChecker/sound.mp3") then
						imgui.BeginChild("##activSound", imgui.ImVec2(335, 35), true)
							imgui.PushItemWidth(290)
								if imgui.SliderFloat("##sliderVolume", sliderVolume, 0, 100, "%.0f") then
									database["settings"]["volumeSound"] = tonumber(sliderVolume.v)
									saveDataBase()
								end
							imgui.PopItemWidth()
							imgui.SameLine()
							imgui.Button("(?)", imgui.ImVec2(25, 20))
							imgui.Hint(u8("Громкость проигрования звука при слёте дома."))
						imgui.EndChild()
					end


					if imgui.Checkbox(u8(" Выводить сообщение?"), tableCheckbox["activMessage"]) then
						database["settings"]["activMessage"] = tableCheckbox["activMessage"].v
						saveDataBase()
					end
					if database["settings"]["activMessage"] then
						imgui.BeginChild("##activMessage", imgui.ImVec2(335, 35), true)
							imgui.PushItemWidth(290)
								if imgui.InputText("##textMessage", tableInput["textMessage"]) then
									database["settings"]["textMessage"] = u8:decode(tableInput["textMessage"].v)
									saveDataBase()
								end
							imgui.PopItemWidth()
							imgui.SameLine()
							imgui.Button("(?)", imgui.ImVec2(25, 20))
							imgui.Hint(u8("Текст который будет выводится при слёте дома в чат. Используйте {COUNTRY} для вывода страны, {LAST_COUNT} - показывает сколько было домов до, {NOW_COUNT} - показывает сколько сейчас домов. Можно использовать цвета в формате {ЦВЕТ_HTML}. Пример белого цвета: {FFFFFF}"))
						imgui.EndChild()
					end

					imgui.BeginChild("#vvv", imgui.ImVec2(335, 35), true)
					if imgui.Checkbox(u8(" Авто-поиск в PayDay"), tableCheckbox["vvvp"]) then
						database["settings"]["activPayday"] = tableCheckbox["vvvp"].v
						saveDataBase()
					end
						imgui.EndChild()
						imgui.BeginChild("##activTEXTHOUSE", imgui.ImVec2(335, 35), true)
						if imgui.Checkbox(u8"3D текст на слетевших домах, включить?", TextHouse) then
						end
						imgui.EndChild()
						 imgui.Button(u8("*Версия с уведомлениями в Telegram"), imgui.ImVec2(-1, 0))
							imgui.Hint(u8"Данная версия скрипта позволяет уведомлять о слете дома в ТГ, сразу между несколькими пользователями, которые уже добавлены и подключены к боту.")
				imgui.EndChild()
			end
		imgui.End()
	end
end

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	update()
	sampAddChatMessage("[GC]: {8be547}Чекер домов. /gosmenu - основное меню, /gos - просмотр кол-ва домов, /gos [паркинги] [цена]", -1)

	lua_thread.create(functionTimer)

	font = renderCreateFont(database["settings"]["fontMonitor"], database["settings"]["sizeMonitor"], 5)

	if not doesFileExist(getWorkingDirectory().."/config/gosChecker/sound.mp3") then
		database["settings"]["activSound"] = false
		saveDataBase()
		sampAddChatMessage("[GS]: Не обнаружено файла sound.mp3. Добавьте файл по пути: /config/gosChecker/sound.mp3", database["settings"]["colorMessage"])
	else
		loadSound = loadAudioStream(getWorkingDirectory().."/config/gosChecker/sound.mp3")
	end

	sampRegisterChatCommand("afkgos", function()
	afkgos = not afkgos
	sampAddChatMessage(afkgos and "[GC]: {8be547}Авто-чекер слетевших домов в пейдей - вкл." or "[GC]: {8be547}Авто-чекер слетевших домов в пейдей - выкл.", -1)
	end)



	sampRegisterChatCommand("tgsend", function(test)
		local _, id = sampGetPlayerIdByCharHandle(playerPed)
		if test ~= nil and #test > 0 then
				if test:find(".*") then
					local Comment = test:match("(.*)")
					if Comment then
						local ip = sampGetCurrentServerAddress()
						if ip == "185.169.134.83" then
							prefixTG = "[RPG]"
					local send = ""..prefixTG.." Комментарий от "..sampGetPlayerNickname(id)..": "..Comment..""

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. "\xE2\x98\x81 "..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. andreyTG .. "&text=" .. "\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. tomasTG .. "&text=" .. "\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. patricioTG .. "&text=" .."\xE2\x98\x81 "..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. juniorTG .. "&text=" .."\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jaiTG .. "&text=" .."\xE2\x98\x81 ".. u8(send), "", function (result)
					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. forestTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jeysonTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. codynamiltonTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. bodyaTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. fedyaTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					sampAddChatMessage("[GC] Ваше сообщение в ТГ: {0088cc}"..send, -1)
				elseif ip == "185.169.134.84" then
					prefixTG = "[TRP1]"
					local send = ""..prefixTG.." Комментарий от "..sampGetPlayerNickname(id)..": "..Comment..""

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .."\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. andreyTG .. "&text=" .."\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. tomasTG .. "&text=" .."\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. patricioTG .. "&text=" .."\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. juniorTG .. "&text=" .. "\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jaiTG .. "&text=" .. "\xE2\x98\x81 ".. u8(send), "", function (result)
					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. forestTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jeysonTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. codynamiltonTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. bodyaTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. fedyaTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					sampAddChatMessage("[GC] Ваше сообщение в ТГ: {0088cc}"..send, -1)
				elseif ip == "185.169.134.85" then
					prefixTG = "[TRP2]"
					local send = ""..prefixTG.." Комментарий от "..sampGetPlayerNickname(id)..": "..Comment..""

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. "\xE2\x98\x81 "..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. andreyTG .. "&text=" .. "\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. tomasTG .. "&text=" .. "\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. patricioTG .. "&text=" .."\xE2\x98\x81 "..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. juniorTG .. "&text=" .."\xE2\x98\x81 ".. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jaiTG .. "&text=" .."\xE2\x98\x81 ".. u8(send), "", function (result)
					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. forestTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jeysonTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. codynamiltonTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. bodyaTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. fedyaTG .. "&text=" .. '\xE2\x98\x81 '..u8(send), "", function (result)

					end)
					sampAddChatMessage("[GC] Ваше сообщение в ТГ: {0088cc}"..send, -1)
				end



				end
			else
				sampAddChatMessage("[GC]:{8be547} Правильное использование: /tgsend КОММЕНТАРИЙ.", -1)
			end
		else
			sampAddChatMessage("[GC]:{8be547} Правильное использование: /tgsend КОММЕНТАРИЙ.", -1)
		end
	end)

	--[[sampRegisterChatCommand("tgupdate0", function(update1)
		local update1 = "------------------------------"
		async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. u8(update1), "", function (result)
		end)
	end)

	sampRegisterChatCommand("tgupdate1", function(update2)
		local update1 = "*** ОБНОВЛЕНИЕ ДО ВЕРСИИ 3.0 ***"
		async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. u8(update1), "", function (result)
		end)
	end)

	sampRegisterChatCommand("tgupdate2", function(update3)
		local update1 = "Добавлена команда: /tgsend ДОМ РАЙОН - оповести всех что слетел дом."
		async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. u8(update1), "", function (result)
		end)
	end)--]]




	sampRegisterChatCommand(
		"gos",
		function(text)
			local parks, price = text:match("(%d+) (.*)")
			parksMin, priceRange = parks, price
			if text == "" then
				if not sampIsDialogActive() then
					activationScript, checkAllHouse[1], gosCheckerMessage = true, true, true
					sampSendChat("/call realty")
				else
					sampAddChatMessage("[GC]: {8be547}Закройте активные диалоги.", -1)
				end
			elseif text ~= "" and getCharActiveInterior(PLAYER_PED) ~= 0 then
				return sampAddChatMessage("[GC]: {8be547}Вы не можете использовать эту функцию, находясь в интерьере.", -1)
			elseif not parks or not price or parks >= "3" and price ~= "%-" then
				return sampAddChatMessage("[GC]: {8be547}Вводите правильно: /gos (кол-во парковок до 3х) (wена от-до)", -1)
			end
			if parksMin ~= 0 and priceRange ~= 0 and text ~= "" and not getCharActiveInterior(PLAYER_PED) ~= 0 and price:find("%-") then
				if priceRange:find("x") then
					xfunc = true
				end
				activationScript, checkInGosHouse[1] = true, true
				sampSendChat("/call realty")
			end
		end
	)

	sampRegisterChatCommand(
		"gosmenu",
		function()
			mainMenu.v = not mainMenu.v
		end
	)

	while true do wait(0)

		if TextHouse.v then
		for key, val in pairs(database["HOUSE"]) do
				xM, yM, zM = getCharCoordinates(PLAYER_PED)
				ds = getDistanceBetweenCoords2d(xM, yM, database["HOUSE"][key]["posX"], database["HOUSE"][key]["posY"])
				if ds <= 10 then
				sampDestroy3dText(abs)
			end
		end
	else
		sampDestroy3dText(abs)
	end

		if changePos then
            sampToggleCursor(true)
            database["settings"]["posMonitorX"], database["settings"]["posMonitorY"] = getCursorPos()
            if isKeyJustPressed(0x01) then
				saveDataBase()
                changePos = false
                mainMenu.v = true
                sampToggleCursor(false)
            end
        end

		imgui.Process = mainMenu.v

		if database["settings"]["activScript"] and database["settings"]["activMonitor"] then
			local text = database["settings"]["textMonitor"]
			local text = text:gsub("{US}", currentNumOfHouses["US"])
			local text = text:gsub("{AF}", currentNumOfHouses["AF"])
			local text = text:gsub("{RC}", currentNumOfHouses["RC"])
			renderFontDrawText(font, text, database["settings"]["posMonitorX"], database["settings"]["posMonitorY"], database["settings"]["colorMessage"])
		end
	end
end

function sampev.onSetCheckpoint(pos, rad)
	lua_thread.create(function()
	if houseInGos then
		wait(1000)
    if race_cp ~= nil then deleteCheckpoint(race_cp) end
    race_cp = createCheckpoint(2, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, rad)
    cp_coords = {pos.x, pos.y, pos.z}
		--sampAddChatMessage(pos.x.." ".. pos.y.." ".. pos.z, -1)
			local _, id = sampGetPlayerIdByCharHandle(playerPed)
		for key, val in pairs(database["HOUSE"]) do
			if ""..pos.x.."" == database["HOUSE"][key]["posX"] and ""..pos.y.."" == database["HOUSE"][key]["posY"] then
				cordHouseCoint = cordHouseCoint + 1
				sampAddChatMessage("[GH] {8be547}Найден слетевший дом! {ffffff}№"..database["HOUSE"][key]["num"]..". {8be547}Район - {ffffff}"..database["HOUSE"][key]["area"]..".", -1)

				local _, id = sampGetPlayerIdByCharHandle(playerPed)
				local ip = sampGetCurrentServerAddress()
				if ip == "185.169.134.83" then
					prefixTG = "[RPG; "..os.date("%H:%M").."]"
					local sendTG = ""..prefixTG.." Слетел в гос. дом №"..database["HOUSE"][key]["num"].." в районе "..database["HOUSE"][key]["area"]..".  ("..sampGetPlayerNickname(id)..")"
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. andreyTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. tomasTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. patricioTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. juniorTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jaiTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. forestTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jeysonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. codynamiltonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. bodyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. fedyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
				elseif ip == "185.169.134.84" then
					prefixTG = "[TRP1; "..os.date("%H:%M").."]"
					local sendTG = ""..prefixTG.." Слетел в гос. дом №"..database["HOUSE"][key]["num"].." в районе "..database["HOUSE"][key]["area"]..".  ("..sampGetPlayerNickname(id)..")"
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. andreyTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. tomasTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. patricioTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. juniorTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jaiTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. forestTG .. "&text=" .. '\xF0\x9F\x8C\x85 '..u8(sendTG), "", function (result)

					end)

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jeysonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. codynamiltonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. bodyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. fedyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
				elseif ip == "185.169.134.85" then
					prefixTG = "[TRP2; "..os.date("%H:%M").."]"
					local sendTG = ""..prefixTG.." Слетел в гос. дом №"..database["HOUSE"][key]["num"].." в районе "..database["HOUSE"][key]["area"]..".  ("..sampGetPlayerNickname(id)..")"
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. andreyTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. tomasTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. patricioTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. juniorTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jaiTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. forestTG .. "&text=" .. '\xF0\x9F\x8C\x84 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jeysonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. codynamiltonTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. bodyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. fedyaTG .. "&text=" .. '\xF0\x9F\x8C\x83 '..u8(sendTG), "", function (result)

					end)


				end

				if TextHouse.v then
				xM, yM, zM = getCharCoordinates(PLAYER_PED)
				abs = sampCreate3dText("{80A6FF}*** ДОМ В ГОС ***\n\n{ffffff}Дом №"..database["HOUSE"][key]["num"].." {8be547}|{ffffff} Район "..database["HOUSE"][key]["area"], 0xFFffffff, database["HOUSE"][key]["posX"], database["HOUSE"][key]["posY"], database["HOUSE"][key]["posZ"], 50000, true, -1, -1)
				ds = getDistanceBetweenCoords2d(xM, yM, database["HOUSE"][key]["posX"], database["HOUSE"][key]["posY"])
			end
			end
		end

end
end)
		cordHouseCoint = 0
		houseInGos = false
		--deleteCheckpoint(race_cp)
		--race_cp = nil
end

function functionTimer()
	while true do wait(0)
		if database["settings"]["activScript"] then
			if not sampIsDialogActive() then
				activationScript, checkAllHouse[1] = true, true
				sampSendChat("/call realty")
			end
			wait(database["settings"]["timeWait"])
		end
	end
end

function saveDataBase()
	local configFile = io.open(getWorkingDirectory().."/config/gosChecker/nsettings.json", "w")
	configFile:write(encodeJson(database))
	configFile:close()
end

-- // Маркер в IMGUI
function imgui.Hint(text, delay)
    if imgui.IsItemHovered() then
        if go_hint == nil then go_hint = os.clock() + (delay and delay or 0.0) end
        local alpha = (os.clock() - go_hint) * 5 -- скорость появления
        if os.clock() >= go_hint then
            imgui.PushStyleVar(imgui.StyleVar.Alpha, (alpha <= 1.0 and alpha or 1.0))
                imgui.PushStyleColor(imgui.Col.PopupBg, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
                    imgui.BeginTooltip()
                    imgui.PushTextWrapPos(450)
                    imgui.TextUnformatted(text)
                    if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then go_hint = nil end
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                imgui.PopStyleColor()
            imgui.PopStyleVar()
        end
    end
end

function sampev.onSetObjectMaterialText(id, data)
	if tostring(data.text):find('^%d+  %d+\n\n{ffffff}Владелец:{fbec5d} .*') then
		local crdFlat, crdFalatX, crdFalatY, crdFalatZ = getObjectCoordinates(sampGetObjectHandleBySampId(id))
		local text = tostring(data.text)
		local num, park, owner = tostring(data.text):match("^(%d+)  (%d+)\n\n{ffffff}Владелец:{fbec5d} (%S+)")
		if not CheckGps(num) then
			table.insert(database["HOUSE"], {
				["area"] = getArea(crdFalatX, crdFalatY, crdFalatZ),
				["num"] = num,
				["posX"] = ""..crdFalatX.."",
				["posY"] = ""..crdFalatY.."",
				["posZ"] = ""..crdFalatZ..""
			})
			saveDataBase()
		end
	end
	if tostring(data.text):find('^%d+  %d+\n\n{ffffff}Это жилье продается за {33aa33}.* %${ffffff}.') then
		local crdFlat, crdFalatX, crdFalatY, crdFalatZ = getObjectCoordinates(sampGetObjectHandleBySampId(id))
		local text = tostring(data.text)
		local num, park = tostring(data.text):match("^(%d+)  (%d+)\n\n{ffffff}Это жилье продается за {33aa33}.* %${ffffff}")
		if not CheckGps(num) then
			table.insert(database["HOUSE"], {
				["area"] = getArea(crdFalatX, crdFalatY, crdFalatZ),
				["num"] = num,
				["posX"] = ""..crdFalatX.."",
				["posY"] = ""..crdFalatY.."",
				["posZ"] = ""..crdFalatZ..""
			})
			saveDataBase()
		end
	end
end

function sampev.onCreate3DText(id, color, pos, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
			if text:find("^%d+  %d+\n\n{ffffff}Владелец:{fbec5d} .*") then
	 			local num, park, owner = text:match("^(%d+)  (%d+)\n\n{ffffff}Владелец:{fbec5d} (%S+)")
				--sampAddChatMessage(pos.x.." "..pos.y.." "..pos.z, -1)
				if not CheckGps(num) then
			 		table.insert(database["HOUSE"], {
						["area"] = getArea(pos.x, pos.y, pos.z),
					 	["num"] = num,
						["posX"] = ""..pos.x.."",
						["posY"] = ""..pos.y.."",
						["posZ"] = ""..pos.z..""
				 	})
				 	saveDataBase()
				end
			end
			if text:find("^%d+  %d+\n\n{ffffff}Это жилье продается за {33aa33}.* %${ffffff}.") then
				local num, park = text:match("^(%d+)  (%d+)\n\n{ffffff}Это жилье продается за {33aa33}.* %${ffffff}.")
				if not CheckGps(num) then
					table.insert(database["HOUSE"], {
						["area"] = getArea(pos.x, pos.y, pos.z),
					 	["num"] = num,
						["posX"] = ""..pos.x.."",
						["posY"] = ""..pos.y.."",
						["posZ"] = ""..pos.z..""
				 	})
				 	saveDataBase()
				end
		end
		end



		function getArea(cordX, cordY, cordZ)
			ulici = {
				{
					"Avispa Country Club",
					-2667.81,
					-302.135,
					-28.831,
					-2646.4,
					-262.32,
					71.169
				},
				{
					"Easter Bay Airport",
					-1315.42,
					-405.388,
					15.406,
					-1264.4,
					-209.543,
					25.406
				},
				{
					"Avispa Country Club",
					-2550.04,
					-355.493,
					0,
					-2470.04,
					-318.493,
					39.7
				},
				{
					"Easter Bay Airport",
					-1490.33,
					-209.543,
					15.406,
					-1264.4,
					-148.388,
					25.406
				},
				{
					"Garcia",
					-2395.14,
					-222.589,
					-5.3,
					-2354.09,
					-204.792,
					200
				},
				{
					"Shady Cabin",
					-1632.83,
					-2263.44,
					-3,
					-1601.33,
					-2231.79,
					200
				},
				{
					"East Los Santos",
					2381.68,
					-1494.03,
					-89.084,
					2421.03,
					-1454.35,
					110.916
				},
				{
					"LVA Freight Depot",
					1236.63,
					1163.41,
					-89.084,
					1277.05,
					1203.28,
					110.916
				},
				{
					"Blackfield Intersection",
					1277.05,
					1044.69,
					-89.084,
					1315.35,
					1087.63,
					110.916
				},
				{
					"Avispa Country Club",
					-2470.04,
					-355.493,
					0,
					-2270.04,
					-318.493,
					46.1
				},
				{
					"Temple",
					1252.33,
					-926.999,
					-89.084,
					1357,
					-910.17,
					110.916
				},
				{
					"Unity Station",
					1692.62,
					-1971.8,
					-20.492,
					1812.62,
					-1932.8,
					79.508
				},
				{
					"LVA Freight Depot",
					1315.35,
					1044.69,
					-89.084,
					1375.6,
					1087.63,
					110.916
				},
				{
					"Los Flores",
					2581.73,
					-1454.35,
					-89.084,
					2632.83,
					-1393.42,
					110.916
				},
				{
					"Starfish Casino",
					2437.39,
					1858.1,
					-39.084,
					2495.09,
					1970.85,
					60.916
				},
				{
					"Easter Bay Chemicals",
					-1132.82,
					-787.391,
					0,
					-956.476,
					-768.027,
					200
				},
				{
					"Downtown Los Santos",
					1370.85,
					-1170.87,
					-89.084,
					1463.9,
					-1130.85,
					110.916
				},
				{
					"Esplanade East",
					-1620.3,
					1176.52,
					-4.5,
					-1580.01,
					1274.26,
					200
				},
				{
					"Market Station",
					787.461,
					-1410.93,
					-34.126,
					866.009,
					-1310.21,
					65.874
				},
				{
					"Linden Station",
					2811.25,
					1229.59,
					-39.594,
					2861.25,
					1407.59,
					60.406
				},
				{
					"Montgomery Intersection",
					1582.44,
					347.457,
					0,
					1664.62,
					401.75,
					200
				},
				{
					"Frederick Bridge",
					2759.25,
					296.501,
					0,
					2774.25,
					594.757,
					200
				},
				{
					"Yellow Bell Station",
					1377.48,
					2600.43,
					-21.926,
					1492.45,
					2687.36,
					78.074
				},
				{
					"Downtown Los Santos",
					1507.51,
					-1385.21,
					110.916,
					1582.55,
					-1325.31,
					335.916
				},
				{
					"Jefferson",
					2185.33,
					-1210.74,
					-89.084,
					2281.45,
					-1154.59,
					110.916
				},
				{
					"Mulholland",
					1318.13,
					-910.17,
					-89.084,
					1357,
					-768.027,
					110.916
				},
				{
					"Avispa Country Club",
					-2361.51,
					-417.199,
					0,
					-2270.04,
					-355.493,
					200
				},
				{
					"Jefferson",
					1996.91,
					-1449.67,
					-89.084,
					2056.86,
					-1350.72,
					110.916
				},
				{
					"Julius Thruway West",
					1236.63,
					2142.86,
					-89.084,
					1297.47,
					2243.23,
					110.916
				},
				{
					"Jefferson",
					2124.66,
					-1494.03,
					-89.084,
					2266.21,
					-1449.67,
					110.916
				},
				{
					"Julius Thruway North",
					1848.4,
					2478.49,
					-89.084,
					1938.8,
					2553.49,
					110.916
				},
				{
					"Rodeo",
					422.68,
					-1570.2,
					-89.084,
					466.223,
					-1406.05,
					110.916
				},
				{
					"Cranberry Station",
					-2007.83,
					56.306,
					0,
					-1922,
					224.782,
					100
				},
				{
					"Downtown Los Santos",
					1391.05,
					-1026.33,
					-89.084,
					1463.9,
					-926.999,
					110.916
				},
				{
					"Redsands West",
					1704.59,
					2243.23,
					-89.084,
					1777.39,
					2342.83,
					110.916
				},
				{
					"Little Mexico",
					1758.9,
					-1722.26,
					-89.084,
					1812.62,
					-1577.59,
					110.916
				},
				{
					"Blackfield Intersection",
					1375.6,
					823.228,
					-89.084,
					1457.39,
					919.447,
					110.916
				},
				{
					"Los Santos International",
					1974.63,
					-2394.33,
					-39.084,
					2089,
					-2256.59,
					60.916
				},
				{
					"Beacon Hill",
					-399.633,
					-1075.52,
					-1.489,
					-319.033,
					-977.516,
					198.511
				},
				{
					"Rodeo",
					334.503,
					-1501.95,
					-89.084,
					422.68,
					-1406.05,
					110.916
				},
				{
					"Richman",
					225.165,
					-1369.62,
					-89.084,
					334.503,
					-1292.07,
					110.916
				},
				{
					"Downtown Los Santos",
					1724.76,
					-1250.9,
					-89.084,
					1812.62,
					-1150.87,
					110.916
				},
				{
					"The Strip",
					2027.4,
					1703.23,
					-89.084,
					2137.4,
					1783.23,
					110.916
				},
				{
					"Downtown Los Santos",
					1378.33,
					-1130.85,
					-89.084,
					1463.9,
					-1026.33,
					110.916
				},
				{
					"Blackfield Intersection",
					1197.39,
					1044.69,
					-89.084,
					1277.05,
					1163.39,
					110.916
				},
				{
					"Conference Center",
					1073.22,
					-1842.27,
					-89.084,
					1323.9,
					-1804.21,
					110.916
				},
				{
					"Montgomery",
					1451.4,
					347.457,
					-6.1,
					1582.44,
					420.802,
					200
				},
				{
					"Foster keyley",
					-2270.04,
					-430.276,
					-1.2,
					-2178.69,
					-324.114,
					200
				},
				{
					"Blackfield Chapel",
					1325.6,
					596.349,
					-89.084,
					1375.6,
					795.01,
					110.916
				},
				{
					"Los Santos International",
					2051.63,
					-2597.26,
					-39.084,
					2152.45,
					-2394.33,
					60.916
				},
				{
					"Mulholland",
					1096.47,
					-910.17,
					-89.084,
					1169.13,
					-768.027,
					110.916
				},
				{
					"Yellow Bell Gol Course",
					1457.46,
					2723.23,
					-89.084,
					1534.56,
					2863.23,
					110.916
				},
				{
					"The Strip",
					2027.4,
					1783.23,
					-89.084,
					2162.39,
					1863.23,
					110.916
				},
				{
					"Jefferson",
					2056.86,
					-1210.74,
					-89.084,
					2185.33,
					-1126.32,
					110.916
				},
				{
					"Mulholland",
					952.604,
					-937.184,
					-89.084,
					1096.47,
					-860.619,
					110.916
				},
				{
					"Aldea Malvada",
					-1372.14,
					2498.52,
					0,
					-1277.59,
					2615.35,
					200
				},
				{
					"Las Colinas",
					2126.86,
					-1126.32,
					-89.084,
					2185.33,
					-934.489,
					110.916
				},
				{
					"Las Colinas",
					1994.33,
					-1100.82,
					-89.084,
					2056.86,
					-920.815,
					110.916
				},
				{
					"Richman",
					647.557,
					-954.662,
					-89.084,
					768.694,
					-860.619,
					110.916
				},
				{
					"LVA Freight Depot",
					1277.05,
					1087.63,
					-89.084,
					1375.6,
					1203.28,
					110.916
				},
				{
					"Julius Thruway North",
					1377.39,
					2433.23,
					-89.084,
					1534.56,
					2507.23,
					110.916
				},
				{
					"Willowfield",
					2201.82,
					-2095,
					-89.084,
					2324,
					-1989.9,
					110.916
				},
				{
					"Julius Thruway North",
					1704.59,
					2342.83,
					-89.084,
					1848.4,
					2433.23,
					110.916
				},
				{
					"Temple",
					1252.33,
					-1130.85,
					-89.084,
					1378.33,
					-1026.33,
					110.916
				},
				{
					"Little Mexico",
					1701.9,
					-1842.27,
					-89.084,
					1812.62,
					-1722.26,
					110.916
				},
				{
					"Queens",
					-2411.22,
					373.539,
					0,
					-2253.54,
					458.411,
					200
				},
				{
					"Las Venturas Airport",
					1515.81,
					1586.4,
					-12.5,
					1729.95,
					1714.56,
					87.5
				},
				{
					"Richman",
					225.165,
					-1292.07,
					-89.084,
					466.223,
					-1235.07,
					110.916
				},
				{
					"Temple",
					1252.33,
					-1026.33,
					-89.084,
					1391.05,
					-926.999,
					110.916
				},
				{
					"East Los Santos",
					2266.26,
					-1494.03,
					-89.084,
					2381.68,
					-1372.04,
					110.916
				},
				{
					"Julius Thruway East",
					2623.18,
					943.235,
					-89.084,
					2749.9,
					1055.96,
					110.916
				},
				{
					"Willowfield",
					2541.7,
					-1941.4,
					-89.084,
					2703.58,
					-1852.87,
					110.916
				},
				{
					"Las Colinas",
					2056.86,
					-1126.32,
					-89.084,
					2126.86,
					-920.815,
					110.916
				},
				{
					"Julius Thruway East",
					2625.16,
					2202.76,
					-89.084,
					2685.16,
					2442.55,
					110.916
				},
				{
					"Rodeo",
					225.165,
					-1501.95,
					-89.084,
					334.503,
					-1369.62,
					110.916
				},
				{
					"Las Brujas",
					-365.167,
					2123.01,
					-3,
					-208.57,
					2217.68,
					200
				},
				{
					"Julius Thruway East",
					2536.43,
					2442.55,
					-89.084,
					2685.16,
					2542.55,
					110.916
				},
				{
					"Rodeo",
					334.503,
					-1406.05,
					-89.084,
					466.223,
					-1292.07,
					110.916
				},
				{
					"Vinewood",
					647.557,
					-1227.28,
					-89.084,
					787.461,
					-1118.28,
					110.916
				},
				{
					"Rodeo",
					422.68,
					-1684.65,
					-89.084,
					558.099,
					-1570.2,
					110.916
				},
				{
					"Julius Thruway North",
					2498.21,
					2542.55,
					-89.084,
					2685.16,
					2626.55,
					110.916
				},
				{
					"Downtown Los Santos",
					1724.76,
					-1430.87,
					-89.084,
					1812.62,
					-1250.9,
					110.916
				},
				{
					"Rodeo",
					225.165,
					-1684.65,
					-89.084,
					312.803,
					-1501.95,
					110.916
				},
				{
					"Jefferson",
					2056.86,
					-1449.67,
					-89.084,
					2266.21,
					-1372.04,
					110.916
				},
				{
					"Hampton Barns",
					603.035,
					264.312,
					0,
					761.994,
					366.572,
					200
				},
				{
					"Temple",
					1096.47,
					-1130.84,
					-89.084,
					1252.33,
					-1026.33,
					110.916
				},
				{
					"Kincaid Bridge",
					-1087.93,
					855.37,
					-89.084,
					-961.95,
					986.281,
					110.916
				},
				{
					"Verona Beach",
					1046.15,
					-1722.26,
					-89.084,
					1161.52,
					-1577.59,
					110.916
				},
				{
					"Commerce",
					1323.9,
					-1722.26,
					-89.084,
					1440.9,
					-1577.59,
					110.916
				},
				{
					"Mulholland",
					1357,
					-926.999,
					-89.084,
					1463.9,
					-768.027,
					110.916
				},
				{
					"Rodeo",
					466.223,
					-1570.2,
					-89.084,
					558.099,
					-1385.07,
					110.916
				},
				{
					"Mulholland",
					911.802,
					-860.619,
					-89.084,
					1096.47,
					-768.027,
					110.916
				},
				{
					"Mulholland",
					768.694,
					-954.662,
					-89.084,
					952.604,
					-860.619,
					110.916
				},
				{
					"Julius Thruway South",
					2377.39,
					788.894,
					-89.084,
					2537.39,
					897.901,
					110.916
				},
				{
					"Idlewood",
					1812.62,
					-1852.87,
					-89.084,
					1971.66,
					-1742.31,
					110.916
				},
				{
					"Ocean Docks",
					2089,
					-2394.33,
					-89.084,
					2201.82,
					-2235.84,
					110.916
				},
				{
					"Commerce",
					1370.85,
					-1577.59,
					-89.084,
					1463.9,
					-1384.95,
					110.916
				},
				{
					"Julius Thruway North",
					2121.4,
					2508.23,
					-89.084,
					2237.4,
					2663.17,
					110.916
				},
				{
					"Temple",
					1096.47,
					-1026.33,
					-89.084,
					1252.33,
					-910.17,
					110.916
				},
				{
					"Glen Park",
					1812.62,
					-1449.67,
					-89.084,
					1996.91,
					-1350.72,
					110.916
				},
				{
					"Easter Bay Airport",
					-1242.98,
					-50.096,
					0,
					-1213.91,
					578.396,
					200
				},
				{
					"Martin Bridge",
					-222.179,
					293.324,
					0,
					-122.126,
					476.465,
					200
				},
				{
					"The Strip",
					2106.7,
					1863.23,
					-89.084,
					2162.39,
					2202.76,
					110.916
				},
				{
					"Willowfield",
					2541.7,
					-2059.23,
					-89.084,
					2703.58,
					-1941.4,
					110.916
				},
				{
					"Marina",
					807.922,
					-1577.59,
					-89.084,
					926.922,
					-1416.25,
					110.916
				},
				{
					"Las Venturas Airport",
					1457.37,
					1143.21,
					-89.084,
					1777.4,
					1203.28,
					110.916
				},
				{
					"Idlewood",
					1812.62,
					-1742.31,
					-89.084,
					1951.66,
					-1602.31,
					110.916
				},
				{
					"Esplanade East",
					-1580.01,
					1025.98,
					-6.1,
					-1499.89,
					1274.26,
					200
				},
				{
					"Downtown Los Santos",
					1370.85,
					-1384.95,
					-89.084,
					1463.9,
					-1170.87,
					110.916
				},
				{
					"The Mako Span",
					1664.62,
					401.75,
					0,
					1785.14,
					567.203,
					200
				},
				{
					"Rodeo",
					312.803,
					-1684.65,
					-89.084,
					422.68,
					-1501.95,
					110.916
				},
				{
					"Pershing Square",
					1440.9,
					-1722.26,
					-89.084,
					1583.5,
					-1577.59,
					110.916
				},
				{
					"Mulholland",
					687.802,
					-860.619,
					-89.084,
					911.802,
					-768.027,
					110.916
				},
				{
					"Gant Bridge",
					-2741.07,
					1490.47,
					-6.1,
					-2616.4,
					1659.68,
					200
				},
				{
					"Las Colinas",
					2185.33,
					-1154.59,
					-89.084,
					2281.45,
					-934.489,
					110.916
				},
				{
					"Mulholland",
					1169.13,
					-910.17,
					-89.084,
					1318.13,
					-768.027,
					110.916
				},
				{
					"Julius Thruway North",
					1938.8,
					2508.23,
					-89.084,
					2121.4,
					2624.23,
					110.916
				},
				{
					"Commerce",
					1667.96,
					-1577.59,
					-89.084,
					1812.62,
					-1430.87,
					110.916
				},
				{
					"Rodeo",
					72.648,
					-1544.17,
					-89.084,
					225.165,
					-1404.97,
					110.916
				},
				{
					"Roca Escalante",
					2536.43,
					2202.76,
					-89.084,
					2625.16,
					2442.55,
					110.916
				},
				{
					"Rodeo",
					72.648,
					-1684.65,
					-89.084,
					225.165,
					-1544.17,
					110.916
				},
				{
					"Market",
					952.663,
					-1310.21,
					-89.084,
					1072.66,
					-1130.85,
					110.916
				},
				{
					"Las Colinas",
					2632.74,
					-1135.04,
					-89.084,
					2747.74,
					-945.035,
					110.916
				},
				{
					"Mulholland",
					861.085,
					-674.885,
					-89.084,
					1156.55,
					-600.896,
					110.916
				},
				{
					"King's",
					-2253.54,
					373.539,
					-9.1,
					-1993.28,
					458.411,
					200
				},
				{
					"Redsands East",
					1848.4,
					2342.83,
					-89.084,
					2011.94,
					2478.49,
					110.916
				},
				{
					"Downtown",
					-1580.01,
					744.267,
					-6.1,
					-1499.89,
					1025.98,
					200
				},
				{
					"Conference Center",
					1046.15,
					-1804.21,
					-89.084,
					1323.9,
					-1722.26,
					110.916
				},
				{
					"Richman",
					647.557,
					-1118.28,
					-89.084,
					787.461,
					-954.662,
					110.916
				},
				{
					"Ocean Flats",
					-2994.49,
					277.411,
					-9.1,
					-2867.85,
					458.411,
					200
				},
				{
					"Greenglass College",
					964.391,
					930.89,
					-89.084,
					1166.53,
					1044.69,
					110.916
				},
				{
					"Glen Park",
					1812.62,
					-1100.82,
					-89.084,
					1994.33,
					-973.38,
					110.916
				},
				{
					"LVA Freight Depot",
					1375.6,
					919.447,
					-89.084,
					1457.37,
					1203.28,
					110.916
				},
				{
					"Regular Tom",
					-405.77,
					1712.86,
					-3,
					-276.719,
					1892.75,
					200
				},
				{
					"Verona Beach",
					1161.52,
					-1722.26,
					-89.084,
					1323.9,
					-1577.59,
					110.916
				},
				{
					"East Los Santos",
					2281.45,
					-1372.04,
					-89.084,
					2381.68,
					-1135.04,
					110.916
				},
				{
					"Caligula's Palace",
					2137.4,
					1703.23,
					-89.084,
					2437.39,
					1783.23,
					110.916
				},
				{
					"Idlewood",
					1951.66,
					-1742.31,
					-89.084,
					2124.66,
					-1602.31,
					110.916
				},
				{
					"Pilgrim",
					2624.4,
					1383.23,
					-89.084,
					2685.16,
					1783.23,
					110.916
				},
				{
					"Idlewood",
					2124.66,
					-1742.31,
					-89.084,
					2222.56,
					-1494.03,
					110.916
				},
				{
					"Queens",
					-2533.04,
					458.411,
					0,
					-2329.31,
					578.396,
					200
				},
				{
					"Downtown",
					-1871.72,
					1176.42,
					-4.5,
					-1620.3,
					1274.26,
					200
				},
				{
					"Commerce",
					1583.5,
					-1722.26,
					-89.084,
					1758.9,
					-1577.59,
					110.916
				},
				{
					"East Los Santos",
					2381.68,
					-1454.35,
					-89.084,
					2462.13,
					-1135.04,
					110.916
				},
				{
					"Marina",
					647.712,
					-1577.59,
					-89.084,
					807.922,
					-1416.25,
					110.916
				},
				{
					"Richman",
					72.648,
					-1404.97,
					-89.084,
					225.165,
					-1235.07,
					110.916
				},
				{
					"Vinewood",
					647.712,
					-1416.25,
					-89.084,
					787.461,
					-1227.28,
					110.916
				},
				{
					"East Los Santos",
					2222.56,
					-1628.53,
					-89.084,
					2421.03,
					-1494.03,
					110.916
				},
				{
					"Rodeo",
					558.099,
					-1684.65,
					-89.084,
					647.522,
					-1384.93,
					110.916
				},
				{
					"Easter Tunnel",
					-1709.71,
					-833.034,
					-1.5,
					-1446.01,
					-730.118,
					200
				},
				{
					"Rodeo",
					466.223,
					-1385.07,
					-89.084,
					647.522,
					-1235.07,
					110.916
				},
				{
					"Redsands East",
					1817.39,
					2202.76,
					-89.084,
					2011.94,
					2342.83,
					110.916
				},
				{
					"The Clown's Pocket",
					2162.39,
					1783.23,
					-89.084,
					2437.39,
					1883.23,
					110.916
				},
				{
					"Idlewood",
					1971.66,
					-1852.87,
					-89.084,
					2222.56,
					-1742.31,
					110.916
				},
				{
					"Montgomery Intersection",
					1546.65,
					208.164,
					0,
					1745.83,
					347.457,
					200
				},
				{
					"Willowfield",
					2089,
					-2235.84,
					-89.084,
					2201.82,
					-1989.9,
					110.916
				},
				{
					"Temple",
					952.663,
					-1130.84,
					-89.084,
					1096.47,
					-937.184,
					110.916
				},
				{
					"Prickle Pine",
					1848.4,
					2553.49,
					-89.084,
					1938.8,
					2863.23,
					110.916
				},
				{
					"Los Santos International",
					1400.97,
					-2669.26,
					-39.084,
					2189.82,
					-2597.26,
					60.916
				},
				{
					"Garver Bridge",
					-1213.91,
					950.022,
					-89.084,
					-1087.93,
					1178.93,
					110.916
				},
				{
					"Garver Bridge",
					-1339.89,
					828.129,
					-89.084,
					-1213.91,
					1057.04,
					110.916
				},
				{
					"Kincaid Bridge",
					-1339.89,
					599.218,
					-89.084,
					-1213.91,
					828.129,
					110.916
				},
				{
					"Kincaid Bridge",
					-1213.91,
					721.111,
					-89.084,
					-1087.93,
					950.022,
					110.916
				},
				{
					"Verona Beach",
					930.221,
					-2006.78,
					-89.084,
					1073.22,
					-1804.21,
					110.916
				},
				{
					"Verdant Bluffs",
					1073.22,
					-2006.78,
					-89.084,
					1249.62,
					-1842.27,
					110.916
				},
				{
					"Vinewood",
					787.461,
					-1130.84,
					-89.084,
					952.604,
					-954.662,
					110.916
				},
				{
					"Vinewood",
					787.461,
					-1310.21,
					-89.084,
					952.663,
					-1130.84,
					110.916
				},
				{
					"Commerce",
					1463.9,
					-1577.59,
					-89.084,
					1667.96,
					-1430.87,
					110.916
				},
				{
					"Market",
					787.461,
					-1416.25,
					-89.084,
					1072.66,
					-1310.21,
					110.916
				},
				{
					"Rockshore West",
					2377.39,
					596.349,
					-89.084,
					2537.39,
					788.894,
					110.916
				},
				{
					"Julius Thruway North",
					2237.4,
					2542.55,
					-89.084,
					2498.21,
					2663.17,
					110.916
				},
				{
					"East Beach",
					2632.83,
					-1668.13,
					-89.084,
					2747.74,
					-1393.42,
					110.916
				},
				{
					"Fallow Bridge",
					434.341,
					366.572,
					0,
					603.035,
					555.68,
					200
				},
				{
					"Willowfield",
					2089,
					-1989.9,
					-89.084,
					2324,
					-1852.87,
					110.916
				},
				{
					"Chinatown",
					-2274.17,
					578.396,
					-7.6,
					-2078.67,
					744.17,
					200
				},
				{
					"El Castillo del Diablo",
					-208.57,
					2337.18,
					0,
					8.43,
					2487.18,
					200
				},
				{
					"Ocean Docks",
					2324,
					-2145.1,
					-89.084,
					2703.58,
					-2059.23,
					110.916
				},
				{
					"Easter Bay Chemicals",
					-1132.82,
					-768.027,
					0,
					-956.476,
					-578.118,
					200
				},
				{
					"The Visage",
					1817.39,
					1703.23,
					-89.084,
					2027.4,
					1863.23,
					110.916
				},
				{
					"Ocean Flats",
					-2994.49,
					-430.276,
					-1.2,
					-2831.89,
					-222.589,
					200
				},
				{
					"Richman",
					321.356,
					-860.619,
					-89.084,
					687.802,
					-768.027,
					110.916
				},
				{
					"Green Palms",
					176.581,
					1305.45,
					-3,
					338.658,
					1520.72,
					200
				},
				{
					"Richman",
					321.356,
					-768.027,
					-89.084,
					700.794,
					-674.885,
					110.916
				},
				{
					"Starfish Casino",
					2162.39,
					1883.23,
					-89.084,
					2437.39,
					2012.18,
					110.916
				},
				{
					"East Beach",
					2747.74,
					-1668.13,
					-89.084,
					2959.35,
					-1498.62,
					110.916
				},
				{
					"Jefferson",
					2056.86,
					-1372.04,
					-89.084,
					2281.45,
					-1210.74,
					110.916
				},
				{
					"Downtown Los Santos",
					1463.9,
					-1290.87,
					-89.084,
					1724.76,
					-1150.87,
					110.916
				},
				{
					"Downtown Los Santos",
					1463.9,
					-1430.87,
					-89.084,
					1724.76,
					-1290.87,
					110.916
				},
				{
					"Garver Bridge",
					-1499.89,
					696.442,
					-179.615,
					-1339.89,
					925.353,
					20.385
				},
				{
					"Julius Thruway South",
					1457.39,
					823.228,
					-89.084,
					2377.39,
					863.229,
					110.916
				},
				{
					"East Los Santos",
					2421.03,
					-1628.53,
					-89.084,
					2632.83,
					-1454.35,
					110.916
				},
				{
					"Greenglass College",
					964.391,
					1044.69,
					-89.084,
					1197.39,
					1203.22,
					110.916
				},
				{
					"Las Colinas",
					2747.74,
					-1120.04,
					-89.084,
					2959.35,
					-945.035,
					110.916
				},
				{
					"Mulholland",
					737.573,
					-768.027,
					-89.084,
					1142.29,
					-674.885,
					110.916
				},
				{
					"Ocean Docks",
					2201.82,
					-2730.88,
					-89.084,
					2324,
					-2418.33,
					110.916
				},
				{
					"East Los Santos",
					2462.13,
					-1454.35,
					-89.084,
					2581.73,
					-1135.04,
					110.916
				},
				{
					"Ganton",
					2222.56,
					-1722.33,
					-89.084,
					2632.83,
					-1628.53,
					110.916
				},
				{
					"Avispa Country Club",
					-2831.89,
					-430.276,
					-6.1,
					-2646.4,
					-222.589,
					200
				},
				{
					"Willowfield",
					1970.62,
					-2179.25,
					-89.084,
					2089,
					-1852.87,
					110.916
				},
				{
					"Esplanade North",
					-1982.32,
					1274.26,
					-4.5,
					-1524.24,
					1358.9,
					200
				},
				{
					"The High Roller",
					1817.39,
					1283.23,
					-89.084,
					2027.39,
					1469.23,
					110.916
				},
				{
					"Ocean Docks",
					2201.82,
					-2418.33,
					-89.084,
					2324,
					-2095,
					110.916
				},
				{
					"Last Dime Motel",
					1823.08,
					596.349,
					-89.084,
					1997.22,
					823.228,
					110.916
				},
				{
					"Bayside Marina",
					-2353.17,
					2275.79,
					0,
					-2153.17,
					2475.79,
					200
				},
				{
					"King's",
					-2329.31,
					458.411,
					-7.6,
					-1993.28,
					578.396,
					200
				},
				{
					"El Corona",
					1692.62,
					-2179.25,
					-89.084,
					1812.62,
					-1842.27,
					110.916
				},
				{
					"Blackfield Chapel",
					1375.6,
					596.349,
					-89.084,
					1558.09,
					823.228,
					110.916
				},
				{
					"The Pink Swan",
					1817.39,
					1083.23,
					-89.084,
					2027.39,
					1283.23,
					110.916
				},
				{
					"Julius Thruway West",
					1197.39,
					1163.39,
					-89.084,
					1236.63,
					2243.23,
					110.916
				},
				{
					"Los Flores",
					2581.73,
					-1393.42,
					-89.084,
					2747.74,
					-1135.04,
					110.916
				},
				{
					"The Visage",
					1817.39,
					1863.23,
					-89.084,
					2106.7,
					2011.83,
					110.916
				},
				{
					"Prickle Pine",
					1938.8,
					2624.23,
					-89.084,
					2121.4,
					2861.55,
					110.916
				},
				{
					"Verona Beach",
					851.449,
					-1804.21,
					-89.084,
					1046.15,
					-1577.59,
					110.916
				},
				{
					"Robada Intersection",
					-1119.01,
					1178.93,
					-89.084,
					-862.025,
					1351.45,
					110.916
				},
				{
					"Linden Side",
					2749.9,
					943.235,
					-89.084,
					2923.39,
					1198.99,
					110.916
				},
				{
					"Ocean Docks",
					2703.58,
					-2302.33,
					-89.084,
					2959.35,
					-2126.9,
					110.916
				},
				{
					"Willowfield",
					2324,
					-2059.23,
					-89.084,
					2541.7,
					-1852.87,
					110.916
				},
				{
					"King's",
					-2411.22,
					265.243,
					-9.1,
					-1993.28,
					373.539,
					200
				},
				{
					"Commerce",
					1323.9,
					-1842.27,
					-89.084,
					1701.9,
					-1722.26,
					110.916
				},
				{
					"Mulholland",
					1269.13,
					-768.027,
					-89.084,
					1414.07,
					-452.425,
					110.916
				},
				{
					"Marina",
					647.712,
					-1804.21,
					-89.084,
					851.449,
					-1577.59,
					110.916
				},
				{
					"Battery Point",
					-2741.07,
					1268.41,
					-4.5,
					-2533.04,
					1490.47,
					200
				},
				{
					"The Four Dragons Casino",
					1817.39,
					863.232,
					-89.084,
					2027.39,
					1083.23,
					110.916
				},
				{
					"Blackfield",
					964.391,
					1203.22,
					-89.084,
					1197.39,
					1403.22,
					110.916
				},
				{
					"Julius Thruway North",
					1534.56,
					2433.23,
					-89.084,
					1848.4,
					2583.23,
					110.916
				},
				{
					"Yellow Bell Gol Course",
					1117.4,
					2723.23,
					-89.084,
					1457.46,
					2863.23,
					110.916
				},
				{
					"Idlewood",
					1812.62,
					-1602.31,
					-89.084,
					2124.66,
					-1449.67,
					110.916
				},
				{
					"Redsands West",
					1297.47,
					2142.86,
					-89.084,
					1777.39,
					2243.23,
					110.916
				},
				{
					"Doherty",
					-2270.04,
					-324.114,
					-1.2,
					-1794.92,
					-222.589,
					200
				},
				{
					"Hilltop Farm",
					967.383,
					-450.39,
					-3,
					1176.78,
					-217.9,
					200
				},
				{
					"Las Barrancas",
					-926.13,
					1398.73,
					-3,
					-719.234,
					1634.69,
					200
				},
				{
					"Pirates in Men's Pants",
					1817.39,
					1469.23,
					-89.084,
					2027.4,
					1703.23,
					110.916
				},
				{
					"City Hall",
					-2867.85,
					277.411,
					-9.1,
					-2593.44,
					458.411,
					200
				},
				{
					"Avispa Country Club",
					-2646.4,
					-355.493,
					0,
					-2270.04,
					-222.589,
					200
				},
				{
					"The Strip",
					2027.4,
					863.229,
					-89.084,
					2087.39,
					1703.23,
					110.916
				},
				{
					"Hashbury",
					-2593.44,
					-222.589,
					-1,
					-2411.22,
					54.722,
					200
				},
				{
					"Los Santos International",
					1852,
					-2394.33,
					-89.084,
					2089,
					-2179.25,
					110.916
				},
				{
					"Whitewood Estates",
					1098.31,
					1726.22,
					-89.084,
					1197.39,
					2243.23,
					110.916
				},
				{
					"Sherman Reservoir",
					-789.737,
					1659.68,
					-89.084,
					-599.505,
					1929.41,
					110.916
				},
				{
					"El Corona",
					1812.62,
					-2179.25,
					-89.084,
					1970.62,
					-1852.87,
					110.916
				},
				{
					"Downtown",
					-1700.01,
					744.267,
					-6.1,
					-1580.01,
					1176.52,
					200
				},
				{
					"Foster keyley",
					-2178.69,
					-1250.97,
					0,
					-1794.92,
					-1115.58,
					200
				},
				{
					"Las Payasadas",
					-354.332,
					2580.36,
					2,
					-133.625,
					2816.82,
					200
				},
				{
					"keyle Ocultado",
					-936.668,
					2611.44,
					2,
					-715.961,
					2847.9,
					200
				},
				{
					"Blackfield Intersection",
					1166.53,
					795.01,
					-89.084,
					1375.6,
					1044.69,
					110.916
				},
				{
					"Ganton",
					2222.56,
					-1852.87,
					-89.084,
					2632.83,
					-1722.33,
					110.916
				},
				{
					"Easter Bay Airport",
					-1213.91,
					-730.118,
					0,
					-1132.82,
					-50.096,
					200
				},
				{
					"Redsands East",
					1817.39,
					2011.83,
					-89.084,
					2106.7,
					2202.76,
					110.916
				},
				{
					"Esplanade East",
					-1499.89,
					578.396,
					-79.615,
					-1339.89,
					1274.26,
					20.385
				},
				{
					"Caligula's Palace",
					2087.39,
					1543.23,
					-89.084,
					2437.39,
					1703.23,
					110.916
				},
				{
					"Royal Casino",
					2087.39,
					1383.23,
					-89.084,
					2437.39,
					1543.23,
					110.916
				},
				{
					"Richman",
					72.648,
					-1235.07,
					-89.084,
					321.356,
					-1008.15,
					110.916
				},
				{
					"Starfish Casino",
					2437.39,
					1783.23,
					-89.084,
					2685.16,
					2012.18,
					110.916
				},
				{
					"Mulholland",
					1281.13,
					-452.425,
					-89.084,
					1641.13,
					-290.913,
					110.916
				},
				{
					"Downtown",
					-1982.32,
					744.17,
					-6.1,
					-1871.72,
					1274.26,
					200
				},
				{
					"Hankypanky Point",
					2576.92,
					62.158,
					0,
					2759.25,
					385.503,
					200
				},
				{
					"K.A.C.C. Military Fuels",
					2498.21,
					2626.55,
					-89.084,
					2749.9,
					2861.55,
					110.916
				},
				{
					"Harry Gold Parkway",
					1777.39,
					863.232,
					-89.084,
					1817.39,
					2342.83,
					110.916
				},
				{
					"Bayside Tunnel",
					-2290.19,
					2548.29,
					-89.084,
					-1950.19,
					2723.29,
					110.916
				},
				{
					"Ocean Docks",
					2324,
					-2302.33,
					-89.084,
					2703.58,
					-2145.1,
					110.916
				},
				{
					"Richman",
					321.356,
					-1044.07,
					-89.084,
					647.557,
					-860.619,
					110.916
				},
				{
					"Randolph Industrial Estate",
					1558.09,
					596.349,
					-89.084,
					1823.08,
					823.235,
					110.916
				},
				{
					"East Beach",
					2632.83,
					-1852.87,
					-89.084,
					2959.35,
					-1668.13,
					110.916
				},
				{
					"Flint Water",
					-314.426,
					-753.874,
					-89.084,
					-106.339,
					-463.073,
					110.916
				},
				{
					"Blueberry",
					19.607,
					-404.136,
					3.8,
					349.607,
					-220.137,
					200
				},
				{
					"Linden Station",
					2749.9,
					1198.99,
					-89.084,
					2923.39,
					1548.99,
					110.916
				},
				{
					"Glen Park",
					1812.62,
					-1350.72,
					-89.084,
					2056.86,
					-1100.82,
					110.916
				},
				{
					"Downtown",
					-1993.28,
					265.243,
					-9.1,
					-1794.92,
					578.396,
					200
				},
				{
					"Redsands West",
					1377.39,
					2243.23,
					-89.084,
					1704.59,
					2433.23,
					110.916
				},
				{
					"Richman",
					321.356,
					-1235.07,
					-89.084,
					647.522,
					-1044.07,
					110.916
				},
				{
					"Gant Bridge",
					-2741.45,
					1659.68,
					-6.1,
					-2616.4,
					2175.15,
					200
				},
				{
					"Lil' Probe Inn",
					-90.218,
					1286.85,
					-3,
					153.859,
					1554.12,
					200
				},
				{
					"Flint Intersection",
					-187.7,
					-1596.76,
					-89.084,
					17.063,
					-1276.6,
					110.916
				},
				{
					"Las Colinas",
					2281.45,
					-1135.04,
					-89.084,
					2632.74,
					-945.035,
					110.916
				},
				{
					"Sobell Rail Yards",
					2749.9,
					1548.99,
					-89.084,
					2923.39,
					1937.25,
					110.916
				},
				{
					"The Emerald Isle",
					2011.94,
					2202.76,
					-89.084,
					2237.4,
					2508.23,
					110.916
				},
				{
					"El Castillo del Diablo",
					-208.57,
					2123.01,
					-7.6,
					114.033,
					2337.18,
					200
				},
				{
					"Santa Flora",
					-2741.07,
					458.411,
					-7.6,
					-2533.04,
					793.411,
					200
				},
				{
					"Playa del Seville",
					2703.58,
					-2126.9,
					-89.084,
					2959.35,
					-1852.87,
					110.916
				},
				{
					"Market",
					926.922,
					-1577.59,
					-89.084,
					1370.85,
					-1416.25,
					110.916
				},
				{
					"Queens",
					-2593.44,
					54.722,
					0,
					-2411.22,
					458.411,
					200
				},
				{
					"Pilson Intersection",
					1098.39,
					2243.23,
					-89.084,
					1377.39,
					2507.23,
					110.916
				},
				{
					"Spinybed",
					2121.4,
					2663.17,
					-89.084,
					2498.21,
					2861.55,
					110.916
				},
				{
					"Pilgrim",
					2437.39,
					1383.23,
					-89.084,
					2624.4,
					1783.23,
					110.916
				},
				{
					"Blackfield",
					964.391,
					1403.22,
					-89.084,
					1197.39,
					1726.22,
					110.916
				},
				{
					"'The Big Ear'",
					-410.02,
					1403.34,
					-3,
					-137.969,
					1681.23,
					200
				},
				{
					"Dillimore",
					580.794,
					-674.885,
					-9.5,
					861.085,
					-404.79,
					200
				},
				{
					"El Quebrados",
					-1645.23,
					2498.52,
					0,
					-1372.14,
					2777.85,
					200
				},
				{
					"Esplanade North",
					-2533.04,
					1358.9,
					-4.5,
					-1996.66,
					1501.21,
					200
				},
				{
					"Easter Bay Airport",
					-1499.89,
					-50.096,
					-1,
					-1242.98,
					249.904,
					200
				},
				{
					"Fisher's Lagoon",
					1916.99,
					-233.323,
					-100,
					2131.72,
					13.8,
					200
				},
				{
					"Mulholland",
					1414.07,
					-768.027,
					-89.084,
					1667.61,
					-452.425,
					110.916
				},
				{
					"East Beach",
					2747.74,
					-1498.62,
					-89.084,
					2959.35,
					-1120.04,
					110.916
				},
				{
					"San Andreas Sound",
					2450.39,
					385.503,
					-100,
					2759.25,
					562.349,
					200
				},
				{
					"Shady Creeks",
					-2030.12,
					-2174.89,
					-6.1,
					-1820.64,
					-1771.66,
					200
				},
				{
					"Market",
					1072.66,
					-1416.25,
					-89.084,
					1370.85,
					-1130.85,
					110.916
				},
				{
					"Rockshore West",
					1997.22,
					596.349,
					-89.084,
					2377.39,
					823.228,
					110.916
				},
				{
					"Prickle Pine",
					1534.56,
					2583.23,
					-89.084,
					1848.4,
					2863.23,
					110.916
				},
				{
					"Easter Basin",
					-1794.92,
					-50.096,
					-1.04,
					-1499.89,
					249.904,
					200
				},
				{
					"Leafy Hollow",
					-1166.97,
					-1856.03,
					0,
					-815.624,
					-1602.07,
					200
				},
				{
					"LVA Freight Depot",
					1457.39,
					863.229,
					-89.084,
					1777.4,
					1143.21,
					110.916
				},
				{
					"Prickle Pine",
					1117.4,
					2507.23,
					-89.084,
					1534.56,
					2723.23,
					110.916
				},
				{
					"Blueberry",
					104.534,
					-220.137,
					2.3,
					349.607,
					152.236,
					200
				},
				{
					"El Castillo del Diablo",
					-464.515,
					2217.68,
					0,
					-208.57,
					2580.36,
					200
				},
				{
					"Downtown",
					-2078.67,
					578.396,
					-7.6,
					-1499.89,
					744.267,
					200
				},
				{
					"Rockshore East",
					2537.39,
					676.549,
					-89.084,
					2902.35,
					943.235,
					110.916
				},
				{
					"San Fierro Bay",
					-2616.4,
					1501.21,
					-3,
					-1996.66,
					1659.68,
					200
				},
				{
					"Paradiso",
					-2741.07,
					793.411,
					-6.1,
					-2533.04,
					1268.41,
					200
				},
				{
					"The Camel's Toe",
					2087.39,
					1203.23,
					-89.084,
					2640.4,
					1383.23,
					110.916
				},
				{
					"Old Venturas Strip",
					2162.39,
					2012.18,
					-89.084,
					2685.16,
					2202.76,
					110.916
				},
				{
					"Juniper Hill",
					-2533.04,
					578.396,
					-7.6,
					-2274.17,
					968.369,
					200
				},
				{
					"Juniper Hollow",
					-2533.04,
					968.369,
					-6.1,
					-2274.17,
					1358.9,
					200
				},
				{
					"Roca Escalante",
					2237.4,
					2202.76,
					-89.084,
					2536.43,
					2542.55,
					110.916
				},
				{
					"Julius Thruway East",
					2685.16,
					1055.96,
					-89.084,
					2749.9,
					2626.55,
					110.916
				},
				{
					"Verona Beach",
					647.712,
					-2173.29,
					-89.084,
					930.221,
					-1804.21,
					110.916
				},
				{
					"Foster keyley",
					-2178.69,
					-599.884,
					-1.2,
					-1794.92,
					-324.114,
					200
				},
				{
					"Arco del Oeste",
					-901.129,
					2221.86,
					0,
					-592.09,
					2571.97,
					200
				},
				{
					"Fallen Tree",
					-792.254,
					-698.555,
					-5.3,
					-452.404,
					-380.043,
					200
				},
				{
					"The Farm",
					-1209.67,
					-1317.1,
					114.981,
					-908.161,
					-787.391,
					251.981
				},
				{
					"The Sherman Dam",
					-968.772,
					1929.41,
					-3,
					-481.126,
					2155.26,
					200
				},
				{
					"Esplanade North",
					-1996.66,
					1358.9,
					-4.5,
					-1524.24,
					1592.51,
					200
				},
				{
					"Financial",
					-1871.72,
					744.17,
					-6.1,
					-1701.3,
					1176.42,
					300
				},
				{
					"Garcia",
					-2411.22,
					-222.589,
					-1.14,
					-2173.04,
					265.243,
					200
				},
				{
					"Montgomery",
					1119.51,
					119.526,
					-3,
					1451.4,
					493.323,
					200
				},
				{
					"Creek",
					2749.9,
					1937.25,
					-89.084,
					2921.62,
					2669.79,
					110.916
				},
				{
					"Los Santos International",
					1249.62,
					-2394.33,
					-89.084,
					1852,
					-2179.25,
					110.916
				},
				{
					"Santa Maria Beach",
					72.648,
					-2173.29,
					-89.084,
					342.648,
					-1684.65,
					110.916
				},
				{
					"Mulholland Intersection",
					1463.9,
					-1150.87,
					-89.084,
					1812.62,
					-768.027,
					110.916
				},
				{
					"Angel Pine",
					-2324.94,
					-2584.29,
					-6.1,
					-1964.22,
					-2212.11,
					200
				},
				{
					"Verdant Meadows",
					37.032,
					2337.18,
					-3,
					435.988,
					2677.9,
					200
				},
				{
					"Octane Springs",
					338.658,
					1228.51,
					0,
					664.308,
					1655.05,
					200
				},
				{
					"Come-A-Lot",
					2087.39,
					943.235,
					-89.084,
					2623.18,
					1203.23,
					110.916
				},
				{
					"Redsands West",
					1236.63,
					1883.11,
					-89.084,
					1777.39,
					2142.86,
					110.916
				},
				{
					"Santa Maria Beach",
					342.648,
					-2173.29,
					-89.084,
					647.712,
					-1684.65,
					110.916
				},
				{
					"Verdant Bluffs",
					1249.62,
					-2179.25,
					-89.084,
					1692.62,
					-1842.27,
					110.916
				},
				{
					"Las Venturas Airport",
					1236.63,
					1203.28,
					-89.084,
					1457.37,
					1883.11,
					110.916
				},
				{
					"Flint Range",
					-594.191,
					-1648.55,
					0,
					-187.7,
					-1276.6,
					200
				},
				{
					"Verdant Bluffs",
					930.221,
					-2488.42,
					-89.084,
					1249.62,
					-2006.78,
					110.916
				},
				{
					"Palomino Creek",
					2160.22,
					-149.004,
					0,
					2576.92,
					228.322,
					200
				},
				{
					"Ocean Docks",
					2373.77,
					-2697.09,
					-89.084,
					2809.22,
					-2330.46,
					110.916
				},
				{
					"Easter Bay Airport",
					-1213.91,
					-50.096,
					-4.5,
					-947.98,
					578.396,
					200
				},
				{
					"Whitewood Estates",
					883.308,
					1726.22,
					-89.084,
					1098.31,
					2507.23,
					110.916
				},
				{
					"Calton Heights",
					-2274.17,
					744.17,
					-6.1,
					-1982.32,
					1358.9,
					200
				},
				{
					"Easter Basin",
					-1794.92,
					249.904,
					-9.1,
					-1242.98,
					578.396,
					200
				},
				{
					"Los Santos Inlet",
					-321.744,
					-2224.43,
					-89.084,
					44.615,
					-1724.43,
					110.916
				},
				{
					"Doherty",
					-2173.04,
					-222.589,
					-1,
					-1794.92,
					265.243,
					200
				},
				{
					"Mount Chiliad",
					-2178.69,
					-2189.91,
					-47.917,
					-2030.12,
					-1771.66,
					576.083
				},
				{
					"Fort Carson",
					-376.233,
					826.326,
					-3,
					123.717,
					1220.44,
					200
				},
				{
					"Foster keyley",
					-2178.69,
					-1115.58,
					0,
					-1794.92,
					-599.884,
					200
				},
				{
					"Ocean Flats",
					-2994.49,
					-222.589,
					-1,
					-2593.44,
					277.411,
					200
				},
				{
					"Fern Ridge",
					508.189,
					-139.259,
					0,
					1306.66,
					119.526,
					200
				},
				{
					"Bayside",
					-2741.07,
					2175.15,
					0,
					-2353.17,
					2722.79,
					200
				},
				{
					"Las Venturas Airport",
					1457.37,
					1203.28,
					-89.084,
					1777.39,
					1883.11,
					110.916
				},
				{
					"Blueberry Acres",
					-319.676,
					-220.137,
					0,
					104.534,
					293.324,
					200
				},
				{
					"Palisades",
					-2994.49,
					458.411,
					-6.1,
					-2741.07,
					1339.61,
					200
				},
				{
					"North Rock",
					2285.37,
					-768.027,
					0,
					2770.59,
					-269.74,
					200
				},
				{
					"Hunter Quarry",
					337.244,
					710.84,
					-115.239,
					860.554,
					1031.71,
					203.761
				},
				{
					"Los Santos International",
					1382.73,
					-2730.88,
					-89.084,
					2201.82,
					-2394.33,
					110.916
				},
				{
					"Missionary Hill",
					-2994.49,
					-811.276,
					0,
					-2178.69,
					-430.276,
					200
				},
				{
					"San Fierro Bay",
					-2616.4,
					1659.68,
					-3,
					-1996.66,
					2175.15,
					200
				},
				{
					"Restricted Area",
					-91.586,
					1655.05,
					-50,
					421.234,
					2123.01,
					250
				},
				{
					"Mount Chiliad",
					-2997.47,
					-1115.58,
					-47.917,
					-2178.69,
					-971.913,
					576.083
				},
				{
					"Mount Chiliad",
					-2178.69,
					-1771.66,
					-47.917,
					-1936.12,
					-1250.97,
					576.083
				},
				{
					"Easter Bay Airport",
					-1794.92,
					-730.118,
					-3,
					-1213.91,
					-50.096,
					200
				},
				{
					"The Panopticon",
					-947.98,
					-304.32,
					-1.1,
					-319.676,
					327.071,
					200
				},
				{
					"Shady Creeks",
					-1820.64,
					-2643.68,
					-8,
					-1226.78,
					-1771.66,
					200
				},
				{
					"Back o Beyond",
					-1166.97,
					-2641.19,
					0,
					-321.744,
					-1856.03,
					200
				},
				{
					"Mount Chiliad",
					-2994.49,
					-2189.91,
					-47.917,
					-2178.69,
					-1115.58,
					576.083
				},
				{
					"Tierra Robada",
					-1213.91,
					596.349,
					-242.99,
					-480.539,
					1659.68,
					900
				},
				{
					"Flint County",
					-1213.91,
					-2892.97,
					-242.99,
					44.615,
					-768.027,
					900
				},
				{
					"Whetstone",
					-2997.47,
					-2892.97,
					-242.99,
					-1213.91,
					-1115.58,
					900
				},
				{
					"Bone County",
					-480.539,
					596.349,
					-242.99,
					869.461,
					2993.87,
					900
				},
				{
					"Tierra Robada",
					-2997.47,
					1659.68,
					-242.99,
					-480.539,
					2993.87,
					900
				},
				{
					"San Fierro",
					-2997.47,
					-1115.58,
					-242.99,
					-1213.91,
					1659.68,
					900
				},
				{
					"Las Venturas",
					869.461,
					596.349,
					-242.99,
					2997.06,
					2993.87,
					900
				},
				{
					"Red County",
					-1213.91,
					-768.027,
					-242.99,
					2997.06,
					596.349,
					900
				},
				{
					"Los Santos",
					44.615,
					-2892.97,
					-242.99,
					2997.06,
					-768.027,
					900
				}
			}

			if cordX ~= nil and cordY ~= nil and cordZ ~= nil then
				for key, key in ipairs(ulici) do
					if key[2] <= cordX and key[3] <= cordY and key[4] <= cordZ and cordX <= key[5] and cordY <= key[6] and cordZ <= key[7] then
						return key[1]
					end
				end
			end

			return "Не найдено"
		end





					function CheckGps(str)
				  		for key, key in pairs(database["HOUSE"]) do
				   			if key["num"] == str then
				  				return true
				  			 end
				  	 		end
				 			return false
				  	 	end

function darkgreentheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.60, 0.60, 0.60, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.Border]                 = ImVec4(0.70, 0.70, 0.70, 0.40)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.19, 0.19, 0.19, 0.71)
    colors[clr.FrameBgActive]          = ImVec4(0.34, 0.34, 0.34, 0.79)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.69, 0.33, 0.80)
    colors[clr.TitleBgActive]          = ImVec4(0.00, 0.74, 0.36, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.69, 0.33, 0.50)
    colors[clr.MenuBarBg]              = ImVec4(0.00, 0.80, 0.38, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.16, 0.16, 0.16, 1.00)
    colors[clr.ScrollbarGrab]          = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.00, 1.00, 0.48, 1.00)
    colors[clr.ComboBg]                = ImVec4(0.20, 0.20, 0.20, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.77, 0.37, 1.00)
    colors[clr.Button]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ButtonHovered]          = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.00, 0.87, 0.42, 1.00)
    colors[clr.Header]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.00, 0.76, 0.37, 0.57)
    colors[clr.HeaderActive]           = ImVec4(0.00, 0.88, 0.42, 0.89)
    colors[clr.Separator]              = ImVec4(1.00, 1.00, 1.00, 0.40)
    colors[clr.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.60)
    colors[clr.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 0.80)
    colors[clr.ResizeGrip]             = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.ResizeGripHovered]      = ImVec4(0.00, 0.76, 0.37, 1.00)
    colors[clr.ResizeGripActive]       = ImVec4(0.00, 0.86, 0.41, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.00, 0.82, 0.39, 1.00)
    colors[clr.CloseButtonHovered]     = ImVec4(0.00, 0.88, 0.42, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.00, 1.00, 0.48, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(0.00, 0.74, 0.36, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.00, 0.69, 0.33, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(0.00, 0.80, 0.38, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.00, 0.69, 0.33, 0.72)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.17, 0.17, 0.17, 0.48)
end
darkgreentheme()
