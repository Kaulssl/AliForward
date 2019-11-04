#!/bin/bash
# apt update -y
# wget AliForward.sh && chmod +x AliForward.sh
# bash AliForward.sh alihk2

#开启BBR
echo "net.core.default_qdisc=fq" >>/etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.conf
sysctl -p
#配置转发
rv_local_ip=$(hostname -i) #获得本机IP
rv_builtin_domain1="doamin1.example.com"
rv_builtin_domain2="doamin2.example.com"
echo "####################################"
echo "请选择或输入域名："
while true
do
    echo "1. ${rv_builtin_domain1}"
    echo "2. ${rv_builtin_domain2}"
    echo "3. 自定义域名或IP"
    read -eN 1 -p "请输入选项数字：" rv_input_char
    case ${rv_input_char} in
    1)
        rv_domain=${rv_builtin_domain1}
        rv_forwarding_ip=$(ping -c 1 ${rv_domain} | sed '1{s/[^(]*(//;s/).*//;q}')  #获得输入域名的IP
        break
        ;;
    2)
        rv_domain=${rv_builtin_domain2}
        rv_forwarding_ip=$(ping -c 1 ${rv_domain} | sed '1{s/[^(]*(//;s/).*//;q}')  #获得输入域名的IP
        break
        ;;
    3)
        read -p "请输入域名：" rv_domain
        rv_forwarding_ip=$(ping -c 1 ${rv_domain} | sed '1{s/[^(]*(//;s/).*//;q}')  #获得输入域名的IP
        break
        ;;
    *)
        echo "错误输入，请重新输入"
        ;;
    esac
done
rv_forwarding_ip=$(ping -c 1 ${rv_domain} | sed '1{s/[^(]*(//;s/).*//;q}') #获得输入域名的IP
echo "$rv_forwarding_ip"
sed -n '/^net.ipv4.ip_forward=1/'p /etc/sysctl.conf | grep -q "net.ipv4.ip_forward=1"
if [ $? -ne 0 ]; then
	echo -e "net.ipv4.ip_forward=1" >>/etc/sysctl.conf && sysctl -p
fi
iptables -t nat -A PREROUTING -p tcp --dport 15000:30000 -j DNAT --to-destination ${rv_forwarding_ip}
iptables -t nat -A PREROUTING -p udp --dport 15000:30000 -j DNAT --to-destination ${rv_forwarding_ip}
iptables -t nat -A POSTROUTING -p tcp -d ${rv_forwarding_ip} --dport 15000:30000 -j SNAT --to-source ${rv_local_ip}
iptables -t nat -A POSTROUTING -p udp -d ${rv_forwarding_ip} --dport 15000:30000 -j SNAT --to-source ${rv_local_ip}
iptables-save >/etc/iptables.up.rules
iptables-restore </etc/iptables.up.rules
# 监控清除
wget http://update.aegis.aliyun.com/download/uninstall.sh
chmod +x uninstall.sh
/bin/bash /root/uninstall.sh
wget http://update.aegis.aliyun.com/download/quartz_uninstall.sh
chmod +x quartz_uninstall.sh
sudo /root/quartz_uninstall.sh
sudo pkill aliyun-service
/bin/rm -fr /etc/init.d/agentwatch /usr/sbin/aliyun-service
/bin/rm -rf /usr/local/aegis*
iptables="/usr/sbin/iptables"
iptables -I INPUT -s 140.205.201.0/28 -j DROP
iptables -I INPUT -s 140.205.201.16/29 -j DROP
iptables -I INPUT -s 140.205.201.32/28 -j DROP
iptables -I INPUT -s 140.205.225.192/29 -j DROP
iptables -I INPUT -s 140.205.225.200/30 -j DROP
iptables -I INPUT -s 140.205.225.184/29 -j DROP
iptables -I INPUT -s 140.205.225.183/32 -j DROP
iptables -I INPUT -s 140.205.225.206/32 -j DROP
iptables -I INPUT -s 140.205.225.205/32 -j DROP
sudo /usr/local/cloudmonitor/wrapper/bin/cloudmonitor.sh stop
sudo /usr/local/cloudmonitor/wrapper/bin/cloudmonitor.sh remove
sudo rm -rf /usr/local/cloudmonitor
#更改DDNS
wget -nd -O ddns.sh https://gist.githubusercontent.com/benkulbertis/fff10759c2391b6618dd/raw #edit
rv_l3dn=${1#ddns }
sed -i $"s/record_name=\"\(.*\)\([.].*[.].*\)\"/record_name=\"${rv_l3dn}\2\"/" ddns.sh
bash /root/ddns.sh
