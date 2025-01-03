# Recherche de logs dans CloudWatch pour un namespace EKS

## Via l'interface graphique (Console AWS)

1. Connectez-vous à la console AWS
2. Allez dans le service **CloudWatch**
3. Dans le menu de gauche, cliquez sur **Logs > Log insights**
4. Sélectionnez le(s) groupe(s) de logs de votre cluster EKS
5. Copiez-collez une des requêtes ci-dessous dans l'éditeur de requêtes

## Requêtes disponibles

### Logs basiques d'un namespace
```
fields @timestamp, @message
| filter kubernetes.namespace_name == "votre-namespace"
| sort @timestamp desc
```

### Logs détaillés avec informations des conteneurs
```
fields @timestamp, @message, kubernetes.container_name, kubernetes.pod_name
| filter kubernetes.namespace_name == "votre-namespace"
| sort @timestamp desc
| limit 1000
```

### Logs d'erreurs uniquement
```
fields @timestamp, @message
| filter kubernetes.namespace_name == "votre-namespace"
| filter @message like /(?i)(error|exception|fail)/
| sort @timestamp desc
```

### Logs d'un pod spécifique
```
fields @timestamp, @message
| filter kubernetes.namespace_name == "votre-namespace"
| filter kubernetes.pod_name like "nom-du-pod"
| sort @timestamp desc
```

> **Note**: Remplacez "votre-namespace" par le nom réel de votre namespace.
