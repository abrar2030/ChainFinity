# Fixed Security Groups - Circular Dependency Resolved
# Using aws_security_group_rule resources to break the cycle

# ALB Security Group (base definition only)
resource "aws_security_group" "alb_fixed" {
  name_prefix = "chainfinity-alb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Application Load Balancer"

  tags = merge(local.common_tags, {
    Name = "chainfinity-alb-sg"
    Type = "SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Cluster Security Group (base definition only)
resource "aws_security_group" "eks_cluster_fixed" {
  name_prefix = "chainfinity-eks-cluster-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS cluster control plane"

  tags = merge(local.common_tags, {
    Name = "chainfinity-eks-cluster-sg"
    Type = "SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Nodes Security Group (base definition only)
resource "aws_security_group" "eks_nodes_fixed" {
  name_prefix = "chainfinity-eks-nodes-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS worker nodes"

  tags = merge(local.common_tags, {
    Name = "chainfinity-eks-nodes-sg"
    Type = "SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# === ALB Security Group Rules ===
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  description       = "HTTPS from allowed networks"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.allowed_cidr_blocks
  security_group_id = aws_security_group.alb_fixed.id
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  description       = "HTTP redirect to HTTPS"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.allowed_cidr_blocks
  security_group_id = aws_security_group.alb_fixed.id
}

resource "aws_security_group_rule" "alb_egress_to_nodes" {
  type                     = "egress"
  description              = "To EKS nodes"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes_fixed.id
  security_group_id        = aws_security_group.alb_fixed.id
}

# === EKS Cluster Security Group Rules ===
resource "aws_security_group_rule" "eks_cluster_ingress_from_nodes" {
  type                     = "ingress"
  description              = "From EKS nodes"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes_fixed.id
  security_group_id        = aws_security_group.eks_cluster_fixed.id
}

resource "aws_security_group_rule" "eks_cluster_egress_to_nodes" {
  type                     = "egress"
  description              = "To EKS nodes"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes_fixed.id
  security_group_id        = aws_security_group.eks_cluster_fixed.id
}

resource "aws_security_group_rule" "eks_cluster_egress_https" {
  type              = "egress"
  description       = "HTTPS outbound"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster_fixed.id
}

# === EKS Nodes Security Group Rules ===
resource "aws_security_group_rule" "eks_nodes_ingress_from_alb" {
  type                     = "ingress"
  description              = "From ALB"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_fixed.id
  security_group_id        = aws_security_group.eks_nodes_fixed.id
}

resource "aws_security_group_rule" "eks_nodes_ingress_from_cluster" {
  type                     = "ingress"
  description              = "From EKS cluster"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_fixed.id
  security_group_id        = aws_security_group.eks_nodes_fixed.id
}

resource "aws_security_group_rule" "eks_nodes_ingress_self" {
  type              = "ingress"
  description       = "Node to node"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.eks_nodes_fixed.id
}

resource "aws_security_group_rule" "eks_nodes_egress_all" {
  type              = "egress"
  description       = "All outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_nodes_fixed.id
}
