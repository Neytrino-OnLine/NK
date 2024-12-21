#!/bin/sh

VERSION="beta 0"
PROFILE_PATH='/opt/etc/nfqws'
BUTTON='/opt/etc/ndm/button.d/nk.sh'
BACKUP='/opt/backup-nk'
DNSCRYPT='/opt/etc/dnscrypt-proxy.toml'

function fileSave
	{
	local FILE_PATH="$1"
	local CONTENT="$2"
	if [ -f "$FILE_PATH" ];then
		local FILE=`basename "$FILE_PATH"`
		echo ""
		if [ -n "$CONTENT" ];then
			echo -e "\tВ: `dirname $FILE_PATH` уже существует файл: $FILE,"
		else
			echo -e "\tФайл: $FILE_PATH был перемещён в:"
		fi
		local DT=`date +"%C%y.%m.%d_%H-%M-%S"`
		local BACKUP_PATH="$BACKUP/$DT/"
		mkdir -p "$BACKUP_PATH"
		mv "$FILE_PATH" "$BACKUP_PATH$FILE"
		if [ -f "$BACKUP_PATH$FILE" ];then
			if [ -n "$CONTENT" ];then
				echo -e "\tон перемещён в каталог: $BACKUP_PATH"
			else
				echo -e "\t$BACKUP_PATH"
			fi
		else
			echo ""
			echo -e "\tОшибка: не удалось создать резервную копию файла..."
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			exit
		fi
	fi
	if [ -n "$CONTENT" ];then
		echo -e "$CONTENT" > $FILE_PATH
		echo ""
		echo -e "\tФайл: $FILE_PATH - сохранён."
	fi
	}

function copyRight
	{
	
	local YEAR="2024"
	if [ "`date +"%C%y"`" -gt "$YEAR" ];then
		local YEAR="$YEAR-`date +"%C%y"`"
	fi
	local COPYRIGHT="© $YEAR rino Software Lab."
	local COPY_LONG=`echo ${#COPYRIGHT}`
	local VER_LONG=`echo ${#VERSION}`
	local SPACE=`expr 80 - $VER_LONG - $COPY_LONG - 2`
	local SPACE="`awk -v i=$SPACE 'BEGIN { OFS=" "; $i=" "; print }'`"
	read -t 1 -n 1 -r -p " $VERSION$SPACE$COPYRIGHT" keypress
	}

function headLine
	{
	if [ "$2" = "1" ];then
		echo -e "\n\n\n\n\n\n\n\n\n\n\n\n"
	fi
	if [ -n "$1" ];then
		local TEXT=$1
		local LONG=`echo ${#TEXT}`
		local SIZE=`expr 80 - $LONG - 2`
		local SIZE=`expr $SIZE / 2`
		local FRAME=`awk -v i=$SIZE 'BEGIN { OFS="░"; $i="░"; print }'`
		if [ "`expr $LONG / 2 \* 2`" -lt "$LONG" ];then
			local SPACE='░'
		else
			local SPACE=""
		fi
		echo "$FRAME $TEXT $SPACE$FRAME"
	else
		awk -v i=80 'BEGIN { OFS="░"; $i="░"; print }'
	fi
	if [ -n "$MODE" -a -n "$1" -a ! "$2" = "1" ];then
		local LONG=`echo ${#MODE}`
		local SIZE=`expr 80 - $LONG - 1`
		local SPACE=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
		echo "$SPACE$MODE"
	elif [ -z "$MODE" -a -n "$1" -a ! "$2" = "1" ];then
		echo ""
	fi
	}

function messageBox
	{
	local TEXT=$1
	local LONG=`echo ${#TEXT}`
	if [ "`expr $LONG / 2 \* 2`" -lt "$LONG" ];then
		local TEXT="$TEXT "
		local LONG=`expr $LONG + 1`
	fi
	local SIZE=`expr 80 - $LONG - 4`
	local SIZE=`expr $SIZE / 2`
	local LINE=`awk -v i=$LONG 'BEGIN { OFS="─"; $i="─"; print }'`
	local SPACE=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
	echo "$SPACE┌─$LINE─┐$SPACE"
	echo "$SPACE│ $TEXT │$SPACE"
	echo "$SPACE└─$LINE─┘$SPACE"
	if [ ! "$2" = "1" ];then
		echo ""
	fi
	}

function profileOptimize
	{
	clear
	headLine "Оптимизация профиля"
	echo -e "\tВ процессе обновления NFQWS-Keenetic, в профиле накапливаются разные"
	echo "версии файла настроек, файлов списков и пустые файлы... Данный инструмент"
	echo "позволит вам упорядочить их содержимое и избавиться от всего лишнего."
	echo ""
	echo -e "\tПеред тем как начать процесс - настоятельно рекомендуется"
	echo "воспользоваться инструментом создания резервной копии профиля, чтобы (в случае"
	echo "возникновения проблем) - иметь возможность быстро вернуться к предыдущему"
	echo "состоянию..."
	echo ""
	echo "Хотите создать резервную копию профиля?"
	echo ""
	echo -e "\t1: Да (создать резервную копию и приступить к оптимизации)"
	echo -e "\t2: Нет (начать оптимизацию без создания резервной копии)"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		backUp "1"
		listsAndProfileOptimize
	elif [ "$REPLY" = "2" ];then
		listsAndProfileOptimize
	fi
	}

function listsAndProfileOptimize
	{
	clear
	headLine "Оптимизация списков"
	if [ "`ls "$PROFILE_PATH" | grep -c "\-old"`" -gt "0" -o "`ls "$PROFILE_PATH" | grep -c "\-opkg"`" -gt "0" ];then
		echo -e "\tПодождите..."
		local LISTS=`ls $PROFILE_PATH | grep ".list$" | awk '{gsub(/.list /,".list\n")}1'`
		local LISTS=`echo -e "$LISTS"`
		IFS=$'\n'
		for LINE in $LISTS;do
			if [ -f "$PROFILE_PATH/$LINE-old" ];then
				listConfluence "$PROFILE_PATH/$LINE-old" "$PROFILE_PATH/$LINE"
			fi
		done
		for LINE in $LISTS;do
			if [ -f "$PROFILE_PATH/$LINE-opkg" ];then
				listConfluence "$PROFILE_PATH/$LINE" "$PROFILE_PATH/$LINE-opkg"
			fi
		done
		if [ -f "$PROFILE_PATH/nfqws.conf-old" ];then
			configOptimize "$PROFILE_PATH/nfqws.conf-old" "$PROFILE_PATH/nfqws.conf"
		fi
		if [ -f "$PROFILE_PATH/nfqws.conf-opkg" ];then
			configOptimize "$PROFILE_PATH/nfqws.conf" "$PROFILE_PATH/nfqws.conf-opkg"
		fi
	else
		messageBox "Ошибка: объектов для оптимизации - не обнаружено."
	fi
	}

function listConfluence
	{
	listGet "$1"
	local CURENT_LIST=`echo -e "$LIST"`
	listGet "$2"
	local NEW_LIST=`echo -e "$LIST"`
	local NEW=""
	LIST=""
	IFS=$'\n'
	for OUT_LINE in $CURENT_LIST;do
		for IN_LINE in $NEW_LIST;do
			if [ "$OUT_LINE" = "$IN_LINE" ];then
				local NEW_LIST=`echo "$NEW_LIST" | grep -v "$IN_LINE"`
				break
			fi
		done
		if [ -z "$NEW_LIST" ];then
			break
		fi
	done
	if [ -n "$NEW_LIST" ];then
		local ADD=`echo -e "$NEW_LIST" | awk '{sub(/^sp@ce/,"")}1'`
		LIST=`echo -e "$CURENT_LIST" | awk '{sub(/^sp@ce/,"")}1'`
		LIST=`echo -e "$LIST\n\n$ADD"`
	else
		LIST=`echo -e "$CURENT_LIST" | awk '{sub(/^sp@ce/,"")}1'`
	fi
	if [ "`echo "$2" | grep -c "$1"`" -gt "0" -a "`echo "$1" | grep -c "$2"`" = "0" ];then
		fileSave "$1" "$LIST"
		fileSave "$2" ""
	else
		fileSave "$2" "$LIST"
		fileSave "$1" ""
	fi
	}

function listGet
	{
	LIST=`cat "$1" | awk '{sub(/^[[:space:]]*$/,"sp@ce")}1'`
	LIST=`echo -e "$LIST"`
	}

function backUp
	{
	clear
	headLine "Резервное копирование профиля"
	echo "Что вы хотите сделать?"
	echo ""
	echo -e "\t1: Создать резервную копию профиля NFQWS-Keenetic"
	if [ -d $BACKUP/profile ];then
		echo -e "\t2: Восстановить файлы из резервной копии"
		echo -e "\t3: Удалить резервную копию"
	fi
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		if [ -d $BACKUP/profile ];then
			echo ""
			echo -e "\tПри сохранении новой резервной копии, старая - будет полностью удалена..."
			echo ""
			echo "Создать новую резервную копию?"
			echo ""
			echo -e "\t1; Да (по умолчанию)"
			echo -e "\t0; Нет"
			echo ""
			read -r -p "Ваш выбор:"
			if [ "$REPLY" = "0" ];then
				if [ ! "$1" = "1" ];then
					backUp
				fi
			else
				rm -rf $BACKUP/profile
				mkdir -p $BACKUP/profile
				cp -r $PROFILE_PATH/*.* $BACKUP/profile
				echo ""
				echo -e "\tРезервная копия - создана."
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				if [ ! "$1" = "1" ];then
					backUp
				fi
			fi
		else
			mkdir -p $BACKUP/profile
			cp -r $PROFILE_PATH/*.* $BACKUP/profile
			echo ""
			echo -e "\tРезервная копия - создана."
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			if [ ! "$1" = "1" ];then
				backUp
			fi
		fi
	elif [ "$REPLY" = "2" -a -d $BACKUP/profile ];then
		echo ""
		echo "Какие данные вы хотите восстановить?"
		echo ""
		echo -e "\t1: Профиль целиком (по умолчанию)"
		echo -e "\t2: Только файл конфигурации"
		echo -e "\t3: Только файлы списков"
		echo ""
		read -r -p "Ваш выбор:"
		if [ "$REPLY" = "2" ];then
			cp -r $BACKUP/profile/nfqws.conf $PROFILE_PATH
			echo ""
			echo -e "\tФайл конфигурации - восстановлен."
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			if [ ! "$1" = "1" ];then
				backUp
			fi
		elif [ "$REPLY" = "3" ];then
			cp -r $BACKUP/profile/*.list $PROFILE_PATH
			echo ""
			echo -e "\tФайлы списков - восстановлены."
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			if [ ! "$1" = "1" ];then
				backUp
			fi
		else
			cp -r $BACKUP/profile/*.* $PROFILE_PATH
			echo ""
			echo -e "\tПрофиль - восстановлен."
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			if [ ! "$1" = "1" ];then
				backUp
			fi
		fi
	elif [ "$REPLY" = "3" -a -d $BACKUP/profile ];then
		rm -rf $BACKUP/profile
		echo ""
		echo -e "\tРезервная копия - удалена."
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		if [ ! "$1" = "1" ];then
				backUp
			fi
	fi
	}

function configOptimize
	{
	clear
	headLine "Оптимизация конфигурации"
	echo -e "\tПодождите..."
	configGet "$PROFILE_PATH/nfqws.conf"
	CURENT_CONFIG=`echo -e "$CONFIG"`
	configsConfluence "$1" "$2"
	clear
	headLine "птимизация конфигурации"
	echo -e "\tОптимизированная конфигурация - сформирована, можно приступать к её"
	echo "тестированию..."
	echo ""
	echo -e "\t1: Начать тестирование"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		configTest "$1" "$2"
	fi
	}

function configTest
	{
	local TEST_CONFIG=`echo -e "$CONFIG" | awk '{sub(/^sp@ce/,"")}1'`
	fileSave "$PROFILE_PATH/nfqws.conf" "$TEST_CONFIG"
	restartNFQWS
	clear
	headLine "Тестирование конфигурации" "1"
	echo "$TEST_CONFIG"
	headLine
	echo ""
	echo -e "\tТестовая конфигурация - загружена в NFQWS. Теперь вы можете проверить:"
	echo "как с этой конфигурацией работают сайты/сервисы/приложения, для работы которых"
	echo "необходим NFQWS..."
	echo ""
	echo -e "\t1: Сохранить конфигурацию"
	echo -e "\t2: Изменить конфигурацию"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		echo ""
		echo "Хотите сохранить неиспользованные значения в файле конфигурации?"
		echo ""
		echo -e "\t1; Да"
		echo -e "\t0; Нет (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		if [ "$REPLY" = "1" ];then
			local ADD=`echo -e "$CONFIG" | grep "#%\|#@" | awk '{sub(/%/,"")}1' | awk '{sub(/@/,"")}1' | awk '{sub(/=/,"=#")}1'`
			CONFIG=`echo -e "$CONFIG" | grep -v "#%\|#@" | awk '{sub(/^sp@ce/,"")}1'`
			CONFIG=$CONFIG'\n\n# BackUp Optimization ['`date +"%C%y.%m.%d %H:%M:%S"`']\n'$ADD
			CONFIG=`echo -e "$CONFIG"`
		else
			CONFIG=`echo -e "$CONFIG" | grep -v "#%\|#@" | awk '{sub(/^sp@ce/,"")}1'`
		fi
		fileSave "$PROFILE_PATH/nfqws.conf" "$CONFIG"
		if [ ! "$1" = "$PROFILE_PATH/nfqws.conf" ];then
			fileSave "$1" ""
		elif [ ! "$2" = "$PROFILE_PATH/nfqws.conf" ];then
			fileSave "$2" ""
		fi
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	elif [ "$REPLY" = "2" ];then
		configSwitch "$1" "$2"
	else
		CURENT_CONFIG=`echo -e "$CURENT_CONFIG" | awk '{sub(/^sp@ce/,"")}1'`
		fileSave "$PROFILE_PATH/nfqws.conf" "$CURENT_CONFIG"
		restartNFQWS
	fi
	}

function configSwitch
	{
	clear
	headLine "Изменение конфигурации"
	echo -e "\tВы можете ввести один (или несколько, через пробел) идентификатор(ов)"
	echo "настроек - которые хотите переключить..."
	echo ""
	local LIST=`echo -e "$CONFIG" | grep "#@\|#%" | awk -F"=" '{print $1}'`
	local CHANGE_LIST=""
	local NUM="1"
	IFS=$'\n'
	for LINE in $LIST;do
		if [ "`echo "$LINE" | grep -c "#%"`" -gt "0" ];then
			local FLAG="%"
		else
			local FLAG="@"
		fi
		local CHANGE_LIST=$CHANGE_LIST$NEW$NUM'\t'$FLAG'\t'`echo $LINE | awk '{sub(/^#%/,"")}1' | awk '{sub(/^#@/,"")}1'`
		local NEW='\n'
		local NUM=`expr $NUM + 1`
	done
	local CHANGE_LIST=`echo -e $CHANGE_LIST`
	IFS=$'\n'
	for LINE in $CHANGE_LIST;do
		local STRING=`echo "$LINE" | awk -F"\t" '{print $1": Параметр: "$3}'`
		if [ "`echo "$LINE" | awk -F"\t" '{print $3}'`" = "ISP_INTERFACE" ];then
			echo -e "\t$STRING (Выбор сетевого интерфейса провайдера)"
		elif [ "`echo "$LINE" | awk -F"\t" '{print $3}'`" = "NFQWS_ARGS" ];then
			echo -e "\t$STRING (Стратегия обработки HTTP(S) трафика)"
		elif [ "`echo "$LINE" | awk -F"\t" '{print $3}'`" = "NFQWS_ARGS_QUIC" ];then
			echo -e "\t$STRING (Стратегия обработки QUIC трафика)"
		elif [ "`echo "$LINE" | awk -F"\t" '{print $3}'`" = "NFQWS_ARGS_UDP" ];then
			echo -e "\t$STRING (Стратегия обработки UDP трафика)"
		elif [ "`echo "$LINE" | awk -F"\t" '{print $3}'`" = "TCP_PORTS" ];then
			echo -e "\t$STRING (TCP порты для iptables)"
		elif [ "`echo "$LINE" | awk -F"\t" '{print $3}'`" = "UDP_PORTS" ];then
			echo -e "\t$STRING (UDP порты для iptables)"
		fi
		if [ "`echo "$LINE" | awk -F"\t" '{print $2}'`" = "%" ];then
			echo -e "\t   Установлено: старое значение\t\tДоступно: новое значение"
		else
			echo -e "\t   Установлено: новое значение\t\tДоступно: старое значение"
		fi
		echo ""
	done
	CONFIG=`echo -e "$CONFIG"`
	read -r -p "Введите один (или несколько, через пробел) идентификатор(ов):"
	REPLY=`echo $REPLY | awk '{gsub(/ /,"\n")}1'`
	if [ -n "$REPLY" ];then
		IFS=$'\n'
		for ITEM in $REPLY;do
			for LINE in $CHANGE_LIST;do
				if [ "$ITEM" = "`echo "$LINE" | awk -F"\t" '{print $1}'`" ];then
					local NEW_CONFIG=""
					for CONFIG_LINE in $CONFIG;do
						if [ "`echo "$CONFIG_LINE" | awk -F"=" '{print $1}'`" = "`echo "$LINE" | awk -F"\t" '{print $3}'`" ];then
							if [ "`echo "$LINE" | awk -F"\t" '{print $2}'`" = "%" ];then
								local BEGIN="#@"
							else
								local BEGIN="#%"
							fi
							local NEW_CONFIG=$NEW_CONFIG`echo "$BEGIN$CONFIG_LINE"`'\n'
						else
							local NEW_CONFIG=$NEW_CONFIG$CONFIG_LINE'\n'
						fi
					done
					CONFIG=`echo -e "$NEW_CONFIG"`
					local NEW_CONFIG=""
					for CONFIG_LINE in $CONFIG;do
						if [ "`echo "$CONFIG_LINE" | awk -F"=" '{print $1}'`" = "`echo "$LINE" | awk -F"\t" '{print "#"$2$3}'`" ];then
							local NEW_CONFIG=$NEW_CONFIG`echo "$CONFIG_LINE" | awk '{sub(/^#%/,"")}1' | awk '{sub(/^#@/,"")}1'`'\n'
						else
							local NEW_CONFIG=$NEW_CONFIG$CONFIG_LINE'\n'
						fi
					done
					CONFIG=`echo -e "$NEW_CONFIG"`
				fi
			done
		done
	fi
	configTest "$1" "$2"
	}

function paramChoice
	{
	local LINE=`echo $1 | awk -F"=" '{print $1}'`
	local LIST=`echo "$2" | awk '{gsub(/ /,"\n")}1'`
	local LIST=`echo -e "$LIST"`
	if [ "`echo "$LIST" | grep "^$LINE$"`" = "$LINE" ];then
		echo "$LINE"
	else
		echo ""
	fi
	}

function configsConfluence
	{
	configGet "$1"
	local CURENT_CONFIG=`echo -e "$CONFIG"`
	configGet "$2"
	local NEW_CONFIG=`echo -e "$CONFIG"`
	local NEW=""
	CONFIG=""
	IFS=$'\n'
	for OUT_LINE in $NEW_CONFIG;do
		for IN_LINE in $CURENT_CONFIG;do
			local FLAG="0"
			if [ "$OUT_LINE" = "sp@ce" ];then
				CONFIG=$CONFIG$NEW'sp@ce'
				local NEW='\n'
				local FLAG="1"
				break
			elif [ "$OUT_LINE" = "$IN_LINE" ];then
				CONFIG=$CONFIG$NEW$OUT_LINE
				local CURENT_CONFIG=`echo "$CURENT_CONFIG" | grep -v "$IN_LINE"`
				local NEW='\n'
				local FLAG="1"
				break
			elif [ "`echo "$OUT_LINE" | grep -c "$IN_LINE"`" -gt "0" -a "`echo "$OUT_LINE" | grep -c "NFQWS_EXTRA_ARGS"`" -gt "0" -o "`echo "$IN_LINE" | grep -c "$OUT_LINE"`" -gt "0" -a "`echo "$OUT_LINE" | grep -c "NFQWS_EXTRA_ARGS"`" -gt "0" ];then
				CONFIG=$CONFIG$NEW`echo "$IN_LINE" | awk -F"=" '{print $1}'`'='`echo "$OUT_LINE" | awk '{sub(/#/,"")}1' | awk '{sub(/NFQWS_EXTRA_ARGS=/,"")}1'`
				local CURENT_CONFIG=`echo "$CURENT_CONFIG" | grep -v "$IN_LINE"`
				local NEW='\n'
				local FLAG="1"
				break
			elif [ "`echo "$OUT_LINE" | awk -F"=" '{print $1}'`" = "`echo "$IN_LINE" | awk -F"=" '{print $1}'`" ];then
				if [ -n "`paramChoice "$OUT_LINE" "ISP_INTERFACE TCP_PORTS UDP_PORTS"`" ];then
					CONFIG=$CONFIG$NEW$IN_LINE'\n#%'$OUT_LINE
					local CURENT_CONFIG=`echo "$CURENT_CONFIG" | grep -v "$IN_LINE"`
					local NEW='\n'
					local FLAG="1"
					break
				elif [ -n "`paramChoice "$OUT_LINE" "NFQWS_ARGS NFQWS_ARGS_QUIC NFQWS_ARGS_UDP"`" ];then
					CONFIG=$CONFIG$NEW$OUT_LINE'\n#@'$IN_LINE
					local CURENT_CONFIG=`echo "$CURENT_CONFIG" | grep -v "$IN_LINE"`
					local NEW='\n'
					local FLAG="1"
					break
				elif [ -n "`paramChoice "$OUT_LINE" "IPV6_ENABLED POLICY_NAME LOG_LEVEL"`" ];then
					CONFIG=$CONFIG$NEW$IN_LINE
					local CURENT_CONFIG=`echo "$CURENT_CONFIG" | grep -v "$IN_LINE"`
					local NEW='\n'
					local FLAG="1"
					break
				else
					CONFIG=$CONFIG$NEW$OUT_LINE
					local CURENT_CONFIG=`echo "$CURENT_CONFIG" | grep -v "$IN_LINE"`
					local NEW='\n'
					local FLAG="1"
					break
				fi
			fi
		done
		if [ "$FLAG" = "0" ];then
			CONFIG=$CONFIG$NEW$OUT_LINE
		fi
	done
	local FLAG="0"
	local NEW=""
	local ADD_CONFIG=""
	IFS=$'\n'
	for LINE in $CURENT_CONFIG;do
		if [ "`echo "$LINE" | grep -c "BackUp"`" -gt "0" ];then
			local ADD_CONFIG=$ADD_CONFIG$NEW$LINE
			local FLAG="1"
			local NEW='\n'
		elif [ "$FLAG" = "1" ];then
			local ADD_CONFIG=$ADD_CONFIG$NEW$LINE
			local NEW='\n'
		fi
	done
	if [ -n "$ADD_CONFIG" ];then
		CONFIG=$CONFIG'\nsp@ce\n'$ADD_CONFIG
	fi
	}

function configGet
	{
	CONFIG=`cat "$1" | awk '{sub(/^[[:space:]]*$/,"sp@ce")}1'`
	CONFIG=`echo -e "$CONFIG"`
	}

function ispInterfaceEdit
	{
	clear
	headLine "Интерфейс провайдера"
	local EDIT=""
	local CHANGE="0"
	IFS=$'\n'
	for LINE in $CONFIG;do
		if [ "`echo "$LINE" | grep -c '^ISP_INTERFACE'`" -gt "0" ];then
			echo "Текущее значение: `echo "$LINE" | awk -F"=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
			echo ""
			echo -e "\tВы можете указать один или несколько интерфейсов (из списка ниже) -"
			echo "разделяя их пробелами (например: \"eth3 nwg1\"). Или, можно нажать ввод (оставив"
			echo "строку пустой) - чтобы использовать текущее значение параметра."
			echo ""
			ip addr show | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print "\t"$(NF), $2}'
			echo ""
			read -r -p "Новое значение:"
			if [ -n "$REPLY" ];then
				local EDIT=$EDIT'ISP_INTERFACE="'$REPLY'"\n'
				local CHANGE="1"
			else
				local EDIT=$EDIT$LINE'\n'
				local CHANGE="-1"
			fi
		else
			local EDIT=$EDIT$LINE'\n'
		fi
	done
	if [ "$CHANGE" = "0" ];then
		messageBox "Ошибка: параметр не обнаружен в конфигурации."
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	else
		CONFIG=`echo -e $EDIT`
		if [ "$CHANGE" -gt "0" ];then
			CHANGES=`expr $CHANGES + 1`
		fi
	fi
	#
	}

function httpsEdit
	{
	clear
	headLine "Стратегия обработки HTTP(S) трафика"
	local EDIT=""
	local SAVE=""
	local CHANGE="0"
	IFS=$'\n'
	for LINE in $CONFIG;do
		if [ "`echo "$LINE" | grep -c '^NFQWS_ARGS='`" -gt "0" ];then
			echo "Текущее значение: `echo "$LINE" | awk '{sub(/^NFQWS_ARGS=/,"")}1' | awk '{gsub(/"/,"")}1'`"
			echo ""
			echo -e "\tВы можете ввести новую стратегию обработки HTTP(S) трафика, или нажать"
			echo "ввод (оставив строку пустой) - чтобы использовать текущее значение параметра."
			echo ""
			read -r -p "Новое значение:"
			if [ -n "$REPLY" ];then
				local EDIT=$EDIT'NFQWS_ARGS="'$REPLY'"\n'
				local CHANGE="1"
				echo ""
				echo "Хотите сохранить старую HTTP(S) стратегию в конфигурации?"
				echo ""
				echo -e "\t1: Да"
				echo -e "\t0: Нет (по умолчанию)"
				echo ""
				read -r -p "Ваш выбор:"
				if [ "$REPLY" = "1" ];then
					local SAVE='sp@ce\n# BackUp HTTP(S) strategy ['`date +"%C%y.%m.%d %H:%M:%S"`']\n'`echo $LINE | awk '{sub(/^NFQWS_ARGS=/,"#NFQWS_ARGS=#")}1'`
				fi
			else
				local EDIT=$EDIT$LINE'\n'
				local CHANGE="-1"
			fi
		else
			local EDIT=$EDIT$LINE'\n'
		fi
	done
	local EDIT=$EDIT$SAVE
	if [ "$CHANGE" = "0" ];then
		messageBox "Ошибка: параметр не обнаружен в конфигурации."
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	else
		CONFIG=`echo -e $EDIT`
		if [ "$CHANGE" -gt "0" ];then
			CHANGES=`expr $CHANGES + 1`
		fi
	fi
	}

function quicEdit
	{
	clear
	headLine "Стратегия обработки QUIC трафика"
	local EDIT=""
	local SAVE=""
	local CHANGE="0"
	IFS=$'\n'
	for LINE in $CONFIG;do
		if [ "`echo "$LINE" | grep -c '^NFQWS_ARGS_QUIC='`" -gt "0" ];then
			echo "Текущее значение: `echo "$LINE" | awk '{sub(/^NFQWS_ARGS_QUIC=/,"")}1' | awk '{gsub(/"/,"")}1'`"
			echo ""
			echo -e "\tВы можете ввести новую стратегию обработки QUIC трафика, или нажать ввод"
			echo "(оставив строку пустой) - чтобы использовать текущее значение параметра."
			echo ""
			read -r -p "Новое значение:"
			if [ -n "$REPLY" ];then
				local EDIT=$EDIT'NFQWS_ARGS_QUIC="'$REPLY'"\n'
				local CHANGE="1"
				echo ""
				echo "Хотите сохранить старую QUIC стратегию в конфигурации?"
				echo ""
				echo -e "\t1: Да"
				echo -e "\t0: Нет (по умолчанию)"
				echo ""
				read -r -p "Ваш выбор:"
				if [ "$REPLY" = "1" ];then
					local SAVE='sp@ce\n# QUIC strategy BackUp ['`date +"%C%y.%m.%d %H:%M:%S"`']\n'`echo $LINE | awk '{sub(/^NFQWS_ARGS_QUIC=/,"#NFQWS_ARGS_QUIC=#")}1'`
				fi
			else
				local EDIT=$EDIT$LINE'\n'
				local CHANGE="-1"
			fi
		else
			local EDIT=$EDIT$LINE'\n'
		fi
	done
	local EDIT=$EDIT$SAVE
	if [ "$CHANGE" = "0" ];then
		messageBox "Ошибка: параметр не обнаружен в конфигурации."
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	else
		CONFIG=`echo -e $EDIT`
		if [ "$CHANGE" -gt "0" ];then
			CHANGES=`expr $CHANGES + 1`
		fi
	fi
	}

function udpEdit
	{
	clear
	headLine "Стратегия обработки UDP трафика"
	local EDIT=""
	local SAVE=""
	local CHANGE="0"
	IFS=$'\n'
	for LINE in $CONFIG;do
		if [ "`echo "$LINE" | grep -c '^NFQWS_ARGS_UDP='`" -gt "0" ];then
			echo "Текущее значение: `echo "$LINE" | awk '{sub(/^NFQWS_ARGS_UDP=/,"")}1' | awk '{gsub(/"/,"")}1'`"
			echo ""
			echo -e "\tВы можете ввести новую стратегию обработки UDP трафика, или нажать ввод"
			echo "(оставив строку пустой) - чтобы использовать текущее значение параметра."
			echo ""
			read -r -p "Новое значение:"
			if [ -n "$REPLY" ];then
				local EDIT=$EDIT'NFQWS_ARGS_UDP="'$REPLY'"\n'
				local CHANGE="1"
				echo ""
				echo "Хотите сохранить старую UDP стратегию в конфигурации?"
				echo ""
				echo -e "\t1: Да"
				echo -e "\t0: Нет (по умолчанию)"
				echo ""
				read -r -p "Ваш выбор:"
				if [ "$REPLY" = "1" ];then
					local SAVE='sp@ce\n# UDP strategy BackUp ['`date +"%C%y.%m.%d %H:%M:%S"`']\n'`echo $LINE | awk '{sub(/^NFQWS_ARGS_UDP=/,"#NFQWS_ARGS_UDP=#")}1'`
				fi
			else
				local EDIT=$EDIT$LINE'\n'
				local CHANGE="-1"
			fi
		else
			local EDIT=$EDIT$LINE'\n'
		fi
	done
	local EDIT=$EDIT$SAVE
	if [ "$CHANGE" = "0" ];then
		messageBox "Ошибка: параметр не обнаружен в конфигурации."
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	else
		CONFIG=`echo -e $EDIT`
		if [ "$CHANGE" -gt "0" ];then
			CHANGES=`expr $CHANGES + 1`
		fi
	fi
	}

function ipv6Switch
	{
	clear
	headLine "Обработка IPv6"
	echo "Выберите один из вариантов:"
	echo ""
	echo -e "\t1: Обрабатывать"
	echo -e "\t0: Не обрабатывать (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		local PARAM="1"
	else
		local PARAM="0"
	fi
	local EDIT=""
	local CHANGE="0"
	#CONFIG=`echo "$CONFIG" | awk '{sub(/^NFQWS_EXTRA_ARGS=/,"#NFQWS_EXTRA_ARGS=")}1'`
	IFS=$'\n'
	for LINE in $CONFIG;do
		if [ "`echo "$LINE" | grep -c "^IPV6_ENABLED="`" -gt "0" ];then
			EDIT=$EDIT'IPV6_ENABLED='$PARAM'\n'
			local CHANGE="1"
		else
			EDIT=$EDIT$LINE'\n'
		fi
	done
	CONFIG=`echo -e $EDIT`
	if [ "$CHANGE" -gt "0" ];then
		CHANGES=`expr $CHANGES + 1`
	fi
	}

function logSwitch
	{
	clear
	headLine "Режим вывода данных в Syslog"
	echo "Выберите один из вариантов:"
	echo ""
	echo -e "\t1: debug"
	echo -e "\t0: silent (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		local PARAM="1"
	else
		local PARAM="0"
	fi
	local EDIT=""
	local CHANGE="0"
	IFS=$'\n'
	for LINE in $CONFIG;do
		if [ "`echo "$LINE" | grep -c "^LOG_LEVEL="`" -gt "0" ];then
			EDIT=$EDIT'LOG_LEVEL='$PARAM'\n'
			local CHANGE="1"
		else
			EDIT=$EDIT$LINE'\n'
		fi
	done
	CONFIG=`echo -e $EDIT`
	if [ "$CHANGE" -gt "0" ];then
		CHANGES=`expr $CHANGES + 1`
	fi
	}

function tcpPortsEdit
	{
	clear
	headLine "TCP порты для iptables"
	local EDIT=""
	local SAVE=""
	local CHANGE="0"
	IFS=$'\n'
	for LINE in $CONFIG;do
		if [ "`echo "$LINE" | grep -c '^TCP_PORTS='`" -gt "0" ];then
			echo "Текущее значение: `echo "$LINE" | awk '{sub(/^TCP_PORTS=/,"")}1' | awk '{gsub(/"/,"")}1'`"
			echo ""
			echo -e "\tВы можете указать новые TCP порты для iptables, или нажать ввод (оставив"
			echo "строку пустой) - чтобы использовать текущее значение параметра."
			echo ""
			read -r -p "Новое значение:"
			if [ -n "$REPLY" ];then
				local EDIT=$EDIT'TCP_PORTS="'$REPLY'"\n'
				local CHANGE="1"
				echo ""
				echo "Хотите сохранить старое значение в файле конфигурации?"
				echo ""
				echo -e "\t1: Да"
				echo -e "\t0: Нет (по умолчанию)"
				echo ""
				read -r -p "Ваш выбор:"
				if [ "$REPLY" = "1" ];then
					local SAVE='sp@ce\n# BackUp TCP ports for iptables rules ['`date +"%C%y.%m.%d %H:%M:%S"`']\n'`echo $LINE | awk '{sub(/^TCP_PORTS=/,"#TCP_PORTS=#")}1'`
				fi
			else
				local EDIT=$EDIT$LINE'\n'
				local CHANGE="-1"
			fi
		else
			local EDIT=$EDIT$LINE'\n'
		fi
	done
	local EDIT=$EDIT$SAVE
	if [ "$CHANGE" = "0" ];then
		messageBox "Ошибка: параметр не обнаружен в конфигурации."
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	else
		CONFIG=`echo -e $EDIT`
		if [ "$CHANGE" -gt "0" ];then
			CHANGES=`expr $CHANGES + 1`
		fi
	fi
	}

function udpPortsEdit
	{
	clear
	headLine "UDP порты для iptables"
	local EDIT=""
	local SAVE=""
	local CHANGE="0"
	IFS=$'\n'
	for LINE in $CONFIG;do
		if [ "`echo "$LINE" | grep -c '^UDP_PORTS='`" -gt "0" ];then
			echo "Текущее значение: `echo "$LINE" | awk '{sub(/^UDP_PORTS=/,"")}1' | awk '{gsub(/"/,"")}1'`"
			echo ""
			echo -e "\tВы можете указать новые UDP порты для iptables, или нажать ввод (оставив"
			echo "строку пустой) - чтобы использовать текущее значение параметра."
			echo ""
			read -r -p "Новое значение:"
			if [ -n "$REPLY" ];then
				local EDIT=$EDIT'UDP_PORTS="'$REPLY'"\n'
				local CHANGE="1"
				echo ""
				echo "Хотите сохранить старое значение в файле конфигурации?"
				echo ""
				echo -e "\t1: Да"
				echo -e "\t0: Нет (по умолчанию)"
				echo ""
				read -r -p "Ваш выбор:"
				if [ "$REPLY" = "1" ];then
					local SAVE='sp@ce\n# BackUp UDP ports for iptables rules ['`date +"%C%y.%m.%d %H:%M:%S"`']\n'`echo $LINE | awk '{sub(/^UDP_PORTS=/,"#UDP_PORTS=#")}1'`
				fi
			else
				local EDIT=$EDIT$LINE'\n'
				local CHANGE="-1"
			fi
		else
			local EDIT=$EDIT$LINE'\n'
		fi
	done
	local EDIT=$EDIT$SAVE
	if [ "$CHANGE" = "0" ];then
		messageBox "Ошибка: параметр не обнаружен в конфигурации."
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	else
		CONFIG=`echo -e $EDIT`
		if [ "$CHANGE" -gt "0" ];then
			CHANGES=`expr $CHANGES + 1`
		fi
	fi
	}

function policyNameEdit
	{
	clear
	headLine "Название политики"
	local EDIT=""
	local SAVE=""
	local CHANGE="0"
	IFS=$'\n'
	for LINE in $CONFIG;do
		if [ "`echo "$LINE" | grep -c '^POLICY_NAME='`" -gt "0" ];then
			echo "Текущее значение: `echo "$LINE" | awk '{sub(/^POLICY_NAME=/,"")}1' | awk '{gsub(/"/,"")}1'`"
			echo ""
			echo -e "\tВы можете указать новое название политики, или нажать ввод (оставив"
			echo "строку пустой) - чтобы использовать текущее значение параметра."
			echo ""
			read -r -p "Новое значение:"
			if [ -n "$REPLY" ];then
				local EDIT=$EDIT'POLICY_NAME="'$REPLY'"\n'
				local CHANGE="1"
				echo ""
				echo "Хотите сохранить старое значение в файле конфигурации?"
				echo ""
				echo -e "\t1: Да"
				echo -e "\t0: Нет (по умолчанию)"
				echo ""
				read -r -p "Ваш выбор:"
				if [ "$REPLY" = "1" ];then
					local SAVE='sp@ce\n# BackUp Keenetic policy name ['`date +"%C%y.%m.%d %H:%M:%S"`']\n'`echo $LINE | awk '{sub(/^POLICY_NAME=/,"#POLICY_NAME=#")}1'`
				fi
			else
				local EDIT=$EDIT$LINE'\n'
				local CHANGE="-1"
			fi
		else
			local EDIT=$EDIT$LINE'\n'
		fi
	done
	local EDIT=$EDIT$SAVE
	if [ "$CHANGE" = "0" ];then
		messageBox "Ошибка: параметр не обнаружен в конфигурации."
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	else
		CONFIG=`echo -e $EDIT`
		if [ "$CHANGE" -gt "0" ];then
			CHANGES=`expr $CHANGES + 1`
		fi
	fi
	}

function modeSwitch
	{
	local CHANGE="0"
	clear
	headLine "Режим работы"
	echo "Выберите один из вариантов:"
	echo ""
	echo -e "\t1: Авто (по умолчанию) - автоматическое определение недоступных доменов"
	echo -e "\t2: Список - обработка доменов, только из \"user.list\""
	echo -e "\t3: Всё - обработка всего трафика, кроме доменов из \"exclude.list\""
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "2" ];then
		local FIND1='# list '
		local FIND2=' user.list'
	elif [ "$REPLY" = "3" ];then
		local FIND1='# all '
		local FIND2=' exclude.list'
	else
		local FIND1='# auto '
		local FIND2=' auto.list'
	fi
	local EDIT=""
	local CHANGE="0"
	local FLAG="0"
	CONFIG=`echo "$CONFIG" | awk '{sub(/^NFQWS_EXTRA_ARGS=/,"#NFQWS_EXTRA_ARGS=")}1'`
	IFS=$'\n'
	for LINE in $CONFIG;do
		if [ "`echo "$LINE" | grep -c $FIND1`" -gt "0" -a "`echo "$LINE" | grep -c $FIND2`" -gt "0" -a "$FLAG" = "0" ];then
			EDIT=$EDIT$LINE'\n'
			local FLAG="1"
		elif [ "`echo "$LINE" | grep -c '^#NFQWS_EXTRA_ARGS='`" -gt "0" -a "$FLAG" = "1" ];then
			EDIT=$EDIT`echo "$LINE" | awk '{sub(/^#NFQWS_EXTRA_ARGS=/,"NFQWS_EXTRA_ARGS=")}1'`'\n'
			local FLAG="0"
			local CHANGE="1"
		else
			EDIT=$EDIT$LINE'\n'
		fi
	done
	CONFIG=`echo -e $EDIT`
	if [ "$CHANGE" -gt "0" ];then
		CHANGES=`expr $CHANGES + 1`
	fi
	}

function configSwitches
	{
	clear
	headLine "Переключаемые параметры"
	echo -e "\t1: Режим работы"
	echo -e "\t2: Обработка IPv6"
	echo -e "\t3: Режим вывода данных в Syslog"
	echo -e "\t0: Назад (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		modeSwitch
	elif [ "$REPLY" = "2" ];then
		ipv6Switch
	elif [ "$REPLY" = "3" ];then
		logSwitch
	fi
	}

function configAction
	{
	clear
	headLine "Конфигурация" "1"
	if [ -n "$CONFIG" ];then
		echo -e "$CONFIG" | awk '{sub(/^sp@ce*$/,"")}1'
	else
		messageBox "Ошибка: конфигурация отсутствует." "1"
	fi	
	headLine
	echo ""
	echo "Доступные действия:"
	echo ""
	echo -e "\t1: Сохранить\t\t\t2: Изменить интерфейс провайдера"
	echo -e "\t3: Изменить HTTP(S) стратегию\t4: Изменить QUIC стратегию"
	echo -e "\t5: Изменить UDP стратегию\t6: Изменить TCP порты"
	echo -e "\t7: Изменить UDP порты\t\t8: Изменить название политики"
	echo -e "\t9: Переключаемые параметры\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		CONFIG=`echo "$CONFIG" | awk '{sub(/^sp@ce/,"")}1'`
		fileSave "$PROFILE_PATH/nfqws.conf" "$CONFIG"
		echo ""
		echo -e "\tДля того, чтобы изменения вступили в силу - вам необходимо перезапустить"
		echo "службу NFQWS..."
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	elif [ "$REPLY" = "2" ];then
		ispInterfaceEdit
		configAction
	elif [ "$REPLY" = "3" ];then
		httpsEdit
		configAction
	elif [ "$REPLY" = "4" ];then
		quicEdit
		configAction
	elif [ "$REPLY" = "5" ];then
		udpEdit
		configAction
	elif [ "$REPLY" = "6" ];then
		tcpPortsEdit
		configAction
	elif [ "$REPLY" = "7" ];then
		udpPortsEdit
		configAction
	elif [ "$REPLY" = "8" ];then
		policyNameEdit
		configAction
	elif [ "$REPLY" = "9" ];then
		configSwitches
		configAction
	else
		if [ "$CHANGES" -gt "0" ];then
			echo ""
			echo "Если продолжить, все внесённые изменения - будут утеряны..."
			echo ""
			echo -e "\t1: Продолжить"
			echo -e "\t0: Назад (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			if [ ! "$REPLY" = "1" ];then
				configAction
			fi
		fi
	fi
	}

function configEditor
	{
	CONFIG=""
	CHANGES="0"
	configGet "$PROFILE_PATH/nfqws.conf"
	configAction
	}

function listsGet
	{
	local LISTS=`ls $PROFILE_PATH | grep ".list$" | awk '{gsub(/.list /,".list\n")}1'`
	local LISTS=`echo -e "$LISTS"`
	local LIST=""
	local NUM='1'
	local NEW=""
	IFS=$'\n'
	for FILE_NAME in $LISTS;do
		LIST=$LIST$NEW$NUM'\t'$FILE_NAME
		local NEW='\n'
		local NUM=`expr $NUM + 1`
		if [ "$FILE_NAME" = "auto.list" ];then
			LIST=$LIST'\t(добавлено автоматически)'
		elif [ "$FILE_NAME" = "exclude.list" ];then
			LIST=$LIST'\t(исключения)'
		elif [ "$FILE_NAME" = "user.list" ];then
			LIST=$LIST'\t(добавлено пользователем)'
		fi
	done
	clear
	headLine "Редактор списков"
	echo "Выберите список - который хотите отредактировать:"
	echo ""
	echo -e "$LIST\n0\tОтмена" | awk -F"\t" '{print "\t"$1": "$2, $3}'
	echo ""
	read -r -p "Введите номер правила:"
	FILE_NAME=""
	if [ -z "`echo "$REPLY" | sed 's/[0-9]//g'`" -a ! "$REPLY" = "0" -a ! "$REPLY" = "" ];then
		local LIST=`echo -e $LIST`
		IFS=$'\n'
		for LINE in $LIST;do
			if [ "`echo "$LINE" | awk -F"\t" '{print $1}'`" = "$REPLY" ];then
				FILE_NAME=`echo "$LINE" | awk -F"\t" '{print $2}'`
				break
			fi
		done
		if [ -n "$FILE_NAME" ];then
			EDIT=`cat $PROFILE_PATH/$FILE_NAME`
		else
			EDIT=""
		fi
	fi
	}

function itemAdd
	{
	local NEW=""
	echo ""
	read -r -p "Добавить в список:"
	if [ -n "$EDIT" ];then
		local NEW='\n'
	fi
	if [ -n "$REPLY" ];then
		EDIT=$EDIT$NEW$REPLY
		local NEW='\n'
		itemAdd
	else
		EDIT=`echo -e "$EDIT"`
		listAction
	fi
	}

function itemDelete
	{
	read -r -p "Удалить из списка:" DEL_FIELD
	echo ""
	if [ -n "$DEL_FIELD" ];then
		if [ -n "`echo "$EDIT" | grep "$DEL_FIELD"`" ];then
			echo "Обнаружены следующие совпадения:"
			echo ""
			echo "$EDIT" | grep "$DEL_FIELD" | awk -F"\n" '{print "\t- "$1}'
			echo ""
			echo "Удалить все найденные совпадения?"
			echo ""
			echo -e "\t1: Да"
			echo -e "\t0: Нет (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			if [ "$REPLY" = "1" ];then
				EDIT=`echo "$EDIT" | grep -v "$DEL_FIELD"`
				listAction
			else
				listAction
			fi
		else
			messageBox "Ошибка: ничего не найдено"
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			echo ""
			itemDelete
		fi
	else
		listAction
	fi
	}

function listAction
	{
	if [ ! "$FILE_NAME" = "" ];then
		clear
		headLine "Список: $FILE_NAME" "1"
		if [ -n "$EDIT" ];then
			echo -e "$EDIT" | awk -F"\n" '{print "\t"$1}'
		else
			messageBox "Список пуст" "1"
		fi	
		headLine
		echo ""
		echo "Доступные действия:"
		echo ""
		echo -e "\t1: Сохранить"
		echo -e "\t2: Добавить записи"
		echo -e "\t3: Удалить записи"
		echo -e "\t4: Очистить список"
		echo -e "\t0: Отмена (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		if [ "$REPLY" = "1" ];then
			fileSave "$PROFILE_PATH/$FILE_NAME" "$EDIT"
			echo ""
			echo -e "\tДля того, чтобы изменения вступили в силу - вам необходимо перезапустить"
			echo "службу NFQWS..."
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		elif [ "$REPLY" = "2" ];then
			echo ""
			echo -e "\tВы можете добавлять строку за строкой... Для завершения процесса"
			echo "добавления - нажмите ввод (оставив строку пустой)."
			itemAdd
		elif [ "$REPLY" = "3" ];then
			echo ""
			echo -e "\tВведите последовательность символов,  содержащеюся в строках - которые"
			echo "нужно удалить. Или нажмите ввод (оставив строку пустой), для выхода из диалога"
			echo "удаления..."
			echo ""
			itemDelete
		elif [ "$REPLY" = "4" ];then
			EDIT=""
			listAction
		fi
	fi
	}

function listsEditor
	{
	FILE_NAME=""
	EDIT=""
	listsGet
	listAction
	}

function startNFQWS
	{
	headLine "/opt/etc/init.d/S51nfqws start" "1"
	/opt/etc/init.d/S51nfqws start
	headLine
	}
	
function stopNFQWS
	{
	headLine "/opt/etc/init.d/S51nfqws stop" "1"
	/opt/etc/init.d/S51nfqws stop
	headLine
	}
	
function restartNFQWS
	{
	headLine "/opt/etc/init.d/S51nfqws restart" "1"
	/opt/etc/init.d/S51nfqws restart
	headLine
	}
	
function statusNFQWS
	{
	headLine "/opt/etc/init.d/S51nfqws status" "1"
	/opt/etc/init.d/S51nfqws status
	headLine
	}

function infoNFQWS
	{
	headLine "opkg info nfqws-keenetic" "1"
	opkg info nfqws-keenetic
	headLine
	}

function zyxelSetupBegining
	{
	clear
	headLine "Настройка ZyXel Keenetic"
	echo -e "\tДанный метод подходит для маршрутизаторов ZyXEL Keenetic с USB-портом и"
	echo "KeeneticOS версии 2.07 (и выше), кроме моделей: \"4G II\" и \"4G III\"."
	echo "Для обновления KeeneticOS до последней доступной версии - открываем в браузере:"
	echo ""
	messageBox 'http://192.168.1.1/a'
	echo "и вводим в поле \"Command\" одну из следующих команду:"
	echo ""
	echo "                         (для KeeneticOS до версии 2.06)"
	messageBox 'components sync legacy'
	echo "                       (для KeeneticOS версии 2.06 и выше)"
	messageBox 'components list legacy'
	echo -e "\t1: Продолжить"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		clear
		opkg update
		opkg install dnscrypt-proxy2
		opkg install ca-certificates cron iptables
		local FILE=`cat $DNSCRYPT | awk '{gsub(/^listen_addresses = \[.127.0.0.1:53.\]/,"listen_addresses = [|0.0.0.0:53|]")}1' | tr "|" "'"`
		echo -e "$FILE" > $DNSCRYPT
		/opt/etc/init.d/S09dnscrypt-proxy2 start
		clear
		headLine "Настройка ZyXel Keenetic"
		echo ""
		echo -e "\tНа следующем шага - соединение с маршрутизатором будет разорвано..."
		echo "После восстановления соединения, необходимо снова подключиться к Entware и"
		echo "повторно запустить: \"Дополнительно/Предварительная настройка ZyXel Keenetic (с"
		echo "KeeneticOS 2.x)\"."
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		ndmc -c 'opkg dns-override'
		ndmc -c 'system configuration save'	
	fi
	}
	
function zyxelSetupEnding
	{
	ndmc -c 'system configuration save'
	local Z_IP=`ip addr show br0 | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print $2}'`
	clear
	headLine "Настройка ZyXel Keenetic"
	echo -e "\tТеперь нужно установить IP-адрес маршрутизатора ($Z_IP) в качестве"
	echo "DNS-сервера (в настройках подключения(й) к интернету и сегмента домашней сети)."
	echo ""
	echo -e "\tВ веб-конфигураторе маршрутизатора:"
	echo "Переходим в \"Интернет/(ваше интернет подключение)/Параметры IP.../Показать"
	echo "дополнительные настройки...\", в поле: \"DNS 1\" вводим \"$Z_IP\"..."
	echo "(если у вас несколько интернет подключений, это нужно повторить для каждого из них)"
	echo ""
	read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	clear
	headLine "Настройка ZyXel Keenetic"
	echo -e "\tПереходим в \"Мои сети и Wi-Fi/Домашняя сеть/Параметры IP/Показать"
	echo "настройки DHCP\", в поле: \"Сервер DNS 1\" вводим \"$Z_IP\"."
	echo ""
	read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	clear
	headLine "Настройка ZyXel Keenetic"
	echo -e "\tПереходим в \"Сетевые правила/Интернет-фильтр\", в таблице: \"Серверы DNS\""
	echo "- должны присутствовать только записи с IP-адресом маршрутизатора. Все остальные"
	echo "(если будут наблюдаться проблемы с доступом к некоторым сайтом) - нужно удалить"
	echo "(если для доступа в интернет не используются: L2TP, PPPoE, IPoE и т.п.)..."
	echo ""
	read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	rm -rf /opt/etc/ndm/netfilter.d/10-ClientDNS-Redirect.sh
	echo -e '#!/bin/sh\n[ "$type" == "ip6tables" ] && exit 0\n[ "$table" != "nat" ] && exit 0\n[ -z "$(iptables -nvL -t nat | grep "to:'$Z_IP':53")" ] && iptables -t nat -I PREROUTING -p udp --dport 53 -j DNAT --to-destination '$Z_IP':53\nexit 0' >> /opt/etc/ndm/netfilter.d/10-ClientDNS-Redirect.sh
	chmod +x /opt/etc/ndm/netfilter.d/10-ClientDNS-Redirect.sh
	clear
	headLine "Настройка ZyXel Keenetic"
	echo "Теперь нужно перезагрузить маршрутизатор. Хотите сделать это прямо сейчас?"
	echo ""
	echo -e "\t1: Да (по умолчанию)"
	echo -e "\t0: Нет, я выполню перезагрузку самостоятельно"
	echo ""
	read -r -p "Ваш выбор:"
	if [ ! "$REPLY" = "0" ];then
		ndmc -c 'system reboot'
	fi
	}

function zyxelSetup
	{
	if [  "`opkg list-installed | grep -c "dnscrypt-proxy2"`" -gt "0" ];then
		local APP="1"
	else
		local APP="0"
	fi
	if [ -f "$DNSCRYPT" ];then
		if [ "`cat "$DNSCRYPT" | grep -c "listen_addresses = \['0.0.0.0:53'\]"`" -gt "0" ];then
			local MOD="1"
		else
			local MOD="0"
		fi
	else
		local MOD="0"
	fi
	if [ "$APP" = "0" -o "$FILE_MOD" = "0" ];then
		zyxelSetupBegining
	else
		clear
		headLine "Настройка ZyXel Keenetic"
		echo -e "\tПохоже, вы снова подключились к Entware  (после разрыва соединения с"
		echo "маршрутизатором). Если это так - ваш вариант: \"Продолжить процесс настройки\","
		echo "в противном случае -вы можете начать процесс настройки с начала..."
		echo ""
		echo -e "\t1: Начать настройку сначала"
		echo -e "\t2: Продолжить процесс настройки (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		if [ "$REPLY" = "1" ];then
			zyxelSetupBegining
		else
			zyxelSetupEnding
		fi
	fi
	}

function buttonSelect
	{
	local FLAG=$1
	echo "Выберите кнопку:"
	echo ""
	echo -e "\t1: Кнопка WiFi"
	echo -e "\t2: Кнопка FN1"
	echo -e "\t3: Кнопка FN2"
	if [ "$FLAG" = "1" ];then
		echo -e "\t0: Отмена (по умолчанию)"
	else
		echo -e "\t0: Завершить процесс настройки (по умолчанию)"
	fi
	echo ""
	read -r -p "Ваш выбор:" BUTTON_NAME
	if [ "$BUTTON_NAME" = "1" -o "$BUTTON_NAME" = "2" -o "$BUTTON_NAME" = "3" ];then
		echo ""
		echo "Выберите тип нажатия:"
		echo ""
		echo -e "\t1: Короткое нажатие"
		echo -e "\t2: Двойное нажатие"
		echo -e "\t3: Длинное нажатие"
		echo -e "\t0: Отмена (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:" TYPE
		if [ "$TYPE" = "1" -o "$TYPE" = "2" -o "$TYPE" = "3" ];then
			echo ""
			echo "Выберите действие:"
			echo ""
			echo -e "\t1: Запустить службу NFQWS-Keenetic"
			echo -e "\t2: Остановить службу NFQWS-Keenetic"
			echo -e "\t3: Перезапустить службу NFQWS-Keenetic"
			echo -e "\t0: Отмена (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:" ACTION
			if [ "$ACTION" = "1" -o "$ACTION" = "2" -o "$ACTION" = "3" ];then
				if [ "$ACTION" = "1" ];then
					ACTION='/opt/etc/init.d/S51nfqws start'
				elif [ "$ACTION" = "2" ];then
					ACTION='/opt/etc/init.d/S51nfqws stop'
				else
					ACTION='/opt/etc/init.d/S51nfqws restart'
				fi
				if [ "$TYPE" = "1" ];then
					TYPE='click'
				elif [ "$TYPE" = "2" ];then
					TYPE='double-click'
				else
					TYPE='hold'
				fi
				if [ "$BUTTON_NAME" = "1" ];then
					WLAN=$WLAN$TYPE'&'$ACTION'\t'
				elif [ "$BUTTON_NAME" = "2" ];then
					FN1=$FN1$TYPE'&'$ACTION'\t'
				else
					FN2=$FN2$TYPE'&'$ACTION'\t'
				fi
				echo ""
				echo -e "\tНастройка - добавлена в конфигурацию."
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				clear
				headLine "Настройка кнопки"
				buttonSelect
			fi
		fi
	else
		if [ "$FLAG" = "1" ];then
			buttonMenu
			exit
		fi
	fi
	}

function buttonConfig
	{
	WLAN=""
	FN1=""
	FN2=""
	clear
	headLine "Настройка кнопки"
	echo -e "\tНекоторые кнопки (из списка ниже) могут физически отсутствовать на вашей"
	echo "модели маршрутизатора. Пожалуйста выбирайте только те кнопки - которые есть на"
	echo "устройстве..."
	echo ""
	buttonSelect "1"
	if [ -n "$WLAN" -o -n "$FN1" -o -n "$FN2" ];then
		local TEXT='#!/opt/bin/sh\n\ncase "$button" in\n\n'
		if [ -n "$WLAN" ];then
			local TEXT=$TEXT'"WLAN")\n\tcase "$action" in\n'
			WLAN=`echo -e $WLAN`
			IFS=$'\t'
			for LINE in $WLAN;do
				local TEXT=$TEXT'\t"'`echo $LINE | awk '{gsub(/&/,"\")\n\t\t")}1'`'\n\t\t;;\n' 
			done
			local TEXT=$TEXT'\tesac\n\t;;\n'
		fi
		if [ -n "$FN1" ];then
			local TEXT=$TEXT'"FN1")\n\tcase "$action" in\n'
			FN1=`echo -e $FN1`
			IFS=$'\t'
			for LINE in $FN1;do
				local TEXT=$TEXT'\t"'`echo $LINE | awk '{gsub(/&/,"\")\n\t\t")}1'`'\n\t\t;;\n' 
			done
			local TEXT=$TEXT'\tesac\n\t;;\n'
		fi
		if [ -n "$FN2" ];then
			local TEXT=$TEXT'"FN2")\n\tcase "$action" in\n'
			FN2=`echo -e $FN2`
			IFS=$'\t'
			for LINE in $FN2;do
				local TEXT=$TEXT'\t"'`echo $LINE | awk '{gsub(/&/,"\")\n\t\t")}1'`'\n\t\t;;\n' 
			done
			local TEXT=$TEXT'\tesac\n\t;;\n'
		fi
		local TEXT=$TEXT'esac'
		fileSave "$BUTTON" "$TEXT"
		echo ""
		echo -e "\tНе забудьте выбрать вариант \"OPKG - Запуск скриптов button.d\" в"
		echo "веб-конфигураторе маршрутизатора (Управление/Параметры системы/Назначение кнопок"
		echo "и индикаторов интернет-центра) для всех кнопок и типов нажатия - которые вы"
		echo "настроили..."
		echo ""
		else
		echo ""
		echo -e "\tНовая конфигурация - не задана..."
		echo ""
	fi
	
	read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	}

function buttonMenu
	{
	clear
	headLine "Настройка кнопок"
	echo "Доступные действия:"
	echo ""
	echo -e "\t1: Настроить новую конфигурацию кнопок"
	if [ -f "$BUTTON" ];then
		echo -e "\t2: Сбросить текущую конфигурацию кнопок"
	fi
	echo -e "\t0: Вернуться в главное меню (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		buttonConfig
		buttonMenu
		exit
	elif [ "$REPLY" = "2" ];then
		rm -rf $BUTTON
		if [ ! -f "$BUTTON" ];then
			echo ""
			echo -e "\tФайл: $BUTTON - удалён."
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		buttonMenu
		exit
	#else
		#mainMenu
		#exit
	fi
	}

function preInstall
	{
	opkg update
	opkg install ca-certificates wget-ssl
	opkg remove wget-nossl
	mkdir -p /opt/etc/opkg
	}

function nfqwsInstall
	{
	opkg update
	opkg install nfqws-keenetic
	headLine
	}

function installMips
	{
	headLine "Установка NFQWS-Keenetic (архитектуры mips)" "1"
	preInstall
	echo "src/gz nfqws-keenetic https://anonym-tsk.github.io/nfqws-keenetic/mips" > /opt/etc/opkg/nfqws-keenetic.conf
	nfqwsInstall
	}

function installMipsel
	{
	headLine "Установка NFQWS-Keenetic (архитектуры mipsel)" "1"
	preInstall
	echo "src/gz nfqws-keenetic https://anonym-tsk.github.io/nfqws-keenetic/mipsel" > /opt/etc/opkg/nfqws-keenetic.conf
	nfqwsInstall
	}

function installAarch64
	{
	headLine "Установка NFQWS-Keenetic (архитектуры aarch64" "1"
	preInstall
	echo "src/gz nfqws-keenetic https://anonym-tsk.github.io/nfqws-keenetic/aarch64" > /opt/etc/opkg/nfqws-keenetic.conf
	nfqwsInstall
	}

function installUniversal
	{
	headLine "Установка NFQWS-Keenetic (универсальный установщик)" "1"
	preInstall
	echo "src/gz nfqws-keenetic https://anonym-tsk.github.io/nfqws-keenetic/all" > /opt/etc/opkg/nfqws-keenetic.conf
	nfqwsInstall
	}

function installWeb
	{
	headLine "Установка WEB-интерфейса NFQWS-Keenetic" "1"
	opkg install nfqws-keenetic-web
	headLine
	}

function updateNFQWS
	{
	headLine "Обновление NFQWS-Keenetic" "1"
	opkg update
	opkg upgrade nfqws-keenetic
	opkg upgrade nfqws-keenetic-web
	headLine
	}

function uninstallNFQWS
	{
	headLine "Удаление NFQWS-Keenetic" "1"
	opkg remove --autoremove nfqws-keenetic-web nfqws-keenetic
	headLine
	}

function installNFQWS
	{
	clear
	headLine "Установка NFQWS-Keenetic"
	echo "Выберите архитектуру:"
	echo ""
	echo -e "\t1: mips"
	echo -e "\t2: mipsel"
	echo -e "\t3: aarch64"
	echo -e "\t4: Универсальный установщик"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		installMips
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		installMenu
		exit
	elif [ "$REPLY" = "2" ];then
		installMipsel
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		installMenu
		exit
	elif [ "$REPLY" = "3" ];then
		installAarch64
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		installMenu
		exit
	elif [ "$REPLY" = "4" ];then
		installUniversal
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		installMenu
		exit
	else
		installMenu
		exit
	fi
	}

function installMenu
	{
	if [  "`opkg list-installed | grep -c "nfqws-keenetic"`" -gt "1" ];then
		local NFQWS="2"
	elif [  "`opkg list-installed | grep -c "nfqws-keenetic"`" -gt "0" ];then
		local NFQWS="1"
	else
		local NFQWS="0"
	fi
	clear
	headLine "Установка/удаление"
	echo "Доступные действия:"
	echo ""
	if [ "$NFQWS" = "0" ];then
		echo -e "\t1: Установить NFQWS-Keenetic"
	fi
	if [ "$NFQWS" -lt "2" ];then
	echo -e "\t2: Установить WEB-интерфейс"
	fi
	if [ "$NFQWS" -gt "0" ];then
		echo -e "\t3: Обновить..."
		echo -e "\t4: Удалить NFQWS-Keenetic"
		echo -e "\t5: Информация об установленной службе"
		echo -e "\t6: Резервное копирование профиля"
	fi
	echo -e "\t0: Вернуться в главное меню (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" -a "$NFQWS" = "0" ];then
		installNFQWS
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		installMenu
		exit
	elif [ "$REPLY" = "2" -a "$NFQWS" -lt "2" ];then
		installWeb
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		installMenu
		exit
	elif [ "$REPLY" = "3" -a "$NFQWS" -gt "0" ];then
		updateNFQWS
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		installMenu
		exit
	elif [ "$REPLY" = "4" -a "$NFQWS" -gt "0" ];then
		uninstallNFQWS
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		installMenu
		exit
	elif [ "$REPLY" = "5" -a "$NFQWS" -gt "0" ];then
		infoNFQWS
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		installMenu
		exit
	elif [ "$REPLY" = "6" -a "$NFQWS" -gt "0" ];then
		backUp
		installMenu
		exit
	else
		mainMenu
		exit
	fi
	}

function findStrategy
	{
	clear
	headLine "Подбор рабочей стратегии NFQWS"
	echo -e "\tДля поиска рабочей стратегии - запустите скрипт и следуйте инструкциям."
	echo "Подробнее о его работе - можно почитать здесь:"
	echo ""
	echo "                            https://clck.ru/3F84AQ"
	echo ""
	echo -e "\t1: Запустить скрипт"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		opkg install curl
		/bin/sh -c "$(curl -fsSL https://github.com/Anonym-tsk/nfqws-keenetic/raw/master/common/strategy.sh)"
	fi
	}

function extraMenu
	{
	clear
	headLine "Дополнительно"
	echo "Что вы хотите сделать?"
	echo ""
	echo -e "\t1: Удалить NK"
	if [ -d "$BACKUP" ];then
		echo -e "\t2: Удалить резервные копии NK"
	fi
	echo -e "\t3: Предварительная настройка ZyXel Keenetic (с KeeneticOS 2.x)"
	echo -e "\t4: Подбор рабочей стратегии NFQWS"
	echo -e "\t0: Вернуться в главное меню (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		clear
		rm -rf /opt/bin/nk
		exit
	elif [ "$REPLY" = "2" -a -d "$BACKUP" ];then
		rm -rf $BACKUP
		echo ""
		echo -e "\tРезервные копии Xvps - удалены."
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	elif [ "$REPLY" = "3" ];then
		zyxelSetup
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	elif [ "$REPLY" = "4" ];then
		findStrategy
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	else
		mainMenu
		exit
	fi
	extraMenu
	exit
	}

function mainMenu
	{
	if [  "`opkg list-installed | grep -c "nfqws-keenetic"`" -gt "1" ];then
		local NFQWS="2"
	elif [  "`opkg list-installed | grep -c "nfqws-keenetic"`" -gt "0" ];then
		local NFQWS="1"
	else
		local NFQWS="0"
	fi
	clear
	headLine "NK для NFQWS-Keenetic"
	if [ "`ls "$PROFILE_PATH" | grep -c "\-old"`" -gt "0" -o "`ls "$PROFILE_PATH" | grep -c "\-opkg"`" -gt "0" ];then
		messageBox "Доступна оптимизация профиля"
		local OPTIMIZATION="1"
	else
		local OPTIMIZATION="0"
	fi
	echo "Доступные функции:"
	echo ""
	if [ "$NFQWS" -gt "0" ];then
		echo -e "\t1: Запуск/перезапуск службы"
		echo -e "\t2: Остановка службы"
		echo -e "\t3: Статус службы"
		echo -e "\t4: Редактор конфигурации"
	fi
	if [ "$OPTIMIZATION" = "1" ];then
		echo -e "\t5: Оптимизация профиля"
	fi
	if [ "$NFQWS" -gt "0" ];then
		echo -e "\t6: Редактор списков"
	fi
	echo -e "\t7: Настройка кнопок"
	echo -e "\t8: Установка/обновление/удаление"
	echo -e "\t9: Дополнительно..."
	echo -e "\t0: Выход (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" -a "$NFQWS" -gt "0" ];then
		restartNFQWS
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		mainMenu
		exit
	elif [ "$REPLY" = "2" -a "$NFQWS" -gt "0" ];then
		stopNFQWS
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		mainMenu
		exit
	elif [ "$REPLY" = "3" -a "$NFQWS" -gt "0" ];then
		statusNFQWS
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		mainMenu
		exit
	elif [ "$REPLY" = "4" -a "$NFQWS" -gt "0" ];then
		configEditor
		mainMenu
		exit
	elif [ "$REPLY" = "5" -a "$OPTIMIZATION" = "1" ];then
		profileOptimize
		mainMenu
		exit
	elif [ "$REPLY" = "6" ];then
		listsEditor
		mainMenu
		exit
	elif [ "$REPLY" = "7" ];then
		buttonMenu
		mainMenu
		exit
	elif [ "$REPLY" = "8" ];then
		installMenu
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		mainMenu
		exit
	elif [ "$REPLY" = "9" ];then
		extraMenu
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		mainMenu
		exit
	else
		echo ""
		copyRight
		clear
		exit
	fi
	}

echo;while [ -n "$1" ];do
case "$1" in

-A)	MODE="-A"
	installAarch64
	exit
	;;

-b)	MODE="-b"
	backUp
	exit
	;;

-B)	MODE="-B"
	buttonMenu
	exit
	;;

-c)	MODE="-c"
	configEditor
	exit
	;;

-i)	MODE="-i"
	infoNFQWS
	exit
	;;

-I)	MODE="-I"
	installUniversal
	exit
	;;

-l)	MODE="-l"
	listsEditor
	exit
	;;

-m)	MODE="-m"
	installMips
	exit
	;;

-M)	MODE="-M"
	installMipsel
	exit
	;;

-o)	MODE="-o"
	profileOptimize
	exit
	;;

-r)	MODE="-r"
	restartNFQWS
	exit
	;;

-R)	MODE="-R"
	uninstallNFQWS
	exit
	;;

-s)	MODE="-s"
	stopNFQWS
	exit
	;;

-S)	MODE="-S"
	startNFQWS
	exit
	;;

-u)	clear
	opkg update
	opkg install ca-certificates wget-ssl
	opkg remove wget-nossl
	wget -O /tmp/nk.sh https://
	if [ ! "`cat "/tmp/nk.sh" | grep -c 'function fileSave'`" -gt "0" ];then
		echo "Ошибка: проблемы со скачиванием файла..."
	else
		mv /tmp/nk.sh /opt/bin/nk
		chmod +x /opt/bin/nk
		echo "Сейчас установлен: Xvps `cat "/opt/bin/nk" | grep '^VERSION="' | awk '{gsub(/VERSION="/,"")}1' | awk '{gsub(/"/,"")}1'`"
	fi
	exit
	;;

-U)	MODE="-U"
	updateNFQWS
	exit
	;;

-v)	echo " $VERSION"
	exit
	;;

-W)	MODE="-W"
	installWeb
	exit
	;;

-z)	MODE="-z"
	zyxelSetup
	exit
	;;

*) 	echo "Ошибка: введён некорректный ключ.

Доступные ключи:

	-A: Установка NFQWS-Keenetic архитектуры aarch64
	-b: Резервное копирование профиля
	-B: Настройка кнопок маршрутизатора
	-с: Редактор конфигурации
	-i: Информация о пакете 
	-I: Универсальный установщик NFQWS-Keenetic
	-l: Редактор списков
	-m: Установка NFQWS-Keenetic архитектуры mips
	-M: Установка NFQWS-Keenetic архитектуры mipsel
	-o: Оптимизация профиля
	-r: Перезапуск службы
	-R: Удаление NFQWS-Keenetic
	-s: Остановка службы
	-S: Запуск службы
	-u: Обновление NK
	-U: Обновление NFQWS-Keenetic
	-v: Отображение текущей версии NK
	-W: Установка Web-интерфейса
	-z: Предварительная настройка ZyXel Keenetic (с KeeneticOS 2.x)"
	exit
	;;
	
esac;shift;done
mainMenu