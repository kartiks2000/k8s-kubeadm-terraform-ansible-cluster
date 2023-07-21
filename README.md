# k8s-kubeadm-terraform-ansible-cluster
k8s-kubeadm-terraform-ansible-cluster

Pre-requisites to run the repo:
1) Terraform installed on local machine
2) AWS CLI setup or excess and secret key
3) Ansible installed on local machine
4) Once ansible is installed, install (ansible-galaxy collection install cloud.terraform)
https://galaxy.ansible.com/cloud/terraform
5) Then run the below commands:
terraform init
terraform plan
terraform apply
6) Once the repo is completely run and the above steps are also completed, run the play booking using:
sudo ansible-playbook -i inventory.yml playbook.yml


Once you run the repo, use can use below commands for your help:
1) to see the ansible inventory (ansible hosts)
ansible-inventory -i inventory.yml --graph 


chmod 400 private-key.pem
sudo ansible-playbook -u ubuntu -i ./inventories/k8s_nodes  --private-key private-key.pem playbooks/k8s_dependency_playbook.yml
sudo ansible-playbook -u ubuntu -i ./inventories/control_node_inventory  --private-key private-key.pem playbooks/k8s_master_playbook.yml
sudo ansible-playbook -u ubuntu -i ./inventories/worker_node_inventory  --private-key private-key.pem playbooks/k8s_worker_playbook.yml
