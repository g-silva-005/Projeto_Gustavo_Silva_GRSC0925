#!bin/bash

#Instalar dns Bind

cat << end
DDDDDDDDDDDDD        NNNNNNNN        NNNNNNNN   SSSSSSSSSSSSSSS      BBBBBBBBBBBBBBBBB   IIIIIIIIIINNNNNNNN        NNNNNNNNDDDDDDDDDDDDD        
D::::::::::::DDD     N:::::::N       N::::::N SS:::::::::::::::S     B::::::::::::::::B  I::::::::IN:::::::N       N::::::ND::::::::::::DDD     
D:::::::::::::::DD   N::::::::N      N::::::NS:::::SSSSSS::::::S     B::::::BBBBBB:::::B I::::::::IN::::::::N      N::::::ND:::::::::::::::DD   
DDD:::::DDDDD:::::D  N:::::::::N     N::::::NS:::::S     SSSSSSS     BB:::::B     B:::::BII::::::IIN:::::::::N     N::::::NDDD:::::DDDDD:::::D  
  D:::::D    D:::::D N::::::::::N    N::::::NS:::::S                   B::::B     B:::::B  I::::I  N::::::::::N    N::::::N  D:::::D    D:::::D 
  D:::::D     D:::::DN:::::::::::N   N::::::NS:::::S                   B::::B     B:::::B  I::::I  N:::::::::::N   N::::::N  D:::::D     D:::::D
  D:::::D     D:::::DN:::::::N::::N  N::::::N S::::SSSS                B::::BBBBBB:::::B   I::::I  N:::::::N::::N  N::::::N  D:::::D     D:::::D
  D:::::D     D:::::DN::::::N N::::N N::::::N  SS::::::SSSSS           B:::::::::::::BB    I::::I  N::::::N N::::N N::::::N  D:::::D     D:::::D
  D:::::D     D:::::DN::::::N  N::::N:::::::N    SSS::::::::SS         B::::BBBBBB:::::B   I::::I  N::::::N  N::::N:::::::N  D:::::D     D:::::D
  D:::::D     D:::::DN::::::N   N:::::::::::N       SSSSSS::::S        B::::B     B:::::B  I::::I  N::::::N   N:::::::::::N  D:::::D     D:::::D
  D:::::D     D:::::DN::::::N    N::::::::::N            S:::::S       B::::B     B:::::B  I::::I  N::::::N    N::::::::::N  D:::::D     D:::::D
  D:::::D    D:::::D N::::::N     N:::::::::N            S:::::S       B::::B     B:::::B  I::::I  N::::::N     N:::::::::N  D:::::D    D:::::D 
DDD:::::DDDDD:::::D  N::::::N      N::::::::NSSSSSSS     S:::::S     BB:::::BBBBBB::::::BII::::::IIN::::::N      N::::::::NDDD:::::DDDDD:::::D  
D:::::::::::::::DD   N::::::N       N:::::::NS::::::SSSSSS:::::S     B:::::::::::::::::B I::::::::IN::::::N       N:::::::ND:::::::::::::::DD   
D::::::::::::DDD     N::::::N        N::::::NS:::::::::::::::SS      B::::::::::::::::B  I::::::::IN::::::N        N::::::ND::::::::::::DDD     
DDDDDDDDDDDDD        NNNNNNNN         NNNNNNN SSSSSSSSSSSSSSS        BBBBBBBBBBBBBBBBB   IIIIIIIIIINNNNNNNN         NNNNNNNDDDDDDDDDDDDD        
end


cat << END
Escolha, por favor, uma das seguintes opcoes:

1: Instalar o serviço DNS BIND
2: Testes e verificações do serviço
3: Fechar o programa

END

while true;do
	read -p ": " w
	case $w in
		1)
		echo "----> A instalar o serviço <----"
		sudo dnf install -y bind bind-utils
		echo "----> IP do servidor <----"
		nmcli
		read -p "Introduza o ip que está presente na interface ens192: " ip
		read -p "Do ip introduzido anteriormente, introduza o ultimo octeto: " octeto
		echo "----> A aplicar as configurações necessárias <----"
		sudo cat << EOF_NAMEDCONF | sudo tee /etc/named.conf > /dev/null
acl internal-network {
        192.168.1.0/24;
};

options {
        listen-on port 53 { any; };
        listen-on-v6 { any; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        
        allow-query     { localhost; internal-network; };
        allow-transfer  { localhost; };

        recursion yes;

        forward only;
        forwarders { 8.8.8.8; 8.8.4.4; };
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

zone "empresa.local" IN {
        type primary;
        file "empresa.local.lan";
        allow-update { none; };
};
zone "1.168.192.in-addr.arpa" IN {
        type primary;
        file "1.168.192.db";
        allow-update { none; };
};
EOF_NAMEDCONF


		sudo cat << EOF_FWD | sudo tee /var/named/empresa.local.lan > /dev/null
\$TTL 86400
@   IN  SOA     servidor1.empresa.local. root.empresa.local. (
        1761555569  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)
@               IN  NS      servidor1.empresa.local.
servidor1       IN  A       $ip
@               IN  MX 10   servidor1.empresa.local.
www             IN  A       192.168.1.120
EOF_FWD

		sudo tee /var/named/1.168.192.db > /dev/null << END
\$TTL 86400
@   IN  SOA     servidor1.empresa.local. root.empresa.local. (
        1761555569  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)
@               IN  NS      servidor1.empresa.local.
$octeto         IN  PTR     servidor1.empresa.local.
120             IN  PTR     www.empresa.local.

END
		echo "---> Definir permissoes no ficheiro <---"
		sudo chown named:named /var/named/empresa.local.lan
        sudo chown named:named /var/named/1.168.192.db
		echo "---> Definir permissoes na firewall <---"
		sudo firewall-cmd --add-service=dns --permanent
		sudo firewall-cmd --reload
		echo "---> Iniciar o serviço DNS BIND <---"
		sudo systemctl enable --now named
		sudo systemctl start named
		sudo systemctl status named
		;;
		2)
		echo "---> BIND <---"
		dig @$ip empresa.local
		echo "---> BIND <---"
		echo "---> NSLOOKUP <---"
		nslookup servidor1.empresa.local $ip
		echo "---> NSLOOKUP <---"
		echo "---> TESTE INVERSO <---"
		dig -x $ip
		echo "---> TESTE INVERSO <---"
		echo "---> TESTE DE ENCAMINHAMENTO <---"
		ping www.google.com 
		echo "---> TESTE DE ENCAMINHAMENTO <---"
		;;
		3)
		echo "A fechar programa! Goodbye!"
		break
		exit 0
		;;
		*)
		echo "Opção inválida! Coloque um numero de 1 a 3 por favor!"
		;;
	esac
done	


cat << end
     OOOOOOOOO     BBBBBBBBBBBBBBBBB   RRRRRRRRRRRRRRRRR   IIIIIIIIII      GGGGGGGGGGGGG               AAA               DDDDDDDDDDDDD             OOOOOOOOO     
   OO:::::::::OO   B::::::::::::::::B  R::::::::::::::::R  I::::::::I   GGG::::::::::::G              A:::A              D::::::::::::DDD        OO:::::::::OO   
 OO:::::::::::::OO B::::::BBBBBB:::::B R::::::RRRRRR:::::R I::::::::I GG:::::::::::::::G             A:::::A             D:::::::::::::::DD    OO:::::::::::::OO 
O:::::::OOO:::::::OBB:::::B     B:::::BRR:::::R     R:::::RII::::::IIG:::::GGGGGGGG::::G            A:::::::A            DDD:::::DDDDD:::::D  O:::::::OOO:::::::O
O::::::O   O::::::O  B::::B     B:::::B  R::::R     R:::::R  I::::I G:::::G       GGGGGG           A:::::::::A             D:::::D    D:::::D O::::::O   O::::::O
O:::::O     O:::::O  B::::B     B:::::B  R::::R     R:::::R  I::::IG:::::G                        A:::::A:::::A            D:::::D     D:::::DO:::::O     O:::::O
O:::::O     O:::::O  B::::BBBBBB:::::B   R::::RRRRRR:::::R   I::::IG:::::G                       A:::::A A:::::A           D:::::D     D:::::DO:::::O     O:::::O
O:::::O     O:::::O  B:::::::::::::BB    R:::::::::::::RR    I::::IG:::::G    GGGGGGGGGG        A:::::A   A:::::A          D:::::D     D:::::DO:::::O     O:::::O
O:::::O     O:::::O  B::::BBBBBB:::::B   R::::RRRRRR:::::R   I::::IG:::::G    G::::::::G       A:::::A     A:::::A         D:::::D     D:::::DO:::::O     O:::::O
O:::::O     O:::::O  B::::B     B:::::B  R::::R     R:::::R  I::::IG:::::G    GGGGG::::G      A:::::AAAAAAAAA:::::A        D:::::D     D:::::DO:::::O     O:::::O
O:::::O     O:::::O  B::::B     B:::::B  R::::R     R:::::R  I::::IG:::::G        G::::G     A:::::::::::::::::::::A       D:::::D     D:::::DO:::::O     O:::::O
O::::::O   O::::::O  B::::B     B:::::B  R::::R     R:::::R  I::::I G:::::G       G::::G    A:::::AAAAAAAAAAAAA:::::A      D:::::D    D:::::D O::::::O   O::::::O
O:::::::OOO:::::::OBB:::::BBBBBB::::::BRR:::::R     R:::::RII::::::IIG:::::GGGGGGGG::::G   A:::::A             A:::::A   DDD:::::DDDDD:::::D  O:::::::OOO:::::::O
 OO:::::::::::::OO B:::::::::::::::::B R::::::R     R:::::RI::::::::I GG:::::::::::::::G  A:::::A               A:::::A  D:::::::::::::::DD    OO:::::::::::::OO 
   OO:::::::::OO   B::::::::::::::::B  R::::::R     R:::::RI::::::::I   GGG::::::GGG:::G A:::::A                 A:::::A D::::::::::::DDD        OO:::::::::OO   
     OOOOOOOOO     BBBBBBBBBBBBBBBBB   RRRRRRRR     RRRRRRRIIIIIIIIII      GGGGGG   GGGGAAAAAAA                   AAAAAAADDDDDDDDDDDDD             OOOOOOOOO     

end

