#!/bin/sh
#
# Copyright (C) 2025  Etersoft
# Copyright (C) 2025  Kirill Unitsaev <fiersik@etersoft.ru>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

COPY=false

print_error() {
    printf "\033[1;31m%s\033[0m\n" "$1"
    exit 1
}

print_green() {
    printf "\033[1;32m%s\033[0m\n" "$1"
}

print_yellow() {
    printf "\033[1;33m%s\033[0m\n" "$1"
}

print_blue() {
    printf "\033[1;34m%s\033[0m\n" "$1"
}

print_red() {
    printf "\033[1;31m%s\033[0m\n" "$1"
}

print_white() {
    printf "\033[0m%s\033[0m\n" "$1"
}

print_help() {
	print_white ""
	print_green  "Использование: $(basename $0) [опции]"
	print_white  ""
	print_white  "  -h | --help      Вывод этой справки"
	print_white  ""
	print_blue   "Режим:"
	print_white  "  -m | --mode      Режим создания скриншота"
	print_yellow "                    output - выбрать монитор"
	print_yellow "                    window - выбрать окно"
	print_yellow "                    region - выбрать область"
	print_blue   "Сохраниние:"
	print_white  "  -o | --output    Сохранить изображение в файл"
	print_white  "                   Используйте - для вывода в stdout"
	print_white  "  -c | --copy      Сохранить в буфер обмена" 
	print_blue   "Способ обработки:"
	print_white  "       --swappy    Вызвать swappy"
	print_white  "       --satty     Вызвать satty"
	print_white  "       -- [*]      Перенаправить вывод в другую команду"
	print_red    "                    При использовании -- не учитываются флаги секции 'Сохранение'"
	exit 0
}

trim() {
    local geometry="${1}"
    local xy_str=$(echo "${geometry}" | cut -d' ' -f1)
    local wh_str=$(echo "${geometry}" | cut -d' ' -f2)
    local x=`echo "${xy_str}" | cut -d',' -f1`
    local y=`echo "${xy_str}" | cut -d',' -f2`
    local width=`echo "${wh_str}" | cut -dx -f1`
    local height=`echo "${wh_str}" | cut -dx -f2`

    local max_width=`hyprctl monitors -j | jq -r '[.[] | if (.transform % 2 == 0) then (.x + .width) else (.x + .height) end] | max'`
    local max_height=`hyprctl monitors -j | jq -r '[.[] | if (.transform % 2 == 0) then (.y + .height) else (.y + .width) end] | max'`

    local min_x=`hyprctl monitors -j | jq -r '[.[] | (.x)] | min'`
    local min_y=`hyprctl monitors -j | jq -r '[.[] | (.y)] | min'`

    local cropped_x=$x
    local cropped_y=$y
    local cropped_width=$width
    local cropped_height=$height

    if ((x + width > max_width)); then
        cropped_width=$((max_width - x))
    fi
    if ((y + height > max_height)); then
        cropped_height=$((max_height - y))
    fi

    if ((x < min_x)); then
        cropped_x="$min_x"
        cropped_width=$((cropped_width + x - min_x))
    fi
    if ((y < min_y)); then
        cropped_y="$min_y"
        cropped_height=$((cropped_height + y - min_y))
    fi

    local cropped=`printf "%s,%s %sx%s\n" \
        "${cropped_x}" "${cropped_y}" \
        "${cropped_width}" "${cropped_height}"`
    echo ${cropped}
}

process_screenshot() {
    local output_file="$1"
    local app="$2"
    local geometry="$3"

    case "$app" in
        "")
            if [ "$output_file" = "-" ]; then
                grim -g "${geometry}" --stdout
            elif [ -n "$output_file" ]; then
                grim -g "${geometry}" "$output_file"
            fi
            if [ "$COPY" == "true" ]; then
				grim -g "${geometry}" - | wl-copy
            fi
            ;;
        swappy|satty)
            if [ "$output_file" = "-" ]; then
                grim -g "${geometry}" - | "$app" -f - -o -
            else
                grim -g "${geometry}" - | "$app" -f - -o "${output_file:-}"
            fi
            ;;
    esac
}

save_geometry() {
	local geometry="${1}"

	if [ -z "$OUTPUT" ] && [ "$COPY" == "false" ]; then
		OUTPUT="$(xdg-user-dir PICTURES)/Снимки экрана/снимок-$(date +%Y%m%d-%H%M%S).png"
	fi
	
	if [ -n "$OUTPUT" ] && [ "$OUTPUT" != "-" ]; then
		OUTPUT_DIR=$(dirname "${OUTPUT}")
		mkdir -p "$OUTPUT_DIR"
	fi
	
	if [ "$COMMAND" ]; then
		wayshot -s "${geometry}" --stdout | $COMMAND
		return
	fi
	    
	if [ -z "$OUTPUT_APP" ]; then
	    process_screenshot "$OUTPUT" "" "$geometry"
	else
	    process_screenshot "$OUTPUT" "$OUTPUT_APP" "$geometry"
	fi
}

begin_grab() {
    case $1 in
        output)
			local geometry=`get_output`
            ;;
        region)
            local geometry=`get_region`
            ;;
        window)
        	local geometry=`get_window`
	    geometry=`trim "${geometry}"`
            ;;
    esac
    save_geometry "${geometry}"
}

get_output() {
    slurp -or
}

get_region() {
    slurp -d
}

get_window() {
    local monitors=`hyprctl -j monitors`
    local clients=`hyprctl -j clients | jq -r '[.[] | select(.workspace.id | contains('$(echo $monitors | jq -r 'map(.activeWorkspace.id) | join(",")')'))]'`
    local boxes="$(echo $clients | jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.title)"' | cut -f1,2 -d' ')"
    slurp -r <<< "$boxes"
}

OPTS=$(getopt -o ho:m:c --long help,copy,swappy,satty -- "$@") || {
    print_error "Ошибка обработки опций."
}
eval set -- "$OPTS"

while true; do
    case "$1" in
        -h|--help)
            print_help
            ;;
        -o | --output)
            OUTPUT=$2
            shift 2
            ;;
		-m | --mode)
            MODE=$2
            shift 2
            ;;
		-c | --copy)
            COPY=true
            shift
            ;;
		--swappy)
            OUTPUT_APP=swappy
            shift
            ;;
        --satty)
        	OUTPUT_APP=satty
        	shift
        	;;
		--)
			shift
       		COMMAND=${@}
       		break
       		;;
        "")
            shift
            ;;
       	*)
       		print_error "Неверная опция: $1"
       		;;
       	
    esac
done

begin_grab $MODE
