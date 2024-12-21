# NK для [NFQWS-Keenetic](https://github.com/Anonym-tsk/nfqws-keenetic)
Небольшая надстройка, позволяющая упростить и сделать максимально дружелюбным - процесс его установки, настройки и эксплуатации...

## Установка.
Для того чтобы начать использовать NK - достаточно скопировать следующие несколько команд:
```
opkg update
opkg install ca-certificates wget-ssl
opkg remove wget-nossl
wget -O /opt/bin/nk https://raw.githubusercontent.com/Neytrino-OnLine/NK/refs/heads/main/nk.sh
chmod +x /opt/bin/nk

```
И вставить их в окно консоли (кликом по правой кнопке мыши)...
По завершению процесса - вводим в консоль:
```
nk
```
И нажимаем ввод.
