#!/bin/bash
set -e

pwd_path=$(pwd)

case "$1" in
  all)
        echo "build all"
	echo "****build ndn"
	cd $pwd_path/ndn_workspace
	./build_ndn.sh

	echo "****build baar bsdr openwrt"
	cd $pwd_path/workspace
	./build_clone_openwrt.sh
        ;;
 
  no_clone_openwrt)
        echo "build all but not clone openwrt,just copy baar to openwrt system"
	echo "****build ndn"
	cd $pwd_path/ndn_workspace
	./build_ndn.sh

	echo "****build baar bsdr openwrt"
	cd $pwd_path/workspace
	./build_noclone_openwrt.sh
        ;;

  no_ndn)
        echo "build all but not build ndn"
	echo "****build baar bsdr openwrt"
	cd $pwd_path/workspace
	./build_clone_openwrt.sh
	;;

  no_ndn_openwrt)
        echo "build all but build ndn and not clone openwrt,just copy baar to openwrt system"
	echo "****build baar bsdr openwrt"
	cd $pwd_path/workspace
	./build_noclone_openwrt.sh
        ;;
  deb)
	echo "no build code ,just make deb package"
	;; 
  *)
        echo "Usage: $0 [all|no_clone_openwrt|no_ndn|no_ndn_openwrt|deb]" >&2
        exit 3
        ;;
esac


echo "build deb"
cd $pwd_path
build_version=$(date +%Y%m%d-%H%M%S)
result_path=$(pwd)/result/$(date +%Y%m%d)/$(date +%Y%m%d-%H:%M:%S)
deb_path=$result_path/bndeb

#mkdir -pv result_path

#rm -rfv    $deb_path
mkdir -pv $deb_path/DEBIAN
touch     $deb_path/DEBIAN/control
touch     $deb_path/DEBIAN/postinst
touch     $deb_path/DEBIAN/postrm
touch     $deb_path/DEBIAN/preinst
touch     $deb_path/DEBIAN/prerm
chmod 755 $deb_path/DEBIAN/postinst
chmod 755 $deb_path/DEBIAN/postrm
chmod 755 $deb_path/DEBIAN/preinst
chmod 755 $deb_path/DEBIAN/prerm

mkdir -pv  $deb_path/usr/share/snmp/mibs
mkdir -pv  $deb_path/usr/local
mkdir -pv  $deb_path/usr/local/lib

cp -rf $pwd_path/ndn_workspace/build/ndn_cxx/*          $deb_path/usr/local
cp -rf $pwd_path/ndn_workspace/build/nfd/*              $deb_path/usr/local

cp -rf $pwd_path/workspace/build/Consensus/*            $deb_path/usr/local
mv $deb_path/usr/local/bin/bitcoind                     $deb_path/usr/local/bin/noded   
mv $deb_path/usr/local/bin/bitcoin-cli                  $deb_path/usr/local/bin/noded-cli   
mv $deb_path/usr/local/bin/test_bitcoin                 $deb_path/usr/local/bin/test_noded
mv $deb_path/usr/local/bin/bitcoin-tx                   $deb_path/usr/local/bin/noded-tx

cp -rf $pwd_path/workspace/build/bsdr                   $deb_path/usr/local/bin

cp $pwd_path/workspace/build/SNMP/BNDevice.so           $deb_path/usr/local/lib
cp $pwd_path/workspace/build/SNMP/EARTHLEDGER-MIB.txt   $deb_path/usr/share/snmp/mibs
cp $pwd_path/workspace/build/build_hash.txt             $deb_path/usr/local/

echo "Package: bsdr"                    >> $deb_path/DEBIAN/control
echo "Version: 1.0-$build_version"      >> $deb_path/DEBIAN/control
echo "Section: free"                    >> $deb_path/DEBIAN/control
echo "Prioritt: mysoftware"             >> $deb_path/DEBIAN/control
echo "Architecture: amd64"              >> $deb_path/DEBIAN/control
echo "Maintainer: etherledger"          >> $deb_path/DEBIAN/control
echo "Description: bnos software"       >> $deb_path/DEBIAN/control
sed  's/^/    &/g' $deb_path/usr/local/build_hash.txt>>$deb_path/DEBIAN/control


echo "#!/bin/sh"                                                                   >> $deb_path/DEBIAN/preinst
echo "service snmpd stop"                                                          >> $deb_path/DEBIAN/preinst

echo "#!/bin/sh"                                                                   >> $deb_path/DEBIAN/postinst
echo "ldconfig"                                                                    >> $deb_path/DEBIAN/postinst
echo "ldconfig -v"                                                                 >> $deb_path/DEBIAN/postinst
echo "cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak"                            >> $deb_path/DEBIAN/postinst
echo "echo \"dlmod BNDevice  /usr/local/lib/BNDevice.so\" >> /etc/snmp/snmpd.conf" >> $deb_path/DEBIAN/postinst
echo "sed -i \"s:trapsink:#trapsink:g\" /etc/snmp/snmpd.conf"                      >> $deb_path/DEBIAN/postinst
echo "sed -i \"s:#trap2sink:trap2sink:g\" /etc/snmp/snmpd.conf"                    >> $deb_path/DEBIAN/postinst
echo "rm -f /etc/rc.local"                                                         >> $deb_path/DEBIAN/postinst
echo "touch /etc/rc.local"                                                         >> $deb_path/DEBIAN/postinst
echo "echo \"#!/bin/bash -e\"         >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"nfd-start\"              >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"sleep 4\"                >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"noded-start bsdr\"       >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"sleep 2\"                >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"cd /usr/local/bin/bsdr\" >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"./configndn.sh\"         >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"sleep 2\"                >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"./bsdrsvr &\"            >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"sleep 1\"                >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"exit 0\"                 >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "chmod 777 /etc/rc.local"                                                     >> $deb_path/DEBIAN/postinst
echo "service snmpd start"                                                         >> $deb_path/DEBIAN/postinst
echo "cd /usr/local/bin/bsdr/"                                                     >> $deb_path/DEBIAN/postinst
echo "./bsdrsvr --ccdb"                                                            >> $deb_path/DEBIAN/postinst
echo "./bsdrsvr --ccdata"                                                          >> $deb_path/DEBIAN/postinst
echo "./bsdrsvr --cctx"                                                            >> $deb_path/DEBIAN/postinst

echo "#!/bin/sh"                                                                   >> $deb_path/DEBIAN/prerm
#echo "if [ "$1" = "remove" -o "$1" = "deconfigure" ]; then"                        >> $deb_path/DEBIAN/prerm
echo "  killall noded"                                                             >> $deb_path/DEBIAN/prerm
echo "  killall bsdrsvr"                                                           >> $deb_path/DEBIAN/prerm
echo "  killall nfd"                                                               >> $deb_path/DEBIAN/prerm
echo "  service snmpd stop"                                                        >> $deb_path/DEBIAN/prerm
echo "  rm -f /etc/rc.local"                                                       >> $deb_path/DEBIAN/prerm
echo "  touch /etc/rc.local"                                                       >> $deb_path/DEBIAN/prerm
echo "  cp /etc/snmp/snmpd.conf.bak /etc/snmp/snmpd.conf"                          >> $deb_path/DEBIAN/prerm
#echo "fi"                                                                          >> $deb_path/DEBIAN/prerm


echo "#!/bin/sh"                                                                   >> $deb_path/DEBIAN/postrm
#echo "if [ "$1" = "purge" ] ; then"                                                >> $deb_path/DEBIAN/postrm
echo "  service snmpd start"                                                       >> $deb_path/DEBIAN/postrm
echo "  ldconfig"                                                                  >> $deb_path/DEBIAN/postrm
#echo "fi"                                                                          >> $deb_path/DEBIAN/postrm

#rm -rfv bsdr.deb
dpkg -b $deb_path $result_path/bsdr.deb


rm -fv    $deb_path/DEBIAN/control
rm -fv    $deb_path/DEBIAN/postinst
rm -fv    $deb_path/DEBIAN/prerm
touch     $deb_path/DEBIAN/control
touch     $deb_path/DEBIAN/postinst
touch     $deb_path/DEBIAN/prerm
chmod 755 $deb_path/DEBIAN/postinst
chmod 755 $deb_path/DEBIAN/prerm

echo "Package: bcr"                     >> $deb_path/DEBIAN/control
echo "Version: 1.0-$build_version"      >> $deb_path/DEBIAN/control
echo "Section: free"                    >> $deb_path/DEBIAN/control
echo "Prioritt: mysoftware"             >> $deb_path/DEBIAN/control
echo "Architecture: amd64"              >> $deb_path/DEBIAN/control
echo "Maintainer: etherledger"          >> $deb_path/DEBIAN/control
echo "Description: bnos software"       >> $deb_path/DEBIAN/control
sed 's/^/    &/g' $deb_path/usr/local/build_hash.txt>>$deb_path/DEBIAN/control


#echo "#!/bin/sh"                                                                   >> $deb_path/DEBIAN/preinst
#echo "service snmpd stop"                                                          >> $deb_path/DEBIAN/preinst

echo "#!/bin/sh"                                                                   >> $deb_path/DEBIAN/postinst
echo "ldconfig"                                                                    >> $deb_path/DEBIAN/postinst
echo "cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak"                            >> $deb_path/DEBIAN/postinst
echo "echo \"dlmod BNDevice  /usr/local/lib/BNDevice.so\" >> /etc/snmp/snmpd.conf" >> $deb_path/DEBIAN/postinst
echo "sed -i \"s:trapsink:#trapsink:g\" /etc/snmp/snmpd.conf"                      >> $deb_path/DEBIAN/postinst
echo "sed -i \"s:#trap2sink:trap2sink:g\" /etc/snmp/snmpd.conf"                    >> $deb_path/DEBIAN/postinst
echo "rm -f /etc/rc.local"                                                         >> $deb_path/DEBIAN/postinst
echo "touch /etc/rc.local"                                                         >> $deb_path/DEBIAN/postinst
echo "echo \"#!/bin/bash -e\"         >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"noded-start bcr\"        >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"sleep 2\"                >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "echo \"exit 0\"                 >>/etc/rc.local"                             >> $deb_path/DEBIAN/postinst
echo "chmod 777 /etc/rc.local"                                                     >> $deb_path/DEBIAN/postinst
echo "service snmpd start"                                                         >> $deb_path/DEBIAN/postinst

echo "#!/bin/sh"                                                                   >> $deb_path/DEBIAN/prerm
#echo "if [ "$1" = "remove" -o "$1" = "deconfigure" ]; then"                        >> $deb_path/DEBIAN/prerm
echo "  killall noded"                                                             >> $deb_path/DEBIAN/prerm
echo "  service snmpd stop"                                                        >> $deb_path/DEBIAN/prerm                                              
echo "  rm -f /etc/rc.local"                                                       >> $deb_path/DEBIAN/prerm
echo "  touch /etc/rc.local"                                                       >> $deb_path/DEBIAN/prerm
echo "  cp /etc/snmp/snmpd.conf.bak /etc/snmp/snmpd.conf"                          >> $deb_path/DEBIAN/prerm
#echo "fi"                                                                          >> $deb_path/DEBIAN/prerm

#echo "#!/bin/sh"                                                                   >> $deb_path/DEBIAN/postrm
#echo "  if [ "$1" = "purge" ] ; then"                                              >> $deb_path/DEBIAN/postrm
#echo "  service snmpd start"                                                       >> $deb_path/DEBIAN/postrm
echo "  ldconfig"                                                                  >> $deb_path/DEBIAN/postrm
#echo "fi"                                                                          >> $deb_path/DEBIAN/postrm



#rm -rfv bcr.deb
dpkg -b $deb_path $result_path/bcr.deb

cp  -rf $pwd_path/workspace/build/openwrt-ramips-mt7621-zk-wac5080-squashfs-sysupgrade.bin  $result_path   


