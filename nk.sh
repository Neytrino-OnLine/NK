#!/bin/sh

VERSION="beta 2"
PROFILE_PATH='/opt/etc/nfqws'
BUTTON='/opt/etc/ndm/button.d/nk.sh'
BACKUP='/opt/backup-nk'
DNSCRYPT='/opt/etc/dnscrypt-proxy.toml'
OLD_LIST="ISP_INTERFACE
IPV6_ENABLED
POLICY_NAME
POLICY_EXCLUDE
LOG_LEVEL"
SAVE_LIST="NFQWS_ARGS=Стратегия обработки HTTP(S)
NFQWS_ARGS_QUIC=Стратегия обработки QUIC
NFQWS_ARGS_UDP=Стратегия обработки UDP
TCP_PORTS=TCP порты для iptables
UDP_PORTS=UDP порты для iptables"
LISTS_LIST="auto.list=добавлено автоматически
exclude.list=исключения
user.list=добавлено пользователем"
COLUNS="`stty -a | awk -F"; " '{print $3}' | grep "columns" | awk -F" " '{print $2}'`"

function sysConfigGet
	{
	local SYS_CONFIG=`ndmc -c 'show version'`
	ARCH=`echo "$SYS_CONFIG" | grep "arch: " | sed -e 's/^[^[:alpha:]]\+//' | awk -F": " '{print $2}'`
	if [ "$ARCH" = "mips" ];then
		local HEXDUMP1=`echo -n I | hexdump -o | awk '{ print substr($2,6,1); exit}'`
		local HEXDUMP2=`hexdump -s 5 -n 1 -C /opt/bin/busybox | awk -F" " '{print $2}'`
		if [ "$HEXDUMP1" = "1" -a "$HEXDUMP2" = "01" ];then
			ARCH=$ARCH'el'
		fi
	fi
	}

function checkForUpdate
	{
	local CURENT=`opkg list-installed | grep "^nfqws-keenetic " | awk -F" - " '{print $2}'`
	local URL=`cat /opt/etc/opkg/nfqws-keenetic.conf | awk '{gsub(/^src\/gz nfqws-keenetic /,"")}1'`
	local AVAILABLE="`wget -q -O - "$URL" | sed  's/<[^>]*>//g' | grep "^nfqws-keenetic_" | awk -F"_" '{print $2}'`"
	if [ ! "$CURENT" = "$AVAILABLE" -a -n "$CURENT" -a -n "$AVAILABLE" ];then
		echo "$AVAILABLE"
	else
		echo ""
	fi
	}

function headLine	#1 - заголовок	#2 - скрыть полосу под заголовком	#3 - добавить пустые строки для прокрутки
	{
	if [ -n "$3" ];then
		local COUNTER=24
		while [ "$COUNTER" -gt "0" ];do
			echo -e "\033[30m█\033[39m"
			local COUNTER=`expr $COUNTER - 1`
		done
	fi
	if [ "`expr $COLUNS / 2 \* 2`" -lt "$COLUNS" ];then
		local WIDTH="`expr $COLUNS / 2 \* 2`"
		local PREFIX=' '
	else
		local WIDTH=$COLUNS
		local PREFIX=""
	fi
	if [ -n "$1" ];then
		clear
		local TEXT=$1
		local LONG=`echo ${#TEXT}`
		local SIZE=`expr $WIDTH - $LONG`
		local SIZE=`expr $SIZE / 2`
		local FRAME=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
		if [ "`expr $LONG / 2 \* 2`" -lt "$LONG" ];then
			local SUFIX=' '
		else
			local SUFIX=""
		fi
		echo -e "\033[30m\033[47m$PREFIX$FRAME$TEXT$FRAME$SUFIX\033[39m\033[49m"
	else
		echo -e "\033[30m\033[47m`awk -v i=$COLUNS 'BEGIN { OFS=" "; $i=" "; print }'`\033[39m\033[49m"
	fi
	if [ -n "$MODE" -a -n "$1" -a -z "$2" ];then
		local LONG=`echo ${#MODE}`
		local SIZE=`expr $COLUNS - $LONG - 1`
		echo "`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`$MODE"
	elif [ -z "$MODE" -a -n "$1" -a -z "$2" ];then
		echo ""
	fi
	}

function messageBox	#1 - текст	#2 - цвет
	{
	local TEXT=$1
	local COLOR=$2
	local LONG=`echo ${#TEXT}`
	if [ ! "$LONG" -gt "`expr $COLUNS - 4`" ];then
		local TEXT="│ $TEXT │"
		local SIZE=`expr $COLUNS - $LONG - 4`
		local SIZE=`expr $SIZE / 2`
		local SPACE=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
	else
		local LONG=`expr $COLUNS - 4`
		local SPACE=""
	fi
	if [ "$COLUNS" = "80" ];then
		echo -e "$COLOR$SPACE┌─`awk -v i=$LONG 'BEGIN { OFS="─"; $i="─"; print }'`─┐\033[39m\033[49m"
		echo -e "$COLOR$SPACE$TEXT\033[39m\033[49m"
		echo -e "$COLOR$SPACE└─`awk -v i=$LONG 'BEGIN { OFS="─"; $i="─"; print }'`─┘\033[39m\033[49m"
	else
		echo -e "$COLOR$SPACE□-`awk -v i=$LONG 'BEGIN { OFS="-"; $i="-"; print }'`-□\033[39m\033[49m"
		echo -e "$COLOR$SPACE$TEXT\033[39m\033[49m"
		echo -e "$COLOR$SPACE□-`awk -v i=$LONG 'BEGIN { OFS="-"; $i="-"; print }'`-□\033[39m\033[49m"
	fi
	}

function showText	#1 - текст	#2 - цвет
	{
	local INPUT_TEXT=`echo "$1" | awk '{gsub(/\\\t/,"____")}1'`
	local INPUT_TEXT=`echo -e "$INPUT_TEXT"`
	local STRING=""
	local SPACE=""
	IFS=$' '
	for WORD in $INPUT_TEXT;do
			local WORD_LONG=`echo ${#WORD}`
			local STRING_LONG=`echo ${#STRING}`
			if [ "`expr $WORD_LONG + $STRING_LONG + 1`" -gt "$COLUNS" ];then
				echo -e "$2$STRING\033[39m\033[49m" | awk '{gsub(/____/,"    ")}1'
				local STRING=$WORD
				local END=""
			else
				local STRING=$STRING$SPACE$WORD
				local SPACE=" "
				local END="show"
			fi
	done
	if [ -n "$END" ];then
		echo -e "$2$STRING\033[39m\033[49m" | awk '{gsub(/____/,"    ")}1'
	fi
	}

function showInCentrе	#1 - текст	#2 - цвет
	{
	if [ "`expr $COLUNS / 2 \* 2`" -lt "$COLUNS" ];then
		local WIDTH="`expr $COLUNS / 2 \* 2`"
		local PREFIX=' '
	else
		local WIDTH=$COLUNS
		local PREFIX=""
	fi
	if [ -n "$1" ];then
		local TEXT=$1
		local LONG=`echo ${#TEXT}`
		if [ "$LONG" -lt "$COLUNS" ];then
			local SIZE=`expr $WIDTH - $LONG`
			local SIZE=`expr $SIZE / 2`
			if [ ! "$COLUNS" -lt "$LONG" ];then
				local SPACE=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
			else
				local SPACE=""
			fi
			if [ "`expr $LONG / 2 \* 2`" -lt "$LONG" ];then
				local SUFIX=' '
			else
				local SUFIX=""
			fi
			echo -e "$2$PREFIX$SPACE$TEXT\033[39m\033[49m"
		else
			local LONG="`expr $LONG / 2`"
			local STRING=""
			local SPACE=""
			IFS=$' '
			for WORD in $TEXT;do
				local WORD_LONG=`echo ${#WORD}`
				local STRING_LONG=`echo ${#STRING}`
				if [ "`expr $WORD_LONG + $STRING_LONG + 1`" -gt "$LONG" ];then
					local SIZE=`expr $COLUNS - $STRING_LONG`
					local SIZE=`expr $SIZE / 2`
					local INDENT=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
					echo -e "$2$INDENT$STRING\033[39m\033[49m"
					local STRING=$WORD
					local END=""
				else
					local STRING=$STRING$SPACE$WORD
					local SPACE=" "
					local END="show"
				fi
			done
			if [ -n "$END" ];then
				local STRING_LONG=`echo ${#STRING}`
				local SIZE=`expr $COLUNS - $STRING_LONG`
				local SIZE=`expr $SIZE / 2`
				local INDENT=`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`
				echo -e "$2$INDENT$STRING\033[39m\033[49m"
			fi
		fi
	fi
	}

function copyRight	#1 - название	#2 - год
	{
	if [ "`date +"%C%y"`" -gt "$2" ];then
		local YEAR="-`date +"%C%y"`"
	fi
	local COPYRIGHT="© $2$YEAR rino Software Lab."
	local SIZE=`expr $COLUNS - ${#1} - ${#VERSION} - ${#COPYRIGHT} - 3`
	read -t 1 -n 1 -r -p " $1 $VERSION`awk -v i=$SIZE 'BEGIN { OFS=" "; $i=" "; print }'`$COPYRIGHT" keypress
	}

function showOption	#1 - текст	#2 - флаг блокировки
	{
	if [ -n "$2" ];then
		local COLOR="\033[90m"
	fi
	echo -e "$COLOR$1\033[39m"
	}

function backUp	#1 - не возвращаться в меню резервного копирования по завершению процесса
	{
	if [ -d $BACKUP/profile ];then
		local STATE=""
	else
		local STATE="block"
	fi
	headLine "Резервное копирование профиля"
	echo "Что вы хотите сделать?"
	echo ""
	echo -e "\t1: Создать резервную копию профиля"
	showOption "\t2: Восстановить файлы из резервной копии" "$STATE"
	showOption "\t3: Удалить резервную копию" "$STATE"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		if [ -z "$STATE" ];then
			showText "\tПри сохранении новой резервной копии, старая - будет полностью удалена..."
			echo ""
			echo "Создать новую резервную копию?"
			echo ""
			echo -e "\t1; Да (по умолчанию)"
			echo -e "\t0; Нет"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ ! "$REPLY" = "0" ];then
				rm -rf $BACKUP/profile
				mkdir -p $BACKUP/profile
				cp -r $PROFILE_PATH/*.* $BACKUP/profile
				messageBox "Резервная копия - создана."
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			fi
		else
			mkdir -p $BACKUP/profile
			cp -r $PROFILE_PATH/*.* $BACKUP/profile
			messageBox "Резервная копия - создана."
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		if [ -z "$1" ];then
			backUp
		fi
	elif [ "$REPLY" = "2" ];then
		if [ -z "$STATE" ];then
			echo "Какие данные вы хотите восстановить?"
			echo ""
			echo -e "\t1: Профиль целиком (по умолчанию)"
			echo -e "\t2: Только файл конфигурации"
			echo -e "\t3: Только файлы списков"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "2" ];then
				cp -r $BACKUP/profile/nfqws.conf $PROFILE_PATH
				messageBox "Файл конфигурации - восстановлен."
			elif [ "$REPLY" = "3" ];then
				cp -r $BACKUP/profile/*.list $PROFILE_PATH
				messageBox "Файлы списков - восстановлены."
			else
				cp -r $BACKUP/profile/*.* $PROFILE_PATH
				messageBox "Профиль - восстановлен."
			fi
			echo ""
			restartDialogue
		else
			messageBox "Резервная копия отсутствует." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		if [ -z "$1" ];then
			backUp
		fi
	elif [ "$REPLY" = "3" ];then
		if [ -z "$STATE" ];then
			rm -rf $BACKUP/profile
			messageBox "Резервная копия - удалена."
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		else
			messageBox "Резервная копия отсутствует." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		if [ -z "$1" ];then
			backUp
		fi
	fi
	
	}

function fileSave	#1 - путь к файлу	#2 - сохраняемое содержимое
	{
	local FILE=`basename "$1"`
	if [ -f "$1" ];then
		if [ -n "$2" ];then
			echo "Файл: $FILE - уже существует,"
		else
			echo "Файл: $FILE - перемещён в:"
		fi
		local DATE_TTME=`date +"%C%y.%m.%d_%H-%M-%S"`
		local BACKUP_PATH="$BACKUP/$DATE_TTME/"
		mkdir -p "$BACKUP_PATH"
		mv "$1" "$BACKUP_PATH$FILE"
		if [ -f "$BACKUP_PATH$FILE" ];then
			if [ -n "$2" ];then
				echo "он перемещён в: $BACKUP_PATH"
			else
				echo "$BACKUP_PATH"
			fi
		else
			echo ""
			messageBox "Не удалось создать резервную копию." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			exit
		fi
		echo ""
	fi
	if [ -n "$2" ];then
		echo -e "$2" > $1
		messageBox "Файл: $FILE - сохранён."
		echo ""
	fi
	}

function listGet	#1 - файл списка
	{
	LIST=`cat $1 | awk '{sub(/^[[:space:]]*$/,"sp@ce")}1'`
	LIST=`echo -e "$LIST"`
	}

function listConfluence	#1 - файл текущего списка	#2 - файл нового списка
	{
	local REMAINDER="`grep -Fxvf "$1" "$2"`"
	if [ -n "$REMAINDER" ];then
		listGet "$1"
		LIST=`echo -e "$LIST" | awk '{sub(/^sp@ce/,"")}1'`
		LIST=`echo -e "$LIST\n\n$REMAINDER"`
		if [ -n "`echo "$2" | grep "$1"`" -a -z "`echo "$1" | grep "$2"`" ];then
			fileSave "$1" "$LIST"
			fileSave "$2" ""
		else
			fileSave "$2" "$LIST"
			fileSave "$1" ""
		fi
	else
		if [ -n "`echo "$2" | grep "$1"`" -a -z "`echo "$1" | grep "$2"`" ];then
			fileSave "$2" ""
		else
			fileSave "$1" ""
		fi
	fi
	}

function configGet	#1 - файл конфигурации
	{
	CONFIG=`cat "$1" | awk '{sub(/^[[:space:]]*$/,"sp@ce")}1'`
	CONFIG=`echo -e "$CONFIG"`
	}

function configOptimize	#1 - файл текущей конфигурации	#2 - файл новой конфигурации
	{
	headLine "Оптимизация конфигурации"
	echo -e "\tПодождите..."
	configGet "$PROFILE_PATH/nfqws.conf"
	CURENT_CONFIG=`echo -e "$CONFIG"`
	configsConfluence "$1" "$2"
	headLine "Оптимизация конфигурации"
	messageBox "Оптимизированная конфигурация - сформирована."
	echo ""
	showText "\tТеперь можно её протестировать и убедиться что всё работает правильно..."
	echo ""
	echo -e "\t1: Начать тестирование"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		configTest "$1" "$2"
	fi
	}

function configTest	#1 - файл текущей конфигурации	#2 - файл новой конфигурации
	{
	local TEST_CONFIG=`echo -e "$CONFIG" | awk '{sub(/^sp@ce/,"")}1'`
	fileSave "$PROFILE_PATH/nfqws.conf" "$TEST_CONFIG"
	restartNFQWS "compact"
	headLine "Тестирование конфигурации" "hide" "space"
	echo "$TEST_CONFIG"
	headLine
	if [ -n "`echo -e "$CONFIG" | grep "#OLD#\|#NEW#"`" ];then
		local STATE=""
	else
		local STATE="block"
	fi
	echo ""
	messageBox "Тестовая конфигурация - загружена в NFQWS."
	echo ""
	showText "\tТеперь вы можете проверить - как с этой конфигурацией работают сайты/сервисы/приложения (для работы которых - необходим NFQWS)..."
	echo ""
	echo -e "\t1: Сохранить конфигурацию"
	echo -e "\t2: Отложить решение"
	showOption "\t3: Изменить" "$STATE"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		if [ -z "$STATE" ];then
			echo "Сохранить неиспользованные значения?"
			echo ""
			echo -e "\t1; Да"
			echo -e "\t0; Нет (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				local REMAINDER=`echo -e "$CONFIG" | grep "#OLD#\|#NEW#" | awk '{sub(/#OLD#|#NEW#/,"#")}1' | awk '{sub(/=/,"=#")}1'`
				CONFIG=$CONFIG'\n\n# Optimization BackUp ['`date +"%C%y.%m.%d %H:%M:%S"`']\n'$REMAINDER
			fi
		fi
		CONFIG=`echo -e "$CONFIG" | grep -v "#OLD#\|#NEW#" | awk '{sub(/^sp@ce/,"")}1'`
		fileSave "$PROFILE_PATH/nfqws.conf" "$CONFIG"
		if [ ! "$1" = "$PROFILE_PATH/nfqws.conf" -a -n "$1" ];then
			fileSave "$1" ""
		elif [ ! "$2" = "$PROFILE_PATH/nfqws.conf" -a -n "$2" ];then
			fileSave "$2" ""
		fi
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	elif [ "$REPLY" = "2" ];then
		fileSave "$PROFILE_PATH/nfqws.conf" "$CONFIG"
		if [ ! "$1" = "$PROFILE_PATH/nfqws.conf" -a -n "$1" ];then
			fileSave "$1" ""
		elif [ ! "$2" = "$PROFILE_PATH/nfqws.conf" -a -n "$2" ];then
			fileSave "$2" ""
		fi
		showText "\tВы сможете вернуться к тестированию - выбрав пункт \"Оптимизация профиля\" в главном меню..."
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	elif [ "$REPLY" = "3" ];then
		if [ -z "$STATE" ];then
			configSwitch "$1" "$2"
		else
			messageBox "Изменяемые параметры - отсутствуют." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			modeSwitch
		fi
	else
		CURENT_CONFIG=`echo -e "$CURENT_CONFIG" | awk '{sub(/^sp@ce/,"")}1'`
		fileSave "$PROFILE_PATH/nfqws.conf" "$CURENT_CONFIG"
		restartNFQWS "compact"
	fi
	}

function configSwitch	#1 - файл текущей конфигурации	#2 - файл новой конфигурации
	{
	headLine "Изменение конфигурации"
	showText "\tВы можете ввести один (или несколько, через пробел) идентификатор(ов) настроек - которые хотите переключить..."
	echo ""
	local LIST=`echo -e "$CONFIG" | grep "#OLD#\|#NEW#" | awk -F"=" '{print NR$1}'`
	IFS=$'\n'
	for LINE in $LIST;do
		local STRING=`echo "$LINE" | awk -F"#" '{print $1": Параметр: "$3}'`
		if [ "`echo "$LINE" | awk -F"#" '{print $2}'`" = "NEW" ];then
			local STATE1="block"
			local STATE2=""
		else
			local STATE1=""
			local STATE2="block"
		fi
		echo -e "\t$STRING"
		local PARAM=`echo "$LINE" | awk -F"#" '{print $3}'`
		echo -e "\t(`echo "$SAVE_LIST" | grep "^$PARAM=" | awk -F"=" '{print $2}'`)"
		echo -e "\tЗначение: `showOption "новое" "$STATE1"`/`showOption "станое" "$STATE2"`"
		echo ""
	done
	read -r -p "Введите один (или несколько, через пробел) идентификатор(ов):"
	echo ""
	if [ -n "$REPLY" ];then
		IFS=$' '
		for ITEM in $REPLY;do
			local FLAG="`echo "$LIST" | grep "^$ITEM#" | awk -F"#" '{print $2}'`"
			local PARAM="`echo "$LIST" | grep "^$ITEM#" | awk -F"#" '{print $3}'`"
			if [ -n "$FLAG" -a "$FLAG" = "NEW" ];then
				CONFIG="`echo "$CONFIG" | sed -e "s/^$PARAM=/#OLD#$PARAM=/g"`"
				CONFIG="`echo "$CONFIG" | sed -e "s/^#NEW#$PARAM=/$PARAM=/g"`"
			elif [ -n "$FLAG" -a "$FLAG" = "OLD" ];then
				CONFIG="`echo "$CONFIG" | sed -e "s/^$PARAM=/#NEW#$PARAM=/g"`"
				CONFIG="`echo "$CONFIG" | sed -e "s/^#OLD#$PARAM=/$PARAM=/g"`"
			fi
		done
	fi
	configTest "$1" "$2"
	}

function configsConfluence	#1 - файл текущей конфигурации	#2 - файл новой конфигурации
	{
	configGet "$1"
	local CURENT_CONFIG=`echo -e "$CONFIG"`
	configGet "$2"
	local NEW_CONFIG=`echo -e "$CONFIG"`
	local BACK_UP="`echo "$CURENT_CONFIG" | grep -i -A 2 "BackUp"`"
	local EXTRA_ARGS="`echo "$CURENT_CONFIG" | grep -i -B 1 "^NFQWS_EXTRA_ARGS="`"
	local CURENT_CONFIG="`echo "$CURENT_CONFIG" | grep -v "^#\|NFQWS_EXTRA_ARGS=\|sp@ce"`"
	IFS=$'\n'
	for LINE in $CURENT_CONFIG;do
		if [ ! "`echo "$NEW_CONFIG" | grep "$LINE"`" = "$LINE" ];then
			local PARAM="`echo "$LINE" | awk -F"=" '{print $1}'`"
			local VALUE="`echo "$LINE" | sed -e "s/^$PARAM="/"/g" | awk '{gsub(/"/,"")}1'`"
			if [ "`echo "$OLD_LIST" | awk -F"=" '{print $1}' | grep "^$PARAM$"`=" = "$PARAM=" ];then
				local REPLACE="`echo "$NEW_CONFIG" | grep "^$PARAM="`"
				local REPLACE=$(echo "$REPLACE" | sed 's:/:\\/:g')
				local LINE=$(echo "$LINE" | sed 's:/:\\/:g')
				NEW_CONFIG=`echo "$NEW_CONFIG" | sed -e "s/^$REPLACE$/$LINE/g"`
			fi
			if [ "`echo "$SAVE_LIST" | awk -F"=" '{print $1}' | grep "^$PARAM$"`=" = "$PARAM=" ];then
				local REPLACE="`echo "$NEW_CONFIG" | grep "^$PARAM="`"
				local REPLACE=$(echo "$REPLACE" | sed 's:/:\\/:g')
				local LINE=$(echo "$LINE" | sed 's:/:\\/:g')
				NEW_CONFIG=`echo "$NEW_CONFIG" | sed -e "s/^$REPLACE$/$REPLACE\n#OLD#$LINE/g"`
			fi
		fi
	done
	if [ -n "`echo "$EXTRA_ARGS" | grep "^# auto.*auto.list$"`" ];then
		local EXTRA_ARGS="`echo "$NEW_CONFIG" | grep -i -A 1 "^# auto.*auto.list$" | tail -1`"
	elif [ -n "`echo "$EXTRA_ARGS" | grep "^# list.*user.list$"`" ];then
		local EXTRA_ARGS="`echo "$NEW_CONFIG" | grep -i -A 1 "^# list.*user.list$" | tail -1`"
	else
		local EXTRA_ARGS="`echo "$NEW_CONFIG" | grep -i -A 1 "^# all.*exclude.list$" | tail -1`"
	fi
	local EXTRA_ARGS="`echo "$EXTRA_ARGS" | awk '{gsub(/#/,"")}1'`"
	local EXTRA_ARGS=$(echo "$EXTRA_ARGS" | sed 's:/:\\/:g')
	CONFIG="`echo "$NEW_CONFIG" | awk '{gsub(/^NFQWS_EXTRA_ARGS=/,"#NFQWS_EXTRA_ARGS=")}1' | sed -e "s/#$EXTRA_ARGS/$EXTRA_ARGS/g"`"
	if [ -n "$BACK_UP" ];then
		CONFIG=$CONFIG'\nsp@ce\n'$BACK_UP
	fi
	}

function listsAndProfileOptimize
	{
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
		messageBox "Объектов для оптимизации - не обнаружено." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function profileOptimize
	{
	if [ -n "`cat "$PROFILE_PATH/nfqws.conf" | grep "#OLD#\|#NEW#"`" ];then
		configGet "$PROFILE_PATH/nfqws.conf"
		configTest
	else
		headLine "Оптимизация профиля"
		showText "\tВ процессе обновления NFQWS-Keenetic, в профиле накапливаются разные версии файла настроек и файлов списков (в том числе и пустые)... Данный инструмент, позволит вам упорядочить их содержимое и избавиться от всего лишнего."
		echo ""
		showText "\tПеред тем как начать процесс - настоятельно рекомендуется воспользоваться инструментом создания резервной копии профиля, чтобы (в случае возникновения проблем) - иметь возможность быстро вернуться к предыдущему состоянию..."
		echo ""
		echo "Создать резервную копию профиля?"
		echo ""
		echo -e "\t1: Да"
		echo -e "\t2: Нет (начать оптимизацию)"
		echo -e "\t0: Отмена (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		echo ""
		if [ "$REPLY" = "1" ];then
			backUp "no return"
			listsAndProfileOptimize
		elif [ "$REPLY" = "2" ];then
			listsAndProfileOptimize
		fi
	fi
	}

function segListGet
	{
	local IP_ADDR_SHOW=`ip addr show | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print $(NF)"\t"$2}' | grep -v "^lo\|^ezcfg\|^br"`
	local SHOW_INTERFACE=`ndmc -c show interface | grep "address: \|description: "`
	IFS=$'\n'
	for LINE in $IP_ADDR_SHOW;do
		local IP="`echo "$LINE" | awk -F"\t" '{print $2}'`"
		local DESCRIPTION="`echo "$SHOW_INTERFACE" | grep -i -B 1 -A 0 "$IP" | head -n1 | awk -F": " '{print $2}'`"
		if [ -n "$DESCRIPTION" ];then
			IP_ADDR_SHOW="`echo "$IP_ADDR_SHOW" | sed -e "s/$IP/$DESCRIPTION/g"`"
		fi
	done
	SEG_LIST="`echo "$IP_ADDR_SHOW" | awk -F"\t" '{print "\t• "$1" ("$2")"}'`"
	}

function ispInterfaceEdit
	{
	headLine "Интерфейс провайдера"
	local CURENT="`echo "$CONFIG" | grep "^ISP_INTERFACE="`"
	if [ -n "$CURENT" ];then
		local PARAM="`echo "$CURENT" | awk -F"=" '{print $1}'`"
		local VALUE="`echo "$CURENT" | awk -F"ISP_INTERFACE=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
		local NEW=""
		echo "Текущее значение:$VALUE"
		echo ""
		showText "\tВы можете указать один или несколько интерфейсов (из списка ниже) - разделяя их пробелами (например: \"eth3 nwg1\"). Вы можете ввести "0" - чтобы установить значение по умолчанию. Или нажать ввод (оставив поле пустым) - чтобы использовать текущее значение параметра."
		echo ""
		echo "Доступные варианты:"
		echo ""
		segListGet
		echo "$SEG_LIST"
		echo ""
		read -r -p "Новое значение:"
		echo ""
		if [ "$REPLY" = "0" ];then
			local NEW="$PARAM="'"'`route | grep '^default' | grep -o '[^ ]*$'`'"'
		elif [ -n "$REPLY" ];then
			local NEW="$PARAM="'"'"$REPLY"'"'
		fi
		if [ ! "$CURENT" = "$NEW" -a -n "$NEW" ];then
			local NEW=$(echo "$NEW" | sed 's:/:\\/:g')
			CONFIG=`echo "$CONFIG" | awk '/^ISP_INTERFACE=/ { $0 = "repl@ce" } 1' | sed "s/repl@ce/$NEW/g"`
			CHANGES=`expr $CHANGES + 1`
		fi
	else
		messageBox "Параметр не обнаружен." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function httpsEdit
	{
	headLine "Стратегия обработки HTTP(S) трафика"
	local CURENT="`echo "$CONFIG" | grep "^NFQWS_ARGS="`"
	if [ -n "$CURENT" ];then
		local PARAM="`echo "$CURENT" | awk -F"=" '{print $1}'`"
		local VALUE="`echo "$CURENT" | awk -F"NFQWS_ARGS=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
		local NEW=""
		local SAVE=""
		echo "Текущее значение:$VALUE"
		echo ""
		showText "\tВы можете ввести новую стратегию обработки HTTP(S) трафика, или нажать ввод (оставив поле пустым) - чтобы использовать текущее значение параметра."
		echo ""
		read -r -p "Новое значение:"
		echo ""
		if [ -n "$REPLY" ];then
			local NEW="$PARAM="'"'"$REPLY"'"'
			echo "Сохранить старую HTTP(S) стратегию?"
			echo ""
			echo -e "\t1: Да"
			echo -e "\t0: Нет (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				local SAVE='\nsp@ce\n# HTTP(S) strategy BackUp ['`date +"%C%y.%m.%d %H:%M:%S"`']\n#'"$PARAM#=\"$VALUE\""
			fi
		fi
		if [ ! "$CURENT" = "$NEW" -a -n "$NEW" ];then
			local NEW=$(echo "$NEW" | sed 's:/:\\/:g')
			CONFIG=`echo "$CONFIG" | awk '/^NFQWS_ARGS=/ { $0 = "repl@ce" } 1' | sed "s/repl@ce/$NEW/g"`
			CHANGES=`expr $CHANGES + 1`
			if [ -n "$SAVE" ];then
				CONFIG=$CONFIG"`echo -e "$SAVE"`"
			fi
		fi
	else
		messageBox "Параметр не обнаружен." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function quicEdit
	{
	headLine "Стратегия обработки QUIC трафика"
	local CURENT="`echo "$CONFIG" | grep "^NFQWS_ARGS_QUIC="`"
	if [ -n "$CURENT" ];then
		local PARAM="`echo "$CURENT" | awk -F"=" '{print $1}'`"
		local VALUE="`echo "$CURENT" | awk -F"NFQWS_ARGS_QUIC=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
		local NEW=""
		local SAVE=""
		echo "Текущее значение:$VALUE"
		echo ""
		showText "\tВы можете ввести новую стратегию обработки QUIC трафика, или нажать ввод (оставив поле пустым) - чтобы использовать текущее значение параметра."
		echo ""
		read -r -p "Новое значение:"
		echo ""
		if [ -n "$REPLY" ];then
			local NEW="$PARAM="'"'"$REPLY"'"'
			echo "Сохранить старую QUIC стратегию?"
			echo ""
			echo -e "\t1: Да"
			echo -e "\t0: Нет (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				local SAVE='\nsp@ce\n# QUIC strategy BackUp ['`date +"%C%y.%m.%d %H:%M:%S"`']\n#'"$PARAM#=\"$VALUE\""
			fi
		fi
		if [ ! "$CURENT" = "$NEW" -a -n "$NEW" ];then
			local NEW=$(echo "$NEW" | sed 's:/:\\/:g')
			CONFIG=`echo "$CONFIG" | awk '/^NFQWS_ARGS_QUIC=/ { $0 = "repl@ce" } 1' | sed "s/repl@ce/$NEW/g"`
			CHANGES=`expr $CHANGES + 1`
			if [ -n "$SAVE" ];then
				CONFIG=$CONFIG"`echo -e "$SAVE"`"
			fi
		fi
	else
		messageBox "Параметр не обнаружен." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function udpEdit
	{
	headLine "Стратегия обработки UDP трафика"
	local CURENT="`echo "$CONFIG" | grep "^NFQWS_ARGS_UDP="`"
	if [ -n "$CURENT" ];then
		local PARAM="`echo "$CURENT" | awk -F"=" '{print $1}'`"
		local VALUE="`echo "$CURENT" | awk -F"NFQWS_ARGS_UDP=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
		local NEW=""
		local SAVE=""
		echo "Текущее значение:$VALUE"
		echo ""
		showText "\tВы можете ввести новую стратегию обработки UDP трафика, или нажать ввод (оставив строку пустой) - чтобы использовать текущее значение параметра."
		echo ""
		read -r -p "Новое значение:"
		echo ""
		if [ -n "$REPLY" ];then
			local NEW="$PARAM="'"'"$REPLY"'"'
			echo "Сохранить старую UDP стратегию?"
			echo ""
			echo -e "\t1: Да"
			echo -e "\t0: Нет (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				local SAVE='\nsp@ce\n# UDP strategy BackUp ['`date +"%C%y.%m.%d %H:%M:%S"`']\n#'"$PARAM#=\"$VALUE\""
			fi
		fi
		if [ ! "$CURENT" = "$NEW" -a -n "$NEW" ];then
			local NEW=$(echo "$NEW" | sed 's:/:\\/:g')
			CONFIG=`echo "$CONFIG" | awk '/^NFQWS_ARGS_UDP=/ { $0 = "repl@ce" } 1' | sed "s/repl@ce/$NEW/g"`
			CHANGES=`expr $CHANGES + 1`
			if [ -n "$SAVE" ];then
				CONFIG=$CONFIG"`echo -e "$SAVE"`"
			fi
		fi
	else
		messageBox "Параметр не обнаружен." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function tcpPortsEdit
	{
	headLine "TCP порты для iptables"
	local CURENT="`echo "$CONFIG" | grep "^TCP_PORTS="`"
	if [ -n "$CURENT" ];then
		local PARAM="`echo "$CURENT" | awk -F"=" '{print $1}'`"
		local VALUE="`echo "$CURENT" | awk -F"TCP_PORTS=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
		local NEW=""
		local SAVE=""
		echo "Текущее значение:$VALUE"
		echo ""
		showText "\tВы можете указать новые TCP порты для iptables, или нажать ввод (оставив строку пустой) - чтобы использовать текущее значение параметра."
		echo ""
		read -r -p "Новое значение:"
		echo ""
		if [ -n "$REPLY" ];then
			local NEW="$PARAM="'"'"$REPLY"'"'
			echo "Сохранить старое значение?"
			echo ""
			echo -e "\t1: Да"
			echo -e "\t0: Нет (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				local SAVE='\nsp@ce\n# TCP ports for iptables rules BackUp ['`date +"%C%y.%m.%d %H:%M:%S"`']\n#'"$PARAM#=\"$VALUE\""
			fi
		fi
		if [ ! "$CURENT" = "$NEW" -a -n "$NEW" ];then
			local NEW=$(echo "$NEW" | sed 's:/:\\/:g')
			CONFIG=`echo "$CONFIG" | awk '/^TCP_PORTS=/ { $0 = "repl@ce" } 1' | sed "s/repl@ce/$NEW/g"`
			CHANGES=`expr $CHANGES + 1`
			if [ -n "$SAVE" ];then
				CONFIG=$CONFIG"`echo -e "$SAVE"`"
			fi
		fi
	else
		messageBox "Параметр не обнаружен." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function udpPortsEdit
	{
	headLine "UDP порты для iptables"
	local CURENT="`echo "$CONFIG" | grep "^UDP_PORTS="`"
	if [ -n "$CURENT" ];then
		local PARAM="`echo "$CURENT" | awk -F"=" '{print $1}'`"
		local VALUE="`echo "$CURENT" | awk -F"UDP_PORTS=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
		local NEW=""
		local SAVE=""
		echo "Текущее значение:$VALUE"
		echo ""
		showText "\tВы можете указать новые UDP порты для iptables, или нажать ввод (оставив строку пустой) - чтобы использовать текущее значение параметра."
		echo ""
		read -r -p "Новое значение:"
		echo ""
		if [ -n "$REPLY" ];then
			local NEW="$PARAM="'"'"$REPLY"'"'
			echo "Сохранить старое значение?"
			echo ""
			echo -e "\t1: Да"
			echo -e "\t0: Нет (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				local SAVE='\nsp@ce\n# UDP ports for iptables rules BackUp ['`date +"%C%y.%m.%d %H:%M:%S"`']\n#'"$PARAM#=\"$VALUE\""
			fi
		fi
		if [ ! "$CURENT" = "$NEW" -a -n "$NEW" ];then
			local NEW=$(echo "$NEW" | sed 's:/:\\/:g')
			CONFIG=`echo "$CONFIG" | awk '/^UDP_PORTS=/ { $0 = "repl@ce" } 1' | sed "s/repl@ce/$NEW/g"`
			CHANGES=`expr $CHANGES + 1`
			if [ -n "$SAVE" ];then
				CONFIG=$CONFIG"`echo -e "$SAVE"`"
			fi
		fi
	else
		messageBox "Параметр не обнаружен." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function policyNameEdit
	{
	headLine "Название политики"
	local CURENT="`echo "$CONFIG" | grep "^POLICY_NAME="`"
	if [ -n "$CURENT" ];then
		local PARAM="`echo "$CURENT" | awk -F"=" '{print $1}'`"
		local VALUE="`echo "$CURENT" | awk -F"POLICY_NAME=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
		local NEW=""
		local SAVE=""
		echo "Текущее значение:$VALUE"
		echo ""
		showText "\tВы можете указать новое название политики, или нажать ввод (оставив поле пустым) - чтобы использовать текущее значение параметра."
		echo ""
		read -r -p "Новое значение:"
		echo ""
		if [ -n "$REPLY" ];then
			local NEW="$PARAM="'"'"$REPLY"'"'
			echo "Сохранить старое значение?"
			echo ""
			echo -e "\t1: Да"
			echo -e "\t0: Нет (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				local SAVE='\nsp@ce\n# Keenetic policy name BackUp ['`date +"%C%y.%m.%d %H:%M:%S"`']\n#'"$PARAM#=\"$VALUE\""
			fi
		fi
		if [ ! "$CURENT" = "$NEW" -a -n "$NEW" ];then
			local NEW=$(echo "$NEW" | sed 's:/:\\/:g')
			CONFIG=`echo "$CONFIG" | awk '/^POLICY_NAME=/ { $0 = "repl@ce" } 1' | sed "s/repl@ce/$NEW/g"`
			CHANGES=`expr $CHANGES + 1`
			if [ -n "$SAVE" ];then
				CONFIG=$CONFIG"`echo -e "$SAVE"`"
			fi
		fi
	else
		messageBox "Параметр не обнаружен." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function modeSwitch
	{
	headLine "Режим работы"
	local CURENT=""
	local MODE_AUTO="`echo "$CONFIG" | grep -i -A 1 "^# auto.*auto.list$" | grep "NFQWS_EXTRA_ARGS="`"
	local MODE_LIST="`echo "$CONFIG" | grep -i -A 1 "^# list.*user.list$" | grep "NFQWS_EXTRA_ARGS="`"
	local MODE_ALL="`echo "$CONFIG" | grep -i -A 1 "^# all.*exclude.list$" | grep "NFQWS_EXTRA_ARGS="`"
	if [ -n "$MODE_AUTO" -a -n "$MODE_LIST" -a -n "$MODE_ALL" ];then
		showText "\tNFQWS применяет стратегии ко всем доменам из \"user.list\" и \"auto.list\" (за исключением доменов из \"exclude.list\"). В конфигурации доступны (на выбор) три режима работы:"
		showText "\t• Авто (используется по умолчанию) - автоматическое определение недоступных доменов (если в течении 60 секунд, домен окажется недоступен трижды)"
		showText "\t• Список - обработка доменов, только из \"user.list\""
		showText "\t• Всё - обработка всего трафика, кроме доменов из \"exclude.list\""
		echo ""
		if [ -z "`echo "$MODE_AUTO" | grep "#"`" ];then
			messageBox "Выбран режим: Авто"
			local STATE1="block"
			local STATE2=""
			local STATE3=""
		elif [ -z "`echo "$MODE_LIST" | grep "#"`" ];then
			messageBox "Выбран режим: Список"
			local STATE1=""
			local STATE2="block"
			local STATE3=""
		else
			messageBox "Выбран режим: Всё"
			local STATE1=""
			local STATE2=""
			local STATE3="block"
		fi
		echo ""
		echo "Выберите режим работы:"
		echo ""
		showOption "\t1: Авто" "$STATE1"
		showOption "\t2: Список" "$STATE2"
		showOption "\t3: Всё" "$STATE3"
		echo -e "\t0: Отмена (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		echo ""
		if [ "$REPLY" = "1" ];then
			if [ -z "$STATE1" ];then
				local CURENT=$MODE_AUTO
			else
				messageBox "Этот вариант уже выбран." "\033[91m"
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				modeSwitch
			fi
		elif [ "$REPLY" = "2" ];then
			if [ -z "$STATE2" ];then
				local CURENT=$MODE_LIST
			else
				messageBox "Этот вариант уже выбран." "\033[91m"
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				modeSwitch
			fi
		elif [ "$REPLY" = "3" ];then
			if [ -z "$STATE3" ];then
				local CURENT=$MODE_ALL
			else
				messageBox "Этот вариант уже выбран." "\033[91m"
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				modeSwitch
			fi
		fi
		if [ -n "`echo "$CURENT" | grep "#"`" ];then
			local CURENT="`echo "$CURENT" | awk '{gsub(/#/,"")}1'`"
			local CURENT=$(echo "$CURENT" | sed 's:/:\\/:g')
			CONFIG="`echo "$CONFIG" | awk '{gsub(/^NFQWS_EXTRA_ARGS=/,"#NFQWS_EXTRA_ARGS=")}1' | sed -e "s/#$CURENT/$CURENT/g"`"
			CHANGES=`expr $CHANGES + 1`
		fi
	else
		messageBox "Один или несколько параметров не обнаружен(ы)." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function ipv6Switch
	{
	headLine "Обработка IPv6"
	local CURENT="`echo "$CONFIG" | grep "^IPV6_ENABLED="`"
	if [ -n "$CURENT" ];then
		local PARAM="`echo "$CURENT" | awk -F"=" '{print $1}'`"
		local VALUE="`echo "$CURENT" | awk -F"IPV6_ENABLED=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
		local NEW=""
		local SAVE=""
		if [ "$VALUE" = "1" ];then
			messageBox "Текущее значение: обрабатывать"
			local STATE1="block"
			local STATE2=""
		else
			messageBox "Текущее значение: не обрабатывать"
			local STATE1=""
			local STATE2="block"
		fi
		echo ""
		echo "Обрабатывать IPv6 соединения?"
		echo ""
		showOption "\t1: Обрабатывать" "$STATE1"
		showOption "\t2: Не обрабатывать" "$STATE2"
		echo -e "\t0: Отмена (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		echo ""
		if [ "$REPLY" = "1" ];then
			if [ -z "$STATE1" ];then
				local NEW="$PARAM="'1'
			else
				messageBox "Этот вариант уже выбран." "\033[91m"
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				ipv6Switch
			fi
		elif [ "$REPLY" = "2" ];then
			if [ -z "$STATE2" ];then
				local NEW="$PARAM="'0'
			else
				messageBox "Этот вариант уже выбран." "\033[91m"
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				ipv6Switch
			fi
		fi
		if [ ! "$CURENT" = "$NEW" -a -n "$NEW" ];then
			CONFIG=`echo "$CONFIG" | awk '/^IPV6_ENABLED=/ { $0 = "repl@ce" } 1' | sed "s/repl@ce/$NEW/g"`
			CHANGES=`expr $CHANGES + 1`
		fi
	else
		messageBox "Параметр не обнаружен." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function logSwitch
	{
	headLine "Режим вывода данных в Syslog"
	local CURENT="`echo "$CONFIG" | grep "^LOG_LEVEL="`"
	if [ -n "$CURENT" ];then
		local PARAM="`echo "$CURENT" | awk -F"=" '{print $1}'`"
		local VALUE="`echo "$CURENT" | awk -F"LOG_LEVEL=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
		local NEW=""
		local SAVE=""
		if [ "$VALUE" = "1" ];then
			messageBox "Текущее значение: Debug"
			local STATE1="block"
			local STATE2=""
		else
			messageBox "Текущее значение: Silent"
			local STATE1=""
			local STATE2="block"
		fi
		echo ""
		echo "Выберите режим вывода в syslig:"
		echo ""
		showOption "\t1: Debug" "$STATE1"
		showOption "\t2: Silent" "$STATE2"
		echo -e "\t0: Отмена (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		echo ""
		if [ "$REPLY" = "1" ];then
			if [ -z "$STATE1" ];then
				local NEW="$PARAM="'1'
			else
				messageBox "Этот вариант уже выбран." "\033[91m"
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				logSwitch
			fi
		elif [ "$REPLY" = "2" ];then
			if [ -z "$STATE2" ];then
				local NEW="$PARAM="'0'
			else
				messageBox "Этот вариант уже выбран." "\033[91m"
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				logSwitch
			fi
		fi
		if [ ! "$CURENT" = "$NEW" -a -n "$NEW" ];then
			CONFIG=`echo "$CONFIG" | awk '/^LOG_LEVEL=/ { $0 = "repl@ce" } 1' | sed "s/repl@ce/$NEW/g"`
			CHANGES=`expr $CHANGES + 1`
		fi
	else
		messageBox "Параметр не обнаружен." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function policySwitch
	{
	headLine "Режим работы политики доступа"
	local CURENT="`echo "$CONFIG" | grep "^POLICY_EXCLUDE="`"
	if [ -n "$CURENT" ];then
		local PARAM="`echo "$CURENT" | awk -F"=" '{print $1}'`"
		local VALUE="`echo "$CURENT" | awk -F"POLICY_EXCLUDE=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
		local NEW=""
		local SAVE=""
		if [ "$VALUE" = "1" ];then
			messageBox "Политика в режиме исключений"
			local STATE1="block"
			local STATE2=""
		else
			messageBox "Политика в обычном режиме"
			local STATE1=""
			local STATE2="block"
		fi
		echo ""
		echo "Выберите режим работы политики:"
		echo ""
		showOption "\t1: Режим исключений" "$STATE1"
		showOption "\t2: Обычный режим" "$STATE2"
		echo -e "\t0: Отмена (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		echo ""
		if [ "$REPLY" = "1" ];then
			if [ -z "$STATE1" ];then
				local NEW="$PARAM="'1'
			else
				messageBox "Этот вариант уже выбран." "\033[91m"
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				policySwitch
			fi
		elif [ "$REPLY" = "2" ];then
			if [ -z "$STATE2" ];then
				local NEW="$PARAM="'0'
			else
				messageBox "Этот вариант уже выбран." "\033[91m"
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				policySwitch
			fi
		fi
		if [ ! "$CURENT" = "$NEW" -a -n "$NEW" ];then
			CONFIG=`echo "$CONFIG" | awk '/^POLICY_EXCLUDE=/ { $0 = "repl@ce" } 1' | sed "s/repl@ce/$NEW/g"`
			CHANGES=`expr $CHANGES + 1`
		fi
	else
		messageBox "Параметр не обнаружен." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

function restartDialogue
	{
	showText "\tДля того чтобы изменения вступили в силу - необходимо перезапустить службу NFQWS..."
	echo ""
	echo "Перезапустить службу?"
	echo ""
	echo -e "\t1: Да"
	echo -e "\t0 Нет (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		restartNFQWS "compact"
	fi
	}

function configSwitches
	{
	headLine "Переключаемые параметры"
	echo -e "\t1: Режим работы"
	echo -e "\t2: Обработка IPv6"
	echo -e "\t3: Режим работы политики доступа"
	echo -e "\t4: Режим вывода данных в Syslog"
	echo -e "\t0: Назад (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	if [ "$REPLY" = "1" ];then
		modeSwitch
	elif [ "$REPLY" = "2" ];then
		ipv6Switch
	elif [ "$REPLY" = "3" ];then
		policySwitch
	elif [ "$REPLY" = "4" ];then
		logSwitch
	fi
	}

function configAction
	{
	headLine "Конфигурация" "hide" "space"
	if [ -n "$CONFIG" ];then
		echo -e "$CONFIG" | awk '{sub(/^sp@ce*$/,"")}1'
	else
		messageBox "Конфигурация отсутствует." "\033[91m"
	fi	
	headLine
	if [ "$COLUNS" = "80" ];then
		local SEPARATE=""
	else
		local SEPARATE="\n"
	fi
	echo ""
	echo "Доступные действия:"
	echo ""
	echo -e "\t1: Сохранить\t\t$SEPARATE\t2: Интерфейс провайдера"
	echo -e "\t3: HTTP(S) стратегия\t$SEPARATE\t4: QUIC стратегия"
	echo -e "\t5: UDP стратегия\t$SEPARATE\t6: TCP порты"
	echo -e "\t7: UDP порты\t\t$SEPARATE\t8: Название политики"
	echo -e "\t9: Переключаемые параметры$SEPARATE\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		CONFIG=`echo "$CONFIG" | awk '{sub(/^sp@ce/,"")}1'`
		fileSave "$PROFILE_PATH/nfqws.conf" "$CONFIG"
		restartDialogue
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
			showText "Если продолжить, все внесённые изменения - будут утеряны..."
			echo ""
			echo -e "\t1: Продолжить"
			echo -e "\t0: Назад (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
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
	if [ "$COLUNS" = "80" ];then
		local SEPARATE=""
	else
		local SEPARATE="\n\t   "
	fi
	local LISTS=`ls $PROFILE_PATH | grep ".list$" | awk '{gsub(/.list /,".list\n")}1'`
	local LISTS=`echo -e "$LISTS" | awk '{print NR"#"$0}'`
	headLine "Редактор списков"
	echo "Выберите список для редактирования:"
	echo ""
	IFS=$'\n'
	for LINE in $LISTS;do
		local LIST_NAME=`echo "$LINE" | awk -F"#" '{print $2}'`
		echo -e "\t`echo $LINE | awk -F"#" '{print $1": "$2}'` $SEPARATE(`echo "$LISTS_LIST" | grep "^$LIST_NAME=" | awk -F"=" '{print $2}'`)"
		if [ -n "$SEPARATE" ];then
			echo ""
		fi
	done
	echo -e "\t0: отмена (по умолчанию)"
	echo ""
	read -r -p "Введите номер списка:"
	echo ""
	FILE_NAME=""
	if [ -z "`echo "$REPLY" | sed 's/[0-9]//g'`" -a ! "$REPLY" = "0" -a ! "$REPLY" = "" ];then
		FILE_NAME=`echo "$LISTS" | grep "^$REPLY#" | awk -F"#" '{print $2}'`
		if [ -n "$FILE_NAME" ];then
			EDIT=`cat $PROFILE_PATH/$FILE_NAME`
		else
			EDIT=""
		fi
	fi
echo "e=$EDIT"
	}

function itemAdd
	{
	local NEW=""
	read -r -p "Добавить в список:" ADD_FIELD
	echo ""
	if [ -n "$EDIT" ];then
		local NEW='\n'
	fi
	if [ -n "$ADD_FIELD" ];then
		local COINCIDENCE="`echo $EDIT | grep "$ADD_FIELD"`"
		if [ -n "$COINCIDENCE" ];then
			messageBox "Обнаружены совпадения."
			echo ""
			echo "В списке уже есть:"
			echo ""
			echo "$COINCIDENCE" | awk -F"\n" '{print "\t• "$1}'
			echo ""
			echo "Все равно добавить запись?"
			echo ""
			echo -e "\t1: Да (по умолчанию)"
			echo -e "\t0: Нет"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ ! "$REPLY" = "0" ];then
				EDIT=$EDIT$NEW$ADD_FIELD
				local NEW='\n'
				EDIT=`echo -e "$EDIT"`
			fi
		else
			EDIT=$EDIT$NEW$ADD_FIELD
			local NEW='\n'
			EDIT=`echo -e "$EDIT"`
		fi
		itemAdd
	else
		EDIT=`echo -e "$EDIT"`
		CHANGES=`expr $CHANGES + 1`
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
			echo "$EDIT" | grep "$DEL_FIELD" | awk -F"\n" '{print "\t• "$1}'
			echo ""
			echo "Удалить все совпадения?"
			echo ""
			echo -e "\t1: Да"
			echo -e "\t0: Нет (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:"
			echo ""
			if [ "$REPLY" = "1" ];then
				EDIT=`echo "$EDIT" | grep -v "$DEL_FIELD"`
				CHANGES=`expr $CHANGES + 1`
				listAction
			else
				listAction
			fi
		else
			messageBox "Совпадений не найдено"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			itemDelete
		fi
	else
		listAction
	fi
	}

function listAction
	{
	if [ ! "$FILE_NAME" = "" ];then
		headLine "Список: $FILE_NAME" "hide" "space"
		if [ -n "$EDIT" ];then
			echo -e "$EDIT" | awk -F"\n" '{print "\t"$1}'
		else
			messageBox "Список пуст"
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
		echo ""
		if [ "$REPLY" = "1" ];then
			fileSave "$PROFILE_PATH/$FILE_NAME" "$EDIT"
			srestartDialogue
		elif [ "$REPLY" = "2" ];then
			showText "\tВы можете добавлять строку за строкой... Для завершения процесса добавления - нажмите ввод (оставив поле пустым)."
			echo ""
			itemAdd
		elif [ "$REPLY" = "3" ];then
			showText "\tВведите последовательность символов,  содержащуюся в строках - которые нужно удалить. Или нажмите ввод (оставив поле пустым), для выхода из диалога удаления..."
			echo ""
			itemDelete
		elif [ "$REPLY" = "4" ];then
			EDIT=""
			CHANGES=`expr $CHANGES + 1`
			listAction
		else
			if [ "$CHANGES" -gt "0" ];then
				showText "Если продолжить, все внесённые изменения - будут утеряны..."
				echo ""
				echo -e "\t1: Продолжить"
				echo -e "\t0: Назад (по умолчанию)"
				echo ""
				read -r -p "Ваш выбор:"
				echo ""
				if [ ! "$REPLY" = "1" ];then
					listAction
				fi
			fi
		fi
	fi
	}

function listsEditor
	{
	FILE_NAME=""
	EDIT=""
	CHANGES="0"
	listsGet
	listAction
	}

function startNFQWS	#1 - скрыть заголовок
	{
	if [ -z "$1" ];then
		headLine "Запуск службы NFQWS"
		echo "Запуск службы..."
		echo ""
	fi
	local LOG="`/opt/etc/init.d/S51nfqws start`"
	statusNFQWS "hide headline"
	echo "Хотите просмотреть лог?"
	echo ""
	echo -e "\t1: Да"
	echo -e "\t0: Нет (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		headLine
		echo "$LOG"
		headLine
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}
	
function stopNFQWS
	{
	headLine "Остановка службы NFQWS"
	if [ "`/opt/etc/init.d/S51nfqws status`" = "Service NFQWS is running" ];then
		echo "Остановка службы FNQWS..."
		echo ""
		echo "`/opt/etc/init.d/S51nfqws stop`" > /dev/null
	
	fi
	statusNFQWS "no headline"
	read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	}
	
function restartNFQWS	#1 - компактная версия
	{
	if [ -z "$1" ];then
		if [ "`/opt/etc/init.d/S51nfqws status`" = "Service NFQWS is running" ];then
			headLine "Перезапуск службы NFQWS"
			echo "`/opt/etc/init.d/S51nfqws stop`" > /dev/null
			echo "Перезапуск службы..."
			echo ""
		else
			headLine "Запуск службы NFQWS"
			echo "Запуск службы..."
			echo ""
		fi
		startNFQWS "no headline"
	else
		headLine "Перезапуск службы NFQWS"
		echo -e "\tПодождите..."
		echo "`/opt/etc/init.d/S51nfqws restart`" > /dev/null
	fi
	}
	
function statusNFQWS	#1 - скрыть заголовок
	{
	if [ -z "$1" ];then
		headLine "Статус службы NFQWS"
	fi
	local TEXT="Служба NFQWS - остановлена."
	if [ -f "/opt/etc/init.d/S51nfqws" ];then
		if [ "`/opt/etc/init.d/S51nfqws status`" = "Service NFQWS is running" ];then
			local TEXT="Служба NFQWS - запущена."
		fi
	fi
	if [ -z "$1" ];then
		echo "$TEXT"
		echo ""
		headLine
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	
	else
		messageBox "$TEXT"
		echo ""
	fi
	}

function preInstall
	{
	echo "`opkg update`" > /dev/null
	echo "`opkg install ca-certificates wget-ssl`" > /dev/null
	echo "`opkg remove wget-nossl`" > /dev/null
	if [ ! -d "/opt/etc/opkg" ];then
		mkdir -p /opt/etc/opkg
	fi
	}

function nfqwsInstall	#1 - пропустить диалог демонстрации лога
	{
	echo "Установка пакета..."
	echo "`opkg update`" > /dev/null
	local LOG="`opkg install nfqws-keenetic`"
	headLine "Установка NFQWS-Keenetic"
	echo "Установка пакета..."
	echo ""
	messageBox "Пакет - установлен"
	echo ""
	if [ -z "$1" ];then
		echo "Хотите просмотреть лог?"
		echo ""
		echo -e "\t1: Да"
		echo -e "\t0: Нет (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		echo ""
		if [ "$REPLY" = "1" ];then
			headLine
			echo "$LOG"
			headLine
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
	fi
	}

function installMips	#1 - пропустить диалог демонстрации лога
	{
	headLine "Установка NFQWS-Keenetic"
	preInstall
	echo "src/gz nfqws-keenetic https://anonym-tsk.github.io/nfqws-keenetic/mips" > /opt/etc/opkg/nfqws-keenetic.conf
	nfqwsInstall "$1"
	}

function installMipsel	#1 - пропустить диалог демонстрации лога
	{
	headLine "Установка NFQWS-Keenetic"
	preInstall
	echo "src/gz nfqws-keenetic https://anonym-tsk.github.io/nfqws-keenetic/mipsel" > /opt/etc/opkg/nfqws-keenetic.conf
	nfqwsInstall "$1"
	}

function installAarch64	#1 - пропустить диалог демонстрации лога
	{
	headLine "Установка NFQWS-Keenetic"
	preInstall
	echo "src/gz nfqws-keenetic https://anonym-tsk.github.io/nfqws-keenetic/aarch64" > /opt/etc/opkg/nfqws-keenetic.conf
	nfqwsInstall "$1"
	}

function installUniversal	#1 - пропустить диалог демонстрации лога
	{
	headLine "Установка NFQWS-Keenetic"
	preInstall
	echo "src/gz nfqws-keenetic https://anonym-tsk.github.io/nfqws-keenetic/all" > /opt/etc/opkg/nfqws-keenetic.conf
	nfqwsInstall "$1"
	}

function installWeb
	{
	headLine "Установка WEB-интерфейса"
	echo "Установка WEB-интерфейса NFQWS-keenetic..."
	local LOG="`opkg install nfqws-keenetic-web`"
	echo ""
	echo "Хотите просмотреть лог?"
	echo ""
	echo -e "\t1: Да"
	echo -e "\t0: Нет (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		headLine
		echo "$LOG"
		headLine
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	echo ""
	showText "\tWEEB-интерфейс доступен по адресу:"
	messageBox "http://`ip addr show br0 | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print $2}'`:90" "\033[94m"
	showInCentrе "(можно использовать: CTRL+SHIFT+С - чтобы скопировать выделенный текст)"
	showText "Для входа в WEB-интерфейс - используйте те-же учётные данные, что и для входа в Entware (по умолчанию это имя пользователя: root и пароль: keenetic). Если WEB-интерфейс не открывается, возможно требуется перезагрузить интернет-центр..."
	echo ""
	echo "Выполнить перезагрузку сейчас?"
	echo ""
	echo -e "\t1: Да"
	echo -e "\t0: Нет (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		showText "\tПосле перезагрузки интернет-центра, вам придётся повторно установить подключение к Entware (чтобы продолжить работу с NK)..."
		echo ""
		echo "Перезагрузка..."
		echo "`ndmc -c 'system reboot'`" > /dev/null
	fi
	}

function updateNFQWS
	{
	headLine "Обновление NFQWS-Keenetic"
	echo "`opkg update`" > /dev/null
	local LOG="`opkg upgrade nfqws-keenetic`"
	echo ""
	echo "Хотите просмотреть лог?"
	echo ""
	echo -e "\t1: Да"
	echo -e "\t0: Нет (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		headLine
		echo "$LOG"
		headLine
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	if [ -n "`opkg list-installed | grep "^nfqws-keenetic-web"`" ];then
		local LOG_WEB="`opkg upgrade nfqws-keenetic-web`"
		echo ""
		echo "Хотите просмотреть лог?"
		echo ""
		echo -e "\t1: Да"
		echo -e "\t0: Нет (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		echo ""
		if [ "$REPLY" = "1" ];then
			headLine
			echo "$LOG_WEB"
			headLine
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
	fi
	UPDATE=`checkForUpdate`
	}

function uninstallNFQWS
	{
	headLine "Удаление NFQWS-Keenetic"
	echo "Вы точно хотите удалить NFQWS-keenetic?"
	echo ""
	echo -e "\t1: Да"
	echo -e "\t0: Нет (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		echo "Удалить файлы списков и конфигурации?"
		echo ""
		echo -e "\ty: Да"
		echo -e "\tn: Нет"
		echo ""
		echo -n "Ваш выбор:"
		local LOG="`opkg remove --autoremove nfqws-keenetic-web nfqws-keenetic`" #> /dev/null
		echo ""
		if [ -z "`opkg list-installed | grep "nfqws-keenetic"`" ];then
			messageBox "Пакет - удалён."
		else
			messageBox "Не удалось удалить пакет."
		fi
		echo ""
		echo "Хотите просмотреть лог?"
		echo ""
		echo -e "\t1: Да"
		echo -e "\t0: Нет (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		echo ""
		if [ "$REPLY" = "1" ];then
			headLine
			echo "$LOG"
			headLine
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
	fi
	}

function installNFQWS
	{
	headLine "Установка NFQWS-Keenetic"
	sysConfigGet
	messageBox "Текущая архитектура: $ARCH"
	echo "Выберите архитектуру:"
	echo ""
	echo -e "\t1: mips"
	echo -e "\t2: mipsel"
	echo -e "\t3: aarch64"
	echo -e "\t4: Универсальный установщик"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		installMips
		installMenu
	elif [ "$REPLY" = "2" ];then
		installMipsel
		installMenu
	elif [ "$REPLY" = "3" ];then
		installAarch64
		installMenu
	elif [ "$REPLY" = "4" ];then
		installUniversal
		echo ""
		installMenu
	else
		installMenu
	fi
	}

function infoNFQWS
	{
	headLine "Сведения о пакете" "hide"
	opkg info nfqws-keenetic
	headLine
	echo ""
	read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	}

function findStrategy
	{
	headLine "Подбор рабочей стратегии NFQWS"
	showText "\tДля поиска рабочей стратегии - запустите скрипт и следуйте инструкциям. Подробнее о его работе - можно почитать здесь:"
	messageBox "https://clck.ru/3F84AQ" "\033[94m"
	showInCentrе "(можно использовать: CTRL+SHIFT+С - чтобы скопировать выделенный текст)"
	echo ""
	echo -e "\t1: Запустить скрипт"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		echo "`opkg install curl`" > /dev/null
		/bin/sh -c "$(curl -fsSL https://github.com/Anonym-tsk/nfqws-keenetic/raw/master/common/strategy.sh)"
	fi
	}

function zyxelSetupBegining
	{
	headLine "Начало настройки"
	showText "\tВ KeeneticOS версии 2.x - отсутствуют компоненты: \"Прокси-сервер DNS-over-TLS\" (DoT) и \"Прокси-сервер DNS-over-HTTPS\" (DoH). В качестве альтернативы - будет установлен и настроен пакет \"dnscrypt-proxy2\"."
	echo ""
	showText "\tПеред тем как продолжить, настоятельно рекомендуется сохранить резервную копию настроек интернет-центра..." "\033[91m"
	echo ""
	echo -e "\t1: Продолжить"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		echo "Установка и настройка dnscrypt-proxy2..."
		echo "`opkg update`" > /dev/null
		echo "`opkg install dnscrypt-proxy2`" > /dev/null
		echo "`opkg install ca-certificates cron iptables`" > /dev/null
		local FILE=`cat $DNSCRYPT | awk '{gsub(/^listen_addresses = \[.127.0.0.1:53.\]/,"listen_addresses = [|0.0.0.0:53|]")}1' | tr "|" "'"`
		echo -e "$FILE" > $DNSCRYPT
		echo "`/opt/etc/init.d/S09dnscrypt-proxy2 start`" > /dev/null
		echo ""
		showText "\tНа следующем шаге, встроенный DNS-прокси - будет заменён \"dnscrypt-proxy2\" и соединение с интернет-центром будет разорвано... После восстановления соединения, необходимо снова подключиться к Entware и повторно запустить: \"Дополнительно/Донастройка ZyXel Keenetic\"."
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		echo "`ndmc -c 'opkg dns-override'`" > /dev/null
		echo "`ndmc -c 'system configuration save'	`" > /dev/null
	fi
	}
	
function zyxelSetupEnding
	{
	headLine "Завершение настройки"
	local DNS=`ip addr show br0 | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print $2}'`
	echo "Настройка DNS в интерфейсе(ах) провайдера..."
	local ISP_INTERFACE="`cat "$PROFILE_PATH/nfqws.conf" | grep "^ISP_INTERFACE=" | awk -F"ISP_INTERFACE=" '{print $2}' | awk '{gsub(/"/,"")}1' | awk '{gsub(/ /,"\n")}1'`"
	local SHOW_INTERFACE=`ndmc -c show interface | grep "address: \|id: "`
	IFS=$'\n'
	for LINE in $ISP_INTERFACE;do
		local IP_ADDR_SHOW=`ip addr show $LINE | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print $2}'`
		local INTERFACE=`echo "$SHOW_INTERFACE" | grep -i -B 1 "$IP_ADDR_SHOW" | grep "id: " | awk -F": " '{print $2}'`
		echo "`ndmc -c ip name-server $DNS '""' on $INTERFACE`" > /dev/null
	done
	echo "`ndmc -c 'system configuration save'	`" > /dev/null
	echo ""
	echo "Настройка DNS в домашнем сегменте..."
	echo "`ndmc -c ip dhcp pool _WEBADMIN dns-server $DNS`" > /dev/null
	echo "`ndmc -c 'system configuration save'	`" > /dev/null
	echo ""
	showText "\t(В веб-конфигураторе) интернет-центра:"
	messageBox "http://$DNS" "\033[94m"
	showInCentrе "(можно использовать: CTRL+SHIFT+С - чтобы скопировать выделенный текст)"
	showText "открываем: \"Сетевые правила/Интернет-фильтр\", в таблице: \"Серверы DNS\" - должны присутствовать только записи с IP-адресом интернет-центра ($DNS)."
	echo ""
	showText "\tЕсли для доступа к интернет, вы не используете серверы авторизации (с указанием внутренних доменных имён из сети провайдера: L2TP, PPPoE, IPoE и т.п.), все остальные записи - нужно удалить. Если такие серверы авторизации используются - удаление DNS провайдера из таблицы - может лишить вас возможности подключение к интернету..."
	rm -rf /opt/etc/ndm/netfilter.d/10-ClientDNS-Redirect.sh
	echo -e '#!/bin/sh\n[ "$type" == "ip6tables" ] && exit 0\n[ "$table" != "nat" ] && exit 0\n[ -z "$(iptables -nvL -t nat | grep "to:'$DNS':53")" ] && iptables -t nat -I PREROUTING -p udp --dport 53 -j DNAT --to-destination '$DNS':53\nexit 0' >> /opt/etc/ndm/netfilter.d/10-ClientDNS-Redirect.sh
	chmod +x /opt/etc/ndm/netfilter.d/10-ClientDNS-Redirect.sh
	echo ""
	showText "\tТеперь нужно перезагрузить интернет-центр."
	echo ""
	echo "Хотите сделать это прямо сейчас?"
	echo ""
	echo -e "\t1: Да (по умолчанию)"
	echo -e "\t0: Нет, я сделаю это самостоятельно"
	echo ""
	read -r -p "Ваш выбор:"
	if [ ! "$REPLY" = "0" ];then
		echo "`ndmc -c system reboot`" > /dev/null
		exit
	fi
	}

function zyxelSetup
	{
	if [ -n "`opkg list-installed | grep "dnscrypt-proxy2"`" ];then
		local STATE1="installed"
	else
		local STATE1=""
	fi
	if [ -f "$DNSCRYPT" ];then
		if [ "`cat "$DNSCRYPT" | grep -c "listen_addresses = \['0.0.0.0:53'\]"`" -gt "0" ];then
			local STATE2="found"
		else
			local STATE2=""
		fi
	else
		local STATE2=""
	fi
	if [ -z "$STATE1" -o -z "$STATE2" ];then
		zyxelSetupBegining
	else
		headLine "Донастройка ZyXel Keenetic"
		showText "\tПохоже, вы снова подключились к Entware  (после разрыва соединения с интернет-центром). Если это так - выберите: \"Продолжить настройку\". В противном случае - вы можете начать процесс сначала..."
		echo ""
		echo -e "\t1: Начать настройку сначала"
		echo -e "\t2: Продолжить настройку"
		echo -e "\t0: Отмена (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		echo ""
		if [ "$REPLY" = "1" ];then
			zyxelSetupBegining
		elif [ "$REPLY" = "2" ];then
			zyxelSetupEnding
		fi
	fi
	}

function policyCreate
	{
	local POLICY_NAME="`cat "$PROFILE_PATH/nfqws.conf" | grep "^POLICY_NAME=" | awk -F"POLICY_NAME=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
	if [ -z "$POLICY_NAME" ];then
		messageBox "Имя политики - не задано." "\033[91m"
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	else
		local SHOW_IP_POLICY="`ndmc -c show ip policy`"
		if [ -z "`echo "$SHOW_IP_POLICY" | grep "description = $POLICY_NAME"`" ];then
			echo "Создание политики доступа..."
			local NUM=0
			while [ -n "`echo "$SHOW_IP_POLICY" | grep "Policy$NUM"`" ];do
				local NUM=`expr $NUM + 1`
			done
			local POLICY="Policy$NUM"
			echo "`ndmc -c ip policy $POLICY`" > /dev/null
			echo ""
			echo "Изменение имени политики доступа..."
			echo "`ndmc -c ip policy $POLICY description $POLICY_NAME`" > /dev/null
			echo ""
		else
			local POLICY="`echo "$SHOW_IP_POLICY" | grep "description = $POLICY_NAME" | awk -F" = " '{print $2}' | awk -F", " '{print $1}'`"
		fi
		echo "Добавление интерфейса(ов) провайдера..."
		local ISP_INTERFACE="`cat "$PROFILE_PATH/nfqws.conf" | grep "^ISP_INTERFACE=" | awk -F"ISP_INTERFACE=" '{print $2}' | awk '{gsub(/"/,"")}1' | awk '{gsub(/ /,"\n")}1'`"
		local ISP_INTERFACE=`echo -e "$ISP_INTERFACE" | awk '{print NR"\t"$0}' | sort -t\t -rk1 | awk -F"\t" '{print $2}'`
		local SHOW_INTERFACE=`ndmc -c show interface | grep "address: \|id: "`
		IFS=$'\n'
		for LINE in $ISP_INTERFACE;do
			local IP_ADDR_SHOW=`ip addr show $LINE | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print $2}'`
			local INTERFACE=`echo "$SHOW_INTERFACE" | grep -i -B 1 "$IP_ADDR_SHOW" | grep "id: " | awk -F": " '{print $2}'`
			echo "`ndmc -c ip policy $POLICY permit global $INTERFACE order 0`" > /dev/null
		done
		echo ""
		echo "Сохранение настроек..."
		echo "`ndmc -c system configuration save`" > /dev/null
		echo ""
		messageBox "Политика: $POLICY_NAME - настроена."
		echo ""
		restartDialogue
	fi
	}

function policyDelete
	{
	local POLICY_NAME="`cat "$PROFILE_PATH/nfqws.conf" | grep "^POLICY_NAME=" | awk -F"POLICY_NAME=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
	local SHOW_IP_POLICY="`ndmc -c show ip policy`"
	if [ -n "`echo "$SHOW_IP_POLICY" | grep "description = $POLICY_NAME"`" ];then
		local POLICY="`echo "$SHOW_IP_POLICY" | grep "description = $POLICY_NAME" | awk -F" = " '{print $2}' | awk -F", " '{print $1}'`"
		echo "Удаление политики..."
		echo "`ndmc -c no ip policy $POLICY`" > /dev/null
		echo ""
		echo "Сохранение настроек..."
		echo "`ndmc -c system configuration save`" > /dev/null
		echo ""
		messageBox "Политика: $POLICY_NAME - удалена."
		echo ""
		restartDialogue
	else
		echo ""
		messageBox "Политика $POLICY_NAME - не найдена." "\033[91m"
		echo ""
	fi
	}

function policySetup
	{
	headLine "Настройка политики доступа"
	showText "\tПолитика доступа, позволяет распространить обработку пакетов, только на устройства/сегменты - добавленные в неё. Или наоборот - оградить их от обработки пакетов. Настроить имя политики и режим её работы - можно в \"Редакторе конфигурации\"..."
	echo ""
	local POLICY_NAME="`cat "$PROFILE_PATH/nfqws.conf" | grep "^POLICY_NAME=" | awk -F"POLICY_NAME=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
	local POLICY_EXCLUDE="`cat "$PROFILE_PATH/nfqws.conf" | grep "^POLICY_EXCLUDE=" | awk -F"POLICY_EXCLUDE=" '{print $2}'`"
	local SHOW_IP_POLICY="`ndmc -c show ip policy`"
	if [ -n "`echo "$SHOW_IP_POLICY" | grep "description = $POLICY_NAME"`" ];then
		if [ "$POLICY_EXCLUDE" = "0" ];then
			local MODE="обычный режим"
		else
			local MODE="режим исключений"
		fi
		messageBox "Политика: $POLICY_NAME, $MODE."
		local STATE=""
	else
		messageBox "Политика доступа - не настроена."
		local STATE="block"
	fi
	echo ""
	echo -e "\t1: Создать/настроить политику"
	showOption "\t2: Удалить политику" "$STATE"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		policyCreate
	elif [ "$REPLY" = "2" ];then
		if [ -z "$STATE" ];then
			policyDelete
		else
			messageBox "Политика отсутствует." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			policySetup
		fi
	fi
	}

function buttonSelect	#1 - без сохранения
	{
	local FLAG=$1
	echo "Выберите кнопку:"
	echo ""
	echo -e "\t1: Кнопка WiFi"
	echo -e "\t2: Кнопка FN1"
	echo -e "\t3: Кнопка FN2"
	showOption "\t4: Сохранить конфигурацию" "$FLAG"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:" BUTTON_NAME
	echo ""
	if [ "$BUTTON_NAME" = "1" -o "$BUTTON_NAME" = "2" -o "$BUTTON_NAME" = "3" ];then
		echo "Выберите тип нажатия:"
		echo ""
		echo -e "\t1: Короткое нажатие"
		echo -e "\t2: Двойное нажатие"
		echo -e "\t3: Длинное нажатие"
		echo -e "\t0: Отмена (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:" TYPE
		echo ""
		if [ "$TYPE" = "1" -o "$TYPE" = "2" -o "$TYPE" = "3" ];then
			echo "Выберите действие:"
			echo ""
			echo -e "\t1: Запустить службу NFQWS"
			echo -e "\t2: Остановить службу NFQWS"
			echo -e "\t3: Перезапустить службу NFQWS"
			echo -e "\t0: Отмена (по умолчанию)"
			echo ""
			read -r -p "Ваш выбор:" ACTION
			echo ""
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
					if [ -n "`echo $WLAN | grep "$TYPE"`" ];then
						local LIST="`echo -e "$WLAN" | awk '{gsub(/\t/,"\n")}1' | grep -v "^$TYPE"`"
						WLAN=""
						IFS=$'\n'
						for LINE in $LIST;do
							WLAN=$WLAN$LINE'\t'
						done
					fi
					WLAN=$WLAN$TYPE'&'$ACTION'\t'
				elif [ "$BUTTON_NAME" = "2" ];then
					if [ -n "`echo $FN1 | grep "$TYPE"`" ];then
						local LIST="`echo -e "$FN1" | awk '{gsub(/\t/,"\n")}1' | grep -v "^$TYPE"`"
						FN1=""
						IFS=$'\n'
						for LINE in $LIST;do
							FN1=$FN1$LINE'\t'
						done
					fi
					FN1=$FN1$TYPE'&'$ACTION'\t'
				else
					if [ -n "`echo $FN2 | grep "$TYPE"`" ];then
						local LIST="`echo -e "$FN2" | awk '{gsub(/\t/,"\n")}1' | grep -v "^$TYPE"`"
						FN2=""
						IFS=$'\n'
						for LINE in $LIST;do
							FN2=$FN2$LINE'\t'
						done
					fi
					FN2=$FN2$TYPE'&'$ACTION'\t'
				fi
				echo ""
				messageBox "Настройка - добавлена в конфигурацию."
				echo ""
				read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
				headLine "Новая конфигурация"
				buttonSelect
			fi
		fi
	elif [ "$BUTTON_NAME" = "4" ];then
		if [ -n "$FLAG" ];then
			messageBox "Отсутствуют данные для сохранения." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
			headLine "Новая конфигурация"
			buttonSelect "no save"
		fi
	else
		WLAN=""
		FN1=""
		FN2=""
	fi
	}

function buttonConfig
	{
	headLine "Новая конфигурация"
	WLAN=""
	FN1=""
	FN2=""
	showText "\tНекоторые кнопки (из списка ниже) могут физически отсутствовать на вашей модели интернет-центра. Пожалуйста выбирайте только те кнопки - которые есть на устройстве..."
	echo ""
	buttonSelect "no save"
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
		echo -e "$TEXT" > "$BUTTON_FILE"
		messageBox "Новая конфигурация - сохранена."
		echo ""
		showText "\tНе забудьте выбрать вариант \"OPKG - Запуск скриптов button.d\" в веб-конфигураторе интернет-центра (Управление/Параметры системы/Назначение кнопок и индикаторов интернет-центра) для всех кнопок и типов нажатия - которые вы настроили..."
		echo ""
	else
		messageBox "Создания новой конфигурации - прервано."
		echo ""
		WLAN=""
		FN1=""
		FN2=""
	fi
	read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	}

function buttonSetup
	{
	headLine "Настройка кнопок"
	showText "\tМожно управлять некоторыми функциями NFQWS-keenetic, при помощи аппаратных кнопок на интернет-центре..."
	echo ""
	if [ -f "$BUTTON_FILE" ];then
		messageBox "Конфигурация кнопок уже используется."
		local STATE=""
	else
		messageBox "Конфигурация не задана."
		local STATE="block"
	fi
	echo ""
	echo -e "\t1: Новая конфигурация"
	showOption  "\t2: Сброс конфигурации" "$STATE"
	echo -e "\t0: Отмена (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		buttonConfig
		buttonSetup
	elif [ "$REPLY" = "2" ];then
		if [ -z "$STATE" ];then
			rm -rf $BUTTON_FILE
			messageBox "Файл конфигурации кнопок - удалён."
		else
			messageBox "Файл конфигурации кнопок отсутствует." "\033[91m"
		fi
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		buttonSetup
	fi
	}

function installMenu
	{
	headLine "Управление пакетом"
	if [ -n "`opkg list-installed | grep "nfqws-keenetic"`" ];then
		local STATE1="block"
		local STATE3=""
	else
		local STATE1=""
		local STATE3="block"
	fi
	if [ -n "`opkg list-installed | grep "nfqws-keenetic-web"`" ];then
		local STATE2="block"
	else
		local STATE2=""
	fi
	showOption "\t1: Установить NFQWS-Keenetic" "$STATE1"
	showOption "\t2: Установить WEB-интерфейс" "$STATE2"
	showOption "\t3: Обновить..." "$STATE3"
	showOption "\t4: Сведения о пакете" "$STATE3"
	showOption "\t9: Удалить NFQWS-Keenetic" "$STATE3"
	echo -e "\t0: В главное меню (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		if [ -z "$STATE1" ];then
			installNFQWS
		else
			messageBox "Пакет NFQWS-keenetic - уже установлен" "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		installMenu
	elif [ "$REPLY" = "2" ];then
		if [ -z "$STATE2" ];then
			installWeb
		else
			messageBox "WEB-интерфейс - уже установлен" "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		installMenu
	elif [ "$REPLY" = "3" ];then
		if [ -z "$STATE3" ];then
			updateNFQWS
		else
			messageBox "Пакет NFQWS-keenetic - отсутствует" "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		installMenu
	elif [ "$REPLY" = "4" ];then
		if [ -z "$STATE3" ];then
			infoNFQWS
		else
			messageBox "Пакет NFQWS-keenetic - отсутствует" "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		installMenu
	elif [ "$REPLY" = "9" ];then
		if [ -z "$STATE3" ];then
			uninstallNFQWS
		else
			messageBox "Пакет NFQWS-keenetic - отсутствует" "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		installMenu
	fi
	}

function extraMenu
	{
	headLine "Дополнительно"
	if [ -d "$BACKUP" ];then
		local STATE1=""
	else
		local STATE1="block"
	fi
	if [ -n "`opkg list-installed | grep "nfqws-keenetic"`" ];then
		local STATE2=""
	else
		local STATE2="block"
	fi
	echo -e "\t1: Резервное копирование профиля"
	showOption "\t2: Удаление резервные копии" "$STATE1"
	showOption "\t3: Политика доступа" "$STATE2"
	echo -e "\t4: Настройка кнопок"
	echo -e "\t5: Донастройка ZyXel Keenetic"
	showOption "\t6: Подбор стратегии NFQWS" "$STATE2"
	echo -e "\t9: Удаление NK"
	echo -e "\t0: В главное меню (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		backUp
		extraMenu
	elif [ "$REPLY" = "2" ];then
		if [ -z "$STATE3" -a -d $BACKUP ];then
			rm -rf $BACKUP
			messageBpx "Резервные копии - удалены."
		else
			messageBox "Резервные копии - отсутствуют." "\033[91m"
		fi
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		extraMenu
	elif [ "$REPLY" = "3" ];then
		if [ -z "$STATE2" -a -d $BACKUP ];then
			policySetup
		else
			messageBox "Пакет NFQWS-keenetic - отсутствуют." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		extraMenu
	elif [ "$REPLY" = "4" ];then
		buttonSetup
		extraMenu
	elif [ "$REPLY" = "5" ];then
		zyxelSetup
		extraMenu
	elif [ "$REPLY" = "6" ];then
		findStrategy
		extraMenu
	elif [ "$REPLY" = "1" ];then
		headLine "Удаление NK"
		echo "Вы действительно хотите удалить NK?"
		echo ""
		echo -e "\t1: Да"
		echo -e "\t0: Нет (по умолчанию)"
		echo ""
		read -r -p "Ваш выбор:"
		echo ""
		if [ "$REPLY" = "9" ];then
			if [ -d $BACKUP ];then
				echo "Удалить все резервные копии?"
				echo ""
				echo -e "\t1: Да"
				echo -e "\t0: Нет (по умолчанию)"
				echo ""
				read -r -p "Ваш выбор:"
				echo ""
				if [ "$REPLY" = "1" ];then
					rm -rf $BACKUP
					messageBpx "Резервные копии - удалены."
				fi
			fi
			headLine
			copyRight "NK" "2024"
			rm -rf /opt/bin/nk
			clear
			exit
		fi
	fi
	}

function mainMenu
	{
	headLine "NK для NFQWS-Keenetic"
	if [ -n "`opkg list-installed | grep "nfqws-keenetic"`" ];then
		local STATE1=""
	else
		local STATE1="block"
	fi
	if [ -d "$PROFILE_PATH" ];then
		if [ -n "$UPDATE" -a -z "$STATE1" ];then
			messageBox "Доступно обновление до: $UPDATE"
			echo ""
			local STATE2=""
			local STATE3="block"
		elif [ -n "`ls "$PROFILE_PATH" | grep "\-old"`" -a -z "$STATE1" -o -n "`ls "$PROFILE_PATH" | grep "\-opkg"`" -a -z "$STATE1" ];	then
			messageBox "Можно оптимизировать профиль..."
			echo ""
			local STATE2="block"
			local STATE3=""
		elif [ -n "`cat "$PROFILE_PATH/nfqws.conf" | grep "#OLD#\|#NEW#"`" -a -z "$STATE1" ];	then
			local STATE2="block"
			local STATE3=""
		else
			local STATE2="block"
			local STATE3="block"
		fi
	else
		local STATE2="block"
		local STATE3="block"
	fi
	echo "Главное меню:"
	echo ""
	showOption "\t1: Запуск/перезапуск службы" "$STATE1"
	showOption "\t2: Остановка службы" "$STATE1"
	showOption "\t3: Состояние службы" "$STATE1"
	showOption "\t4: Обновление" "$STATE2"
	showOption "\t5: Редактор конфигурации" "$STATE1"
	showOption "\t6: Оптимизация профиля" "$STATE3"
	showOption "\t7: Редактор списков" "$STATE1"
	echo -e "\t8: Управление пакетом"
	echo -e "\t9: Дополнительно"
	echo -e "\t0: Выход (по умолчанию)"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ "$REPLY" = "1" ];then
		if [ -z "$STATE1" ];then
			restartNFQWS
		else
			messageBox "Пакет NFQWS-keenetic - не установлен." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		mainMenu
		exit
	elif [ "$REPLY" = "2" ];then
		if [ -z "$STATE1" ];then
			stopNFQWS
		else
			messageBox "Пакет NFQWS-keenetic - не установлен." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		mainMenu
		exit
	elif [ "$REPLY" = "3" ];then
		if [ -z "$STATE1" ];then
			statusNFQWS
		else
			messageBox "Пакет NFQWS-keenetic - не установлен." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		mainMenu
		exit
	elif [ "$REPLY" = "4" ];then
		if [ -z "$STATE2" ];then
			updateNFQWS
		else
			messageBox "Нет доступных обновлений." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		mainMenu
		exit
	elif [ "$REPLY" = "5" ];then
		if [ -z "$STATE1" ];then
			configEditor
		else
			messageBox "Пакет NFQWS-keenetic - не установлен." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		mainMenu
		exit
	elif [ "$REPLY" = "6" ];then
		if [ -z "$STATE3" ];then
			profileOptimize
		else
			messageBox "Оптимизация - не требуется." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		mainMenu
		exit
	elif [ "$REPLY" = "7" ];then
		if [ -z "$STATE1" ];then
			listsEditor
		else
			messageBox "Пакет NFQWS-keenetic - не установлен." "\033[91m"
			echo ""
			read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
		fi
		mainMenu
		exit
	elif [ "$REPLY" = "8" ];then
		installMenu
		mainMenu
		exit
	elif [ "$REPLY" = "9" ];then
		extraMenu
		mainMenu
		exit
	else
		headLine
		copyRight "NK" "2024"
		clear
		exit
	fi
	}

function firstStart	# текст
	{
	headLine "Привет!"
	showText "\tПохоже это $1 NK... Существует мнение что: в хорошей программе - должна быть одна единственная кнопка: \"сделать хорошо\". Руководствуясь им, вам предоставляется возможность настроить почти всё - нажатием одной клавиши (Ввод). А получить доступ к более гибким настройкам, можно в \"Главном меню\"..."
	echo ""
	echo -e "     Ввод: Сделать хорошо"
	echo -e "\t0: В главное меню"
	echo ""
	read -r -p "Ваш выбор:"
	echo ""
	if [ -z "$REPLY" ];then
		sysConfigGet
		if [ -z "`opkg list-installed | grep "nfqws-keenetic"`" ];then
			if [ "$ARCH" = "aarch64" ];then
				installAarch64 "skup"
			elif [ "$ARCH" = "Mipsel" ];then
				installMipsel "skup"
			elif [ "$ARCH" = "Mips" ];then
				installMips "skup"
			else
				installUniversal "skup"
			fi
		fi
		if [ -f "/opt/etc/init.d/S51nfqws" ];then
			if [ "`/opt/etc/init.d/S51nfqws status`" = "Service NFQWS is running" ];then
				showInCentrе "Установка - завершена, NFQWS - уже работает." "\033[92m"
				echo ""
				showText "\tВ главном меню NK, вы сможете: запускать и останавливать службу NFQWS, изменять настройки, редактировать списки доменных имён, создавать и восстанавливать резервные копии пользовательского профиля а также выполнять ряд других (полезных) действий (в режиме диалога)..."
				local NDMS_VERSION="`ndmc -c show version | grep "release" | awk -F": " '{print $2}'`"
				if [ "`echo $NDMS_VERSION | awk -F"." '{print $1}'`" -lt "3" ];then	
					echo ""
					showText "\tВ KeeneticOS 2.x - недоступны компоненты DoT и DoH, вы можете настроить альтернативу в разделе \"Дополнительно/Донастройка ZyXel Keenetic\"..."
				fi
			else
				messageBox "Что-то пошло не так." "\033[91m"
				echo ""
				showText "\tВ главном меню, вы можете попробовать запустить службу NFQWS вручную, или выполнить переустановку пакета..."
			fi
		else
			messageBox "Что-то пошло не так." "\033[91m"
			echo ""
			showText "\tВ главном меню, вы можете попробовать запустить службу NFQWS вручную, или выполнить переустановку пакета..."
		fi
		echo ""
		read -n 1 -r -p "(Чтобы продолжить - нажмите любую клавишу...)" keypress
	fi
	}

echo;while [ -n "$1" ];do
case "$1" in

-a)	sysConfigGet
	messageBox "Сейчас, этот сценарий выполняется на архитектуре: $ARCH"
	exit
	;;

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

-f)	MODE="-f"
	firstStart "имитация первого запуска"
	MODE=""
	mainMenu
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

-p)	MODE="-p"
	policySetup
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

-u)	SCRIPT_NAME="NK"
	headLine "Обновление $SCRIPT_NAME"
	FILE_NAME="`echo "$SCRIPT_NAME" | tr '[:upper:]' '[:lower:]'`"
	if [ -f "/opt/_install/$FILE_NAME.sh" ];then
		echo "Локальное обновление..."
		echo ""
		mv /opt/_install/$FILE_NAME.sh /opt/bin/$FILE_NAME
		rm -rf /opt/_install/
	else
		echo "Обновление..."
		echo ""
		echo "`opkg update`" > /dev/null
		echo "`opkg install ca-certificates wget-ssl`" > /dev/null
		echo "`opkg remove wget-nossl`" > /dev/null
		wget -q -O /tmp/$FILE_NAME.sh https://raw.githubusercontent.com/Neytrino-OnLine/NK/refs/heads/main/nk.sh
		if [ ! -n "`cat "/tmp/$FILE_NAME.sh" | grep 'function copyRight'`" ];then
			messageBox "Не удалось загрузить файл." "\033[91m"
			exit
		else
			mv /tmp/$FILE_NAME.sh /opt/bin/$FILE_NAME
		fi
	fi
	chmod +x /opt/bin/$FILE_NAME
	messageBox "Сейчас, версия $SCRIPT_NAME: `cat "/opt/bin/$FILE_NAME" | grep '^VERSION="' | awk -F"=" '{print $2}' | awk '{gsub(/"/,"")}1'`"
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

*) 	messageBox "Введён некорректный ключ." "\033[91m" "1"
	if [ "$COLUNS" = "80" ];then
		SEPARATE="\t"
	else
		SEPARATE="\n\t"
	fi
	echo ""
	echo -e "Доступные ключи:

	-a: Архитектура процессора$SEPARATE-A: Установка пакета aarch64
	-b: Резервное копирование$SEPARATE-B: Настройка кнопок
	-с: Редактор конфигурации$SEPARATE-f: Имитация первого запуска
	-i: Информация о пакете $SEPARATE-I: Установка универсального пакета
	-l: Редактор списков	$SEPARATE-m: Установка пакета mips
	-M: Установка пакета mipsel$SEPARATE-o: Оптимизация профиля
	-p: Без проверки обновлений$SEPARATE-p: Политика доступа
	-r: Перезапуск службы	$SEPARATE-R: Удаление пакета
	-s: Остановка службы	$SEPARATE-S: Запуск службы
	-u: Обновление NK	$SEPARATE-U: Обновление пакета
	-v: Текущая версия NK	$SEPARATE-W: Установка Web-интерфейса
	-z: Донастройка ZyXel Keenetic"
	exit
	;;
	
esac;shift;done
if [ -z "`opkg list-installed | grep "nfqws-keenetic"`" -a ! -d "$PROFILE_PATH" ];then
	firstStart "первый запуск"
fi
headLine "NK"
echo -e "\tПодождите..."
UPDATE=`checkForUpdate`
mainMenu
