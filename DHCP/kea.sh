#!bin/bash
cat << END
                                                                                                                                                               
DDDDDDDDDDDDD      HHHHHHHHH     HHHHHHHHH      CCCCCCCCCCCCCPPPPPPPPPPPPPPPPP        KKKKKKKKK    KKKKKKKEEEEEEEEEEEEEEEEEEEEEE               AAA               
D::::::::::::DDD   H:::::::H     H:::::::H   CCC::::::::::::CP::::::::::::::::P       K:::::::K    K:::::KE::::::::::::::::::::E              A:::A              
D:::::::::::::::DD H:::::::H     H:::::::H CC:::::::::::::::CP::::::PPPPPP:::::P      K:::::::K    K:::::KE::::::::::::::::::::E             A:::::A             
DDD:::::DDDDD:::::DHH::::::H     H::::::HHC:::::CCCCCCCC::::CPP:::::P     P:::::P     K:::::::K   K::::::KEE::::::EEEEEEEEE::::E            A:::::::A            
  D:::::D    D:::::D H:::::H     H:::::H C:::::C       CCCCCC  P::::P     P:::::P     KK::::::K  K:::::KKK  E:::::E       EEEEEE           A:::::::::A           
  D:::::D     D:::::DH:::::H     H:::::HC:::::C                P::::P     P:::::P       K:::::K K:::::K     E:::::E                       A:::::A:::::A          
  D:::::D     D:::::DH::::::HHHHH::::::HC:::::C                P::::PPPPPP:::::P        K::::::K:::::K      E::::::EEEEEEEEEE            A:::::A A:::::A         
  D:::::D     D:::::DH:::::::::::::::::HC:::::C                P:::::::::::::PP         K:::::::::::K       E:::::::::::::::E           A:::::A   A:::::A        
  D:::::D     D:::::DH:::::::::::::::::HC:::::C                P::::PPPPPPPPP           K:::::::::::K       E:::::::::::::::E          A:::::A     A:::::A       
  D:::::D     D:::::DH::::::HHHHH::::::HC:::::C                P::::P                   K::::::K:::::K      E::::::EEEEEEEEEE         A:::::AAAAAAAAA:::::A      
  D:::::D     D:::::DH:::::H     H:::::HC:::::C                P::::P                   K:::::K K:::::K     E:::::E                  A:::::::::::::::::::::A     
  D:::::D    D:::::D H:::::H     H:::::H C:::::C       CCCCCC  P::::P                 KK::::::K  K:::::KKK  E:::::E       EEEEEE    A:::::AAAAAAAAAAAAA:::::A    
DDD:::::DDDDD:::::DHH::::::H     H::::::HHC:::::CCCCCCCC::::CPP::::::PP               K:::::::K   K::::::KEE::::::EEEEEEEE:::::E   A:::::A             A:::::A   
D:::::::::::::::DD H:::::::H     H:::::::H CC:::::::::::::::CP::::::::P               K:::::::K    K:::::KE::::::::::::::::::::E  A:::::A               A:::::A  
D::::::::::::DDD   H:::::::H     H:::::::H   CCC::::::::::::CP::::::::P               K:::::::K    K:::::KE::::::::::::::::::::E A:::::A                 A:::::A 
DDDDDDDDDDDDD      HHHHHHHHH     HHHHHHHHH      CCCCCCCCCCCCCPPPPPPPPPP               KKKKKKKKK    KKKKKKKEEEEEEEEEEEEEEEEEEEEEEAAAAAAA                   AAAAAAA

END

#pequeno menu de introducao
cat << END
Escolha, por favor, uma das seguintes opcoes:

1: Instalar o serviço DHCP KEA
2: Restaurar o arquivo de configuracoes do serviço
3: Verificação de leases e de logs
4: Fechar o programa

END

while true; do
	read -p ": " w
	case $w in
		1)
		echo "A Instalar o dhcp..."
		sudo dnf install -y kea

		#Colocar o ip estatico
		echo "A colocar o ip do server como estatico..."
		sudo nmcli connection modify ens192 ipv4.addresses 192.168.1.112/24
		sudo nmcli connection modify ens192 ipv4.method manual

		#Pedir de ips para utilizar
		echo "Introduz uma gama de ips que  pertençam a mesma subnet do servidor dhcp 192.168.1.0/24:"
		echo "Atenção!!!! Não utilizar uma gama de IPS onde o ip do servidor ( 192.168.1.112/24 ) nem o ips do gateway (192.168.1.254) estejam presentes!!"
		read -p " Ip de inicío :" ip_inicio
		read -p " ip final:" ip_fim

		#verificar o intervalo da gama de ips
		subnet="^192\.168\.1\."
		mask="255.255.255.0"
		subrede="192.168.1.0/24"
		ip_servidor="192.168.1.112"

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
		echo "Criação de um arquivo .org de modo a deixar mais fluida a leitura do ficheiro de configuração..."
		sudo mv /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.org

		#Variavel do arquivo de DHCP

		dns= $dns
		subrede= $subrede
		ip_inicio= $ip_inicio
		ip_fim= $ip_fim
		ip_gateway= $ip_gateway

		echo "A aplicar as configurações..."
		sudo tee /etc/kea/kea-dhcp4.conf > /dev/null << END
		{
		  "Dhcp4": {
			"interfaces-config": {
			  "interfaces": [ "ens192" ]
			},
			"expired-leases-processing": {
			  "reclaim-timer-wait-time": 10,
			  "flush-reclaimed-timer-wait-time": 25,
			  "hold-reclaimed-time": 3600,
			  "max-reclaim-leases": 100,
			  "max-reclaim-time": 250,
			  "unwarned-reclaim-cycles": 5
			},
			"renew-timer": 900,
			"rebind-timer": 1800,
			"valid-lifetime": 3600,
			"option-data": [
			  {
				"name": "domain-name-servers",
				"data": "$dns"
			  },
			  {
				"name": "domain-name",
				"data": "empresa.local"
			  },
			  {
				"name": "domain-search",
				"data": "empresa.local"
			  }
			],
			"subnet4": [
			  {
				"id": 1,
				"subnet": "$subrede",
				"pools": [ { "pool": "$ip_inicio - $ip_fim" } ],
				"option-data": [
				  {
					"name": "routers",
					"data": "$ip_gateway"
				  }
				]
			  }
			],
			"loggers": [
			  {
				"name": "kea-dhcp4",
				"output-options": [
				  {
					"output": "/var/log/kea/kea-dhcp4.log"
				  }
				],
				"severity": "INFO",
				"debuglevel": 0
			  }
			]
		  }
		}
END


		#Inicio DHCP
		echo " A iniciar todas as configurações..."
		sudo systemctl enable --now kea-dhcp4

		#ativar serviços firewall
		echo " Configurar a firewall..."
		sudo firewall-cmd --add-service=dhcp
		sudo firewall-cmd --runtime-to-permanent
		sudo firewall-cmd --reload

		#veriicar os status
		echo "A verificar o status do DHCP..."
		sudo systemctl status kea-dhcp4

		echo "Instalação concluida e configuração feita com sucesso! :)"
		;;
		2)
		if sudo test -f "/etc/kea/kea-dhcp4.conf.org"; then
			echo "UI! Encontrei aqui o ficheiro backup!"
			sudo mv /etc/kea/kea-dhcp4.conf.org /etc/kea/kea-dhcp4.conf
			echo "Arquivo backup restaurado"
		else
			while true;do 
				echo "Oh nao :( Nao encontrei nenhum ficheiro backup, bora criar?"
				read -p ": " criar
				case $criar in
					S|s)
					echo "A criar o ficheiro..."
					sudo mv /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.org
					sudo tee /etc/kea/kea-dhcp4.conf > /dev/null << END
					{
					  "Dhcp4": {
						"interfaces-config": {
						  "interfaces": [ "ens192" ]
						},
						"expired-leases-processing": {
						  "reclaim-timer-wait-time": 10,
						  "flush-reclaimed-timer-wait-time": 25,
						  "hold-reclaimed-time": 3600,
						  "max-reclaim-leases": 100,
						  "max-reclaim-time": 250,
						  "unwarned-reclaim-cycles": 5
						},
						"renew-timer": 900,
						"rebind-timer": 1800,
						"valid-lifetime": 3600,
						"option-data": [
						  {
							"name": "domain-name-servers",
							"data": "$dns"
						  },
						  {
							"name": "domain-name",
							"data": "srv.world"
						  },
						  {
							"name": "domain-search",
							"data": "srv.world"
						  }
						],
						"subnet4": [
						  {
							"id": 1,
							"subnet": "$subrede",
							"pools": [ { "pool": "$ip_inicio - $ip_fim" } ],
							"option-data": [
							  {
								"name": "routers",
								"data": "$ip_gateway"
							  }
							]
						  }
						],
						"loggers": [
						  {
							"name": "kea-dhcp4",
							"output-options": [
							  {
								"output": "/var/log/kea/kea-dhcp4.log"
							  }
							],
							"severity": "INFO",
							"debuglevel": 0
						  }
						]
					  }
					}
END
					echo "UH LA LA! Ficheiro backup criado com sucesso!"
					exit
					;;
					N|n)
					echo "OKAPA CHEFE! Ficheiro nao ira ser criado :)"
					exit
					;;
					*)
					echo "IIIIHHHHH! Opcao invalida, bye bye"
					;;
				esac
			done
		fi
		break
		;;
		3)
		echo "Vamos lá verificar as leases e logs!"
		echo "----> LOGS DHCP KEA <----"
		sudo tail -f /var/log/kea-dhcp4.log
		echo "----> LOGS DHCP KEA <----"
		echo "----> VER LEASES DHCP KEA <----"
		sudo cat /var/lib/kea/kea-leases4.csv
		echo "----> VER LEASES DHCP KEA <----"
		echo "----> VER ESCUTA <----"
		sudo ss -lun | grep 67
		echo "----> VER ESCUTA <----"
		read -p "Esta tudo funcional?" pagante
		while true; do 
			if [ $pagante = sim ]; then
				echo "UFA! Fico feliz :)"
				break
				exit 0
			elif [ $pagante = nao ]; then
				echo "Verifica o arquivo de configuracao, talvez esteja ai o problema."
				break
				exit 0
			else
				echo "Opcao invalida, tenta por sim ou nao."
			fi
		done
		;;
		4)
		echo "OKAPA CHEFE! Goodbye"
		exit
		;;
		*)
		echo "Opcao invalida, escolha um numero de 1 a 3 por favor!"
		;;
	esac
done
