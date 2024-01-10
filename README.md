# ATIVIDADE AWS DOCKER PB COMPASSUOL

# Objetivo:
![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/4f041453-b9d2-4e3f-96f3-8d75b946fffb)

1. instalação e configuração do DOCKER
ou CONTAINERD no host EC2;
Ponto adicional para o trabalho utilizar
a instalação via script de Start Instance
(user_data.sh)

2. Efetuar Deploy de uma aplicação
Wordpress com:
container de aplicação
RDS database Mysql

3. configuração da utilização do serviço
EFS AWS para estáticos do container
de aplicação Wordpress

4. configuração do serviço de Load
Balancer AWS para a aplicação
Wordpress


# Passo 1 - Criação da VPC

- Devemos criar uma Rede VPC conforme mostra o mapa de rede a seguir:
![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/b1c7b2d0-4da7-4241-9b0a-fc286821c320)

- Pontos de atenção:
- Assegure-se de incluir a marcação do Nat Gateway durante o processo de criação automática da VPC. O Nat Gateway será utilizado para proporcionar conectividade à Internet para as instâncias privadas."

# Passo 2 - Criação dos Security Groups:

- Crie os Seguintes Security Groups:

- SG - Instancias EC2:
  
| Porta  | Origem |
| ------------- | ------------- |
| 80  | 0.0.0.0  |
| 22  | 0.0.0.0  |

- SG - EFS:
  
| Porta  | Origem |
| -----| -------- |
| 2049 | 0.0.0.0  |

- SG - RDS:
  
| Porta  | Origem |
| -----| -------- |
| 3306 | 0.0.0.0  |

- SG - ALB:
  
| Porta  | Origem |
| -----| -------- |
| 80  | 0.0.0.0  |


#  Passo 3 - Criação do EFS:
Crie um EFS personalizado, integrado à sua rede VPC, com a configuração de duas sub-redes públicas. Certifique-se de associar o respectivo Security Group do EFS a ambas as Az's durante o processo de criação.

![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/f9f0a912-0254-47e4-b9d9-dab07c177b13)

# Passo 4 - Criação do RDS:
- Crie um Banco de dados RDS no plano free tier e selecione o banco mysql:
![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/8a6750db-781d-4b37-a276-006dc361f32e)

- Defina seu master username
- Defina seu master password
![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/060584d4-01b8-4ea4-9f44-1d6920640aca)

- Selecione a VPC criada anteriormente
- Habilite o acesso publico do banco
- Selecione o Security Group criado para o rds anteriormente
![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/2a1d814a-3216-482c-b37f-70e683602563)

- Defina um nome inicial para o seu banco de dados Obs(guarde este nome, pois sera usado para conectar seu banco ao wordpress!)
![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/b588aafb-8b87-4411-b743-fa37034e5ae4)

- Crie o RDS

# Passo 4 - Criação do Template:

Crie um Template EC2 com as seguintes definições:
- Maquina Amazon Linux
- Tipo de instancia: t3.small
- Com o seguinte User data:

```
#!/bin/bash
sudo su
yum update -y
yum install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mv /usr/local/bin/docker-compose /bin/docker-compose
yum install nfs-utils -y
mkdir /mnt/efs/
chmod +rwx /mnt/efs/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ID_DO_SEU_EFS.efs.us-east-1.amazonaws.com:/ /mnt/efs
echo "ID_DO_SEU_EFS.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs defaults 0 0" >> /etc/fstab
echo "version: '3.3'
services:
  wordpress:
    image: wordpress:latest
    volumes:
      - /mnt/efs/wordpress:/var/www/html
    ports:
      - 80:80
    restart: always
    environment:
      WORDPRESS_DB_HOST: ENDPOINT DO SEU RDS
      WORDPRESS_DB_USER: MASTER USERNAME DO SEU RDS
      WORDPRESS_DB_PASSWORD: MASTER PASSWORD DO SEU RDS
      WORDPRESS_DB_NAME: INITIAL NAME DO SEU RDS
      WORDPRESS_TABLE_CONFIG: wp_" | sudo tee /mnt/efs/docker-compose.yml
cd /mnt/efs && sudo docker-compose up -d
```
- Copie o cliente do seu nfs e cole no userdata
- Copie o Endpoint + username + password + inital name do seu rds e cole no userdata

# Passo 5 - Criação do Target Group:
- Crie um Target Group com as seguintes definições:

- Tipo de destino: Instâncias
- Protocolo: http - porta 80
- Ipv4
- ![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/7dcec586-c859-454e-8c00-ad261a036cfa)

- Selecione a VPC Criada Anteriormente
  ![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/83766d9e-6640-49d4-8827-71f757c6bc3a)

- Não registre nenhuma instância por enquanto!
- Crie o Target Group

  # Passo 6 - Criação do Application Load Balancer
  - Crie um Application Load Balancer Com as seguintes definições:

  - Selecione A VPC criada anteriormente
  - Mapeie as duas Az's
  - Selecione as 2 Subnets publicas!!
   ![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/2bec8423-6d77-41be-b23f-65737cdd6de2)

  - Selecione como grupo de destino, o target group criado anteriormente em Listeners e Roteamento
  ![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/887bb695-b9ae-4b68-b9e4-2d9d3814d9fb)

  Crie o ALB

  # Passo 6 - Criação do Auto Scaling:
  - Crie um Auto Scaling com as Seguintes Definições:

  - Selecione o Template usado anteriormente
  ![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/6da11458-66c6-4a2b-9921-35061f6a7d40)

  - Selecione a VPC criada anteriormente
  - Selecione as 2 Subnets Privadas
  ![image](https://github.com/luizcortezdev/atividade_docker_aws/assets/141674600/324c17f6-afbb-4c58-9c2f-25bce558bb36)

  - Crie o Auto Scaling


