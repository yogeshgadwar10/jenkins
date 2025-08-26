provider "aws" {
    region = "us-east-2"  
}
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "eks.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
  
}
resource "aws_iam_role_policy_attachment" "cluster_policy_attachment" {
  role = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "my-role" {
  name = "eks-my-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        }
    ]
}) // arn:aws:iam::aws:policy/AmazonEC2FullAccess
}
resource "aws_iam_role_policy_attachment" "ec2_full_excces" {
  role = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

data "aws_vpc" "my_vpc" {
  default = true
}
data "aws_subnets" "my_subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.my_vpc.id]
  }  
}
resource "aws_eks_cluster" "my_cluster" {
 name = "my-eks-cluster"
 role_arn = aws_iam_role.eks_cluster_role.arn 

 vpc_config {
    # subnet_ids = data.aws_subnets.my_subnets.ids 
    subnet_ids = data.aws_subnets.my_subnets.ids
 
  }
  depends_on = [ 
    aws_iam_role_policy_attachment.cluster_policy_attachment
   ]
  
}

resource "aws_iam_role" "node_role" {
  name = "my-node-role"  
   assume_role_policy = jsonencode({
       "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "ec2_container_registery" {
  role = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "my_cluster" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = data.aws_subnets.my_subnets.id
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  update_config{
  max_unavailable = 1
  }
 
 depends_on = [
  aws_eks_cluster.my_cluster,
  aws_iam_role_policy_attachment.eks_cni_policy_attachment,
  aws_iam_role_policy_attachment.eks_worker_node_policy,
  aws_iam_role_policy_attachment.ec2_container_registery

  ]
}