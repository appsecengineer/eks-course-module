resource "aws_iam_role" "ase-eks-wn-role" {
  name = "ase-eks-node-group-role"

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
