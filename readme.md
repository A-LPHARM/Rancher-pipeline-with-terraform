To help understand the repo 
here is all the commands and codes for using Rancher to create a pipeline and deploying with Terraform, Helm, and ArgoCD:

---

# Setting Up Infrastructure with Rancher, Terraform, Helm, and ArgoCD

## Setting Up Infrastructure

1. **Create Network on VM:**
   ```powershell
   Get-NetAdapter
   Import-Module Hyper-V
   $net = Get-NetAdapter -Name "Ethernet"
   New-VMSwitch -Name "virtual-network" -AllowManagementOS $True -NetAdapterName $net.Name
   ```

2. **Create Virtual Machines on Hyper-V:**
   ```powershell
   mkdir c:\temp\vms\linux-1\
   mkdir c:\temp\vms\linux-2\

   New-VHD -Path c:\temp\vms\linux-1\linux-1.vhdx -SizeBytes 20GB
   New-VHD -Path c:\temp\vms\linux-2\linux-2.vhdx -SizeBytes 20GB
   ```
the infrastructure

   ```
   New-VM `
   -Name "linux-1" `
   -Generation 1 `
   -MemoryStartupBytes 2048MB `
   -SwitchName "virtual-network" `
   -VHDPath "c:\temp\vms\linux-1\linux-1.vhdx" `
   -Path "c:\temp\vms\linux-1\"

   New-VM `
   -Name "linux-2" `
   -Generation 1 `
   -MemoryStartupBytes 2048MB `
   -SwitchName "virtual-network" `
   -VHDPath "c:\temp\vms\linux-2\linux-2.vhdx" `
   -Path "c:\temp\vms\linux-2\"
   ```

3. **Set Up DVD Drive for Ubuntu Server ISO:**
   ```powershell
   Set-VMDvdDrive -VMName "linux-1" -ControllerNumber 1 -Path "C:\temp\ubuntu-24.04-desktop-amd64.iso"
   Set-VMDvdDrive -VMName "linux-2" -ControllerNumber 1 -Path "C:\temp\ubuntu-24.04-desktop-amd64.iso"
   ```

4. **Start Virtual Machines:**
   ```powershell
   Start-VM -Name "linux-1"
   Start-VM -Name "linux-2"
   ```

## Initial Setup on Virtual Machines

5. **Install SSH on Virtual Machines:**
   ```bash
   sudo apt update
   sudo apt install -y nano net-tools openssh-server
   sudo systemctl enable ssh
   sudo ufw allow ssh
   sudo systemctl start ssh
   ```

6. **Install Docker on Virtual Machines:**
   ```bash
   curl -sSL https://get.docker.com/ | sh
   sudo usermod -aG docker $(whoami)
   sudo service docker start
   ```

7. **Start Rancher Server:**
   ```bash
   mkdir volume 
   sudo docker run -d --name rancher-server  -v ${PWD}/volume:/var/lib/rancher --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher
   ```

8. **Access Rancher UI:**
   - Wait for Rancher to start.
   - Extract the Rancher initial bootstrap password from the logs:
     ```bash
     sudo docker logs rancher-server
     ```

## Deploying with Terraform, Helm, and ArgoCD

9. **Install kubectl, Terraform, Helm, and ArgoCD on Virtual Machines.**

10. **Clone Repository:**
    ```bash
    git clone https://github.com/A-LPHARM/Rancher-pipeline-with-terraform.git
    ```
    Next is to copy the ~/.kube/config file from Rancher in linux-2 and send to Linux-2

    ```
    mkdir -p ~/.kube
    ```
    once the file is created in the .kube directory

    ```
    vi ~/.kube/config
    ``` 
    after adding the config file give the directory the specific rights

    ```
    chmod 600 ~/.kube/config
    ```

11. **Create ArgoCD Application with Terraform:**
    ```bash
    cd Rancher-pipeline-with-terraform/argo-helm
    terraform init
    terraform apply --auto-approve
    ```

12. **Access ArgoCD UI:**
    - Update the service type of ArgoCD server:
      ```bash
      kubectl patch svc argocd-server -n argocd -p \
        '{"spec": {"type": "NodePort", "ports": [{"name": "http", "nodePort": 30800, "port": 80, "protocol": "TCP", "targetPort": 8080}, {"name": "https", "nodePort": 30443, "port": 443, "protocol": "TCP", "targetPort": 8080}]}}'
      ```
    - Access ArgoCD UI with: `http://<ip_address>:30800`
    - Get the initial admin password:
      ```bash
      kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
      ```
13. **Log in to ArgoCD:**
    ```bash
    kubectl config set-context --current --namespace=argocd
    argocd login 44.204.119.208:30800
    ```

14. **Deploy the Development applications via kubectl**
    ```bash
    kubectl apply -f demo-dev/root.yaml
    ```

15. **Deploy Application with Helm Charts via ArgoCD:**
    ```bash
    argocd app create demo-app \
      --repo https://github.com/A-LPHARM/Rancher-pipeline-with-terraform.git \
      --path helmcharts/charttest1 \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace default \
      --sync-policy automated \
      --self-heal
      ```
