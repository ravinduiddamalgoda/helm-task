🛠️ 1. Navigate to Core Services Directory

cd terragrunt/live/envs/core-services/

🔐 2. Export Required Environment Variables

export DOPPLER_TOKEN="dp.pt.uExBWewpWyPprCdXLombA8TAMJdvPs9Cf3igywuo9KY"
export DOPPLER_SERVICE_TOKEN="dp.st.dev.F5mkxW6Bwm8jMriOnN4rWD6kFIisIqIGFitEfjlQxZW"
export TAILSCALE_AUTH_KEY="tskey-auth-kU92wsCTnE11CNTRL-B3wEFVYdB6WCcWFyiuZ56WBnj45tGYgpb"
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

export DOPPLER_SERVICE_TOKEN="dp.st.dev.F5mkxW6Bwm8jMriOnN4rWD6kFIisIqIGFitEfjlQxZW"
export OCI_USERNAME=""
export OCI_PASSWORD=""
export OCI_EMAIL=""

📦 Helm Deployment Commands

helm dependency update
make lint ENV=staging
make template ENV=staging
make install ENV=staging



