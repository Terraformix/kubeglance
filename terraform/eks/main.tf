resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins SG"
  }
}

resource "aws_subnet" "private-us-east-1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.0.0/19"
  availability_zone = "us-east-1a"

  tags = {
    Name                              = "private-us-east-1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
  }
}

resource "aws_subnet" "private-us-east-1b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.32.0/19"
  availability_zone = "us-east-1b"

  tags = {
    Name                              = "private-us-east-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
  }
}

resource "aws_subnet" "public-us-east-1a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.64.0/19"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                         = "public-us-east-1a"
    "kubernetes.io/role/elb"     = "1" #this instruct the kubernetes to create public load balancer in these subnets
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_subnet" "public-us-east-1b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.96.0/19"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                         = "public-us-east-1b"
    "kubernetes.io/role/elb"     = "1" #this instruct the kubernetes to create public load balancer in these subnets
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.128.0/19"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "jenkins"
  }
}

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-us-east-1a.id

  tags = {
    Name = "k8s-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
      cidr_block                 = "0.0.0.0/0"
      nat_gateway_id             = aws_nat_gateway.nat.id
    }

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.igw.id
    }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "private-us-east-1a" {
  subnet_id      = aws_subnet.private-us-east-1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-us-east-1b" {
  subnet_id      = aws_subnet.private-us-east-1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-us-east-1a" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-us-east-1b" {
  subnet_id      = aws_subnet.public-us-east-1b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "jenkins" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.public.id
}

# IAM role for eks
# Allows EKS control plane to:
#   - Create and manage EKS clusters
#   - Communicate with worker nodes and other AWS services
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# bare minimum requirement of eks

resource "aws_eks_cluster" "demo" {
  name     = "demo"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private-us-east-1a.id,
      aws_subnet.private-us-east-1b.id,
      aws_subnet.public-us-east-1a.id,
      aws_subnet.public-us-east-1b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# IAM role for nodegroup
# Allows EC2 instances in the Nodegroup to:
#   - Join the EKS cluster
#   - Pull container images from ECR
#   - Communicate with AWS services

resource "aws_iam_role" "nodes" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# IAM policy attachment to nodegroup
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}


resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "private-nodes"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = [
    aws_subnet.private-us-east-1a.id,
    aws_subnet.private-us-east-1b.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t2.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    node = "kubenode02"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
  ]
}

resource "aws_ecr_repository" "kubeglance_backend" {
  name                 = "kubeglance-backend"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "kubeglance_frontend" {
  name                 = "kubeglance-frontend"
  image_tag_mutability = "MUTABLE"
}

# Create a key pair for SSH access
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/my-key.pem"
  file_permission = "0400"
}

# Create Elastic IPs
resource "aws_eip" "jenkins_master" {
  vpc = true
}

resource "aws_eip" "jenkins_slave" {
  vpc = true

}

resource "aws_eip_association" "jenkins_master" {
  instance_id   = aws_instance.jenkins_master.id
  allocation_id = aws_eip.jenkins_master.id
}

resource "aws_eip_association" "jenkins_slave" {
  instance_id   = aws_instance.jenkins_slave.id
  allocation_id = aws_eip.jenkins_slave.id
}

resource "aws_instance" "jenkins_master" {
  ami           = "ami-084568db4383264d4"
  instance_type = "t2.small"
  subnet_id     = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  # Add public key to AWS, which will be installed on any VM you create with that key pair.
  key_name      = aws_key_pair.generated_key.key_name

  tags = {
    Name = "jenkins-master"
  }
}

resource "aws_instance" "jenkins_slave" {
  ami           = "ami-084568db4383264d4"
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  # Add public key to AWS, which will be installed on any VM you create with that key pair.
  key_name      = aws_key_pair.generated_key.key_name

  tags = {
    Name = "jenkins-slave"
  }
}
