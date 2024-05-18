output "endpoint" {
  value = aws_eks_cluster.ase-eks.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.ase-eks.certificate_authority[0].data
}

output "ASE-EKS-Cluster-Name" {
  value = aws_eks_cluster.ase-eks.name
}

output "ASE-EKS-cp-role-id" {
  value = aws_iam_role.ase-eks-role.id
}

output "ASE-EKS-wn-role-id" {
  value = aws_iam_role.ase-eks-wn-role.id
}

output "random_output" {
  value = random_string.suffix.result
}