#!bin/bash

echo "A Instalar o dhcp..."
sudo dnf update
sudo dnf install -y dhcp-server



#Ativar a interface enp0s8 para o dhcp usar apenas essa interface
sudo nmcli connection add type ethernet ifname enp0s8 ipv4.addresses 192.168.2.1/24
sudo nmcli connection modify enp0s8 ipv4.method manual ipv4.gateway 192.168.2.1/24 ipv4.addresses 192.168.2.1/24 	#ativar o server como gateway

#Pedir de ips para utilizar 
echo "Introduz uma gama de ips que  pertençam a mesma subnet do servidor dhcp 192.168.2.1/24:"
echo "Atenção!!!! Não utilizar uma gama de IPS onde o ip do servidor ( 192.168.2.1/24 ) nem o ips do gateway (192.168.2.254) estejam presentes!!"
read -p " Ip de inicío :" ip_inicio
read -p " ip final:" ip_fim

#verificar o intervalo da gama de ips
subnet="^192\.168\.2\."
mask="255.255.255.0"
subrede="192.168.2.0"
ip_servidor="192.168.2.1"

if [[ $ip_inicio =~ $subnet ]] && [[ $ip_fim =~ $subnet ]] && [[ $ip_inicio != $ip_servidor ]] &&  [[ $ip_fim != $ip_servidor ]]; then
echo " IPs válidos na subnet do servidor! :)"
else
echo " ERRO 232: Os IPs estão na subnet errado ou algum IP está com o mesmo ip do servidor. A fechar o programa..."
exit 1
fi

# Ip default gateway
echo " Introduz o IP do default-gateway"
read -p "gateway:" ip_gateway

#verificar gateway
if [[ $ip_gateway =~ $subnet ]];then
echo " O default-gateway válido na subrede! :)"
else
echo "ERRO 232: O default-gateway não está na mesma subrede. A Fechar o programa..."
exit 1
fi

#receber o dns
echo " Introduza o ip do DNS"
read -p " DNS:" dns

#backup
echo " Backup do arquivo de configuração DHCP-SERVER"
sudo cp /etc/dhcp/dhcp.conf /etc/dhcp/dhcp.conf.bak

#Variavel do arquivo de DHCP
dhcp_config="/etc/dhcp/dhcpd.conf"
echo "A acabar as configurações..."
sudo bash -c "cat >> $dhcp_config" << END
subnet $subrede netmask $mask {
	default-lease-time 600;
	max-lease-time 7200;
	range $ip_inicio $ip_fim;	#gama de ips
	option routers $ip_gateway;	#gateway da rede
	option domain-name-servers $dns;	#dns da rede
}
END

#Inicio DHCP
echo " A iniciar todas as configurações..."
sudo systemctl enable --now dhcpd.service
sudo systemctl start --now dhcpd.service
#ativar serviços firewall
echo " Configurar a firewall..."
sudo firewall-cmd --add-service=dhcp --permanent
sudo firewall-cmd --reload

#veriicar os status
echo " A verificar o status do DHCP..."
sudo systemctl status dhcpd.service

echo "Instalação concluida e configuração feita com sucesso! :)"
