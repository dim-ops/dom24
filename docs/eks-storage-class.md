# Storage Classes Kubernetes

## Qu'est-ce qu'une Storage Class ?

Une Storage Class est une ressource Kubernetes qui permet de définir différentes classes de stockage disponibles dans un cluster. Elle agit comme un template pour provisionner dynamiquement des volumes persistants (PV) selon des paramètres prédéfinis.

Les Storage Classes permettent aux administrateurs de définir différents niveaux de stockage avec des caractéristiques spécifiques comme :
- Le type de stockage (SSD, HDD, etc.)
- Les performances
- La politique de rétention
- Le mode de provisionnement
- Le chiffrement

## Storage Classes Disponibles

Dans notre infrastructure, nous avons défini deux Storage Classes utilisant AWS EBS GP3 :

### 1. ebs-gp3 (Storage Class par défaut)

```yaml
storageClassName: ebs-gp3
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
  encrypted: "true"
```

Caractéristiques principales :
- **Storage Class par défaut** : Utilisée automatiquement si aucune Storage Class n'est spécifiée
- **Politique de récupération** : Delete (le volume est supprimé automatiquement avec le PVC)
- **Mode de binding** : WaitForFirstConsumer (le volume est créé uniquement lorsqu'un pod le demande)
- **Type** : GP3 (SSD à usage général d'AWS)
- **Chiffrement** : Activé

### 2. ebs-gp3-retain

```yaml
storageClassName: ebs-gp3-retain
provisioner: ebs.csi.aws.com
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
  encrypted: "true"
```

Identique à ebs-gp3, mais avec une politique de rétention différente :
- **Politique de récupération** : Retain (le volume persiste même après la suppression du PVC)

## Quand utiliser quelle Storage Class ?

### ebs-gp3 (par défaut)
Utilisez cette Storage Class pour :
- Les données temporaires ou reconstituables
- Les environnements de développement
- Les cas où vous voulez une gestion automatique du cycle de vie des volumes
- Les applications stateful qui ne nécessitent pas de conserver les données après leur suppression

Exemple d'utilisation :
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mon-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  # storageClassName: ebs-gp3  # Optionnel car c'est la classe par défaut
```

### ebs-gp3-retain
Utilisez cette Storage Class pour :
- Les données critiques qui doivent survivre à la suppression du PVC
- Les bases de données de production
- Les données qui nécessitent une sauvegarde ou une analyse post-mortem
- Les environnements de production où la perte accidentelle de données doit être évitée

Exemple d'utilisation :
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mon-pvc-critique
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ebs-gp3-retain  # Spécification explicite nécessaire
```

## Points importants à noter

1. **Volume Binding Mode** : Le mode `WaitForFirstConsumer` est utilisé dans les deux cas pour optimiser le placement des pods et des volumes dans la même zone de disponibilité.

2. **Chiffrement** : Tous les volumes sont chiffrés par défaut pour assurer la sécurité des données.

3. **Gestion des volumes "Retain"** :
   - Les volumes créés avec `ebs-gp3-retain` doivent être nettoyés manuellement après la suppression du PVC
   - Ces volumes persistent dans AWS et continuent d'être facturés
   - Il est recommandé de mettre en place un processus de gestion des volumes retenus

4. **Considérations de coût** :
   - Les volumes GP3 sont facturés selon leur taille et leurs performances
   - Pensez à nettoyer régulièrement les volumes inutilisés, particulièrement ceux avec la politique "Retain"
