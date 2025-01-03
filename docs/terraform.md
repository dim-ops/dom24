# Commandes Essentielles Terraform

## Commandes d'initialisation et de configuration

### `terraform init`
- Initialise un environnement de travail Terraform
- Télécharge les providers nécessaires
- Initialise le backend pour le state
- À exécuter après chaque modification des providers ou du backend
- Peut être utilisé avec `-upgrade` pour mettre à jour les providers

### `terraform fmt`
- Reformate les fichiers de configuration selon le style standard Terraform
- Très utile pour maintenir une cohérence dans les équipes
- Peut être utilisé avec `-recursive` pour formater tous les sous-répertoires
- Option `-check` pour vérification dans les CI/CD

### `terraform validate`
- Vérifie la syntaxe et la cohérence interne des fichiers de configuration
- Ne nécessite pas d'accès aux providers ou à l'infrastructure
- Idéal dans les pipelines CI/CD pour la validation rapide
- Ne vérifie pas les valeurs des variables

## Commandes de planification et d'exécution

### `terraform plan`
- Montre les changements qui seront appliqués
- Crée un plan d'exécution détaillé
- Options importantes :
  - `-out=plan.tfplan` : sauvegarde le plan dans un fichier
  - `-var-file=prod.tfvars` : spécifie un fichier de variables
  - `-target=aws_instance.example` : plan pour une ressource spécifique

### `terraform apply`
- Applique les changements planifiés à l'infrastructure
- Peut être utilisé avec un fichier plan : `terraform apply plan.tfplan`
- Options importantes :
  - `-auto-approve` : skip la validation manuelle (à utiliser avec précaution)
  - `-backup=path` : spécifie où sauvegarder le state avant modification

### `terraform destroy`
- Détruit toutes les ressources gérées par Terraform
- Très dangereux en production !
- Options importantes :
  - `-target` : détruit une ressource spécifique
  - `-auto-approve` : skip la validation (à utiliser avec extrême précaution)

## Commandes de gestion d'état

### `terraform state list`
- Liste toutes les ressources dans le state
- Utile pour vérifier ce qui est géré par Terraform

### `terraform state show [ressource]`
- Montre les détails d'une ressource spécifique dans le state
- Pratique pour le debug ou la vérification des attributs

### `terraform state mv`
- Déplace une ressource dans le state
- Utile pour la réorganisation du code sans détruire/recréer les ressources
- Exemple : `terraform state mv aws_instance.old aws_instance.new`

### `terraform import`
- Importe une ressource existante dans le state Terraform
- Permet de commencer à gérer des ressources créées manuellement
- Exemple : `terraform import aws_instance.web i-1234567890abcdef0`

## Commandes de workspace

### `terraform workspace list/new/select/delete`
- Gère les workspaces (environnements séparés)
- Utile pour gérer dev/staging/prod
- Permet d'avoir des states séparés pour différents environnements
- Exemple : `terraform workspace new dev`

## Commandes de Debug et Maintenance

### `terraform console`
- Ouvre une console interactive
- Permet de tester des expressions et des fonctions
- Très utile pour le debug des interpolations complexes

### `terraform refresh`
- Met à jour le state avec l'état réel de l'infrastructure
- À utiliser avec précaution car peut causer des dérives
- Préférer `terraform plan` qui fait un refresh automatique

### `terraform output`
- Affiche les outputs définis dans la configuration
- Peut être utilisé avec `-json` pour un format parseable
- Utile pour les scripts et l'intégration avec d'autres outils

## Bonnes Pratiques

1. **Toujours faire un plan avant apply**
   - Vérifier attentivement les changements proposés
   - Sauvegarder les plans importants

2. **Utiliser les workspaces**
   - Séparer les environnements
   - Éviter les modifications accidentelles

3. **Gestion du state**
   - Toujours utiliser un backend distant
   - Versionner le state
   - Faire des backups réguliers

4. **Automatisation**
   - Intégrer `fmt` et `validate` dans les pre-commit hooks
   - Utiliser `plan` dans les pull requests
   - Automatiser les tests avec `terraform test`
