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
		echo "This script will only work on debian Stretch images at this time."
		echo "No other version of debian is supported at this time. "
		echo "**** EXITING ****"
		exit -1
	fi
fi

if [[ ! -f  /tmp/stage0 ]] ; then
	#
	#Update tzdata timezone
	#
	dpkg-reconfigure tzdata

	touch /tmp/stage0
fi

#board & branch selection
if [[ -f /tmp/stage0 ]] && [[ ! -f /tmp/stage1 ]] ; then
    #update repo
	apt-get update > /dev/null

	#
	# Request user input to ask for device type	
	#
	echo ""
	heading="What Nanopi-Neo Board?"
	title="Please choose the Nanopi-Neo Board you are building on:"
	prompt="Pick a Nanopi-Neo Board:"
	options=( "Nanopi_Duo" "Nanopi_Neo_32bit" "NanoPi_Neo2_64bit" "NanoPi_Neo+2_64bit" )
	echo "$heading"
	echo "$title"
	PS3="$prompt"
	select opt1 in "${options[@]}" "Quit"; do
        case "$REPLY" in
        # Nanopi-Duo 32bit
        1 ) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="duo"; break;;
        # Nanopi-Neo 32bit
        2 ) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="neo"; break;;
        # Nanopi-Neo2 64bit
        3 ) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="neo2"; break;;
        # Nanopi-Neo2+ 64bit
        4 ) echo ""; echo "Building for $opt1"; device_long_name="$opt1"; device_short_name="neo+2"; break;;
        $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit;;
        # invalid choice
        *) echo "Invalid option. Try another one.";continue;;
        esac
	done
	echo ""

	#
	# Request user input to ask for type of svxlink install
	#
	echo ""
	heading="What branch of svxlink install: Stable=1.5.99 Release=1.5.99.x Testing=Head ?"
	title="Please choose svxlink branch:"
	prompt="Pick a Svxlink install type Stable=1.5.99 Release=1.5.99.x Testing=Head : "
	options=("stable" "release" "testing")
	echo "$heading"
	echo "$title"
	PS3="$prompt"
	select opt1 in "${options[@]}" "Quit"; do
    case "$REPLY" in
        # Stable
        1 ) echo ""; echo "Building for $opt1"; svx_long_name="$opt1"; svx_short_name="svxs"; break;;
        # Release
        2 ) echo ""; echo "Building for $opt1"; svx_long_name="$opt1"; svx_short_name="svxr"; break;;
        # Testing
        3 ) echo ""; echo "Building for $opt1"; svx_long_name="$opt1"; svx_short_name="svxt"; break;;
        $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit;;
        *) echo "Invalid option. Try another one.";continue;;
        esac
	done
	echo ""

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

	if [[ $svx_short_name == "svxs" ]] ; then
		echo "--------------------------------------------------------------"
		echo " Adding SvxLink Stable Repository                             "
		echo "--------------------------------------------------------------"
		cat > /etc/apt/sources.list.d/svxlink.list << DELIM
deb http://otg-repeater.ddns.net/svxlink/Stable/debian/ stretch main
DELIM
	fi

	if [[ $svx_short_name == "svxr" ]] ; then
		echo "--------------------------------------------------------------"
		echo " Adding SvxLink Release Repository                            "
		echo "--------------------------------------------------------------"
		cat > /etc/apt/sources.list.d/svxlink.list << DELIM
deb http://otg-repeater.ddns.net/svxlink/Release/debian/ stretch main
DELIM
	fi

	if [[ $svx_short_name == "svxt" ]] ; then
		echo "--------------------------------------------------------------"
		echo " Adding SvxLink Testing Repository                            "
		echo "--------------------------------------------------------------"
		cat > /etc/apt/sources.list.d/svxlink.list << DELIM
deb http://otg-repeater.ddns.net/svxlink/Testing/debian/ stretch main
DELIM
        fi

	#add key
	curl http://otg-repeater.ddns.net/otg-repeater.ddns.net.gpg.key | apt-key add -

	echo "--------------------------------------------------------------"
	echo "Performing Base os Update...                                  "
	echo "--------------------------------------------------------------"
	apt-get update > /dev/null
	for i in upgrade clean ;do apt-get "${i}" -y --force-yes --fix-missing ; done

	touch /tmp/stage1
fi

#Deps/svxlink install & enable
if [[ -f /tmp/stage1 ]] && [[ ! -f /tmp/stage2 ]] ; then
	echo "--------------------------------------------------------------"
	echo " Installing Svxlink Dependencies...                           "
	echo "--------------------------------------------------------------"
	#svxlink deps
		apt-get install -y --fix-missing libopus0 alsa-utils vorbis-tools sox libsox-fmt-mp3 librtlsdr0 ntp libasound2 \
			libasound2-plugin-equal libspeex1 libgcrypt20 libpopt0 libgsm1 tcl8.6 tk8.6 bzip2 flite i2c-tools inetutils-syslogd \
			screen uuid usbutils whiptail dialog logrotate cron gawk git-core libsigc++-2.0-0v5 

        #python deps for python interfae
        echo "--------------------------------------------------------------"
        echo " Installing python and extra deps                             "
        echo "--------------------------------------------------------------"
        apt-get install -y --fix-missing python3-dev python3-pip python3-wheel python3-setuptools python3-serial \
			python-libxml2 python-libxslt1 python3-usb libxslt1.1 libxml2 libssl1.1

		pip install spidev
		
        #Cleanup
        apt-get clean

        # Install svxlink
        echo "--------------------------------------------------------------"
        echo " Installing svxlink + remotetrx                               "
        echo "--------------------------------------------------------------"
		apt-get -y --force-yes install svxlink-server libasynccpp1.4 libecholib1.3

        apt-get clean

        echo "--------------------------------------------------------------"
        echo " Installing svxlink sounds                                    "
        echo "--------------------------------------------------------------"
        git clone https://github.com/RichNeese/en_US-laura-16k-V2.git
        cp -rp en_US-laura-16k-V2/* /usr/share/svxlink/sounds/
        rm -rf en_US-laura-16k-V2
		
		
		#add custom logic dir
		mkdir /etc/svxlink/local-events.d
		ln -s /etc/svxlink/local-events.d /usr/share/svxlink/events.d/local

        #Svxlink Services
        #enable svxlink
        echo "--------------------------------------------------------------"
        echo " Enabling svxlink Service                                     "
        echo "--------------------------------------------------------------"
        systemctl enable svxlink

        touch /tmp/stage2
fi

#sound configuration
if [[ -f /tmp/stage2 ]] && [[ ! -f /tmp/stage3 ]] ; then

        echo "--------------------------------------------------------------"
        echo " Add svxlink user to groups: gpio, audio, and daemon          "
        echo "--------------------------------------------------------------"
        usermod -a -G daemon,audio svxlink

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
DELIM

	if [[ $device_short_name == "duo" ]] || [[ $device_short_name == "neo" ]] ; then
		echo "--------------------------------------------------------------"
		echo " Configuring /boot/armbianEnv.txt                             "
		echo "--------------------------------------------------------------"
		cat >>/boot/armbianEnv.txt << DELIM
overlays=analog-codec i2c0 i2c1 spi-spidev uart1 w1-gpio
DELIM
	fi

	if [[ $device_short_name == "neo2" ]] || [[ $device_short_name == "neo+2" ]] ; then
		echo "--------------------------------------------------------------"
		echo " Configuring /boot/armbianEnv.txt                             "
		echo "--------------------------------------------------------------"
		cat >>/boot/armbianEnv.txt << DELIM
overlays=analog-codec i2c0 i2c1 spi-spidev uart1 w1-gpio
DELIM
	fi

	echo "--------------------------------------------------------------"
	echo " Enable the spi & i2c /etc/modules                            "
	echo "--------------------------------------------------------------"
	{ echo "i2c-dev"; echo "w1-gpio"; echo "w1-therm"; echo "spidev"; } >> /etc/modules

	touch /tmp/stage3
fi

echo " ########################################################################################## "
echo " #             The SVXLink Repeater / Echolink server Install is now complete             # "
echo " #                          and your system is ready for use..                            # "
echo " ########################################################################################## "

if [[ -f /tmp/stage3 ]] && [[ ! -f clean ]] ; then
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


) | tee install.log
