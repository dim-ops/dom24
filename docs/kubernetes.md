# Commandes Essentielles Kubernetes (kubectl)

## Commandes de base

### `kubectl get`
- Affiche les ressources du cluster
- Utilisations courantes :
  - `kubectl get pods` : liste des pods
  - `kubectl get nodes` : liste des nœuds
  - `kubectl get services` : liste des services
  - `kubectl get all` : toutes les ressources
- Options importantes :
  - `-o wide` : affiche plus d'informations
  - `-o yaml` : sortie en format YAML
  - `-o json` : sortie en format JSON
  - `-n namespace` : spécifie le namespace
  - `--all-namespaces` ou `-A` : tous les namespaces

### `kubectl describe`
- Affiche les détails d'une ressource
- Très utile pour le debugging
- Exemples :
  - `kubectl describe pod mon-pod`
  - `kubectl describe node mon-node`
  - `kubectl describe service mon-service`

### `kubectl logs`
- Affiche les logs d'un pod
- Options utiles :
  - `-f` : suit les logs en temps réel
  - `--previous` : logs du conteneur précédent
  - `-c container-name` : logs d'un conteneur spécifique
- Exemple : `kubectl logs mon-pod -f`

## Gestion des déploiements

### `kubectl apply`
- Applique une configuration depuis un fichier
- Crée ou met à jour des ressources
- Exemples :
  - `kubectl apply -f deployment.yaml`
  - `kubectl apply -f ./mon-dossier`
  - `kubectl apply -k .` (avec kustomize)

### `kubectl delete`
- Supprime des ressources
- Utilisations :
  - `kubectl delete pod mon-pod`
  - `kubectl delete -f deployment.yaml`
  - `kubectl delete deployment mon-deployment`

### `kubectl rollout`
- Gère les déploiements
- Commandes principales :
  - `kubectl rollout status deployment/mon-app`
  - `kubectl rollout history deployment/mon-app`
  - `kubectl rollout undo deployment/mon-app`
  - `kubectl rollout restart deployment/mon-app`

## Commandes d'interaction

### `kubectl exec`
- Exécute une commande dans un conteneur
- Options courantes :
  - `-it` : mode interactif
  - `-c container-name` : spécifie le conteneur
- Exemple : `kubectl exec -it mon-pod -- /bin/bash`

### `kubectl cp`
- Copie des fichiers entre pod et système local
- Syntaxe : `kubectl cp <pod>:/chemin/source /chemin/destination`
- Exemple : `kubectl cp mon-pod:/var/log/app.log ./local.log`

### `kubectl port-forward`
- Crée un tunnel entre port local et port du pod/service
- Exemple : `kubectl port-forward service/mon-service 8080:80`

## Gestion du contexte

### `kubectl config`
- Gère la configuration kubectl
- Commandes utiles :
  - `kubectl config current-context`
  - `kubectl config use-context mon-context`
  - `kubectl config get-contexts`
  - `kubectl config set-context --current --namespace=mon-namespace`

## Debugging et troubleshooting

### `kubectl debug`
- Crée un pod de debugging
- Utile pour investiguer des problèmes
- Exemple : `kubectl debug node/mon-node -it --image=ubuntu`

### `kubectl top`
- Affiche les métriques d'utilisation
- Requiert metrics-server
- Utilisations :
  - `kubectl top pods`
  - `kubectl top nodes`

### `kubectl cordon/uncordon`
- Marque un nœud comme non-schedulable/schedulable
- Utile pour la maintenance
- Exemple : `kubectl cordon mon-node`

### `kubectl drain`
- Vide un nœud de ses pods
- À utiliser avant maintenance
- Exemple : `kubectl drain mon-node --ignore-daemonsets`

## Commandes avancées

### `kubectl diff`
- Montre les différences entre l'état actuel et un fichier
- Exemple : `kubectl diff -f deployment.yaml`

### `kubectl scale`
- Change le nombre de réplicas
- Exemple : `kubectl scale deployment mon-app --replicas=3`

### `kubectl taint`
- Ajoute/supprime des taints sur les nœuds
- Influence le scheduling des pods
- Exemple : `kubectl taint nodes mon-node key=value:NoSchedule`

## Bonnes pratiques

1. **Utilisation des namespaces**
   - Organiser les ressources
   - Isoler les environnements
   - `kubectl create namespace mon-namespace`

2. **Labels et sélecteurs**
   - Utiliser des labels pertinents
   - Faciliter le filtrage et l'organisation
   - `kubectl get pods -l app=mon-app`

3. **Gestion des contextes**
   - Bien organiser les fichiers kubeconfig
   - Vérifier régulièrement le contexte actif

4. **Monitoring et logging**
   - Surveiller régulièrement les ressources
   - Centraliser les logs
   - Mettre en place des alertes

5. **Sécurité**
   - Utiliser RBAC
   - Limiter les privilèges
   - Scanner les images régulièrement

## Alias utiles

```bash
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ka='kubectl apply -f'
alias kns='kubectl config set-context --current --namespace'
```
