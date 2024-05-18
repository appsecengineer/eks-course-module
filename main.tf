resource "random_string" "suffix" {
  length  = 8
  upper   = false
  lower   = true
  number  = false
  special = false
}

resource "aws_vpc" "ase-eks-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ase-eks-${random_string.suffix.result}"
  }
}


resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.ase-eks-vpc.id
  tags = {
    Name = "ase-eks-Gateway-${random_string.suffix.result}"
  }
}
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.ase-eks-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
  tags = {
    Name = "Public Subnet Route"
  }
}

resource "aws_subnet" "public-subnet1" {
  cidr_block              = var.public_subnet_cidr1
  vpc_id                  = aws_vpc.ase-eks-vpc.id
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ase-eks-Public-Subnet1-${random_string.suffix.result}"
  }
}

resource "aws_subnet" "public-subnet2" {
  cidr_block              = var.public_subnet_cidr2
  vpc_id                  = aws_vpc.ase-eks-vpc.id
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "ase-eks-Public-Subnet2-${random_string.suffix.result}"
  }
}

resource "aws_route_table_association" "public-subnet1" {
  route_table_id = aws_route_table.public-route.id
  subnet_id      = aws_subnet.public-subnet1.id
}

resource "aws_route_table_association" "public-subnet2" {
  route_table_id = aws_route_table.public-route.id
  subnet_id      = aws_subnet.public-subnet2.id
}

resource "aws_iam_role" "ase-eks-role" {
  name = "ase-eks-cluster-${random_string.suffix.result}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ase-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.ase-eks-role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "ase-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.ase-eks-role.name
}

resource "aws_eks_cluster" "ase-eks" {
  name     = local.cluster_name
  role_arn = aws_iam_role.ase-eks-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.ase-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.ase-AmazonEKSVPCResourceController
  ]
}

resource "aws_iam_role" "ase-eks-wn-role" {
  name = "ase-eks-node-group-role-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "ase-wn-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.ase-eks-wn-role.name
}

resource "aws_iam_role_policy_attachment" "ase-wn-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.ase-eks-wn-role.name
}

resource "aws_iam_role_policy_attachment" "ase-wn-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ase-eks-wn-role.name
}

resource "aws_eks_node_group" "ase-eks-wn" {
  cluster_name    = aws_eks_cluster.ase-eks.name
  node_group_name = "worker-group-1"
  node_role_arn   = aws_iam_role.ase-eks-wn-role.arn
  subnet_ids      = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
    instance_types = ["t3.small"]
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.ase-wn-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.ase-wn-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.ase-wn-AmazonEC2ContainerRegistryReadOnly,
  ]
}

# commented since we are doing only one node for demo
# resource "aws_eks_node_group" "ase-eks-wn2" {
#   cluster_name    = aws_eks_cluster.ase-eks.name
#   node_group_name = "worker-group-2"
#   node_role_arn   = aws_iam_role.ase-eks-wn-role.arn
#   subnet_ids      = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
#     instance_types = ["t3.small"]
#   scaling_config {
#     desired_size = 1
#     max_size     = 1
#     min_size     = 1
#   }

#   update_config {
#     max_unavailable = 1
#   }
#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#   depends_on = [
#     aws_iam_role_policy_attachment.ase-wn-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.ase-wn-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.ase-wn-AmazonEC2ContainerRegistryReadOnly,
#   ]
# }