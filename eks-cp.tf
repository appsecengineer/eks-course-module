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
  enabled_cluster_log_types = local.cluster_log_types
  
  dynamic "encryption_config" {
    for_each = var.enable_encryption ? [1] : []
    content {
      provider {
        key_arn =  var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

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

