#!/bin/bash
(
#MIT License

# Copyright (c) [2017] [Richard E Neese]

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

if [[ ! -f  /tmp/stage0 ]] ; then

#
#Update tzdata timezone
#
dpkg-reconfigure tzdata

#
#uptdate Locales
#
apt-get update > /dev/null  && apt-get -y install locales-all
dpkg-reconfigure locales

touch /tmp/stage0
fi

#
# Check to confirm running as root. # First, we need to be root...
#
if (( UID != 0 )) ; then
  sudo -p "$(basename "$0") must be run as root, please enter your sudo password : " "$0" "$@"
  exit 0
fi
echo "--------------------------------------------------------------"
echo "Looks Like you are root.... continuing!"
echo "--------------------------------------------------------------"
echo ""

#
# Request user input to ask for type of svxlink install
#
echo ""
heading="What type of svxlink install: Stable=1.5.99 Teesting is 1.5.99.x  Devel=Head ?"
title="Please choose svxlink install type:"
prompt="Pick a Svxlink install type Stable=1.5.11.99 Teesting is 1.5.99.x  Devel=Head : "
options=("stable" "release" "testing" "devel")
echo "$heading"
echo "$title"
PS3="$prompt "
select opt1 in "${options[@]}" "Quit"; do
    case "$REPLY" in

    # Stable Release
    1 ) echo ""; echo "Building for $opt1"; svx_long_name="$opt1"; svx_short_name="svx-stable"; break;;
	# Release Release
    2 ) echo ""; echo "Building for $opt1"; svx_long_name="$opt1"; svx_short_name="svx-release"; break;;
    # Testing Release
    2 ) echo ""; echo "Building for $opt1"; svx_long_name="$opt1"; svx_short_name="svx-testing"; break;;
    # Devel Release
    3 ) echo ""; echo "Building for $opt1"; svx_long_name="$opt1"; svx_short_name="svx-devel"; break;;
    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit;;

    *) echo "Invalid option. Try another one.";continue;;

    esac
done
echo ""

#
# Request user input to ask for type of svxlink install
#
echo ""
heading="What type of SoundCard ?"
title="Please choose Soundcard type:"
prompt="Pick your sound card:"
options=("usbsnd" "sgtl5000")
echo "$heading"
echo "$title"
PS3="$prompt"
select opt1 in "${options[@]}" "Quit"; do
    case "$REPLY" in
    # Soundcard usb
    1 ) echo ""; echo "Building for $opt1"; snd_long_name="$opt1"; snd_short_name="usb"; break;;

    # Soundcard sgtl5000
    2 ) echo ""; echo "Building for $opt1"; snd_long_name="$opt1"; snd_short_name="sgtl"; break;;
    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit;;
	
    *) echo "Invalid option. Try another one.";continue;;

    esac
done
echo ""

if [[ ! -f  /tmp/stage1 ]] && [[ ! -f  /tmp/stage1 ]] ; then
	#
	# Request user input to set hostname
	#
	echo ""
	heading="System hostname"
	dfhost=$(hostname -s)
	title="What would you like to set your hostname to? Valid characters are a-z, 0-9, and hyphen. Hit ENTER to use the default hostname ($dfhost) for this device OR enter your own and hit ENTER:"

	echo "$heading"
	echo "$title"
	read -r svx_hostname

	if [[ $svx_hostname == "" ]] ; then
 	       svx_hostname="$dfhost"
	fi

	echo ""
	echo "Using $svx_hostname as hostname."
	echo ""

	# debian Systems
	if [[ -f /etc/debian_version ]] ; then
  		os=debian
	else
  		os=unknown
	fi

	# Prepare debian systems for the installation process
	if [[ "$os" = "debian" ]] ; then

	# Jan 17, 2016
	# Detect the version of debian, and do some custom work for different versions
	if (grep -q "9." /etc/debian_version) ; then
  		debian_version=9
	else
  		debian_version=Unsupported
	fi

	if [[ "$debian_version" != "9" ]]; then
	  	echo
		echo "**** ERROR ****"
		echo "This script will only work on debian stretch images at this time."
		echo "No other version of debian is supported at this time. "
		echo "**** EXITING ****"
		exit -1
	fi
fi

#
# Notes / Warnings
#
echo ""
cat << DELIM
                   Not Ment For L.A.M.P Installs

                  L.A.M.P = Linux Apache Mysql PHP

         This Script Is Meant To Be Run On A Fresh Install Of

             debian 8 (Jessie) ArmHF / Arm64 

DELIM

#
# Testing for internet connection. Pulled from and modified
# http://www.linuxscrew.com/2009/04/02/tiny-bash-scripts-check-internet-connection-availability/
#
    echo "--------------------------------------------------------------"
    echo "This Script Currently Requires a internet connection          "
    echo "--------------------------------------------------------------"
    wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null

    if [[ ! -s /tmp/index.google ]] ;then
            echo "No Internet connection. Please check ethernet cable / wifi connection"
            /bin/rm /tmp/index.google
            exit 1
    else
            echo "I Found the Internet ... continuing!!!!!"
            /bin/rm /tmp/index.google
    fi

    echo "--------------------------------------------------------------"
    printf ' Current ip is eth0: '; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
    printf ' Current ip is wlan0: '; ip -f inet addr show dev wlan0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
    echo "--------------------------------------------------------------"
    echo

    echo "--------------------------------------------------------------"
    echo " Set a reboot if Kernel Panic                                 "
    echo "--------------------------------------------------------------"
    cat >> /etc/sysctl.conf << DELIM
kernel.panic = 10
DELIM

    echo "--------------------------------------------------------------"
    echo " Setting Host/Domain name                                     "
    echo "--------------------------------------------------------------"
    cat > /etc/hostname << DELIM
$svx_hostname
DELIM

# Setup /etc/hosts
cat > /etc/hosts << DELIM
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.0.1       $svx_hostname

DELIM
touch /tmp/stage1
fi

if [[ -f /tmp/stage1 ]] && [[ ! -f /tmp/stage2 ]] ; then
#
# all boards
# Setting apt_get to use the httpredirecter to get
# To have <APT> automatically select a mirror close to you, use the Geo-ip redirector in your
# sources.list "deb http://httpredir.debian.org/debian/ jessie main".
# See http://httpredir.debian.org/ for more information.  The redirector uses HTTP 302 redirects
# not dnS to serve content so is safe to use with Google dnS.
# See also <which httpredir.debian.org>.  This service is identical to http.debian.net.
#

   	echo "--------------------------------------------------------------"
   	echo " Adding debian repository...                                  "
    echo "--------------------------------------------------------------"
	cat > /etc/apt/sources.list << DELIM
deb http://httpredir.debian.org/debian/ stretch main contrib non-free
deb http://httpredir.debian.org/debian/ stretch-updates main contrib non-free
deb http://httpredir.debian.org/debian/ stretch-backports main contrib non-free
deb http://security.debian.org/ stretch/updates main contrib non-free
DELIM
		
	#update repo 
	apt-get update > /dev/null
		
        if [[ $svx_short_name == "svx-stable" ]] ; then
                echo "--------------------------------------------------------------"
                echo " Adding SvxLink Stable Repository                             "
                echo "--------------------------------------------------------------"
                cat > /etc/apt/sources.list.d/svxlink.list << DELIM
deb http://otg-repeater.ddns.net/svxlink/stable/debian/ stretch main
DELIM
        fi

        if [[ $svx_short_name == "svx-release" ]] ; then
                echo "--------------------------------------------------------------"
                echo " Adding SvxLink Stable Repository                             "
                echo "--------------------------------------------------------------"
                cat > /etc/apt/sources.list.d/svxlink.list << DELIM
deb http://otg-repeater.ddns.net/svxlink/release/debian/ stretch main
DELIM
        fi		
		
        # SvxLink Testing Repo
        if [[ $svx_short_name == "svx-testing" ]] ; then
                echo "--------------------------------------------------------------"
                echo " Adding SvxLink Testing Repository                            "
                echo "--------------------------------------------------------------"
                cat > /etc/apt/sources.list.d/svxlink.list << DELIM
deb http://otg-repeater.ddns.net/svxlink/testing/debian/ stretch main
DELIM
		fi

#add key	
curl http://otg-repeater.ddns.net/otg-repeater.ddns.net.gpg.key | apt-key add -
		
                echo "--------------------------------------------------------------"
                echo "Performing Base os Update...                                  "
                echo "--------------------------------------------------------------"
        		apt-get update > /dev/null
        		for i in upgrade clean ;do apt-get "${i}" -y --force-yes --fix-missing ; done

touch /tmp/stage2
fi


if [[ -f /tmp/stage2 ]] && [[ ! -f /tmp/stage3 ]] ; then
        echo "--------------------------------------------------------------"
        echo " Installing Svxlink Dependencies...                           "
        echo "--------------------------------------------------------------"
        #svxlink deps
		apt-get install -y --fix-missing libopus0 alsa-base alsa-utils vorbis-tools sox libsox-fmt-mp3 librtlsdr0 ntp libasound2 \
			libasound2-plugin-equal libspeex1 libgcrypt20 libpopt0 libgsm1 tcl8.6 tk8.6 bzip2 flite i2c-tools inetutils-syslogd \
			screen uuid usbutils whiptail dialog logrotate cron gawk git-core libsigc++-2.0-0v5 

        #python deps for python interfae
        echo "--------------------------------------------------------------"
        echo " Installing python and extra deps                             "
        echo "--------------------------------------------------------------"
        apt-get install -y --fix-missing python3-dev python3-pip python3-wheel python3-setuptools python3-spidev pytpython3-serial \
			python-libxml2 python-libxslt1 python3-usb libxslt1.1 libxml2 libssl1.1

		#Cleanup
		apt-get clean

        # Install svxlink
        echo "--------------------------------------------------------------"
        echo " Installing svxlink + remotetrx                               "
        echo "--------------------------------------------------------------"
        apt-get -y --force-yes install svxlink-server 

        apt-get clean

        echo "--------------------------------------------------------------"
        echo " Installing svxlink into the gpio group                        "
        echo "--------------------------------------------------------------"
        #adding user svxlink to gpio user group
        usermod -a -G gpio svxlink

        echo "--------------------------------------------------------------"
        echo " Installing svxlink sounds                                    "
        echo "--------------------------------------------------------------"
		git clone https://github.com/RichNeese/en_US-laura-16k-V2.git
		cp -rp en_US-laura-16k-V2/* /usr/share/svxlink/sounds/
		rm -rf en_US-laura-16k-V2

		#Svxlink Services
		#enable svxlink 
		echo "--------------------------------------------------------------"
        echo " Enabling svxlink Service                                "
        echo "--------------------------------------------------------------"
		systemctl enable svxlink
		
touch /tmp/stage3
fi

if [[ -f /tmp/stage3 ]] && [[ ! -f /tmp/stage4 ]] ; then
    echo "--------------------------------------------------------------"
    echo " Add svxlink user to groups: gpio, audio, and daemon          "
    echo "--------------------------------------------------------------"
    usermod -a -G daemon,gpio,audio svxlink

#Install asound.conf for audio performance
	cat > /etc/asound.conf << DELIM
pcm.dmixed {
    type dmix
    ipc_key 1024
    ipc_key_add_uid 0
    slave.pcm "hw:0,0"
}

pcm.dsnooped {
    type dsnoop
    ipc_key 1025
    slave.pcm "hw:0,0"
}

pcm.duplex {
    type asym
    playback.pcm "dmixed"
    capture.pcm "dsnooped"
}

pcm.left {
    type asym
    playback.pcm "shared_left"
    capture.pcm "dsnooped"
}

pcm.right {
    type asym
    playback.pcm "shared_right"
    capture.pcm "dsnooped"
}

# Instruct ALSA to use pcm.duplex as the default device
pcm.!default {
    type plug
    slave.pcm "duplex"
}

ctl.!default {
    type hw
    card 0
}

# split left channel off
pcm.shared_left {
   type plug
   slave.pcm "hw:0"
   slave.channels 2
   ttable.0.0 1
}

# split right channel off
pcm.shared_right {
   type plug
   slave.pcm "hw:0"
   slave.channels 2
   ttable.1.1 1
}

#dtparam=i2s=on
Pcm_slave.hw_loopback {
   Pcm "hw: loopback, 1.2"
   Channels 2
   Format RAW
   Rate 16000
}

Pcm.plug_loopback {
   Type plug
   Slave hw_loopback
    Ttable {
    0.0 = 1
    0.1 = 1
  }
}

Ctl. Equal  {
   type equal ;
   Controls "/home/pi/.alsaequal.bin"
}

DELIM

	if [[ $snd_short_name == "usb" ]] ; then
	echo "--------------------------------------------------------------"
	echo " Set up usb sound for alsa mixer                              "
	echo "--------------------------------------------------------------"
		if ( ! grep -q snd-usb-audio /etc/modules ); then
			{ echo "snd-aloop"; echo "snd-usb-audio"; } >> "/etc/modules"
			sed -i /boot/config.txt -e "s#dtparam=audio=on#dtparam=audio=off#"
		fi
	fi
	
	if [[ $snd_short_name == "sgtl" ]] ; then	
		echo "--------------------------------------------------------------"
		echo " Enable the fe-pi in /boot/config.txt                  "
		echo "--------------------------------------------------------------"
		{echo "dtoverlay=fe-pi-audio"; echo "dtoverlay=i2s-mmap" } /boot/config.txt
	fi
	
	echo "--------------------------------------------------------------"
	echo " Enable the bcm2708 and bcm2835 /etc/modules                  "
	echo "--------------------------------------------------------------"
	{ echo "i2c-bcm2708"; echo "spi-bcm2835"; } >> /etc/modules

	echo "--------------------------------------------------------------"
	echo " Enable the spi & i2c /etc/modules                            "
	echo "--------------------------------------------------------------"
	{ echo "i2c-dev"; echo "w1-gpio"; echo "w1-therm"; } >> /etc/modules

	echo "--------------------------------------------------------------"
	echo " Configuring /boot/config.txt options 1"
	echo "--------------------------------------------------------------"
	sed -i /boot/config.txt -e "s#\#dtparam=i2c_arm=on#dtparam=i2c_arm=on#"
	sed -i /boot/config.txt -e "s#\#dtparam=spi=on#dtparam=spi=on#"

	echo "--------------------------------------------------------------"
	echo " Disable onboard HDMI sound card not used                     "
	echo "--------------------------------------------------------------"
	#/boot/config.txt
	sed -i /boot/config.txt -e "s#dtparam=audio=on#\#dtparam=audio=on#"

	echo "--------------------------------------------------------------"
	echo " Configuring /boot/config.txt options part 3                  "
	echo "--------------------------------------------------------------"
	# set usb power level
	cat >> /boot/config.txt << DELIM

#usb max current
usb_max_current=1

#enable 1wire onboard temp
dtoverlay=w1-gpio,gpiopin=4

#Enable FE-Pi Overlay
dtoverlay=fe-pi-audio
dtoverlay=i2s-mmap

#Enable mcp23s17 Overlay
dtoverlay=mcp23017,addr=0x20,gpiopin=12

Enable mcp3008 adc overlay
dtoverlay=mcp3008:spi0-0-present,spi0-0-speed=3600000

#use the UART for GPS
enable_uart=1
dtoverlay=pi3-miniuart-bt
#Configure PPS pin for gps
overlay=pps-gpio,gpiopin=16

DELIM

echo "--------------------------------------------------------------"
echo " Installing wiringpi                                          "
echo "--------------------------------------------------------------"
apt-get install -y --force-yes wiringpi

touch /tmp/stage4
fi

if [[ -f /tmp/stage4 ]] && [[ ! -f /tmp/stage5 ]] ; then
	echo "--------------------------------------------------------------"
	echo " Set apt-get run in a tempfs                                  "
	echo "--------------------------------------------------------------"
	cat >> /etc/fstab << DELIM
tmpfs /tmp  tmpfs nodev,nosuid,mode=1777  0 0
tmpfs /var/tmp  tmpfs nodev,nosuid,mode=1777  0 0
DELIM

touch /tmp/stage5
fi

echo " ########################################################################################## "
echo " #             The SVXLink Repeater / Echolink server Install is now complete             # "
echo " #                          and your system is ready for use..                            # "
echo " ########################################################################################## "

if [[ -f /tmp/stage5 ]] && [[ ! -f clean ]] ; then
	echo "--------------------------------------------------------------"
	echo " Cleaning up after install                                    "
	echo "--------------------------------------------------------------"
	apt-get clean
	rm /var/cache/apt/archives/*
	rm /var/cache/apt/archives/partial/*
	touch /tmp/clean
fi

echo " ###########################################################################################"
echo " # reboot required due to kernel update                                                     "
echo " ###########################################################################################"
reboot

) | tee install.log