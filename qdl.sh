#!/bin/bash

#tool: quick downloder
#by RUR999
#fb: Riyaz Ull Rabby


# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Path & temp file
download_path="/sdcard/DLP/"
temp=$(mktemp)
mkdir -p "${download_path}"

# Cleanup
function cleanup() {
    rm -f "$temp"
    echo -e "${NC}"
}
trap cleanup EXIT

#banner
function banner() {
    colors=('\033[1;31m' '\033[1;33m' '\033[1;34m' '\033[1;35m' '\033[1;32m')
    num_color=${#colors[@]}
    random=$((RANDOM % num_color))
    color=${colors[$random]}
    echo ""
    echo -e "${color} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⡀"
    echo -e "${color}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿"
    echo -e "${color} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡏⠉⠉⣿⣿"
    echo -e "${color}⠀⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⣿⣿⡇⠀⠀⣿⣿"
    echo -e "${color}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡇⠀⠀⣿⣿"
    echo -e "${color}⠀⠀⠀⠀⠀⠀⠀⠀⣠⣤⣤⣤⣿⣿⡇⠀ ⣿⣿⣤⣤⣤⣄"
    echo -e "${color} ⠀⠀⠀⠀⠀⠀ ⢿⣿⣿⣿⠿⠿⠇⠀ ⠿⠿⣿⣿⣿⡿"
    echo -e "${color} ⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣦⡀    ⣴⣿⡿⠋"
    echo -e "${color}⠀⠀⠀⠀⠀    ⠀ ⠻⣿⣿⣦⣀⣴⣿⣿⠟ ${CYAN}QuickDL"
    echo -e "${color}⠀⠀⠀⠀⠀⠀⠀      ⠻⣿⣿⣿⠟⠁ ${CYAN}By RUR999"
    echo -e "${color}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ⠀⠀ ⠉"
    echo -e "${NC}"
}

#loding animation
function loading() {
    local pid=$1
    local bar_len=5
    local i=0
    local dot=""
    local msg=("${@:2}")
    printf "\n"
    printf "${GREEN}${msg[@]}${NC}"
    while kill -0 ${pid} 2>/dev/null; do
        if [[ $i -lt ${bar_len} ]]; then
            dot+="."
            i=$((i + 1))
        else
            dot=""
            i=0
        fi
        printf "\r${GREEN}${msg[@]}${CYAN}%-5s" "${dot}"
        sleep 0.1
    done
    printf "\r${GREEN}${msg[@]}${CYAN} ...   \n"
    printf "${NC}"
}

#full display line
function line() {
    columns=$(stty size | awk '{print $2}')
    if [ -z "$columns" ] || [ "$columns" -eq 0 ]; then
         columns=50
    fi
    printf -- '%.s-' $(seq 1 $columns)
}


# check storage
function check_storage() {
    while true; do
        clear;banner
        if [ ! -d "$HOME/storage/shared" ]; then
           echo -e "\n${RED}Storage permission required...${NC}"
           termux-setup-storage
           echo -en "${GREEN}Press enter after allowed permission.${NC}"
           read -s -n 1 ENTER
           echo ""
           continue
        else
           break
        fi
    done
}
# Check pkgs
function check_pkgs() {
    clear;banner
    if ! command -v yt-dlp &> /dev/null; then
        pkg install -y yt-dlp &> /dev/null &
        loading $! "Installing yt-dlp"
        wait $!
        if ! command -v yt-dlp &> /dev/null; then
            echo -e "\n${RED}Error: yt-dlp failed. Installing differently.${NC}"
            (pkg install -y python; pip install -U yt-dlp) &> /dev/null &
            loading $! "Installing yt-dlp"
            wait $!
            if ! command -v yt-dlp &> /dev/null && ! pip list | grep -q yt-dlp; then
                echo -e "${RED}Error: yt-dlp failed. Try manually.${NC}"
                exit 1
            fi
        fi
    fi

    pkgs=(aria2 jq mpv)
    for pkg in "${pkgs[@]}"; do
        if ! dpkg -s "${pkg}" &>/dev/null; then
           pkg install -y "${pkg}" &> /dev/null &
           loading $! "Installing ${pkg}"
           wait $!
           if ! dpkg -s "${pkg}" &>/dev/null; then
              echo -e "${RED}Error: ${pkg} not installed. Try manually.${NC}"
              exit 1
           fi
        fi
    done
}


# Set threads
function setmt() {
        mt_args=("--downloader" "aria2c" "--downloader-args" "aria2c: -x \"16\" -s \"16\"")
}
    
    
# Find formats
function findf() {
    vformats=$(echo "${searchf}" | jq -r '
    .formats[] | select(.vcodec != "none" and .height != null) |
    {
        code: .format_id,
        ext: .ext,
        quality: .resolution,
        size: .filesize | tostring
    } |
    "\(.quality)\t\(.code)\t\(.ext)\t\(.quality)p\t\(.size)"
' | sort -rn)

    aformats=$(echo "${searchf}" | jq -r '
        .formats[] | select(.vcodec == "none" and .acodec != "none") |
        {
            code: .format_id,
            ext: .ext,
            bitrate: .abr,
            size: .filesize | tostring
        } |
        "\(.bitrate)\t\(.code)\t\(.ext)\t\(.bitrate)k\t\(.size)"
    ' | sort -rn)

    a_list=$(echo -e "$aformats" | awk -v g="$GREEN" -v b="$BLUE" -v c="$CYAN" -v n="$NC" '
    function byte(bytes) {
    if (bytes == "null" || bytes == "0" || bytes == "") {
        return "Unknown";
    }
    split("B K M G T", scales, " ");
    i = 1;
    while (bytes >= 1024 && i < 5) {
        bytes /= 1024;
        i++;
    }
    return sprintf("%.2f%s", bytes, scales[i]);
}

    {
        size_byte = byte($5);
        printf "%s%-3s%s | %s%-5s%s | %s%-10s%s | %s%s%s\n", g, NR, n, b, $3, n, c, $4, n, b, size_byte, n;
    }
')
    num_audio_formats=$(echo -e "$aformats" | wc -l | tr -d '[:space:]')
    v_list=$(echo -e "$vformats" | awk -v g="$GREEN" -v b="$BLUE" -v c="$CYAN" -v n="$NC" -v start_num=$((num_audio_formats + 1)) '
    function byte(bytes) {
    if (bytes == "null" || bytes == 0 || bytes == "") {
        return "Unknown";
    }
    split("B K M G T", scales, " ");
    i = 1;
    while (bytes >= 1024 && i < 5) {
        bytes /= 1024;
        i++;
    }
    return sprintf("%.2f%s", bytes, scales[i]);
}

    {
        size_byte = byte($5);
        printf "%s%-3s%s | %s%-5s%s | %s%-10s%s | %s%s%s\n", g, NR + start_num - 1, n, b, $3, n, c, $4, n, b, size_byte, n;
    }
')
    IFS=$'\n' read -r -d '' -a vcodes <<< "$(echo -e "${vformats}" | awk '{print $2}')"
    IFS=$'\n' read -r -d '' -a acodes <<< "$(echo -e "${aformats}" | awk '{print $2}')"
}


# Download
function download() {
    local dlink="$1"
    local path="$2"
    local type="$3"
    shift 3
    local download_args=("$@")
    clear;banner
    echo -e "${GREEN}Downloading ${type}...${NC}"
    yt-dlp "${mt_args[@]}" --progress "${download_args[@]}" -o "${path}" "${dlink}" 2>"${temp}"
    local status=$?

    if [ ${status} -eq 0 ] && ! grep -q "ERROR:" "${temp}"; then
        echo -e "${GREEN}Download successful! Saved in ${download_path}${NC}"
    elif grep -q "Got an error" "${temp}" || grep -q "Incomplete download" "${temp}" || grep -q "timed out" "${temp}"; then
        echo -e "\n\n${RED}Network error. ${GREEN}Attempting resume...${NC}"
        > "${temp}"
        yt-dlp "${mt_args[@]}" -c --progress "${download_args[@]}" -o "${path}" "${dlink}" 2>"${temp}"
        local resume_status=$?

        if [ ${resume_status} -eq 0 ] && ! grep -q "ERROR:" "${temp}"; then
            echo -e "${GREEN}Download resumed and completed! Saved in ${download_path}${NC}"
        else
            echo -e "\n\n${RED}Failed to resume. Try again later.${NC}"
            if [ -s "${temp}" ]; then
                echo -e "\n\n${RED}Error details:\n$(cat "${temp}")${NC}"
            fi
            rm -f ${temp}
        fi
    elif [ "${type}" == "video" ] && grep -q "Requested format is not available" "${temp}"; then
        echo -e "${RED}Format unavailable.${GREEN} Trying another way...${NC}"
        > "${temp}"
        download_args=("-f" "${format_code}")
        yt-dlp "${mt_args[@]}" --progress "${download_args[@]}" -o "${path}" "${dlink}" 2>"${temp}"
        local f_status=$?

        if [ ${f_status} -eq 0 ] && ! grep -q "ERROR:" "${temp}"; then
            echo -e "${GREEN}Alternative format downloaded! Saved in ${download_path}${NC}"
        else
            echo -e "\n\n${RED}Failed to download with alternative format.${NC}"
            if [ -s "${temp}" ]; then
                echo -e "\n\n${RED}Error details:\n$(cat "${temp}")${NC}"
            fi
            rm -f ${temp}
        fi
    elif grep -q "aria2c exited with code 28" "${temp}";then
        echo -e "\n\n${RED}Error for multi threaded. ${GREEN}Try with Multi threaded 4...${NC}"
        > "${temp}"
        setmt "4"
        yt-dlp "${mt_args[@]}" --progress "${download_args[@]}" -o "${path}" "${dlink}" 2>"${temp}"
        local mt_status=$?
        if [ ${mt_status} -eq 0 ] && ! grep -q "ERROR:" "${temp}"; then
            echo -e "${GREEN}Download completed with multi threaded 4. Saved in ${download_path}${NC}"
        elif grep -q "aria2c exited with code 28" "${temp}";then
            echo -e "\n\n${RED}Error for multi threaded. ${GREEN}Try without Multi threaded...${NC}"
            > "${temp}"
            yt-dlp --progress "${download_args[@]}" -o "${path}" "${dlink}" 2>"${temp}"
            local mt2_status=$?
            if [ ${mt2_status} -eq 0 ] && ! grep -q "ERROR:" "${temp}"; then
                echo -e "${GREEN}Download completed without multi threaded Saved in ${download_path}${NC}"
            else
                echo -e "\n\n${RED}Failed to download without Multi threaded...${NC}"
            fi
            if [ -s "${temp}" ]; then
                echo -e "\n\n${RED}Error details:\n$(cat "${temp}")${NC}"
            fi
            rm -f ${temp}
        fi
    elif grep -q "aria2c exited with code 16" "${temp}";then
        echo -e "\n\n${RED}Error for file name too long. ${GREEN}Try with file name is ${RANDOM_NUMBER}...${NC}"
        RANDOM_NUMBER=$(shuf -i 100000000000000-999990000099999 -n 1)
        > "${temp}"
        yt-dlp "${mt_args[@]}" --progress "${download_args[@]}" -o "${download_path}${RANDOM_NUMBER}.%(ext)s" "${dlink}" 2>"${temp}"
        local fn_status=$?
        if [ ${fn_status} -eq 0 ] && ! grep -q "ERROR:" "${temp}"; then
            echo -e "${GREEN}Download completed with file name ${RANDOM_NUMBER}. Saved in ${download_path}${NC}"
        else
            echo -e "\n\n${RED}Failed to download with file name ${RANDOM_NUMBER}...${NC}"
        fi
        if [ -s "${temp}" ]; then
            echo -e "\n\n${RED}Error details:\n$(cat "${temp}")${NC}"
        fi
        rm -f ${temp}
    else
        echo -e "\n\n${RED}Download failed!${NC}"
        if [ -s "${temp}" ]; then
            echo -e "\n\n${RED}Error details:\n$(cat "${temp}")${NC}"
        fi
    fi
    rm -f ${temp}
}


# Play music
function play_music() {
    local link="$1"
    while true; do
        clear;banner
        echo -e "${GREEN}Playing music${CYAN}...${NC}"
        mpv --no-video "${link}"
        echo -en "\n* ${CYAN}Play again? (y/n): ${NC}"
        read -r -n 1 pagain
        echo ""
        if [[ ! "${pagain}" =~ ^[Yy]$ ]]; then
            break
        fi
    done
}


# List formats
function flist() {
    local dlink="$1"
    while true; do
        clear;banner
        echo -e "\n${CYAN}     *Audio Formats*${NC}\n"
        echo -e "${BLUE}No. ${NC}| ${BLUE}Ext   ${NC}| ${BLUE}Bitrate    ${NC}| ${BLUE}Size${NC}"
        line
        echo -e "${a_list}"
        line
        echo -e "\n\n${CYAN}     *Video Formats*${NC}\n"
        echo -e "${BLUE}No. ${NC}| ${BLUE}Ext   ${NC}| ${BLUE}Resolution ${NC}| ${BLUE}Size${NC}"
        line
        echo -e "${v_list}"
        line
        echo -e "${GREEN}Enter 'h' for highest quality.${NC}"
        echo -e "${GREEN}Enter 'p' to play music.${NC}"
        echo -e "${GREEN}Enter a number for quality.${NC}"
        line
        echo -en "\n\n* ${CYAN}Enter Choice: ${NC}"
        read -r choice
        case ${choice} in
            [Pp]lay|[Pp])
                play_music "${dlink}"
                break
                ;;
            h)
                setmt
                download_args=("-f" "bestvideo+bestaudio")
                download "${dlink}" "${download_path}/%(title)s.%(ext)s" "video" "${download_args[@]}"
                break
                ;;
            *)
                if [[ "${choice}" =~ ^[0-9]+$ ]]; then
                    if [ "${choice}" -ge 1 ] && [ "${choice}" -le "${num_audio_formats}" ]; then
                        local index=$((choice-1))
                        local format_code="${acodes[${index}]}"
                        setmt
                        download_args=("-f" "${format_code}")
                        download "${dlink}" "${download_path}/%(title)s.%(ext)s" "audio" "${download_args[@]}"
                        break
                    elif [ "${choice}" -gt "${num_audio_formats}" ] && [ "${choice}" -le "$((num_audio_formats + ${#vcodes[@]}))" ]; then
                        local index=$((choice - num_audio_formats - 1))
                        local format_code="${vcodes[${index}]}"
                        setmt
                        download_args=("-f" "${format_code}+bestaudio")
                        download "${dlink}" "${download_path}/%(title)s.%(ext)s" "video" "${download_args[@]}"
                        break
                    else
                        echo -e "${RED}Invalid number. Enter a valid number.${NC}"
                        sleep 2
                    fi
                else
                    echo -e "${RED}Invalid input. Try again.${NC}"
                    sleep 2
                fi
                ;;
        esac
    done
}

# Handle playlists
function playlist() {
    readarray -t titles < <(echo "${searchpl}" | jq -r '.title')
    readarray -t ids < <(echo "${searchpl}" | jq -r '.id')
    local ptitle=$(echo "${searchpl}" | jq -r '.playlist' | head -n 1)
    local totalv=$(echo "${searchpl}" | wc -l)
    clear;banner
    echo -e "   ${CYAN}*Select option*${NC}\n"
    echo -e "${GREEN}Playlist: ${BLUE}${ptitle}${NC}"
    echo -e "${GREEN}Total videos: ${BLUE}${totalv}${NC}\n"
    line
    echo -e "${GREEN}1. ${CYAN}Download all videos from playlist${NC}"
    echo -e "${GREEN}2. ${CYAN}Download select videos from playlist${NC}"
    line
    echo -en "* ${CYAN}Enter (1 or 2): ${NC}"
    read -r -n 1 choice
    echo ""
    local numbers=""
    local path="${download_path}/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"
    case ${choice} in
    1)
        clear;banner
        pflist
        setmt
        echo -e "${GREEN}Downloading all videos...${NC}"
        download "${dlink}" "${path}" "${type}" "${download_args[@]}"
        ;;
    2)
        clear;banner
        echo -e "${CYAN}Available videos...${NC}"
        for i in "${!titles[@]}"; do
            echo -e "${GREEN}$((i+1)).${BLUE} ${titles[${i}]}${NC}"
            line
        done
        echo -en "* ${CYAN}Select videos (ex: 1,3,5): ${NC}"
        read numbers
        IFS=',' read -ra selected <<< "${numbers}"
        pflist
        setmt
        for num in "${selected[@]}"; do
            local select=$((num - 1))
            if [ "${select}" -ge 0 ] && [ "${select}" -lt "${#ids[@]}" ]; then
                local dlink="https://www.youtube.com/watch?v=${ids[${select}]}"
                echo -e "\n${GREEN}Downloading: ${titles[${select}]}${NC}"
                download "${dlink}" "${path}" "${type}" "${download_args[@]}"
            else
                echo -e "${RED}Warning: Invalid number: ${num}. Skipping.${NC}"
            fi
        done
        ;;
    *)
        echo -e "${RED}Invalid choice.${NC}"
        return
        ;;
    esac
}

# playlist format
function pflist() {
    while true; do
        clear;banner
        echo -e "${GREEN}Playlist: ${BLUE}${ptitle}${NC}"
        echo -e "\n${CYAN}   *Choose a format for all videos*${NC}\n"
        echo -e "${BLUE}No.${NC}| ${BLUE}Quality ${NC}"
        line
        echo -e "${GREEN}1. ${NC}|${CYAN} Highest Quality${NC}"
        echo -e "${GREEN}2. ${NC}|${CYAN} 1080p${NC}"
        echo -e "${GREEN}3. ${NC}|${CYAN} 720p${NC}"
        echo -e "${GREEN}4. ${NC}|${CYAN} 480p${NC}"
        echo -e "${GREEN}5. ${NC}|${CYAN} 360p${NC}"
        echo -e "${GREEN}6. ${NC}|${CYAN} Audio${NC}"
        line
        echo -e "${GREEN}Type '${CYAN}p${GREEN}' to play music.${NC}"
        echo -e "${GREEN}Type '${CYAN}a${GREEN}' number for quality.\n${NC}"
        line
        echo -en "* ${CYAN}Enter Choice: ${NC}"
        read -r -n 1 format
        echo ""
        
        local format_code
        type="video"
        case "${format}" in
            [Pp]lay|[Pp])
                play_music "${dlink}"
                break
                ;;
            1|01)
                download_args=("-f" "bestvideo[height=4320]+bestaudio")
                break
                ;;
            2|02)
                download_args=("-f" "bestvideo[height=1080]+bestaudio")
                break
                ;;
            3|03)
                download_args=("-f" "bestvideo[height=720]+bestaudio")
                break
                ;;
            4|04)
                download_args=("-f" "bestvideo[height=480]+bestaudio")
                break
                ;;
            5|05)
                download_args=("-f" "bestvideo[height=360]+bestaudio")
                break
                ;;
            6|06)
                type="audio"
                download_args=("-f" "bestaudio")
                break
                ;;
            *)
                echo -e "${RED}Wrong input. Try again.${NC}"
                ;;
        esac
    done
}




# Main loop
function main_loop() {
    while true; do
        while true; do
            clear;banner
            if [ "$#" -gt 0 ]; then
                dinput="$@"
            else
                echo -en "${CYAN}ENTER DOWNLOAD LINK OR SEARCH QUERY: ${NC}"
                read -r dinput
            fi

            if [ -z "${dinput}" ]; then
                echo -e "${RED}No input. Enter a download link or search anything.${NC}"
                sleep 2
                set --
                continue

            elif [[ "${dinput}" =~ ^https?:// ]]; then
                dlink="${dinput}"
                if [[ "${dlink}" =~ playlist ]]; then
                    clear;banner
                    echo -e "\n${GREEN}Link is a playlist${NC}"
                    echo -e "${GREEN}Playlist link '${dlink}'${NC}"
                    >${temp}
                    yt-dlp --dump-json --flat-playlist "${dlink}" >${temp} 2> /dev/null &
                    loading $! "Fetching videos"
                    wait $!
                    status=$?
                    searchpl=$(cat ${temp})
                    rm -f ${temp}
                    if [ ${status} -ne 0 ] || [ -z "${searchpl}" ]; then
                        echo -e "${RED}No videos found.${NC}"
                        sleep 2
                        set --
                        continue
                    fi
                    playlist
                else
                   clear;banner
                   echo -e "${GREEN}Link '${dlink}'${NC}"
                   >${temp}
                   yt-dlp --dump-json "${dlink}" >${temp} 2> /dev/null &
                   loading $! "Finding formats"
                   wait $!
                   status=$?
                   searchf=$(cat ${temp})
                   rm -f ${temp}
                       if [ $status -ne 0 ] || [ -z "${searchf}" ]; then
                        echo -e "${RED}No formats found. Try again.${NC}"
                        sleep 2
                        set --
                        continue
                    fi
                    findf
                    flist "${dlink}"
                fi
                break
            else
               clear;banner
                >${temp}
                yt-dlp --dump-json --ignore-errors "ytsearch3:${dinput}" >${temp} 2> /dev/null &
                loading $! "Searching in youtube"
                wait $!
                searchyt=$(cat ${temp})
                rm -f ${temp}

                if [ -z "${searchyt}" ]; then
                    echo -e "${RED}No videos found. Try again.${NC}"
                    sleep 2
                    set --
                    continue
                fi
                IFS='!' read -r -a title <<< "$(echo "${searchyt}" | jq -r '.title' | tr '\n' '!')"
                IFS='!' read -r -a id <<< "$(echo "${searchyt}" | jq -r '.id' | tr '\n' '!')"

                while true; do
                    clear;banner
                    echo -e "${GREEN}Query '${dinput}'${NC}"
                    echo -e "\n   *${CYAN}Top 3 videos${NC}*"
                    line
                    for i in "${!title[@]}"; do
                        echo -e "${GREEN}$((i+1)).${BLUE} ${title[${i}]}${NC}"
                        line
                    done
                    echo -en "* ${CYAN}Choose a video: ${NC}"
                    read -r -n 1 choice
                    echo ""

                    if [[ "${choice}" =~ ^[1-3]$ ]]; then
                        dlink="https://www.youtube.com/watch?v=${id[${choice}-1]}"
                        clear;banner
                        echo -e "${GREEN}Link '${dlink}'${NC}"
                        >${temp}
                        yt-dlp --dump-json "${dlink}" >${temp} 2> /dev/null &
                        loading $! "Finding formats"
                        wait $!
                        searchf=$(cat ${temp})
                        rm -f ${temp}
                       if [ $? -ne 0 ] || [ -z "${searchf}" ]; then
                        echo -e "${RED}No formats found. Try again.${NC}"
                        sleep 2
                        set --
                        continue
                       fi
                        findf
                        flist "${dlink}"
                        break
                    else
                        echo -e "${RED}Invalid choice. Enter 1-3.${NC}"
                        sleep 2
                        continue
                    fi
                done
                break
            fi
        done
        echo -en "\n* ${CYAN}Download another? (y/n): ${NC}"
        read -r -n 1 continue_choice
        echo ""
        if [[ ! "${continue_choice}" =~ ^[Yy]$ ]]; then
            break
        fi
    done
}

# Run
check_storage
check_pkgs
main_loop $@
