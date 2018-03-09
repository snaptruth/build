#!/bin/bash	
set -e
cxx_nfd_git=http://xiaodong:12345678@172.16.23.248/liulijin/cxx_nfd.git
ndnconfig_git=http://xiaodong:12345678@172.16.23.248/xudaquan/ndnconfig.git

result_path=$(pwd)/build
src_path=$(pwd)/src
ndn_path=cxx_nfd/asset
nfd_path=nfd
ndn_cxx_path=ndn_cxx
ndnconfig_path=ndnconfig

flag=1
if [ $flag -eq 1 ]
then

echo "start build"
#cd ~/workspace
rm -rf $src_path
rm -rf $result_path
mkdir -pv $result_path/$nfd_path
mkdir -pv $result_path/$ndn_cxx_path

mkdir -pv $src_path


#build ndn
echo "build ndn cxx"
cd  $src_path
git clone  $cxx_nfd_git
cd  $src_path/$ndn_path
tar -zxvf ndn-cxx-0.5.1.tar.gz
cd ndn-cxx-0.5.1
#./waf clean
./waf configure --prefix=$result_path/$ndn_cxx_path 
./waf
./waf install

echo "build nfd"
cd  $src_path/$ndn_path
tar -zxvf NFD-0.5.1.tar.gz
cd NFD-0.5.1
#./waf clean
./waf configure --without-websocket --prefix=$result_path/$nfd_path 
./waf
./waf install

fi

echo "get ndn.conf"
cd  $src_path
rm -rf $ndnconfig_path
git clone  $ndnconfig_git


sed -i "s:/home/bn/ndn_workspace/build/nfd:/usr/local:g" $result_path/$nfd_path/bin/nfd-status-http-server
sed -i "s:/home/bn/ndn_workspace/build/nfd:/usr/local:g" $result_path/$nfd_path/bin/nfd-start
sed -i "s:/home/bn/ndn_workspace/build/nfd:/usr/local:g" $result_path/$nfd_path/etc/ndn/nfd.conf.sample
sed -i "s:/home/bn/ndn_workspace/build/ndn_cxx:/usr/local:g" $result_path/$ndn_cxx_path/include/ndn-cxx/ndn-cxx-config.hpp
sed -i "s:/home/bn/ndn_workspace/build/ndn_cxx:/usr/local:g" $result_path/$ndn_cxx_path/lib/pkgconfig/libndn-cxx.pc
sed -i "s#--config /usr/local/etc/ndn/nfd.conf# #g"                                      $result_path/$nfd_path/bin/nfd-start
sed -i "s#/usr/local/bin/nfd#/usr/local/bin/nfd --config /usr/local/etc/ndn/nfd.conf#g"  $result_path/$nfd_path/bin/nfd-start

echo "copy ndn.conf"
cp  $src_path/$ndnconfig_path/nfd.conf  $result_path/$nfd_path/etc/ndn/nfd.conf

