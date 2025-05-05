#!/bin/bash

display_menu() {
    echo "------- EKSCTL CLUSTER SETUP WITH EBS-CSI Addons --------
                - Cyclobold Connect --
                - Olu ADEYEMO

                -- Requirements:
                1. Run 'aws configure' to configure your system with aws
                2. Ensure that eksctl is installed on your machine
                ---------------------------------------------------------
                "

    echo "Menu Options:
    1. Create Cluster
    2. Delete Cluster
    3. View Cluster
    4. Setup OIDC
    5. Exit"
}

create_cluster() {
    echo "Creating Cluster..."

    # collect the cluster name
    read -p "Enter cluster name: " cluster_name
    echo "Your cluster name: $cluster_name"

    # collect the node group name
    read -p "Enter Node group name: " nodegroup_name
    echo "Node group name: $nodegroup_name"

    # collect the node type
    read -p "Enter Node type: " node_type
    echo "Node type: $node_type"

    # collect number of nodes
    read -p "Enter total number of nodes: " total_nodes
    echo "Total nodes: $total_nodes"

    # collect max number of nodes
    read -p "Enter maximum number of nodes: " max_nodes
    echo "Maximum nodes: $max_nodes"

    # collect min number of nodes
    read -p "Enter minimum number of nodes: " min_nodes
    echo "Minimum nodes: $min_nodes"

    # collect account id of the user
    read -p "Enter your account ID: " account_id

    # ask whether to proceed with creating the cluster...
    read -p "Do you want to create the cluster $cluster_name Y(Yes)/N(No)? " confirmation

    if [[ $confirmation == "Yes" || $confirmation == "Y" ]]; then
        echo "Getting ready to start creating cluster ..."
        sleep 2
        eksctl create cluster --name $cluster_name --nodegroup-name $nodegroup_name --node-type $node_type --nodes $total_nodes --nodes-max $max_nodes --nodes-min $min_nodes --managed
    else
        echo "Exiting ..."
        exit
    fi
}

delete_cluster() {
    echo "Deleting Cluster..."

    # collect the cluster name
    read -p "Enter cluster name to delete: " cluster_name

    # ask for confirmation
    read -p "Are you sure you want to delete cluster $cluster_name? (Y/N): " confirmation

    if [[ $confirmation == "Y" || $confirmation == "y" ]]; then
        echo "Getting ready to delete cluster $cluster_name..."
        sleep 2
        eksctl delete cluster --name $cluster_name
    else
        echo "Operation cancelled."
    fi
}

view_cluster() {
    echo "Viewing Cluster..."

    # view cluster information
    eksctl get cluster
}

setup_oidc() {
    echo "Setting up OIDC..."

    # collect the cluster name
    read -p "Enter cluster name to setup OIDC: " cluster_name

    # OIDC setup
    echo "Setting up OIDC..."
    oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
    aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
    eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve

    # create a service account
    echo "Creating service account..."
    eksctl create iamserviceaccount \
        --name ebs-csi-controller-sa \
        --namespace kube-system \
        --cluster $cluster_name \
        --role-name AmazonEKS_EBS_CSI_DriverRole \
        --role-only \
        --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
        --approve

    # add the EBS-CSI addon
    echo "Adding EBS-CSI addon..."
    eksctl create addon --name aws-ebs-csi-driver --cluster $cluster_name --service-account-role-arn arn:aws:iam::$account_id:role/AmazonEKS_EBS_CSI_DriverRole --force
}

read_user_choice() {
    read -p "Enter your choice: " choice
}

handle_choice() {
    case $choice in
        1)
            create_cluster
            ;;
        2)
            delete_cluster
            ;;
        3)
            view_cluster
            ;;
        4)
            setup_oidc
            ;;
        5)
            echo "Exiting ..."
            exit
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
}

main() {
    while true; do
        display_menu
        read_user_choice
        handle_choice
    done
}

main