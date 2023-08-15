# k8s-kubeadm-terraform-ansible-cluster

Deploying K8s cluster on EC2

*NOTE: Only compatible with `Ubuntu 22.04`*

Pre-requisites to run the repo:
1) Terraform installed on local machine
2) AWS CLI setup or access and secret key
3) Ansible installed on local machine
4) Then run the below commands:

`terraform init`

`terraform plan`

`terraform apply --auto-approve`

`chmod 400 private-key.pem`

`sudo ansible-playbook -u ubuntu -i ./k8s_nodes.yaml --private-key private-key.pem playbooks/k8s_dependency_playbook.yml`

`sudo ansible-playbook -u ubuntu -i ./k8s_nodes.yaml --private-key private-key.pem playbooks/k8s_master_playbook.yml`

`sudo ansible-playbook -u ubuntu -i ./k8s_nodes.yaml --private-key private-key.pem playbooks/k8s_worker_playbook.yml`


Note: To change the number of workers, go to variables.tf file and change the dafault value of `worker_nodes_count` to number of workers you want

Note: run the last commented task in k8s_master_playbook.yml if kubectl commands does not work using ansible.
