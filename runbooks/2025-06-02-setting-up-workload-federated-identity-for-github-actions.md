This is a very rough sequence of steps that I used to setup
Workload Federated Identity on GCP so that Github Actions can authenticate without having to store secrets.

gcloud iam workload-identity-pools delete "kgcash-identity-pool" --location="global"

# CREATE A WORKLOAD IDENTITY POOL AND PROVIDER FOR GITHUB ACTIONS
gcloud iam workload-identity-pools create "kgcash-identity-pool-github" \
  --project="kgcash-176905" \
  --location="global" \
  --display-name="kgcash ID pool"

# CREATE A WORKLOAD IDENTITY PROVIDER FOR GITHUB ACTIONS
gcloud iam workload-identity-pools providers create-oidc "kgcash-identity-provider" \
  --project="kgcash-176905" \
  --location="global" \
  --workload-identity-pool="kgcash-identity-pool-github" \
  --display-name="kgcash ID provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
  --attribute-condition="assertion.repo=='geordie/kgcash' && assertion.ref=='refs/heads/main'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

gcloud iam workload-identity-pools providers update-oidc "kgcash-identity-provider" \
  --project="kgcash-176905" \
  --location="global" \
  --workload-identity-pool="kgcash-identity-pool-github" \
  --display-name="kgcash ID provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
  --attribute-condition="assertion.sub=='repo:geordie/kgcash:ref:refs/heads/main'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# ADD THE GITHUB ACTIONS SERVICE ACCOUNT TO THE WORKLOAD IDENTITY PROVIDER
gcloud iam service-accounts add-iam-policy-binding "kgcash-github-actions@kgcash-176905.iam.gserviceaccount.com" \
  --role="roles/iam.workloadIdentityUser" \                                                                                                 repo:geordie/kgcash:ref:refs/heads/main
  --member="principal://iam.googleapis.com/projects/567189324080/locations/global/workloadIdentityPools/kgcash-identity-pool-github/subject/repo:geordie/kgcash:ref:refs/heads/main"


# LIST THE WORKLOAD IDENTITY POOL PROVIDERS
gcloud iam workload-identity-pools providers list \
  --location="global" \
  --workload-identity-pool="kgcash-identity-pool-github"

---------------

# ADD THIS TO THE GITHUB ACTIONS WORKFLOW

steps:
- id: 'auth'
  name: 'Authenticate to Google Cloud'
  uses: 'google-github-actions/auth@v0.4.0'
  with:
    workload_identity_provider: 'projects/567189324080/locations/global/workloadIdentityPools/kgcash-identity-pool/attribute.repository/geordie/kgcash'
    service_account: 'gcp-auth-for-github-action@kgcash-176905.iam.gserviceaccount.com'

- id: get-gke-credentials
  uses: google-github-actions/get-gke-credentials@v0.4.0
  with:
    cluster_name: my-cluster
    location: us-central1-a


    Kubernetes Engine Cluster Admin
    Container Registry Service Agent