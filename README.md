# Projeto_Gustavo_Silva_GRSC0925
Este projeto tem um script de DHCP e um script de DNS 
<div align="center">
         <img src="https://github.com/user-attachments/assets/ce0a71e3-1b30-401c-ac30-0ec6369539c9" width="450"/>
         <br>
</div>


## Intruçoes de uso

1 - É necessário o servidor que for usado estes scripts tenham dois adaptadores de internet. Um em nat outro em bridged. 

2 - Caso um script nao corra, provavelmente foi o windows. Usa o comando dos2unix nome_do_script.

3 - Caso seja preciso libertar o ip para a máquina cliente pedir um novo ao server, usa estes comando:

Windows: 

         ipconfig /release -> liberta o ip que tem 
        
         ipconfig /renew -> pede um ip novo ao servidor dhcp

Linux: 

       sudo dhclient -r [interface] -> liberta o ip que tem
       
       sudo dhclient [interface] -> pede um ip novo ao servidor dhcp 

