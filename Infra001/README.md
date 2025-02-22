# Example usage :

Start by copying and editing the `secretvars` example file 

```bash
cp ./secrets/secretvars.example.tf ./secrets/secretvars.tf
```

Then download a service account key in the secrets directory. Make sure it has the following roles  :
 - Compute Admin
 - Compute Instance Admin (v1)

Then edit the `main.tf` to reference it.

```terraform
# main.tf

provider "google" {
  credentials = file("./secrets/credentials.json") # Change this line
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

```
Then use the following commands :

```bash

tofu init
tofu plan --var-file ./secrets/secretvars.tf
tofu apply --var-file ./secrets/secretvars.tf
```

To output the IPs of the created machines :

```bash
tofu output master_nodes
tofu output worker_nodes

```

