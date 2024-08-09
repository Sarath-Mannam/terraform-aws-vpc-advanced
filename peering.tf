### VPC Peering with Default VPC
resource "aws_vpc_peering_connection" "peering" {
  count = var.is_peering_required ? 1 : 0
 #peer_owner_id = var.peer_owner_id
  peer_vpc_id   = aws_vpc.main.id
  vpc_id        = var.requester_vpc_id # ID of the requester VPC, Here Default VPC is the requester
  auto_accept   = true

  tags = merge(
    {
      Name = "VPC Peering between default and ${var.project_name}"
    },
    var.common_tags
  )
}

resource "aws_route" "default_route" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = var.default_route_table_id
  destination_cidr_block    = var.cidr_block            # roboshop cidr
  # Since we set count parameter, It is treated as list even if there is single element
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
  # depends_on = [ aws_route_table.testing ]
}

# Add route in Roboshop pubblic route table 
resource "aws_route" "public_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = var.default_vpc_cidr        # Default VPC CIDR
  # Since we set count parameter, It is treated as list even if there is single element
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
  # depends_on = [ aws_route_table.testing ]
}

resource "aws_route" "private_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = var.default_vpc_cidr        # Default VPC CIDR
  # Since we set count parameter, It is treated as list even if there is single element
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
  # depends_on = [ aws_route_table.testing ]
}

resource "aws_route" "database_peering" {
  count = var.is_peering_required ? 1 : 0
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = var.default_vpc_cidr        # Default VPC CIDR
  # Since we set count parameter, It is treated as list even if there is single element
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
  # depends_on = [ aws_route_table.testing ]
}

