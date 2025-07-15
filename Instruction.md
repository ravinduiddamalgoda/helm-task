🛠️ 1. Navigate to Core Services Directory

cd terragrunt/live/envs/core-services/

🔐 2. Export Required Environment Variables


export BASTION_SSH_KEY="$HOME/.ssh/oci_bastion_ed25519"

🚀 3. Apply Terragrunt to Create Core Infrastructure

terragrunt run-all apply

This command will provision the following resources:

    Network
    Bastion Host
    Operator Node
    Kubernetes Cluster


🧩 4. Apply Additional Terragrunt Modules

▶️ Database

cd ../database
terragrunt apply

🔐 Security

cd ../security
terragrunt apply

🌐 Load Balancer

cd ../loadbalancer
terragrunt apply


⛵ 5. Deploy Services Using Helm

🔄 Change Directory
cd helm/

Install the Knative Serving component

kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.18.1/serving-crds.yaml
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.18.1/serving-core.yaml

📦 Helm Deployment Commands

helm dependency update
make lint ENV=staging
make template ENV=staging
make install ENV=staging



