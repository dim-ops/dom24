# Guide Pluto pour la Préparation des Upgrades Kubernetes

> ⚠️ **Attention** : Chaque montée de version est différente, il faut donc prendre en compte la documentation fournie par AWS. Cette procédure recense les étapes communes à chaque upgrade. Il est recommandé de réaliser les montées de versions une par une.

## Mise à jour des addon EKS

Avant de débuter l'upgrade du cluster EKS, veuillez vérifier que les addons sont bien déployés avec la dernière version disponible pour votre version Kubernetes actuelle. Si ce n'est pas le cas, je vous encourage à monter les versions dans le fichiers __terraform/<env>/20_eks/main.tf__.

```h
module "eks" {
  [...]
  cluster_addons = {
    amazon-cloudwatch-observability = {
      most_recent              = true
      addon_version            = "v2.6.0-eksbuild.1"
      service_account_role_arn = module.cloudwatch_irsa_role.iam_role_arn
    }
    aws-ebs-csi-driver = {
      most_recent              = false
      addon_version            = "v1.37.0-eksbuild.1"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
    coredns = {
      most_recent   = false
      addon_version = "v1.11.4-eksbuild.1"
    }
    kube-proxy = {
      most_recent   = false
      addon_version = "v1.31.3-eksbuild.2"
    }
    vpc-cni = {
      most_recent   = false
      addon_version = "v1.19.2-eksbuild.1"
    }
  }
  [...]
}
```

Les commandes pour vérifier la dernière version disponible:

```bash
aws eks describe-addon-versions \
--kubernetes-version <kubernetes-version-actuelle> \
--addon-name coredns | jq '.addons[].addonVersions[0].addonVersion'
```

```bash
aws eks describe-addon-versions \
--kubernetes-version <kubernetes-version-actuelle> \
--addon-name kube-proxy | jq '.addons[].addonVersions[0].addonVersion'
```

```bash
aws eks describe-addon-versions \
--kubernetes-version <kubernetes-version-actuelle> \
--addon-name aws-ebs-csi-driver | jq '.addons[].addonVersions[0].addonVersion'
```

```bash
aws eks describe-addon-versions \
--kubernetes-version <kubernetes-version-actuelle> \
--addon-name amazon-cloudwatch-observability | jq '.addons[].addonVersions[0].addonVersion'
```

```bash
aws eks describe-addon-versions \
--kubernetes-version <kubernetes-version-actuelle> \
--addon-name vpc-cni | jq '.addons[].addonVersions[0].addonVersion'
```

## Mise à jour d'AWS Load Balancer Controller

Vous devez également mettre à jour la version AWS Load Balancer Controller. Vous pouvez trouver la dernière version grâce aux commandes suivantes:

```bash
helm repo add "eks" "https://aws.github.io/eks-charts"
helm repo update
helm search repo eks/aws-load-balancer-controller
```

Vous devez prendre la version inscrite dans la colonne **CHART VERSION** et l'inscrire dans __terraform/<env>/20_eks__, puis faire un __terraform init__ & __terraform apply__.

```h
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = "1.11.0" <--
  namespace  = "kube-system"
  [...]
}
```

## Qu'est-ce que Pluto ?

Pluto est un outil qui aide à détecter les ressources API obsolètes dans vos clusters Kubernetes. Son utilité principale est de faciliter les mises à niveau de clusters en identifiant les potentiels problèmes de compatibilité avant qu'ils ne surviennent.

## Pourquoi utiliser Pluto ?

1. **Prévention des problèmes**
   - Identifie les APIs dépréciées avant la mise à niveau
   - Évite les pannes liées aux ressources incompatibles
   - Permet une planification proactive des mises à jour nécessaires

2. **Gain de temps**
   - Analyse automatique des manifests
   - Détection rapide des problèmes potentiels
   - Réduction du temps de debugging post-upgrade

3. **Sécurité**
   - Assure que vous n'utilisez pas d'APIs obsolètes
   - Aide à maintenir votre cluster à jour
   - Réduit les risques lors des upgrades

## Commandes Essentielles

### Détection des Ressources API

```bash
# Analyser les ressources API dans le cluster actif
pluto detect-api-resources -v <kubernetes-version-cible>

# Avec plus de détails
pluto detect-api-resources -v <kubernetes-version-cible> --output wide
```

### Analyse des Fichiers Locaux

```bash
# Analyser un répertoire de manifests
pluto detect-files -d /chemin/vers/manifests/ -v <kubernetes-version-cible>

# Analyser un fichier spécifique
pluto detect-files -f manifest.yaml -v <kubernetes-version-cible>
```

### Analyse des Charts Helm

```bash
# Analyser toutes les releases Helm
pluto detect-helm -v <kubernetes-version-cible>

# Analyser une release spécifique
pluto detect-helm --release-name ma-release -v <kubernetes-version-cible>

# Analyser un namespace spécifique
pluto detect-helm --namespace mon-namespace -v <kubernetes-version-cible>
```

### Gestion des Versions

```bash
# Lister les versions d'API et leur statut
pluto list-versions

# Vérifier une version spécifique de Kubernetes
pluto list-versions --kubernetes-version <kubernetes-version-actuelle>
```

## Options Utiles

### Formats de Sortie

```bash
# Format détaillé
pluto detect-api-resources --output wide

# Sortie JSON pour intégration CI/CD
pluto detect-api-resources --output json

# Sortie YAML
pluto detect-api-resources --output yaml
```

### Filtrage et Contrôle

```bash
# Ignorer les dépréciations
pluto detect-api-resources --ignore-deprecations

# Cibler une version spécifique
pluto detect-api-resources -v <kubernetes-version-cible> --target-versions k8s=v<kubernetes-version-actuelle>
```

Avec les informations fournies par **Pluto** vous serez en capacité de savoir si vos applicatifs (Wazuh, Shuffle...) seront impactés par l'upgrade. Si c'est le cas, vous devez montée la version de vos charts helm afin d'éviter tout désagrément.

## Montée de version EKS

Maintenant que vous êtes assurés qu'il n'y aura pas d'inter compatibilité entre vos applicatifs et la nouveau version du cluster Kubernetes, vous pouvez procédez à la montée de version.

Pour cela vous devez modifier la version EKS présente dans le fichier __terraform/<env>/20_eks__:

```h
module "eks" {
  [...]
  cluster_version = "1.31" <--
  [...]
}
```

## Mise à jour des addon EKS vers la version cible

Pour terminer, vous devez réaliser la même étape que l'étape numéro 1 mais en spécifiant la nouvelle version du cluster.
