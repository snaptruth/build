#!/bin/bash
set -e
Consensus_git=http://xiaodong:12345678@172.16.23.248/BNLM1969/Consensus.git
runConsensus_url=http://172.16.23.248/zhoushengxian/runConsensus/raw/master/bin/noded-start.sh
				 
bsdr_git=http://xiaodong:12345678@172.16.23.248/xudaquan/bsdr.git
baar_git=http://xiaodong:12345678@172.16.23.248/xudaquan/baar.git 
snmp_git=http://xiaodong:12345678@172.16.23.248/BNLM1969/SNMP.git

openwrt_git=http://xiaodong:12345678@172.16.23.248/BNLM1969/openwrt.git
ndnconfig_git=http://xiaodong:12345678@172.16.23.248/xudaquan/ndnconfig.git

result_path=$(pwd)/build
build_file=$result_path/build_hash.txt
src_path=$(pwd)/src
openwrt_path=$(pwd)/zkopenwrt_uclib
Consensus_path=Consensus
bsdr_path=bsdr
baar_path=baar
snmp_path=SNMP
ndnconfig_path=ndnconfig

flag=1
if [ $flag -eq 1 ]
then

echo "start build"
rm -rfv $result_path
mkdir -pv $result_path/$Consensus_path
mkdir -pv $result_path/$openwrt_path
mkdir -pv $result_path/$bsdr_path
mkdir -pv $result_path/$baar_path
mkdir -pv $result_path/$snmp_path

rm -rf $src_path
mkdir -pv $src_path


#build openwrt baar
echo "build openwrt baar 1"
cd  $src_path
git clone  $openwrt_git 
cd  $src_path/openwrt
echo "openwrt hash:"      >> $build_file
git show -q | grep commit >> $build_file
cp  -rf $src_path/openwrt/all/.  $openwrt_path
#cd  $openwrt_path
#make target/clean
#make -j8
#cp   -f ./bin/ramips/openwrt-ramips-mt7621-zk-wac5080-squashfs-sysupgrade.bin  $result_path

#build Consensus
echo "build Consensus"
cd  $src_path
git clone  $Consensus_git 
cd  $src_path/$Consensus_path
echo "Consensus hash:"    >> $build_file
git show -q | grep commit >> $build_file
find . -name "*.sh" | xargs chmod 744
find . -name "build_detect_platform" | xargs chmod 744
./autogen.sh
./configure --with-incompatible-bdb --with-gui=no --prefix=$result_path/$Consensus_path
make clean
make 
make install

echo "get runConsensus_git"
wget -O   $result_path/$Consensus_path/bin/noded-start $runConsensus_url 
chmod 755 $result_path/$Consensus_path/bin/noded-start

#build bsdr
echo "build bsdr"
cd  $src_path
git clone  $bsdr_git
cd  $src_path/$bsdr_path
echo "bsdr hash:"    >> $build_file
git show -q | grep commit >> $build_file
make clean
make 
cp ./bsdrsvr            $result_path/$bsdr_path
cp ./bsdrca.xml         $result_path/$bsdr_path
cp ./log4cxx.properties $result_path/$bsdr_path
cp ./ipconfig.xml       $result_path/$bsdr_path
cp ./configndn.sh       $result_path/$bsdr_path

#build baar
echo "build baar"
cd  $src_path
git clone  $baar_git
cp -rf $src_path/$baar_path/* $openwrt_path/package/system/baar/src
cd  $src_path/$baar_path
echo "baar hash:"    >> $build_file
git show -q | grep commit >> $build_file
make clean
make 
cp ./baarsvr            $result_path/$baar_path
cp ./ylca.xml           $result_path/$baar_path
cp ./log4cxx.properties $result_path/$baar_path
cp ./server.pem         $result_path/$baar_path
cp ./ipconfig.xml       $result_path/$baar_path
cp ./configndn.sh       $result_path/$baar_path

#build snmp
echo "build snmp"
cd  $src_path
git clone $snmp_git
cd  $src_path/$snmp_path
echo "snmp hash:"    >> $build_file
git show -q | grep commit >> $build_file
make clean
make 
cp ./BNDevice.so $result_path/$snmp_path
cp ./EARTHLEDGER-MIB.txt $result_path/$snmp_path

#get ndn.config
echo "get ndn.config"
cd  $src_path
git clone  $ndnconfig_git
cp -rf $src_path/$ndnconfig_path/* $openwrt_path/package/system/ndn-all-dev/src/nfd/etc/ndn/

#build openwrt baar
echo "build openwrt baar 2"
#cd  $src_path
#git clone  $openwrt_git 
#cd  $src_path/openwrt
#echo "openwrt hash:"      >> $build_file
#git show -q | grep commit >> $build_file
#cp  -rfv $src_path/openwrt/all  $openwrt_path
cd  $openwrt_path
rm   -f ./bin/ramips/openwrt-ramips-mt7621-zk-wac5080-squashfs-sysupgrade.bin
make target/clean
make 
cp   -f ./bin/ramips/openwrt-ramips-mt7621-zk-wac5080-squashfs-sysupgrade.bin  $result_path


fi

sed -i "s:/home/bn/workspace/build/Consensus:/usr/local:g" $result_path/$Consensus_path/lib/libbitcoinconsensus.la
sed -i "s:/home/bn/workspace/build/Consensus:/usr/local:g" $result_path/$Consensus_path/lib/pkgconfig/libbitcoinconsensus.pc
