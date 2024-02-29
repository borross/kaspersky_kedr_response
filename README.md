(English description is below)

# Использование
`chmod +x kedr_response_universal.sh`

Сгенерируйте уникальный UUID (на ОС должен быть установлен uuidgen):
`./kedr_response_universal.sh -uuid`

Создайте сертификат и пару ключей для связи API:
`./kedr_response_universal.sh -kata <KATA_IP_ADDRESS>`

Доступные действия KEDR:
`./kedr_response_universal.sh -kedr_isolate <KEDR_IP_ADDRESS> <HOURS>` изолирует хост KEDR_IP_ADDRESS от сети на <HOURS> часов.
`./kedr_response_universal.sh -kedr_isolate_off <KEDR_IP_ADDRESS>` отключение изоляции хоста <KEDR_IP_ADDRESS> от сети на <HOURS> часов
`./kedr_response_universal.sh -kedr_block <KEDR_IP_ADDRESS или all> <md5 или sha256> <hash>` отключение изоляции хоста <KEDR_IP_ADDRESS> от сети на <HOURS> часов
`./kedr_response_universal.sh -kedr_exec <KEDR_IP_ADDRESS> \"<file_execute>\"` файл, исполняемый на хосте <KEDR_IP_ADDRESS>. Для пути используйте четыре обратных слеша вместо одного

Посмотреть журнал активности скрипта:
`journalctl | grep kuma-KEDR-response`


# Usage

`chmod +x kedr_response_universal.sh`

Generate unique UUID (uuidgen must be installed on the OS):
`./kedr_response_universal.sh -uuid`

Generate certificate and key pair foe API communication:
`./kedr_response_universal.sh -kata <KATA_IP_ADDRESS>`

Available KEDR actions:
`./kedr_response_universal.sh -kedr_isolate <KEDR_IP_ADDRESS> <HOURS>` isolating KEDR_IP_ADDRESS host from network for <HOURS> hours
`./kedr_response_universal.sh -kedr_isolate_off <KEDR_IP_ADDRESS>` disabling isolation <KEDR_IP_ADDRESS> host from network for <HOURS> hours
`./kedr_response_universal.sh -kedr_block <KEDR_IP_ADDRESS or all> <md5 or sha256> <hash>` disabling isolation <KEDR_IP_ADDRESS> host from network for <HOURS> hours
`./kedr_response_universal.sh -kedr_exec <KEDR_IP_ADDRESS> \"<file_execute>\"` file executing on host <KEDR_IP_ADDRESS>. For path use four back slashes instead of one.

See script activity log:
`journalctl | grep kuma-KEDR-response`
