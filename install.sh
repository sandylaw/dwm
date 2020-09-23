#!/usr/bin/bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-09-20
# shellcheck disable=SC1091
source '/etc/os-release'
ID=$(echo "${ID}" | tr '[:upper:]' '[:lower:]')
VERSION=$(echo "${VERSION}" | awk -F "[()]" '{print $2}')
check_system() {
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]]; then
        echo -e "当前系统为 Centos ${VERSION_ID} ${VERSION}"
        echo "Next time!"
        exit 1
        sudo yum update
        INS="yum install"
    elif [[ "${ID}" == "debian" ]] || [[ "${ID}" == "ubuntu" ]] || [[ "${ID}" == "deepin" ]] || [[ "${ID}" == "uos" ]]; then
        echo -e "当前系统为 Debian系"
        sudo apt update
        INS="apt install"
        sudo $INS libx11-dev libxrandr-dev libxft-dev libxinerama-dev libjpeg-dev firefox-esr -y
    elif [[ "${ID}" == "archlinux"  ]] || [[ "${ID}" == "manjaro"  ]] || [[ "${ID}" == "endeavouros"  ]]; then
        echo -e "当前系统为 $ID"
        sudo pacman -Sy
        INS="pacman -S --noconfirm"
        sudo $INS --noconfirm base-devel firefox
    else
        echo -e "当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断"
        exit 1
    fi
}

function install_dwm() {
    rm -rf st dmenu dwm slstatus farbfeld sent slock || true
    yes | sudo $INS recordmydesktop git feh compton xautolock scrot pcmanfm || exit
    if ! [ -f dwm.diff ]; then
        wget -N --no-check-certificate -q -O dwm.diff "https://raw.githubusercontent.com/sandylaw/dwm/master/dwm.diff"
    fi
    if ! [ -f st.diff ]; then
        wget -N --no-check-certificate -q -O st.diff "https://raw.githubusercontent.com/sandylaw/dwm/master/st.diff"
    fi
    if ! [ -f bg.jpg ]; then
        wget -N --no-check-certificate -q -O bg.jpg "https://raw.githubusercontent.com/sandylaw/dwm/master/bg.jpg"
    fi
    if ! [ -f dwm.tar.gz ]; then
        wget -N --no-check-certificate -q -O dwm.tar.gz "https://raw.githubusercontent.com/sandylaw/dwm/master/dwm.tar.gz"
    fi
    TUSER="$USER"
    wget -O - https://dl.suckless.org/st/st-0.8.4.tar.gz | tar -xz
    mv st-0.8.4 st
    cd st || exit
    cp ../st.diff .
    patch -p1 < st.diff
    cd ..
    #git clone https://git.suckless.org/dwm/
    tar -xz dwm.tar.gz || exit
    cp dwm.diff dwm/
    cd dwm || exit
    sed -ri "s/_USERNAME/$TUSER/g" dwm.diff
    patch -p1 < dwm.diff
    cd ..
    git clone https://git.suckless.org/dmenu/
    git clone https://git.suckless.org/slock
    wget -O - https://dl.suckless.org/farbfeld/farbfeld-4.tar.gz | tar -xz
    mv farbfeld* farbfeld
    git clone git://git.suckless.org/slstatus
    mkdir -p sent/
    pushd sent/ > /dev/null || exit
    wget -O - https://dl.suckless.org/tools/sent-1.tar.gz | tar -xz
    popd > /dev/null || exit
    mkdir -p /home/"$TUSER"/screenshots 2>/dev/null
    tree -d .
    DWM=(st dmenu dwm slstatus farbfeld sent slock)
    for x in ${DWM[*]}; do
        pushd "$x" > /dev/null || exit
        rm config.h
        sudo make clean install
        popd > /dev/null || exit
    done

    cat << EOF | sudo tee /usr/share/xsessions/dwm.desktop
[Desktop Entry]
Name=dwm
Exec=/home/$TUSER/.dwm-init
EOF
    if [ -f bg.jpg ]; then
        cp bg.jpg /home/"$TUSER"/Pictures/bg.jpg
        feh --bg-fill /home/"$TUSER"/Pictures/bg.jpg
    else
        echo "bg.jpg is not exist."
        exit 1
    fi
    cat << EOF | tee /home/"$TUSER"/.dwm-init
xset r rate 300 50
xset -dpms
xset s off
slstatus &
setxkbmap -option grp:switch us,dk
#synclient TapButton2=
#xfce4-volumed
nm-applet &
#dwmstatusda > ~/dwmstatusda.txt &
xautolock -time 10 -locker slock &
#mailchecker &
/home/$TUSER/.fehbg &
compton focus-exclude = "x = 0 && y = 0 && override_redirect = true" &
while true; do
    # Log stderror to a file 
    dwm 2> ~/.dwm.log
    # No error logging
    #dwm >/dev/null 2>&1

done
EOF
    chmod +x /home/"$TUSER"/.dwm-init
}
check_system
install_dwm
