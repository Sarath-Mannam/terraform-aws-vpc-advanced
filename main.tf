resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block  # user will provide
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support = var.enable_dns_support

  # Merge function helps to merge multiple maps
  tags = merge(
    var.common_tags,
    {
        Name = var.project_name
    },
    var.vpc_tags
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
        Name = var.project_name
    },
    var.igw_tags
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = local.azs[count.index] 
  # availability zone we kept in locals for users not to override the values
  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-public-${local.azs[count.index]}"
    }
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr[count.index]
  availability_zone = local.azs[count.index] 
  # availability zone we kept in locals for users not to override the values
  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-private-${local.azs[count.index]}"
    }
  )
}

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidr)
  vpc_id = aws_vpc.main.id
  cidr_block = var.database_subnet_cidr[count.index]
  availability_zone = local.azs[count.index] 
  # availability zone we kept in locals for users not to override the values
  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-database-${local.azs[count.index]}"
    }
  )
}

# Here I'm creating public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_internet_gateway.main.id
  # }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-public"
    },
    var.public_route_table_tags
  )
}

# Always add route seperately, adding internet route 
resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.main.id
}

resource "aws_eip" "eip" {
  # instance = aws_instance.web.id --> Not Associating with any instance
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.public[0].id  # Here 0 is because we have two public subnets 
  # one in us-east-1a and other one in us-east-1b, So i'm provisioning in us-east-1a
  # for saving the cost. 

  tags = merge(
    var.common_tags,
    {
      Name = var.project_name
    },
    var.nat_gateway_tags
  )

  # To ensure proper ordering, It is recommended to add an explicit dependency on the 
  # Internet gateway for the VPC
  depends_on = [ aws_internet_gateway.main ]
}


# Here I'm creating private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # route {
  #   cidr_block = "0.0.0.0/0"
  #   nat_gateway_id = aws_nat_gateway.main.id
  # }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-private"
    },
    var.private_route_table_tags
  )
}

# adding NAT Gateway raoute
resource "aws_route" "private" {
  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  # route {
  #   cidr_block = "0.0.0.0/0"
  #   nat_gateway_id = aws_nat_gateway.main.id
  # }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-database"
    },
    var.database_route_table_tags
  )
}

# adding NAT Gateway raoute
resource "aws_route" "database" {
  route_table_id = aws_route_table.database.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}

# Iterating two times because we have two public subnets
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr)           # At this line it will get count as 2 subnets
  subnet_id      = element(aws_subnet.public[*].id, count.index) # At this line it will get first subnet and then second subnet
  route_table_id = aws_route_table.public.id 
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr)           # At this line it will get count as 2 subnets
  subnet_id      = element(aws_subnet.private[*].id, count.index) # At this line it will get first subnet and then second subnet
  route_table_id = aws_route_table.private.id 
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidr)           # At this line it will get count as 2 subnets
  subnet_id      = element(aws_subnet.database[*].id, count.index) # At this line it will get first subnet and then second subnet
  route_table_id = aws_route_table.database.id 
}

resource "aws_db_subnet_group" "roboshop" {
  name = var.project_name
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    var.common_tags,
    {
      Name = var.project_name
    },
    var.db_subnet_group_tags
  )
}