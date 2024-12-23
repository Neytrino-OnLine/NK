# NK для [NFQWS-Keenetic](https://github.com/Anonym-tsk/nfqws-keenetic)
Небольшая надстройка, позволяющая упростить и сделать максимально дружелюбным - процесс его установки, настройки и эксплуатации...

## Установка.
<details><summary>Для тех, кто начинает с самого начала...</summary>
Нам понадобится маршрутизатор Keenetic (или ZyXel Keenetic) с USB-портом (портами) и поддержкой накопителей.

> К таковым не относятся устройства: 4GII, 4GIII, а так-же бюджетные модели 2024-го года (уточняйте поддержку соответствующих функций на сайте производителя).

<details><summary>Если у вас ZyXel Keenetic с KeeneticOS (версии 2.x)...</summary>
Открываем интерфейс командной строки (в веб-конфигураторе), обычно это:
 
 ````
 http://192.168.1.1/a
 ````
 И вводим в поле "Command" одну из следующих команд:
 
````
components sync legacy
````
> (для KeeneticOS до версии 2.06)
````
components list legacy
````
> (для KeeneticOS версии 2.06 и выше)

Нажимаем кнопку "Отправить запрос".

Затем, переходим в "Управление/Параметры системы", проверяем наличие обновления KeeneticOS и устанавливаем его (если таковое имеется)...
</details>
В веб-конфигураторе переходим в "Управление/Параметры системы", нажимаем "Изменить набор компонентов" и устанавливаем/убеждаемся что установлены следующие компоненты:

- Поддержка открытых пакетов
- Протокол IPv6
- Модули ядра подсистемы Netfilter
- Пакет расширения Xtables-addons для Netfilter

 Устанавливаем недостающие компоненты, перезагружаемся...
 
Теперь нужно определиться - где будет установлен Entware: во встроенной памяти или на USB-накопителе (встроенной памяти нужно 30-40 MB минимум, USB-накопитель - желательно отформатировать в [ext4](https://www.aomeitech.com/pa/standard.html) и обязательно задать ему метку тома).

Скачиваем дистрибутив Entware (подходящий для архитектуры процессора вашего маршрутизатора): [mipsel](https://bin.entware.net/mipselsf-k3.4/installer/mipsel-installer.tar.gz), [mips](https://bin.entware.net/mipssf-k3.4/installer/mips-installer.tar.gz), [aarch64](https://bin.entware.net/aarch64-k3.10/installer/aarch64-installer.tar.gz). Определить, какая именно архитектура у вашего устройства - не так просто как хотелось бы...Открываем интерфейс командной строки:

````
http://192.168.1.1/a
````
Вводим следующую команду:

````
show version
````
И нажимаем кнопку "Отправить запрос". В ответе на этот запрос - будет присудствовать строка содержащая:

````
"arch": "*****"
````
(где ***** - указание на архитектуру процессора).

Если архитектура: aarch64 - можно смело качать и устанавливать соответствующий дистрибутив Entware. Если в ответе: mips - придётся воспользоваться интернетом для уточнения архитектуры процессора вашего маршрутизатора (mips или mipsel)...

Переходим в "Управление/Приложения" (в веб-конфигураторе), в разделе "Диски и принтеры" - открываем накопитель (который будет использоваться для размещения Entware), создаём в корне диска папку "install" (с маленькой буквы) - помещаем в неё скачанный архив с дистрибутивом Entware.

Затем, переходим в "Управление/OPKG" и в меню "Накопитель" - выбираем диск с дистрибутивом Entware, нажимаем "Сохранить"...

Дождавшись когда побледневшая кнопка "Сохранить" полностью исчезнет - переходим в "Управление/Диагностика", где нажимаем "Показать журнал". В журнале (один за другим) будут появляться события об устанавке различных модулей Entware, мы ждём события: "Установка системы пакетов Entware - завершена".

Теперь нам понадобится [PuTTY](http://www.putty.org/) (скачиваем, устанавливаем и запускаем его). В поле "Host Name (or IP adress)" - вписываем IP-адрес вашего маршрутизатора (обычно это: 192.168.1.1), в поле "Port" - оставляем "22" (или вводим "222", если до установки Entware в прошивке уже был установлен компонент "Сервер SSH") и нажимаем кнопку "Open"... (При первом подключении) появится окошко с предупреждением (в котором нужно нажать "Accept") и окошко терминала - в котором должен появиться запрос на ввод имени пользователя. Вводим:

````
root
````
(в качестве имени), а в качестве пароля:

````
keenetic
````
(при вводе пароля - символы отображаться не будут). Если всё правильно - появится приглашение для ввода команд: "~ #"...
</details>

Для того чтобы начать пользоваться NK - достаточно скопировать следующие несколько команд:

```
opkg update
opkg install ca-certificates wget-ssl
opkg remove wget-nossl
wget -O /opt/bin/nk https://raw.githubusercontent.com/Neytrino-OnLine/NK/refs/heads/main/nk.sh
chmod +x /opt/bin/nk

```
И вставить их в окно терминала (кликом правой кнопки мыши)...
По завершению процесса - вводим в терминал:
```
nk
```
И нажимаем ввод.
