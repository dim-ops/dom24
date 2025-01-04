# Projet DOM24

Cette documentation explique comment déployer l'infrastructure AWS pour le projet **DOM24**.

Voici l'architecture cible:

![AWS Architecture](/docs/images/architecture.png)

## Région AWS

Le choix de la région est important, car il va impacter les coûts ainsi que l'expérience utilisateur. Par défaut, toutes les régions ne sont pas activées.

Si vous souhaitez en activer d'autres, veuillez vous rendre [ici](https://us-east-1.console.aws.amazon.com/billing/home?region=eu-west-1#/account?AWS-Regions). L'activation peut prendre quelques minutes.

> ⚠️ **Attention** : Cette action ne peut être effectuée uniquement par l'utilisateur root du compte

## Création d'utilisateurs pour chaque membre de l'équipe.

La première étape a été réalisée avec le **compte root du AWS**, car vous n'aviez pas le choix. Pour la suite, vous allez créer un utilisateur IAM pour continuer la procédure.

1. Rendez-vous dans le service IAM et dans la section Users:

![Étape 1](/docs/images/iam-user-0.png)

2. Créez l'utilisateur avec les paramètres suivants:

![Étape 2](/docs/images/iam-user-1.png)

3. Donnez les permissions Administrator à l'utilisateur:

> ⚠️ Attention : Beaucoup de permissions sont accordées, cela simplifie la procédure, mais il est judicieux de restreindre les permissions

![Étape 3](/docs/images/iam-user-2.png)

4. AWS vous affiche une dernière revue avant la création de l'utilisateur:

![Étape 4](/docs/images/iam-user-3.png)

5. L'utilisateur est désormais créé. N'oublier de copier et stocker dans un endroit sécurisé les informations pour se connecter à la console:

![Étape 5](/docs/images/iam-user-4.png)

6. Pour des raisons de sécurité, vous pouvez configurer un MFA:

![Étape 6](/docs/images/iam-user-5.png)

7. La dernière étape consiste à créer des access keys pour pouvoir interagir avec les APIs AWS:

![Étape 7](/docs/images/iam-user-6.png)

8. Sélectionnez CLI, puis créez les access keys:

![Étape 8](/docs/images/iam-user-7.png)

Vous pouvez désormais interagir avec AWS via le CLI et Terraform.

> ⚠️ **Attention** : Si l'entreprise vient à grandir ou souhaite passer des certifications de sécurité, la bonne pratique est de configurer une Organisation AWS avec un SSO. Cette étape peut être réalisée dans un second temps dans impact.

## Mise en place de Terraform

Je ne détaillerai pas comment fonctionne Terraform ici, mais voici [la documentation](https://spacelift.io/blog/terraform-tutorial#step-1-terraform-installation-and-setup) si vous êtes débutants.

Dans cette section, vous allez créer le bucket S3 qui contiendra vos **tfstate** ainsi que la base DynamoDB pour gérer les locks Terraform.

Pensez à faire un __aws configure__ afin de configurer des votre terminal pour executer des commandes via la ligne de commande terraform.

### 1. Création du backend Terraform

Comme l'infrastructure Terraform n'est pas encore en place, vous allez créer via les lignes de commandes ci-dessous le bucket S3 et la table DynamoDB.

Création du bucket S3 :
```bash
aws s3api create-bucket --bucket <bucket-name> --create-bucket-configuration LocationConstraint=<aws-region>
```

> ⚠️ **Attention** : le nom du bucket est unique chez AWS. Cela signifie que je ne peux pas avoir un bucket nommé s3-test si un autre utilisateur dans le monde a déjà pris ce nom.

Activation du versioning du bucket :
```bash
aws s3api put-bucket-versioning --bucket <bucket-name> --versioning-configuration Status=Enabled
```

Création de la table dynamoDB:
```bash
aws dynamodb create-table \
--table-name terraform-lock-table \
--attribute-definitions AttributeName=LockID,AttributeType=S \
--key-schema AttributeName=LockID,KeyType=HASH \
--billing-mode PAY_PER_REQUEST
```

Le **billing mode** signifie que vous serez facturé à la requête: 0 requête = 0€

À cette étape, vous avez tout ce qu'il faut pour commencer à utiliser Terraform.

Allez dans le répertoire __terraform/env/00_terraform_backend__.

Afin de respecter les bonnes pratiques d'**Infrastructure as Code**, vous allez réconcilier Terraform et votre infrastructure. Pour cela, vous allez réaliser des terraform import. Cette commande permet d'ajouter une ressource existante dans le tfstate.

```bash
terraform init
terraform import 'module.s3_bucket.aws_s3_bucket.this[0]' '<bucket-name>'
terraform import 'module.s3_bucket.aws_s3_bucket_versioning.this[0]' '<bucket-name>'
terraform import 'module.s3_bucket.aws_s3_bucket_public_access_block.this[0]' '<bucket-name>'
terraform import 'aws_dynamodb_table.terraform_lock' 'terraform-lock-table'
```

A cete étape, vous devriez avoir quelques changements en attente, car nous n'avons pas de spécifier les tags dans nos commandes CLI. Vous pouvez faire un __terraform apply__ afin de les ajouter.

Vous devriez avoir cette sortie quand vous exécutez la commande. __terraform plan__:
```No changes. Your infrastructure matches the configuration.```

## Création du VPC (Virtual Private Cloud)

Vous pouvez vous attaquer à la création du réseau AWS.

Dans un premier temps, je vous invite manuellement à supprimer le VPC par défaut de votre région. Il ne vous servira pas.

Ensuite, rendez-vous dans le répertoire __terraform/env/10_vpc__.

Un **terraform apply** suffira à créer toute l'infrastructure réseau.

Vous créez:
- 1 VPC
- 1 Internet Gateway (trafic entrant)
- 1 Nat Gateway (trafic sortant)
- 2 subnets publics (pour les load balancers)
- 2 subnets privés (pour noeuds EKS)
- 1 route table publique
- 1 route table privée

Si demain vous souhaitez une architecture plus robuste afin avec 3 azs, voici le réseau que vous obtiendrez:
![VPC Architecture](/docs/images/vpc-0.png)

## Création du cluster EKS (Elastic Kubernetes Service)

Vous pouvez enchaîner avec la création du cluster en réalisant un __terraform apply__ dans le layer __terraform/env/20_eks__. Pour rappel, le choix a été fait de partir sur **EKS auto-mode**, ce qui permet de ne pas se soucier de la gestion des nœuds par [Karpenter](https://karpenter.sh/) qui est **préinstallé**.

Pour vous connecter au cluster, vous devez récupérer le kubeconfig:

```bash
aws eks update-kubeconfig --region <aws-region> --name main --alias dom24-<env>
```

Vous pouvez valider que tout fonctionne avec la commande suivante:

```bash
kubectl get nodes
```

Si ce n'est pas fait, installez helm et executez les commandes:

```bash
helm repo add "eks" "https://aws.github.io/eks-charts"
helm repo update
```

Ce

## Création des Load Balancers & Storage Class

Dans le layer __terraform/env/25_eks_addons__, vous allez créer les storage classes essentielles pour pouvoir utiliser EBS avec EKS.

Pour en savoir plus sur les storage policies, vous pouvez lire cette [documentation](docs/eks-storage-class.md).

Le AWS Load Balancer Controller est un contrôleur Kubernetes qui permet de **créer et gérer automatiquement des ressources AWS (comme les ALB et NLB) directement depuis votre cluster Kubernetes** en interprétant les Ingress et Services que vous définissez.

Il vous suffira de faire un __terraform apply__.

## Déploiement applicatif

Désormais, votre environnement est prêt à héberger un applicatif dans EKS !

### Utilisation d'une storage class

```yaml
opensearch:
  persistence:
    enabled: true
    storageClass: "ebs-gp3-retain"
    size: 8Gi
```

## Utilisation d'AWS Load Balancer controler

Depuis un déploiement Helm, vous êtes en capacité de déployer un nouvel ALB (Application Load Balancer) en ajoutant des annotations au niveau de l'ingress:

```yaml
ingress:
  web:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: "alb"
      alb.ingress.kubernetes.io/scheme: "internet-facing"
      alb.ingress.kubernetes.io/target-type: "ip"
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/ssl-redirect: "443"
      alb.ingress.kubernetes.io/group.name: "test"
    path: "/"
    pathType: "Prefix"
    hosts:
      - name: "airflow.example.com"
        tls:
          enabled: true
          secretName: "airflow-tls-cert"
    ingressClassName: "alb"
```

Un exemple dans le répertoire __tests/load-balancer-controller.yaml__ vous est fourni. Il vous suffit de faire un __kubectl apply -f load-balancer-controller.yaml__ pour déployer deux Nginx se partageant un unique ALB.

La même chose est possible avec les NLB (Network Load Balancer). Vous pouvez en apprendre davantage en suivant la [doc officielle](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.11/).

## Création du WAF

Voici la dernière section de la procédure d'installation de l'architecture. Ici, vous allez créer une whitelist IP pour chaque application afin de restreindre les accès.

Pour cela, vous devez spécifier les **IPv4** et **IPv6** que vous souhaitez whitelister pour chaque application.

```h
  applications = {
    app1 = {
      path     = "/app1"
      ipv4_ips = ["1.2.3.4/32"]
      ipv6_ips = []
      priority = 1
    }
    app2 = {
      path     = "/app2"
      ipv4_ips = ["1.2.3.4/32", "1.2.3.5/32"]
      ipv6_ips = [
        "2a01:cb14:e53:3c00:e89a:ab8a:dce6:f6c2/128",
        "2a01:cb09:d04a:a09b:0:59:f258:ea01/128"
      ]
      priority = 2
    }
  }
```

Vous pouvez désormais tester l'accès à vos applications **HTTP/HTTPS**.

## Pistes d'amélioration

- Mise en place d'une [organisation AWS](https://docs.aws.amazon.com/organizations/latest/userguide/pricing.html) + SSO pour l'authentification
- Mise en place d'un CICD pour le déploiement, les montées de versions (Renovate)...
- Mise en place du DNS
- Mise en place d'un [VPN](https://docs.aws.amazon.com/fr_fr/vpc/latest/userguide/vpn-connections.html) entre l'architecture du client et la votre
- Mise en place d'un [VPN](https://docs.aws.amazon.com/fr_fr/vpc/latest/userguide/vpn-connections.html) pour accèder à l'API de votre EKS
- Externaliser les bases de données en dehors du cluster EKS (Backup, réplication...)

## Annexes

[Introduction à Terraform](https://spacelift.io/blog/terraform-tutorial#step-1-terraform-installation-and-setup)
[Mise en place de Terraform](https://medium.com/@deepeshjaiswal6734/setting-up-terraform-with-s3-backend-and-dynamodb-locking-1e4b69e0b3cd)
[Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)
[Terraform Module S3](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest)
[Terraform Module EKS](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
[Terraform Module VPC](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
[AWS Organisation](https://docs.aws.amazon.com/organizations/latest/userguide/pricing.html)
[EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
[AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.11/)

