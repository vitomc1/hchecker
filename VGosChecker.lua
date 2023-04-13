script_version("3.3")
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

local afkgos = false

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
if not doesFileExist(getWorkingDirectory().."/config/gosChecker/settings.json") then
	local fee = io.open(getWorkingDirectory().."/config/gosChecker/settings.json", "w")
	fee:write(encodeJson({
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
if doesFileExist(getWorkingDirectory().."/config/gosChecker/settings.json") then
	local fee = io.open(getWorkingDirectory().."/config/gosChecker/settings.json", "r")
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
					local sendTG = ""..prefixTG..":  В  '"..city.."'  слетел  дом.  Было:  "..lastCurrentNumOfHouses[city]..",  а  сейчас  -  "..currentNumOfHouses[city].."  "..os.date("Время:  %H:%M:%S  Дата: %d.%m.20%y").."  ("..sampGetPlayerNickname(id)..")."
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
				elseif ip == "185.169.134.84" then
					prefixTG = "[TRP1]"
					local sendTG = ""..prefixTG..":  В  '"..city.."'  слетел  дом.  Было:  "..lastCurrentNumOfHouses[city]..",  а  сейчас  -  "..currentNumOfHouses[city].."  "..os.date("Время:  %H:%M:%S  Дата: %d.%m.20%y").."  ("..sampGetPlayerNickname(id)..")."
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
				elseif ip == "185.169.134.85" then
					prefixTG = "[TRP2]"
					local sendTG = ""..prefixTG..":  В  '"..city.."'  слетел  дом.  Было:  "..lastCurrentNumOfHouses[city]..",  а  сейчас  -  "..currentNumOfHouses[city].."  "..os.date("Время:  %H:%M:%S  Дата: %d.%m.20%y").."  ("..sampGetPlayerNickname(id)..")."
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
				wait(0)
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
		if checkInGosHouse[4] and id == 2114 then
			sampSendDialogResponse(2114, 1, 36, "")
			checkInGosHouse[4], checkInGosHouse[5] = false, true
			return false
		end
		if checkInGosHouse[5] and id == 2114 then
			sampSendDialogResponse(2114, 1, 38, "")
			checkInGosHouse[5], checkInGosHouse[6] = false, true
			return false
		end
		if checkInGosHouse[6] and id == 2116 then
			sampSendDialogResponse(2116, 1, 0, parksMin)
			checkInGosHouse[6], checkInGosHouse[7] = false, true
			return false
		end
		if checkInGosHouse[7] and id == 2118 then
			checkInGosHouse[7], checkInGosHouse[8], checkInGosHouse[9] = false, true, true
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
		if checkInGosHouse[8] and id == 2111 and text:find("По вашему запросу не найдено") then
			sampAddChatMessage("[GC]: {8be547}По вашему запросу не найдено ни одного предложения о продаже.", -1)
			sampSendDialogResponse(2111, 1, 0, "")
			checkInGosHouse[8], checkInGosHouse[9], closeDialog = false, false, true
			return false
		end
		if checkInGosHouse[9] and id == 2111 and text:find("По вашему запросу найдено") then
			local kolvoGosHouse = text:match("{fbec5d}(%d+){ffffff}")
			sampSendDialogResponse(2111, 1, 0, "")
			sampAddChatMessage("[GC]: {8be547}По вашему запросу найдено {FFFFFF}"..kolvoGosHouse.. "{8be547} предложений. Ближайшее к вам отмечено на радаре.", -1)
			checkInGosHouse[8], checkInGosHouse[9], closeDialog = false, false, true
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

	sampRegisterChatCommand("play", function()
	end)
	sampRegisterChatCommand("sliv", function()
		sampSendChat("/play")
	end)

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


				sampRegisterChatCommand("tgbc", function(send)
				local send = send:match("(.*)")

					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. maximTG .. "&text=" .. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. andreyTG .. "&text=" .. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. tomasTG .. "&text=" .. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. patricioTG .. "&text=" .. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. juniorTG .. "&text=" .. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jaiTG .. "&text=" .. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. forestTG .. "&text=" .. u8(send), "", function (result)

					end)
					async_http_request("https://api.telegram.org/bot" .. botTG .. "/sendMessage?chat_id=" .. jeysonTG .. "&text=" .. u8(send), "", function (result)

					end)
					end)

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
	local configFile = io.open(getWorkingDirectory().."/config/gosChecker/settings.json", "w")
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
