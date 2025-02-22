# Example usage :

Start by copying and editing the `secretvars` example file 

```bash
cp ./secrets/secretvars.example.tf ./secrets/secretvars.tf
```

Then download a service account key with the rôle "Project IAM Admin" in the secrets directory. And edit the `main.tf` to reference it.

```terraform
# main.tf

provider "google" {
  credentials = file("./secrets/<NAME_OF_SERVICE_ACCOUNT_KEY.json>") # Change this line
  project     = var.project_id
  region      = "europe-west1" # Chose your region
}

```

```bash

tofu init
tofu plan --var-file ./secrets/secretvars.tf
tofu apply --var-file ./secrets/secretvars.tf
```
